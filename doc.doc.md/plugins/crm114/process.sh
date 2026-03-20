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
DOCUMENT_TEXT=$(plugin_get_field "documentText")
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

# Resolve text: prefer textContent, fall back to documentText, then ocrText
TEXT="${TEXT_CONTENT:-}"
if [ -z "$TEXT" ]; then
  TEXT="${DOCUMENT_TEXT:-}"
fi
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

# Build CSS file list for the CRM114 classify statement (pipe-separated paths)
CSS_LIST=""
for _css in "${CSS_FILES[@]}"; do
  if [ -z "$CSS_LIST" ]; then
    CSS_LIST="$_css"
  else
    CSS_LIST="$CSS_LIST | $_css"
  fi
done

# Build and run a temp CRM114 classify script.
# The {classify...} block always populates :stats: regardless of which file wins.
# crmclassify does not exist in the crm114 package; the crm interpreter is used instead.
_CRM_CLASSIFY=$(mktemp /tmp/crm114_classify_XXXXXX.crm)
trap 'rm -f "$_CRM_CLASSIFY"' EXIT
cat > "$_CRM_CLASSIFY" << CRMEOF
window
input (:mytext:)
isolate (:stats:)
{
  classify <osb> [:mytext:] // ($CSS_LIST) (:stats:)
}
output /:*:stats:\n/
CRMEOF

CLASSIFY_OUTPUT=$(printf '%s\n' "$TEXT" | crm "$_CRM_CLASSIFY" 2>/dev/null) || true

# Parse CRM114 classify output to extract per-category pR values.
# Per-category line format: "#N (/path/to/catname.css): features: N, hits: N, prob: X, pR:   X.XX"
# Store regex in a variable: bash mis-parses ) in [^)] character class when inline in [[ =~ ]]
_re='^#[0-9]+[[:space:]]\(([^)]+)\.css\):.*pR:[[:space:]]+([+-]?[0-9]+\.[0-9]+)'
categories_json="[]"
while IFS= read -r line; do
  if [[ "$line" =~ $_re ]]; then
    css_path="${BASH_REMATCH[1]}"
    pr_value="${BASH_REMATCH[2]}"
    cat_name=$(basename "$css_path")
    categories_json=$(printf '%s' "$categories_json" | jq \
      --arg name "$cat_name" \
      --argjson pr "$pr_value" \
      '. + [{"categoryName": $name, "pR": $pr}]')
  fi
done <<< "$CLASSIFY_OUTPUT"

jq -n --argjson cats "$categories_json" '{categories: $cats}'
