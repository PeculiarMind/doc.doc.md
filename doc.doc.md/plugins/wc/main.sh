#!/bin/bash
# wc plugin - process command
# Reads accumulated pipeline JSON from stdin, selects available text
# (textContent → ocrText → documentText, first non-empty), pipes it to
# wc -l -w -m, and returns lineCount, wordCount, charCount as JSON.
# Exit codes: 0 success, 65 skip (no text available — ADR-004), 1 failure

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../components/plugin_input.sh"

plugin_read_input

# Select text using priority order: textContent → ocrText → documentText
TEXT_CONTENT=$(plugin_get_field "textContent")
OCR_TEXT=$(plugin_get_field "ocrText")
DOCUMENT_TEXT=$(plugin_get_field "documentText")

TEXT="${TEXT_CONTENT:-}"
if [ -z "$TEXT" ]; then
  TEXT="${OCR_TEXT:-}"
fi
if [ -z "$TEXT" ]; then
  TEXT="${DOCUMENT_TEXT:-}"
fi

# Skip if no text available (ADR-004: exit 65)
if [ -z "$TEXT" ]; then
  echo "No text content available for word counting" >&2
  exit 65
fi

# Count lines, words, characters via wc (stdin only — no file paths)
read -r line_count word_count char_count <<< "$(printf '%s' "$TEXT" | wc -l -w -m | awk '{print $1, $2, $3}')"

# Output JSON
jq -n \
  --argjson lineCount "$line_count" \
  --argjson wordCount "$word_count" \
  --argjson charCount "$char_count" \
  '{
    lineCount: $lineCount,
    wordCount: $wordCount,
    charCount: $charCount
  }'
