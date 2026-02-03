#!/usr/bin/env bash
set -euo pipefail

# Source common language utilities
source "$(dirname "$0")/language-utils.sh"

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
  no_status=$(echo "$project_json" | jq -r '.no_status')
  total=$((todo + ongoing + done + no_status))
  
  if [[ $total -gt 0 ]]; then
    completion_pct=$((done * 100 / total))
  else
    completion_pct=0
  fi
  
  # Determine project completion color
  if [[ $total -eq 0 ]]; then
    project_color="brightgreen"
    completion_display="0%25%20(clean)"
  elif [[ $completion_pct -ge 80 ]]; then
    project_color="brightgreen"
    completion_display="${completion_pct}%25"
  elif [[ $completion_pct -ge 50 ]]; then
    project_color="yellow"
    completion_display="${completion_pct}%25"
  elif [[ $completion_pct -ge 25 ]]; then
    project_color="orange"
    completion_display="${completion_pct}%25"
  else
    project_color="red"
    completion_display="${completion_pct}%25"
  fi
  
  # Get project languages with debugging
  languages_json=$(echo "$project_json" | jq '.languages // []')
  echo "DEBUG: Languages JSON for $project: $languages_json" >&2
  languages=$(echo "$project_json" | jq -r '.languages // [] | map(.language) | join(", ")')
  echo "DEBUG: Languages string for $project: $languages" >&2
  
  # Add project metrics
  cat >> project-breakdown.tmp << EOF
### 🚀 $project
![Todo](https://img.shields.io/badge/Todo-$todo-blue?style=for-the-badge)
![In Progress](https://img.shields.io/badge/In%20Progress-$ongoing-yellow?style=for-the-badge)
![Done](https://img.shields.io/badge/Done-$done-green?style=for-the-badge)
![No Status](https://img.shields.io/badge/No%20Status-$no_status-grey?style=for-the-badge)
![Project Completion](https://img.shields.io/badge/Completion-${completion_display}-${project_color}?style=for-the-badge&logo=github&logoColor=white)

EOF

  # Add languages if they exist
  if [[ "$languages" != "null" && "$languages" != "" ]]; then
    # Create language badges using common function
    generate_language_badges "$languages" "flat-square" >> project-breakdown.tmp
    
    cat >> project-breakdown.tmp << EOF

EOF
  else
    echo "DEBUG: No languages found for $project" >&2
  fi
done

cat >> project-breakdown.tmp << EOF
---

EOF