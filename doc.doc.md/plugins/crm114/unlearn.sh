#!/bin/bash
# crm114 plugin - unlearn command
# Non-interactive: remove text from a category CSS model.
# Input:  JSON on stdin with filePath, category, pluginStorage, and textContent or ocrText (at least one required)
# Output: JSON {"success": true, "category": "<name>"} on success
# Exit codes: 0 success, 1 validation or execution failure

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../components/plugin_input.sh"

plugin_read_input
plugin_validate_filepath

CATEGORY=$(plugin_get_field "category")
PLUGIN_STORAGE=$(plugin_get_field "pluginStorage")
TEXT_CONTENT=$(plugin_get_field "textContent")
OCR_TEXT=$(plugin_get_field "ocrText")

# Validate required fields
if [ -z "$CATEGORY" ]; then
  echo "Error: Missing 'category' in JSON input" >&2
  exit 1
fi

if [ -z "$PLUGIN_STORAGE" ]; then
  echo "Error: Missing 'pluginStorage' in JSON input" >&2
  exit 1
fi

# Security: sanitize category name — alphanumeric, dash, underscore, dot only (REQ_SEC_005)
if ! [[ "$CATEGORY" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: Invalid category name '$CATEGORY'. Only alphanumeric characters, dash, underscore, and dot are allowed." >&2
  exit 1
fi

# Security: reject path traversal in pluginStorage (REQ_SEC_005)
if [[ "$PLUGIN_STORAGE" == *".."* ]]; then
  echo "Error: Path traversal detected in pluginStorage" >&2
  exit 1
fi

# Require at least one text source
TEXT="${TEXT_CONTENT:-}"
if [ -z "$TEXT" ]; then
  TEXT="${OCR_TEXT:-}"
fi
if [ -z "$TEXT" ]; then
  echo "Error: At least one of 'textContent' or 'ocrText' is required" >&2
  exit 1
fi

CSS_FILE="$PLUGIN_STORAGE/$CATEGORY.css"

# Fail gracefully if CSS file does not exist
if [ ! -f "$CSS_FILE" ]; then
  jq -n --arg cat "$CATEGORY" '{success: false, category: $cat, error: "Category model file does not exist"}'
  exit 1
fi

# Build and run a temp CRM114 script: learn <osb microgroom refute> removes text from the CSS model.
# The 'refute' flag is the correct unlearn mechanism in CRM114 (cssunlearn does not exist).
_CRM_UNLEARN=$(mktemp /tmp/crm114_unlearn_XXXXXX.crm)
trap 'rm -f "$_CRM_UNLEARN"' EXIT
cat > "$_CRM_UNLEARN" << CRMEOF
window
input (:mytext:)
learn <osb microgroom refute> ($CSS_FILE) [:mytext:] //
CRMEOF

if ! printf '%s\n' "$TEXT" | crm "$_CRM_UNLEARN" > /dev/null 2>&1; then
  jq -n --arg cat "$CATEGORY" '{success: false, category: $cat}'
  exit 1
fi

jq -n --arg cat "$CATEGORY" '{success: true, category: $cat}'
