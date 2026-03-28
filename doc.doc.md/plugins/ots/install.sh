#!/bin/bash
# ots plugin - install command
# Installs OTS via the system package manager.
# Output: JSON {"success": bool, "message": string} to stdout

if command -v ots >/dev/null 2>&1; then
  jq -n '{success: true, message: "ots is already installed."}'
  exit 0
fi

if command -v apt-get >/dev/null 2>&1; then
  if apt-get install -y ots >/dev/null 2>&1; then
    jq -n '{success: true, message: "ots installed successfully via apt."}'
    exit 0
  else
    jq -n '{success: false, message: "Failed to install ots via apt. Try: sudo apt install -y ots"}'
    exit 1
  fi
else
  jq -n '{success: false, message: "No supported package manager found. Install ots manually."}'
  exit 1
fi
