#!/usr/bin/env bash
set -euo pipefail

# Source common language utilities
source "$(dirname "$0")/language-utils.sh"

# Generate language statistics section
if [[ -f "language-stats.json" ]]; then
  cat > languages.tmp << EOF
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
    
    # Create language badge using common function
    badge_url=$(generate_language_badge "$lang" "for-the-badge" "$percentage")
    cat >> languages.tmp << EOF
![${lang}](${badge_url}) 
EOF
  done

  cat >> languages.tmp << EOF
---

EOF
fi