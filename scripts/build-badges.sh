#!/usr/bin/env bash
set -euo pipefail

# Source common utilities
source "$(dirname "$0")/language-utils.sh"

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

# Generate compact global overview using common utilities
cat > metrics.tmp << EOF
## 📊 MaquestiauxLabs Metrics

$(generate_all_status_badges "$total_todo" "$total_ongoing" "$total_done" "0" "for-the-badge" "true")
![Completion Rate]($(generate_completion_badge "$completion_rate" "for-the-badge" "true"))

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
![Todo](https://img.shields.io/badge/Todo-$todo-blue?style=for-the-badge)
![In Progress](https://img.shields.io/badge/In%20Progress-$ongoing-yellow?style=for-the-badge)
![Done](https://img.shields.io/badge/Done-$done-green?style=for-the-badge)
![Project Completion](https://img.shields.io/badge/${completion_pct}%25-${project_color}?style=for-the-badge&logo=github&logoColor=white)

EOF
done

# Add language statistics section
if [[ -f "language-stats.json" ]]; then
  cat >> metrics.tmp << EOF
## 💻 Programming Languages

EOF

  # Get top languages (top 8)
  jq -r '.[:8] | .[] | "\(.language) \(.total_bytes)"' language-stats.json | while read -r lang bytes; do
    # Calculate percentage (need total bytes)
    total_bytes=$(jq '[.[].total_bytes] | add' language-stats.json)
    if [[ $total_bytes -gt 0 ]]; then
      percentage=$((bytes * 100 / total_bytes))
    else
      percentage=0
    fi
    
    # Language colors
    lang_color="grey"
    case "$lang" in
      "JavaScript") lang_color="yellow" ;;
      "TypeScript") lang_color="blue" ;;
      "Python") lang_color="green" ;;
      "Java") lang_color="orange" ;;
      "Go") lang_color="cyan" ;;
      "Rust") lang_color="red" ;;
      "C++") lang_color="blue" ;;
      "HTML") lang_color="orange" ;;
      "CSS") lang_color="purple" ;;
      "Shell") lang_color="green" ;;
    esac
    
    # Create language badge
    cat >> metrics.tmp << EOF
![${lang}](https://img.shields.io/badge/${lang}-${percentage}%25-${lang_color}?style=flat-square) 
EOF
  done
fi

cat >> metrics.tmp << EOF
---

EOF

echo "_Last updated: $(date -u +'%Y-%m-%d %H:%M UTC')_" >> metrics.tmp