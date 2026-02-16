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
      }
    }
  }
}' -F org="$ORG" 2>/dev/null) || RAW_RESPONSE=""

mkdir -p "$(dirname "$OUT_PATH")"

if [[ -z "$RAW_RESPONSE" ]]; then
	echo "[]" > "$OUT_PATH"
	echo "No data returned; wrote empty array to $OUT_PATH"
	exit 0
fi

echo "$RAW_RESPONSE" | jq '(.data.organization.projectsV2.nodes // []) | sort_by(.title // "")' > "$OUT_PATH"

if [[ ! -s "$OUT_PATH" ]]; then
	echo "[]" > "$OUT_PATH"
fi

PROJECT_COUNT=$(jq 'length' "$OUT_PATH" 2>/dev/null || echo 0)
echo "Saved $PROJECT_COUNT projects to $OUT_PATH"