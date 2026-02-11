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
# Purpose: Mode-aware logging with structured output for non-interactive mode
# Dependencies: constants.sh, mode_detection.sh (optional, for IS_INTERACTIVE)
# Exports: log(), set_log_level(), is_verbose(), log_progress_milestone()
# Side Effects: Writes to stderr
#
# Component Tags: INIT, SCAN, PLUGIN, WORKSPACE, TOOL, TEMPLATE, REPORT, MAIN

# ==============================================================================
# Global Flags
# ==============================================================================
VERBOSE=false

# ==============================================================================
# Internal Helpers
# ==============================================================================

# Sanitize a log message value to prevent log injection (CWE-117)
# Replaces newlines, carriage returns, and strips control characters
_sanitize_log_value() {
  local value="$1"
  # Replace carriage returns and newlines with literal representations
  value="${value//$'\r'/\\r}"
  value="${value//$'\n'/\\n}"
  # Remove remaining control characters (0x00-0x1F except tab, and 0x7F)
  # Using tr to strip non-printable characters while preserving tabs
  printf '%s' "$value" | LC_ALL=C tr -d '\000-\010\013-\037\177'
}

# ==============================================================================
# Logging Functions
# ==============================================================================

# Log message with level, timestamp, and component
# Supports mode-aware output:
#   - Non-interactive (IS_INTERACTIVE=false): structured format with ISO 8601 timestamp
#   - Interactive (IS_INTERACTIVE=true): human-friendly format with colors
#   - Legacy (IS_INTERACTIVE unset): original behavior for backward compatibility
#
# Arguments (3-arg form):
#   $1 - Log level (INFO, WARN, ERROR, DEBUG)
#   $2 - Component tag (INIT, SCAN, PLUGIN, WORKSPACE, TOOL, TEMPLATE, REPORT, MAIN)
#   $3 - Message to log
#
# Arguments (2-arg form, backward compatible):
#   $1 - Log level
#   $2 - Message (component defaults to MAIN)
log() {
  local level="$1"
  local component="$2"
  local message="$3"

  # Support 2-arg backward compatible form: log LEVEL MESSAGE
  if [[ -z "$message" ]]; then
    message="$component"
    component="MAIN"
  fi

  # DEBUG only shown in verbose mode (all modes)
  if [[ "${level}" == "DEBUG" ]] && [[ "${VERBOSE}" != true ]]; then
    return
  fi

  # Sanitize message to prevent log injection
  message="$(_sanitize_log_value "$message")"

  # Route to mode-specific formatter (all output to >&2)
  # ERROR and WARN levels are always shown; INFO shown in non-interactive or verbose
  if [[ "${IS_INTERACTIVE:-}" == "true" ]]; then
    _log_interactive "$level" "$message"
  elif [[ "${IS_INTERACTIVE:-}" == "false" ]]; then
    _log_structured "$level" "$component" "$message"
  else
    # Legacy behavior: no IS_INTERACTIVE set (backward compatibility)
    _log_legacy "$level" "$component" "$message"
  fi
}

# Structured format for non-interactive mode
# Format: [YYYY-MM-DDTHH:MM:SSZ] [LEVEL] [COMPONENT ] message
_log_structured() {
  local level="$1"
  local component="$2"
  local message="$3"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Fixed-width component tag (9 chars, right-padded)
  local component_fmt
  component_fmt=$(printf "%-9s" "$component")

  printf '[%s] [%-5s] [%s] %s\n' "$timestamp" "$level" "$component_fmt" "$message" >&2
}

# Human-friendly format for interactive mode
_log_interactive() {
  local level="$1"
  local message="$2"

  case "$level" in
    ERROR)
      echo -e "\033[31m[ERROR]\033[0m ${message}" >&2
      ;;
    WARN)
      echo -e "\033[33m[WARN]\033[0m ${message}" >&2
      ;;
    INFO)
      echo "$message" >&2
      ;;
    DEBUG)
      # DEBUG only reaches here if VERBOSE is true
      echo "[DEBUG] ${message}" >&2
      ;;
  esac
}

# Legacy behavior when IS_INTERACTIVE is not set (backward compatibility)
_log_legacy() {
  local level="$1"
  local component="$2"
  local message="$3"
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

# ==============================================================================
# Progress Milestone Logging
# ==============================================================================

# Log progress milestones for non-interactive monitoring
# Logs at 10% intervals or every 50 items, whichever comes first
# Arguments:
#   $1 - Number of items processed so far
#   $2 - Total number of items
#   $3 - Component tag (optional, defaults to SCAN)
log_progress_milestone() {
  local processed="$1"
  local total="$2"
  local component="${3:-SCAN}"

  # Guard against division by zero
  if [[ "$total" -le 0 ]] 2>/dev/null; then
    return
  fi

  local percent=$(( processed * 100 / total ))

  # Log at every 50 items or when crossing a 10% boundary
  if (( processed % 50 == 0 )) || \
     (( processed > 1 && ( (processed - 1) * 100 / total ) / 10 < percent / 10 )); then
    log "INFO" "$component" "Milestone: ${processed}/${total} files processed (${percent}%)"
  fi
}
