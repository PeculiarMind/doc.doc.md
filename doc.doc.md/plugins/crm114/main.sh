#!/bin/bash
# crm114 plugin - process command
# Reads JSON input from stdin with filePath and pluginStorage parameters,
# classifies document text using CRM114, and outputs JSON to stdout.
# Exit codes: 0 success, 65 skip (no trained categories or no text), 1 error
# Exit code contract: ADR-004

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../components/plugin_input.sh"

plugin_read_input
plugin_validate_filepath

# Extract pluginStorage path
PLUGIN_STORAGE=$(plugin_get_field "pluginStorage")
if [ -z "$PLUGIN_STORAGE" ]; then
  echo '{"message":"pluginStorage not provided"}' 
  exit 65
fi

# Validate pluginStorage path (REQ_SEC_005)
CANONICAL_STORAGE=$(readlink -f "$PLUGIN_STORAGE" 2>/dev/null) || CANONICAL_STORAGE=""
if [ -z "$CANONICAL_STORAGE" ] || [ ! -d "$CANONICAL_STORAGE" ]; then
  echo '{"message":"pluginStorage directory does not exist"}'
  exit 65
fi

# Find trained category models (.css files)
shopt -s nullglob
css_files=("$CANONICAL_STORAGE"/*.css)
shopt -u nullglob

if [ ${#css_files[@]} -eq 0 ]; then
  echo '{"message":"No trained categories found"}'
  exit 65
fi

# Read file text content
file_text=$(cat "$PLUGIN_FILEPATH" 2>/dev/null | head -c 1048576) || file_text=""
if [ -z "$file_text" ]; then
  echo '{"message":"No extractable text"}'
  exit 65
fi

# Classify against each category
categories_json="{}"
for css_file in "${css_files[@]}"; do
  category_name=$(basename "$css_file" .css)

  # Run CRM114 classification
  crm_output=$(echo "$file_text" | cssutil -r "$css_file" 2>/dev/null) || crm_output=""
  if [ -z "$crm_output" ]; then
    # Try alternative: crm114 classify command
    crm_output=$(echo "$file_text" | crm -e 'classify <osb unique microgroom> ('"$css_file"')' 2>/dev/null) || crm_output=""
  fi

  # Extract pR score from CRM114 output
  pr_score=$(echo "$crm_output" | grep -oP 'pR:\s*\K[-+]?[0-9]*\.?[0-9]+' 2>/dev/null | head -1) || pr_score=""

  # Only include positive pR scores
  if [ -n "$pr_score" ]; then
    is_positive=$(echo "$pr_score" | awk '{print ($1 > 0) ? "yes" : "no"}')
    if [ "$is_positive" = "yes" ]; then
      categories_json=$(echo "$categories_json" | jq --arg cat "$category_name" --argjson score "$pr_score" '. + {($cat): $score}')
    fi
  fi
done

# Output result
jq -n --argjson categories "$categories_json" '{categories: $categories}'
