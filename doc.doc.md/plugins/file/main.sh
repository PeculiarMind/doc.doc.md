#!/bin/bash
# file plugin - process command
# Reads JSON input from stdin with a filePath parameter,
# detects MIME type using the 'file' command, and outputs JSON to stdout.
# Works on both Linux and macOS.
# Exit code: 0 on success, 1 on error

set -euo pipefail

# Read JSON input from stdin (limit to 1MB to prevent memory exhaustion per REQ_SEC_009)
input=$(head -c 1048576)

# Parse filePath from JSON input using jq
filePath=$(echo "$input" | jq -r '.filePath // empty' 2>/dev/null) || {
  echo "Error: Invalid JSON input" >&2
  exit 1
}

# Validate filePath is present
if [ -z "$filePath" ]; then
  echo "Error: Missing or invalid 'filePath' in JSON input" >&2
  exit 1
fi

# Resolve symlinks and canonicalize path for validation
resolvedPath=$(readlink -f "$filePath" 2>/dev/null) || resolvedPath=""
if [ -z "$resolvedPath" ]; then
  echo "Error: Cannot access the specified file" >&2
  exit 1
fi

# Reject paths in dangerous system directories (defense-in-depth per REQ_SEC_005)
case "$resolvedPath" in
  /proc/*|/proc|/dev/*|/dev|/sys/*|/sys|/etc/*|/etc)
    echo "Error: Cannot access the specified file" >&2
    exit 1
    ;;
esac

# Validate file exists and is readable (combined to prevent file-existence oracle)
if [ ! -f "$resolvedPath" ] || [ ! -r "$resolvedPath" ]; then
  echo "Error: Cannot access the specified file" >&2
  exit 1
fi

# Use resolved path for all subsequent operations
filePath="$resolvedPath"

# Detect MIME type using file command
# -b: brief (no filename prefix), --mime-type: output MIME type only
mimeType=$(file --mime-type -b "$filePath" | tr -d '[:space:]')

# Output valid JSON using jq
jq -n --arg mimeType "$mimeType" '{mimeType: $mimeType}'