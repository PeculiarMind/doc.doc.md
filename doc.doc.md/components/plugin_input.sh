#!/bin/bash
# plugin_input.sh - Shared plugin input validation for doc.doc.md
# Part of doc.doc.md architecture (Level 3: Bash Components)
# Provides secure input reading and path validation for all plugins.
# Complies with REQ_SEC_005 (path traversal prevention) and REQ_SEC_009 (stdin size limit).
#
# Usage:  source "$(dirname "${BASH_SOURCE[0]}")/../../components/plugin_input.sh"
#         plugin_read_input          # reads stdin, sets PLUGIN_INPUT_JSON
#         plugin_validate_filepath   # validates and resolves filePath, sets PLUGIN_FILEPATH
#
# After calling both:
#   PLUGIN_INPUT_JSON  — raw JSON string from stdin
#   PLUGIN_FILEPATH    — canonicalized, validated file path (safe for operations)
#
# Exit codes: 1 on any validation failure (per ADR-004)

# Restricted system directories (defense-in-depth per REQ_SEC_005)
_RESTRICTED_PATH_PATTERN='^/(proc|dev|sys|etc)(/|$)'

# Read JSON input from stdin (limit to 1MB per REQ_SEC_009)
plugin_read_input() {
  PLUGIN_INPUT_JSON=$(head -c 1048576)
  if [ -z "$PLUGIN_INPUT_JSON" ]; then
    echo "Error: Empty input" >&2
    exit 1
  fi
}

# Extract a string field from PLUGIN_INPUT_JSON. Prints empty string if absent.
plugin_get_field() {
  local field="$1"
  local val
  val=$(echo "$PLUGIN_INPUT_JSON" | jq -r --arg f "$field" '.[$f] // empty' 2>/dev/null) || val=""
  echo "$val"
}

# Validate and resolve the filePath from PLUGIN_INPUT_JSON.
# Sets PLUGIN_FILEPATH to the canonical path.
plugin_validate_filepath() {
  local raw_path
  raw_path=$(plugin_get_field "filePath")

  if [ -z "$raw_path" ]; then
    echo "Error: Missing or invalid 'filePath' in JSON input" >&2
    exit 1
  fi

  # Resolve symlinks and canonicalize
  PLUGIN_FILEPATH=$(readlink -f "$raw_path" 2>/dev/null) || PLUGIN_FILEPATH=""
  if [ -z "$PLUGIN_FILEPATH" ]; then
    echo "Error: Cannot access the specified file" >&2
    exit 1
  fi

  # Reject restricted directories
  if [[ "$PLUGIN_FILEPATH" =~ $_RESTRICTED_PATH_PATTERN ]]; then
    echo "Error: Access to restricted path denied" >&2
    exit 1
  fi

  # Validate file exists and is readable
  if [ ! -f "$PLUGIN_FILEPATH" ] || [ ! -r "$PLUGIN_FILEPATH" ]; then
    echo "Error: Cannot access the specified file" >&2
    exit 1
  fi
}
