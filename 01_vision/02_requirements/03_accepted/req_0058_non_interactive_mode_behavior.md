# Requirement: Non-Interactive Mode Behavior

**ID**: req_0058

## Status
State: Accepted  
Created: 2026-02-10  
Last Updated: 2026-02-10

## Overview
The system shall detect when running in non-interactive mode (scripts, cron, CI/CD) and operate without prompts, using sensible defaults, machine-readable output, and comprehensive logging for unattended operation.

## Description
When the toolkit runs in non-interactive mode (not connected to a terminal), it operates completely automatically without any user prompts that would cause hangs in automated environments. Non-interactive mode is detected when stdin or stdout are not terminals (`! [ -t 0 ] || ! [ -t 1 ]`). This mode prioritizes automation-friendly operation: no prompts or confirmations, sensible defaults for all decisions, machine-parseable output formats, predictable exit codes, comprehensive logging with timestamps, and actionable error messages suitable for retry logic. Critical for cron jobs, CI/CD pipelines, and other automated workflows.

## Motivation
From CLI Interface Concept (08_0003_cli_interface_concept.md) and quality scenario R1: "Scheduled task (cron) triggers analysis, runs automatically at 2 AM daily, executes without hangs, completes with exit code 0." Unattended operation is a core use case. Without proper non-interactive handling, cron jobs would hang indefinitely on prompts or fail mysteriously without clear error messages.

Split from req_0045 (Non-Interactive Mode Detection and Handling) to separate interactive and non-interactive concerns for clearer implementation and testing.

## Category
- Type: Functional
- Priority: High

## Acceptance Criteria

### Mode Detection
- [ ] System detects non-interactive mode when stdin is NOT a terminal (`! [ -t 0 ]`)
- [ ] System detects non-interactive mode when stdout is NOT a terminal (`! [ -t 1 ]`)
- [ ] Either condition triggers non-interactive mode (logical OR)
- [ ] Mode detection performed early in script execution
- [ ] Mode stored in global variable (e.g., `IS_INTERACTIVE=false`)
- [ ] Verbose mode logs detected mode ("Running in non-interactive mode")

### No Prompts Policy
- [ ] No prompts or user input requests (all operations automatic or fail)
- [ ] No `read` commands executed in non-interactive mode
- [ ] No blocking waits for user input
- [ ] All decisions made automatically using defaults or fail with clear errors

### Automatic Defaults
- [ ] Missing optional tools: log warning, skip associated plugins, continue analysis
- [ ] Minor workspace migration (compatible versions): apply automatically, log migration
- [ ] Major workspace migration (breaking changes): fail with clear error, do not prompt
- [ ] Target/workspace directory creation: create automatically if possible
- [ ] Invalid arguments: fail immediately with exit code, do not prompt for correction

### Progress Reporting
- [ ] Progress indicators suppressed or limited to periodic log entries
- [ ] No in-place updating displays (no `\r` or cursor manipulation)
- [ ] Progress logged as discrete events (start, milestones, completion)
- [ ] All progress output scrolls normally (suitable for log files)
- [ ] Periodic milestone logging (e.g., every 10% or every N files)

### Logging Requirements
- [ ] All log entries include ISO 8601 timestamps
- [ ] Structured logging format for parsing (`[timestamp] [level] message`)
- [ ] Detailed logging for audit trail (include paths, versions, conditions)
- [ ] Full context in error messages (no ambiguous "something failed")
- [ ] Log level appropriate for automated monitoring

### Output Format
- [ ] Output format consistent and parseable
- [ ] No ANSI color codes in non-interactive mode
- [ ] Predictable structure for automated parsing
- [ ] Exit codes documented and consistent
- [ ] Summary output suitable for parsing by monitoring tools

### Error Handling
- [ ] Errors include full context (paths, versions, conditions)
- [ ] Errors include actionable information for automated retry logic
- [ ] Exit codes consistent and documented regardless of mode
- [ ] Never exit with ambiguous "something failed" error
- [ ] Error messages suitable for log aggregation and alerting

### Testing Support
- [ ] Mode detection can be forced via environment variable (`DOC_DOC_INTERACTIVE=false`)
- [ ] Test suite includes tests for non-interactive behavior
- [ ] CI/CD pipelines test non-interactive mode exclusively

## Related Requirements
- req_0057 (Interactive Mode Behavior) - complementary requirement for user interaction
- req_0045 (Non-Interactive Mode Detection and Handling) - obsoleted parent requirement
- req_0006 (Verbose Logging Mode) - logging behavior adapts to mode
- req_0020 (Error Handling) - error messages adapt to mode

## Technical Considerations

### Mode Detection Implementation
```bash
detect_interactive_mode() {
  if [ -t 0 ] && [ -t 1 ]; then
    IS_INTERACTIVE=true
    log "DEBUG" "Running in interactive mode"
  else
    IS_INTERACTIVE=false
    log "DEBUG" "Running in non-interactive mode (automated)"
  fi
}
```

### Non-Interactive Behavior Implementation
```bash
# No prompts - automatic decisions
if [[ "${IS_INTERACTIVE}" == "true" ]]; then
  read -p "Install missing tool? [y/N] " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    install_tool
  fi
else
  # Non-interactive: log and skip
  log "WARN" "Tool not available, skipping plugin (non-interactive mode)"
fi
```

### Logging Output Example
```bash
# Non-interactive mode - Scrolling log entries with timestamps
[2026-02-09T14:30:00Z] [INFO] Starting analysis of 152 files
[2026-02-09T14:30:00Z] [DEBUG] Running in non-interactive mode (automated)
[2026-02-09T14:30:00Z] [INFO] Processing file 1/152: manual.pdf
[2026-02-09T14:30:05Z] [INFO] Processing file 2/152: guide.pdf
[2026-02-09T14:30:10Z] [INFO] Milestone: 10/152 files processed (7%)
[2026-02-09T14:31:30Z] [INFO] Milestone: 50/152 files processed (33%)
[2026-02-09T14:33:00Z] [INFO] Milestone: 100/152 files processed (66%)
[2026-02-09T14:42:34Z] [INFO] Analysis complete: 152 files processed, 3 skipped, 149 reports generated
[2026-02-09T14:42:34Z] [INFO] Exit code: 0
```

### Decision Matrix for Non-Interactive Mode

| Scenario | Action | Exit Code |
|----------|--------|-----------|
| Missing optional tool | Log warning, skip plugin, continue | 0 (success) |
| Minor workspace migration | Auto-migrate, log, continue | 0 (success) |
| Major workspace migration | Log error, fail | 1 (error) |
| Invalid arguments | Log error, fail | 2 (usage error) |
| Target dir doesn't exist | Create automatically, log | 0 (success) |
| Permission denied | Log error with details, fail | 1 (error) |

### Environment Variable Override
```bash
# For testing or explicit control
export DOC_DOC_INTERACTIVE=false  # Force non-interactive

# In script
if [[ -n "${DOC_DOC_INTERACTIVE}" ]]; then
  IS_INTERACTIVE="${DOC_DOC_INTERACTIVE}"
else
  detect_interactive_mode
fi
```

### Structured Logging Function
```bash
log_structured() {
  local level="$1"
  local component="${2:-MAIN}"
  local message="$3"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  if [[ "${IS_INTERACTIVE}" == "true" ]]; then
    # Human-friendly for interactive
    echo "[${level}] ${message}"
  else
    # Structured for non-interactive
    echo "[${timestamp}] [${level}] [${component}] ${message}"
  fi
}
```

## Transition History
- [2026-02-10] Created by Requirements Engineer Agent - split from req_0045 to separate non-interactive mode concerns
- [2026-02-10] Moved to accepted (inherits acceptance status from req_0045)
