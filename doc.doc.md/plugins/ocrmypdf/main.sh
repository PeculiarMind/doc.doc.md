#!/bin/bash
# ocrmypdf plugin - process command
# Reads JSON input from stdin with filePath, mimeType, and optional imageDpi parameters.
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

# Parse filePath, mimeType, and optional imageDpi from JSON input
file_path=$(echo "$input" | jq -r '.filePath // empty' 2>/dev/null) || {
  echo "Error: Invalid JSON input" >&2
  exit 1
}

mime_type=$(echo "$input" | jq -r '.mimeType // empty' 2>/dev/null) || mime_type=""

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

if [ -z "$mime_type" ]; then
  echo "Error: Missing required parameter 'mimeType' in JSON input" >&2
  exit 1
fi

# Determine if this is a PDF or a supported image type based on mimeType
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
    echo "Error: Unsupported MIME type '${mime_type}'. Supported types: application/pdf, image/jpeg, image/png, image/tiff, image/bmp, image/gif." >&2
    exit 1
    ;;
esac

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

# Validate required tools are available
if ! command -v ocrmypdf >/dev/null 2>&1; then
  echo "Error: ocrmypdf is not installed. Run the install command first." >&2
  exit 1
fi

# Create a temporary directory for sidecar output
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

sidecar_file="$tmp_dir/ocr_output.txt"

# Run text extraction
ocr_text=""

if [ "$is_image" = true ]; then
  # Strip alpha channel if present (ocrmypdf rejects RGBA images)
  ocr_input="$resolved_path"
  if command -v python3 >/dev/null 2>&1; then
    has_alpha=$(python3 -c "
from PIL import Image
try:
    img = Image.open('$resolved_path')
    print('yes' if img.mode in ('RGBA','LA','PA') else 'no')
except Exception:
    print('no')
" 2>/dev/null) || has_alpha="no"
    if [ "$has_alpha" = "yes" ]; then
      flat_image="$tmp_dir/flat_image.png"
      python3 -c "
from PIL import Image
img = Image.open('$resolved_path').convert('RGB')
img.save('$flat_image')
" 2>/dev/null && ocr_input="$flat_image"
    fi
  fi

  # Image input: use ocrmypdf with --image-dpi
  if ! ocrmypdf --image-dpi "$image_dpi" --sidecar "$sidecar_file" --output-type none "$ocr_input" /dev/null >/dev/null 2>&1; then
    echo "Error: OCRmyPDF processing failed for: $resolved_path" >&2
    exit 1
  fi
  if [ -f "$sidecar_file" ]; then
    ocr_text=$(cat "$sidecar_file")
  fi
else
  # PDF input: try pdftotext first to extract existing text layer (fast, accurate)
  if command -v pdftotext >/dev/null 2>&1; then
    ocr_text=$(pdftotext "$resolved_path" - 2>/dev/null) || ocr_text=""
  fi

  # If pdftotext yielded no text (scanned PDF), fall back to ocrmypdf OCR
  if [ -z "$(echo "$ocr_text" | tr -d '[:space:]')" ]; then
    if ! ocrmypdf --sidecar "$sidecar_file" --output-type none "$resolved_path" /dev/null >/dev/null 2>&1; then
      echo "Error: OCRmyPDF processing failed for: $resolved_path" >&2
      exit 1
    fi
    if [ -f "$sidecar_file" ]; then
      ocr_text=$(cat "$sidecar_file")
    fi
  fi
fi

# Output valid JSON
jq -n \
  --arg ocrText "$ocr_text" \
  '{ocrText: $ocrText}'
