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

# Component: workspace_security.sh
# Purpose: Workspace integrity verification and security enforcement
# Dependencies: logging.sh
# Exports: verify_workspace_integrity(), validate_workspace_structure(), 
#          validate_workspace_permissions(), harden_workspace_permissions(),
#          validate_workspace_json(), remove_corrupted_file(),
#          validate_file_type(), clean_stale_locks()
# Side Effects: Modifies filesystem permissions, removes corrupted files

# ==============================================================================
# Security Configuration Defaults
# ==============================================================================
MAX_FILE_SIZE=${MAX_FILE_SIZE:-104857600}      # 100 MB default
MAX_WORKSPACE_SIZE=${MAX_WORKSPACE_SIZE:-10737418240}  # 10 GB
LOCK_TIMEOUT=${LOCK_TIMEOUT:-300}              # 5 minutes
MAX_LOCKS=${MAX_LOCKS:-100}                    # Prevent lock DoS
WORKSPACE_PERMISSIONS=${WORKSPACE_PERMISSIONS:-700}  # Owner only
FILE_PERMISSIONS=${FILE_PERMISSIONS:-600}      # Owner read/write only
SOURCE_DIR=${SOURCE_DIR:-}                     # Set by caller

# ==============================================================================
# Main Entry Point
# ==============================================================================

verify_workspace_integrity() {
  local workspace_dir="$1"
  
  log "INFO" "SECURITY" "Verifying workspace integrity: $workspace_dir"
  
  # Validate workspace structure
  if ! validate_workspace_structure "$workspace_dir"; then
    log "ERROR" "SECURITY" "Workspace structure validation failed"
    return 1
  fi
  
  # Validate permissions
  if ! validate_workspace_permissions "$workspace_dir"; then
    log "WARN" "SECURITY" "Workspace permissions too permissive"
    # Attempt to fix
    harden_workspace_permissions "$workspace_dir"
  fi
  
  # Validate JSON files
  local corrupted_count=0
  while IFS= read -r json_file; do
    if ! validate_workspace_json "$json_file"; then
      log "WARN" "SECURITY" "Corrupted JSON detected: $json_file"
      remove_corrupted_file "$workspace_dir" "$json_file"
      corrupted_count=$((corrupted_count + 1))
    fi
  done < <(find "$workspace_dir/files" -name '*.json' -type f 2>/dev/null)
  
  if ((corrupted_count > 0)); then
    log "WARN" "SECURITY" "Removed $corrupted_count corrupted files"
  fi
  
  # Clean stale locks
  clean_stale_locks "$workspace_dir"
  
  log "INFO" "SECURITY" "Workspace integrity verification complete"
  return 0
}

# ==============================================================================
# Workspace Structure Validation
# ==============================================================================

validate_workspace_structure() {
  local workspace_dir="$1"
  
  # Check required directories
  for subdir in files plugins; do
    if [[ ! -d "$workspace_dir/$subdir" ]]; then
      log "ERROR" "SECURITY" "Missing required directory: $subdir"
      return 1
    fi
  done
  
  # Validate path doesn't contain traversal
  if [[ "$workspace_dir" == *".."* ]]; then
    log "ERROR" "SECURITY" "Path traversal detected in workspace path"
    return 1
  fi
  
  return 0
}

# ==============================================================================
# Permission Validation and Hardening
# ==============================================================================

validate_workspace_permissions() {
  local workspace_dir="$1"
  
  # Check directory permissions
  local dir_perms
  dir_perms=$(stat -c '%a' "$workspace_dir" 2>/dev/null)
  
  if [[ "$dir_perms" != "700" ]]; then
    log "WARN" "SECURITY" "Workspace directory permissions too permissive: $dir_perms (should be 700)"
    return 1
  fi
  
  # Check file permissions
  while IFS= read -r json_file; do
    local file_perms
    file_perms=$(stat -c '%a' "$json_file" 2>/dev/null)
    
    if [[ "$file_perms" != "600" ]]; then
      log "WARN" "SECURITY" "Workspace file permissions too permissive: $json_file ($file_perms, should be 600)"
      return 1
    fi
  done < <(find "$workspace_dir/files" -name '*.json' -type f 2>/dev/null)
  
  return 0
}

harden_workspace_permissions() {
  local workspace_dir="$1"
  
  log "INFO" "SECURITY" "Hardening workspace permissions"
  
  # Set directory permissions
  chmod 700 "$workspace_dir" 2>/dev/null || {
    log "ERROR" "SECURITY" "Failed to set workspace directory permissions"
    return 1
  }
  
  chmod 700 "$workspace_dir"/{files,plugins} 2>/dev/null
  
  # Set file permissions
  find "$workspace_dir" -type f -exec chmod 600 {} \; 2>/dev/null
  
  log "INFO" "SECURITY" "Workspace permissions hardened"
  return 0
}

# ==============================================================================
# JSON Validation
# ==============================================================================

validate_workspace_json() {
  local json_file="$1"
  
  # Validate JSON syntax
  if ! jq empty "$json_file" 2>/dev/null; then
    log "ERROR" "SECURITY" "Invalid JSON syntax: $json_file"
    return 1
  fi
  
  # Validate required fields
  for field in file_path file_type last_scanned; do
    if ! jq -e "has(\"$field\")" "$json_file" >/dev/null 2>&1; then
      log "ERROR" "SECURITY" "Missing required field '$field': $json_file"
      return 1
    fi
  done
  
  return 0
}

# ==============================================================================
# Corrupted File Handling
# ==============================================================================

remove_corrupted_file() {
  local workspace_dir="$1"
  local corrupted_file="$2"
  
  rm -f "$corrupted_file" 2>/dev/null || {
    log "ERROR" "SECURITY" "Failed to remove corrupted file: $corrupted_file"
    return 1
  }
  
  log "INFO" "SECURITY" "Removed corrupted file: $corrupted_file"
  return 0
}

# ==============================================================================
# File Type Validation
# ==============================================================================

validate_file_type() {
  local file_path="$1"
  
  # Check if regular file
  if [[ ! -f "$file_path" ]]; then
    log "ERROR" "SECURITY" "Not a regular file: $file_path"
    return 1
  fi
  
  # Check for special file types
  if [[ -c "$file_path" ]] || [[ -b "$file_path" ]] || [[ -p "$file_path" ]] || [[ -S "$file_path" ]]; then
    log "ERROR" "SECURITY" "Special file type rejected: $file_path"
    return 1
  fi
  
  # Check file size
  local file_size
  file_size=$(stat -c '%s' "$file_path" 2>/dev/null)
  
  if [[ "$file_size" -gt "$MAX_FILE_SIZE" ]]; then
    log "ERROR" "SECURITY" "File exceeds size limit: $file_path ($file_size bytes > $MAX_FILE_SIZE)"
    return 1
  fi
  
  # If symlink, validate target
  if [[ -L "$file_path" ]]; then
    local target
    target=$(readlink -f "$file_path")
    
    # Validate target is within allowed directory
    if [[ "$target" != "$SOURCE_DIR"* ]]; then
      log "ERROR" "SECURITY" "Symlink target outside source directory: $file_path -> $target"
      return 1
    fi
  fi
  
  return 0
}

# ==============================================================================
# Lock File Management
# ==============================================================================

clean_stale_locks() {
  local workspace_dir="$1"
  local lock_timeout=300  # 5 minutes
  local current_time
  current_time=$(date +%s)
  
  while IFS= read -r found_lock_file; do
    local lock_age
    lock_age=$(stat -c '%Y' "$found_lock_file" 2>/dev/null)
    
    if (( current_time - lock_age > lock_timeout )); then
      log "WARN" "SECURITY" "Removing stale lock file: $found_lock_file"
      rm -f "$found_lock_file"
    fi
  done < <(find "$workspace_dir/files" -name '*.lock' -type f 2>/dev/null)
}
