#!/bin/bash
# langid plugin - installed check
# Checks if the langid Python package is importable in the plugin venv.
# Output: JSON {"installed": true/false} to stdout
# Exit code: always 0 (reporting status, not failing)
set -euo pipefail
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PYTHON="$PLUGIN_DIR/.venv/bin/python3"

if [ -x "$VENV_PYTHON" ] && "$VENV_PYTHON" -c "import langid" >/dev/null 2>&1; then
  jq -n '{"installed": true}'
else
  jq -n '{"installed": false}'
fi

exit 0
