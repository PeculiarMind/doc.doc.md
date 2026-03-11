#!/bin/bash
# stat plugin - process command
# Reads JSON input from stdin with a filePath parameter,
# extracts file statistics, and outputs JSON to stdout.
# Supports both Linux and macOS via platform detection.
# Exit codes: 0 success (EX_OK), 1 failure — exit 65 not applicable (all file types handled)
# Exit code contract: ADR-004 (project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md)

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../components/plugin_input.sh"

plugin_read_input
plugin_validate_filepath

# Detect platform and gather file statistics
platform=$(uname -s)

if [ "$platform" = "Darwin" ]; then
  fileSize=$(stat -f '%z' "$PLUGIN_FILEPATH")
  fileOwner=$(stat -f '%Su' "$PLUGIN_FILEPATH")
  birthEpoch=$(stat -f '%B' "$PLUGIN_FILEPATH")
  modEpoch=$(stat -f '%m' "$PLUGIN_FILEPATH")
  changeEpoch=$(stat -f '%c' "$PLUGIN_FILEPATH")

  if [ "$birthEpoch" -gt 0 ] 2>/dev/null; then
    fileCreated=$(date -r "$birthEpoch" -u '+%Y-%m-%dT%H:%M:%SZ')
  else
    fileCreated=""
  fi
  fileModified=$(date -r "$modEpoch" -u '+%Y-%m-%dT%H:%M:%SZ')
  fileMetadataChanged=$(date -r "$changeEpoch" -u '+%Y-%m-%dT%H:%M:%SZ')
else
  fileSize=$(stat -c '%s' "$PLUGIN_FILEPATH")
  fileOwner=$(stat -c '%U' "$PLUGIN_FILEPATH")
  birthEpoch=$(stat -c '%W' "$PLUGIN_FILEPATH")
  modEpoch=$(stat -c '%Y' "$PLUGIN_FILEPATH")
  changeEpoch=$(stat -c '%Z' "$PLUGIN_FILEPATH")

  if [ "$birthEpoch" -gt 0 ] 2>/dev/null; then
    fileCreated=$(date -u -d "@$birthEpoch" '+%Y-%m-%dT%H:%M:%SZ')
  else
    fileCreated=""
  fi
  fileModified=$(date -u -d "@$modEpoch" '+%Y-%m-%dT%H:%M:%SZ')
  fileMetadataChanged=$(date -u -d "@$changeEpoch" '+%Y-%m-%dT%H:%M:%SZ')
fi

jq -n \
  --argjson fileSize "$fileSize" \
  --arg fileOwner "$fileOwner" \
  --arg fileCreated "$fileCreated" \
  --arg fileModified "$fileModified" \
  --arg fileMetadataChanged "$fileMetadataChanged" \
  '{
    fileSize: $fileSize,
    fileOwner: $fileOwner,
    fileCreated: $fileCreated,
    fileModified: $fileModified,
    fileMetadataChanged: $fileMetadataChanged
  }'