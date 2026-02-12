# Requirement: Security Audit Logging

**ID**: req_0062  
**Status**: Funnel  
**Priority**: MEDIUM  
**Created**: 2026-02-11  
**Source**: Security Review Agent (Finding-006)

## Description

The system must implement comprehensive security event logging to enable detection, investigation, and response to security incidents. Security-relevant events must be logged with appropriate detail, context, and severity for audit trail purposes.

## Rationale

**Security Finding**: FINDING-006 identified insufficient security event logging:
- Input validation failures not consistently logged
- Attack attempts (path traversal, injection) not captured
- Permission changes not audited
- Workspace integrity violations lack context
- Cannot reconstruct security incident timelines

**Risk Assessment**:
- **DREAD Likelihood**: 6.0 (Damage=5, Reproducibility=10, Exploitability=N/A, Affected=10, Discoverability=5)
- **STRIDE Impact**: Repudiation = 9 (cannot prove/disprove attacker actions)
- **Risk Score**: 6.0 × 9 × 2 = **108 (MEDIUM)**
- **CWE**: CWE-778 (Insufficient Logging)

## Requirements

### Functional Requirements

**FR-062-01**: The system MUST define and implement a security event taxonomy covering:
- Authentication events (future: login, logout, failed attempts)
- Authorization events (permission checks, access denials)
- Input validation failures (malformed input, injection attempts)
- Security policy violations (path traversal, sandbox escapes)
- Configuration changes (permission hardening, security settings)
- Integrity events (corruption detection, verification failures)
- Audit events (security scans, compliance checks)

**FR-062-02**: Each security event MUST include:
- **Timestamp**: ISO 8601 UTC (`2026-02-11T14:30:45Z`)
- **Event Type**: Category from taxonomy (e.g., `INPUT_VALIDATION_FAILURE`)
- **Severity**: CRITICAL, HIGH, MEDIUM, LOW, INFO
- **Component**: Source component (e.g., `ARGUMENT_PARSER`, `PLUGIN_VALIDATOR`)
- **Actor**: User/process initiating action (username, PID)
- **Action**: What was attempted (e.g., `validate_path`, `execute_plugin`)
- **Target**: Resource affected (file path, plugin name)
- **Outcome**: Success, failure, blocked
- **Details**: Contextual information (error codes, validation rules violated)
- **Source IP**: N/A for local-only tool (placeholder for future)

**FR-062-03**: Security events MUST be logged to a separate security log channel:
- Distinct from operational logs
- Higher retention requirements
- Protected permissions (0600)
- Machine-parseable format (JSON lines)

**FR-062-04**: The system MUST provide security log query capabilities:
- Filter by event type, severity, time range
- Search for specific actors or targets
- Export for SIEM integration

### Security Requirements

**SR-062-01**: Security logs MUST NOT contain sensitive data:
- Full file content
- Credentials or tokens
- Confidential user data
- Logs must sanitize paths (keep structure, redact sensitive directories)

**SR-062-02**: Security log files MUST be protected:
- File permissions: 0600 (owner read/write only)
- Tampering detection (optional: cryptographic signatures)
- Separate from workspace (prevent accidental deletion)

**SR-062-03**: Log injection attacks MUST be prevented:
- Escape newlines, control characters in logged data
- Validate event field formats
- Use structured logging (JSON) to prevent parsing attacks

**SR-062-04**: Security event logging failures MUST NOT cause application failure:
- Log to stderr as fallback
- Continue operation (fail open for logging)
- Alert on repeated logging failures

## Acceptance Criteria

1. ✅ Security event taxonomy documented
2. ✅ Security logging wrapper implemented (`log_security_event()`)
3. ✅ All critical security events logged:
   - Path traversal attempts
   - Command injection attempts
   - Plugin validation failures
   - Permission changes
   - Workspace integrity violations
   - Sandbox escape attempts
   - Input validation rejections
4. ✅ JSON-formatted security log output
5. ✅ Log sanitization prevents sensitive data leakage
6. ✅ Security log query tool implemented
7. ✅ Test suite validates security event logging
8. ✅ Documentation: Security log analysis guide

## Security Event Taxonomy

### Critical Events
- **AUTH_FAILURE**: Authentication attempt failed (future)
- **AUTHZ_VIOLATION**: Authorization check blocked access
- **INJECTION_DETECTED**: Command/path/log injection attempt
- **SANDBOX_ESCAPE**: Plugin attempted to escape sandbox
- **INTEGRITY_FAILURE**: Cryptographic verification failed

### High Events
- **PATH_TRAVERSAL**: Directory escape attempt
- **PERMISSION_VIOLATION**: Insufficient permissions for operation
- **PLUGIN_VALIDATION_FAILURE**: Plugin descriptor failed security checks
- **WORKSPACE_CORRUPTION**: Workspace integrity check failed

### Medium Events
- **INPUT_VALIDATION_FAILURE**: Malformed input rejected
- **CONFIG_CHANGE**: Security-relevant configuration modified
- **RESOURCE_LIMIT_EXCEEDED**: DoS protection triggered

### Low Events
- **SECURITY_SCAN_START**: Security scan initiated
- **SECURITY_SCAN_COMPLETE**: Security scan completed
- **AUDIT_EVENT**: Compliance check performed

## Implementation Notes

### Security Logging Wrapper
```bash
# In logging.sh
log_security_event() {
  local event_type="$1"
  local severity="$2"
  local component="$3"
  local action="$4"
  local target="$5"
  local outcome="$6"
  local details="$7"
  
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  local actor="${USER}@${HOSTNAME}"
  
  # Sanitize target (remove sensitive paths)
  local sanitized_target
  sanitized_target=$(sanitize_path_for_log "$target")
  
  # Build JSON event
  local event_json
  event_json=$(jq -n \
    --arg ts "$timestamp" \
    --arg type "$event_type" \
    --arg sev "$severity" \
    --arg comp "$component" \
    --arg actor "$actor" \
    --arg action "$action" \
    --arg target "$sanitized_target" \
    --arg outcome "$outcome" \
    --arg details "$details" \
    '{
      timestamp: $ts,
      event_type: $type,
      severity: $sev,
      component: $comp,
      actor: $actor,
      action: $action,
      target: $target,
      outcome: $outcome,
      details: $details
    }')
  
  # Write to security log
  echo "$event_json" >> "${SECURITY_LOG_FILE:-/tmp/doc.doc.security.log}"
}
```

### Usage Example
```bash
# In argument_parser.sh
if [[ "$SOURCE_DIR" == *".."* ]]; then
  log_security_event \
    "PATH_TRAVERSAL" \
    "HIGH" \
    "ARGUMENT_PARSER" \
    "validate_path" \
    "$SOURCE_DIR" \
    "BLOCKED" \
    "Directory traversal attempt detected in source directory path"
  
  echo "Error: Invalid source directory (path traversal detected)" >&2
  exit 1
fi
```

## Test Cases

### Test-062-01: Path Traversal Logged
```bash
./doc.doc.sh -d "../../../etc" -w /tmp/workspace -t /tmp/output 2>&1
# Check security log contains PATH_TRAVERSAL event
grep "PATH_TRAVERSAL" /tmp/doc.doc.security.log
```

### Test-062-02: Plugin Validation Failure Logged
```bash
# Create malicious plugin descriptor with injection
./doc.doc.sh -p list
# Check security log for PLUGIN_VALIDATION_FAILURE
```

### Test-062-03: Log Injection Prevention
```bash
# Attempt log injection with newline in path
./doc.doc.sh -d "/tmp/source\nFAKE_EVENT" -w /tmp/workspace -t /tmp/output
# Verify newline escaped in log, no fake event created
```

### Test-062-04: Sensitive Data Sanitization
```bash
./doc.doc.sh -d "/home/user/.ssh/source" -w /tmp/workspace -t /tmp/output
# Verify security log redacts "/home/user/.ssh" path
```

## Dependencies

- **Requires**: jq (JSON manipulation)
- **Blocks**: v1.1 release (security hardening milestone)
- **Related**: req_0052 (Secure Logging Practices)

## Security Scope Updates

Update `02_runtime_application_security.md`:
- Add audit logging controls section
- Document security event taxonomy
- Update residual risks (improved detection capability)

## Traceability

- **Security Finding**: FINDING-006 (Medium Priority, Risk=108)
- **Security Scope**: scope_runtime_app_001
- **Related Requirements**: req_0052 (Secure Logging)
- **Feature**: Enhancement to logging component

## Review Status

- **Created By**: Security Review Agent
- **Reviewed By**: (Pending)
- **Approved By**: (Pending)
- **Status**: Funnel (Requires analysis and acceptance)

---

**Notes**: This requirement addresses a MEDIUM-priority security gap identified during comprehensive security review. Implementation target is v1.1 release.
