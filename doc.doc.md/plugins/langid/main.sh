#!/bin/bash
# langid plugin - process command
# Reads accumulated pipeline JSON from stdin, selects available text
# (documentText → ocrText → textContent, first non-empty), passes it to
# langid.classify() via Python, and returns languageCode and languageConfidence.
# Exit codes: 0 success, 65 skip (no text available — ADR-004), 1 failure

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PLUGIN_DIR/../../components/plugin_input.sh"

# Use venv python if available, otherwise fall back to system python3
if [ -x "$PLUGIN_DIR/.venv/bin/python3" ]; then
  PYTHON_BIN="$PLUGIN_DIR/.venv/bin/python3"
else
  PYTHON_BIN="python3"
fi

plugin_read_input

# Select text using priority order: documentText → ocrText → textContent
DOCUMENT_TEXT=$(plugin_get_field "documentText")
OCR_TEXT=$(plugin_get_field "ocrText")
TEXT_CONTENT=$(plugin_get_field "textContent")

TEXT="${DOCUMENT_TEXT:-}"
if [ -z "$TEXT" ]; then
  TEXT="${OCR_TEXT:-}"
fi
if [ -z "$TEXT" ]; then
  TEXT="${TEXT_CONTENT:-}"
fi

# Skip if no text available (ADR-004: exit 65)
if [ -z "$TEXT" ]; then
  echo "No text content available for language identification" >&2
  exit 65
fi

# Run langid via Python — text passed via stdin, never interpolated into shell command
RESULT=$(printf '%s' "$TEXT" | "$PYTHON_BIN" -c "
import sys, json, langid
text = sys.stdin.read()
code, conf = langid.classify(text)
print(json.dumps({'languageCode': code, 'languageConfidence': conf}))
" 2>/dev/null) || {
  echo "langid classification failed" >&2
  exit 65
}

# Validate output is valid JSON
if ! echo "$RESULT" | jq empty 2>/dev/null; then
  echo "langid produced invalid output" >&2
  exit 65
fi

echo "$RESULT"
