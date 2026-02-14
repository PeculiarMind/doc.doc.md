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

# Component: plugin_tool_checker.sh
# Purpose: Tool availability verification and installation guidance
# Dependencies: core/logging.sh, core/constants.sh, core/platform_detection.sh, plugin/plugin_parser.sh
# Exports: verify_plugin_tools(), check_tool_availability(), get_install_guidance(), prompt_tool_install(), get_plugin_tool_status()
# Side Effects: May execute installation commands with user confirmation

# ==============================================================================
# Tool Verification Functions
# ==============================================================================

# Check if a tool is available by running a check command
# Arguments:
#   $1 - Check command string to execute
# Returns:
#   0 if tool is available, 1 if not
check_tool_availability() {
  local check_command="$1"

  if [[ -z "${check_command}" ]]; then
    log "WARN" "TOOLCHECK" "Empty check command provided"
    return 1
  fi

  log "DEBUG" "TOOLCHECK" "Checking tool availability: ${check_command}"

  if bash -c "${check_command}" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Get platform-specific installation guidance
# Arguments:
#   $1 - Install command from descriptor (may be empty)
#   $2 - Platform identifier (ubuntu, debian, darwin, etc.)
# Returns:
#   Echoes install command string on stdout
get_install_guidance() {
  local install_command="$1"
  local platform="${2:-generic}"

  if [[ -n "${install_command}" ]] && [[ "${install_command}" != "null" ]]; then
    echo "${install_command}"
    return 0
  fi

  # Fallback to generic platform-specific guidance
  case "${platform}" in
    ubuntu|debian)
      echo "apt install <package-name>"
      ;;
    darwin)
      echo "brew install <package-name>"
      ;;
    alpine)
      echo "apk add <package-name>"
      ;;
    *)
      echo "Please install the required tool using your system package manager"
      ;;
  esac
  return 0
}

# Prompt user to install a missing tool
# Arguments:
#   $1 - Tool/plugin name
#   $2 - Install command to execute
# Returns:
#   0 on successful installation, 1 on failure or decline
prompt_tool_install() {
  local tool_name="$1"
  local install_command="$2"

  # Only prompt if stdin is a TTY
  if [[ ! -t 0 ]]; then
    log "DEBUG" "TOOLCHECK" "Not a TTY, skipping install prompt for: ${tool_name}"
    return 1
  fi

  if [[ -z "${install_command}" ]] || [[ "${install_command}" == "null" ]]; then
    log "WARN" "TOOLCHECK" "No install command available for: ${tool_name}"
    return 1
  fi

  local response
  read -p "Install ${tool_name}? [y/N] " -r response

  if [[ "${response}" =~ ^[Yy]$ ]]; then
    log "INFO" "TOOLCHECK" "Installing ${tool_name}: ${install_command}"
    if bash -c "${install_command}"; then
      log "INFO" "TOOLCHECK" "Installation command completed for: ${tool_name}"
      return 0
    else
      log "ERROR" "TOOLCHECK" "Installation failed for: ${tool_name}"
      return 1
    fi
  else
    log "INFO" "TOOLCHECK" "User declined installation of: ${tool_name}"
    return 1
  fi
}

# Get tool status summary for all plugins
# Arguments:
#   $1 - Plugins directory path
# Returns:
#   Echoes "plugin_name|tool_name|status" for each plugin (one per line)
#   Status is "available" or "missing"
get_plugin_tool_status() {
  local plugins_dir="$1"

  if [[ ! -d "${plugins_dir}" ]]; then
    log "ERROR" "TOOLCHECK" "Plugins directory not found: ${plugins_dir}"
    return 1
  fi

  log "DEBUG" "TOOLCHECK" "Getting tool status for plugins in: ${plugins_dir}"

  while IFS= read -r -d '' descriptor_file; do
    local plugin_name check_command

    plugin_name=$(jq -r '.name // empty' "${descriptor_file}" 2>/dev/null)
    if [[ -z "${plugin_name}" ]]; then
      continue
    fi

    # Skip tool status check for inactive plugins
    local plugin_active
    if declare -p PLUGIN_ACTIVATION_OVERRIDES &>/dev/null && [[ -v PLUGIN_ACTIVATION_OVERRIDES["${plugin_name}"] ]]; then
      plugin_active="${PLUGIN_ACTIVATION_OVERRIDES[${plugin_name}]}"
    else
      plugin_active=$(jq -r 'if has("active") then .active else true end' "${descriptor_file}" 2>/dev/null)
    fi
    if [[ "${plugin_active}" == "false" ]]; then
      log "DEBUG" "TOOLCHECK" "Skipping tool status for inactive plugin: ${plugin_name}"
      echo "${plugin_name}|${plugin_name}|inactive"
      continue
    fi

    check_command=$(jq -r '.check_commandline // empty' "${descriptor_file}" 2>/dev/null)
    if [[ -z "${check_command}" ]]; then
      echo "${plugin_name}|${plugin_name}|missing"
      continue
    fi

    if check_tool_availability "${check_command}"; then
      echo "${plugin_name}|${plugin_name}|available"
    else
      echo "${plugin_name}|${plugin_name}|missing"
    fi
  done < <(find "${plugins_dir}" -name "descriptor.json" -type f -print0 2>/dev/null)

  return 0
}

# Main verification function - scans all plugins and reports tool status
# Arguments:
#   $1 - Plugins directory path
#   $2 - Interactive mode ("true" or "false")
# Returns:
#   Count of missing tools (0 = all OK)
verify_plugin_tools() {
  local plugins_dir="$1"
  local interactive="${2:-false}"
  local missing_count=0

  if [[ ! -d "${plugins_dir}" ]]; then
    log "ERROR" "TOOLCHECK" "Plugins directory not found: ${plugins_dir}"
    return 1
  fi

  log "INFO" "TOOLCHECK" "Verifying plugin tools in: ${plugins_dir}"

  while IFS= read -r -d '' descriptor_file; do
    local plugin_name check_command install_command

    plugin_name=$(jq -r '.name // empty' "${descriptor_file}" 2>/dev/null)
    if [[ -z "${plugin_name}" ]]; then
      log "WARN" "TOOLCHECK" "Skipping descriptor with no name: ${descriptor_file}"
      continue
    fi

    # Determine if plugin is active (CLI > Config > Descriptor)
    local plugin_active
    if declare -p PLUGIN_ACTIVATION_OVERRIDES &>/dev/null && [[ -v PLUGIN_ACTIVATION_OVERRIDES["${plugin_name}"] ]]; then
      plugin_active="${PLUGIN_ACTIVATION_OVERRIDES[${plugin_name}]}"
    else
      plugin_active=$(jq -r 'if has("active") then .active else true end' "${descriptor_file}" 2>/dev/null)
    fi

    # Skip tool verification for inactive plugins
    if [[ "${plugin_active}" == "false" ]]; then
      log "DEBUG" "TOOLCHECK" "Skipping tool check for inactive plugin: ${plugin_name}"
      continue
    fi

    check_command=$(jq -r '.check_commandline // empty' "${descriptor_file}" 2>/dev/null)
    if [[ -z "${check_command}" ]]; then
      log "WARN" "TOOLCHECK" "No check_commandline for plugin: ${plugin_name}"
      missing_count=$((missing_count + 1))
      continue
    fi

    log "DEBUG" "TOOLCHECK" "Checking tool for plugin: ${plugin_name}"

    if check_tool_availability "${check_command}"; then
      log "INFO" "TOOLCHECK" "Tool available for plugin: ${plugin_name}"
    else
      missing_count=$((missing_count + 1))
      install_command=$(jq -r '.install_commandline // empty' "${descriptor_file}" 2>/dev/null)
      local guidance
      guidance=$(get_install_guidance "${install_command}" "${PLATFORM:-generic}")

      log "WARN" "TOOLCHECK" "Missing tool for plugin '${plugin_name}'. Install with: ${guidance}"

      if [[ "${interactive}" == "true" ]]; then
        if prompt_tool_install "${plugin_name}" "${install_command}"; then
          # Re-check after installation
          if check_tool_availability "${check_command}"; then
            log "INFO" "TOOLCHECK" "Tool now available for plugin: ${plugin_name}"
            missing_count=$((missing_count - 1))
          fi
        fi
      fi
    fi
  done < <(find "${plugins_dir}" -name "descriptor.json" -type f -print0 2>/dev/null)

  log "INFO" "TOOLCHECK" "Tool verification complete. Missing tools: ${missing_count}"
  return "${missing_count}"
}
