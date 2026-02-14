# Security Review: Feature 0002 - OCRmyPDF Plugin

**Review ID**: security_review_0002  
**Feature**: feature_0002_ocrmypdf_plugin  
**Reviewer**: Security Review Agent  
**Review Date**: 2026-02-13  
**Status**: ✅ **RESOLVED - ALL FIXES VERIFIED** (See security_re_review_feature_0002.md)  
**Re-Review Date**: 2026-02-13

---

## Executive Summary

The ocrmypdf plugin implementation has been reviewed for security vulnerabilities. The review identified **6 security issues** ranging from **MEDIUM to HIGH severity**. The implementation demonstrates good security practices in some areas (input validation, file type checking) but has critical vulnerabilities related to command injection, unsafe temporary file handling, and insufficient output sanitization.

**Overall Security Status**: ✅ **APPROVED** - All issues resolved (Verified: 2026-02-13)

**Risk Level**: **LOW** - All vulnerabilities have been successfully remediated

**Note**: This review identified 6 security issues. All have been fixed and verified. See `security_re_review_feature_0002.md` for final approval.

---

## Files Reviewed

1. `scripts/plugins/ubuntu/ocrmypdf/descriptor.json` - Plugin metadata
2. `scripts/plugins/ubuntu/ocrmypdf/install.sh` - Installation script
3. `scripts/plugins/ubuntu/ocrmypdf/ocrmypdf_wrapper.sh` - Main wrapper script

---

## Security Findings

### 🔴 CRITICAL FINDINGS

#### CRIT-001: Command Injection via Unquoted Variable in descriptor.json
**Severity**: HIGH  
**CWE**: CWE-78 (OS Command Injection)  
**File**: `scripts/plugins/ubuntu/ocrmypdf/descriptor.json`  
**Line**: 29  

**Issue**:
```json
"commandline": "/plugin/ocrmypdf_wrapper.sh '${file_path_absolute}'"
```

The command in the descriptor uses single quotes around `${file_path_absolute}`, which will prevent shell variable expansion. This will cause the literal string `${file_path_absolute}` to be passed instead of the actual file path.

**Impact**:
- Plugin will fail to execute correctly
- File path will not be substituted
- Breaks fundamental plugin functionality

**Evidence**:
Single quotes in bash prevent variable expansion. The shell will pass the literal string `'${file_path_absolute}'` to the wrapper script instead of expanding the variable.

**Remediation**:
Change single quotes to double quotes to enable variable expansion while maintaining injection protection:
```json
"commandline": "/plugin/ocrmypdf_wrapper.sh \"${file_path_absolute}\""
```

Or use the pattern without quotes if the execution environment handles quoting:
```json
"commandline": "/plugin/ocrmypdf_wrapper.sh ${file_path_absolute}"
```

**Priority**: CRITICAL - Must fix before deployment

---

#### CRIT-002: Unsafe Command Execution in ocrmypdf Invocation
**Severity**: MEDIUM-HIGH  
**CWE**: CWE-78 (OS Command Injection)  
**File**: `scripts/plugins/ubuntu/ocrmypdf/ocrmypdf_wrapper.sh`  
**Line**: 61  

**Issue**:
```bash
if ocrmypdf --force-ocr --sidecar "$TEXT_FILE" "$FILE_PATH" "$OUTPUT_PDF" >/dev/null 2>&1; then
```

While `$FILE_PATH`, `$TEXT_FILE`, and `$OUTPUT_PDF` are quoted (good practice), the ocrmypdf command is invoked directly. If an attacker can control the file path to include special characters or command sequences, there's potential for exploitation.

**Impact**:
- Potential command injection if file paths contain malicious content
- Risk amplified if FILE_PATH comes from untrusted sources
- Could lead to arbitrary code execution

**Evidence**:
Although quoting provides some protection, file paths with embedded newlines, null bytes, or other special characters could potentially bypass protections depending on how ocrmypdf handles arguments.

**Remediation**:
1. Add explicit path sanitization before ocrmypdf invocation:
```bash
# Sanitize file path - reject paths with suspicious characters
if [[ "$FILE_PATH" =~ [[:cntrl:]] ]]; then
    echo "0,failed,Error: Invalid characters in file path" >&2
    exit 1
fi
```

2. Use absolute path resolution:
```bash
FILE_PATH=$(realpath "$FILE_PATH" 2>/dev/null)
if [[ $? -ne 0 ]]; then
    echo "0,failed,Error: Could not resolve file path" >&2
    exit 1
fi
```

**Priority**: HIGH - Should fix before deployment

---

### 🟡 HIGH FINDINGS

#### HIGH-001: Insufficient Output Sanitization
**Severity**: HIGH  
**CWE**: CWE-116 (Improper Encoding or Escaping of Output)  
**File**: `scripts/plugins/ubuntu/ocrmypdf/ocrmypdf_wrapper.sh`  
**Line**: 67  

**Issue**:
```bash
OCR_TEXT=$(cat "$TEXT_FILE" | tr '\n' ' ' | tr -d ',' | sed 's/[[:space:]]\+/ /g' | xargs)
```

The sanitization only removes commas and normalizes whitespace. It does NOT sanitize:
- Shell metacharacters (`, $, `, \, etc.)
- Control characters (except newlines)
- Embedded commands or code
- Unicode exploits
- CSV injection payloads (=, +, -, @)

**Impact**:
- If OCR text is later used in shell commands → command injection
- If OCR text is written to CSV → CSV injection attacks
- If OCR text is displayed in terminal → terminal escape sequence injection
- Could lead to code execution in downstream processing

**Evidence**:
OCR text from PDFs is completely untrusted. Malicious PDFs could embed text designed to exploit downstream systems. Only removing commas is insufficient.

**Remediation**:
Implement comprehensive sanitization:
```bash
# Sanitize OCR output - remove dangerous characters
OCR_TEXT=$(cat "$TEXT_FILE" | \
    tr '\n' ' ' | \
    tr -d '\000-\037' | \  # Remove all control characters
    tr -d '`$\\|;&<>(){}[]!*?' | \  # Remove shell metacharacters
    tr -d ',' | \  # Remove commas for CSV
    sed 's/[[:space:]]\+/ /g' | \
    sed 's/^[=+\-@]//' | \  # Remove CSV injection prefixes
    xargs | \
    head -c 10000)  # Limit output size

# Additional validation
if [[ ! "$OCR_TEXT" =~ ^[[:print:][:space:]]*$ ]]; then
    OCR_TEXT="[OCR output contains invalid characters]"
fi
```

**Priority**: HIGH - Fix before deployment

---

#### HIGH-002: Race Condition in Temporary File Handling
**Severity**: MEDIUM-HIGH  
**CWE**: CWE-377 (Insecure Temporary File), CWE-367 (Time-of-check Time-of-use)  
**File**: `scripts/plugins/ubuntu/ocrmypdf/ocrmypdf_wrapper.sh`  
**Lines**: 51-56  

**Issue**:
```bash
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

OUTPUT_PDF="$TEMP_DIR/output.pdf"
TEXT_FILE="$TEMP_DIR/output.txt"
```

While `mktemp -d` creates a secure temporary directory, there's no verification that the directory was created successfully, and the trap may not execute in all failure scenarios (e.g., SIGKILL).

**Impact**:
- If mktemp fails silently, operations will fail with confusing errors
- Temporary files may be left behind if script is killed unexpectedly
- Potential information disclosure if temp files persist

**Evidence**:
The script doesn't check if `$TEMP_DIR` is empty or if mktemp succeeded. In failure scenarios, the trap may not clean up.

**Remediation**:
Add validation and more robust cleanup:
```bash
# Create temporary directory with validation
TEMP_DIR=$(mktemp -d) || {
    echo "0,failed,Error: Failed to create temporary directory" >&2
    exit 1
}

# Set restrictive permissions
chmod 700 "$TEMP_DIR"

# Ensure cleanup on multiple signal types
trap 'rm -rf "$TEMP_DIR" 2>/dev/null' EXIT INT TERM HUP

# Verify directory exists and is writable
if [[ ! -d "$TEMP_DIR" ]] || [[ ! -w "$TEMP_DIR" ]]; then
    echo "0,failed,Error: Temporary directory not usable" >&2
    exit 1
fi
```

**Priority**: MEDIUM - Should fix for robustness

---

### 🟢 MEDIUM FINDINGS

#### MED-001: Insufficient Error Message Sanitization
**Severity**: MEDIUM  
**CWE**: CWE-209 (Information Exposure Through Error Message)  
**File**: `scripts/plugins/ubuntu/ocrmypdf/ocrmypdf_wrapper.sh`  
**Lines**: 34, 40  

**Issue**:
```bash
echo "0,failed,Error: File not found: $FILE_PATH" >&2
```

Error messages include user-provided file paths directly. This could expose sensitive information about directory structure, user names, or system configuration.

**Impact**:
- Information disclosure about file system structure
- Potential exposure of sensitive paths
- Could aid attackers in system reconnaissance

**Remediation**:
Sanitize file paths in error messages:
```bash
# Show only filename, not full path
FILENAME=$(basename "$FILE_PATH" 2>/dev/null || echo "unknown")
echo "0,failed,Error: File not found: $FILENAME" >&2
```

Or use generic error messages:
```bash
echo "0,failed,Error: File not found or not accessible" >&2
```

**Priority**: MEDIUM - Consider fixing for defense in depth

---

#### MED-002: Missing Input Length Validation
**Severity**: MEDIUM  
**CWE**: CWE-400 (Uncontrolled Resource Consumption)  
**File**: `scripts/plugins/ubuntu/ocrmypdf/ocrmypdf_wrapper.sh`  
**Line**: 30  

**Issue**:
```bash
FILE_PATH="$1"
```

No validation on the length of the file path argument. Extremely long paths could cause resource exhaustion or buffer issues in downstream processing.

**Impact**:
- Potential denial of service via resource exhaustion
- Could trigger errors in ocrmypdf or file operations
- Log injection if path is logged

**Remediation**:
Add path length validation:
```bash
FILE_PATH="$1"

# Validate path length (PATH_MAX is typically 4096)
if [[ ${#FILE_PATH} -gt 4096 ]]; then
    echo "0,failed,Error: File path exceeds maximum length" >&2
    exit 1
fi

# Validate path doesn't contain null bytes or control characters
if [[ "$FILE_PATH" =~ [[:cntrl:]] ]]; then
    echo "0,failed,Error: File path contains invalid characters" >&2
    exit 1
fi
```

**Priority**: MEDIUM - Recommended for robustness

---

### ✅ POSITIVE SECURITY CONTROLS IDENTIFIED

The implementation includes several good security practices:

1. **Input Validation** (Line 25-28): Proper argument count validation
2. **File Existence Check** (Line 33-36): Validates file exists before processing
3. **File Type Validation** (Line 39-42): Uses `file` command to verify PDF MIME type
4. **Dependency Check** (Line 45-48): Verifies ocrmypdf is installed
5. **Proper Quoting** (throughout): Variables are generally quoted to prevent word splitting
6. **Error Handling**: Uses `set -euo pipefail` for strict error handling
7. **Temporary File Cleanup**: Uses trap for cleanup (though could be improved)
8. **No Privileged Operations**: Script doesn't require or use elevated privileges
9. **GPL License Headers**: Proper copyright and licensing information

---

## Compliance with Security Scope

**Reference**: `01_vision/04_security/02_scopes/03_plugin_execution_security.md`

### Compliance Status by Component

| Security Control | Status | Notes |
|------------------|--------|-------|
| Plugin Input Validation | ⚠️ **Partial** | Basic validation present but needs enhancement |
| Argument Quoting | ⚠️ **Partial** | Generally good but descriptor has quoting issue |
| Output Sanitization | ❌ **Non-Compliant** | Insufficient sanitization of OCR text |
| Dependency Validation | ✅ **Compliant** | Proper check_commandline usage |
| Execution Isolation | ✅ **Compliant** | No privilege escalation |
| Resource Limits | ❌ **Missing** | No timeout or size limits enforced |
| Error Handling | ✅ **Compliant** | Proper error handling present |
| Temporary File Security | ⚠️ **Partial** | Uses mktemp but needs validation |

---

## Threat Model (STRIDE Analysis)

### Spoofing
- **Risk**: Low - Plugin execution doesn't involve authentication
- **Control**: File type validation helps prevent processing non-PDF files

### Tampering
- **Risk**: Medium - Malicious PDFs could contain crafted OCR text
- **Control**: Output sanitization needed (currently insufficient)

### Repudiation
- **Risk**: Low - Plugin execution is logged by parent process
- **Control**: Adequate

### Information Disclosure
- **Risk**: Medium - Error messages expose file paths
- **Control**: Error message sanitization recommended

### Denial of Service
- **Risk**: Medium - No resource limits on OCR processing
- **Control**: Should add timeout and output size limits

### Elevation of Privilege
- **Risk**: Low - Script runs with user privileges only
- **Control**: Adequate - no sudo or privilege escalation

---

## Risk Assessment (DREAD)

| Finding | Damage | Reproducibility | Exploitability | Affected Users | Discoverability | **Score** |
|---------|---------|-----------------|----------------|----------------|-----------------|-----------|
| CRIT-001: Variable Expansion | 8 | 10 | 10 | 10 | 10 | **9.6** |
| CRIT-002: Command Injection | 9 | 7 | 6 | 10 | 8 | **8.0** |
| HIGH-001: Output Sanitization | 8 | 8 | 7 | 10 | 7 | **8.0** |
| HIGH-002: Temp File Race | 5 | 6 | 5 | 10 | 4 | **6.0** |
| MED-001: Error Disclosure | 4 | 10 | 3 | 10 | 9 | **7.2** |
| MED-002: Length Validation | 5 | 7 | 5 | 10 | 6 | **6.6** |

**Overall Risk Score**: **7.6 / 10** (HIGH)

---

## Mandatory Fixes Required

Before this feature can be approved for deployment, the following fixes are **MANDATORY**:

### Priority 1 (CRITICAL - Must Fix)
1. **CRIT-001**: Fix variable expansion in descriptor.json commandline
   - Change single quotes to double quotes or remove quotes
   - Test that file path is properly passed to wrapper script

### Priority 2 (HIGH - Should Fix)
2. **CRIT-002**: Add path sanitization and validation
   - Reject paths with control characters
   - Use realpath for path resolution
   
3. **HIGH-001**: Implement comprehensive output sanitization
   - Remove all control characters
   - Remove shell metacharacters
   - Add CSV injection protection
   - Limit output size
   
4. **HIGH-002**: Enhance temporary file handling
   - Add mktemp validation
   - Set restrictive permissions
   - Improve trap reliability

### Priority 3 (MEDIUM - Recommended)
5. **MED-001**: Sanitize error messages
6. **MED-002**: Add input length validation

---

## Testing Recommendations

After fixes are applied, perform the following security tests:

### Test 1: Command Injection
```bash
# Test with filenames containing special characters
touch '/tmp/test;whoami;.pdf'
# Verify: Plugin should reject or safely handle this file
```

### Test 2: Path Traversal
```bash
# Test with path traversal attempts
./ocrmypdf_wrapper.sh '../../../../../etc/passwd'
# Verify: Should reject non-PDF files and suspicious paths
```

### Test 3: Output Sanitization
```bash
# Create PDF with embedded shell commands in OCR text
# Verify: Output contains no shell metacharacters
```

### Test 4: Resource Exhaustion
```bash
# Test with extremely large PDF
# Verify: Plugin completes or times out gracefully
```

### Test 5: Malformed Inputs
```bash
# Test with null bytes, very long paths, special characters
# Verify: All inputs are rejected gracefully
```

---

## Recommendations for Future Enhancement

1. **Timeout Implementation**: Add execution timeout (e.g., 300 seconds)
2. **Output Size Limits**: Limit OCR text to reasonable size (e.g., 1MB)
3. **Sandboxing**: Consider running ocrmypdf in restricted environment
4. **Input Validation Library**: Develop shared validation functions for all plugins
5. **Security Testing**: Add automated security tests to CI/CD pipeline
6. **Logging**: Add security event logging for suspicious inputs
7. **Documentation**: Document security considerations in plugin README

---

## References

- **Plugin Execution Security Scope**: `01_vision/04_security/02_scopes/03_plugin_execution_security.md`
- **CWE-78**: OS Command Injection
- **CWE-116**: Improper Output Encoding
- **CWE-377**: Insecure Temporary File
- **OWASP Top 10**: A03:2021 – Injection

---

## Developer Handoff

**Status**: ⚠️ **RETURNED TO DEVELOPER FOR FIXES**

**Required Actions**:
1. Address all CRITICAL and HIGH severity findings
2. Implement recommended sanitization and validation
3. Add security-focused tests
4. Re-run security review after fixes applied
5. Update work item with fix implementation details

**Expected Timeline**: 
- Fixes: 2-4 hours
- Testing: 1-2 hours  
- Re-review: 1 hour

**Next Steps**:
1. Developer implements mandatory fixes
2. Developer runs security tests
3. Developer requests re-review
4. Security agent verifies fixes and approves or identifies remaining issues

---

**Security Review Agent**  
*Protecting doc.doc.md through proactive security analysis*  
Date: 2026-02-13
