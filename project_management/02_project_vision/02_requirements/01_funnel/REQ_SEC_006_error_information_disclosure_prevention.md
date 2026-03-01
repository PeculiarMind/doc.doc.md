# Requirement: Error Information Disclosure Prevention

- **ID:** REQ_SEC_006
- **Status:** FUNNEL
- **Created at:** 2026-02-25
- **Created by:** Security Agent
- **Source:** Security threat analysis (STRIDE/DREAD Scope 6)
- **Type:** Security Requirement
- **Priority:** MEDIUM
- **Related Threats:** Information Disclosure, Security Through Obscurity

---

> **FUNNEL STATUS NOTE:**  
> This requirement is pending formal review and approval by PeculiarMind. It is referenced in the architecture vision for planning purposes but is not yet formally accepted into the project scope.

---

## Description

Error messages and logging must not disclose sensitive information that could aid attackers, while still providing useful feedback for debugging and troubleshooting.

### Specific Requirements

1. **Production Error Messages** (Default Behavior):
   - Generic, user-friendly error messages
   - No internal system paths revealed
   - No file content or sensitive metadata exposed
   - No stack traces or debug information
   - No plugin internal errors exposed verbatim

2. **Debug/Verbose Mode** (`--verbose` or `--debug` flag):
   - Detailed error messages with full context
   - Internal paths and file details included
   - Plugin error output shown
   - Stack traces for debugging
   - Explicitly opt-in only

3. **Sanitization Rules**:
   - **File paths**: Show relative paths or basenames only, not full system paths
   - **File content**: Never include actual file content in errors
   - **User information**: No usernames, home directories, or system info
   - **Command output**: Sanitize output from external commands (file, stat, etc.)
   - **Plugin errors**: Wrap plugin errors with generic message in production mode

4. **Logging Best Practices**:
   - Separate log levels: ERROR, WARN, INFO, DEBUG
   - Default log level: INFO (no sensitive data)
   - DEBUG level only in verbose mode
   - Log files (if implemented) must have restrictive permissions (600)
   - Optional log rotation to prevent disk filling

### Security Controls

- **SC-006**: Error Message Sanitization - Generic messages in production

### Error Message Examples

| Scenario | Production Message | Debug/Verbose Message |
|----------|-------------------|----------------------|
| Invalid input directory | `ERROR: Input directory not found` | `ERROR: Input directory not found: /home/user/secret_docs (ENOENT)` |
| Permission denied | `ERROR: Cannot access input directory` | `ERROR: Permission denied accessing /home/user/docs (EACCES, uid=1000)` |
| Plugin failure | `ERROR: Plugin 'file' failed to process document` | `ERROR: Plugin 'file' failed: /usr/bin/file exited with code 127: command not found` |
| Template not found | `ERROR: Template file not found` | `ERROR: Template file not found: /home/user/.config/doc.doc.md/custom.md` |
| Filter syntax error | `ERROR: Invalid filter pattern in --include` | `ERROR: Invalid glob pattern '**[unclosed' in --include parameter` |
| Path traversal detected | `ERROR: Invalid file path` | `ERROR: Path traversal detected: '../../../etc/passwd' outside '/home/user/docs'` |

### Test Requirements

**Functional Tests**:
- Error messages provide actionable feedback
- Users can resolve common errors without debug mode
- Debug mode provides sufficient detail for troubleshooting

**Security Tests**:
- Production errors don't reveal home directories
- Production errors don't reveal system paths (/usr, /etc, /var)
- Production errors don't show file content snippets
- Plugin errors wrapped generically in production mode
- Permission errors don't reveal user IDs or ownership
- Failed operations don't reveal internal code structure
- Log files created with restrictive permissions (600)

### Acceptance Criteria

- [ ] Default error messages are generic and safe
- [ ] `--verbose` flag enables detailed errors
- [ ] File paths sanitized in production errors
- [ ] No sensitive data in production logs
- [ ] Plugin errors wrapped with generic message
- [ ] Security test suite confirms no information leakage
- [ ] Documentation explains debug mode for troubleshooting

### Error Sanitization Functions

**Sanitize File Path**:
```bash
sanitize_path() {
    local path="$1"
    local mode="${2:-production}"  # production or debug
    
    if [[ "$mode" == "debug" ]]; then
        echo "$path"
    else
        # Show only basename in production
        basename "$path"
    fi
}
```

**Safe Error Reporting**:
```bash
report_error() {
    local category="$1"
    local detailed_msg="$2"
    local user_msg="$3"
    
    if [[ "$VERBOSE" == "true" ]] || [[ "$DEBUG" == "true" ]]; then
        # Debug mode: show all details
        echo "ERROR: [$category] $detailed_msg" >&2
    else
        # Production mode: generic message
        echo "ERROR: $user_msg" >&2
    fi
}

# Usage:
report_error "INPUT_VALIDATION" \
    "Input directory not found: /home/user/secret_project (ENOENT)" \
    "Input directory not found"
```

**Plugin Error Wrapping**:
```bash
execute_plugin_safe() {
    local plugin_name="$1"
    local plugin_cmd="$2"
    local error_output
    
    # Execute plugin and capture errors
    error_output=$($plugin_cmd 2>&1) || {
        local exit_code=$?
        
        if [[ "$VERBOSE" == "true" ]]; then
            log_error "Plugin '$plugin_name' failed with exit code $exit_code:"
            log_error "$error_output"
        else
            log_error "Plugin '$plugin_name' failed to process document"
            log_info "Run with --verbose for details"
        fi
        
        return $exit_code
    }
    
    echo "$error_output"
}
```

### Logging Configuration

**Log Levels**:
```bash
LOG_LEVEL="${LOG_LEVEL:-INFO}"  # Default: INFO

log_debug() {
    [[ "$LOG_LEVEL" == "DEBUG" ]] && echo "[DEBUG] $*" >&2
}

log_info() {
    [[ "$LOG_LEVEL" =~ ^(INFO|DEBUG)$ ]] && echo "[INFO] $*" >&2
}

log_warn() {
    [[ "$LOG_LEVEL" =~ ^(WARN|INFO|DEBUG)$ ]] && echo "[WARN] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}
```

**Log File Permissions** (Future Feature):
```bash
init_log_file() {
    local log_file="$1"
    
    # Create log file with restrictive permissions
    touch "$log_file"
    chmod 600 "$log_file"  # Owner read/write only
    
    # Verify permissions
    local perms=$(stat -c '%a' "$log_file" 2>/dev/null || stat -f '%A' "$log_file")
    [[ "$perms" == "600" ]] || log_warn "Log file permissions not restrictive: $perms"
}
```

### Documentation Requirements

User documentation must include:

1. **Error Message Guide**:
   - Common errors and their meanings
   - How to resolve typical issues
   - When to use `--verbose` for more details

2. **Debug Mode Usage**:
   - `--verbose` flag shows detailed errors
   - `--debug` flag shows even more diagnostic info
   - Warning: Debug output may contain sensitive paths

3. **Security Note**:
   ```
   ⚠️ Privacy Note: Debug mode (--verbose/--debug) may expose file paths
   and system information in error messages. Only use when troubleshooting,
   and be cautious when sharing debug output publicly.
   ```

### Related Requirements

- All security requirements benefit from safe error handling
- REQ_SEC_003 (Plugin Descriptor Validation) - plugin errors must be sanitized

### Risk if Not Implemented

**Risk Level**: LOW (2.43)

**STRIDE Score**: 1.67 | **DREAD Score**: 3.2

Without error message sanitization:
- **Information Disclosure**: Attackers learn system structure, paths, users
- **Aids Reconnaissance**: Error details help attacker plan further attacks
- **Privacy Violation**: Exposes sensitive file names and locations
- **Social Engineering**: Detailed errors aid phishing and targeted attacks

While DREAD score is moderate (3.2), the actual risk is LOW because:
- Information disclosure alone doesn't compromise system
- Primarily aids further attacks rather than direct exploitation
- Home user context limits attack scenarios

However, good security hygiene requires sanitizing production errors regardless of risk level.

### Implementation Notes

**Balance Usability and Security**:
- Production errors should still be actionable
- Don't go too far with obscurity (users need to fix problems)
- Provide clear path to get more details (--verbose flag)

**Progressive Disclosure**:
1. **Default**: Generic error + hint
2. **--verbose**: Detailed error + context
3. **--debug**: Full diagnostic output

**Example**:
```
# Default
ERROR: Cannot process file 'document.pdf'
Hint: Check file permissions and ensure file is readable

# --verbose
ERROR: Cannot process file '/home/user/docs/2024/document.pdf'
Reason: Permission denied (EACCES)
File permissions: -rw------- (owner: root, current user: user)

# --debug
ERROR: Cannot process file '/home/user/docs/2024/document.pdf'
Reason: Permission denied (EACCES)
File permissions: -rw------- (owner: root, current user: user)
Stat output: [full stat output]
Plugin execution trace: [full trace]
```

### References

- Security Concept Section 5.6 (Scope 6: Error Handling and Logging)
- OWASP: Improper Error Handling
- CWE-209: Generation of Error Message Containing Sensitive Information
- CWE-532: Insertion of Sensitive Information into Log File
