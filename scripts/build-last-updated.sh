#!/usr/bin/env bash
set -euo pipefail

# Generate last updated section
cat > last-updated.tmp << EOF

_Last updated: $(date -u +'%Y-%m-%d %H:%M UTC')_
EOF