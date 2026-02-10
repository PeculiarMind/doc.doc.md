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

# Component: scanner.sh
# Purpose: Directory scanning and file discovery
# Dependencies: core/logging.sh, orchestration/workspace.sh
# Exports: scan_directory(), detect_file_type(), filter_files()
# Side Effects: Reads filesystem

# ==============================================================================
# Configuration Constants
# ==============================================================================

# Maximum file size (100MB default, per req_0055)
readonly MAX_FILE_SIZE="${MAX_FILE_SIZE:-104857600}"

# ==============================================================================
# Scanner Functions
# ==============================================================================

# Detect MIME type for a file
# Arguments:
#   $1 - File path
# Returns:
#   MIME type string or "application/octet-stream" on failure
detect_file_type() {
  local file_path="$1"
  
  # Validate file exists
  if [[ ! -e "$file_path" ]]; then
    log "DEBUG" "SCANNER" "File does not exist for MIME detection: $file_path"
    echo "application/octet-stream"
    return 0
  fi
  
  # Detect MIME type using file command
  local mime_type
  mime_type=$(file --mime-type -b "$file_path" 2>/dev/null)
  
  if [[ -z "$mime_type" ]]; then
    log "DEBUG" "SCANNER" "MIME detection failed for: $file_path"
    echo "application/octet-stream"
  else
    log "DEBUG" "SCANNER" "Detected MIME type for $file_path: $mime_type"
    echo "$mime_type"
  fi
  
  return 0
}

# Get last scan timestamp from workspace
# Arguments:
#   $1 - Workspace directory
# Returns:
#   Unix timestamp or empty string if no previous scan
get_last_scan_time() {
  local workspace_dir="$1"
  
  # If workspace doesn't exist or is empty, return empty (no previous scan)
  if [[ -z "$workspace_dir" ]] || [[ ! -d "$workspace_dir" ]]; then
    echo ""
    return 0
  fi
  
  # Try to read timestamp file (future: integrate with workspace.sh)
  local timestamp_file="${workspace_dir}/.last_scan_timestamp"
  if [[ -f "$timestamp_file" ]]; then
    cat "$timestamp_file" 2>/dev/null || echo ""
  else
    echo ""
  fi
  
  return 0
}

# Scan directory recursively and discover files
# Arguments:
#   $1 - Source directory path
#   $2 - Workspace directory (optional, for incremental analysis)
#   $3 - Force fullscan flag ("true" or "false", default "false")
# Returns:
#   Exit code: 0 on success, 1 on failure
# Outputs:
#   List of files to analyze: filepath|mime_type|file_size|modification_time
scan_directory() {
  local source_dir="$1"
  local workspace_dir="${2:-}"
  local force_fullscan="${3:-false}"
  
  # Validate source directory argument
  if [[ -z "$source_dir" ]]; then
    log "ERROR" "SCANNER" "Source directory argument is required"
    return 1
  fi
  
  # Validate source directory exists
  if [[ ! -d "$source_dir" ]]; then
    log "ERROR" "SCANNER" "Source directory does not exist: $source_dir"
    return 1
  fi
  
  # Get absolute path for source directory
  source_dir="$(cd "$source_dir" && pwd)"
  
  # Get canonical path for boundary checking
  local canonical_source
  canonical_source=$(readlink -f "$source_dir" 2>/dev/null || realpath "$source_dir" 2>/dev/null || echo "$source_dir")
  
  log "INFO" "SCANNER" "Scanning directory: $source_dir"
  
  # Load workspace timestamp for incremental analysis
  local last_scan_time=""
  if [[ "$force_fullscan" != "true" ]]; then
    last_scan_time=$(get_last_scan_time "$workspace_dir")
    if [[ -n "$last_scan_time" ]]; then
      log "INFO" "SCANNER" "Incremental scan mode: comparing against timestamp $last_scan_time"
    else
      log "INFO" "SCANNER" "No previous scan found, analyzing all files"
    fi
  else
    log "INFO" "SCANNER" "Full scan mode: analyzing all files"
  fi
  
  # Counters for reporting
  local total_files=0
  local files_to_analyze=0
  local files_unchanged=0
  local files_skipped=0
  
  # Temporary array to collect files
  local -a files_to_process=()
  
  # Find all items recursively using single find invocation (excluding directories)
  while IFS= read -r -d '' filepath; do
    total_files=$((total_files + 1))
    
    # Skip directories
    if [[ -d "$filepath" ]]; then
      log "DEBUG" "SCANNER" "Skipping directory: $filepath"
      files_skipped=$((files_skipped + 1))
      continue
    fi
    
    # Security: Check for symlinks and skip them (CWE-59 - Symlink Path Traversal)
    if [[ -L "$filepath" ]]; then
      log "WARN" "SCANNER" "Skipping symlink: $filepath"
      files_skipped=$((files_skipped + 1))
      continue
    fi
    
    # Security: Validate path stays within source directory bounds (CWE-22 - Path Traversal)
    local canonical_file
    canonical_file=$(readlink -f "$filepath" 2>/dev/null || realpath "$filepath" 2>/dev/null || echo "$filepath")
    
    # Check if canonical path starts with canonical source path
    if [[ "$canonical_file" != "$canonical_source"* ]]; then
      log "WARN" "SCANNER" "Skipping file outside source directory bounds: $filepath"
      files_skipped=$((files_skipped + 1))
      continue
    fi
    
    # Check for special file types (FIFO, character device, block device, socket)
    if [[ -p "$filepath" ]] || [[ -c "$filepath" ]] || [[ -b "$filepath" ]] || [[ -S "$filepath" ]]; then
      log "WARN" "SCANNER" "Skipping special file: $filepath"
      files_skipped=$((files_skipped + 1))
      continue
    fi
    
    # Validate file is a regular file (not symlink to special file, etc.)
    if [[ ! -f "$filepath" ]]; then
      log "DEBUG" "SCANNER" "Skipping non-regular file: $filepath"
      files_skipped=$((files_skipped + 1))
      continue
    fi
    
    # Get file size
    local file_size
    file_size=$(stat -c '%s' "$filepath" 2>/dev/null)
    
    if [[ -z "$file_size" ]]; then
      log "WARN" "SCANNER" "Could not determine file size, skipping: $filepath"
      files_skipped=$((files_skipped + 1))
      continue
    fi
    
    # Check file size limit
    if [[ "$file_size" -gt "$MAX_FILE_SIZE" ]]; then
      log "WARN" "SCANNER" "Skipping file exceeding size limit ($MAX_FILE_SIZE bytes): $filepath ($file_size bytes)"
      files_skipped=$((files_skipped + 1))
      continue
    fi
    
    # Get file modification time
    local file_mtime
    file_mtime=$(stat -c '%Y' "$filepath" 2>/dev/null)
    
    if [[ -z "$file_mtime" ]]; then
      log "WARN" "SCANNER" "Could not determine modification time, skipping: $filepath"
      files_skipped=$((files_skipped + 1))
      continue
    fi
    
    # Check if file needs analysis (incremental mode)
    if [[ "$force_fullscan" == "true" ]] || [[ -z "$last_scan_time" ]] || [[ "$file_mtime" -gt "$last_scan_time" ]]; then
      # File needs analysis - detect MIME type
      local mime_type
      mime_type=$(detect_file_type "$filepath")
      
      # Add to processing list
      files_to_process+=("$filepath|$mime_type|$file_size|$file_mtime")
      files_to_analyze=$((files_to_analyze + 1))
      
      log "DEBUG" "SCANNER" "Queued for analysis: $filepath (MIME: $mime_type, Size: $file_size, MTime: $file_mtime)"
    else
      # File unchanged since last scan
      files_unchanged=$((files_unchanged + 1))
      log "DEBUG" "SCANNER" "Unchanged, skipping: $filepath"
    fi
    
  done < <(find "$source_dir" -print0 2>/dev/null)
  
  # Log scan summary - always shown as this is primary operation feedback
  # Using direct stderr output instead of log() to ensure visibility
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S")
  echo "[${timestamp}] [INFO] [SCANNER] Scan complete: $files_to_analyze files to analyze" >&2
  
  if is_verbose; then
    log "INFO" "SCANNER" "Total files found: $total_files"
    log "INFO" "SCANNER" "Files to analyze: $files_to_analyze"
    log "INFO" "SCANNER" "Files unchanged: $files_unchanged"
    log "INFO" "SCANNER" "Files skipped: $files_skipped"
  fi
  
  # Output file list for downstream processing
  for file_entry in "${files_to_process[@]}"; do
    echo "$file_entry"
  done
  
  return 0
}

# Filter files by criteria (future implementation)
# Arguments:
#   $1 - Filter criteria
#   $@ - Files to filter
# Returns:
#   Filtered file list
filter_files() {
  local criteria="$1"
  shift
  log "DEBUG" "SCANNER" "Filtering files by: ${criteria}"
  # Placeholder for filtering logic
  return 0
}
