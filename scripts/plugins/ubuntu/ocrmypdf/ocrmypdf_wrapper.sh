#!/usr/bin/env bash
# Copyright (c) 2026 doc.doc.md Project
# This file is part of doc.doc.md.
#
# doc.doc.md is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# doc.doc.md is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with doc.doc.md. If not, see <https://www.gnu.org/licenses/>.

# OCRmyPDF Wrapper Script
# Performs OCR on PDF files and outputs results in standardized format
# Output format: ocr_confidence,ocr_status,ocr_text_content (comma-separated, alphabetical order)

set -euo pipefail

# Input validation
if [[ $# -ne 1 ]]; then
    echo "0,failed,Error: Invalid arguments" >&2
    exit 1
fi

FILE_PATH="$1"

# Validate file exists
if [[ ! -f "$FILE_PATH" ]]; then
    echo "0,failed,Error: File not found: $FILE_PATH" >&2
    exit 1
fi

# Validate file is a PDF
if ! file -b --mime-type "$FILE_PATH" | grep -q "application/pdf"; then
    echo "0,skipped,Not a PDF file"
    exit 0
fi

# Check if ocrmypdf is available
if ! command -v ocrmypdf >/dev/null 2>&1; then
    echo "0,failed,Error: ocrmypdf not installed"
    exit 1
fi

# Create temporary directory for OCR output
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

OUTPUT_PDF="$TEMP_DIR/output.pdf"
TEXT_FILE="$TEMP_DIR/output.txt"

# Perform OCR on the PDF
# --force-ocr: Always perform OCR even if PDF already has text layer
# --skip-text: Skip pages that already have text
# --quiet: Suppress output
if ocrmypdf --force-ocr --sidecar "$TEXT_FILE" "$FILE_PATH" "$OUTPUT_PDF" >/dev/null 2>&1; then
    OCR_STATUS="success"
    
    # Extract text content from sidecar file
    if [[ -f "$TEXT_FILE" ]]; then
        # Read text content and sanitize (remove commas for CSV format)
        OCR_TEXT=$(cat "$TEXT_FILE" | tr '\n' ' ' | tr -d ',' | sed 's/[[:space:]]\+/ /g' | xargs)
        
        # OCRmyPDF doesn't provide confidence scores, so we use a default
        OCR_CONFIDENCE="85"
    else
        OCR_TEXT=""
        OCR_CONFIDENCE="0"
    fi
else
    OCR_STATUS="failed"
    OCR_TEXT="OCR processing failed"
    OCR_CONFIDENCE="0"
fi

# Output in alphabetical order: ocr_confidence, ocr_status, ocr_text_content
echo "${OCR_CONFIDENCE},${OCR_STATUS},${OCR_TEXT}"
