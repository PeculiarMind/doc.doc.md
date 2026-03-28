#!/bin/bash
# ots plugin - process command
# Reads accumulated pipeline JSON from stdin, selects available text
# (textContent → ocrText → documentText, first non-empty), pipes it to
# ots --ratio <N> [--dic <path>], and returns summaryText as JSON.
# Exit codes: 0 success, 65 skip (no text or ots failure — ADR-004), 1 failure

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
  echo "No text content available for summarization" >&2
  exit 65
fi

# Validate and extract summaryRatio (integer 1-100, default 20)
RATIO_RAW=$(plugin_get_field "summaryRatio")
RATIO=20
if [ -n "$RATIO_RAW" ] && [[ "$RATIO_RAW" =~ ^[0-9]+$ ]]; then
  if [ "$RATIO_RAW" -ge 1 ] && [ "$RATIO_RAW" -le 100 ]; then
    RATIO="$RATIO_RAW"
  fi
fi

# Validate and extract languageCode (2-letter lowercase alphabetic, no path traversal)
LANG_CODE_RAW=$(plugin_get_field "languageCode")
SUMMARY_LANG="null"
DIC_ARGS=()

if [ -n "$LANG_CODE_RAW" ] && [[ "$LANG_CODE_RAW" =~ ^[a-z]{2}$ ]]; then
  DIC_PATH="/usr/share/ots/${LANG_CODE_RAW}.xml"
  if [ -f "$DIC_PATH" ]; then
    DIC_ARGS=("--dic" "$LANG_CODE_RAW")
    SUMMARY_LANG="$LANG_CODE_RAW"
  fi
fi

# Run OTS via stdin only — no temp files, no shell interpolation of document content
SUMMARY=""
SUMMARY=$(printf '%s' "$TEXT" | ots --ratio "$RATIO" "${DIC_ARGS[@]+"${DIC_ARGS[@]}"}" 2>/dev/null) || true

# Skip if OTS produced empty output or failed (ADR-004: exit 65)
if [ -z "$SUMMARY" ]; then
  echo "OTS produced empty output or failed" >&2
  exit 65
fi

# Output JSON via jq — no manual string concatenation
if [ "$SUMMARY_LANG" = "null" ]; then
  jq -n \
    --arg summaryText "$SUMMARY" \
    --argjson summaryRatio "$RATIO" \
    '{
      summaryText: $summaryText,
      summaryRatio: $summaryRatio,
      summaryLanguage: null
    }'
else
  jq -n \
    --arg summaryText "$SUMMARY" \
    --argjson summaryRatio "$RATIO" \
    --arg summaryLanguage "$SUMMARY_LANG" \
    '{
      summaryText: $summaryText,
      summaryRatio: $summaryRatio,
      summaryLanguage: $summaryLanguage
    }'
fi
