#!/bin/bash
# templates.sh - Template rendering module for doc.doc.md
# Part of doc.doc.md architecture (Level 3: Bash Components)
# Handles template loading and variable substitution for sidecar
# markdown file generation.
#
# Public Interface:
#   render_template_json <template_file> <result_json>
#       - Render a template file replacing {{key}} placeholders
#         with values from the provided JSON string.
#       - Derives {{fileName}} from the filePath key.

# --- Template rendering (FEATURE_0019) ---

# render_template_json renders a template file replacing {{key}} placeholders
# with values from the provided JSON string.
render_template_json() {
  local template="$1"
  local result_json="$2"
  local content
  content="$(cat "$template")"

  # Iterate over keys; extract each value preserving all lines (fixes DEBTR_003 and BUG_0009)
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    local val
    val="$(echo "$result_json" | jq -r --arg k "$key" '.[$k] // empty')"
    content="${content//\{\{${key}\}\}/${val}}"
  done < <(echo "$result_json" | jq -r 'keys[]')

  # Derive fileName from filePath
  local fp
  fp=$(echo "$result_json" | jq -r '.filePath // empty')
  if [ -n "$fp" ]; then
    local fname
    fname="$(basename "$fp")"
    content="${content//\{\{fileName\}\}/${fname}}"
  fi

  printf '%s' "$content"
}
