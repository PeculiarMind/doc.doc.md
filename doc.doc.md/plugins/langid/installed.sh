#!/bin/bash
# langid plugin - installed check
# Checks if the langid Python package is importable.
# Output: JSON {"installed": true/false} to stdout
# Exit code: always 0 (reporting status, not failing)

if python3 -c "import langid" >/dev/null 2>&1; then
  jq -n '{installed: true}'
else
  jq -n '{installed: false}'
fi

exit 0
