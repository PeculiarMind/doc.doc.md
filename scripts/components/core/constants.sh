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
