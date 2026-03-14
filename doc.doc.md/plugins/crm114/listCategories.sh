#!/bin/bash
# crm114 plugin - listCategories command
# Lists all category names that have a trained .css model in pluginStorage.
# Input:  JSON from stdin with pluginStorage (required)
# Output: {"categories": ["cat1", "cat2", ...]} to stdout
# Exit codes: 0 success, 1 error

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../components/plugin_input.sh"

plugin_read_input

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

# Collect category names from .css files
shopt -s nullglob
css_files=("$CANONICAL_STORAGE"/*.css)
shopt -u nullglob

declare -a category_names=()
for css_file in "${css_files[@]}"; do
  category_names+=("$(basename "$css_file" .css)")
done

# Build JSON array in a single jq invocation
jq -n '$ARGS.positional | {categories: .}' --args "${category_names[@]+"${category_names[@]}"}"
