#!/usr/bin/env bash
set -euo pipefail

PROJECTS_JSON="all-projects-summary.json"

# Generate cool badges-based metrics
cat > metrics.tmp << 'EOF'
## 📊 Project Dashboard

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
  
  # URL encode project name for shields.io
  project_encoded=$(echo "$project" | sed 's/ /%20/g' | sed 's/(/%28/g' | sed 's/)/%29/g' | sed 's/\//%2F/g')
  
  # Create project header with completion badge
  completion_color="red"
  if [[ $completion_pct -ge 80 ]]; then
    completion_color="brightgreen"
  elif [[ $completion_pct -ge 50 ]]; then
    completion_color="yellow"
  elif [[ $completion_pct -ge 25 ]]; then
    completion_color="orange"
  fi
  
  cat >> metrics.tmp << EOF

### 🚀 $project

![Project Completion](https://img.shields.io/badge/Progress-${completion_pct}%25-${completion_color}?style=for-the-badge)

---

**📋 Task Overview**

![Todo](https://img.shields.io/badge/Todo-$todo-blue?style=flat-square) ![In Progress](https://img.shields.io/badge/In%20Progress-$ongoing-yellow?style=flat-square) ![Done](https://img.shields.io/badge/Done-$done-green?style=flat-square)

EOF

  # Add progress bar using shields.io
  if [[ $completion_pct -gt 0 ]]; then
    # Create custom progress bar
    progress_url="https://img.shields.io/badge/Progress-${completion_pct}%25-${completion_color}?style=for-the-badge&logo=github&logoColor=white"
    cat >> metrics.tmp << EOF

**📈 Progress Tracker**

![Progress](https://progress-bar.dev/${completion_pct}/?title=Completed&width=600&color=brightgreen&suffix=%25)

EOF
  fi
  
  # Add activity badges
  activity_level="Low"
  activity_color="grey"
  if [[ $ongoing -gt 3 ]]; then
    activity_level="High"
    activity_color="brightgreen"
  elif [[ $ongoing -gt 1 ]]; then
    activity_level="Medium"
    activity_color="yellow"
  elif [[ $ongoing -gt 0 ]]; then
    activity_level="Low"
    activity_color="orange"
  fi
  
  cat >> metrics.tmp << EOF
**🔥 Activity Level**

![Activity](https://img.shields.io/badge/Activity-${activity_level}-${activity_color}?style=flat-square)

EOF

  # Add summary stats
  cat >> metrics.tmp << EOF
| Metric | Count | Status |
|--------|-------|--------|
| Total Tasks | **$total** | 📊 |
| Completion Rate | **${completion_pct}%** | $([[ $completion_pct -eq 100 ]] && echo "✅ Perfect!" || ([[ $completion_pct -ge 75 ]] && echo "🟢 Great!" || ([[ $completion_pct -ge 50 ]] && echo "🟡 Good" || echo "🔴 Needs Work"))) |
| Active Work | **$ongoing** | $([[ $ongoing -eq 0 ]] && echo "😴 Idle" || ([[ $ongoing -le 2 ]] && echo "🚀 Steady" || echo "🔥 Very Active")) |

EOF

  # Add separator
  cat >> metrics.tmp << EOF
---
EOF
done

cat >> metrics.tmp << EOF

## 🎯 Overall Summary

EOF

# Calculate overall stats
total_todo=$(jq '[.[].todo] | add' "$PROJECTS_JSON")
total_ongoing=$(jq '[.[].ongoing] | add' "$PROJECTS_JSON")
total_done=$(jq '[.[].done] | add' "$PROJECTS_JSON")
total_projects=$(jq 'length' "$PROJECTS_JSON")
total_items=$((total_todo + total_ongoing + total_done))

if [[ $total_items -gt 0 ]]; then
  overall_completion=$((total_done * 100 / total_items))
else
  overall_completion=0
fi

# Overall completion color
overall_color="red"
if [[ $overall_completion -ge 80 ]]; then
  overall_color="brightgreen"
elif [[ $overall_completion -ge 50 ]]; then
  overall_color="yellow"
elif [[ $overall_completion -ge 25 ]]; then
  overall_color="orange"
fi

cat >> metrics.tmp << EOF

![Total Projects](https://img.shields.io/badge/Projects-$total_projects-blue?style=for-the-badge) ![Overall Completion](https://img.shields.io/badge/Completion-${overall_completion}%25-${overall_color}?style=for-the-badge)

---

EOF

echo "_Last updated: $(date -u +'%Y-%m-%d %H:%M UTC')_ Generated with 🤖 by MaquestiauxLabs/project-metrics-action_" >> metrics.tmp