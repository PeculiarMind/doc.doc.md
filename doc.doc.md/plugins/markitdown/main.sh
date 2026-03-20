#!/bin/bash
# markitdown plugin - process command
# Converts MS Office documents to markdown using the markitdown Python library.
# Input: JSON from stdin with filePath and mimeType
# Output: JSON with documentText
# Exit codes: 0 success (EX_OK), 65 unsupported input (EX_DATAERR, ADR-004), 1 failure
# Exit code contract: ADR-004 (project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md)

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PLUGIN_DIR/../../components/plugin_input.sh"

SUPPORTED_MIME_TYPES=(
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  "application/vnd.openxmlformats-officedocument.presentationml.presentation"
  "application/msword"
  "application/vnd.ms-excel"
  "application/vnd.ms-powerpoint"
)

plugin_read_input
plugin_validate_filepath

mime_type="$(plugin_get_field "mimeType")"
if [ -z "$mime_type" ]; then
  echo "Error: mimeType is required" >&2
  exit 1
fi

mime_supported=false
for supported in "${SUPPORTED_MIME_TYPES[@]}"; do
  if [ "$mime_type" = "$supported" ]; then
    mime_supported=true
    break
  fi
done

if [ "$mime_supported" = false ]; then
  echo "{\"message\":\"skipped: unsupported MIME type $mime_type\"}"
  exit 65
fi

# Run markitdown from the plugin-local venv, fall back to PATH
MARKITDOWN_BIN="$PLUGIN_DIR/.venv/bin/markitdown"
if [ ! -x "$MARKITDOWN_BIN" ]; then
  MARKITDOWN_BIN="$(command -v markitdown 2>/dev/null || true)"
  if [ -z "$MARKITDOWN_BIN" ] || [ ! -x "$MARKITDOWN_BIN" ]; then
    echo "Error: markitdown not installed. Run: doc.doc.sh install --plugin markitdown" >&2
    exit 1
  fi
fi
_mkd_err_file="$(mktemp)"
_mkd_exit=0
if ! document_text="$("$MARKITDOWN_BIN" "$PLUGIN_FILEPATH" 2>"$_mkd_err_file")"; then
  _mkd_exit=$?
  _mkd_err_content="$(cat "$_mkd_err_file" 2>/dev/null)" || _mkd_err_content=""
  rm -f "$_mkd_err_file"
  if [ -n "$_mkd_err_content" ]; then
    echo "Error: markitdown conversion failed: $_mkd_err_content" >&2
  else
    echo "Error: markitdown conversion failed (exit code: $_mkd_exit)" >&2
  fi
  exit 1
fi
rm -f "$_mkd_err_file"

jq -n --arg documentText "$document_text" '{"documentText": $documentText}'
