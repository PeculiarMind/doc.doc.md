#!/bin/bash
# crm114 plugin - install command
# Attempts to install crm114 via the system package manager.
# Output: JSON {"success": bool, "message": string} to stdout
# Exit code: 0 on success or already installed, 1 if installation fails

if command -v csslearn >/dev/null 2>&1 && \
   command -v cssunlearn >/dev/null 2>&1 && \
   command -v crmclassify >/dev/null 2>&1; then
  jq -n '{success: true, message: "crm114 tools are already installed"}'
  exit 0
fi

# Try apt-get (Debian/Ubuntu)
if command -v apt-get >/dev/null 2>&1; then
  if apt-get install -y crm114 >/dev/null 2>&1; then
    jq -n '{success: true, message: "crm114 installed successfully via apt-get"}'
    exit 0
  fi
fi

# Try brew (macOS)
if command -v brew >/dev/null 2>&1; then
  if brew install crm114 >/dev/null 2>&1; then
    jq -n '{success: true, message: "crm114 installed successfully via brew"}'
    exit 0
  fi
fi

jq -n '{success: false, message: "crm114 could not be installed automatically. Install manually: apt install crm114 (Debian/Ubuntu) or brew install crm114 (macOS)."}'
exit 1
