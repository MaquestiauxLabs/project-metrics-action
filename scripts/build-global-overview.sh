#!/usr/bin/env bash
set -euo pipefail

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

# Determine completion color
if [[ $total_items -eq 0 ]]; then
  completion_color="brightgreen"
  completion_display="0%25%20(clean)"
elif [[ $completion_rate -ge 80 ]]; then
  completion_color="brightgreen"
  completion_display="${completion_rate}%25"
elif [[ $completion_rate -ge 50 ]]; then
  completion_color="yellow"
  completion_display="${completion_rate}%25"
elif [[ $completion_rate -ge 25 ]]; then
  completion_color="orange"
  completion_display="${completion_rate}%25"
else
  completion_color="red"
  completion_display="${completion_rate}%25"
fi

# Generate compact global overview
cat > global-overview.tmp << EOF
## 📊 MaquestiauxLabs Metrics

![Todo](https://img.shields.io/badge/Todo-$total_todo-blue?style=for-the-badge&logo=todoist&logoColor=white) 
![In Progress](https://img.shields.io/badge/In%20Progress-$total_ongoing-yellow?style=for-the-badge&logo=gitlab&logoColor=white) 
![Done](https://img.shields.io/badge/Done-$total_done-green?style=for-the-badge&logo=checkmarx&logoColor=white)
![No Status](https://img.shields.io/badge/No%20Status-$total_no_status-grey?style=for-the-badge&logo=help&logoColor=white)
![Completion Rate](https://img.shields.io/badge/Completion-${completion_display}-${completion_color}?style=for-the-badge&logo=github&logoColor=white)

EOF