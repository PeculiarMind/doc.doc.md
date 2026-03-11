#!/bin/bash
# file plugin - process command
# Reads JSON input from stdin with a filePath parameter,
# detects MIME type using the 'file' command, and outputs JSON to stdout.
# Works on both Linux and macOS.
# Exit codes: 0 success (EX_OK), 1 failure — exit 65 not applicable (all file types handled)
# Exit code contract: ADR-004 (project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md)

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../components/plugin_input.sh"

plugin_read_input
plugin_validate_filepath

# Detect MIME type using file command
# -b: brief (no filename prefix), --mime-type: output MIME type only
mimeType=$(file --mime-type -b "$PLUGIN_FILEPATH" | tr -d '[:space:]')

# Output valid JSON using jq
jq -n --arg mimeType "$mimeType" '{mimeType: $mimeType}'