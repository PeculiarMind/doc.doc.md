#!/bin/bash
# crm114 plugin - learn command
# Non-interactive: trains a specified category model with text from filePath.
# Input:  JSON from stdin with category (required), pluginStorage (required),
#         filePath (required)
# Output: {"success": true/false, "message": "..."} to stdout
# Exit codes: 0 success, 1 error
#
# Uses `crm -e 'learn ...'` instead of standalone css-learn binary, so only
# the `crm` binary (shipped by the Debian crm114 package) is required.

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../components/plugin_input.sh"

plugin_read_input

# Extract category name
CATEGORY=$(plugin_get_field "category")
if [ -z "$CATEGORY" ]; then
  echo "Error: Missing required field 'category'" >&2
  exit 1
fi

# Sanitize category name: alphanumeric, dash, underscore, dot only (REQ_SEC_005)
if ! echo "$CATEGORY" | grep -qE '^[a-zA-Z0-9._-]+$'; then
  echo "Error: Invalid category name '$CATEGORY' — only alphanumeric, dash, underscore, and dot are allowed" >&2
  exit 1
fi

# Extract and validate pluginStorage
PLUGIN_STORAGE=$(plugin_get_field "pluginStorage")
if [ -z "$PLUGIN_STORAGE" ]; then
  echo "Error: Missing required field 'pluginStorage'" >&2
  exit 1
fi

CANONICAL_STORAGE=$(readlink -f "$PLUGIN_STORAGE" 2>/dev/null) || CANONICAL_STORAGE=""
if [ -z "$CANONICAL_STORAGE" ] || [ ! -d "$CANONICAL_STORAGE" ]; then
  echo "Error: pluginStorage directory does not exist: $PLUGIN_STORAGE" >&2
  exit 1
fi

# Validate filePath
plugin_validate_filepath
# PLUGIN_FILEPATH is now set and validated by plugin_validate_filepath

# Construct and validate the .css model path (prevent path traversal via symlinks)
CSS_FILE="$CANONICAL_STORAGE/$CATEGORY.css"
CSS_DIR=$(readlink -f "$(dirname "$CSS_FILE")" 2>/dev/null) || CSS_DIR=""
if [ -z "$CSS_DIR" ] || [ "$CSS_DIR" != "$CANONICAL_STORAGE" ]; then
  echo "Error: Resolved model path escapes pluginStorage" >&2
  exit 1
fi

# Check crm availability
if ! command -v crm >/dev/null 2>&1; then
  jq -n '{success: false, message: "crm is not available — install crm114"}'
  exit 1
fi

# Read text content from file
file_text=$(head -c 1048576 "$PLUGIN_FILEPATH" 2>/dev/null) || file_text=""
if [ -z "$file_text" ]; then
  jq -n '{success: false, message: "No text content in file"}'
  exit 1
fi

# Run crm learn: train the category model with the document text
if echo "$file_text" | crm '-{ learn <osb unique microgroom> ( '"$CSS_FILE"' ) }' >/dev/null 2>&1; then
  jq -n --arg cat "$CATEGORY" '{success: true, message: ("Trained category: " + $cat)}'
else
  jq -n --arg cat "$CATEGORY" '{success: false, message: ("crm learn failed for category: " + $cat)}'
  exit 1
fi
