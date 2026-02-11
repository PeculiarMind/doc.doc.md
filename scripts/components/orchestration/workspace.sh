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

# Component: workspace.sh
# Purpose: Workspace directory management, JSON read/write with atomic operations and locking
# Dependencies: core/logging.sh, core/error_handling.sh, core/constants.sh
# Exports: init_workspace(), generate_file_hash(), load_workspace(), save_workspace(),
#          acquire_lock(), release_lock(), get_last_scan_time(), update_scan_timestamp(),
#          remove_corrupted_workspace_file(), validate_workspace_schema()
# Side Effects: Reads/writes filesystem

# ==============================================================================
# Configuration Constants
# ==============================================================================

# Lock acquisition timeout in seconds
readonly WORKSPACE_LOCK_TIMEOUT="${WORKSPACE_LOCK_TIMEOUT:-30}"

# Stale lock threshold in seconds (5 minutes)
readonly WORKSPACE_STALE_LOCK_AGE="${WORKSPACE_STALE_LOCK_AGE:-300}"

# ==============================================================================
# Workspace Initialization
# ==============================================================================

# Initialize workspace directory structure
# Creates workspace directory with standard subdirectories: files/ and plugins/
# Arguments:
#   $1 - Workspace directory path
# Returns:
#   0 on success, 1 on failure
init_workspace() {
  local workspace_dir="$1"

  # Validate argument
  if [[ -z "$workspace_dir" ]]; then
    log "ERROR" "WORKSPACE" "Workspace directory argument is required"
    return 1
  fi

  # Security: Prevent path traversal (CWE-22)
  case "$workspace_dir" in
    *..*)
      log "ERROR" "WORKSPACE" "Path traversal detected in workspace directory"
      return 1
      ;;
  esac

  # Check if workspace already exists and is valid
  if [[ -d "$workspace_dir" ]] && [[ -d "$workspace_dir/files" ]] && [[ -d "$workspace_dir/plugins" ]]; then
    # Validate writable
    if [[ -w "$workspace_dir" ]]; then
      log "INFO" "WORKSPACE" "Workspace already initialized: $workspace_dir"
      return 0
    else
      log "ERROR" "WORKSPACE" "Workspace directory is not writable: $workspace_dir"
      return 1
    fi
  fi

  log "INFO" "WORKSPACE" "Initializing workspace: $workspace_dir"

  # Create workspace directory structure with restrictive permissions (0700)
  if ! mkdir -p "$workspace_dir" 2>/dev/null; then
    log "ERROR" "WORKSPACE" "Failed to create workspace directory: $workspace_dir"
    return 1
  fi
  chmod 0700 "$workspace_dir" 2>/dev/null || true

  # Create standard subdirectories
  if ! mkdir -p "$workspace_dir/files" 2>/dev/null; then
    log "ERROR" "WORKSPACE" "Failed to create files subdirectory"
    return 1
  fi
  chmod 0700 "$workspace_dir/files" 2>/dev/null || true

  if ! mkdir -p "$workspace_dir/plugins" 2>/dev/null; then
    log "ERROR" "WORKSPACE" "Failed to create plugins subdirectory"
    return 1
  fi
  chmod 0700 "$workspace_dir/plugins" 2>/dev/null || true

  # Validate workspace is writable
  if [[ ! -w "$workspace_dir" ]]; then
    log "ERROR" "WORKSPACE" "Workspace directory is not writable: $workspace_dir"
    return 1
  fi

  log "INFO" "WORKSPACE" "Workspace initialized successfully: $workspace_dir"
  return 0
}

# ==============================================================================
# File Hash Generation
# ==============================================================================

# Generate content-based SHA-256 hash for file identification
# Arguments:
#   $1 - File path
# Returns:
#   Hash string on stdout, exit code 0 on success, 1 on failure
generate_file_hash() {
  local filepath="$1"

  if [[ -z "$filepath" ]]; then
    log "ERROR" "WORKSPACE" "File path argument is required for hash generation"
    return 1
  fi

  if [[ ! -f "$filepath" ]]; then
    log "ERROR" "WORKSPACE" "File does not exist for hash generation: $filepath"
    return 1
  fi

  if [[ ! -r "$filepath" ]]; then
    log "ERROR" "WORKSPACE" "File is not readable for hash generation: $filepath"
    return 1
  fi

  local hash
  hash=$(sha256sum "$filepath" 2>/dev/null | cut -d' ' -f1)

  if [[ -z "$hash" ]]; then
    log "ERROR" "WORKSPACE" "Failed to generate hash for: $filepath"
    return 1
  fi

  echo "$hash"
  return 0
}

# ==============================================================================
# Lock Management
# ==============================================================================

# Acquire lock for a workspace file
# Arguments:
#   $1 - Workspace directory
#   $2 - File hash
#   $3 - Timeout in seconds (optional, defaults to WORKSPACE_LOCK_TIMEOUT)
# Returns:
#   0 on success, 1 on failure (timeout or error)
acquire_lock() {
  local workspace_dir="$1"
  local file_hash="$2"
  local timeout="${3:-$WORKSPACE_LOCK_TIMEOUT}"

  if [[ -z "$workspace_dir" ]] || [[ -z "$file_hash" ]]; then
    log "ERROR" "WORKSPACE" "Workspace directory and file hash required for lock acquisition"
    return 1
  fi

  local lock_file="$workspace_dir/files/${file_hash}.json.lock"
  local start_time
  start_time=$(date +%s)

  log "DEBUG" "WORKSPACE" "Acquiring lock: $lock_file (timeout: ${timeout}s)"

  while true; do
    # Check for stale lock and clean up
    if [[ -f "$lock_file" ]]; then
      local lock_age
      local lock_mtime
      lock_mtime=$(stat -c '%Y' "$lock_file" 2>/dev/null || echo "0")
      lock_age=$(( $(date +%s) - lock_mtime ))

      if [[ "$lock_age" -gt "$WORKSPACE_STALE_LOCK_AGE" ]]; then
        log "WARN" "WORKSPACE" "Removing stale lock file (age: ${lock_age}s): $lock_file"
        rm -f "$lock_file" 2>/dev/null
      fi
    fi

    # Try to create lock file atomically using mkdir (atomic on POSIX)
    if (set -C; echo "$$" > "$lock_file") 2>/dev/null; then
      chmod 0600 "$lock_file" 2>/dev/null || true
      log "DEBUG" "WORKSPACE" "Lock acquired: $lock_file"
      return 0
    fi

    # Check timeout
    local elapsed
    elapsed=$(( $(date +%s) - start_time ))
    if [[ "$elapsed" -ge "$timeout" ]]; then
      log "ERROR" "WORKSPACE" "Lock acquisition timed out after ${timeout}s: $lock_file"
      return 1
    fi

    # Wait briefly before retrying
    sleep 0.1 2>/dev/null || sleep 1
  done
}

# Release lock for a workspace file
# Arguments:
#   $1 - Workspace directory
#   $2 - File hash
# Returns:
#   0 on success, 1 on failure
release_lock() {
  local workspace_dir="$1"
  local file_hash="$2"

  if [[ -z "$workspace_dir" ]] || [[ -z "$file_hash" ]]; then
    log "ERROR" "WORKSPACE" "Workspace directory and file hash required for lock release"
    return 1
  fi

  local lock_file="$workspace_dir/files/${file_hash}.json.lock"

  if [[ -f "$lock_file" ]]; then
    rm -f "$lock_file" 2>/dev/null
    log "DEBUG" "WORKSPACE" "Lock released: $lock_file"
  else
    log "DEBUG" "WORKSPACE" "Lock file already removed: $lock_file"
  fi

  return 0
}

# ==============================================================================
# Workspace Data Operations
# ==============================================================================

# Load workspace JSON data for a specified file hash
# Arguments:
#   $1 - Workspace directory
#   $2 - File hash
# Returns:
#   JSON data on stdout, exit code 0 on success
#   Empty JSON object on missing file, exit code 0
#   Removes corrupted files and returns empty JSON, exit code 0
load_workspace() {
  local workspace_dir="$1"
  local file_hash="$2"

  if [[ -z "$workspace_dir" ]] || [[ -z "$file_hash" ]]; then
    log "ERROR" "WORKSPACE" "Workspace directory and file hash required for load"
    echo "{}"
    return 1
  fi

  local json_file="$workspace_dir/files/${file_hash}.json"

  # Handle missing workspace files gracefully
  if [[ ! -f "$json_file" ]]; then
    log "DEBUG" "WORKSPACE" "No workspace data found for hash: $file_hash"
    echo "{}"
    return 0
  fi

  # Read and validate JSON
  local json_data
  json_data=$(cat "$json_file" 2>/dev/null)

  if [[ -z "$json_data" ]]; then
    log "WARN" "WORKSPACE" "Empty workspace file, removing: $json_file"
    remove_corrupted_workspace_file "$workspace_dir" "$file_hash" "$json_file"
    echo "{}"
    return 0
  fi

  # Validate JSON syntax
  if ! echo "$json_data" | jq empty 2>/dev/null; then
    log "WARN" "WORKSPACE" "Corrupted JSON detected, removing: $json_file"
    remove_corrupted_workspace_file "$workspace_dir" "$file_hash" "$json_file"
    echo "{}"
    return 0
  fi

  log "DEBUG" "WORKSPACE" "Loaded workspace data for hash: $file_hash"
  echo "$json_data"
  return 0
}

# Save workspace JSON data atomically using temp file + rename pattern
# Arguments:
#   $1 - Workspace directory
#   $2 - File hash
#   $3 - JSON data string
# Returns:
#   0 on success, 1 on failure
save_workspace() {
  local workspace_dir="$1"
  local file_hash="$2"
  local json_data="$3"

  if [[ -z "$workspace_dir" ]] || [[ -z "$file_hash" ]] || [[ -z "$json_data" ]]; then
    log "ERROR" "WORKSPACE" "Workspace directory, file hash, and JSON data required for save"
    return 1
  fi

  local json_file="$workspace_dir/files/${file_hash}.json"
  local temp_file="$json_file.tmp.$$"

  # Validate JSON before writing
  if ! echo "$json_data" | jq empty 2>/dev/null; then
    log "ERROR" "WORKSPACE" "Invalid JSON data, not saving for hash: $file_hash"
    return 1
  fi

  # Acquire lock
  if ! acquire_lock "$workspace_dir" "$file_hash" "$WORKSPACE_LOCK_TIMEOUT"; then
    log "ERROR" "WORKSPACE" "Failed to acquire lock for save: $file_hash"
    return 1
  fi

  # Write to temp file with pretty-printing
  if ! echo "$json_data" | jq '.' > "$temp_file" 2>/dev/null; then
    log "ERROR" "WORKSPACE" "Failed to write temp file: $temp_file"
    rm -f "$temp_file" 2>/dev/null
    release_lock "$workspace_dir" "$file_hash"
    return 1
  fi

  # Validate the written temp file
  if ! jq empty "$temp_file" 2>/dev/null; then
    log "ERROR" "WORKSPACE" "Temp file contains invalid JSON, aborting save"
    rm -f "$temp_file" 2>/dev/null
    release_lock "$workspace_dir" "$file_hash"
    return 1
  fi

  # Set restrictive permissions on temp file (0600)
  chmod 0600 "$temp_file" 2>/dev/null || true

  # Atomic rename
  if ! mv "$temp_file" "$json_file" 2>/dev/null; then
    log "ERROR" "WORKSPACE" "Failed atomic rename for: $json_file"
    rm -f "$temp_file" 2>/dev/null
    release_lock "$workspace_dir" "$file_hash"
    return 1
  fi

  # Release lock
  release_lock "$workspace_dir" "$file_hash"

  log "DEBUG" "WORKSPACE" "Saved workspace data for hash: $file_hash"
  return 0
}

# ==============================================================================
# Metadata Operations
# ==============================================================================

# Merge new plugin data with existing workspace data
# Arguments:
#   $1 - Existing JSON data
#   $2 - Plugin name
#   $3 - Plugin result JSON
#   $4 - Status (success/failure)
# Returns:
#   Merged JSON on stdout
merge_plugin_data() {
  local existing_data="$1"
  local plugin_name="$2"
  local plugin_result="$3"
  local status="${4:-success}"

  if [[ -z "$existing_data" ]]; then
    existing_data="{}"
  fi

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Build plugin execution entry
  local plugin_entry
  plugin_entry=$(jq -n \
    --arg name "$plugin_name" \
    --arg ts "$timestamp" \
    --arg status "$status" \
    '{"name": $name, "timestamp": $ts, "status": $status}' 2>/dev/null)

  # Merge plugin result and update plugins_executed array
  local merged
  merged=$(echo "$existing_data" | jq \
    --arg plugin_name "$plugin_name" \
    --argjson plugin_result "$plugin_result" \
    --argjson plugin_entry "$plugin_entry" \
    '. * {($plugin_name): $plugin_result} | .plugins_executed = ((.plugins_executed // []) + [$plugin_entry])' 2>/dev/null)

  if [[ -z "$merged" ]]; then
    log "ERROR" "WORKSPACE" "Failed to merge plugin data for: $plugin_name"
    echo "$existing_data"
    return 1
  fi

  echo "$merged"
  return 0
}

# ==============================================================================
# Timestamp Tracking
# ==============================================================================

# Get last scan timestamp from workspace
# Arguments:
#   $1 - Workspace directory
# Returns:
#   ISO 8601 timestamp string or empty string if no previous scan
get_last_scan_time() {
  local workspace_dir="$1"

  if [[ -z "$workspace_dir" ]] || [[ ! -d "$workspace_dir" ]]; then
    echo ""
    return 0
  fi

  local workspace_meta="$workspace_dir/workspace.json"
  if [[ -f "$workspace_meta" ]]; then
    local timestamp
    timestamp=$(jq -r '.last_full_scan // empty' "$workspace_meta" 2>/dev/null)
    if [[ -n "$timestamp" ]]; then
      echo "$timestamp"
      return 0
    fi
  fi

  echo ""
  return 0
}

# Update scan timestamp for a specific file hash
# Arguments:
#   $1 - Workspace directory
#   $2 - File hash
#   $3 - Timestamp (optional, defaults to current UTC time)
# Returns:
#   0 on success, 1 on failure
update_scan_timestamp() {
  local workspace_dir="$1"
  local file_hash="$2"
  local timestamp="${3:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}"

  if [[ -z "$workspace_dir" ]] || [[ -z "$file_hash" ]]; then
    log "ERROR" "WORKSPACE" "Workspace directory and file hash required for timestamp update"
    return 1
  fi

  # Load existing data
  local existing_data
  existing_data=$(load_workspace "$workspace_dir" "$file_hash")

  # Update last_scanned field
  local updated_data
  updated_data=$(echo "$existing_data" | jq \
    --arg ts "$timestamp" \
    '.last_scanned = $ts' 2>/dev/null)

  if [[ -z "$updated_data" ]]; then
    log "ERROR" "WORKSPACE" "Failed to update timestamp for hash: $file_hash"
    return 1
  fi

  # Save updated data
  save_workspace "$workspace_dir" "$file_hash" "$updated_data"
}

# Update workspace-level last full scan timestamp
# Arguments:
#   $1 - Workspace directory
#   $2 - Timestamp (optional, defaults to current UTC time)
# Returns:
#   0 on success, 1 on failure
update_full_scan_timestamp() {
  local workspace_dir="$1"
  local timestamp="${2:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}"

  if [[ -z "$workspace_dir" ]]; then
    log "ERROR" "WORKSPACE" "Workspace directory required for full scan timestamp update"
    return 1
  fi

  local workspace_meta="$workspace_dir/workspace.json"
  local temp_file="$workspace_meta.tmp.$$"

  # Load existing workspace metadata or create new
  local existing_data="{}"
  if [[ -f "$workspace_meta" ]]; then
    existing_data=$(cat "$workspace_meta" 2>/dev/null || echo "{}")
    if ! echo "$existing_data" | jq empty 2>/dev/null; then
      existing_data="{}"
    fi
  fi

  # Update timestamp
  local updated_data
  updated_data=$(echo "$existing_data" | jq \
    --arg ts "$timestamp" \
    '.last_full_scan = $ts' 2>/dev/null)

  if [[ -z "$updated_data" ]]; then
    log "ERROR" "WORKSPACE" "Failed to update full scan timestamp"
    return 1
  fi

  # Atomic write
  if ! echo "$updated_data" | jq '.' > "$temp_file" 2>/dev/null; then
    rm -f "$temp_file" 2>/dev/null
    log "ERROR" "WORKSPACE" "Failed to write workspace metadata"
    return 1
  fi

  chmod 0600 "$temp_file" 2>/dev/null || true

  if ! mv "$temp_file" "$workspace_meta" 2>/dev/null; then
    rm -f "$temp_file" 2>/dev/null
    log "ERROR" "WORKSPACE" "Failed atomic rename for workspace metadata"
    return 1
  fi

  log "INFO" "WORKSPACE" "Updated full scan timestamp: $timestamp"
  return 0
}

# ==============================================================================
# Integrity and Recovery
# ==============================================================================

# Remove corrupted workspace file and log the removal
# Arguments:
#   $1 - Workspace directory
#   $2 - File hash
#   $3 - JSON file path (optional, derived from hash if not provided)
# Returns:
#   0 on success
remove_corrupted_workspace_file() {
  local workspace_dir="$1"
  local file_hash="$2"
  local json_file="${3:-$workspace_dir/files/${file_hash}.json}"

  log "WARN" "WORKSPACE" "Removing corrupted workspace file: $json_file"
  log "WARN" "WORKSPACE" "File will be treated as unscanned and rebuilt on next scan"

  rm -f "$json_file" 2>/dev/null

  # Also remove any associated lock file
  rm -f "$json_file.lock" 2>/dev/null

  return 0
}

# Validate workspace directory structure and integrity
# Arguments:
#   $1 - Workspace directory
# Returns:
#   0 if valid, 1 if invalid
validate_workspace_schema() {
  local workspace_dir="$1"
  local is_valid=0

  if [[ -z "$workspace_dir" ]]; then
    log "ERROR" "WORKSPACE" "Workspace directory argument required for validation"
    return 1
  fi

  # Check workspace directory exists
  if [[ ! -d "$workspace_dir" ]]; then
    log "ERROR" "WORKSPACE" "Workspace directory does not exist: $workspace_dir"
    return 1
  fi

  # Check required subdirectories
  if [[ ! -d "$workspace_dir/files" ]]; then
    log "ERROR" "WORKSPACE" "Missing required subdirectory: files/"
    is_valid=1
  fi

  if [[ ! -d "$workspace_dir/plugins" ]]; then
    log "ERROR" "WORKSPACE" "Missing required subdirectory: plugins/"
    is_valid=1
  fi

  # Check writability
  if [[ ! -w "$workspace_dir" ]]; then
    log "ERROR" "WORKSPACE" "Workspace directory is not writable"
    is_valid=1
  fi

  # Validate all JSON files in files/ directory
  if [[ -d "$workspace_dir/files" ]]; then
    local corrupted_count=0
    local valid_count=0

    for json_file in "$workspace_dir/files"/*.json; do
      # Skip if no JSON files exist (glob didn't match)
      [[ -f "$json_file" ]] || continue

      if jq empty "$json_file" 2>/dev/null; then
        valid_count=$((valid_count + 1))
      else
        corrupted_count=$((corrupted_count + 1))
        local file_hash
        file_hash=$(basename "$json_file" .json)
        log "WARN" "WORKSPACE" "Corrupted JSON file detected: $json_file"
        remove_corrupted_workspace_file "$workspace_dir" "$file_hash" "$json_file"
      fi
    done

    if [[ "$corrupted_count" -gt 0 ]]; then
      log "WARN" "WORKSPACE" "Removed $corrupted_count corrupted file(s), $valid_count valid file(s) remain"
      log "WARN" "WORKSPACE" "Corrupted files will be rebuilt on next scan (rescan behavior)"
    else
      log "DEBUG" "WORKSPACE" "All $valid_count workspace file(s) validated successfully"
    fi
  fi

  # Validate workspace.json if present
  if [[ -f "$workspace_dir/workspace.json" ]]; then
    if ! jq empty "$workspace_dir/workspace.json" 2>/dev/null; then
      log "WARN" "WORKSPACE" "Corrupted workspace.json detected, removing"
      rm -f "$workspace_dir/workspace.json" 2>/dev/null
    fi
  fi

  if [[ "$is_valid" -eq 0 ]]; then
    log "DEBUG" "WORKSPACE" "Workspace validation passed: $workspace_dir"
  fi

  return "$is_valid"
}
