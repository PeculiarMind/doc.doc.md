#!/bin/bash
# markitdown plugin - process command
# Converts MS Office documents to markdown using the markitdown Python library.
# Input: JSON from stdin with filePath and mimeType
# Output: JSON with documentText

set -euo pipefail

SUPPORTED_MIME_TYPES=(
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  "application/vnd.openxmlformats-officedocument.presentationml.presentation"
  "application/msword"
  "application/vnd.ms-excel"
  "application/vnd.ms-powerpoint"
)

input_json="$(cat)"
file_path="$(echo "$input_json" | jq -r '.filePath // empty')"
mime_type="$(echo "$input_json" | jq -r '.mimeType // empty')"

if [ -z "$file_path" ]; then
  echo "Error: filePath is required" >&2
  exit 1
fi

canonical_path="$(readlink -f "$file_path" 2>/dev/null || echo "")"
if [ -z "$canonical_path" ]; then
  echo "Error: Cannot resolve file path" >&2
  exit 1
fi

case "$canonical_path" in
  /proc/*|/dev/*|/sys/*|/etc/*)
    echo "Error: Access to restricted path denied" >&2
    exit 1
    ;;
esac

if [ ! -f "$canonical_path" ]; then
  echo "Error: File not found" >&2
  exit 1
fi

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
  echo "Error: Unsupported MIME type: $mime_type" >&2
  exit 1
fi

# Run markitdown to convert the file
_mkd_err_file="$(mktemp)"
if ! document_text="$(markitdown "$canonical_path" 2>"$_mkd_err_file")"; then
  echo "Error: markitdown conversion failed" >&2
  rm -f "$_mkd_err_file"
  exit 1
fi
rm -f "$_mkd_err_file"

jq -n --arg documentText "$document_text" '{"documentText": $documentText}'
