#!/usr/bin/env bash
set -euo pipefail

ORG="$1"

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
        | "\(.number)|\(.title)"' 2>/dev/null) || PROJECTS=""

PROJECTS=$(echo "$PROJECTS" | grep -v '^$' | head -20)

if [[ -z "$PROJECTS" ]]; then
  echo '{"total_todo":0,"total_ongoing":0,"total_closed":0}' > global-stats.json
  echo "[]" > all-projects-summary.json
  echo "[]" > language-stats.json
  exit 0
fi

T_TODO=0
T_ONGOING=0
T_DONE=0

rm -f project-*-stats.json

while IFS="|" read -r NUM TITLE; do
  [[ -z "$NUM" || -z "$TITLE" ]] && continue
  
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

  RESULT=$(gh api graphql -f query="$QUERY" -f org="$ORG" -F num="$NUM" 2>/dev/null) || RESULT="{}"

  if [[ -z "$RESULT" || "$RESULT" == "{}" ]]; then
    continue
  fi

  P_TODO=0
  P_ONGOING=0
  P_DONE=0
  P_NO_STATUS=0

  if echo "$RESULT" | jq -e '.data.organization.projectV2.items.nodes' >/dev/null 2>&1; then
    P_TODO=$(echo "$RESULT" | jq '[.data.organization.projectV2.items.nodes[]
      | select(.status != null and .status.name != null) 
      | select(.status.name == "Todo" or .status.name == "Planned")] | length' 2>/dev/null || echo "0")

    P_ONGOING=$(echo "$RESULT" | jq '[.data.organization.projectV2.items.nodes[]
      | select(.status != null and .status.name != null)
      | select(.status.name == "In Progress" or .status.name == "Ongoing")] | length' 2>/dev/null || echo "0")

    P_DONE=$(echo "$RESULT" | jq '[.data.organization.projectV2.items.nodes[]
      | select(.status != null and .status.name != null)
      | select(.status.name == "Done" or .status.name == "Complete")] | length' 2>/dev/null || echo "0")

    P_NO_STATUS=$(echo "$RESULT" | jq '[.data.organization.projectV2.items.nodes[]
      | select(.status == null or .status.name == null)] | length' 2>/dev/null || echo "0")
  fi

  T_TODO=$((T_TODO + P_TODO))
  T_ONGOING=$((T_ONGOING + P_ONGOING))
  T_DONE=$((T_DONE + P_DONE))

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
    --jq '.data.organization.repositories.nodes[]' 2>/dev/null) || ALL_REPOS=""

  REPOS_WITH_LANGS="[]"
  
  if [[ -n "$ALL_REPOS" && "$ALL_REPOS" != "null" ]]; then
    case "$TITLE" in
      *"React"*)
        TARGET_REPOS=$(echo "$ALL_REPOS" | jq 'select(.name | test("react"; "i"))' 2>/dev/null || echo "[]")
        ;;
      *"Angular"*)
        TARGET_REPOS=$(echo "$ALL_REPOS" | jq 'select(.name | test("angular"; "i"))' 2>/dev/null || echo "[]")
        ;;
      *"Metrics"*)
        TARGET_REPOS=$(echo "$ALL_REPOS" | jq 'select(.name | test("metrics|action"; "i"))' 2>/dev/null || echo "[]")
        ;;
      *"Demo"*)
        TARGET_REPOS=$(echo "$ALL_REPOS" | jq 'select(.name | test("demo|resume"; "i"))' 2>/dev/null || echo "[]")
        ;;
      *)
        TARGET_REPOS="[]"
        ;;
    esac

    if [[ -z "$TARGET_REPOS" || "$TARGET_REPOS" == "null" || "$TARGET_REPOS" == "[]" ]]; then
      REPOS_WITH_LANGS="[]"
    else
      LANGS_DATA=$(echo "$TARGET_REPOS" | jq -c '[.languages.edges[]? // [] | {language: .node.name, size: .size}] | group_by(.language) | map({language: .[0].language, size: (map(.size) | add)}) | sort_by(.size) | reverse | .[:3]' 2>/dev/null)
      
      if [[ -z "$LANGS_DATA" || "$LANGS_DATA" == "null" ]]; then
        REPOS_WITH_LANGS="[]"
      else
        REPOS_WITH_LANGS="$LANGS_DATA"
      fi
    fi
  fi

  if [[ -z "$REPOS_WITH_LANGS" || "$REPOS_WITH_LANGS" == "null" ]]; then
    REPOS_WITH_LANGS="[]"
  else
    REPOS_WITH_LANGS=$(echo "$REPOS_WITH_LANGS" | jq -c 'group_by(.language) | map({language: .[0].language, size: (map(.size) | add)}) | sort_by(.size) | reverse | .[:3]' 2>/dev/null || echo "[]")
  fi

  if [[ -z "$REPOS_WITH_LANGS" || "$REPOS_WITH_LANGS" == "null" ]]; then
    REPOS_WITH_LANGS="[]"
  fi

  NUM_INT=0
  if [[ -n "$NUM" ]]; then
    NUM_INT=$(echo "$NUM" | jq -n 'tonumber(.)' 2>/dev/null || echo "0")
  fi

  P_TODO=$(echo "$P_TODO" | jq -n 'tonumber(.)' 2>/dev/null || echo "0")
  P_ONGOING=$(echo "$P_ONGOING" | jq -n 'tonumber(.)' 2>/dev/null || echo "0")
  P_DONE=$(echo "$P_DONE" | jq -n 'tonumber(.)' 2>/dev/null || echo "0")
  P_NO_STATUS=$(echo "$P_NO_STATUS" | jq -n 'tonumber(.)' 2>/dev/null || echo "0")

  jq -n \
    --arg project "$TITLE" \
    --argjson number "$NUM_INT" \
    --argjson todo "$P_TODO" \
    --argjson ongoing "$P_ONGOING" \
    --argjson done "$P_DONE" \
    --argjson no_status "$P_NO_STATUS" \
    --argjson languages "$REPOS_WITH_LANGS" \
    '{project:$project,number:$number,todo:$todo,ongoing:$ongoing,done:$done,no_status:$no_status,languages:$languages}' \
    > "project-$NUM-stats.json"

done <<< "$PROJECTS"

jq -n \
  --argjson todo "$T_TODO" \
  --argjson ongoing "$T_ONGOING" \
  --argjson done "$T_DONE" \
  '{total_todo:$todo,total_ongoing:$ongoing,total_closed:$done}' \
  > global-stats.json

jq -n '[inputs]' project-*-stats.json > all-projects-summary.json 2>/dev/null || echo "[]" > all-projects-summary.json

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
        | {language: .node.name, size: .size}' 2>/dev/null) || LANG_STATS=""

if [[ -n "$LANG_STATS" && "$LANG_STATS" != "null" ]]; then
  echo "$LANG_STATS" | jq -s '
    group_by(.language) |
    map({
      language: .[0].language,
      total_bytes: map(.size) | add
    }) |
    sort_by(.total_bytes) |
    reverse
  ' > language-stats.json
else
  echo "[]" > language-stats.json
fi
