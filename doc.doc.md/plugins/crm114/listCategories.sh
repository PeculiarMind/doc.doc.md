#!/bin/bash
# crm114 plugin - listCategories command
# Lists all category names with trained .css model files in pluginStorage.
# Input:  JSON on stdin with pluginStorage (required)
# Output: JSON {"categories": ["cat1", "cat2", ...]} to stdout
# Exit codes: 0 success, 1 on validation failure

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../components/plugin_input.sh"

plugin_read_input

PLUGIN_STORAGE=$(plugin_get_field "pluginStorage")

# Validate pluginStorage is provided
if [ -z "$PLUGIN_STORAGE" ]; then
  echo "Error: Missing 'pluginStorage' in JSON input" >&2
  exit 1
fi

# Security: reject path traversal in pluginStorage (REQ_SEC_005)
if [[ "$PLUGIN_STORAGE" == *".."* ]]; then
  echo "Error: Path traversal detected in pluginStorage" >&2
  exit 1
fi

# If storage directory does not exist, return empty array (not an error)
if [ ! -d "$PLUGIN_STORAGE" ]; then
  jq -n '{categories: []}'
  exit 0
fi

# Collect category names from .css files
categories_json="[]"
while IFS= read -r css_file; do
  cat_name=$(basename "$css_file" .css)
  categories_json=$(printf '%s' "$categories_json" | jq --arg n "$cat_name" '. + [$n]')
done < <(find "$PLUGIN_STORAGE" -maxdepth 1 -name "*.css" 2>/dev/null | sort)

jq -n --argjson cats "$categories_json" '{categories: $cats}'
