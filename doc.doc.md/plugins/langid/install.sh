#!/bin/bash
# langid plugin - install command
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PLUGIN_DIR/.venv"
if python3 -m venv "$VENV_DIR" >/dev/null 2>&1 && \
   "$VENV_DIR/bin/pip" install langid >/dev/null 2>&1; then
  jq -n '{"success": true, "message": "langid installed successfully."}'
else
  jq -n '{"success": false, "message": "Failed to install langid."}'
fi
