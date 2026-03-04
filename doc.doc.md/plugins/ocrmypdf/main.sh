#!/bin/bash
# ocrmypdf plugin - process command
# Reads JSON input from stdin with filePath and optional imageDpi parameters.
# Runs OCRmyPDF on a PDF or image file and returns extracted text as JSON.
#
# Supported input types: application/pdf, image/jpeg, image/png, image/tiff,
#                        image/bmp, image/gif
#
# Uses the sidecar pattern for text extraction:
#   ocrmypdf [--image-dpi <dpi>] --sidecar <sidecar.txt> --output-type none <input> /dev/null
#
# Output JSON fields:
#   ocrText    - full plain-text extracted by OCR
#
# Exit code: 0 on success, 1 on error

set -euo pipefail

# Read JSON input from stdin (limit to 1MB to prevent memory exhaustion per REQ_SEC_009)
input=$(head -c 1048576)

# Parse filePath and optional imageDpi from JSON input
file_path=$(echo "$input" | jq -r '.filePath // empty' 2>/dev/null) || {
  echo "Error: Invalid JSON input" >&2
  exit 1
}

image_dpi=$(echo "$input" | jq -r '.imageDpi // 300' 2>/dev/null) || image_dpi=300
# Validate imageDpi is a positive integer; warn and fall back to 300 if invalid
if ! echo "$image_dpi" | grep -qE '^[0-9]+$' || [ "$image_dpi" -lt 1 ] 2>/dev/null; then
  echo "Warning: Invalid imageDpi value '${image_dpi}'; using default of 300." >&2
  image_dpi=300
fi

# Validate required parameters
if [ -z "$file_path" ]; then
  echo "Error: Missing required parameter 'filePath' in JSON input" >&2
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

# Detect MIME type
mime_type=""
if command -v file >/dev/null 2>&1; then
  mime_type=$(file --mime-type -b "$resolved_path" 2>/dev/null | tr -d '[:space:]')
fi

# Determine if this is a PDF or a supported image type
is_pdf=false
is_image=false

case "$mime_type" in
  application/pdf)
    is_pdf=true
    ;;
  image/jpeg|image/png|image/tiff|image/bmp|image/gif)
    is_image=true
    ;;
  *)
    # Fall back to extension check for PDF
    case "$resolved_path" in
      *.pdf|*.PDF) is_pdf=true ;;
    esac
    ;;
esac

if [ "$is_pdf" = false ] && [ "$is_image" = false ]; then
  echo "Error: Unsupported file type (detected MIME type: ${mime_type:-unknown}). Supported types: application/pdf, image/jpeg, image/png, image/tiff, image/bmp, image/gif." >&2
  exit 1
fi

# Validate required tools are available
if ! command -v ocrmypdf >/dev/null 2>&1; then
  echo "Error: ocrmypdf is not installed. Run the install command first." >&2
  exit 1
fi

# Create a temporary directory for sidecar output
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

sidecar_file="$tmp_dir/ocr_output.txt"

# Run OCRmyPDF with sidecar pattern to extract text
if [ "$is_image" = true ]; then
  # Image input: pass --image-dpi
  if ! ocrmypdf --image-dpi "$image_dpi" --sidecar "$sidecar_file" --output-type none "$resolved_path" /dev/null >/dev/null 2>&1; then
    echo "Error: OCRmyPDF processing failed for: $resolved_path" >&2
    exit 1
  fi
else
  # PDF input: no --image-dpi needed
  if ! ocrmypdf --sidecar "$sidecar_file" --output-type none "$resolved_path" /dev/null >/dev/null 2>&1; then
    echo "Error: OCRmyPDF processing failed for: $resolved_path" >&2
    exit 1
  fi
fi

# Read extracted text from sidecar
ocr_text=""
if [ -f "$sidecar_file" ]; then
  ocr_text=$(cat "$sidecar_file")
fi

# Output valid JSON
jq -n \
  --arg ocrText "$ocr_text" \
  '{ocrText: $ocrText}'
