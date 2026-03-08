#!/bin/bash
# markitdown plugin - install command
set -euo pipefail
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PLUGIN_DIR/.venv"
if python3 -m venv "$VENV_DIR" >/dev/null 2>&1 && \
   "$VENV_DIR/bin/pip" install 'markitdown[pptx,docx,xlsx,xls]' >/dev/null 2>&1; then
  jq -n '{"success": true, "message": "markitdown installed successfully."}'
else
  jq -n '{"success": false, "message": "Failed to install markitdown."}'
fi
