#!/bin/bash
# stat plugin - install command
# Checks if the 'stat' command is available and reports status.
# stat is typically pre-installed on Unix systems.
# Output: JSON {"success": bool, "message": string} to stdout
# Exit code: 0 on success, 1 if installation needed but can't be done

if command -v stat >/dev/null 2>&1; then
  jq -n '{success: true, message: "stat command already available"}'
  exit 0
else
  jq -n '{success: false, message: "stat command is not available. It is typically pre-installed on Unix systems. Please install coreutils for your platform."}'
  exit 1
fi