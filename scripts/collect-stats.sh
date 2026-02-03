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
    | select(.status.name != null) 
    | select(.status.name == "Todo" or .status.name == "Planned")] | length')

  P_ONGOING=$(echo "$RESULT" | jq '[.data.organization.projectV2.items.nodes[]
    | select(.status.name != null)
    | select(.status.name == "In Progress" or .status.name == "Ongoing")] | length')

  P_DONE=$(echo "$RESULT" | jq '[.data.organization.projectV2.items.nodes[]
    | select(.status.name != null)
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
              }
            }
          }
        }
      }
    }' -f org="$ORG" -F num="$NUM" \
    --jq '.data.organization.projectV2.items.nodes[]
          | select(.content.__typename == "Repository")
          | .content')

  if [[ -n "$REPOS" ]]; then
    # For each repository found, get its stats separately
    echo "$REPOS" | while read -r repo_info; do
      REPO_NAME=$(echo "$repo_info" | jq -r '.name')
      REPO_OWNER=$(echo "$repo_info" | jq -r '.owner.login')
      
      REPO_STATS=$(gh api repos/"$REPO_OWNER"/"$REPO_NAME" \
        --jq '{
          name: .name,
          owner: .owner.login,
          issues: .open_issues_count,
          prs: (gh search prs "repo:$REPO_OWNER/$REPO_NAME state:open" --jq ". | length" 2>/dev/null || echo "0"),
          stars: .stargazers_count,
          forks: .forks_count
        }')
      
      echo "$REPO_STATS" | jq --arg project "$TITLE" '. + {project: $project}' >> "repo-$NUM-stats.json"
    done
  fi
done <<< "$PROJECTS"

if ls repo-*-stats.json 1> /dev/null 2>&1; then
  jq -n '[inputs]' repo-*-stats.json > all-repos-summary.json
else
  echo '[]' > all-repos-summary.json
fi
