#!/bin/bash
# markitdown plugin - installed check command
set -euo pipefail
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_MARKITDOWN="$PLUGIN_DIR/.venv/bin/markitdown"
if [ -x "$VENV_MARKITDOWN" ]; then
  jq -n '{"installed": true}'
else
  jq -n '{"installed": false}'
fi
