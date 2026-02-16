#!/usr/bin/env bash
set -euo pipefail

DATA_PATH="${1:-../data/projects.json}"
TEMPLATE_PATH="${2:-../sample-README.md}"
OUTPUT_PATH="${3:-../README.md}"

if [[ ! -f "$DATA_PATH" ]]; then
    echo "Data file not found: $DATA_PATH" >&2
    exit 1
fi

if [[ ! -f "$TEMPLATE_PATH" ]]; then
    echo "Template file not found: $TEMPLATE_PATH" >&2
    exit 1
fi

get_completion_color() {
    local rate="$1"
    if [[ $rate -ge 80 ]]; then
        echo "green"
    elif [[ $rate -ge 50 ]]; then
        echo "yellow"
    elif [[ $rate -gt 0 ]]; then
        echo "orange"
    else
        echo "lightgrey"
    fi
}

get_lang_color() {
    local percent="$1"
    if [[ $percent -ge 95 ]]; then
        echo "brightgreen"
    elif [[ $percent -ge 90 ]]; then
        echo "green"
    elif [[ $percent -ge 85 ]]; then
        echo "yellowgreen"
    elif [[ $percent -ge 80 ]]; then
        echo "teal"
    elif [[ $percent -ge 75 ]]; then
        echo "blue"
    elif [[ $percent -ge 70 ]]; then
        echo "blueviolet"
    elif [[ $percent -ge 65 ]]; then
        echo "violet"
    elif [[ $percent -ge 60 ]]; then
        echo "purple"
    elif [[ $percent -ge 55 ]]; then
        echo "magenta"
    elif [[ $percent -ge 50 ]]; then
        echo "pink"
    elif [[ $percent -ge 45 ]]; then
        echo "red"
    elif [[ $percent -ge 40 ]]; then
        echo "orange"
    elif [[ $percent -ge 35 ]]; then
        echo "yellow"
    elif [[ $percent -ge 30 ]]; then
        echo "greenyellow"
    elif [[ $percent -ge 25 ]]; then
        echo "chartreuse"
    elif [[ $percent -ge 20 ]]; then
        echo "lime"
    elif [[ $percent -ge 15 ]]; then
        echo "aqua"
    elif [[ $percent -ge 10 ]]; then
        echo "cyan"
    elif [[ $percent -ge 5 ]]; then
        echo "grey"
    elif [[ $percent -gt 0 ]]; then
        echo "lightgrey"
    else
        echo "white"
    fi
}

generate_badge() {
    local label="$1"
    local value="$2"
    local color="$3"
    local url="https://img.shields.io/badge/${label}-${value}-${color}?style=for-the-badge"
    echo "![${label}]($url)"
}

ORG_NAME=$(jq -r '.organisationName // ""' "$DATA_PATH")
ORG_DESC=$(jq -r '.organisationDescription // ""' "$DATA_PATH")

GLOBAL_OVERVIEW="## 📊 Overview

"

total=$(jq '[.projects[].statusCounts.Total // 0] | add' "$DATA_PATH")
done_count=$(jq '[.projects[].statusCounts.Done // 0] | add' "$DATA_PATH")
in_progress=$(jq '[.projects[].statusCounts."In Progress" // 0] | add' "$DATA_PATH")
todo=$(jq '[.projects[].statusCounts.Todo // 0] | add' "$DATA_PATH")

if [[ $total -gt 0 ]]; then
    completion=$((done_count * 100 / total))
else
    completion=0
fi

completion_color="lightgrey"
if [[ $completion -ge 80 ]]; then completion_color="green"
elif [[ $completion -ge 50 ]]; then completion_color="yellow"
elif [[ $completion -gt 0 ]]; then completion_color="orange"
fi

GLOBAL_OVERVIEW+="![Total](https://img.shields.io/badge/Total-$total-blue?style=for-the-badge) "
GLOBAL_OVERVIEW+="![Done](https://img.shields.io/badge/Done-$done_count-green?style=for-the-badge) "
GLOBAL_OVERVIEW+="![In Progress](https://img.shields.io/badge/In%20Progress-$in_progress-yellow?style=for-the-badge) "
GLOBAL_OVERVIEW+="![Todo](https://img.shields.io/badge/Todo-$todo-red?style=for-the-badge)
"
GLOBAL_OVERVIEW+="![Completion](https://img.shields.io/badge/Completion-$completion%25-$completion_color?style=for-the-badge)"

PROJECT_BREAKDOWN=""

while read -r title; do
    read -r total; read -r done; read -r inProgress; read -r todo; read -r rate
    
    completion_color="lightgrey"
    if [[ $rate -ge 80 ]]; then completion_color="green"; elif [[ $rate -ge 50 ]]; then completion_color="yellow"; elif [[ $rate -gt 0 ]]; then completion_color="orange"; fi
    
    PROJECT_BREAKDOWN+="### 🚀 $title
"
    PROJECT_BREAKDOWN+="![Total](https://img.shields.io/badge/Total-$total-blue?style=for-the-badge) "
    PROJECT_BREAKDOWN+="![Done](https://img.shields.io/badge/Done-$done-green?style=for-the-badge) "
    PROJECT_BREAKDOWN+="![In Progress](https://img.shields.io/badge/In%20Progress-$inProgress-yellow?style=for-the-badge) "
    PROJECT_BREAKDOWN+="![Todo](https://img.shields.io/badge/Todo-$todo-red?style=for-the-badge)
"
    PROJECT_BREAKDOWN+="![Completion](https://img.shields.io/badge/Completion-$rate%25-$completion_color?style=for-the-badge)

"

    languages=$(jq -r --arg title "$title" '
        .projects[] | select(.title == $title) | .repositories.nodes[].languages.edges
        | map({name: .node.name, size: .size})
        | (map(.size) | add) as $total
        | map(. + {percent: (if $total > 0 then ((.size * 100 / $total) | floor) else 0 end)})
        | sort_by(.percent) | reverse
    ' "$DATA_PATH" 2>/dev/null)

    if [[ -n "$languages" && "$languages" != "null" ]]; then
        lang_lines=""
        while IFS= read -r lang_entry; do
            [[ -z "$lang_entry" || "$lang_entry" == "null" ]] && continue
            lang=$(echo "$lang_entry" | jq -r '.name')
            percent=$(echo "$lang_entry" | jq -r '.percent')
            lang_lower=$(echo "$lang" | tr '[:upper:]' '[:lower:]')
            lang_color=$(get_lang_color "$percent")
            lang_lines+="![$lang $percent%](https://img.shields.io/badge/$lang-$percent%25-$lang_color?style=flat-square&logo=$lang_lower&logoColor=white) "
        done <<< "$(echo "$languages" | jq -c '.[]' 2>/dev/null)"
        if [[ -n "$lang_lines" ]]; then
            PROJECT_BREAKDOWN+="$lang_lines
"
        fi
    fi
done < <(jq -r '.projects[] | .statusCounts as $sc | .title as $title | 
  ($sc.Total // 0) as $total |
  ($sc.Done // 0) as $done |
  ($sc.Todo // 0) as $todo |
  ($sc."In Progress" // 0) as $inProgress |
  (if $total > 0 then (($done * 100 / $total) | floor) else 0 end) as $rate |
  $title, $total, $done, $inProgress, $todo, $rate
' "$DATA_PATH")

PROJECT_BREAKDOWN="## 📋 Project Status

${PROJECT_BREAKDOWN}"

LAST_UPDATED="Updated on $(date -u +'%Y-%m-%d %H:%M UTC')"

cp "$TEMPLATE_PATH" "$OUTPUT_PATH"

awk -v orgName="$ORG_NAME" '
/<!-- ORGANISATION_NAME:START -->/ { print; print "# " orgName; skip=1; next }
/<!-- ORGANISATION_NAME:END -->/ { if (skip) { print; skip=0; next }; print }
{ if (!skip) print }
' "$OUTPUT_PATH" > tmp && mv tmp "$OUTPUT_PATH"

awk -v orgDesc="$ORG_DESC" '
/<!-- ORGANISATION_DESCRIPTION:START -->/ { print; print "🚀 " orgDesc; skip=1; next }
/<!-- ORGANISATION_DESCRIPTION:END -->/ { if (skip) { print; skip=0; next }; print }
{ if (!skip) print }
' "$OUTPUT_PATH" > tmp && mv tmp "$OUTPUT_PATH"

awk -v content="$GLOBAL_OVERVIEW" '
/<!-- GLOBAL_OVERVIEW:START -->/ { print; print content; skip=1; next }
/<!-- GLOBAL_OVERVIEW:END -->/ { if (skip) { print; skip=0; next }; print }
{ if (!skip) print }
' "$OUTPUT_PATH" > tmp && mv tmp "$OUTPUT_PATH"

awk -v content="$PROJECT_BREAKDOWN" '
/<!-- PROJECT_BREAKDOWN:START -->/ { print; print content; skip=1; next }
/<!-- PROJECT_BREAKDOWN:END -->/ { if (skip) { print; skip=0; next }; print }
{ if (!skip) print }
' "$OUTPUT_PATH" > tmp && mv tmp "$OUTPUT_PATH"

awk -v content="$LAST_UPDATED" '
/<!-- LAST_UPDATED:START -->/ { print; print content; skip=1; next }
/<!-- LAST_UPDATED:END -->/ { if (skip) { print; skip=0; next }; print }
{ if (!skip) print }
' "$OUTPUT_PATH" > tmp && mv tmp "$OUTPUT_PATH"

echo "Updated $OUTPUT_PATH"
