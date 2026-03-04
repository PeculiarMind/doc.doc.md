#!/bin/bash
# ocrmypdf plugin - install command
# Installs ocrmypdf and pdftotext (poppler-utils) if not already available.
# Tries pip install for ocrmypdf and apt-get/brew for poppler-utils.
# Output: JSON {"success": bool, "message": string} to stdout
# Exit code: 0 on success, 1 if installation could not be completed

ocrmypdf_ok=false
pdftotext_ok=false

command -v ocrmypdf >/dev/null 2>&1 && ocrmypdf_ok=true
command -v pdftotext >/dev/null 2>&1 && pdftotext_ok=true

# If both are already available, report success immediately
if [ "$ocrmypdf_ok" = true ] && [ "$pdftotext_ok" = true ]; then
  jq -n '{success: true, message: "ocrmypdf and pdftotext are already available"}'
  exit 0
fi

# Attempt to install missing tools
if [ "$pdftotext_ok" = false ]; then
  if command -v apt-get >/dev/null 2>&1; then
    apt-get install -y poppler-utils >/dev/null 2>&1 && pdftotext_ok=true
  elif command -v brew >/dev/null 2>&1; then
    brew install poppler >/dev/null 2>&1 && pdftotext_ok=true
  fi
  # Re-check after installation attempt
  command -v pdftotext >/dev/null 2>&1 && pdftotext_ok=true
fi

if [ "$ocrmypdf_ok" = false ]; then
  if command -v pip >/dev/null 2>&1; then
    pip install ocrmypdf >/dev/null 2>&1 && ocrmypdf_ok=true
  elif command -v pip3 >/dev/null 2>&1; then
    pip3 install ocrmypdf >/dev/null 2>&1 && ocrmypdf_ok=true
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get install -y ocrmypdf >/dev/null 2>&1 && ocrmypdf_ok=true
  fi
  # Re-check after installation attempt
  command -v ocrmypdf >/dev/null 2>&1 && ocrmypdf_ok=true
fi

if [ "$ocrmypdf_ok" = true ] && [ "$pdftotext_ok" = true ]; then
  jq -n '{success: true, message: "ocrmypdf and pdftotext installed successfully"}'
  exit 0
else
  missing=""
  [ "$ocrmypdf_ok" = false ] && missing="ocrmypdf"
  if [ "$pdftotext_ok" = false ]; then
    [ -n "$missing" ] && missing="$missing and pdftotext" || missing="pdftotext"
  fi
  jq -n --arg msg "Could not install: $missing. Install manually: pip install ocrmypdf && apt-get install poppler-utils" \
    '{success: false, message: $msg}'
  exit 1
fi
