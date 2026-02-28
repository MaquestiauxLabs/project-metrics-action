#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=== Fetching project data ==="
export GH_TOKEN
if [[ -z "${GH_TOKEN:-}" ]]; then
    GH_TOKEN=$(gh auth token)
    export GH_TOKEN
fi

ORG="${1:-MaquestiauxLabs}"

./scripts/get_data.sh "$ORG" "test/projects.json"

echo ""
echo "=== Checking public field ==="
jq -r '.projects[] | "  \(.title): public=\(.public)"' "test/projects.json"

echo ""
echo "=== Generating README ==="
./scripts/update_readme.sh "test/projects.json" "sample-README.md" "test/README.md"

echo ""
echo "=== Generated README (PROJECT_BREAKDOWN section) ==="
grep -A 50 "## 📋 Project Status" "test/README.md" || echo "Note: Awk multiline issue may prevent content injection"

echo ""
echo "=== Test complete ==="
