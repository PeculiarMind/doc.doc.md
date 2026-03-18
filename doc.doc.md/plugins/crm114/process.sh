#!/bin/bash
# crm114 plugin - process command
# Classifies document text against all trained category models and returns pR scores.
# Input:  JSON on stdin with filePath, pluginStorage (required), textContent or ocrText
# Output: JSON {"categories": [{"categoryName": "...", "pR": ...}, ...]} to stdout
# Exit codes: 0 success, 1 validation failure, 65 skip (ADR-004: no categories, no text)
# Exit code contract: ADR-004

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../components/plugin_input.sh"

plugin_read_input
plugin_validate_filepath

PLUGIN_STORAGE=$(plugin_get_field "pluginStorage")
TEXT_CONTENT=$(plugin_get_field "textContent")
OCR_TEXT=$(plugin_get_field "ocrText")

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

# Resolve text: prefer textContent, fall back to ocrText
TEXT="${TEXT_CONTENT:-}"
if [ -z "$TEXT" ]; then
  TEXT="${OCR_TEXT:-}"
fi

# Exit 65 (skip) if no extractable text
if [ -z "$TEXT" ]; then
  exit 65
fi

# Exit 65 (skip) if pluginStorage does not exist or has no CSS files
if [ ! -d "$PLUGIN_STORAGE" ]; then
  exit 65
fi

mapfile -t CSS_FILES < <(find "$PLUGIN_STORAGE" -maxdepth 1 -name "*.css" 2>/dev/null | sort)

if [ "${#CSS_FILES[@]}" -eq 0 ]; then
  exit 65
fi

# Classify text against all CSS files using crmclassify
# crmclassify accepts multiple CSS files and outputs pR per file
CLASSIFY_OUTPUT=$(printf '%s\n' "$TEXT" | crmclassify "${CSS_FILES[@]}" 2>/dev/null) || true

# Parse crmclassify output to extract per-category pR values
# Format: lines like "Best match to <path>/<name>.css pR: <value>  <path>/<name2>.css pR: <value2>"
# or:     "<path>/<name>.css: pR: <value>"
# We extract all occurrences of "<something>.css pR: <value>" or "<something>.css: pR: <value>"
categories_json="[]"
while IFS= read -r line; do
  # Match patterns: "name.css pR: VALUE" or "name.css: pR: VALUE"
  while [[ "$line" =~ ([^/[:space:]]+)\.css[[:space:]]*:?[[:space:]]*pR:[[:space:]]*([+-]?[0-9]+\.?[0-9]*) ]]; do
    cat_name="${BASH_REMATCH[1]}"
    pr_value="${BASH_REMATCH[2]}"
    categories_json=$(printf '%s' "$categories_json" | jq \
      --arg name "$cat_name" \
      --argjson pr "$pr_value" \
      '. + [{"categoryName": $name, "pR": $pr}]')
    # Consume the matched portion so we can continue scanning the line
    line="${line#*"${BASH_REMATCH[0]}"}"
  done
done <<< "$CLASSIFY_OUTPUT"

jq -n --argjson cats "$categories_json" '{categories: $cats}'
