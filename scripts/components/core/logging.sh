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

# Component: logging.sh
# Purpose: Logging infrastructure with levels and formatting
# Dependencies: constants.sh
# Exports: log(), set_log_level(), is_verbose()
# Side Effects: Writes to stderr

# ==============================================================================
# Global Flags
# ==============================================================================
VERBOSE=false

# ==============================================================================
# Logging Functions
# ==============================================================================

# Log message with level, timestamp, and component
# Arguments:
#   $1 - Log level (INFO, WARN, ERROR, DEBUG)
#   $2 - Component identifier (e.g., MAIN, PARSER, PLUGIN)
#   $3 - Message to log
log() {
  local level="$1"
  local component="$2"
  local message="$3"
  
  # Generate ISO 8601 timestamp in UTC
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S")
  
  if [[ "${VERBOSE}" == true ]] || [[ "${level}" == "ERROR" ]] || [[ "${level}" == "WARN" ]]; then
    echo "[${timestamp}] [${level}] [${component}] ${message}" >&2
  fi
}

# Set log level (enable/disable verbose)
# Arguments:
#   $1 - "true" to enable verbose, "false" to disable
set_log_level() {
  local verbose_flag="$1"
  VERBOSE="${verbose_flag}"
}

# Check if verbose mode is enabled
# Returns:
#   0 if verbose is true, 1 otherwise
is_verbose() {
  [[ "${VERBOSE}" == true ]]
}
