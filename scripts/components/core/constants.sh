#!/usr/bin/env bash
# Component: constants.sh
# Purpose: Global constants, configuration defaults, version info
# Dependencies: None
# Exports: VERSION, DEFAULT_*, EXIT_CODE_*, SCRIPT_*
# Side Effects: None (pure data)

# ==============================================================================
# Script Metadata
# ==============================================================================
readonly SCRIPT_NAME="doc.doc.sh"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly SCRIPT_COPYRIGHT="Copyright (c) 2026 doc.doc.md Project"
readonly SCRIPT_LICENSE="GPL-3.0"

# ==============================================================================
# Exit Codes
# ==============================================================================
readonly EXIT_SUCCESS=0
readonly EXIT_INVALID_ARGS=1
readonly EXIT_FILE_ERROR=2
readonly EXIT_PLUGIN_ERROR=3
readonly EXIT_REPORT_ERROR=4
readonly EXIT_WORKSPACE_ERROR=5
