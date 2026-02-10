# Security Review Report: Directory Scanner (Feature 6)

**To**: Developer Agent  
**From**: Security Review Agent  
**Date**: 2026-02-10  
**Subject**: Security Assessment - Feature 0006 (Directory Scanner)  
**Branch**: copilot/test-dev-cycle

---

## Executive Summary

⚠️ **APPROVED WITH CONDITIONS**

The Directory Scanner implementation has **2 HIGH severity vulnerabilities** and **1 MEDIUM severity issue** that must be addressed before production deployment. The implementation demonstrates good security practices in several areas (file size limits, special file rejection, safe command handling), but has critical gaps in symlink handling and path validation.

**Severity Breakdown:**
- **CRITICAL**: 0
- **HIGH**: 2 (Symlink Exploitation, Insufficient Input Validation)  
- **MEDIUM**: 1 (TOCTOU Race Condition)
- **LOW**: 2 (Information Disclosure, Missing Depth Limit)

---

## Vulnerability Findings

### HIGH-001: Symlink Path Traversal Attack
**Severity**: HIGH  
**CWE**: CWE-59 (Improper Link Resolution Before File Access)  
**OWASP**: A01:2021 - Broken Access Control

**Description:**
The scanner treats symlinks as regular files using `[[ -f "$filepath" ]]` (line 162), which follows symlinks. This allows an attacker to create symlinks pointing to sensitive files outside the scan directory (e.g., `/etc/passwd`, `/etc/shadow`, private keys), causing the scanner to process and potentially expose these files.

**Evidence:**
```bash
# Test demonstrates vulnerability
$ ln -s /etc/passwd /tmp/test_dir/malicious_link
$ scan_directory "/tmp/test_dir"
# Output includes: /tmp/test_dir/malicious_link|text/plain|...
# Scanner processes /etc/passwd content via symlink
```

**Attack Scenario:**
1. Attacker creates symlink to `/home/victim/.ssh/id_rsa`
2. Scanner processes symlink as regular file
3. Document generation includes private key content
4. Attacker gains sensitive information from generated report

**Current Code (lines 162-166):**
```bash
# Validate file is a regular file (not symlink to special file, etc.)
if [[ ! -f "$filepath" ]]; then
  log "DEBUG" "SCANNER" "Skipping non-regular file: $filepath"
  files_skipped=$((files_skipped + 1))
  continue
fi
```

**Impact**: 
- Arbitrary file read outside scan directory
- Potential exposure of secrets, credentials, private keys
- Privacy violation through unauthorized data access

**Recommendation**:
Add explicit symlink detection and validation:

```bash
# Check if file is a symlink
if [[ -L "$filepath" ]]; then
  log "WARN" "SCANNER" "Skipping symlink: $filepath"
  files_skipped=$((files_skipped + 1))
  continue
fi

# Alternatively, validate symlink target if following is desired
if [[ -L "$filepath" ]]; then
  local target
  target=$(readlink -f "$filepath")
  
  # Verify target is within source directory bounds
  if [[ "$target" != "$source_dir"* ]]; then
    log "WARN" "SCANNER" "Rejecting symlink pointing outside source directory: $filepath -> $target"
    files_skipped=$((files_skipped + 1))
    continue
  fi
fi
```

**Required Action**: MUST FIX before production deployment

---

### HIGH-002: Missing Path Boundary Validation
**Severity**: HIGH  
**CWE**: CWE-22 (Improper Limitation of a Pathname to a Restricted Directory)  
**OWASP**: A01:2021 - Broken Access Control

**Description:**
The scanner lacks explicit validation that resolved file paths remain within the source directory boundary. While `find` naturally restricts traversal, the code doesn't validate symlink targets or canonical paths, creating a security gap.

**Current Code:**
The implementation relies on `find` behavior but doesn't explicitly validate path boundaries:
```bash
done < <(find "$source_dir" -print0 2>/dev/null)
```

**Gaps:**
1. No validation that `readlink -f` resolved paths stay within bounds
2. No rejection of `../` patterns in filenames
3. No canonical path comparison against source directory

**Attack Vector:**
Combined with symlink following (HIGH-001), an attacker could:
1. Create symlink named `../../../../etc/shadow`
2. Scanner follows and processes sensitive file
3. No boundary check prevents this

**Recommendation**:
Add explicit boundary validation after path resolution:

```bash
# Get canonical paths for comparison
local canonical_source
canonical_source=$(readlink -f "$source_dir")

# For each file discovered
local canonical_file
canonical_file=$(readlink -f "$filepath")

# Verify file is within source directory
if [[ "$canonical_file" != "$canonical_source"* ]]; then
  log "WARN" "SCANNER" "Rejecting file outside source directory: $filepath"
  files_skipped=$((files_skipped + 1))
  continue
fi
```

**Required Action**: MUST FIX before production deployment

---

### MEDIUM-001: TOCTOU Race Condition
**Severity**: MEDIUM  
**CWE**: CWE-367 (Time-of-check Time-of-use Race Condition)  
**OWASP**: Not directly mapped, security misconfiguration

**Description:**
The scanner performs file validation checks (type, size, permissions) at discovery time (lines 169-193), but downstream components access files later. An attacker could replace a legitimate file with a malicious one between scan and processing.

**Vulnerable Sequence:**
```bash
# Time T1: Scanner validates file
file_size=$(stat -c '%s' "$filepath" 2>/dev/null)  # 100 bytes, OK
if [[ "$file_size" -gt "$MAX_FILE_SIZE" ]]; then ...

# Time T2: Attacker replaces file
# $ rm file.txt && dd if=/dev/zero of=file.txt bs=1G count=10

# Time T3: Downstream component reads file (now 10GB!)
```

**Impact**:
- Resource exhaustion bypass (file size limits)
- Symlink swap attack (regular file → symlink to `/etc/passwd`)
- Type confusion (text file → binary executable)

**Current Mitigation**: 
None. Scanner doesn't use atomic operations or file locking.

**Recommendation**:
1. **Short-term**: Document TOCTOU risk in security concept, advise users to scan trusted directories only
2. **Long-term**: Implement file descriptor-based processing:
   ```bash
   # Open file and validate via file descriptor
   exec {fd}< "$filepath"
   fstat "$fd"  # Validate on open FD
   # Pass FD to downstream, not filepath
   ```
3. Add inode/device tracking to detect file replacement:
   ```bash
   local inode_at_scan
   inode_at_scan=$(stat -c '%i' "$filepath")
   # Store in metadata, verify before processing
   ```

**Required Action**: Document risk, consider mitigation for v2.0

---

### LOW-001: Information Disclosure in Error Messages
**Severity**: LOW  
**CWE**: CWE-209 (Generation of Error Message Containing Sensitive Information)  
**OWASP**: A04:2021 - Insecure Design

**Description:**
Error messages include full file paths, which may reveal directory structure and file naming conventions to potential attackers reviewing logs or error output.

**Examples:**
```bash
log "ERROR" "SCANNER" "Source directory does not exist: $source_dir"
log "WARN" "SCANNER" "Could not determine file size, skipping: $filepath"
log "WARN" "SCANNER" "Skipping file exceeding size limit ($MAX_FILE_SIZE bytes): $filepath ($file_size bytes)"
```

**Information Leaked:**
- Internal directory structure
- File naming conventions
- Configuration details (MAX_FILE_SIZE value)
- System paths

**Impact**: Low - primarily assists reconnaissance phase of attacks

**Recommendation**:
1. Use relative paths in user-facing messages
2. Reserve absolute paths for DEBUG level only
3. Sanitize paths in ERROR/WARN messages:
   ```bash
   local relative_path="${filepath#$source_dir/}"
   log "WARN" "SCANNER" "Skipping file exceeding size limit: $relative_path"
   ```

**Required Action**: Optional improvement for v2.0

---

### LOW-002: Missing Recursion Depth Limit
**Severity**: LOW  
**CWE**: CWE-674 (Uncontrolled Recursion)  
**OWASP**: A05:2021 - Security Misconfiguration

**Description:**
The scanner uses `find` without depth limiting, potentially causing performance degradation or denial of service with deeply nested directory structures.

**Attack Scenario:**
```bash
# Create 10,000 levels of nested directories
mkdir -p $(python -c "print('a/' * 10000)")
# Scanner hangs or crashes traversing structure
```

**Current Implementation:**
```bash
find "$source_dir" -print0 2>/dev/null
# No -maxdepth parameter
```

**Impact**: 
- DoS through resource exhaustion
- Stack overflow in extreme cases
- Unresponsive scanner behavior

**Recommendation**:
Add configurable depth limit:
```bash
local max_depth="${MAX_SCAN_DEPTH:-100}"
find "$source_dir" -maxdepth "$max_depth" -print0 2>/dev/null
```

**Required Action**: Optional improvement, document in security concept

---

## Security Controls Verified ✓

### 1. File Size Limiting (req_0055)
**Status**: ✅ IMPLEMENTED CORRECTLY

Lines 178-183 enforce MAX_FILE_SIZE limit (100MB default):
```bash
if [[ "$file_size" -gt "$MAX_FILE_SIZE" ]]; then
  log "WARN" "SCANNER" "Skipping file exceeding size limit..."
  files_skipped=$((files_skipped + 1))
  continue
fi
```

**Test Result**: Confirmed with 200MB file - correctly rejected.

### 2. Special File Rejection
**Status**: ✅ IMPLEMENTED CORRECTLY

Lines 154-159 reject FIFO, character devices, block devices, sockets:
```bash
if [[ -p "$filepath" ]] || [[ -c "$filepath" ]] || [[ -b "$filepath" ]] || [[ -S "$filepath" ]]; then
  log "WARN" "SCANNER" "Skipping special file: $filepath"
  files_skipped=$((files_skipped + 1))
  continue
fi
```

**Test Result**: FIFO correctly rejected.

### 3. Command Injection Protection
**Status**: ✅ IMPLEMENTED CORRECTLY

Proper quoting throughout implementation prevents command injection:
```bash
file_size=$(stat -c '%s' "$filepath" 2>/dev/null)  # Quoted variable
find "$source_dir" -print0  # Null-delimited for special characters
while IFS= read -r -d '' filepath; do  # Safe parsing
```

**Test Result**: Files with names like `$(whoami).txt`, `` file`id`.txt `` handled safely without command execution.

### 4. Input Validation
**Status**: ✅ IMPLEMENTED CORRECTLY

Lines 105-114 validate source directory argument:
```bash
if [[ -z "$source_dir" ]]; then
  log "ERROR" "SCANNER" "Source directory argument is required"
  return 1
fi

if [[ ! -d "$source_dir" ]]; then
  log "ERROR" "SCANNER" "Source directory does not exist: $source_dir"
  return 1
fi
```

### 5. Error Handling
**Status**: ✅ IMPLEMENTED CORRECTLY

Graceful degradation for stat failures (lines 169-176, 186-193):
```bash
if [[ -z "$file_size" ]]; then
  log "WARN" "SCANNER" "Could not determine file size, skipping: $filepath"
  files_skipped=$((files_skipped + 1))
  continue
fi
```

Scanner continues processing despite individual file errors.

---

## OWASP Top 10 Analysis

### A01:2021 - Broken Access Control
- ❌ **VULNERABLE**: Symlink path traversal (HIGH-001)
- ❌ **VULNERABLE**: Missing path boundary validation (HIGH-002)
- ⚠️ **PARTIAL**: No privilege checking, assumes user permissions

### A02:2021 - Cryptographic Failures
- ✅ **NOT APPLICABLE**: No cryptography in scanner

### A03:2021 - Injection
- ✅ **PROTECTED**: Command injection prevented via proper quoting
- ✅ **PROTECTED**: Null-delimited find prevents filename injection

### A04:2021 - Insecure Design
- ⚠️ **CONCERN**: TOCTOU race condition (MEDIUM-001)
- ⚠️ **CONCERN**: Information disclosure in errors (LOW-001)

### A05:2021 - Security Misconfiguration
- ⚠️ **CONCERN**: No recursion depth limit (LOW-002)
- ✅ **GOOD**: Configurable size limits via environment variables

### A06:2021 - Vulnerable Components
- ✅ **NOT APPLICABLE**: Uses standard Unix utilities

### A07:2021 - Authentication Failures
- ✅ **NOT APPLICABLE**: No authentication in scanner

### A08:2021 - Software and Data Integrity
- ⚠️ **CONCERN**: TOCTOU allows file replacement (MEDIUM-001)

### A09:2021 - Logging Failures
- ✅ **GOOD**: Comprehensive logging of security events
- ⚠️ **CONCERN**: Logs include sensitive paths (LOW-001)

### A10:2021 - SSRF
- ✅ **NOT APPLICABLE**: No network operations

---

## CWE Pattern Analysis

### CWE-22: Path Traversal
**Status**: ❌ VULNERABLE (HIGH-002)

### CWE-59: Improper Link Resolution
**Status**: ❌ VULNERABLE (HIGH-001)

### CWE-78: OS Command Injection
**Status**: ✅ PROTECTED

### CWE-209: Information Disclosure
**Status**: ⚠️ MINOR ISSUE (LOW-001)

### CWE-367: TOCTOU
**Status**: ⚠️ VULNERABLE (MEDIUM-001)

### CWE-400: Resource Exhaustion
**Status**: ✅ PARTIALLY PROTECTED (size limits implemented)

### CWE-674: Uncontrolled Recursion
**Status**: ⚠️ MINOR ISSUE (LOW-002)

---

## Test Coverage Assessment

### Security Tests Present ✓
1. ✅ Command injection prevention (line 530-539)
2. ✅ Special character handling (line 520-528)
3. ✅ File size enforcement (line 276-288)
4. ✅ Special file rejection (line 240-251, 252-263)
5. ✅ Permission handling (line 396-409, 426-442)

### Security Tests Missing ❌
1. ❌ **Symlink path traversal** - No test validates symlink rejection
2. ❌ **Path boundary validation** - No test for canonical path checks
3. ❌ **TOCTOU scenarios** - No test for file replacement between scan and use
4. ❌ **Circular symlink handling** - Test exists but marked TODO (line 262)
5. ❌ **Recursion depth limit** - No test for deeply nested structures

---

## Recommendations Summary

### Must Fix (Blocking)
1. **HIGH-001**: Add symlink detection and rejection/validation
2. **HIGH-002**: Implement path boundary validation with canonical paths

### Should Fix (Before Production)
3. **MEDIUM-001**: Document TOCTOU risks, consider FD-based processing
4. Add comprehensive symlink security tests
5. Add path traversal security tests

### Nice to Have (Future)
6. **LOW-001**: Sanitize error messages to use relative paths
7. **LOW-002**: Add configurable recursion depth limit
8. Implement inode tracking to detect file modifications
9. Add security-focused integration tests

---

## Security Concept Updates Required

The following updates are needed in `01_vision/04_security/`:

### 1. Document Symlink Policy
Create `symlink_handling_policy.md`:
- Define whether symlinks are followed, rejected, or validated
- Document boundary checking requirements
- Specify user notifications for rejected symlinks

### 2. Document TOCTOU Risks
Update threat model to include:
- TOCTOU attack scenarios
- Mitigation strategies
- User guidance (scan trusted directories)

### 3. Document Resource Limits
Update `resource_exhaustion_controls.md`:
- Document MAX_FILE_SIZE enforcement
- Add recursion depth recommendations
- Define memory/time limits for scanning

### 4. Document Error Handling Security
Create `information_disclosure_controls.md`:
- Define what information can be logged at each level
- Specify path sanitization requirements
- Define sensitive data masking rules

---

## Approval Decision

### Status: ⚠️ **APPROVED WITH CONDITIONS**

**Conditions for Production Deployment:**
1. ✅ **Required**: Fix HIGH-001 (Symlink Path Traversal)
2. ✅ **Required**: Fix HIGH-002 (Path Boundary Validation)
3. ✅ **Required**: Add security tests for symlink and path traversal scenarios
4. ⚠️ **Recommended**: Document TOCTOU risks in security concept
5. ⚠️ **Recommended**: Sanitize error messages (relative paths)

**Development/Testing Status**: ✅ APPROVED FOR MERGE
- Current implementation is safe for development/testing in controlled environments
- Security issues do not block feature branch merging
- Issues MUST be addressed before production release

**Confidence Level**: HIGH
- Vulnerabilities clearly identified with reproduction steps
- Mitigations specified with code examples
- Test coverage gaps documented

---

## Next Steps for Developer Agent

1. **Immediate** (Before production):
   - Implement symlink detection/rejection (HIGH-001)
   - Implement path boundary validation (HIGH-002)
   - Add security tests for symlinks and path traversal
   - Re-run security review after fixes

2. **Short-term** (v1.0 hardening):
   - Document TOCTOU risks in security concept
   - Add recursion depth limit configuration
   - Sanitize error messages for information disclosure

3. **Long-term** (v2.0):
   - Implement file descriptor-based processing
   - Add inode tracking for TOCTOU detection
   - Comprehensive security audit

---

**Security Review Agent Sign-off**: CONDITIONAL APPROVAL  
**Date**: 2026-02-10  
**Next Review Required**: After HIGH severity fixes implemented
