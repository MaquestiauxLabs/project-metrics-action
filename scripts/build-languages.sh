#!/usr/bin/env bash
set -euo pipefail

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
    cat >> languages.tmp << EOF
![${lang}](https://img.shields.io/badge/${lang}-${percentage}%25-${lang_color}?style=flat-square) 
EOF
  done

  cat >> languages.tmp << EOF
---

EOF
fi