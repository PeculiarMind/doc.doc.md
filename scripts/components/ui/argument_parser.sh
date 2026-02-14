#!/usr/bin/env bash
# Component: argument_parser.sh
# Purpose: CLI argument parsing and validation
# Dependencies: core/logging.sh, core/error_handling.sh, ui/help_system.sh, ui/version_info.sh
# Exports: parse_arguments(), validate_arguments()
# Side Effects: Sets global config variables, may exit on errors or help/version flags

# ==============================================================================
# Parsed Argument Variables
# ==============================================================================
SOURCE_DIR=""
SINGLE_FILE=""
TEMPLATE_FILE=""
TARGET_DIR=""
WORKSPACE_DIR=""
FORCE_FULLSCAN="false"
CONFIG_FILE=""

# Plugin activation overrides (associative arrays)
declare -gA PLUGIN_ACTIVATION_OVERRIDES

# ==============================================================================
# Argument Parsing Functions
# ==============================================================================

# Load configuration file and apply plugin activation settings
# Arguments:
#   $1 - Path to configuration file (JSON format)
load_config_file() {
  local config_path="$1"
  
  if [[ ! -f "${config_path}" ]]; then
    log "WARN" "PARSER" "Configuration file not found: ${config_path}"
    return 1
  fi
  
  log "DEBUG" "PARSER" "Loading configuration from: ${config_path}"
  
  # Parse plugin activation settings from config file using jq
  if command -v jq >/dev/null 2>&1; then
    # Extract plugin activation settings if they exist
    # Format: { "plugins": { "plugin-name": { "active": true }, ... } }
    local plugins_obj
    plugins_obj=$(jq -r '.plugins // {}' "${config_path}" 2>/dev/null)
    
    if [[ "${plugins_obj}" != "{}" ]]; then
      # Iterate over each plugin in the config
      local plugin_names
      plugin_names=$(echo "${plugins_obj}" | jq -r 'keys[]' 2>/dev/null)
      
      while IFS= read -r plugin_name; do
        if [[ -n "${plugin_name}" ]]; then
          local plugin_active
          plugin_active=$(echo "${plugins_obj}" | jq -r ".\"${plugin_name}\".active // empty" 2>/dev/null)
          
          if [[ -n "${plugin_active}" ]]; then
            PLUGIN_ACTIVATION_OVERRIDES["${plugin_name}"]="${plugin_active}"
            log "DEBUG" "PARSER" "Config override for ${plugin_name}: active=${plugin_active}"
          fi
        fi
      done <<< "${plugin_names}"
    fi
  else
    log "WARN" "PARSER" "jq not available, cannot parse configuration file"
    return 1
  fi
  
  return 0
}

# Parse command-line arguments
# Arguments:
#   $@ - Command-line arguments
# Side Effects:
#   May set global variables (VERBOSE, SOURCE_DIR, TEMPLATE_FILE, TARGET_DIR, WORKSPACE_DIR, FORCE_FULLSCAN)
#   May call show_help/show_version and exit
#   May exit on invalid arguments
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
      --help-plugins)
        show_help_plugins
        exit "${EXIT_SUCCESS}"
        ;;
      --help-template)
        show_help_template
        exit "${EXIT_SUCCESS}"
        ;;
      --help-examples)
        show_help_examples
        exit "${EXIT_SUCCESS}"
        ;;
      --list-templates)
        list_templates
        exit "${EXIT_SUCCESS}"
        ;;
      -v|--verbose)
        set_log_level true
        log "INFO" "PARSER" "Verbose mode enabled"
        shift
        ;;
      --version)
        show_version
        exit "${EXIT_SUCCESS}"
        ;;
      -d)
        if [[ $# -lt 2 ]] || [[ "$2" == -* ]]; then
          echo "Error: -d requires a directory argument" >&2
          echo "Try '$SCRIPT_NAME --help' for more information." >&2
          exit "${EXIT_INVALID_ARGS}"
        fi
        SOURCE_DIR="$2"
        log "INFO" "PARSER" "Source directory: $2"
        shift 2
        ;;
      -m)
        if [[ $# -lt 2 ]] || [[ "$2" == -* ]]; then
          echo "Error: -m requires a template file argument" >&2
          echo "Try '$SCRIPT_NAME --help' for more information." >&2
          exit "${EXIT_INVALID_ARGS}"
        fi
        TEMPLATE_FILE="$2"
        log "INFO" "PARSER" "Template file: $2"
        shift 2
        ;;
      -t)
        if [[ $# -lt 2 ]] || [[ "$2" == -* ]]; then
          echo "Error: -t requires a target directory argument" >&2
          echo "Try '$SCRIPT_NAME --help' for more information." >&2
          exit "${EXIT_INVALID_ARGS}"
        fi
        TARGET_DIR="$2"
        log "INFO" "PARSER" "Target directory: $2"
        shift 2
        ;;
      -w)
        if [[ $# -lt 2 ]] || [[ "$2" == -* ]]; then
          echo "Error: -w requires a workspace argument" >&2
          echo "Try '$SCRIPT_NAME --help' for more information." >&2
          exit "${EXIT_INVALID_ARGS}"
        fi
        WORKSPACE_DIR="$2"
        log "INFO" "PARSER" "Workspace directory: $2"
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
        # Check if next argument exists and is not a flag
        if [[ $# -ge 2 ]] && [[ "$2" != -* ]]; then
          # Single file analysis mode
          SINGLE_FILE="$2"
          log "INFO" "PARSER" "Single file analysis: $2"
          shift 2
        else
          # Force full scan mode (backward compatibility)
          FORCE_FULLSCAN="true"
          log "INFO" "PARSER" "Full scan mode enabled"
          shift
        fi
        ;;
      --config)
        if [[ $# -lt 2 ]] || [[ "$2" == -* ]]; then
          echo "Error: --config requires a configuration file argument" >&2
          echo "Try '$SCRIPT_NAME --help' for more information." >&2
          exit "${EXIT_INVALID_ARGS}"
        fi
        CONFIG_FILE="$2"
        log "INFO" "PARSER" "Configuration file: $2"
        # Load config file and apply plugin activation settings
        load_config_file "$2"
        shift 2
        ;;
      --activate-plugin)
        if [[ $# -lt 2 ]] || [[ "$2" == -* ]]; then
          echo "Error: --activate-plugin requires a plugin name argument" >&2
          echo "Try '$SCRIPT_NAME --help' for more information." >&2
          exit "${EXIT_INVALID_ARGS}"
        fi
        PLUGIN_ACTIVATION_OVERRIDES["$2"]="true"
        log "INFO" "PARSER" "Plugin activation override: $2 = true"
        shift 2
        ;;
      --deactivate-plugin)
        if [[ $# -lt 2 ]] || [[ "$2" == -* ]]; then
          echo "Error: --deactivate-plugin requires a plugin name argument" >&2
          echo "Try '$SCRIPT_NAME --help' for more information." >&2
          exit "${EXIT_INVALID_ARGS}"
        fi
        PLUGIN_ACTIVATION_OVERRIDES["$2"]="false"
        log "INFO" "PARSER" "Plugin activation override: $2 = false"
        shift 2
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

# Validate parsed arguments (future use)
validate_arguments() {
  # Check for conflicting arguments
  if [[ -n "${SINGLE_FILE}" ]] && [[ -n "${SOURCE_DIR}" ]]; then
    echo "Error: Cannot specify both -d (directory) and -f (single file)" >&2
    echo "Try '$SCRIPT_NAME --help' for more information." >&2
    exit "${EXIT_INVALID_ARGS}"
  fi
  
  # Validate single file if specified
  if [[ -n "${SINGLE_FILE}" ]]; then
    # Security: Canonicalize path to prevent path traversal (CWE-22)
    local canonical_path
    canonical_path=$(realpath -e "${SINGLE_FILE}" 2>/dev/null)
    
    if [[ $? -ne 0 ]] || [[ -z "${canonical_path}" ]]; then
      echo "Error: File does not exist: ${SINGLE_FILE}" >&2
      exit "${EXIT_FILE_ERROR}"
    fi
    
    # Security: Validate file type (reject devices, FIFOs, sockets, etc.)
    # This also validates symlink targets
    # Note: SOURCE_DIR is not set in single-file mode, so symlink validation is skipped
    if [[ ! -f "${canonical_path}" ]]; then
      echo "Error: Not a regular file: ${SINGLE_FILE}" >&2
      exit "${EXIT_FILE_ERROR}"
    fi
    
    if [[ -c "${canonical_path}" ]] || [[ -b "${canonical_path}" ]] || [[ -p "${canonical_path}" ]] || [[ -S "${canonical_path}" ]]; then
      echo "Error: Special file type not supported: ${SINGLE_FILE}" >&2
      exit "${EXIT_FILE_ERROR}"
    fi
    
    # Update SINGLE_FILE to canonical path
    SINGLE_FILE="${canonical_path}"
    log "INFO" "PARSER" "Validated single file: ${canonical_path}"
    
    # Set default workspace and target directories for single-file mode if not specified
    if [[ -z "${WORKSPACE_DIR}" ]]; then
      WORKSPACE_DIR="./doc.doc.workspace"
      log "INFO" "PARSER" "Using default workspace directory: ${WORKSPACE_DIR}"
    fi
    
    if [[ -z "${TARGET_DIR}" ]]; then
      TARGET_DIR="./doc.doc.output"
      log "INFO" "PARSER" "Using default target directory: ${TARGET_DIR}"
    fi
  fi
  
  # Set default template if not specified
  if [[ -z "${TEMPLATE_FILE}" ]]; then
    local default_template="${SCRIPT_DIR}/templates/default.md"
    
    if [[ -f "${default_template}" ]]; then
      TEMPLATE_FILE="${default_template}"
      log "INFO" "PARSER" "Using default template: ${default_template}"
    else
      # Only error if we're actually doing an analysis (have source dir or single file)
      if [[ -n "${SOURCE_DIR}" ]] || [[ -n "${SINGLE_FILE}" ]]; then
        echo "Error: Default template not found at ${default_template}" >&2
        echo "Please specify a template with -m flag or restore the default template." >&2
        exit "${EXIT_FILE_ERROR}"
      fi
    fi
  else
    log "INFO" "PARSER" "Using custom template: ${TEMPLATE_FILE}"
  fi
  
  return 0
}
