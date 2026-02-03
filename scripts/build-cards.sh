#!/usr/bin/env bash
set -euo pipefail

PROJECTS_JSON="all-projects-summary.json"
REPOS_JSON="all-repos-summary.json"

# Debug: Print JSON structure
echo "=== DEBUG: Projects JSON structure ===" >&2
cat "$PROJECTS_JSON" >&2
echo "=== END DEBUG ===" >&2

# Generate CSS for cards
cat > metrics.tmp << 'EOF'
<style>
.metrics-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 20px;
  margin: 20px 0;
}
.project-card, .repo-card {
  border: 1px solid #e1e4e8;
  border-radius: 8px;
  padding: 16px;
  background: #fff;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}
.project-card {
  border-left: 4px solid #0969da;
}
.repo-card {
  border-left: 4px solid #2ea043;
}
.card-title {
  font-weight: 600;
  font-size: 1.1em;
  margin-bottom: 12px;
  color: #24292f;
}
.repo-title {
  font-size: 0.9em;
  color: #656d76;
}
.stats-row {
  display: flex;
  justify-content: space-between;
  margin: 8px 0;
  align-items: center;
}
.stat-item {
  text-align: center;
  flex: 1;
}
.stat-number {
  font-size: 1.2em;
  font-weight: 600;
  color: #0969da;
}
.stat-label {
  font-size: 0.8em;
  color: #656d76;
}
.progress-bar {
  width: 100%;
  height: 6px;
  background: #e1e4e8;
  border-radius: 3px;
  margin: 8px 0;
  overflow: hidden;
}
.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #f778ba, #0969da, #2ea043);
  transition: width 0.3s ease;
}
.repo-stats {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
  margin-top: 8px;
}
.repo-stat {
  font-size: 0.85em;
}
.repo-stat-value {
  font-weight: 600;
  color: #0969da;
}
</style>

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

jq -r '.[] | 
  "\(.project)" |
  "\(.todo)" |
  "\(.ongoing)" |
  "\(.done)" |
  "\(.todo + .ongoing + .done)" |
  if (.todo + .ongoing + .done) > 0 then (.done / (.todo + .ongoing + .done) * 100) else 0 end' \
  "$PROJECTS_JSON" | while IFS=$'\n' read -r project; do
    read todo
    read ongoing
    read done
    read total
    read completion_pct
    completion_width=$(echo "$completion_pct * 0.8" | bc -l 2>/dev/null || echo "0")

    cat >> metrics.tmp << EOF
<div class="project-card">
<div class="card-title">🚀 $project</div>
<div class="stats-row">
  <div class="stat-item">
    <div class="stat-number">$todo</div>
    <div class="stat-label">Todo</div>
  </div>
  <div class="stat-item">
    <div class="stat-number">$ongoing</div>
    <div class="stat-label">In Progress</div>
  </div>
  <div class="stat-item">
    <div class="stat-number">$done</div>
    <div class="stat-label">Done</div>
  </div>
</div>
<div class="progress-bar">
  <div class="progress-fill" style="width: ${completion_width}%"></div>
</div>
<div style="text-align: center; font-size: 0.8em; color: #656d76;">
  ${total} items • ${completion_pct}% complete
</div>
</div>
EOF
  done

# Repository section temporarily disabled
# Will be re-enabled when repository collection is fixed

echo "_Last updated: $(date -u +'%Y-%m-%d %H:%M UTC')_" >> metrics.tmp