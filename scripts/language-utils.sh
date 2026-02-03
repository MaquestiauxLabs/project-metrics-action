#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# LANGUAGE UTILITIES
# =============================================================================

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

# =============================================================================
# STATUS UTILITIES
# =============================================================================

# Get status color and icon based on status name
# Usage: get_status_info "Todo" -> "blue" "todoist"
get_status_info() {
  local status="$1"
  local color=""
  local logo=""
  
  case "$status" in
    "Todo") color="blue"; logo="todoist" ;;
    "In Progress") color="yellow"; logo="gitlab" ;;
    "Done") color="green"; logo="checkmarx" ;;
    "No Status") color="grey"; logo="help" ;;
  esac
  
  echo "$color $logo"
}

# Generate status badge URL
# Usage: generate_status_badge "Todo" 5 "for-the-badge" -> "https://img.shields.io/badge/Todo-5-blue?style=for-the-badge&logo=todoist&logoColor=white"
generate_status_badge() {
  local status="$1"
  local count="$2"
  local style="${3:-"for-the-badge"}"
  local include_logo="${4:-"true"}"
  
  # URL encode spaces
  local status_encoded="${status// /%20}"
  
  local status_info
  status_info=$(get_status_info "$status")
  local color=$(echo "$status_info" | cut -d' ' -f1)
  local logo=$(echo "$status_info" | cut -d' ' -f2)
  
  local url="https://img.shields.io/badge/${status_encoded}-${count}-${color}?style=${style}"
  
  if [[ "$include_logo" == "true" ]]; then
    url="${url}&logo=${logo}&logoColor=white"
  fi
  
  echo "$url"
}

# Generate status badges for all four statuses
# Usage: generate_all_status_badges 5 3 10 2 "for-the-badge" -> returns badge URLs for Todo, In Progress, Done, No Status
generate_all_status_badges() {
  local todo="$1"
  local ongoing="$2"
  local done="$3"
  local no_status="$4"
  local style="${5:-"for-the-badge"}"
  local include_logo="${6:-"true"}"
  
  echo "![Todo]($(generate_status_badge "Todo" "$todo" "$style" "$include_logo")) "
  echo "![In Progress]($(generate_status_badge "In Progress" "$ongoing" "$style" "$include_logo")) "
  echo "![Done]($(generate_status_badge "Done" "$done" "$style" "$include_logo")) "
  if [[ "$no_status" -gt 0 ]] || [[ "$include_logo" == "true" ]]; then
    echo "![No Status]($(generate_status_badge "No Status" "$no_status" "$style" "$include_logo")) "
  fi
}

# =============================================================================
# COMPLETION UTILITIES
# =============================================================================

# Get completion color based on completion percentage
# Usage: get_completion_color 85 -> "brightgreen"
get_completion_color() {
  local completion_rate="$1"
  local color="red"
  
  if [[ $completion_rate -ge 80 ]]; then
    color="brightgreen"
  elif [[ $completion_rate -ge 50 ]]; then
    color="yellow"
  elif [[ $completion_rate -ge 25 ]]; then
    color="orange"
  fi
  
  echo "$color"
}

# Generate completion badge URL
# Usage: generate_completion_badge 85 "for-the-badge" -> "https://img.shields.io/badge/Completion-85%25-brightgreen?style=for-the-badge&logo=github&logoColor=white"
generate_completion_badge() {
  local completion_rate="$1"
  local style="${2:-"for-the-badge"}"
  local include_logo="${3:-"true"}"
  
  local color
  color=$(get_completion_color "$completion_rate")
  
  local display_text="${completion_rate}%25"
  if [[ $completion_rate -eq 0 ]]; then
    display_text="0%25%20(clean)"
  fi
  
  local url="https://img.shields.io/badge/Completion-${display_text}-${color}?style=${style}"
  
  if [[ "$include_logo" == "true" ]]; then
    url="${url}&logo=github&logoColor=white"
  fi
  
  echo "$url"
}