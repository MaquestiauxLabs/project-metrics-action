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
  
  # Get project languages with debugging
  languages_json=$(echo "$project_json" | jq '.languages // []')
  echo "DEBUG: Languages JSON for $project: $languages_json" >&2
  languages=$(echo "$project_json" | jq -r '.languages // [] | map(.language) | join(", ")')
  echo "DEBUG: Languages string for $project: $languages" >&2
  
  # Add project metrics using common utilities
  cat >> project-breakdown.tmp << EOF
### 🚀 $project
$(generate_all_status_badges "$todo" "$ongoing" "$done" "$no_status" "for-the-badge" "true")
![Project Completion]($(generate_completion_badge "$completion_pct" "for-the-badge" "true"))

EOF

  # Add languages if they exist
  if [[ "$languages" != "null" && "$languages" != "" ]]; then
    # Create language badges using common function
    generate_language_badges "$languages" "flat-square" "true">> project-breakdown.tmp
    
    cat >> project-breakdown.tmp << EOF

EOF
  else
    echo "DEBUG: No languages found for $project" >&2
  fi
done

cat >> project-breakdown.tmp << EOF
---

EOF