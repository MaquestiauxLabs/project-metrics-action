#!/usr/bin/env bash
set -euo pipefail

echo "| Project | Todo | Ongoing | Done |" > table.tmp
echo "| :--- | :---: | :---: | :---: |" >> table.tmp

jq -r '.[] |
  "| \(.project) | \(.todo) | \(.ongoing) | \(.done) |"
' all-projects-summary.json >> table.tmp

echo >> table.tmp
echo "_Last updated: $(date -u +'%Y-%m-%d %H:%M UTC')_" >> table.tmp
