# Feature: Workspace Integrity and Security

**ID**: 0013  
**Type**: Feature Implementation  
**Status**: Backlog  
**Created**: 2026-02-09  
**Updated**: 2026-02-09 (Moved to backlog)  
**Priority**: High (Security)

## Overview
Implement workspace security features including integrity verification, secure defaults, file type validation, permission hardening, and corruption detection to protect workspace data from tampering and ensure secure operation.

## Description
Create comprehensive workspace security that validates workspace structure, verifies JSON integrity, enforces restrictive file permissions, validates file types before processing, implements secure defaults, and detects corruption attempts. This feature combines multiple security requirements into a cohesive security layer protecting the workspace from unauthorized access, tampering, and malicious input.

Workspace security is critical because workspace contains analysis results, controls plugin execution, and serves as the trust boundary between analysis phases.

## Business Value
- Prevents data tampering and integrity violations
- Enables secure multi-user or shared workspace scenarios
- Prevents path traversal and DoS attacks through file validation
- Provides corruption recovery mechanisms
- Establishes security-first operational posture
- Protects against filesystem-based attacks

## Related Requirements
- [req_0050](../../01_vision/02_requirements/03_accepted/req_0050_workspace_integrity_verification.md) - Workspace Integrity (PRIMARY - Risk 204)
- [req_0052](../../01_vision/02_requirements/03_accepted/req_0052_secure_defaults_and_configuration_hardening.md) - Secure Defaults (Risk 91)
- [req_0055](../../01_vision/02_requirements/03_accepted/req_0055_file_type_verification_and_validation.md) - File Type Verification (Risk 92)
- [req_0032](../../01_vision/02_requirements/03_accepted/req_0032_workspace_directory_management.md) - Workspace Management

## Acceptance Criteria

### Workspace Structure Validation
- [ ] System validates workspace directory structure matches expected schema
- [ ] System validates required subdirectories exist: `files/`, `plugins/`, `corruption/`
- [ ] System validates `.workspace_version` file exists and is readable
- [ ] System detects unexpected files or directories (log warning)
- [ ] System validates workspace root is within expected filesystem boundaries

### JSON Schema Validation
- [ ] System validates JSON syntax for all workspace files before reading
- [ ] System validates required fields present: `file_path`, `file_type`, `last_scanned`
- [ ] System validates field types match expected types
- [ ] System validates JSON structure matches workspace schema version
- [ ] System rejects malformed JSON (quarantine to corruption directory)

### File Permission Hardening
- [ ] System sets restrictive permissions on workspace directory: `0700` (owner only)
- [ ] System sets restrictive permissions on JSON files: `0600` (owner read/write only)
- [ ] System validates workspace ownership (owned by current user)
- [ ] System validates no world-readable or world-writable permissions
- [ ] System warns if permissions are too permissive (log security warning)

### File Type Validation
- [ ] System validates source files are regular files (not devices, FIFOs, sockets)
- [ ] System rejects special file types with clear error message
- [ ] System validates symlinks point to regular files within allowed paths
- [ ] System rejects symlinks pointing outside source directory
- [ ] System enforces maximum file size limit (default: 100MB, configurable)
- [ ] System logs all file type validation failures

### Corruption Detection
- [ ] System detects JSON parsing errors (corrupted workspace files)
- [ ] System quarantines corrupted files to `corruption/` directory
- [ ] System appends timestamp to quarantined files: `<hash>.json.corrupted.YYYYMMDD-HHMMSS`
- [ ] System logs corruption events with file path and error details
- [ ] System continues operation with remaining valid files
- [ ] System provides recovery guidance (suggests `-f fullscan` to regenerate)

### Lock File Verification
- [ ] System validates lock files are recent (not stale)
- [ ] System removes stale lock files (age > timeout threshold, default 5 minutes)
- [ ] System validates lock file ownership matches workspace owner
- [ ] System detects concurrent access conflicts
- [ ] System handles lock acquisition failures gracefully (retry, timeout, fail)

### Secure Defaults
- [ ] System creates workspace with restrictive permissions by default
- [ ] System disables plugins by default (`active: false` until user enables)
- [ ] System enables verbose error messages by default (security exception per TC-0007)
- [ ] System operates in read-only mode unless write required
- [ ] System validates all inputs before processing (fail-secure)

### Configuration Hardening
- [ ] System enforces maximum file size limit (prevent DoS via large files)
- [ ] System enforces maximum workspace size (prevent disk exhaustion)
- [ ] System limits concurrent lock acquisitions (prevent resource exhaustion)
- [ ] System enforces timeout for long-running operations
- [ ] System validates configuration values are within safe ranges

### Attack Surface Reduction
- [ ] System validates all file paths before filesystem operations
- [ ] System prevents path traversal in workspace operations
- [ ] System validates symlink targets are within allowed paths
- [ ] System sanitizes filenames before using in filesystem operations
- [ ] System validates workspace paths don't contain shell metacharacters

### Security Logging
- [ ] System logs all security-relevant events:
  - Permission violations
  - Integrity check failures
  - Corruption detection
  - File type validation failures
  - Lock conflicts
- [ ] System includes timestamp, severity, and context in security logs
- [ ] System provides audit trail for security analysis

## Technical Considerations

### Implementation Approach
```bash
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
      quarantine_corrupted_file "$workspace_dir" "$json_file"
      ((corrupted_count++))
    fi
  done < <(find "$workspace_dir/files" -name '*.json' -type f)
  
  if ((corrupted_count > 0)); then
    log "WARN" "SECURITY" "Quarantined $corrupted_count corrupted files"
  fi
  
  # Clean stale locks
  clean_stale_locks "$workspace_dir"
  
  log "INFO" "SECURITY" "Workspace integrity verification complete"
  return 0
}

validate_workspace_structure() {
  local workspace_dir="$1"
  
  # Check required directories
  for subdir in files plugins corruption; do
    if [[ ! -d "$workspace_dir/$subdir" ]]; then
      log "ERROR" "SECURITY" "Missing required directory: $subdir"
      return 1
    fi
  done
  
  # Check version file
  if [[ ! -f "$workspace_dir/.workspace_version" ]]; then
    log "ERROR" "SECURITY" "Missing workspace version file"
    return 1
  fi
  
  # Validate path doesn't contain traversal
  if [[ "$workspace_dir" == *".."* ]]; then
    log "ERROR" "SECURITY" "Path traversal detected in workspace path"
    return 1
  fi
  
  return 0
}

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
  done < <(find "$workspace_dir/files" -name '*.json' -type f)
  
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
  
  chmod 700 "$workspace_dir"/{files,plugins,corruption} 2>/dev/null
  
  # Set file permissions
  find "$workspace_dir" -type f -exec chmod 600 {} \; 2>/dev/null
  
  log "INFO" "SECURITY" "Workspace permissions hardened"
  return 0
}

validate_workspace_json() {
  local json_file="$1"
  
  # Validate JSON syntax
  if ! jq empty "$json_file" 2>/dev/null; then
    log "ERROR" "SECURITY" "Invalid JSON syntax: $json_file"
    return 1
  fi
  
  # Validate required fields
  for field in file_path file_type last_scanned; do
    if ! jq -e "has(\"$field\")" "$json_file" >/dev/null; then
      log "ERROR" "SECURITY" "Missing required field '$field': $json_file"
      return 1
    fi
  done
  
  return 0
}

quarantine_corrupted_file() {
  local workspace_dir="$1"
  local corrupted_file="$2"
  
  local timestamp
  timestamp=$(date +"%Y%m%d-%H%M%S")
  
  local quarantine_file="$workspace_dir/corruption/$(basename "$corrupted_file").corrupted.$timestamp"
  
  mv "$corrupted_file" "$quarantine_file" 2>/dev/null || {
    log "ERROR" "SECURITY" "Failed to quarantine corrupted file: $corrupted_file"
    return 1
  }
  
  log "INFO" "SECURITY" "Quarantined corrupted file: $quarantine_file"
  return 0
}

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

clean_stale_locks() {
  local workspace_dir="$1"
  local lock_timeout=300  # 5 minutes
  local current_time=$(date +%s)
  
  while IFS= read -r lock_file; do
    local lock_age
    lock_age=$(stat -c '%Y' "$lock_file" 2>/dev/null)
    
    if (( current_time - lock_age > lock_timeout )); then
      log "WARN" "SECURITY" "Removing stale lock file: $lock_file"
      rm -f "$lock_file"
    fi
  done < <(find "$workspace_dir/files" -name '*.lock' -type f)
}
```

### Security Configuration Defaults
```bash
# Secure defaults
MAX_FILE_SIZE=104857600      # 100 MB
MAX_WORKSPACE_SIZE=10737418240  # 10 GB
LOCK_TIMEOUT=300             # 5 minutes
MAX_LOCKS=100                # Prevent lock DoS
WORKSPACE_PERMISSIONS=700    # Owner only
FILE_PERMISSIONS=600         # Owner read/write only
```

### Integration Points
- **Workspace Manager**: Calls integrity verification on initialization
- **Directory Scanner**: Uses file type validation
- **Plugin Execution**: Validates workspace before plugin execution
- **Security Logging**: Records all security events

### Dependencies
- Workspace management (feature_0007)
- Logging infrastructure (feature_0001) ✅

### Performance Considerations
- Cache integrity check results (validate once per session)
- Efficient permission checking (batch operations)
- Quick corruption detection (JSON parse only)
- Optimize large workspace validation

### Security Considerations
- Defense-in-depth: Multiple validation layers
- Fail-secure: Reject on validation failure
- Audit logging: Record all security events
- Isolation: Quarantine corrupted data
- Least privilege: Restrictive permissions by default

## Dependencies
- Requires: Basic script structure (feature_0001) ✅
- Requires: Workspace management (feature_0007)
- Blocks: Secure workspace operations

## Testing Strategy
- Unit tests: Structure validation
- Unit tests: Permission validation and hardening
- Unit tests: JSON validation
- Unit tests: File type validation
- Unit tests: Corruption detection and quarantine
- Security tests: Path traversal attempts
- Security tests: Symlink exploitation attempts
- Security tests: Special file type handling
- Integration tests: Corrupted workspace recovery
- Performance tests: Large workspace validation

## Definition of Done
- [ ] All acceptance criteria met
- [ ] Unit tests passing with >85% coverage
- [ ] Security tests passing
- [ ] Code reviewed and security approved
- [ ] Documentation updated (security policies)
- [ ] Security audit completed
- [ ] Penetration testing performed
