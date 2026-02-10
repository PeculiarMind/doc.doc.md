# File Scanner Security

## Overview
This document defines security requirements and controls for the directory scanner component, which recursively discovers and catalogs files for analysis.

## Security Requirements

### SR-FS-001: Symlink Path Traversal Prevention
**Status**: HIGH PRIORITY - REQUIRED  
**Vulnerability**: CWE-59 (Improper Link Resolution Before File Access)

The scanner MUST prevent symlink-based path traversal attacks that could expose files outside the intended scan directory.

**Requirements**:
1. Scanner MUST detect symbolic links before processing
2. Scanner MUST either:
   - **Option A** (Recommended): Reject all symlinks with warning log
   - **Option B**: Validate symlink targets remain within source directory bounds
3. Scanner MUST use canonical path resolution to verify boundaries
4. Scanner MUST NOT follow symlinks pointing to:
   - Files outside source directory tree
   - System files (`/etc/passwd`, `/etc/shadow`, etc.)
   - User home directories (unless explicitly within scan path)
   - Privileged locations (`/root`, `/sys`, `/proc`, `/dev`)

**Implementation**:
```bash
# Detect symlinks before processing
if [[ -L "$filepath" ]]; then
  log "WARN" "SCANNER" "Skipping symlink: $filepath"
  continue
fi

# Alternative: Validate symlink targets
if [[ -L "$filepath" ]]; then
  local target
  target=$(readlink -f "$filepath")
  local canonical_source
  canonical_source=$(readlink -f "$source_dir")
  
  if [[ "$target" != "$canonical_source"* ]]; then
    log "WARN" "SCANNER" "Rejecting symlink outside source: $filepath -> $target"
    continue
  fi
fi
```

---

### SR-FS-002: Path Boundary Validation
**Status**: HIGH PRIORITY - REQUIRED  
**Vulnerability**: CWE-22 (Improper Limitation of a Pathname to a Restricted Directory)

The scanner MUST validate all resolved file paths remain within the source directory boundary.

**Requirements**:
1. Scanner MUST resolve paths to canonical form using `readlink -f`
2. Scanner MUST compare canonical file path against canonical source directory
3. Scanner MUST reject files with resolved paths outside boundary
4. Scanner MUST validate paths even when not following symlinks
5. Scanner MUST handle `../` patterns in filenames safely

**Implementation**:
```bash
# Resolve canonical paths
local canonical_source
canonical_source=$(readlink -f "$source_dir")

local canonical_file
canonical_file=$(readlink -f "$filepath")

# Verify boundary
if [[ "$canonical_file" != "$canonical_source"* ]]; then
  log "WARN" "SCANNER" "File outside source directory: $filepath"
  files_skipped=$((files_skipped + 1))
  continue
fi
```

---

### SR-FS-003: TOCTOU Race Condition Mitigation
**Status**: MEDIUM PRIORITY - DOCUMENTED RISK  
**Vulnerability**: CWE-367 (Time-of-check Time-of-use Race Condition)

The scanner performs validation at scan time, but files are accessed later. An attacker could replace files between validation and use.

**Current Status**: Known limitation, documented risk

**Attack Scenarios**:
1. Replace small file with huge file after size check → resource exhaustion
2. Replace regular file with symlink to sensitive file → data exposure
3. Replace text file with executable → type confusion

**Short-term Mitigation**:
1. Document TOCTOU risk in user documentation
2. Advise users to scan trusted directories only
3. Recommend read-only source directories during scan
4. Warn against scanning attacker-controlled filesystems

**Long-term Mitigation** (v2.0):
1. Open files and validate via file descriptors
2. Pass file descriptors to downstream components (not paths)
3. Implement inode/device tracking to detect file replacement
4. Add filesystem monitoring for changes during processing

**User Guidance**:
```
WARNING: Files can be modified between scan and processing. 
Ensure source directory is:
- Read-only during analysis
- Not accessible to untrusted users
- Not on attacker-controlled filesystem (e.g., NFS, FUSE)
```

---

### SR-FS-004: Resource Exhaustion Controls
**Status**: IMPLEMENTED  
**Vulnerability**: CWE-400 (Uncontrolled Resource Consumption)

The scanner MUST prevent resource exhaustion attacks through file size limits and scanning controls.

**Controls Implemented**:
1. ✅ Maximum file size limit (100MB default via `MAX_FILE_SIZE`)
2. ✅ Files exceeding limit are skipped with warning log
3. ✅ Special files (FIFO, devices, sockets) rejected to prevent blocking I/O

**Controls Recommended**:
1. ⚠️ Maximum directory depth limit (prevent deep recursion)
2. ⚠️ Maximum total file count limit (prevent memory exhaustion)
3. ⚠️ Timeout for overall scan operation
4. ⚠️ Memory usage monitoring and limits

**Configuration**:
```bash
# Environment variables for tuning
export MAX_FILE_SIZE=104857600        # 100MB
export MAX_SCAN_DEPTH=100             # Directory depth
export MAX_FILE_COUNT=100000          # Total files
export SCAN_TIMEOUT_SECONDS=3600      # 1 hour
```

---

### SR-FS-005: Information Disclosure Prevention
**Status**: LOW PRIORITY - IMPROVEMENT  
**Vulnerability**: CWE-209 (Generation of Error Message Containing Sensitive Information)

Error messages SHOULD minimize information disclosure about internal structure.

**Current Behavior**: Error messages include full absolute paths

**Recommendations**:
1. Use relative paths in user-facing messages (INFO, WARN, ERROR)
2. Reserve absolute paths for DEBUG level only
3. Sanitize paths in error outputs
4. Avoid leaking configuration values in errors

**Implementation**:
```bash
# Calculate relative path for user messages
local relative_path="${filepath#$source_dir/}"

# Use relative path in user-facing logs
log "WARN" "SCANNER" "Skipping file: $relative_path (size limit exceeded)"

# Absolute path only in DEBUG
log "DEBUG" "SCANNER" "Full path: $filepath"
```

---

### SR-FS-006: Command Injection Prevention
**Status**: IMPLEMENTED  
**Vulnerability**: CWE-78 (OS Command Injection)

The scanner MUST prevent command injection through filenames or arguments.

**Controls Implemented**:
1. ✅ Proper variable quoting throughout (`"$filepath"`, `"$source_dir"`)
2. ✅ Null-delimited find output (`find ... -print0`)
3. ✅ Safe read loop (`while IFS= read -r -d '' filepath`)
4. ✅ No use of `eval` or unquoted command substitution
5. ✅ No dynamic command construction from user input

**Test Cases**:
- Filenames with spaces: `"file with spaces.txt"` ✅
- Command substitution: `"$(whoami).txt"` ✅
- Backticks: `` "file`id`.txt" `` ✅
- Semicolons: `"file;rm -rf.txt"` ✅ (cannot create due to invalid char)

---

### SR-FS-007: Special File Handling
**Status**: IMPLEMENTED  
**Vulnerability**: CWE-67 (Improper Handling of Windows Device Names), file system attacks

The scanner MUST reject special file types that could cause blocking I/O or security issues.

**Controls Implemented**:
1. ✅ FIFO (named pipes) rejected - prevents blocking on read
2. ✅ Character devices rejected - prevents device access
3. ✅ Block devices rejected - prevents disk access
4. ✅ Unix sockets rejected - prevents IPC issues
5. ✅ Directory traversal handled by find, not explicit processing

**Detection Logic**:
```bash
if [[ -p "$filepath" ]] || [[ -c "$filepath" ]] || 
   [[ -b "$filepath" ]] || [[ -S "$filepath" ]]; then
  log "WARN" "SCANNER" "Skipping special file: $filepath"
  continue
fi
```

---

## Threat Model

### Threat T-FS-001: Malicious Symlink Attack
**Attacker**: Local user with write access to scan directory  
**Goal**: Read sensitive files outside scan directory  
**Method**: Create symlink to `/etc/shadow` or private keys  
**Impact**: HIGH - Credential exposure, privacy violation  
**Mitigation**: SR-FS-001 (Symlink Prevention)

### Threat T-FS-002: Path Traversal via Crafted Names
**Attacker**: User creating files in scan directory  
**Goal**: Escape directory boundaries  
**Method**: Create files with `../../../` in names  
**Impact**: HIGH - Directory traversal, unauthorized access  
**Mitigation**: SR-FS-002 (Path Boundary Validation)

### Threat T-FS-003: File Replacement Attack (TOCTOU)
**Attacker**: Process with write access during scan  
**Goal**: Bypass validation checks  
**Method**: Replace file after validation, before processing  
**Impact**: MEDIUM - Resource exhaustion, unexpected behavior  
**Mitigation**: SR-FS-003 (TOCTOU Documentation)

### Threat T-FS-004: Resource Exhaustion
**Attacker**: Any user providing scan directory  
**Goal**: Denial of service through resource consumption  
**Method**: Provide directory with huge files or deep nesting  
**Impact**: MEDIUM - Scanner hangs, memory exhaustion  
**Mitigation**: SR-FS-004 (Resource Limits)

### Threat T-FS-005: Information Gathering
**Attacker**: User reviewing error logs  
**Goal**: Learn about system structure  
**Method**: Analyze error messages for path information  
**Impact**: LOW - Reconnaissance aid  
**Mitigation**: SR-FS-005 (Message Sanitization)

---

## Trust Boundaries

### Boundary B-FS-001: Filesystem Trust Boundary
**Trusted**: Files within validated source directory  
**Untrusted**: Symlink targets, external filesystems, user-provided paths

**Controls**:
- Path validation before processing
- Symlink rejection or validation
- Canonical path resolution

### Boundary B-FS-002: Time-based Trust Boundary
**Trusted**: File state at validation time  
**Untrusted**: File state at processing time

**Controls**:
- Document TOCTOU limitations
- Recommend read-only source during scan
- Future: File descriptor-based processing

---

## Security Testing Requirements

### Required Security Tests

1. **Test: Symlink Path Traversal**
   - Create symlink to `/etc/passwd`
   - Verify scanner rejects or validates target
   - Confirm no sensitive data in output

2. **Test: Path Boundary Validation**
   - Create file with `../` in name
   - Create symlink to parent directory
   - Verify all paths remain in source directory

3. **Test: Command Injection**
   - Create files with special characters: `$()`, `` ` ``, `;`, `|`
   - Verify no command execution occurs
   - Confirm safe processing

4. **Test: Resource Exhaustion**
   - Create file exceeding MAX_FILE_SIZE
   - Create deeply nested directories (>100 levels)
   - Verify graceful handling

5. **Test: Special File Handling**
   - Create FIFO, verify rejection
   - Create device files (if possible), verify rejection
   - Confirm scanner doesn't block

6. **Test: TOCTOU Scenario**
   - Start scan of directory
   - Replace file during scan
   - Document behavior (expected failure for now)

---

## Compliance Mapping

### OWASP Top 10 2021
- **A01: Broken Access Control** → SR-FS-001, SR-FS-002
- **A03: Injection** → SR-FS-006
- **A04: Insecure Design** → SR-FS-003, SR-FS-005
- **A05: Security Misconfiguration** → SR-FS-004, SR-FS-007

### CWE Coverage
- **CWE-22**: Path Traversal → SR-FS-002
- **CWE-59**: Improper Link Resolution → SR-FS-001
- **CWE-78**: OS Command Injection → SR-FS-006
- **CWE-209**: Information Disclosure → SR-FS-005
- **CWE-367**: TOCTOU → SR-FS-003
- **CWE-400**: Resource Exhaustion → SR-FS-004

---

## Version History

- **2026-02-10**: Initial security concept for Feature 0006 (Directory Scanner)
  - Identified HIGH severity issues: Symlink traversal, path boundary validation
  - Documented TOCTOU as known limitation
  - Verified command injection protections
  - Defined resource exhaustion controls
