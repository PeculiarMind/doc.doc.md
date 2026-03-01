#!/bin/bash
# stat plugin - process command
# Reads JSON input from stdin with a filePath parameter,
# extracts file statistics, and outputs JSON to stdout.
# Supports both Linux and macOS via platform detection.
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

# Detect platform and gather file statistics
platform=$(uname -s)

if [ "$platform" = "Darwin" ]; then
  # macOS: use stat -f format specifiers
  fileSize=$(stat -f '%z' "$filePath")
  fileOwner=$(stat -f '%Su' "$filePath")
  # macOS: %B=birth time, %m=modification, %c=metadata change (epoch seconds)
  birthEpoch=$(stat -f '%B' "$filePath")
  modEpoch=$(stat -f '%m' "$filePath")
  changeEpoch=$(stat -f '%c' "$filePath")

  # Convert epoch to ISO 8601 on macOS
  if [ "$birthEpoch" -gt 0 ] 2>/dev/null; then
    fileCreated=$(date -r "$birthEpoch" -u '+%Y-%m-%dT%H:%M:%SZ')
  else
    fileCreated=""
  fi
  fileModified=$(date -r "$modEpoch" -u '+%Y-%m-%dT%H:%M:%SZ')
  fileMetadataChanged=$(date -r "$changeEpoch" -u '+%Y-%m-%dT%H:%M:%SZ')
else
  # Linux: use stat -c format specifiers
  fileSize=$(stat -c '%s' "$filePath")
  fileOwner=$(stat -c '%U' "$filePath")

  # Linux: %W=birth time (0 if unsupported), %Y=modification, %Z=metadata change
  birthEpoch=$(stat -c '%W' "$filePath")
  modEpoch=$(stat -c '%Y' "$filePath")
  changeEpoch=$(stat -c '%Z' "$filePath")

  # Convert epoch to ISO 8601 on Linux
  if [ "$birthEpoch" -gt 0 ] 2>/dev/null; then
    fileCreated=$(date -u -d "@$birthEpoch" '+%Y-%m-%dT%H:%M:%SZ')
  else
    fileCreated=""
  fi
  fileModified=$(date -u -d "@$modEpoch" '+%Y-%m-%dT%H:%M:%SZ')
  fileMetadataChanged=$(date -u -d "@$changeEpoch" '+%Y-%m-%dT%H:%M:%SZ')
fi

# Output valid JSON using jq
jq -n \
  --argjson fileSize "$fileSize" \
  --arg fileOwner "$fileOwner" \
  --arg fileCreated "$fileCreated" \
  --arg fileModified "$fileModified" \
  --arg fileMetadataChanged "$fileMetadataChanged" \
  '{
    fileSize: $fileSize,
    fileOwner: $fileOwner,
    fileCreated: $fileCreated,
    fileModified: $fileModified,
    fileMetadataChanged: $fileMetadataChanged
  }'