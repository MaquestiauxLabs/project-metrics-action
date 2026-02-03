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

  # Get all organization repositories and try to match them to project
  ALL_REPOS=$(gh api graphql -f query='
    query($org: String!) {
      organization(login: $org) {
        repositories(first: 50) {
          nodes {
            name
            owner { login }
            languages(first: 5) {
              edges {
                size
                node {
                  name
                }
              }
            }
          }
        }
      }
    }' -f org="$ORG" \
    --jq '.data.organization.repositories.nodes[]')

  echo "DEBUG: All repos in org: $(echo "$ALL_REPOS" | jq -r '.name' | wc -l)" >&2

  REPOS_WITH_LANGS="[]"
  
  # Try to match repos to project by name
  case "$TITLE" in
    *"React"*)
      TARGET_REPOS=$(echo "$ALL_REPOS" | jq 'select(.name | contains("react") or contains("React"))')
      ;;
    *"Angular"*)
      TARGET_REPOS=$(echo "$ALL_REPOS" | jq 'select(.name | contains("angular") or contains("Angular"))')
      ;;
    *"Metrics"*)
      TARGET_REPOS=$(echo "$ALL_REPOS" | jq 'select(.name | contains("metrics") or contains("Metrics") or contains("action") or contains("Action"))')
      ;;
    *"Demo"*)
      TARGET_REPOS=$(echo "$ALL_REPOS" | jq 'select(.name | contains("demo") or contains("Demo") or contains("resume") or contains("Resume"))')
      ;;
    *)
      TARGET_REPOS="[]"
      ;;
  esac

  echo "DEBUG: Matched repos for $TITLE: $(echo "$TARGET_REPOS" | jq -r '.name' | wc -l)" >&2

  if [[ "$TARGET_REPOS" != "null" && "$TARGET_REPOS" != "[]" ]]; then
    # Extract languages from matched repos
    LANGS_DATA=$(echo "$TARGET_REPOS" | jq '[.languages.edges[] | {language: .node.name, size: .size}] | group_by(.language) | map({language: .[0].language, size: (map(.size) | add)}) | sort_by(.size) | reverse | .[:3]')
    
    REPOS_WITH_LANGS="$LANGS_DATA"
  fi
  
  echo "DEBUG: Final languages for project $TITLE: $REPOS_WITH_LANGS" >&2

  REPOS_WITH_LANGS=$(echo "$REPOS_WITH_LANGS" | jq 'group_by(.language) | map({language: .[0].language, size: (map(.size) | add)}) | sort_by(.size) | reverse | .[:3]')

  jq -n \
    --arg project "$TITLE" \
    --argjson todo "$P_TODO" \
    --argjson ongoing "$P_ONGOING" \
    --argjson done "$P_DONE" \
    --argjson languages "$REPOS_WITH_LANGS" \
    '{project:$project,todo:$todo,ongoing:$ongoing,done:$done,languages:$languages}' \
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

# Collect language statistics across the organization
echo "Collecting language statistics..." >&2
LANG_STATS=$(gh api graphql -f query='
  query($org: String!) {
    organization(login: $org) {
      repositories(first: 100, privacy: PUBLIC) {
        nodes {
          languages(first: 10) {
            edges {
              size
              node {
                name
              }
            }
          }
        }
      }
    }
  }' -f org="$ORG" \
  --jq '.data.organization.repositories.nodes[]
        | .languages.edges[]
        | {language: .node.name, size: .size}')

# Aggregate language stats
echo "$LANG_STATS" | jq -s '
  group_by(.language) |
  map({
    language: .[0].language,
    total_bytes: map(.size) | add
  }) |
  sort_by(.total_bytes) |
  reverse
' > language-stats.json

# Create empty repos file for now - repository stats can be added later
echo '[]' > all-repos-summary.json
