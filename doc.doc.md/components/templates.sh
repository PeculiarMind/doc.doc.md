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
#       - Uses full Mustache rendering via mustache_render.py (FEATURE_0040).

# --- Template rendering (FEATURE_0019, FEATURE_0040) ---

# render_template_json renders a template file using the Mustache specification
# via the companion Python script mustache_render.py.
render_template_json() {
  local template="$1"
  local result_json="$2"
  python3 "$(dirname "${BASH_SOURCE[0]}")/mustache_render.py" "$template" "$result_json"
}
