#!/bin/bash
# file plugin - process command
# Reads JSON input from stdin with a filePath parameter,
# detects MIME type using the 'file' command, and outputs JSON to stdout.
# Works on both Linux and macOS.
# Exit code: 0 on success, 1 on error

set -euo pipefail

# Read JSON input from stdin
input=$(cat)

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

# Validate file exists
if [ ! -e "$filePath" ]; then
  echo "Error: File not found: $filePath" >&2
  exit 1
fi

# Validate file is readable
if [ ! -r "$filePath" ]; then
  echo "Error: File is not readable: $filePath" >&2
  exit 1
fi

# Detect MIME type using file command
# -b: brief (no filename prefix), --mime-type: output MIME type only
mimeType=$(file --mime-type -b "$filePath" | tr -d '[:space:]')

# Output valid JSON using jq
jq -n --arg mimeType "$mimeType" '{mimeType: $mimeType}'