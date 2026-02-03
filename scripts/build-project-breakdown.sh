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
  
  # Get project languages
  languages=$(echo "$project_json" | jq -r '.languages // [] | map(.language) | join(", ")')
  
  # Add project metrics
  cat >> project-breakdown.tmp << EOF
### 🚀 $project
![Todo](https://img.shields.io/badge/Todo-$todo-blue?style=for-the-badge)
![In Progress](https://img.shields.io/badge/In%20Progress-$ongoing-yellow?style=for-the-badge)
![Done](https://img.shields.io/badge/Done-$done-green?style=for-the-badge)
![Project Completion](https://img.shields.io/badge/${completion_pct}%25-${project_color}?style=for-the-badge&logo=github&logoColor=white)

EOF

  # Add languages if they exist
  if [[ "$languages" != "null" && "$languages" != "" ]]; then
    # Create language badges
    echo "$languages" | tr ',' '\n' | while read -r lang; do
      lang=$(echo "$lang" | xargs) # trim whitespace
      
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
      
      cat >> project-breakdown.tmp << EOF
![${lang}](https://img.shields.io/badge/${lang}-${lang_color}?style=flat-square&logo=${lang,,}&logoColor=white) 
EOF
    done
    
    cat >> project-breakdown.tmp << EOF

EOF
  fi
done

cat >> project-breakdown.tmp << EOF
---

EOF