#!/bin/bash
# crm114 plugin - install command
# Attempts to install the CRM114 Discriminator tools.
# Output: JSON {"success": bool, "message": string} to stdout
# Exit code: 0 on success, 1 if installation fails

if command -v crm >/dev/null 2>&1 || command -v cssutil >/dev/null 2>&1; then
  jq -n '{success: true, message: "CRM114 tools already available"}'
  exit 0
fi

# Attempt installation via apt (Debian/Ubuntu)
if command -v apt-get >/dev/null 2>&1; then
  if apt-get install -y crm114 >/dev/null 2>&1; then
    jq -n '{success: true, message: "CRM114 installed via apt"}'
    exit 0
  fi
fi

jq -n '{success: false, message: "CRM114 is not available. Install via: apt install crm114 (Debian/Ubuntu) or brew install crm114 (macOS)"}'
exit 1
