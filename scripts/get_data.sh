#!/usr/bin/env bash
set -euo pipefail

ORG="${1:-}"
OUT_PATH="${2:-../data/projects.json}"

if [[ -z "$ORG" ]]; then
	echo "Usage: $0 <org> [output_path]" >&2
	exit 1
fi

echo "Fetching projects for organization: $ORG"

RAW_RESPONSE=$(gh api graphql -f query='query($org: String!) {
  organization(login: $org) {
    name
    description
    location
    avatarUrl,
    projectsV2(first: 20) {
      nodes {
        id
        title
        number
        url
        shortDescription
        public
        closed
        createdAt
        updatedAt
        creator {
          login
        }
        statusField: field(name: "Status") {
          ... on ProjectV2SingleSelectField {
            options {
              id
              name
              color
            }
          }
        }
        items(first: 100) {
          totalCount
          nodes {
            id
            # 1. Get the Kanban Status
            status: fieldValueByName(name: "Status") {
              ... on ProjectV2ItemFieldSingleSelectValue { name }
            }
            # 2. Get Custom Type (if you have a custom field named "Type")
            customType: fieldValueByName(name: "Type") {
              ... on ProjectV2ItemFieldSingleSelectValue { name }
            }
            # 3. Get Labels and Native Issue Type from the content
            content {
              __typename
              ... on Issue {
                title
                number
                issueType { name } # Native GitHub Issue Type (e.g., "Task")
                labels(first: 10) {
                  nodes { name }
                }
                body
              }
              ... on PullRequest {
                title
                number
                labels(first: 10) {
                  nodes { name }
                }
                body
              }
            }
          }
        }
        repositories(first: 10) {
          nodes {
            id
            nameWithOwner
            url
            issues { totalCount }
            openIssues: issues(states: OPEN) { totalCount }
            closedIssues: issues(states: CLOSED) { totalCount }
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
    }
  }
}' -F org="$ORG" 2>/dev/null) || RAW_RESPONSE=""

mkdir -p "$(dirname "$OUT_PATH")"

if [[ -z "$RAW_RESPONSE" ]]; then
	echo '{"organisationName": "", "organisationDescription": "", "organisationLocation": "", "projects": []}' > "$OUT_PATH"
	echo "No data returned; wrote empty object to $OUT_PATH"
	exit 0
fi

echo "$RAW_RESPONSE" | jq '{
  organisationName: .data.organization.name,
  organisationDescription: .data.organization.description,
  organisationLocation: .data.organization.location,
  organisationAvatar: .data.organization.avatarUrl,
  projects: (.data.organization.projectsV2.nodes // [] | sort_by(.title // "") | map(
    . as $proj
    | .statusCounts = ($proj.items.nodes | map(.status.name // "Unassigned") | group_by(.) | map({key: .[0], value: length}) | from_entries)
    | .statusCounts = (($proj.statusField.options // []) | map(.name) | map({(.): 0}) | add) * .statusCounts
    | .statusCounts.Total = ([.statusCounts[]] | add)
    | del(.statusField)
  ))
}' > "$OUT_PATH"

if [[ ! -s "$OUT_PATH" ]]; then
	echo "[]" > "$OUT_PATH"
fi

PROJECT_COUNT=$(jq 'length' "$OUT_PATH" 2>/dev/null || echo 0)
echo "Saved $PROJECT_COUNT projects to $OUT_PATH"