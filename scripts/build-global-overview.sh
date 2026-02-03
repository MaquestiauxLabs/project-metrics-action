#!/usr/bin/env bash
set -euo pipefail

# Source common utilities
source "$(dirname "$0")/language-utils.sh"

PROJECTS_JSON="all-projects-summary.json"

# Calculate global stats
total_todo=$(jq '[.[].todo] | add' "$PROJECTS_JSON")
total_ongoing=$(jq '[.[].ongoing] | add' "$PROJECTS_JSON")
total_done=$(jq '[.[].done] | add' "$PROJECTS_JSON")
total_no_status=$(jq '[.[].no_status] | add' "$PROJECTS_JSON")
total_projects=$(jq 'length' "$PROJECTS_JSON")
total_items=$((total_todo + total_ongoing + total_done + total_no_status))

if [[ $total_items -gt 0 ]]; then
  completion_rate=$((total_done * 100 / total_items))
else
  completion_rate=0
fi

# Generate compact global overview using common utilities
cat > global-overview.tmp << EOF
## 📊 MaquestiauxLabs Metrics

$(generate_all_status_badges "$total_todo" "$total_ongoing" "$total_done" "$total_no_status" "for-the-badge" "true")
![Completion Rate]($(generate_completion_badge "$completion_rate" "for-the-badge" "true"))

EOF