#!/bin/bash
# markitdown plugin - install command
set -euo pipefail
if pip install markitdown 2>&1; then
  jq -n '{"success": true, "message": "markitdown installed successfully."}'
else
  jq -n '{"success": false, "message": "Failed to install markitdown."}'
fi
