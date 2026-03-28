#!/bin/bash
# langid plugin - install command
# Installs the langid Python package via pip.
# Output: JSON {"success": bool, "message": string} to stdout

if python3 -c "import langid" >/dev/null 2>&1; then
  jq -n '{success: true, message: "langid is already installed."}'
  exit 0
fi

if pip install langid >/dev/null 2>&1 || pip3 install langid >/dev/null 2>&1; then
  jq -n '{success: true, message: "langid installed successfully via pip."}'
  exit 0
else
  jq -n '{success: false, message: "Failed to install langid. Try: pip install langid"}'
  exit 1
fi
