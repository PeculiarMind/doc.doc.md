#!/bin/bash
# ocrmypdf plugin - process command
# Reads JSON input from stdin with filePath and pluginStorage parameters.
# Runs OCRmyPDF on a PDF file (if not already cached), extracts plain text,
# and returns structured JSON output.
#
# Caching: the OCR'd output PDF is cached in pluginStorage as <sha256_of_filePath>.pdf
# so subsequent calls with the same filePath skip expensive re-processing.
#
# Output JSON fields:
#   ocrText    - full plain-text extracted from the OCR'd PDF
#   pageCount  - number of pages in the PDF
#   wasCached  - true if cached OCR'd PDF was reused, false if freshly run
#   outputPdf  - absolute path to the OCR'd PDF in pluginStorage
#
# Exit code: 0 on success, 1 on error

set -euo pipefail

# Read JSON input from stdin (limit to 1MB to prevent memory exhaustion per REQ_SEC_009)
input=$(head -c 1048576)

# Parse filePath and pluginStorage from JSON input
file_path=$(echo "$input" | jq -r '.filePath // empty' 2>/dev/null) || {
  echo "Error: Invalid JSON input" >&2
  exit 1
}

plugin_storage=$(echo "$input" | jq -r '.pluginStorage // empty' 2>/dev/null) || {
  echo "Error: Invalid JSON input" >&2
  exit 1
}

# Validate required parameters
if [ -z "$file_path" ]; then
  echo "Error: Missing required parameter 'filePath' in JSON input" >&2
  exit 1
fi

if [ -z "$plugin_storage" ]; then
  echo "Error: Missing required parameter 'pluginStorage' in JSON input" >&2
  exit 1
fi

# Resolve and validate filePath (path traversal prevention per REQ_SEC_005)
resolved_path=$(readlink -f "$file_path" 2>/dev/null) || resolved_path=""
if [ -z "$resolved_path" ]; then
  echo "Error: Cannot access the specified file" >&2
  exit 1
fi

# Reject paths in dangerous system directories
case "$resolved_path" in
  /proc/*|/proc|/dev/*|/dev|/sys/*|/sys|/etc/*|/etc)
    echo "Error: Cannot access the specified file" >&2
    exit 1
    ;;
esac

# Validate file exists and is readable
if [ ! -f "$resolved_path" ] || [ ! -r "$resolved_path" ]; then
  echo "Error: Cannot access the specified file" >&2
  exit 1
fi

# Validate the file is a PDF (by MIME type or extension)
mime_type=""
if command -v file >/dev/null 2>&1; then
  mime_type=$(file --mime-type -b "$resolved_path" 2>/dev/null | tr -d '[:space:]')
fi

is_pdf=false
if [ "$mime_type" = "application/pdf" ]; then
  is_pdf=true
elif [[ "$resolved_path" == *.pdf ]] || [[ "$resolved_path" == *.PDF ]]; then
  is_pdf=true
fi

if [ "$is_pdf" = false ]; then
  echo "Error: Input file is not a PDF (detected MIME type: ${mime_type:-unknown})" >&2
  exit 1
fi

# Validate required tools are available
if ! command -v ocrmypdf >/dev/null 2>&1; then
  echo "Error: ocrmypdf is not installed. Run the install command first." >&2
  exit 1
fi

if ! command -v pdftotext >/dev/null 2>&1; then
  echo "Error: pdftotext is not installed. Run the install command first." >&2
  exit 1
fi

if ! command -v pdfinfo >/dev/null 2>&1; then
  echo "Error: pdfinfo is not installed. Run the install command first." >&2
  exit 1
fi

# Validate pluginStorage path (prevent path traversal)
resolved_storage=$(readlink -m "$plugin_storage" 2>/dev/null) || {
  echo "Error: Invalid pluginStorage path" >&2
  exit 1
}

# Create pluginStorage directory if it does not exist
mkdir -p "$resolved_storage" || {
  echo "Error: Cannot create pluginStorage directory: $resolved_storage" >&2
  exit 1
}

# Compute cache key: sha256 of the filePath string (not file content, per spec)
hash=$(echo -n "$file_path" | sha256sum | awk '{print $1}')
cached_pdf="$resolved_storage/${hash}.pdf"

# Check cache and run OCR if needed
was_cached=false
if [ -f "$cached_pdf" ]; then
  # Cache hit: reuse the existing OCR'd PDF
  was_cached=true
else
  # Cache miss: run OCRmyPDF on the input PDF
  # --skip-text preserves pages that already have a text layer (prevents double-OCR)
  if ! ocrmypdf --skip-text "$resolved_path" "$cached_pdf" >/dev/null 2>&1; then
    echo "Error: OCRmyPDF processing failed for: $resolved_path" >&2
    exit 1
  fi
fi

# Extract plain text from the OCR'd PDF
ocr_text=$(pdftotext "$cached_pdf" - 2>/dev/null) || {
  echo "Error: pdftotext failed to extract text from: $cached_pdf" >&2
  exit 1
}

# Extract page count from the OCR'd PDF
page_count=$(pdfinfo "$cached_pdf" 2>/dev/null | grep "^Pages:" | awk '{print $2}') || page_count="0"
if [ -z "$page_count" ]; then
  page_count="0"
fi

# Output valid JSON with all required fields
jq -n \
  --arg ocrText "$ocr_text" \
  --argjson pageCount "$page_count" \
  --argjson wasCached "$was_cached" \
  --arg outputPdf "$cached_pdf" \
  '{
    ocrText: $ocrText,
    pageCount: $pageCount,
    wasCached: $wasCached,
    outputPdf: $outputPdf
  }'
