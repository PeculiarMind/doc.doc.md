#!/usr/bin/env bash
# doc.doc.sh - Documentation Documentation Tool
# Main entry script for modular component architecture
# This script loads components and orchestrates the main workflow

# Exit on error, undefined variables, pipe failures
set -euo pipefail

# ==============================================================================
# Component Loading
# ==============================================================================

# Determine the components directory
readonly COMPONENTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/components" && pwd)"

# Component loading function with error handling
# Arguments:
#   $1 - Component path relative to components directory (e.g., "core/constants.sh")
source_component() {
  local component="$1"
  local component_path="${COMPONENTS_DIR}/${component}"
  
  if [[ -f "${component_path}" ]]; then
    source "${component_path}" || {
      echo "ERROR: Failed to load component: ${component}" >&2
      exit 1
    }
  else
    echo "ERROR: Component not found: ${component}" >&2
    exit 1
  fi
}

# Load components in dependency order
# Core components (no dependencies)
source_component "core/constants.sh"
source_component "core/version_generator.sh"
source_component "core/logging.sh"
source_component "core/mode_detection.sh"
source_component "core/error_handling.sh"
source_component "core/platform_detection.sh"

# UI components (depend on core)
source_component "ui/help_system.sh"
source_component "ui/version_info.sh"
source_component "ui/template_display.sh"
source_component "ui/argument_parser.sh"
source_component "ui/progress_display.sh"
source_component "ui/prompt_system.sh"

# Plugin components (depend on core)
source_component "plugin/plugin_parser.sh"
source_component "plugin/plugin_discovery.sh"
source_component "plugin/plugin_validator.sh"
source_component "plugin/plugin_tool_checker.sh"
source_component "plugin/plugin_display.sh"

# Orchestration components (depend on core and plugin)
source_component "orchestration/workspace.sh"
source_component "orchestration/workspace_security.sh"
source_component "orchestration/scanner.sh"
source_component "orchestration/template_engine.sh"
source_component "orchestration/report_generator.sh"
source_component "plugin/plugin_executor.sh"
source_component "orchestration/main_orchestrator.sh"

# ==============================================================================
# Main Workflow
# ==============================================================================

# Run directory analysis workflow
# Delegates to main orchestrator while preserving UI compatibility
# Returns:
#   0 on success, 1 on failure
run_analysis() {
  # Determine plugins directory based on platform
  local plugins_dir="${SCRIPT_DIR}/plugins/${PLATFORM}"
  if [[ ! -d "$plugins_dir" ]]; then
    plugins_dir="${SCRIPT_DIR}/plugins/ubuntu"
  fi
  
  # Delegate to main orchestrator
  orchestrate_directory_analysis \
    "$SOURCE_DIR" \
    "$WORKSPACE_DIR" \
    "$TARGET_DIR" \
    "$TEMPLATE_FILE" \
    "$plugins_dir" \
    "$FORCE_FULLSCAN"
  
  return $?
}

# Main entry point
main() {
  # Detect interactive mode early (before any prompts or user-facing output)
  detect_interactive_mode
  
  # Initialize platform detection
  detect_platform
  
  # Parse command-line arguments
  parse_arguments "$@"
  
  # Validate and apply defaults to arguments
  validate_arguments
  
  # Run analysis if source directory is provided
  if [[ -n "$SOURCE_DIR" ]]; then
    run_analysis
    exit $?
  fi

  # If we get here, no action was taken (all flags processed but no work done)
  log "INFO" "MAIN" "Script initialization complete"
  
  exit "${EXIT_SUCCESS}"
}

# ==============================================================================
# Script Execution
# ==============================================================================

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
