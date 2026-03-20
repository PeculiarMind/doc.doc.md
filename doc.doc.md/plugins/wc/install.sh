#!/bin/bash
# wc plugin - install command
# wc is part of GNU coreutils and requires no installation.
# Output: JSON {"success": bool, "message": string} to stdout

if command -v wc >/dev/null 2>&1; then
  jq -n '{success: true, message: "wc is part of GNU coreutils and is already available."}'
  exit 0
else
  jq -n '{success: false, message: "wc is not available. It is part of GNU coreutils — please install coreutils for your platform."}'
  exit 1
fi
