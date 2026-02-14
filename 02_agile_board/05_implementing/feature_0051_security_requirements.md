# Security Requirements: Feature 0051 Implementation Checklist

**Feature**: Single-File Analysis Mode  
**Security Review**: [08_single_file_analysis_security_review.md](../../01_vision/04_security/02_scopes/08_single_file_analysis_security_review.md)  
**Developer**: Developer Agent  
**Status**: Ready for Implementation

## ⚠️ MANDATORY SECURITY CONTROLS

All items marked **[REQUIRED]** MUST be implemented. Items marked **[RECOMMENDED]** should be implemented if feasible.

---

## 1. Path Validation [REQUIRED] - CRITICAL

**Requirement**: SEC-0051-001  
**CWE**: CWE-22 (Path Traversal)  
**Priority**: CRITICAL

### Implementation Checklist:

- [ ] **Canonicalize all file paths** using `realpath` or `readlink -f`
- [ ] **Validate file exists** after canonicalization
- [ ] **Validate file is regular file** (not directory, device, FIFO, socket)
- [ ] **Handle symlinks** by validating final target with existing `validate_file_type()`
- [ ] **Reject non-existent files** with user-friendly error message

### Code Template:

```bash
# Create in: scripts/components/orchestration/workspace_security.sh

validate_single_file_input() {
  local user_path="$1"
  local canonical_path
  
  # Check for null bytes
  if [[ "$user_path" == *$'\0'* ]]; then
    log "ERROR" "SECURITY" "File path contains null byte"
    return 1
  fi
  
  # Canonicalize path (resolves .., symlinks, etc.)
  canonical_path=$(realpath "$user_path" 2>/dev/null) || {
    log "ERROR" "Cannot resolve file path (file may not exist)"
    return 1
  }
  
  # Validate file type using existing function
  if ! validate_file_type "$canonical_path"; then
    return 1
  fi
  
  # Output canonical path on success
  echo "$canonical_path"
  return 0
}
```

### Test Coverage:

✅ Test paths:
- `../../../etc/passwd` - MUST handle safely
- `/absolute/path/to/file` - MUST validate
- `./relative/path/../file` - MUST canonicalize
- Non-existent file - MUST reject with clear error
- File with spaces in name - MUST handle correctly

---

## 2. Input Sanitization [REQUIRED] - CRITICAL

**Requirement**: SEC-0051-002  
**CWE**: CWE-78 (Command Injection)  
**Priority**: CRITICAL

### Implementation Checklist:

- [ ] **Always quote variables** in Bash code: `"$file_path"` not `$file_path`
- [ ] **Reject null bytes** in file paths
- [ ] **Validate argument exists** before use: `[[ -z "${file_path:-}" ]]`
- [ ] **Never use `eval`** with user input
- [ ] **Never use unquoted command substitution** with user input

### Code Rules:

```bash
# ✅ CORRECT:
if [[ -f "$file_path" ]]; then
  canonical_path=$(realpath "$file_path")
  process_file "$canonical_path"
fi

# ❌ WRONG:
if [[ -f $file_path ]]; then          # Unquoted
  eval "process $file_path"           # Extremely dangerous
fi
```

### Test Coverage:

✅ Test inputs:
- File path with spaces: `"file with spaces.txt"`
- File path with quotes: `"file'with\"quotes.txt"`
- File path with `$()`: Should not execute
- File path with semicolons: Should not split
- File path with null byte: Must reject

---

## 3. File Type Validation [REQUIRED] - HIGH

**Requirement**: SEC-0051-004  
**CWE**: CWE-434 (Dangerous File Type), CWE-67 (Improper Handling of Device Files)  
**Priority**: HIGH

### Implementation Checklist:

- [ ] **Call existing `validate_file_type()`** from `workspace_security.sh`
- [ ] **Reject character devices** (`/dev/tty`, `/dev/random`)
- [ ] **Reject block devices** (`/dev/sda`)
- [ ] **Reject named pipes** (FIFOs)
- [ ] **Reject sockets** (Unix domain sockets)
- [ ] **Reject directories** (must use `-d` flag for directories)
- [ ] **Enforce file size limits** (MAX_FILE_SIZE = 100MB default)
- [ ] **Handle empty files** gracefully (0 bytes is valid)

### Code Integration:

```bash
# After path validation:
if ! validate_file_type "$canonical_path"; then
  log "ERROR" "SECURITY" "Invalid file type for single-file analysis"
  exit 1
fi
```

### Test Coverage (from test suite):

✅ Tests 7, 22-26:
- Regular files (.txt, .md, .json, .sh) - MUST accept
- Directory path - MUST reject (test 7)
- Empty file - MUST accept (test 22)
- Large file (>100MB) - MUST handle per policy
- Device files - MUST reject

---

## 4. Plugin Execution Security [REQUIRED] - HIGH

**Requirement**: SEC-0051-005  
**CWE**: CWE-426 (Untrusted Search Path)  
**Priority**: HIGH

### Implementation Checklist:

- [ ] **Reuse existing plugin_executor.sh** - do NOT create new execution path
- [ ] **Pass only canonical paths** to plugins
- [ ] **Apply resource limits** (timeouts, ulimits)
- [ ] **Validate plugin outputs** (JSON schema)
- [ ] **Isolate plugin failures** (one plugin failure doesn't crash application)
- [ ] **Respect plugin active/inactive state** (existing behavior)

### Code Integration:

```bash
# Use existing plugin execution:
execute_plugin_on_file "$plugin_name" "$canonical_path" "$mime_type" "$workspace_dir"

# NOT this:
# execute_plugin "$plugin_name" "$user_input"  # DANGEROUS
```

### Test Coverage (from test suite):

✅ Tests 13-21:
- Active plugins execute on single file (test 13)
- Inactive plugins DO NOT execute (test 14)
- Plugin respects file type filters (test 15)
- --activate-plugin flag works (test 19)
- --deactivate-plugin flag works (test 20)

---

## 5. Workspace Integration [REQUIRED] - MEDIUM

**Requirement**: SEC-0051-006  
**Priority**: MEDIUM

### Implementation Checklist:

- [ ] **Create workspace structure** for single-file analysis
- [ ] **Call `verify_workspace_integrity()`** before analysis
- [ ] **Enforce workspace isolation** (no writes outside workspace)
- [ ] **Do NOT scan sibling files** (only analyze specified file)
- [ ] **Support multiple files to same workspace** (incremental analysis)

### Code Integration:

```bash
# Initialize workspace
initialize_workspace "$workspace_dir" || return 1

# Verify workspace security
verify_workspace_integrity "$workspace_dir" || return 1

# Process only the single file (not siblings)
process_single_file "$canonical_path" "$workspace_dir"
```

### Test Coverage (from test suite):

✅ Tests 27-30:
- Single-file mode does NOT scan siblings (test 27)
- Workspace structure created (test 28)
- Re-analysis uses cached workspace (test 29)
- Multiple files to same workspace (test 30)

---

## 6. Error Message Sanitization [RECOMMENDED] - MEDIUM

**Requirement**: SEC-0051-003  
**CWE**: CWE-209 (Information Exposure Through Error Messages)  
**Priority**: MEDIUM

### Implementation Checklist:

- [ ] **Use generic errors** for user-facing output
- [ ] **Log detailed errors securely** (to file or debug stream)
- [ ] **Do NOT reveal full system paths** in error messages
- [ ] **Do NOT reveal file existence** for unauthorized files

### Code Template:

```bash
# User-facing error (generic):
log "ERROR" "File cannot be accessed"

# Secure log (detailed):
log "ERROR" "SECURITY" "File validation failed: $canonical_path"
```

### Test Coverage:

✅ Error scenarios:
- Non-existent file - Generic error message
- Permission denied - Generic error message  
- Special file rejected - Generic error message
- Path traversal attempt - Generic error message

---

## Implementation Order

### Phase 1: Core Validation (CRITICAL)
1. Implement `validate_single_file_input()` in `workspace_security.sh`
2. Add `-f` flag parsing in `argument_parser.sh`
3. Run basic validation tests

### Phase 2: Orchestration (HIGH)
4. Create `orchestrate_single_file_analysis()` in `main_orchestrator.sh`
5. Integrate with `doc.doc.sh` main workflow
6. Implement MIME type detection for single file

### Phase 3: Plugin Integration (HIGH)
7. Adapt plugin execution for single-file mode
8. Test plugin filtering by MIME type
9. Test plugin active/inactive state

### Phase 4: Workspace & Testing (MEDIUM)
10. Implement workspace creation for single-file mode
11. Run full security test suite (`test_single_file_analysis.sh`)
12. Fix any failing tests
13. Run ShellCheck on all modified files

---

## Pre-Merge Security Checklist

Before merging Feature 0051, verify:

- [ ] ✅ All 5 REQUIRED security controls implemented
- [ ] ✅ No unquoted variables in new code
- [ ] ✅ ShellCheck passes with no warnings
- [ ] ✅ All 30 tests in `test_single_file_analysis.sh` pass
- [ ] ✅ Security test scenarios pass:
  - Path traversal attempts blocked
  - Symlink attacks prevented
  - Special files rejected
  - Command injection prevented
  - Error messages sanitized
- [ ] ✅ Code review completed
- [ ] ✅ No regression in existing tests

---

## Key Functions to Implement

### 1. `validate_single_file_input()` 
**Location**: `scripts/components/orchestration/workspace_security.sh`  
**Purpose**: Validate and canonicalize user-provided file path  
**Returns**: Canonical path on stdout, exit code 0 on success

### 2. `orchestrate_single_file_analysis()`
**Location**: `scripts/components/orchestration/main_orchestrator.sh`  
**Purpose**: Orchestrate plugin execution for single file  
**Arguments**: `$1=file_path, $2=workspace_dir, $3=plugins_dir`

### 3. Argument Parser Addition
**Location**: `scripts/components/ui/argument_parser.sh`  
**Add**: `-f|--file` flag handling with argument validation

### 4. Main Entry Point Logic
**Location**: `scripts/doc.doc.sh`  
**Add**: Conditional logic to call single-file orchestrator

---

## Testing Commands

```bash
# Run security test suite:
./tests/unit/test_single_file_analysis.sh

# Run ShellCheck on modified files:
shellcheck scripts/doc.doc.sh
shellcheck scripts/components/ui/argument_parser.sh
shellcheck scripts/components/orchestration/workspace_security.sh
shellcheck scripts/components/orchestration/main_orchestrator.sh

# Manual security tests:
# Path traversal
./scripts/doc.doc.sh -f "../../../etc/passwd" -w /tmp/workspace

# Symlink attack
ln -s /etc/passwd /tmp/test_symlink
./scripts/doc.doc.sh -f /tmp/test_symlink -w /tmp/workspace

# Special file
./scripts/doc.doc.sh -f /dev/null -w /tmp/workspace

# Command injection
./scripts/doc.doc.sh -f '$(whoami)' -w /tmp/workspace
```

---

## Questions or Clarifications?

If you need clarification on any security requirement:
1. Refer to full security review: `01_vision/04_security/02_scopes/08_single_file_analysis_security_review.md`
2. Existing security functions: `scripts/components/orchestration/workspace_security.sh`
3. Runtime security scope: `01_vision/04_security/02_scopes/02_runtime_application_security.md`

**Security Review Agent**: Available for re-review after implementation.

---

## Sign-Off

**Security Review**: ✅ **APPROVED WITH CONDITIONS**  
**Implementation**: Ready to begin  
**Re-Review Required**: Yes, after implementation before merge

**Date**: 2026-02-14  
**Reviewer**: Security Review Agent
