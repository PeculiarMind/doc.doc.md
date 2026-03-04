#!/bin/bash
# ocrmypdf plugin - convert command
# Reads JSON input from stdin with filePath, optional outputPath, and optional imageDpi.
# Converts an image file (JPEG, PNG, TIFF, BMP, GIF) to a searchable PDF using OCRmyPDF.
#
# Supported input types: image/jpeg, image/png, image/tiff, image/bmp, image/gif
#
# Invocation pattern:
#   ocrmypdf --image-dpi <dpi> <filePath> <outputPath>
#
# Input JSON fields:
#   filePath    - path to the input image file (required)
#   outputPath  - path for the output PDF (optional; defaults to <filePath>.pdf)
#   imageDpi    - DPI for image processing (optional; defaults to 300)
#
# Output JSON fields:
#   outputPdf   - absolute path to the generated PDF
#   success     - true on success, false on failure
#
# Exit code: 0 on success, 1 on error

set -euo pipefail

# Read JSON input from stdin (limit to 1MB to prevent memory exhaustion per REQ_SEC_009)
input=$(head -c 1048576)

# Parse input parameters
file_path=$(echo "$input" | jq -r '.filePath // empty' 2>/dev/null) || {
  jq -n '{"success": false, "error": "Invalid JSON input"}'
  exit 1
}

output_path=$(echo "$input" | jq -r '.outputPath // empty' 2>/dev/null) || output_path=""

image_dpi=$(echo "$input" | jq -r '.imageDpi // 300' 2>/dev/null) || image_dpi=300
if ! echo "$image_dpi" | grep -qE '^[0-9]+$' || [ "$image_dpi" -lt 1 ] 2>/dev/null; then
  image_dpi=300
fi

# Validate required parameters
if [ -z "$file_path" ]; then
  jq -n '{"success": false, "error": "Missing required parameter: filePath"}'
  exit 1
fi

# Validate required tools are available
if ! command -v ocrmypdf >/dev/null 2>&1; then
  echo "Error: ocrmypdf is not installed. Run the install command first." >&2
  jq -n '{"success": false, "error": "ocrmypdf is not installed"}'
  exit 1
fi

# Resolve and validate filePath (path traversal prevention per REQ_SEC_005)
resolved_path=$(readlink -f "$file_path" 2>/dev/null) || resolved_path=""
if [ -z "$resolved_path" ]; then
  jq -n --arg e "Cannot access the specified file" '{"success": false, "error": $e}'
  exit 1
fi

# Reject paths in dangerous system directories
case "$resolved_path" in
  /proc/*|/proc|/dev/*|/dev|/sys/*|/sys|/etc/*|/etc)
    jq -n --arg e "Cannot access the specified file" '{"success": false, "error": $e}'
    exit 1
    ;;
esac

# Validate file exists and is readable
if [ ! -f "$resolved_path" ] || [ ! -r "$resolved_path" ]; then
  jq -n --arg e "Cannot access the specified file" '{"success": false, "error": $e}'
  exit 1
fi

# Detect MIME type
mime_type=""
if command -v file >/dev/null 2>&1; then
  mime_type=$(file --mime-type -b "$resolved_path" 2>/dev/null | tr -d '[:space:]')
fi

# Validate supported image type (convert only handles images, not PDFs)
is_supported_image=false
case "$mime_type" in
  image/jpeg|image/png|image/tiff|image/bmp|image/gif)
    is_supported_image=true
    ;;
esac

if [ "$is_supported_image" = false ]; then
  jq -n --arg m "${mime_type:-unknown}" \
    '{"success": false, "error": ("Unsupported file type for convert command (detected MIME type: " + $m + "). Supported types: image/jpeg, image/png, image/tiff, image/bmp, image/gif.")}'
  exit 1
fi

# Determine output path
if [ -z "$output_path" ]; then
  # Default: place output PDF next to input file with .pdf extension
  output_path="${resolved_path%.*}.pdf"
fi

# Resolve output path
output_dir=$(dirname "$output_path")
if [ ! -d "$output_dir" ]; then
  jq -n --arg d "$output_dir" '{"success": false, "error": ("Output directory does not exist: " + $d)}'
  exit 1
fi

resolved_output=$(readlink -m "$output_path" 2>/dev/null) || {
  jq -n '{"success": false, "error": "Invalid output path"}'
  exit 1
}

# Run ocrmypdf to convert image to searchable PDF
if ! ocrmypdf --image-dpi "$image_dpi" "$resolved_path" "$resolved_output" >/dev/null 2>&1; then
  jq -n --arg p "$resolved_path" '{"success": false, "error": ("OCRmyPDF conversion failed for: " + $p)}'
  exit 1
fi

# Output success JSON
jq -n \
  --arg outputPdf "$resolved_output" \
  '{"outputPdf": $outputPdf, "success": true}'
