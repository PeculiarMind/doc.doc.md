#!/usr/bin/env bash
# Component: main_orchestrator.sh
# Purpose: Main workflow orchestration for directory analysis (-d command)
# Dependencies: workspace.sh, scanner.sh, plugin_executor.sh, report_generator.sh, template_engine.sh, workspace_security.sh
# Exports: orchestrate_directory_analysis(), validate_analysis_parameters(), initialize_analysis(), execute_analysis_workflow(), handle_analysis_errors()
# Side Effects: Creates workspace/target directories, executes plugins, generates reports

# ==============================================================================
# Parameter Validation
# ==============================================================================

# Validate all required parameters for directory analysis
# Arguments:
#   $1 - Source directory path
#   $2 - Workspace directory path
#   $3 - Target directory path
#   $4 - Template file path
# Returns:
#   0 on success, 1 on validation failure
validate_analysis_parameters() {
  local source_dir="$1"
  local workspace_dir="$2"
  local target_dir="$3"
  local template_file="$4"
  
  # Check required parameters
  if [[ -z "$source_dir" ]]; then
    log "ERROR" "ORCHESTRATOR" "Source directory is required (-d)"
    return 1
  fi
  
  if [[ -z "$workspace_dir" ]]; then
    log "ERROR" "ORCHESTRATOR" "Workspace directory is required (-w)"
    return 1
  fi
  
  if [[ -z "$target_dir" ]]; then
    log "ERROR" "ORCHESTRATOR" "Target directory is required (-t)"
    return 1
  fi
  
  if [[ -z "$template_file" ]]; then
    log "ERROR" "ORCHESTRATOR" "Template file is required (-m)"
    return 1
  fi
  
  # Validate source directory exists and is readable
  if [[ ! -d "$source_dir" ]]; then
    log "ERROR" "ORCHESTRATOR" "Source directory does not exist: $source_dir"
    return 1
  fi
  
  if [[ ! -r "$source_dir" ]]; then
    log "ERROR" "ORCHESTRATOR" "Source directory is not readable: $source_dir"
    return 1
  fi
  
  # Validate template file exists and is readable
  if [[ ! -f "$template_file" ]]; then
    log "ERROR" "ORCHESTRATOR" "Template file does not exist: $template_file"
    return 1
  fi
  
  if [[ ! -r "$template_file" ]]; then
    log "ERROR" "ORCHESTRATOR" "Template file is not readable: $template_file"
    return 1
  fi
  
  log "DEBUG" "ORCHESTRATOR" "Parameter validation successful"
  return 0
}

# ==============================================================================
# Initialization
# ==============================================================================

# Initialize workspace and target directories
# Arguments:
#   $1 - Workspace directory path
#   $2 - Target directory path
# Returns:
#   0 on success, 1 on initialization failure
initialize_analysis() {
  local workspace_dir="$1"
  local target_dir="$2"
  
  log "INFO" "ORCHESTRATOR" "Initializing analysis environment"
  
  # Initialize workspace
  if ! init_workspace "$workspace_dir"; then
    log "ERROR" "ORCHESTRATOR" "Failed to initialize workspace: $workspace_dir"
    return 1
  fi
  
  log "DEBUG" "ORCHESTRATOR" "Workspace initialized: $workspace_dir"
  
  # Create target directory if it doesn't exist
  if [[ ! -d "$target_dir" ]]; then
    if ! mkdir -p "$target_dir"; then
      log "ERROR" "ORCHESTRATOR" "Failed to create target directory: $target_dir"
      return 1
    fi
    log "DEBUG" "ORCHESTRATOR" "Target directory created: $target_dir"
  fi
  
  # Initialize target directory (may set permissions, etc.)
  if ! init_target_directory "$target_dir" 2>/dev/null; then
    log "WARN" "ORCHESTRATOR" "Target directory initialization incomplete: $target_dir"
  fi
  
  log "INFO" "ORCHESTRATOR" "Analysis environment initialized"
  return 0
}

# ==============================================================================
# Workflow Execution
# ==============================================================================

# Execute complete analysis workflow: scan → plugins → reports
# Arguments:
#   $1 - Source directory path
#   $2 - Workspace directory path
#   $3 - Target directory path
#   $4 - Template file path
#   $5 - Plugins directory path
#   $6 - Force full scan flag (true/false)
# Returns:
#   0 on success, 1 on workflow failure
execute_analysis_workflow() {
  local source_dir="$1"
  local workspace_dir="$2"
  local target_dir="$3"
  local template_file="$4"
  local plugins_dir="$5"
  local force_fullscan="${6:-false}"
  
  log "INFO" "ORCHESTRATOR" "Starting directory analysis workflow"
  
  # Stage 1: Directory Scanning
  log "INFO" "ORCHESTRATOR" "Stage 1: Scanning directory"
  local scan_output
  scan_output=$(scan_directory "$source_dir" "$workspace_dir" "$force_fullscan" 2>&1)
  if [[ $? -ne 0 ]]; then
    return $(handle_analysis_errors "Directory scan failed: $scan_output" "SCAN")
  fi
  
  log "DEBUG" "ORCHESTRATOR" "Directory scan completed"
  
  # Stage 2: Plugin Execution
  log "INFO" "ORCHESTRATOR" "Stage 2: Processing files with plugins"
  
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
  
  log "INFO" "ORCHESTRATOR" "Processing $total_files files"
  
  # Process each discovered file
  for entry in "${file_entries[@]}"; do
    local file_path
    file_path=$(echo "$entry" | cut -d'|' -f1)
    
    if [[ -z "$file_path" ]] || [[ ! -f "$file_path" ]]; then
      skipped_count=$((skipped_count + 1))
      continue
    fi
    
    processed_count=$((processed_count + 1))
    
    # Execute plugins for this file
    if ! orchestrate_plugins "$file_path" "$workspace_dir" "$plugins_dir" 2>/dev/null; then
      log "WARN" "ORCHESTRATOR" "Plugin execution failed for: $file_path"
      error_count=$((error_count + 1))
      # Continue processing other files (partial success)
    fi
  done
  
  log "INFO" "ORCHESTRATOR" "File processing complete: $processed_count processed, $skipped_count skipped, $error_count errors"
  
  # Log backwards-compatible summary for tests
  log "INFO" "MAIN" "Analysis complete: $processed_count files processed, $skipped_count skipped, $error_count errors"
  
  # Update full scan timestamp
  if type -t update_full_scan_timestamp &>/dev/null; then
    update_full_scan_timestamp "$workspace_dir" 2>/dev/null || true
  fi
  
  # Stage 3: Report Generation
  log "INFO" "ORCHESTRATOR" "Stage 3: Generating reports"
  
  if ! generate_reports "$workspace_dir" "$target_dir" "$template_file" 2>&1; then
    return $(handle_analysis_errors "Report generation failed" "REPORT")
  fi
  
  log "INFO" "ORCHESTRATOR" "Reports generated successfully"
  
  # Workflow complete
  log "INFO" "ORCHESTRATOR" "Directory analysis workflow completed successfully"
  return 0
}

# ==============================================================================
# Error Handling
# ==============================================================================

# Handle analysis errors with logging and context
# Arguments:
#   $1 - Error message
#   $2 - Stage identifier
# Returns:
#   1 (error code)
handle_analysis_errors() {
  local error_message="$1"
  local stage="${2:-UNKNOWN}"
  
  log "ERROR" "ORCHESTRATOR" "Analysis failed at stage $stage: $error_message"
  
  # Provide actionable guidance based on stage
  case "$stage" in
    VALIDATION)
      log "ERROR" "ORCHESTRATOR" "Please check that all required parameters are provided and valid"
      ;;
    INITIALIZATION)
      log "ERROR" "ORCHESTRATOR" "Please check workspace and target directory permissions"
      ;;
    SCAN)
      log "ERROR" "ORCHESTRATOR" "Please verify source directory is accessible and contains files"
      ;;
    PLUGIN)
      log "ERROR" "ORCHESTRATOR" "Please check plugin configurations and dependencies"
      ;;
    REPORT)
      log "ERROR" "ORCHESTRATOR" "Please verify template file format and workspace data"
      ;;
  esac
  
  return 1
}

# ==============================================================================
# Main Entry Point
# ==============================================================================

# Main orchestration function for directory analysis
# This is the primary entry point for the -d <directory> command
# Arguments:
#   $1 - Source directory path
#   $2 - Workspace directory path
#   $3 - Target directory path
#   $4 - Template file path
#   $5 - Plugins directory path
#   $6 - Force full scan flag (true/false)
# Returns:
#   0 on success, 1 on failure
orchestrate_directory_analysis() {
  local source_dir="$1"
  local workspace_dir="$2"
  local target_dir="$3"
  local template_file="$4"
  local plugins_dir="$5"
  local force_fullscan="${6:-false}"
  
  log "INFO" "ORCHESTRATOR" "Starting directory analysis orchestration"
  
  # Step 1: Validate Parameters
  if ! validate_analysis_parameters "$source_dir" "$workspace_dir" "$target_dir" "$template_file"; then
    return $(handle_analysis_errors "Parameter validation failed" "VALIDATION")
  fi
  
  # Step 2: Initialize Analysis Environment
  if ! initialize_analysis "$workspace_dir" "$target_dir"; then
    return $(handle_analysis_errors "Initialization failed" "INITIALIZATION")
  fi
  
  # Step 3: Execute Analysis Workflow
  if ! execute_analysis_workflow "$source_dir" "$workspace_dir" "$target_dir" "$template_file" "$plugins_dir" "$force_fullscan"; then
    # Error already logged by execute_analysis_workflow
    return 1
  fi
  
  # Success
  log "INFO" "ORCHESTRATOR" "Directory analysis completed successfully"
  log "INFO" "ORCHESTRATOR" "Results available in: $target_dir"
  
  return 0
}
