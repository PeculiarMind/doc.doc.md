#!/usr/bin/env bash
# Component: report_generator.sh
# Purpose: Report generation to target directory from workspace data
# Dependencies: orchestration/workspace.sh, orchestration/template_engine.sh
# Exports: generate_reports(), generate_aggregated_report(), init_target_directory()
# Side Effects: Writes report files to target directory

# ==============================================================================
# Target Directory Initialization
# ==============================================================================

# Initialize target directory for report output
# Creates the directory if it doesn't exist, validates writability
# Arguments:
#   $1 - Target directory path
# Returns:
#   0 on success, 1 on failure
init_target_directory() {
  local target_dir="$1"

  if [[ -z "$target_dir" ]]; then
    log "ERROR" "REPORT" "Target directory argument is required"
    return 1
  fi

  # Security: Prevent path traversal (CWE-22)
  case "$target_dir" in
    *..*)
      log "ERROR" "REPORT" "Path traversal detected in target directory"
      return 1
      ;;
  esac

  if [[ -d "$target_dir" ]]; then
    if [[ -w "$target_dir" ]]; then
      log "INFO" "REPORT" "Target directory exists and is writable: $target_dir"
      return 0
    else
      log "ERROR" "REPORT" "Target directory is not writable: $target_dir"
      return 1
    fi
  fi

  log "INFO" "REPORT" "Creating target directory: $target_dir"
  if ! mkdir -p "$target_dir" 2>/dev/null; then
    log "ERROR" "REPORT" "Failed to create target directory: $target_dir"
    return 1
  fi

  if [[ ! -w "$target_dir" ]]; then
    log "ERROR" "REPORT" "Target directory is not writable: $target_dir"
    return 1
  fi

  log "INFO" "REPORT" "Target directory initialized: $target_dir"
  return 0
}

# ==============================================================================
# Report Generation Functions
# ==============================================================================

# Generate reports from workspace data into target directory
# Reads all JSON files from workspace/files/, applies template, writes to target
# Arguments:
#   $1 - Workspace directory
#   $2 - Target directory (output)
#   $3 - Template file path
# Returns:
#   0 on success, 1 on failure
generate_reports() {
  local workspace_dir="$1"
  local target_dir="$2"
  local template_file="$3"

  if [[ -z "$workspace_dir" ]]; then
    log "ERROR" "REPORT" "Workspace directory is required"
    return 1
  fi

  if [[ -z "$target_dir" ]]; then
    log "ERROR" "REPORT" "Target directory is required"
    return 1
  fi

  if [[ -n "$template_file" ]] && [[ ! -f "$template_file" ]]; then
    log "ERROR" "REPORT" "Template file does not exist: $template_file"
    return 1
  fi

  # Initialize target directory
  if ! init_target_directory "$target_dir"; then
    log "ERROR" "REPORT" "Failed to initialize target directory: $target_dir"
    return 1
  fi

  # Read template content
  local template_content=""
  if [[ -n "$template_file" ]] && [[ -f "$template_file" ]]; then
    template_content=$(cat "$template_file" 2>/dev/null)
  fi

  # Find all workspace JSON files
  local workspace_files_dir="$workspace_dir/files"
  if [[ ! -d "$workspace_files_dir" ]]; then
    log "INFO" "REPORT" "No workspace files directory, nothing to report"
    return 0
  fi

  local report_count=0
  for json_file in "$workspace_files_dir"/*.json; do
    # Skip if no JSON files exist (glob didn't match)
    [[ -f "$json_file" ]] || continue

    # Load workspace data
    local json_data
    json_data=$(cat "$json_file" 2>/dev/null)
    if [[ -z "$json_data" ]] || ! echo "$json_data" | jq empty 2>/dev/null; then
      log "WARN" "REPORT" "Skipping invalid workspace file: $json_file"
      continue
    fi

    # Extract file path for naming the report
    local file_path
    file_path=$(echo "$json_data" | jq -r '.file_path // empty' 2>/dev/null)

    # Generate a report filename from the hash
    local file_hash
    file_hash=$(basename "$json_file" .json)
    local report_filename="${file_hash}.md"

    # Generate report content from template and data
    local report_content
    report_content=$(render_report "$template_content" "$json_data" 2>/dev/null)

    # Write report file
    local report_path="$target_dir/$report_filename"
    if echo "$report_content" > "$report_path" 2>/dev/null; then
      report_count=$((report_count + 1))
      log "DEBUG" "REPORT" "Generated report: $report_path"
    else
      log "WARN" "REPORT" "Failed to write report: $report_path"
    fi
  done

  log "INFO" "REPORT" "Report generation complete: $report_count report(s) written to $target_dir"
  return 0
}

# Render a single report by substituting workspace data into template
# Arguments:
#   $1 - Template content
#   $2 - JSON data from workspace
# Returns:
#   Rendered report content on stdout
render_report() {
  local template="$1"
  local json_data="$2"

  if [[ -z "$template" ]]; then
    # No template, output JSON data as a simple report
    echo "$json_data" | jq '.' 2>/dev/null
    return 0
  fi

  local result="$template"

  # Substitute known variables from JSON data
  local file_path file_size file_type
  file_path=$(echo "$json_data" | jq -r '.file_path // ""' 2>/dev/null)
  file_size=$(echo "$json_data" | jq -r '.stat.file_size // .file_size // ""' 2>/dev/null)
  file_type=$(echo "$json_data" | jq -r '.file_type // ""' 2>/dev/null)

  local filename=""
  if [[ -n "$file_path" ]]; then
    filename=$(basename "$file_path")
  fi

  # Perform substitutions
  result="${result//\$\{filename\}/$filename}"
  result="${result//\$\{filepath_absolute\}/$file_path}"
  result="${result//\$\{file_owner\}/${file_owner:-}}"
  result="${result//\$\{doc_doc_version\}/${SCRIPT_VERSION:-1.0.0}}"

  echo "$result"
  return 0
}

# Generate aggregated report summarizing all workspace data
# Arguments:
#   $1 - Workspace directory
#   $2 - Output file path
# Returns:
#   0 on success, 1 on failure
generate_aggregated_report() {
  local workspace_dir="$1"
  local output_file="$2"

  if [[ -z "$workspace_dir" ]] || [[ -z "$output_file" ]]; then
    log "ERROR" "REPORT" "Workspace directory and output file are required"
    return 1
  fi

  # Ensure output directory exists
  local output_dir
  output_dir=$(dirname "$output_file")
  if ! init_target_directory "$output_dir"; then
    log "ERROR" "REPORT" "Failed to initialize output directory for aggregated report"
    return 1
  fi

  local workspace_files_dir="$workspace_dir/files"
  local total_files=0
  local file_list=""

  if [[ -d "$workspace_files_dir" ]]; then
    for json_file in "$workspace_files_dir"/*.json; do
      [[ -f "$json_file" ]] || continue
      total_files=$((total_files + 1))

      local fp
      fp=$(jq -r '.file_path // "unknown"' "$json_file" 2>/dev/null)
      file_list="${file_list}\n- ${fp}"
    done
  fi

  # Write aggregated report
  {
    echo "# Aggregated Analysis Report"
    echo ""
    echo "**Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "**Total files analyzed**: $total_files"
    echo ""
    echo "## Files"
    echo -e "$file_list"
    echo ""
  } > "$output_file" 2>/dev/null

  if [[ $? -eq 0 ]]; then
    log "INFO" "REPORT" "Aggregated report generated: $output_file ($total_files files)"
    return 0
  else
    log "ERROR" "REPORT" "Failed to write aggregated report: $output_file"
    return 1
  fi
}
