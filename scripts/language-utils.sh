#!/usr/bin/env bash
set -euo pipefail

# Get language color based on language name
# Usage: get_language_color "JavaScript"
get_language_color() {
  local lang="$1"
  local lang_color="grey"
  
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
  
  echo "$lang_color"
}

# Generate language badge URL
# Usage: generate_language_badge "JavaScript" "flat-square" -> "https://img.shields.io/badge/JavaScript-yellow?style=flat-square&logo=javascript&logoColor=white"
generate_language_badge() {
  local lang="$1"
  local style="${2:-"flat-square"}"
  local percentage="${3:-""}"
  local lang_color
  lang_color=$(get_language_color "$lang")
  
  if [[ -n "$percentage" ]]; then
    echo "https://img.shields.io/badge/${lang}-${percentage}%25-${lang_color}?style=${style}"
  else
    echo "https://img.shields.io/badge/${lang}-${lang_color}?style=${style}&logo=${lang,,}&logoColor=white"
  fi
}

# Generate language badges from a comma-separated list
# Usage: generate_language_badges "JavaScript, Python, TypeScript" "flat-square"
generate_language_badges() {
  local languages="$1"
  local style="${2:-"flat-square"}"
  local percentage="${3:-""}"
  
  if [[ "$languages" != "null" && "$languages" != "" ]]; then
    echo "$languages" | tr ',' '\n' | while read -r lang; do
      lang=$(echo "$lang" | xargs) # trim whitespace
      if [[ -n "$lang" ]]; then
        local badge_url
        badge_url=$(generate_language_badge "$lang" "$style" "$percentage")
        echo "![${lang}](${badge_url}) "
      fi
    done
  fi
}