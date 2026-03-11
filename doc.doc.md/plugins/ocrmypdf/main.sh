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
# Exit codes: 0 success (EX_OK), 65 unsupported input (EX_DATAERR, ADR-004), 1 failure
# Exit code contract: ADR-004 (project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md)

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../components/plugin_input.sh"

plugin_read_input
plugin_validate_filepath

# Parse mimeType and optional imageDpi
mime_type=$(plugin_get_field "mimeType")
image_dpi=$(echo "$PLUGIN_INPUT_JSON" | jq -r '.imageDpi // 300' 2>/dev/null) || image_dpi=300
if ! echo "$image_dpi" | grep -qE '^[0-9]+$' || [ "$image_dpi" -lt 1 ] 2>/dev/null; then
  echo "Warning: Invalid imageDpi value '${image_dpi}'; using default of 300." >&2
  image_dpi=300
fi

if [ -z "$mime_type" ]; then
  echo "Error: Missing required parameter 'mimeType' in JSON input" >&2
  exit 1
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
    echo "{\"message\":\"skipped: unsupported MIME type $mime_type\"}"
    exit 65
    ;;
esac

# Validate required tools
if ! command -v ocrmypdf >/dev/null 2>&1; then
  echo "Error: ocrmypdf is not installed. Run the install command first." >&2
  exit 1
fi

# Create a temporary directory for sidecar output
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

sidecar_file="$tmp_dir/ocr_output.txt"
ocr_text=""

if [ "$is_image" = true ]; then
  # Strip alpha channel if present (ocrmypdf rejects RGBA images)
  ocr_input="$PLUGIN_FILEPATH"
  if command -v python3 >/dev/null 2>&1; then
    has_alpha=$(python3 -c "
from PIL import Image
try:
    img = Image.open('$PLUGIN_FILEPATH')
    print('yes' if img.mode in ('RGBA','LA','PA') else 'no')
except Exception:
    print('no')
" 2>/dev/null) || has_alpha="no"
    if [ "$has_alpha" = "yes" ]; then
      flat_image="$tmp_dir/flat_image.png"
      python3 -c "
from PIL import Image
img = Image.open('$PLUGIN_FILEPATH').convert('RGB')
img.save('$flat_image')
" 2>/dev/null && ocr_input="$flat_image"
    fi
  fi

  if ! ocrmypdf --image-dpi "$image_dpi" --sidecar "$sidecar_file" --output-type none "$ocr_input" /dev/null >/dev/null 2>&1; then
    echo "Error: OCRmyPDF processing failed for: $PLUGIN_FILEPATH" >&2
    exit 1
  fi
  if [ -f "$sidecar_file" ]; then
    ocr_text=$(cat "$sidecar_file")
  fi
else
  # PDF input: try pdftotext first to extract existing text layer (fast, accurate)
  if command -v pdftotext >/dev/null 2>&1; then
    ocr_text=$(pdftotext "$PLUGIN_FILEPATH" - 2>/dev/null) || ocr_text=""
  fi

  # If pdftotext yielded no text (scanned PDF), fall back to ocrmypdf OCR
  if [ -z "$(echo "$ocr_text" | tr -d '[:space:]')" ]; then
    if ! ocrmypdf --sidecar "$sidecar_file" --output-type none "$PLUGIN_FILEPATH" /dev/null >/dev/null 2>&1; then
      echo "Error: OCRmyPDF processing failed for: $PLUGIN_FILEPATH" >&2
      exit 1
    fi
    if [ -f "$sidecar_file" ]; then
      ocr_text=$(cat "$sidecar_file")
    fi
  fi
fi

jq -n --arg ocrText "$ocr_text" '{ocrText: $ocrText}'
