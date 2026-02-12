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

# Component: prompt_system.sh
# Purpose: User prompt and confirmation system for interactive mode
# Dependencies: core/mode_detection.sh, core/logging.sh
# Exports: prompt_yes_no(), prompt_tool_installation()
# Side Effects: Reads from stdin (interactive mode only)

# ==============================================================================
# Constants
# ==============================================================================

# Maximum number of prompt retry attempts before using default
readonly _PROMPT_MAX_ATTEMPTS=3

# ==============================================================================
# User Prompt Functions
# ==============================================================================

# Prompt user for a yes/no confirmation
# In non-interactive mode, returns the default immediately without prompting.
# Supports DOC_DOC_PROMPT_RESPONSE environment variable for testing.
#
# Arguments:
#   $1 - Prompt message to display
#   $2 - Default response ("y" or "n"), defaults to "n"
# Returns:
#   0 for yes, 1 for no
prompt_yes_no() {
  local message="$1"
  local default="${2:-n}"

  # Normalize default to lowercase
  default="${default,,}"
  if [[ "$default" != "y" && "$default" != "n" ]]; then
    default="n"
  fi

  # Testing override: DOC_DOC_PROMPT_RESPONSE forces a specific response
  if [[ -n "${DOC_DOC_PROMPT_RESPONSE:-}" ]]; then
    local forced="${DOC_DOC_PROMPT_RESPONSE,,}"
    if [[ "$forced" == "y" || "$forced" == "yes" ]]; then
      log "INFO" "MAIN" "Prompt auto-answered 'yes' via DOC_DOC_PROMPT_RESPONSE: ${message}"
      return 0
    else
      log "INFO" "MAIN" "Prompt auto-answered 'no' via DOC_DOC_PROMPT_RESPONSE: ${message}"
      return 1
    fi
  fi

  # Non-interactive mode: return default immediately
  if [[ "${IS_INTERACTIVE:-}" != "true" ]]; then
    if [[ "$default" == "y" ]]; then
      log "INFO" "MAIN" "Non-interactive mode, auto-accepting (default=yes): ${message}"
      return 0
    else
      log "INFO" "MAIN" "Non-interactive mode, auto-declining (default=no): ${message}"
      return 1
    fi
  fi

  # Build the prompt hint: [Y/n] or [y/N]
  local hint
  if [[ "$default" == "y" ]]; then
    hint="[Y/n]"
  else
    hint="[y/N]"
  fi

  # Interactive mode: prompt the user
  local attempt=0
  local response
  while (( attempt < _PROMPT_MAX_ATTEMPTS )); do
    printf '%s %s ' "$message" "$hint" >&2
    read -r response

    # Empty response uses default
    if [[ -z "$response" ]]; then
      response="$default"
    fi

    # Normalize to lowercase
    response="${response,,}"

    case "$response" in
      y|yes)
        log "DEBUG" "MAIN" "User confirmed: ${message}"
        return 0
        ;;
      n|no)
        log "DEBUG" "MAIN" "User declined: ${message}"
        return 1
        ;;
      *)
        attempt=$((attempt + 1))
        if (( attempt < _PROMPT_MAX_ATTEMPTS )); then
          printf "Please enter 'y' or 'n'.\n" >&2
        fi
        ;;
    esac
  done

  # Max attempts reached, use default
  log "WARN" "MAIN" "Max prompt attempts reached, using default '${default}': ${message}"
  if [[ "$default" == "y" ]]; then
    return 0
  else
    return 1
  fi
}

# ==============================================================================
# Tool Installation Prompt
# ==============================================================================

# Prompt user to install a tool, then execute the install command if confirmed.
# SECURITY: Does NOT use eval. Executes via bash -c with timeout.
#
# Arguments:
#   $1 - Name of tool to install
#   $2 - Command to install the tool (passed to bash -c, NOT eval)
# Returns:
#   0 if installed successfully, 1 if declined or failed
prompt_tool_installation() {
  local tool_name="$1"
  local install_command="$2"

  log "INFO" "TOOL" "Tool installation requested: ${tool_name}"

  # Ask user for confirmation
  if ! prompt_yes_no "Install ${tool_name}?" "n"; then
    log "INFO" "TOOL" "Tool installation declined: ${tool_name}"
    return 1
  fi

  log "INFO" "TOOL" "Installing tool: ${tool_name}"

  # Execute install command safely via bash -c with a timeout
  # SECURITY (F4): No eval used. Command runs in a subprocess with timeout.
  local exit_code=0
  if command -v timeout >/dev/null 2>&1; then
    timeout 120 bash -c "$install_command" || exit_code=$?
  else
    bash -c "$install_command" || exit_code=$?
  fi

  if [[ "$exit_code" -eq 0 ]]; then
    log "INFO" "TOOL" "Tool installed successfully: ${tool_name}"
    return 0
  else
    log "ERROR" "TOOL" "Tool installation failed (exit code ${exit_code}): ${tool_name}"
    return 1
  fi
}
