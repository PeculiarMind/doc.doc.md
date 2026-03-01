#!/bin/bash
# file plugin - install command
# Checks if the 'file' command is available and reports status.
# file is typically pre-installed on Unix systems.
# Output: JSON {"success": bool, "message": string} to stdout
# Exit code: 0 on success, 1 if installation needed but can't be done

if command -v file >/dev/null 2>&1; then
  jq -n '{success: true, message: "file command already available"}'
  exit 0
else
  jq -n '{success: false, message: "file command is not available. Install it with: apt-get install file (Debian/Ubuntu), yum install file (RHEL/CentOS), or brew install file (macOS)."}'
  exit 1
fi