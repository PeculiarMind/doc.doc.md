#!/usr/bin/env bash

# Exit on error, undefined variables, pipe failures
set -euo pipefail

# ==============================================================================
# Script Metadata
# ==============================================================================
readonly SCRIPT_NAME="doc.doc.sh"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

# ==============================================================================
# Global Flags
# ==============================================================================
VERBOSE=false
PLATFORM="generic"

# ==============================================================================
# Logging Functions
# ==============================================================================

# Log message with level
# Arguments:
#   $1 - Log level (INFO, WARN, ERROR, DEBUG)
#   $2 - Message to log
log() {
  local level="$1"
  local message="$2"
  
  if [[ "${VERBOSE}" == true ]] || [[ "${level}" == "ERROR" ]] || [[ "${level}" == "WARN" ]]; then
    echo "[${level}] ${message}" >&2
  fi
}

# ==============================================================================
# Help System
# ==============================================================================

show_help() {
  cat <<EOF
${SCRIPT_NAME} - Documentation Documentation Tool

Usage:
  ${SCRIPT_NAME} [OPTIONS]

Description:
  A lightweight Bash utility for analyzing documentation in directories,
  detecting documentation types, and generating reports. Supports plugins
  for extensibility and follows Unix tool design principles.

Options:
  -h, --help              Display this help message and exit
  -v, --verbose           Enable verbose logging output
  --version               Display version information and exit
  -d <directory>          Analyze specified directory (future)
  -m <format>             Output format: markdown, json, html (future)
  -t <types>              Filter by document types (future)
  -w <workspace>          Specify workspace directory (future)
  -p <subcommand>         Plugin operations: list (info, enable, disable - future)
  -f                      Enable fullscan mode (future)

Exit Codes:
  0  Success
  1  Invalid command-line arguments
  2  File or directory access error
  3  Plugin execution failure
  4  Report generation failure
  5  Workspace corruption or access error

Examples:
  ${SCRIPT_NAME} -h                Show this help message
  ${SCRIPT_NAME} --version         Show version information
  ${SCRIPT_NAME} -v                Run with verbose logging (future)
  ${SCRIPT_NAME} -d ./docs         Analyze docs directory (future)
  ${SCRIPT_NAME} -p list           List available plugins

For more information, see the project documentation.
EOF
}

# ==============================================================================
# Version Information
# ==============================================================================

show_version() {
  cat <<EOF
${SCRIPT_NAME} version ${SCRIPT_VERSION}
${SCRIPT_COPYRIGHT}
License: ${SCRIPT_LICENSE}

This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
}

# ==============================================================================
# Platform Detection
# ==============================================================================

detect_platform() {
  if [[ -f /etc/os-release ]]; then
    # Source the os-release file to get distribution info
    . /etc/os-release
    PLATFORM="${ID:-generic}"
  else
    # Fallback to uname if os-release is not available
    case "$(uname -s)" in
      Linux*)   PLATFORM="linux" ;;
      Darwin*)  PLATFORM="darwin" ;;
      CYGWIN*)  PLATFORM="cygwin" ;;
      MINGW*)   PLATFORM="mingw" ;;
      *)        PLATFORM="generic" ;;
    esac
  fi
  
  log "INFO" "Detected platform: ${PLATFORM}"
}

# ==============================================================================
# Error Handling
# ==============================================================================

# Handle errors with context
# Arguments:
#   $1 - Error message
#   $2 - Exit code (optional, defaults to EXIT_FILE_ERROR)
error_exit() {
  local message="$1"
  local exit_code="${2:-${EXIT_FILE_ERROR}}"
  
  log "ERROR" "${message}"
  exit "${exit_code}"
}

# ==============================================================================
# Plugin Management Functions
# ==============================================================================

# Parse plugin descriptor.json file and extract metadata
# Arguments:
#   $1 - Path to descriptor.json file
# Returns:
#   Echoes a pipe-delimited string: "name|description|active"
#   Returns empty string on error
parse_plugin_descriptor() {
  local descriptor_path="$1"
  
  if [[ ! -f "${descriptor_path}" ]]; then
    log "WARN" "Descriptor file not found: ${descriptor_path}"
    return 1
  fi
  
  if [[ ! -r "${descriptor_path}" ]]; then
    log "WARN" "Cannot read descriptor file: ${descriptor_path}"
    return 1
  fi
  
  log "DEBUG" "Parsing descriptor: ${descriptor_path}"
  
  # Use jq to parse JSON (preferred method)
  if command -v jq >/dev/null 2>&1; then
    local name description active
    
    # Extract fields using jq
    name=$(jq -r '.name // empty' "${descriptor_path}" 2>/dev/null)
    description=$(jq -r '.description // empty' "${descriptor_path}" 2>/dev/null)
    active=$(jq -r '.active // false' "${descriptor_path}" 2>/dev/null)
    
    # Validate required fields
    if [[ -z "${name}" ]]; then
      log "WARN" "Plugin descriptor missing 'name' field: ${descriptor_path}"
      return 1
    fi
    
    if [[ -z "${description}" ]]; then
      log "WARN" "Plugin descriptor missing 'description' field: ${descriptor_path}"
      return 1
    fi
    
    # Ensure active is a boolean
    if [[ "${active}" != "true" ]] && [[ "${active}" != "false" ]]; then
      log "DEBUG" "Invalid 'active' value, defaulting to false: ${descriptor_path}"
      active="false"
    fi
    
    echo "${name}|${description}|${active}"
    return 0
  else
    # Fallback to python if jq not available
    if command -v python3 >/dev/null 2>&1; then
      local result
      result=$(python3 -c "
import json
import sys
try:
    with open('${descriptor_path}', 'r') as f:
        data = json.load(f)
    name = data.get('name', '')
    description = data.get('description', '')
    active = str(data.get('active', False)).lower()
    if not name or not description:
        sys.exit(1)
    print(f'{name}|{description}|{active}')
except Exception as e:
    sys.exit(1)
" 2>&1)
      
      if [[ $? -eq 0 ]] && [[ -n "${result}" ]]; then
        echo "${result}"
        return 0
      else
        log "WARN" "Failed to parse descriptor with python: ${descriptor_path}"
        return 1
      fi
    else
      log "ERROR" "No JSON parser available (jq or python3 required)"
      error_exit "Cannot parse plugin descriptors without jq or python3" "${EXIT_PLUGIN_ERROR}"
    fi
  fi
}

# Discover all plugins in the plugins directory
# Returns:
#   Echoes newline-separated list of pipe-delimited plugin data: "name|description|active"
discover_plugins() {
  local plugins_dir="${SCRIPT_DIR}/plugins"
  
  log "DEBUG" "Searching for plugins in: ${plugins_dir}"
  
  # Check if plugins directory exists
  if [[ ! -d "${plugins_dir}" ]]; then
    error_exit "Plugins directory not found: ${plugins_dir}" "${EXIT_FILE_ERROR}"
  fi
  
  # Platform-specific directory (e.g., plugins/ubuntu/)
  local platform_dir="${plugins_dir}/${PLATFORM}"
  
  # Generic/cross-platform directory (plugins/all/)
  local all_dir="${plugins_dir}/all"
  
  # Array to store discovered plugin data
  local -a plugin_list=()
  
  # Track plugin names to handle duplicates (platform-specific takes precedence)
  declare -A seen_plugins
  
  # Discover platform-specific plugins first (higher priority)
  if [[ -d "${platform_dir}" ]]; then
    log "DEBUG" "Searching platform-specific plugins in: ${platform_dir}"
    
    while IFS= read -r -d '' descriptor_file; do
      log "DEBUG" "Found descriptor: ${descriptor_file}"
      
      local plugin_data
      if plugin_data=$(parse_plugin_descriptor "${descriptor_file}"); then
        local plugin_name="${plugin_data%%|*}"
        
        if [[ -z "${seen_plugins[${plugin_name}]+x}" ]]; then
          plugin_list+=("${plugin_data}")
          seen_plugins[${plugin_name}]=1
          log "DEBUG" "Added platform plugin: ${plugin_name}"
        fi
      fi
    done < <(find "${platform_dir}" -name "descriptor.json" -type f -print0 2>/dev/null)
  fi
  
  # Discover cross-platform plugins (lower priority)
  if [[ -d "${all_dir}" ]]; then
    log "DEBUG" "Searching cross-platform plugins in: ${all_dir}"
    
    while IFS= read -r -d '' descriptor_file; do
      log "DEBUG" "Found descriptor: ${descriptor_file}"
      
      local plugin_data
      if plugin_data=$(parse_plugin_descriptor "${descriptor_file}"); then
        local plugin_name="${plugin_data%%|*}"
        
        # Only add if not already seen (platform-specific takes precedence)
        if [[ -z "${seen_plugins[${plugin_name}]+x}" ]]; then
          plugin_list+=("${plugin_data}")
          seen_plugins[${plugin_name}]=1
          log "DEBUG" "Added cross-platform plugin: ${plugin_name}"
        else
          log "DEBUG" "Skipped duplicate plugin (platform version exists): ${plugin_name}"
        fi
      fi
    done < <(find "${all_dir}" -name "descriptor.json" -type f -print0 2>/dev/null)
  fi
  
  # Return plugin list
  if [[ ${#plugin_list[@]} -eq 0 ]]; then
    log "DEBUG" "No valid plugins found"
    return 0
  fi
  
  printf "%s\n" "${plugin_list[@]}"
}

# Display formatted plugin list
# Arguments:
#   $@ - Array of plugin data strings (name|description|active)
display_plugin_list() {
  local -a plugins=("$@")
  
  if [[ ${#plugins[@]} -eq 0 ]]; then
    echo "No plugins found."
    return
  fi
  
  echo "Available Plugins:"
  echo "===================================="
  echo
  
  # Sort plugins by name
  local -a sorted_plugins
  IFS=$'\n' sorted_plugins=($(sort <<<"${plugins[*]}"))
  unset IFS
  
  # Display each plugin
  for plugin_data in "${sorted_plugins[@]}"; do
    # Parse pipe-delimited data
    local name="${plugin_data%%|*}"
    local rest="${plugin_data#*|}"
    local description="${rest%%|*}"
    local active="${rest##*|}"
    
    # Truncate description if too long
    if [[ ${#description} -gt 80 ]]; then
      description="${description:0:77}..."
    fi
    
    # Display with status indicator
    if [[ "${active}" == "true" ]]; then
      printf "[ACTIVE]   %s\n" "${name}"
    else
      printf "[INACTIVE] %s\n" "${name}"
    fi
    printf "           %s\n\n" "${description}"
  done
}

# List all available plugins
list_plugins() {
  log "INFO" "Listing available plugins"
  
  # Discover plugins
  local plugin_data
  plugin_data=$(discover_plugins)
  
  # Convert to array
  local -a plugins=()
  while IFS= read -r line; do
    [[ -n "${line}" ]] && plugins+=("${line}")
  done <<< "${plugin_data}"
  
  # Display plugin list
  display_plugin_list "${plugins[@]}"
}

# ==============================================================================
# Argument Parsing
# ==============================================================================

parse_arguments() {
  # If no arguments, show help and exit with success
  if [[ $# -eq 0 ]]; then
    show_help
    exit "${EXIT_SUCCESS}"
  fi
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        exit "${EXIT_SUCCESS}"
        ;;
      -v|--verbose)
        VERBOSE=true
        log "INFO" "Verbose mode enabled"
        shift
        ;;
      --version)
        show_version
        exit "${EXIT_SUCCESS}"
        ;;
      -d)
        # Future: directory analysis
        if [[ $# -lt 2 ]] || [[ "$2" == -* ]]; then
          echo "Error: -d requires a directory argument" >&2
          echo "Try '$SCRIPT_NAME --help' for more information." >&2
          exit "${EXIT_INVALID_ARGS}"
        fi
        log "INFO" "Directory argument: $2 (not yet implemented)"
        shift 2
        ;;
      -m)
        # Future: output format
        if [[ $# -lt 2 ]] || [[ "$2" == -* ]]; then
          echo "Error: -m requires a format argument" >&2
          echo "Try '$SCRIPT_NAME --help' for more information." >&2
          exit "${EXIT_INVALID_ARGS}"
        fi
        log "INFO" "Format argument: $2 (not yet implemented)"
        shift 2
        ;;
      -t)
        # Future: type filtering
        if [[ $# -lt 2 ]] || [[ "$2" == -* ]]; then
          echo "Error: -t requires a type argument" >&2
          echo "Try '$SCRIPT_NAME --help' for more information." >&2
          exit "${EXIT_INVALID_ARGS}"
        fi
        log "INFO" "Type filter: $2 (not yet implemented)"
        shift 2
        ;;
      -w)
        # Future: workspace
        if [[ $# -lt 2 ]] || [[ "$2" == -* ]]; then
          echo "Error: -w requires a workspace argument" >&2
          echo "Try '$SCRIPT_NAME --help' for more information." >&2
          exit "${EXIT_INVALID_ARGS}"
        fi
        log "INFO" "Workspace argument: $2 (not yet implemented)"
        shift 2
        ;;
      -p|--plugin)
        # Plugin operations
        if [[ $# -lt 2 ]] || [[ "$2" == -* ]]; then
          echo "Error: -p requires a subcommand argument" >&2
          echo "Try '$SCRIPT_NAME --help' for more information." >&2
          exit "${EXIT_INVALID_ARGS}"
        fi
        
        local subcommand="$2"
        shift 2
        
        case "${subcommand}" in
          list)
            list_plugins
            exit "${EXIT_SUCCESS}"
            ;;
          info|enable|disable)
            echo "Error: Plugin subcommand '${subcommand}' not yet implemented" >&2
            exit "${EXIT_INVALID_ARGS}"
            ;;
          *)
            echo "Error: Unknown plugin subcommand: ${subcommand}" >&2
            echo "Available subcommands: list, info, enable, disable" >&2
            exit "${EXIT_INVALID_ARGS}"
            ;;
        esac
        ;;
      -f)
        # Future: fullscan mode
        log "INFO" "Fullscan mode (not yet implemented)"
        shift
        ;;
      -*)
        echo "Error: Unknown option: $1" >&2
        echo "Try '$SCRIPT_NAME --help' for more information." >&2
        exit "${EXIT_INVALID_ARGS}"
        ;;
      *)
        echo "Error: Unexpected argument: $1" >&2
        echo "Try '$SCRIPT_NAME --help' for more information." >&2
        exit "${EXIT_INVALID_ARGS}"
        ;;
    esac
  done
}

# ==============================================================================
# Main Entry Point
# ==============================================================================

main() {
  # Initialize platform detection
  detect_platform
  
  # Parse command-line arguments
  parse_arguments "$@"
  
  # If we get here, no action was taken (all flags processed but no work done)
  log "INFO" "Script initialization complete"
  
  exit "${EXIT_SUCCESS}"
}

# ==============================================================================
# Script Execution
# ==============================================================================

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
