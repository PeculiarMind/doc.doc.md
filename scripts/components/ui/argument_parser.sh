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
TEMPLATE_FILE=""
TARGET_DIR=""
WORKSPACE_DIR=""
FORCE_FULLSCAN="false"

# ==============================================================================
# Argument Parsing Functions
# ==============================================================================

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
        FORCE_FULLSCAN="true"
        log "INFO" "PARSER" "Full scan mode enabled"
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

# Validate parsed arguments (future use)
validate_arguments() {
  # Placeholder for argument validation
  return 0
}
