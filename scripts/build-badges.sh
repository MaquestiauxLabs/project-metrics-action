#!/usr/bin/env bash
set -euo pipefail

PROJECTS_JSON="all-projects-summary.json"

# Calculate global stats
total_todo=$(jq '[.[].todo] | add' "$PROJECTS_JSON")
total_ongoing=$(jq '[.[].ongoing] | add' "$PROJECTS_JSON")
total_done=$(jq '[.[].done] | add' "$PROJECTS_JSON")
total_projects=$(jq 'length' "$PROJECTS_JSON")
total_items=$((total_todo + total_ongoing + total_done))

if [[ $total_items -gt 0 ]]; then
  completion_rate=$((total_done * 100 / total_items))
else
  completion_rate=0
fi

# Determine completion color
completion_color="red"
if [[ $completion_rate -ge 80 ]]; then
  completion_color="brightgreen"
elif [[ $completion_rate -ge 50 ]]; then
  completion_color="yellow"
elif [[ $completion_rate -ge 25 ]]; then
  completion_color="orange"
fi

# Generate compact global overview
cat > metrics.tmp << EOF
## 📊 MaquestiauxLabs Metrics

![Todo](https://img.shields.io/badge/Todo-$total_todo-blue?style=for-the-badge&logo=todoist&logoColor=white) 
![In Progress](https://img.shields.io/badge/In%20Progress-$total_ongoing-yellow?style=for-the-badge&logo=gitlab&logoColor=white) 
![Done](https://img.shields.io/badge/Done-$total_done-green?style=for-the-badge&logo=checkmarx&logoColor=white)
![Completion Rate](https://img.shields.io/badge/Completion-${completion_rate}%25-${completion_color}?style=for-the-badge&logo=github&logoColor=white)

---

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
  cat >> metrics.tmp << EOF
### 🚀 $project
![Todo](https://img.shields.io/badge/Todo-$todo-blue?style=flat-square)
![In Progress](https://img.shields.io/badge/In%20Progress-$ongoing-yellow?style=flat-square)
![Done](https://img.shields.io/badge/Done-$done-green?style=flat-square)
![Project Completion](https://img.shields.io/badge/${completion_pct}%25-${project_color}?style=for-the-badge&logo=github&logoColor=white)

EOF
done

cat >> metrics.tmp << EOF
---

EOF

echo "_Last updated: $(date -u +'%Y-%m-%d %H:%M UTC')_" >> metrics.tmp