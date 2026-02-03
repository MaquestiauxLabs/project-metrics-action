#!/usr/bin/env bash
set -euo pipefail

PROJECTS_JSON="all-projects-summary.json"
REPOS_JSON="all-repos-summary.json"

# Generate markdown-friendly metrics
cat > metrics.tmp << 'EOF'
## 📊 Project Overview
EOF

# Generate project cards
cat >> metrics.tmp << 'EOF'
<div class="metrics-container">
<h3>📊 Project Overview</h3>
EOF

# First check if the JSON is valid
if ! jq empty "$PROJECTS_JSON" 2>/dev/null; then
  echo "ERROR: Invalid JSON in $PROJECTS_JSON" >&2
  exit 1
fi

# Process each project using a safer approach
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
  
  completion_width=$(echo "$completion_pct * 0.8" | bc -l 2>/dev/null || echo "0")

    cat >> metrics.tmp << EOF
### 🚀 $project

| Todo | In Progress | Done |
|:----:|:-----------:|:----:|
| **$todo** | **$ongoing** | **$done** |

<div class="progress-bar">
<div class="progress-fill" style="width: ${completion_width}%"></div>
</div>

*${total} items • ${completion_pct}% complete*

EOF
done

# Repository section temporarily disabled
# Will be re-enabled when repository collection is fixed

echo "_Last updated: $(date -u +'%Y-%m-%d %H:%M UTC')_" >> metrics.tmp