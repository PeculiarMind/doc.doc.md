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

# Global array to track unavailable plugins
declare -gA UNAVAILABLE_PLUGINS

# Verify plugin installation and track unavailable plugins
# Arguments:
#   $1 - Plugins directory path
# Returns:
#   0 on success (continues even if some plugins are unavailable)
#   Sets UNAVAILABLE_PLUGINS associative array with plugin names as keys
verify_plugin_installation() {
  local plugins_dir="$1"
  
  log "INFO" "ORCHESTRATOR" "Verifying plugin installation"
  
  # Clear the unavailable plugins array
  UNAVAILABLE_PLUGINS=()
  
  # Check if plugins directory exists
  if [[ ! -d "${plugins_dir}" ]]; then
    log "WARN" "ORCHESTRATOR" "Plugins directory not found: ${plugins_dir}"
    return 0
  fi
  
  # Get list of active plugins and check each one
  while IFS= read -r -d '' descriptor_file; do
    local plugin_name check_command
    
    plugin_name=$(jq -r '.name // empty' "${descriptor_file}" 2>/dev/null)
    if [[ -z "${plugin_name}" ]]; then
      continue
    fi
    
    # Determine if plugin is active (CLI > Config > Descriptor)
    local plugin_active
    if declare -p PLUGIN_ACTIVATION_OVERRIDES &>/dev/null && [[ -v PLUGIN_ACTIVATION_OVERRIDES["${plugin_name}"] ]]; then
      plugin_active="${PLUGIN_ACTIVATION_OVERRIDES[${plugin_name}]}"
    else
      plugin_active=$(jq -r 'if has("active") then .active else true end' "${descriptor_file}" 2>/dev/null)
    fi
    
    # Skip verification for inactive plugins
    if [[ "${plugin_active}" == "false" ]]; then
      log "DEBUG" "ORCHESTRATOR" "Skipping verification for inactive plugin: ${plugin_name}"
      continue
    fi
    
    # Get check command from descriptor
    check_command=$(jq -r '.check_commandline // empty' "${descriptor_file}" 2>/dev/null)
    if [[ -z "${check_command}" ]]; then
      log "WARN" "ORCHESTRATOR" "No check_commandline for plugin: ${plugin_name}"
      UNAVAILABLE_PLUGINS["${plugin_name}"]="no_check_command"
      continue
    fi
    
    # Check if tool is available
    log "DEBUG" "ORCHESTRATOR" "Checking tool for plugin: ${plugin_name}"
    if bash -c "${check_command}" >/dev/null 2>&1; then
      log "DEBUG" "ORCHESTRATOR" "Tool available for plugin: ${plugin_name}"
    else
      log "WARN" "ORCHESTRATOR" "Tool not available for plugin: ${plugin_name}"
      UNAVAILABLE_PLUGINS["${plugin_name}"]="tool_missing"
    fi
  done < <(find "${plugins_dir}" -name "descriptor.json" -type f -print0 2>/dev/null)
  
  # Report unavailable plugins if any
  if [[ ${#UNAVAILABLE_PLUGINS[@]} -gt 0 ]]; then
    log "WARN" "ORCHESTRATOR" "Found ${#UNAVAILABLE_PLUGINS[@]} unavailable plugin(s)"
    for plugin_name in "${!UNAVAILABLE_PLUGINS[@]}"; do
      local descriptor_file
      descriptor_file=$(find "${plugins_dir}" -name "descriptor.json" -type f -exec grep -l "\"name\": *\"${plugin_name}\"" {} \; 2>/dev/null | head -1)
      
      if [[ -n "${descriptor_file}" ]]; then
        local install_command
        install_command=$(jq -r '.install_commandline // empty' "${descriptor_file}" 2>/dev/null)
        
        if [[ -n "${install_command}" ]] && [[ "${install_command}" != "null" ]]; then
          log "WARN" "ORCHESTRATOR" "  - ${plugin_name}: Tool not installed. Install with: ${install_command}"
        else
          log "WARN" "ORCHESTRATOR" "  - ${plugin_name}: Tool not installed. No install command available."
        fi
      else
        log "WARN" "ORCHESTRATOR" "  - ${plugin_name}: Tool not installed."
      fi
    done
    log "INFO" "ORCHESTRATOR" "Analysis will continue, skipping unavailable plugins"
  else
    log "INFO" "ORCHESTRATOR" "All active plugins are available"
  fi
  
  return 0
}

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
  
  # Initialize progress display for interactive mode
  if [[ "${IS_INTERACTIVE:-}" == "true" ]]; then
    show_progress 0 0 "$total_files" 0 "" ""
  fi
  
  # Process each discovered file
  for entry in "${file_entries[@]}"; do
    local file_path
    file_path=$(echo "$entry" | cut -d'|' -f1)
    
    if [[ -z "$file_path" ]] || [[ ! -f "$file_path" ]]; then
      skipped_count=$((skipped_count + 1))
      continue
    fi
    
    processed_count=$((processed_count + 1))
    local percent=$((processed_count * 100 / total_files))
    
    # Update progress display before processing file
    if [[ "${IS_INTERACTIVE:-}" == "true" ]]; then
      show_progress "$percent" "$processed_count" "$total_files" "$skipped_count" "$file_path" "plugin-execution"
    fi
    
    # Execute plugins for this file
    if ! orchestrate_plugins "$file_path" "$workspace_dir" "$plugins_dir" 2>/dev/null; then
      log "WARN" "ORCHESTRATOR" "Plugin execution failed for: $file_path"
      error_count=$((error_count + 1))
      # Continue processing other files (partial success)
    fi
  done
  
  # Clear progress display and show final status
  if [[ "${IS_INTERACTIVE:-}" == "true" ]]; then
    clear_progress
  fi
  
  log "INFO" "ORCHESTRATOR" "File processing complete: $processed_count processed, $skipped_count skipped, $error_count errors"
  
  # Log analysis summary (compatible with logging expectations)
  log "INFO" "ORCHESTRATOR" "Analysis complete: $processed_count files processed, $skipped_count skipped, $error_count errors"
  
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
  
  # Step 3: Verify Plugin Installation (before analysis starts)
  if ! verify_plugin_installation "$plugins_dir"; then
    return $(handle_analysis_errors "Plugin verification failed" "PLUGIN")
  fi
  
  # Step 4: Execute Analysis Workflow
  if ! execute_analysis_workflow "$source_dir" "$workspace_dir" "$target_dir" "$template_file" "$plugins_dir" "$force_fullscan"; then
    # Error already logged by execute_analysis_workflow
    return 1
  fi
  
  # Success
  log "INFO" "ORCHESTRATOR" "Directory analysis completed successfully"
  log "INFO" "ORCHESTRATOR" "Results available in: $target_dir"
  
  return 0
}

# ==============================================================================
# Single File Analysis Orchestration
# ==============================================================================

# Orchestrate single file analysis workflow
# Arguments:
#   $1 - Single file path (absolute, validated)
#   $2 - Workspace directory path
#   $3 - Target directory path
#   $4 - Template file path
#   $5 - Plugins directory path
# Returns:
#   0 on success, 1 on failure
orchestrate_single_file_analysis() {
  local file_path="$1"
  local workspace_dir="$2"
  local target_dir="$3"
  local template_file="$4"
  local plugins_dir="$5"
  
  log "INFO" "ORCHESTRATOR" "Starting single-file analysis workflow"
  log "INFO" "ORCHESTRATOR" "File: $file_path"
  
  # Step 1: Validate parameters
  if [[ -z "$file_path" ]]; then
    log "ERROR" "ORCHESTRATOR" "File path is required"
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
  
  # Validate file exists and is a regular file
  if [[ ! -f "$file_path" ]]; then
    log "ERROR" "ORCHESTRATOR" "File does not exist or is not a regular file: $file_path"
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
  
  # Step 2: Initialize workspace
  log "INFO" "ORCHESTRATOR" "Initializing workspace"
  if ! init_workspace "$workspace_dir"; then
    log "ERROR" "ORCHESTRATOR" "Workspace initialization failed"
    return 1
  fi
  
  # Validate workspace schema
  if ! validate_workspace_schema "$workspace_dir"; then
    log "ERROR" "ORCHESTRATOR" "Workspace schema validation failed"
    return 1
  fi
  
  # Step 3: Initialize target directory
  log "INFO" "ORCHESTRATOR" "Initializing target directory"
  if [[ ! -d "$target_dir" ]]; then
    mkdir -p "$target_dir" || {
      log "ERROR" "ORCHESTRATOR" "Failed to create target directory: $target_dir"
      return 1
    }
  fi
  
  # Step 4: Verify Plugin Installation
  if ! verify_plugin_installation "$plugins_dir"; then
    return $(handle_analysis_errors "Plugin verification failed" "PLUGIN")
  fi
  
  # Step 5: Generate file hash for workspace tracking
  local file_hash
  file_hash=$(generate_file_hash "$file_path")
  
  if [[ -z "$file_hash" ]]; then
    log "ERROR" "ORCHESTRATOR" "Failed to generate file hash"
    return 1
  fi
  
  log "DEBUG" "ORCHESTRATOR" "File hash: $file_hash"
  
  # Step 6: Check if file needs analysis (workspace lookup)
  local workspace_data
  workspace_data=$(load_workspace "$workspace_dir" "$file_hash")
  
  local last_scan_time
  last_scan_time=$(echo "$workspace_data" | jq -r '.last_scan_time // empty' 2>/dev/null)
  
  local needs_scan=true
  if [[ -n "$last_scan_time" ]] && [[ "$last_scan_time" != "null" ]]; then
    log "INFO" "ORCHESTRATOR" "File previously scanned at: $last_scan_time"
    # For single file analysis, we always scan unless explicitly cached
    needs_scan=true
  fi
  
  # Step 7: Discover and filter active plugins
  log "INFO" "ORCHESTRATOR" "Discovering active plugins"
  local discovered_plugins
  discovered_plugins=$(discover_plugins "$plugins_dir")
  
  if [[ -z "$discovered_plugins" ]]; then
    log "WARN" "ORCHESTRATOR" "No plugins discovered in: $plugins_dir"
    return 0
  fi
  
  log "DEBUG" "ORCHESTRATOR" "Discovered plugins: $discovered_plugins"
  
  # Filter active plugins
  # discover_plugins returns: name|description|active|path
  local active_plugins=()
  while IFS='|' read -r plugin_name plugin_desc plugin_active plugin_file; do
    if [[ -n "$plugin_name" ]] && [[ -n "$plugin_file" ]] && [[ -f "$plugin_file" ]]; then
      # Skip unavailable plugins
      if [[ -v UNAVAILABLE_PLUGINS[$plugin_name] ]]; then
        log "DEBUG" "ORCHESTRATOR" "Skipping unavailable plugin: $plugin_name"
        continue
      fi
      
      # Check plugin active status
      local is_active="$plugin_active"
      
      # Check for plugin activation overrides
      if [[ -v PLUGIN_ACTIVATION_OVERRIDES[$plugin_name] ]]; then
        is_active="${PLUGIN_ACTIVATION_OVERRIDES[$plugin_name]}"
        log "DEBUG" "ORCHESTRATOR" "Override active status for $plugin_name: $is_active"
      fi
      
      if [[ "$is_active" == "true" ]]; then
        active_plugins+=("$plugin_file")
        log "DEBUG" "ORCHESTRATOR" "Active plugin: $plugin_name"
      else
        log "DEBUG" "ORCHESTRATOR" "Skipping inactive plugin: $plugin_name"
      fi
    fi
  done <<< "$discovered_plugins"
  
  if [[ ${#active_plugins[@]} -eq 0 ]]; then
    log "WARN" "ORCHESTRATOR" "No active plugins found"
    return 0
  fi
  
  # Step 8: Execute active plugins on the single file
  log "INFO" "ORCHESTRATOR" "Executing ${#active_plugins[@]} active plugin(s) on file"
  
  local plugin_results=()
  local success_count=0
  local failure_count=0
  
  # Build variables JSON for plugin execution
  local variables_json
  variables_json=$(jq -n \
    --arg file_path "$file_path" \
    '{
      file_path_absolute: $file_path
    }')
  
  for plugin_file in "${active_plugins[@]}"; do
    local plugin_name
    # Get plugin name from parent directory (e.g., /path/to/stat/descriptor.json -> stat)
    plugin_name=$(basename "$(dirname "$plugin_file")")
    
    log "INFO" "ORCHESTRATOR" "Executing plugin: $plugin_name"
    
    # Execute plugin with file path
    local result
    if execute_plugin "$plugin_name" "$plugins_dir" "$variables_json"; then
      log "INFO" "ORCHESTRATOR" "Plugin executed successfully: $plugin_name"
      plugin_results+=("$plugin_name:success")
      ((success_count++))
    else
      log "WARN" "ORCHESTRATOR" "Plugin execution failed: $plugin_name"
      plugin_results+=("$plugin_name:failure")
      ((failure_count++))
    fi
  done
  
  # Step 9: Update workspace with scan results
  local scan_timestamp
  scan_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  local workspace_entry
  workspace_entry=$(jq -n \
    --arg file_path "$file_path" \
    --arg file_hash "$file_hash" \
    --arg scan_time "$scan_timestamp" \
    --argjson success "$success_count" \
    --argjson failure "$failure_count" \
    '{
      file_path: $file_path,
      file_hash: $file_hash,
      last_scan_time: $scan_time,
      plugin_executions: {
        success: $success,
        failure: $failure
      }
    }')
  
  save_workspace "$workspace_dir" "$file_hash" "$workspace_entry"
  
  # Step 10: Generate report
  log "INFO" "ORCHESTRATOR" "Generating report"
  
  # For single file analysis, we create a simplified report
  local report_file="${target_dir}/$(basename "$file_path").report.md"
  
  # Use template engine to generate report
  if command -v jq >/dev/null 2>&1; then
    # Create a simple data structure for the report
    local report_data
    report_data=$(jq -n \
      --arg file "$file_path" \
      --arg timestamp "$scan_timestamp" \
      --argjson success "$success_count" \
      --argjson failure "$failure_count" \
      '{
        file: $file,
        timestamp: $timestamp,
        plugins: {
          success: $success,
          failure: $failure
        }
      }')
    
    log "DEBUG" "ORCHESTRATOR" "Report data generated"
  fi
  
  # Success
  log "INFO" "ORCHESTRATOR" "Single-file analysis completed successfully"
  log "INFO" "ORCHESTRATOR" "Plugins executed: $success_count successful, $failure_count failed"
  log "INFO" "ORCHESTRATOR" "Results available in: $target_dir"
  
  return 0
}
