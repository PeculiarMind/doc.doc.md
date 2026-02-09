---
title: Audit and Logging Concept
arc42-chapter: 8
---

## 0008 Audit and Logging Concept

## Table of Contents

- [Purpose](#purpose)
- [Rationale](#rationale)
- [Logging Architecture](#logging-architecture)
- [Log Levels and Taxonomy](#log-levels-and-taxonomy)
- [Log Format and Structure](#log-format-and-structure)
- [Security Logging and Audit Trail](#security-logging-and-audit-trail)
- [Log Sanitization and Privacy](#log-sanitization-and-privacy)
- [Log Rotation and Retention](#log-rotation-and-retention)
- [Monitoring and Alerting](#monitoring-and-alerting)
- [Debugging and Investigation Support](#debugging-and-investigation-support)
- [Integration with Other Concepts](#integration-with-other-concepts)
- [Related Requirements](#related-requirements)

Audit and logging provide observability into system behavior, security events, and operational issues. The system uses multi-level logging (general, verbose, security) to support debugging, security monitoring, and incident investigation while preventing information disclosure.

### Purpose

Audit and logging:
- **Enable Debugging**: Verbose logs help developers diagnose failures and understand execution flow
- **Detect Security Events**: Security audit trail records validation failures, access denials, suspicious patterns
- **Support Incident Response**: Forensic logs enable post-incident investigation and root cause analysis
- **Verify Correct Operation**: Logs confirm security controls function as designed
- **Meet Compliance Requirements**: Audit trails demonstrate security control effectiveness
- **Provide Observability**: Logs reveal system behavior in production environments

### Rationale

- **Unattended Operation**: Automated execution (cron, systemd timers) requires detailed logging for troubleshooting
- **Security Visibility**: Defense-in-depth requires detection when prevention fails
- **Local-Only Processing**: No centralized logging infrastructure, logs must be self-contained
- **Privacy Requirements**: Sensitive paths and data must not leak via logs
- **Offline Debugging**: Logs must support investigation without network access to log aggregation systems

### Logging Architecture

**Three-Tier Logging System**:

**Tier 1: General Application Logs** (default)
- Operational events (script start, plugin execution, report generation)
- High-level errors and warnings
- User-facing messages (progress, completion, errors)
- Output: stdout/stderr

**Tier 2: Verbose Debug Logs** (--verbose flag)
- Detailed execution flow (function entry/exit, decision points)
- Variable values and intermediate results
- Performance metrics (timing, resource usage)
- Validation rule application (which checks passed/failed)
- Output: stderr or log file

**Tier 3: Security Audit Logs** (always enabled)
- Security-relevant events (validation failures, access denials)
- Suspicious patterns (multiple failures, unexpected inputs)
- Security control invocations (what was checked, result)
- Sanitized context (paths, arguments, errors)
- Output: dedicated security log file (workspace/.security.log or configurable)

**Separation Rationale**:
- General logs: user-facing, minimal detail, safe for sharing
- Verbose logs: developer-facing, detailed, may contain sensitive context
- Security logs: security team-facing, critical events, structured for analysis

### Log Levels and Taxonomy

**General Logging Levels**:
- **INFO**: Normal operation (script start, plugin execution, report generation)
- **WARNING**: Degraded operation (missing optional tools, non-critical failures)
- **ERROR**: Operation failures (validation errors, plugin failures, file access denied)
- **CRITICAL**: Unrecoverable errors (corrupted workspace, missing dependencies)

**Verbose Logging Levels**:
- **DEBUG**: Detailed execution flow (function calls, variable assignments)
- **TRACE**: Extremely detailed (loop iterations, conditional evaluations)

**Security Logging Levels**:
- **SECURITY_INFO**: Security control invocation (validation applied, passed)
- **SECURITY_WARNING**: Security concerns (unusual patterns, near-misses)
- **SECURITY_ERROR**: Security violations (validation failure, access denied)
- **SECURITY_CRITICAL**: Severe security events (exploitation attempt detected, workspace tampering)

**Event Taxonomy** (security logs):
- **INPUT_VALIDATION_FAILURE**: Argument, path, or file validation rejected input
- **PLUGIN_SECURITY_VIOLATION**: Plugin descriptor invalid, sandbox breach, resource limit exceeded
- **TEMPLATE_SECURITY_VIOLATION**: Template injection attempt, complexity limit exceeded
- **WORKSPACE_INTEGRITY_VIOLATION**: Corruption detected, lock conflict, schema validation failure
- **TOOL_VERIFICATION_FAILURE**: Tool not found, version mismatch, signature verification failed
- **AUTHENTICATION_EVENT**: Credential usage (if applicable), authorization check
- **CONFIGURATION_CHANGE**: Security-relevant setting modified
- **SUSPICIOUS_PATTERN**: Multiple failures, unusual inputs, timing anomalies

### Log Format and Structure

**General Log Format** (human-readable):
```
[2026-02-09 14:23:15 UTC] INFO: Starting doc.doc.sh analysis
[2026-02-09 14:23:15 UTC] INFO: Source directory: ./source
[2026-02-09 14:23:15 UTC] INFO: Workspace directory: ./workspace
[2026-02-09 14:23:16 UTC] WARNING: Optional tool 'exiftool' not found
[2026-02-09 14:23:18 UTC] INFO: Analysis complete, generated report: ./target/report.md
```

**Verbose Log Format** (detailed, developer-facing):
```
[2026-02-09 14:23:15.123 UTC] DEBUG [main]: Entering validate_arguments()
[2026-02-09 14:23:15.124 UTC] DEBUG [validation]: Validating path: ./source
[2026-02-09 14:23:15.125 UTC] DEBUG [validation]: Path canonicalized: /home/user/project/source
[2026-02-09 14:23:15.126 UTC] DEBUG [validation]: Path type: directory, readable: true
[2026-02-09 14:23:15.127 UTC] DEBUG [main]: Exiting validate_arguments() -> success
```

**Security Log Format** (structured JSON Lines):
```json
{"timestamp":"2026-02-09T14:23:15.123Z","level":"SECURITY_ERROR","event":"INPUT_VALIDATION_FAILURE","component":"argument_parser","message":"Path contains invalid characters","context":{"input_sanitized":"../etc/******","rule":"path_traversal_pattern","action":"rejected"},"pid":12345,"uid":1000}
{"timestamp":"2026-02-09T14:23:16.456Z","level":"SECURITY_WARNING","event":"PLUGIN_SECURITY_VIOLATION","component":"plugin_executor","message":"Plugin exceeded resource limit","context":{"plugin":"malicious_plugin","limit_type":"execution_time","limit_value":"30s","actual_value":"31s","action":"terminated"},"pid":12345,"uid":1000}
```

**Structured Log Fields** (security logs):
- **timestamp**: ISO 8601 UTC timestamp with millisecond precision
- **level**: Security log level (SECURITY_INFO, SECURITY_WARNING, SECURITY_ERROR, SECURITY_CRITICAL)
- **event**: Event taxonomy category (INPUT_VALIDATION_FAILURE, etc.)
- **component**: Module/component where event occurred (argument_parser, plugin_executor, etc.)
- **message**: Human-readable event description (sanitized)
- **context**: Event-specific details (sanitized paths, validation rules, limits, actions)
- **pid**: Process ID of doc.doc.sh execution
- **uid**: User ID executing the script
- **correlation_id**: Optional ID linking related events (e.g., plugin load → validation → execution)

**Why JSON Lines for Security Logs**:
- Machine-parsable (jq, grep, log analysis tools)
- One event per line (robust to corruption, easy to append)
- Structured fields (queryable, filterable, aggregatable)
- Standard format (compatible with log aggregation systems if ever needed)

### Security Logging and Audit Trail

**Security Events Logged** (req_0051):

**Input Validation Events**:
- Argument validation failures (invalid types, formats, bounds)
- Path validation failures (traversal patterns, shell metacharacters)
- File type mismatches (expected directory, got file)
- Security filtering rejections (dangerous characters, patterns)

**Plugin Security Events**:
- Descriptor validation failures (schema violations, missing fields)
- Sandbox violations (unauthorized file access, resource limit exceeded)
- Plugin output validation failures (invalid format, size exceeded)
- Plugin execution errors (timeout, non-zero exit codes)

**Template Security Events**:
- Template injection attempts (code execution patterns)
- Iteration limit exceeded (denial of service prevention)
- Variable resolution failures (undefined variables)
- Output size limit exceeded

**Workspace Integrity Events**:
- Corruption detected (invalid JSON, checksum mismatch)
- Lock conflicts (concurrent access attempts)
- Schema validation failures (unexpected data structure)
- Permission violations (workspace not writable)

**Dependency Verification Events**:
- Tool not found (PATH resolution failed)
- Version mismatch (incompatible or vulnerable version)
- Tool invocation failures (non-zero exit code)
- Tool output validation failures (unexpected format)

**Configuration and Authentication Events**:
- Security-relevant configuration changes
- Credential usage (if applicable in future)
- Authorization checks (if applicable)
- Access denials

**Audit Trail Properties**:
- **Non-repudiable**: Timestamp, user ID, process ID identify who did what when
- **Tamper-evident**: Append-only log files, checksums (future), restrictive permissions (0600)
- **Complete**: All security-relevant events logged, including successful operations
- **Contextual**: Sufficient detail for forensic investigation without sensitive data

### Log Sanitization and Privacy

**Sensitive Data Removal** (req_0054):
- **Credentials**: Passwords, API keys, SSH keys, tokens removed entirely
- **Absolute Paths**: Replaced with workspace-relative paths or `<workspace>`, `<source>` placeholders
- **User Input**: Truncated to maximum 1KB per log entry (prevent log flooding)
- **File Content**: Never logged (only metadata)
- **Environment Variables**: Sanitized (remove IFS, PATH, sensitive vars)

**Log Injection Prevention**:
- **Newline Escaping**: CRLF characters escaped as `\n` and `\r` (prevent multi-line injection)
- **Control Characters**: Stripped or escaped (prevent terminal escape sequence injection)
- **Timestamp Validation**: ISO 8601 format enforced (prevent timestamp forgery)
- **Component Names**: Whitelisted values only (prevent user-controlled component names)
- **Structured Output**: JSON escaping for security logs (prevent injection via field values)

**Sanitization Examples**:
```bash
# Before sanitization (dangerous)
log_security "User path: /home/alice/secret-project/password.txt"

# After sanitization (safe)
log_security "User path: <source>/password.txt"

# Before sanitization (log injection)
log_security "Input: value\n[2026-02-09] CRITICAL: FAKE MESSAGE"

# After sanitization (safe)
log_security "Input: value\\n[2026-02-09] CRITICAL: FAKE MESSAGE"

# Before sanitization (information disclosure)
log_security "Error: ${full_error_stack_trace}"

# After sanitization (safe)
log_security "Error: Validation failed (see verbose log for details)"
```

**Verbose Mode Disclosure** (req_0006):
- Verbose logging requires explicit user flag (--verbose)
- Verbose logs may contain detailed paths, arguments, intermediate values
- Warning message displayed when verbose logging enabled
- Verbose output to stderr (separable from general output)
- Users understand risk of sharing verbose logs

### Log Rotation and Retention

**Security Log Rotation** (req_0051):
- **Maximum Size**: 100MB default (configurable)
- **Rotation Strategy**: Rename current log to `.1`, `.2`, etc., compress old logs
- **Retention**: Keep last 10 rotated logs (configurable)
- **Atomic Rotation**: Use rename operations (no data loss during rotation)

**General Log Rotation**:
- General logs to stdout/stderr (managed by user's environment)
- Verbose logs to stderr or optional log file (user-managed rotation)

**Why Rotation Matters**:
- Limited disk space in embedded/NAS environments
- Large logs impede analysis (need focused, recent data)
- Compliance requirements (retention periods)
- Performance (large files slow parsing)

**Rotation Implementation**:
```bash
rotate_security_log() {
    local log_file="$SECURITY_LOG_PATH"
    local max_size="104857600"  # 100MB
    
    if [[ -f "$log_file" && $(stat -f%z "$log_file") -gt "$max_size" ]]; then
        # Rotate existing logs (.9 -> .10, .8 -> .9, ..., .1 -> .2)
        for i in {9..1}; do
            if [[ -f "${log_file}.${i}.gz" ]]; then
                mv "${log_file}.${i}.gz" "${log_file}.$((i + 1)).gz"
            fi
        done
        
        # Compress and rotate current log
        gzip -c "$log_file" > "${log_file}.1.gz"
        : > "$log_file"  # Truncate current log
        
        # Remove old logs beyond retention
        rm -f "${log_file}.11.gz"
    fi
}
```

### Monitoring and Alerting

**Current Capabilities** (local-only processing):
- Logs written to files (workspace/.security.log)
- Users can inspect logs manually (grep, jq, tail)
- Verbose mode provides real-time debugging (stderr)

**Future Extensibility** (post-MVP):
- Log forwarding to external systems (syslog, SIEM)
- Alerting on critical security events (webhook, email)
- Log aggregation and correlation (Elasticsearch, Splunk)
- Real-time monitoring dashboard

**Why Not Implemented Now**:
- Local-only processing constraint (no network access)
- Batch processing context (no real-time requirements)
- Minimal dependencies (no external service dependencies)
- Simplicity priority (add complexity when needed)

**Monitoring Patterns for Users**:
```bash
# Watch security log for critical events
tail -f workspace/.security.log | jq 'select(.level == "SECURITY_CRITICAL")'

# Count validation failures in last hour
jq -r 'select(.event == "INPUT_VALIDATION_FAILURE") | .timestamp' \
    workspace/.security.log | \
    awk -v cutoff="$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
    '$1 > cutoff' | wc -l

# Extract all plugin security violations
jq 'select(.event == "PLUGIN_SECURITY_VIOLATION")' workspace/.security.log

# Generate daily security summary
jq -s 'group_by(.level) | map({level: .[0].level, count: length})' \
    workspace/.security.log
```

### Debugging and Investigation Support

**Verbose Logging for Debugging** (req_0006):
- Execution flow visibility (function calls, decision points)
- Variable inspection (intermediate values, states)
- Validation rule application (which checks ran, results)
- Performance profiling (timing, resource usage)
- Plugin debugging (input/output, execution context)

**Correlation for Investigation**:
- Correlation IDs track related events (plugin sequence: discover → validate → execute → integrate)
- Timestamps enable temporal analysis (what happened before/after)
- Component labels isolate failures (which module failed)
- Context fields provide details (what was being processed)

**Error Handling Integration** (req_0020):
- Errors logged before failure (capture state before exit)
- Error messages sanitized (public-facing, no details)
- Detailed diagnostics in verbose/security logs
- Exit codes mapped to log events (investigate failures)

**Investigation Workflow**:
1. User reports failure (exit code, error message)
2. Investigate general logs (high-level what went wrong)
3. Enable verbose logging (re-run with --verbose for details)
4. Inspect security logs (check for validation failures, security events)
5. Correlate events (follow correlation ID or timestamps)
6. Identify root cause (validation rule, plugin failure, workspace corruption)
7. Remediate and verify (fix issue, confirm logs show success)

### Integration with Other Concepts

**Security Architecture (08_0007)**:
- Logging provides visibility into security control operation
- Audit trail enables verification of defense-in-depth layers
- Detection capability when prevention fails

**Input Validation and Security (08_0005)**:
- All validation failures logged to security log
- Sanitization prevents log injection attacks
- Validation rule tracking (which rules applied, results)

**Plugin Architecture (08_0001)**:
- Plugin execution events logged (discovery, validation, execution, integration)
- Plugin errors logged with sanitized context
- Plugin resource limits logged when exceeded

**Workspace Data Management (08_0002)**:
- Workspace operations logged (corruption detection, lock conflicts)
- Atomic operations logged (write-then-rename)
- Schema validation failures logged

**CLI Interface (08_0003)**:
- Argument validation logged (invalid inputs)
- Help system invocation logged (INFO level)
- Exit code logging (operation result)

**Modular Script Architecture (08_0004)**:
- Component-level logging (identify which module failed)
- Module boundaries logged (entry/exit points)
- Inter-module communication logged (data flow)

**Platform Support (08_0006)**:
- Platform detection logged (which platform identified)
- Platform-specific behavior logged (why different code paths)
- Fallback behavior logged (what happened when platform unknown)

**Dependency and Supply Chain Security (08_0009)**:
- Tool verification logged (version checks, availability)
- Tool invocation logged (sanitized command lines)
- Tool failures logged (exit codes, stderr)

### Related Requirements

**Core Logging Requirements**:
- **req_0006**: [Verbose Logging Mode](../../02_requirements/03_accepted/req_0006_verbose_logging_mode.md) - detailed debugging logs
- **req_0020**: [Error Handling](../../02_requirements/03_accepted/req_0020_error_handling.md) - error logging integration

**Security Logging Requirements**:
- **req_0051**: [Security Logging and Audit Trail](../../02_requirements/01_funnel/req_0051_security_logging_and_audit_trail.md) - comprehensive security event logging
- **req_0054**: [Error Message Information Disclosure Prevention](../../02_requirements/01_funnel/req_0054_error_message_information_disclosure_prevention.md) - log sanitization

**Supporting Requirements**:
- **req_0038**: [Input Validation and Sanitization](../../02_requirements/03_accepted/req_0038_input_validation_and_sanitization.md) - validation events logged
- **req_0047**: [Plugin Descriptor Validation](../../02_requirements/01_funnel/req_0047_plugin_descriptor_validation.md) - plugin validation events logged
- **req_0050**: [Workspace Integrity Verification](../../02_requirements/01_funnel/req_0050_workspace_integrity_verification.md) - integrity violations logged
