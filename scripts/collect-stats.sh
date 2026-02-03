#!/usr/bin/env bash
set -euo pipefail

ORG="$1"

# Fetch projects (exclude ".github")
PROJECTS=$(gh api graphql -f query='
  query($org: String!) {
    organization(login: $org) {
      projectsV2(first: 20) {
        nodes {
          number
          title
        }
      }
    }
  }' -f org="$ORG" \
  --jq '.data.organization.projectsV2.nodes[]
        | select(.title != ".github")
        | "\(.number)|\(.title)"')

T_TODO=0
T_ONGOING=0
T_DONE=0

rm -f project-*-stats.json

while IFS="|" read -r NUM TITLE; do
  QUERY='
    query($org: String!, $num: Int!) {
      organization(login: $org) {
        projectV2(number: $num) {
          items(first: 100) {
            nodes {
              status: fieldValueByName(name: "Status") {
                ... on ProjectV2ItemFieldSingleSelectValue {
                  name
                }
              }
            }
          }
        }
      }
    }'

  RESULT=$(gh api graphql -f query="$QUERY" -f org="$ORG" -F num="$NUM")

  P_TODO=$(echo "$RESULT" | jq '[.data.organization.projectV2.items.nodes[]
    | select(.status.name == "Todo" or .status.name == "Planned")] | length')

  P_ONGOING=$(echo "$RESULT" | jq '[.data.organization.projectV2.items.nodes[]
    | select(.status.name == "In Progress" or .status.name == "Ongoing")] | length')

  P_DONE=$(echo "$RESULT" | jq '[.data.organization.projectV2.items.nodes[]
    | select(.status.name == "Done" or .status.name == "Complete")] | length')

  T_TODO=$((T_TODO + P_TODO))
  T_ONGOING=$((T_ONGOING + P_ONGOING))
  T_DONE=$((T_DONE + P_DONE))

  jq -n \
    --arg project "$TITLE" \
    --argjson todo "$P_TODO" \
    --argjson ongoing "$P_ONGOING" \
    --argjson done "$P_DONE" \
    '{project:$project,todo:$todo,ongoing:$ongoing,done:$done}' \
    > "project-$NUM-stats.json"

done <<< "$PROJECTS"

jq -n \
  --argjson todo "$T_TODO" \
  --argjson ongoing "$T_ONGOING" \
  --argjson done "$T_DONE" \
  '{total_todo:$todo,total_ongoing:$ongoing,total_closed:$done}' \
  > global-stats.json

# Collect all projects with their repositories
jq -n '[inputs]' project-*-stats.json > all-projects-summary.json

# Collect repository stats for each project
rm -f repo-*-stats.json

while IFS="|" read -r NUM TITLE; do
  # Get repositories linked to this project
  REPOS=$(gh api graphql -f query='
    query($org: String!, $num: Int!) {
      organization(login: $org) {
        projectV2(number: $num) {
          items(first: 100) {
            nodes {
              content {
                __typename
                ... on Repository {
                  name
                  owner { login }
                  issues(states: OPEN) { totalCount }
                  pullRequests(states: OPEN) { totalCount }
                  stargazerCount
                  forkCount
                }
              }
            }
          }
        }
      }
    }' -f org="$ORG" -F num="$NUM" \
    --jq '.data.organization.projectV2.items.nodes[]
          | select(.content.__typename == "Repository")
          | .content | {
              name: .name,
              owner: .owner.login,
              issues: .issues.totalCount,
              prs: .pullRequests.totalCount,
              stars: .stargazerCount,
              forks: .forkCount
            }')

  if [[ -n "$REPOS" ]]; then
    echo "$REPOS" | jq --arg project "$TITLE" '. + {project: $project}' > "repo-$NUM-stats.json"
  fi
done <<< "$PROJECTS"

if ls repo-*-stats.json 1> /dev/null 2>&1; then
  jq -n '[inputs]' repo-*-stats.json > all-repos-summary.json
else
  echo '[]' > all-repos-summary.json
fi
