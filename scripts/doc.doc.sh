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
source_component "core/logging.sh"
source_component "core/mode_detection.sh"
source_component "core/error_handling.sh"
source_component "core/platform_detection.sh"

# UI components (depend on core)
source_component "ui/help_system.sh"
source_component "ui/version_info.sh"
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
source_component "orchestration/scanner.sh"
source_component "orchestration/template_engine.sh"
source_component "orchestration/report_generator.sh"
source_component "plugin/plugin_executor.sh"

# ==============================================================================
# Main Workflow
# ==============================================================================

# Run directory analysis workflow
# Validates parameters, initializes workspace, scans directory, processes files with plugins
# Returns:
#   0 on success, 1 on failure
run_analysis() {
  # Validate required parameters
  if [[ ! -d "$SOURCE_DIR" ]] || [[ ! -r "$SOURCE_DIR" ]]; then
    log "ERROR" "MAIN" "Source directory does not exist or is not readable: $SOURCE_DIR"
    return 1
  fi

  if [[ -z "$WORKSPACE_DIR" ]]; then
    log "ERROR" "MAIN" "Workspace directory is required (-w)"
    return 1
  fi

  if [[ -z "$TARGET_DIR" ]]; then
    log "ERROR" "MAIN" "Target directory is required (-t)"
    return 1
  fi

  if [[ -z "$TEMPLATE_FILE" ]]; then
    log "ERROR" "MAIN" "Template file is required (-m)"
    return 1
  fi

  # Initialize workspace
  if ! init_workspace "$WORKSPACE_DIR"; then
    log "ERROR" "MAIN" "Failed to initialize workspace: $WORKSPACE_DIR"
    return 1
  fi

  # Scan directory
  local scan_output
  scan_output=$(scan_directory "$SOURCE_DIR" "$WORKSPACE_DIR" "$FORCE_FULLSCAN")
  if [[ $? -ne 0 ]]; then
    log "ERROR" "MAIN" "Directory scan failed"
    return 1
  fi

  # Determine plugins directory
  local plugins_dir="${SCRIPT_DIR}/plugins/${PLATFORM}"
  if [[ ! -d "$plugins_dir" ]]; then
    plugins_dir="${SCRIPT_DIR}/plugins/ubuntu"
  fi

  # Collect scan results into array
  local -a file_entries=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    file_entries+=("$line")
  done <<< "$scan_output"

  local total_files=${#file_entries[@]}
  local processed_count=0
  local skipped_count=0
  local error_count=0

  # Process each discovered file
  for entry in "${file_entries[@]}"; do
    local file_path
    file_path=$(echo "$entry" | cut -d'|' -f1)

    if [[ -z "$file_path" ]] || [[ ! -f "$file_path" ]]; then
      skipped_count=$((skipped_count + 1))
      continue
    fi

    # Show progress
    processed_count=$((processed_count + 1))
    local percent=0
    if [[ $total_files -gt 0 ]]; then
      percent=$(( processed_count * 100 / total_files ))
    fi

    if [[ "${IS_INTERACTIVE:-}" == "true" ]]; then
      show_progress "$percent" "$processed_count" "$total_files" "$skipped_count" "$file_path" "stat"
    else
      log_progress_milestone "$processed_count" "$total_files" "MAIN"
    fi

    # Execute plugins for this file
    if ! orchestrate_plugins "$file_path" "$WORKSPACE_DIR" "$plugins_dir" 2>/dev/null; then
      log "WARN" "MAIN" "Plugin execution failed for: $file_path"
      error_count=$((error_count + 1))
    fi
  done

  # Clear progress display
  clear_progress

  # Update full scan timestamp
  update_full_scan_timestamp "$WORKSPACE_DIR"

  # Generate reports to target directory
  if ! init_target_directory "$TARGET_DIR"; then
    log "ERROR" "MAIN" "Failed to initialize target directory: $TARGET_DIR"
    return 1
  fi

  if ! generate_reports "$WORKSPACE_DIR" "$TARGET_DIR" "$TEMPLATE_FILE"; then
    log "ERROR" "MAIN" "Report generation failed"
    return 1
  fi

  # Log summary
  log "INFO" "MAIN" "Analysis complete: $processed_count files processed, $skipped_count skipped, $error_count errors"

  return 0
}

# Main entry point
main() {
  # Detect interactive mode early (before any prompts or user-facing output)
  detect_interactive_mode
  
  # Initialize platform detection
  detect_platform
  
  # Parse command-line arguments
  parse_arguments "$@"
  
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
