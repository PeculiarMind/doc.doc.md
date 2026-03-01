#!/bin/bash
# file plugin - installed check
# Checks if the 'file' command is available on the system.
# Output: JSON {"installed": true/false} to stdout
# Exit code: always 0 (reporting status, not failing)

if command -v file >/dev/null 2>&1; then
  jq -n '{installed: true}'
else
  jq -n '{installed: false}'
fi

exit 0