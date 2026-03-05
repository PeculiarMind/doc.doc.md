#!/bin/bash
# markitdown plugin - installed check command
set -euo pipefail
if command -v markitdown >/dev/null 2>&1; then
  jq -n '{"installed": true}'
else
  jq -n '{"installed": false}'
fi
