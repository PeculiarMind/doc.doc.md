#!/bin/bash
# crm114 plugin - installed check
# Checks if CRM114 tools are available on the system.
# Only the `crm` binary is required (standalone css-learn/css-unlearn replaced
# by crm -e).
# Output: JSON {"installed": true/false} to stdout
# Exit code: always 0 (reporting status, not failing)

if command -v crm >/dev/null 2>&1; then
  jq -n '{installed: true}'
else
  jq -n '{installed: false}'
fi

exit 0
