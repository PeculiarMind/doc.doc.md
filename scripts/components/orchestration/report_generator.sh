#!/usr/bin/env bash
# Component: report_generator.sh
# Purpose: Report generation to target directory from workspace data
# Dependencies: orchestration/workspace.sh, orchestration/template_engine.sh
# Exports: generate_reports(), generate_aggregated_report(), init_target_directory(),
#          load_template(), merge_workspace_data(), write_report(),
#          human_readable_size(), format_date_iso8601()
# Side Effects: Writes report files to target directory

# ==============================================================================
# Template Cache
# ==============================================================================

declare -g TEMPLATE_CACHE=""
declare -g TEMPLATE_CACHE_PATH=""

# ==============================================================================
# Helper Functions
# ==============================================================================

# Convert bytes to human-readable format
# Arguments:
#   $1 - Size in bytes
# Returns:
#   Human-readable size string (e.g., "1.5KB", "2MB")
human_readable_size() {
  local bytes="$1"
  
  if [[ -z "$bytes" ]] || [[ ! "$bytes" =~ ^[0-9]+$ ]]; then
    echo "0B"
    return 0
  fi
  
  local -a units=("B" "KB" "MB" "GB" "TB")
  local unit_index=0
  local size="$bytes"
  
  while (( size >= 1024 && unit_index < 4 )); do
    size=$((size / 1024))
    unit_index=$((unit_index + 1))
  done
  
  echo "${size}${units[$unit_index]}"
}

# Format date in ISO8601 format
# Arguments:
#   $1 - Optional: Unix timestamp (uses current time if not provided)
# Returns:
#   ISO8601 formatted date string
format_date_iso8601() {
  local timestamp="${1:-}"
  
  if [[ -n "$timestamp" ]]; then
    date -u -d "@$timestamp" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ"
  else
    date -u +"%Y-%m-%dT%H:%M:%SZ"
  fi
}

# Load template from file with caching
# Arguments:
#   $1 - Template file path
# Returns:
#   Template content on stdout, 0 on success, 1 on failure
load_template() {
  local template_file="$1"
  
  if [[ -z "$template_file" ]]; then
    log "ERROR" "REPORT" "Template file path is required"
    return 1
  fi
  
  if [[ ! -f "$template_file" ]]; then
    log "ERROR" "REPORT" "Template file does not exist: $template_file"
    return 1
  fi
  
  if [[ ! -r "$template_file" ]]; then
    log "ERROR" "REPORT" "Template file is not readable: $template_file"
    return 1
  fi
  
  # Check cache
  if [[ "$TEMPLATE_CACHE_PATH" == "$template_file" ]] && [[ -n "$TEMPLATE_CACHE" ]]; then
    echo "$TEMPLATE_CACHE"
    return 0
  fi
  
  # Load and cache template
  local content
  if ! content=$(<"$template_file"); then
    log "ERROR" "REPORT" "Failed to read template file: $template_file"
    return 1
  fi
  
  TEMPLATE_CACHE="$content"
  TEMPLATE_CACHE_PATH="$template_file"
  
  echo "$content"
  return 0
}

# Merge workspace JSON data with helper variables
# Arguments:
#   $1 - JSON data from workspace
# Returns:
#   Enhanced JSON with helper fields on stdout
merge_workspace_data() {
  local json_data="$1"
  
  if [[ -z "$json_data" ]]; then
    log "ERROR" "REPORT" "JSON data is required"
    return 1
  fi
  
  # Flatten nested plugin data to root level for template substitution.
  # Plugin data is stored namespaced: { "stat": { "file_size": "123", ... }, ... }
  # Templates expect flat variables: {{file_size}} not {{stat.file_size}}
  # This jq expression merges all plugin-namespaced objects to the root level,
  # e.g., {"stat": {"file_size": "123"}} becomes {"file_size": "123", "stat": {...}}
  local flattened_data
  flattened_data=$(echo "$json_data" | jq '
    # Start with the original data
    . as $root |
    # Get all plugin names (objects that are not arrays and not primitive)
    [keys[] | select(. as $k | $root[$k] | type == "object" and (. | has("name") | not))] as $plugin_keys |
    # Merge all plugin data objects to root level
    reduce $plugin_keys[] as $pk (.; . * .[$pk])
  ' 2>/dev/null) || flattened_data="$json_data"
  
  # Extract fields from flattened JSON
  local file_path file_size filename filepath_relative
  file_path=$(echo "$flattened_data" | jq -r '.file_path // ""' 2>/dev/null)
  file_size=$(echo "$flattened_data" | jq -r '.file_size // 0' 2>/dev/null)
  filename=$(echo "$flattened_data" | jq -r '.filename // ""' 2>/dev/null)
  filepath_relative=$(echo "$flattened_data" | jq -r '.filepath_relative // ""' 2>/dev/null)
  
  # Fallback for filename if not in JSON
  if [[ -z "$filename" ]] && [[ -n "$file_path" ]]; then
    filename=$(basename "$file_path")
  fi
  
  # Generate helper values
  local file_size_human generation_time
  file_size_human=$(human_readable_size "$file_size")
  generation_time=$(format_date_iso8601)
  
  # Merge with flattened data, ensuring all template variables are at root level
  echo "$flattened_data" | jq \
    --arg filename "$filename" \
    --arg file_size_human "$file_size_human" \
    --arg generation_time "$generation_time" \
    '. + {
      filename: $filename,
      file_size_human: $file_size_human,
      generation_time: $generation_time
    }'
}

# Write report content to file atomically
# Arguments:
#   $1 - Target file path
#   $2 - Report content
# Returns:
#   0 on success, 1 on failure
write_report() {
  local target_file="$1"
  local content="$2"
  
  if [[ -z "$target_file" ]]; then
    log "ERROR" "REPORT" "Target file path is required"
    return 1
  fi
  
  # Create parent directory if needed
  local target_dir
  target_dir=$(dirname "$target_file")
  if [[ ! -d "$target_dir" ]]; then
    if ! mkdir -p "$target_dir" 2>/dev/null; then
      log "ERROR" "REPORT" "Failed to create parent directory: $target_dir"
      return 1
    fi
  fi
  
  # Validate directory is writable
  if [[ ! -w "$target_dir" ]]; then
    log "ERROR" "REPORT" "Target directory is not writable: $target_dir"
    return 1
  fi
  
  # Write atomically using temp file
  local temp_file="${target_file}.tmp.$$"
  if ! echo "$content" > "$temp_file" 2>/dev/null; then
    log "ERROR" "REPORT" "Failed to write temporary file: $temp_file"
    rm -f "$temp_file"
    return 1
  fi
  
  if ! mv "$temp_file" "$target_file" 2>/dev/null; then
    log "ERROR" "REPORT" "Failed to move temporary file to target: $target_file"
    rm -f "$temp_file"
    return 1
  fi
  
  return 0
}

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

  if [[ ! -d "$workspace_dir" ]]; then
    log "ERROR" "REPORT" "Workspace directory does not exist: $workspace_dir"
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

  # Load template content with caching
  local template_content=""
  if [[ -n "$template_file" ]] && [[ -f "$template_file" ]]; then
    if ! template_content=$(load_template "$template_file"); then
      log "ERROR" "REPORT" "Failed to load template: $template_file"
      return 1
    fi
  fi

  # Find all workspace JSON files
  local workspace_files_dir="$workspace_dir/files"
  if [[ ! -d "$workspace_files_dir" ]]; then
    log "INFO" "REPORT" "No workspace files directory, nothing to report"
    return 0
  fi

  local report_count=0
  local error_count=0
  
  for json_file in "$workspace_files_dir"/*.json; do
    # Skip if no JSON files exist (glob didn't match)
    [[ -f "$json_file" ]] || continue

    # Load workspace data
    local json_data
    if ! json_data=$(cat "$json_file" 2>/dev/null); then
      log "WARN" "REPORT" "Failed to read workspace file: $json_file"
      error_count=$((error_count + 1))
      continue
    fi
    
    if ! echo "$json_data" | jq empty 2>/dev/null; then
      log "WARN" "REPORT" "Skipping invalid JSON in workspace file: $json_file"
      error_count=$((error_count + 1))
      continue
    fi

    # Merge workspace data with helper variables
    local enhanced_data
    if ! enhanced_data=$(merge_workspace_data "$json_data"); then
      log "WARN" "REPORT" "Failed to merge workspace data: $json_file"
      error_count=$((error_count + 1))
      continue
    fi

    # Get filepath_relative from workspace data for sidecar naming
    local filepath_relative
    filepath_relative=$(echo "$json_data" | jq -r '.filepath_relative // empty' 2>/dev/null)

    local report_path
    if [[ -n "$filepath_relative" ]]; then
      # Create sidecar file path: source/subdir/doc.pdf -> output/subdir/doc.md
      local relative_dir
      relative_dir=$(dirname "$filepath_relative")
      local basename_noext
      basename_noext=$(basename "$filepath_relative" | sed 's/\.[^.]*$//')
      
      if [[ "$relative_dir" == "." ]]; then
        report_path="$target_dir/${basename_noext}.md"
      else
        # Create subdirectory mirroring source structure
        if ! mkdir -p "$target_dir/$relative_dir" 2>/dev/null; then
          log "WARN" "REPORT" "Failed to create output directory: $target_dir/$relative_dir"
        fi
        report_path="$target_dir/$relative_dir/${basename_noext}.md"
      fi
      log "DEBUG" "REPORT" "Using sidecar path: $report_path (from $filepath_relative)"
    else
      # Fallback to hash-based naming if no filepath_relative
      local file_hash
      file_hash=$(basename "$json_file" .json)
      report_path="$target_dir/${file_hash}.md"
      log "DEBUG" "REPORT" "Fallback to hash-based naming: $report_path"
    fi

    # Generate report content from template and enhanced data
    local report_content
    if [[ -n "$template_content" ]]; then
      if ! report_content=$(render_report "$template_content" "$enhanced_data"); then
        log "WARN" "REPORT" "Failed to render report for: $json_file"
        error_count=$((error_count + 1))
        continue
      fi
    else
      # No template - output formatted JSON
      report_content=$(echo "$enhanced_data" | jq '.')
    fi

    # Write report file atomically
    if write_report "$report_path" "$report_content"; then
      report_count=$((report_count + 1))
      log "DEBUG" "REPORT" "Generated report: $report_path"
    else
      log "WARN" "REPORT" "Failed to write report: $report_path"
      error_count=$((error_count + 1))
    fi
  done

  if [[ $error_count -gt 0 ]]; then
    log "WARN" "REPORT" "Report generation completed with $error_count error(s)"
  fi
  
  log "INFO" "REPORT" "Report generation complete: $report_count report(s) written to $target_dir"
  return 0
}

# Render a single report by substituting workspace data into template
# Arguments:
#   $1 - Template content
#   $2 - JSON data from workspace (enhanced with helpers)
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

  # Convert JSON to associative array for template engine
  declare -A report_data
  
  # Extract all fields from JSON and populate associative array
  while IFS='=' read -r key value; do
    report_data["$key"]="$value"
  done < <(echo "$json_data" | jq -r 'to_entries | .[] | "\(.key)=\(.value // "")"' 2>/dev/null)
  
  # Process template stages directly to avoid nameref issues
  # Note: process_template has a nameref bug where internal functions (substitute_variables,
  # process_conditionals, process_loops) all declare 'local -n data_ref="$2"' which creates
  # a circular reference when process_template itself has 'local -n data_ref="$2"'.
  # Workaround: Call the functions directly instead of through process_template wrapper.
  # This provides full template functionality while avoiding the nameref collision.
  # Related: Template engine is feature_0008, nameref issue documented but not fixed yet.
  local result="$template"
  
  # Validate template syntax
  if ! validate_template_syntax "$result"; then
    log "ERROR" "REPORT" "Template syntax validation failed"
    return 1
  fi
  
  # Apply template transformations
  result=$(substitute_variables "$result" report_data) || {
    log "ERROR" "REPORT" "Variable substitution failed"
    return 1
  }
  
  result=$(process_conditionals "$result" report_data) || {
    log "ERROR" "REPORT" "Conditional processing failed"
    return 1
  }
  
  result=$(process_loops "$result" report_data) || {
    log "ERROR" "REPORT" "Loop processing failed"
    return 1
  }
  
  result=$(remove_comments "$result")
  
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
