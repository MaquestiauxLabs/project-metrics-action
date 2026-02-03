#!/usr/bin/env bash
set -euo pipefail

PROJECTS_JSON="all-projects-summary.json"

# Generate project breakdown
cat > project-breakdown.tmp << EOF
## 📋 Project Breakdown

EOF

# Process each project
jq -c '.[]' "$PROJECTS_JSON" | while read -r project_json; do
  project=$(echo "$project_json" | jq -r '.project')
  todo=$(echo "$project_json" | jq -r '.todo')
  ongoing=$(echo "$project_json" | jq -r '.ongoing')
  done=$(echo "$project_json" | jq -r '.done')
  total=$((todo + ongoing + done))
  
  if [[ $total -gt 0 ]]; then
    completion_pct=$((done * 100 / total))
  else
    completion_pct=0
  fi
  
  # Determine project completion color
  project_color="red"
  if [[ $completion_pct -ge 80 ]]; then
    project_color="brightgreen"
  elif [[ $completion_pct -ge 50 ]]; then
    project_color="yellow"
  elif [[ $completion_pct -ge 25 ]]; then
    project_color="orange"
  fi
  
  # Add project metrics
  cat >> project-breakdown.tmp << EOF
### 🚀 $project
![Todo](https://img.shields.io/badge/Todo-$todo-blue?style=for-the-badge)
![In Progress](https://img.shields.io/badge/In%20Progress-$ongoing-yellow?style=for-the-badge)
![Done](https://img.shields.io/badge/Done-$done-green?style=for-the-badge)
![Project Completion](https://img.shields.io/badge/${completion_pct}%25-${project_color}?style=for-the-badge&logo=github&logoColor=white)

EOF
done

cat >> project-breakdown.tmp << EOF
---

EOF