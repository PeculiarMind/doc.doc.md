#!/bin/bash
# crm114 plugin - installed check
# Checks if crm114 and required CRM114 tools are available on PATH.
# Output: JSON {"installed": true/false} to stdout
# Exit code: always 0 (reporting status, not failing)

if command -v csslearn >/dev/null 2>&1 && \
   command -v cssunlearn >/dev/null 2>&1 && \
   command -v crmclassify >/dev/null 2>&1; then
  jq -n '{installed: true}'
else
  jq -n '{installed: false}'
fi

exit 0
