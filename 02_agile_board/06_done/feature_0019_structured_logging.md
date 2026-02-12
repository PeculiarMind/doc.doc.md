# Feature: Structured Logging for Automation

**ID**: 0019  
**Type**: Feature Implementation  
**Status**: Done  
**Created**: 2026-02-10  
**Updated**: 2026-02-12  
**Completed**: 2026-02-12  
**Priority**: High

## Overview
Implement structured, machine-parseable logging system that provides comprehensive audit trail and monitoring-friendly output for non-interactive mode, with timestamp-based entries and consistent format suitable for log aggregation and automated analysis.

## Description
Create a dual-mode logging system that adapts output format based on execution context. In interactive mode, logs are concise and human-friendly ("Analyzing 152 files..."). In non-interactive mode, logs are structured with ISO 8601 timestamps, component tags, and detailed context suitable for parsing, monitoring, and debugging automated workflows. All log entries in non-interactive mode include full context (paths, versions, conditions) to enable troubleshooting without interactive access.

The logging system provides consistent levels (DEBUG, INFO, WARN, ERROR), supports filtering by level, integrates with verbose mode, and ensures all critical events and errors are captured with sufficient detail for automated retry logic and alerting systems.

## Business Value
- Enables effective monitoring and alerting for automated workflows
- Provides audit trail for compliance and troubleshooting
- Facilitates log aggregation and analysis in centralized logging systems
- Improves debuggability of cron jobs, CI/CD pipelines, and scheduled tasks
- Reduces mean time to resolution (MTTR) through comprehensive context
- Supports operational excellence and SRE practices

## Related Requirements
- [req_0058](../../01_vision/02_requirements/03_accepted/req_0058_non_interactive_mode_behavior.md) - Non-Interactive Mode Behavior (PRIMARY)
- [req_0006](../../01_vision/02_requirements/03_accepted/req_0006_verbose_logging_mode.md) - Verbose Logging Mode
- [req_0020](../../01_vision/02_requirements/03_accepted/req_0020_error_handling.md) - Error Handling (error log format)

## Acceptance Criteria

### Log Format - Non-Interactive Mode
- [ ] All log entries include ISO 8601 timestamp in UTC (`YYYY-MM-DDTHH:MM:SSZ`)
- [ ] Log format: `[timestamp] [level] [component] message`
- [ ] Example: `[2026-02-10T14:30:00Z] [INFO] [SCAN] Processing file 1/152: manual.pdf`
- [ ] Format consistent across all log entries for easy parsing
- [ ] No ANSI color codes in non-interactive mode

### Log Format - Interactive Mode
- [ ] Log entries concise and human-friendly
- [ ] Timestamps optional (omitted by default unless verbose mode)
- [ ] Format: `[level] message` or just `message` for INFO level
- [ ] ANSI color codes acceptable for emphasis
- [ ] Example: `Analyzing 152 files...`

### Log Levels
- [ ] **DEBUG**: Detailed diagnostic information (verbose mode only)
- [ ] **INFO**: General informational messages about normal operation
- [ ] **WARN**: Warning messages for non-critical issues
- [ ] **ERROR**: Error messages for failures requiring attention
- [ ] Log level filtering supported (show only WARN and above, etc.)

### Context and Detail
- [ ] Non-interactive logs include full context: file paths, versions, configurations
- [ ] Error messages include actionable information for automated retry logic
- [ ] No ambiguous messages like "something failed" - always include what failed
- [ ] Include relevant identifiers (file names, plugin names, workspace paths)

### Progress Logging in Non-Interactive Mode
- [ ] Milestone-based progress logging (every N files or every X%)
- [ ] Start/end logging for major operations
- [ ] Example: `[2026-02-10T14:30:10Z] [INFO] [SCAN] Milestone: 50/152 files processed (33%)`
- [ ] No in-place updates or cursor manipulation
- [ ] All log entries scroll normally

### Component Tagging
- [ ] Log entries tagged by component: INIT, SCAN, PLUGIN, WORKSPACE, TOOL, etc.
- [ ] Component tags consistent and documented
- [ ] Tags useful for filtering and monitoring specific subsystems
- [ ] Component tag width fixed (padded/truncated to consistent length)

### Integration with Existing Logging
- [ ] Enhance existing `log()` function to support structured format
- [ ] Backward compatible with existing log calls
- [ ] Automatic mode detection integration (uses `IS_INTERACTIVE` variable)
- [ ] Verbose mode (`-v` flag) increases detail in both interactive and non-interactive modes

### Summary and Exit Logging
- [ ] Final summary logged at end of execution
- [ ] Summary includes: files processed, files skipped, plugins executed, duration
- [ ] Exit code logged explicitly
- [ ] Example: `[2026-02-10T14:42:34Z] [INFO] [MAIN] Analysis complete: 152 files processed, 3 skipped, 149 reports generated`
- [ ] Example: `[2026-02-10T14:42:34Z] [INFO] [MAIN] Exit code: 0`

## Technical Considerations

### Implementation
```bash
# Structured logging function
log() {
  local level="$1"
  local component="${2:-MAIN}"
  local message="$3"
  
  # If only 2 args, assume component is omitted
  if [[ -z "$message" ]]; then
    message="$component"
    component="MAIN"
  fi
  
  # Check log level filtering (if implemented)
  if ! should_log_level "${level}"; then
    return
  fi
  
  # Format based on mode
  if [[ "${IS_INTERACTIVE}" == "true" ]]; then
    # Interactive: human-friendly format
    log_interactive "${level}" "${message}"
  else
    # Non-interactive: structured format
    log_structured "${level}" "${component}" "${message}"
  fi
}

# Structured format for non-interactive
log_structured() {
  local level="$1"
  local component="$2"
  local message="$3"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Fixed-width component tag (8 chars, right-padded)
  local component_formatted=$(printf "%-8s" "${component}")
  
  printf "[%s] [%-5s] [%s] %s\n" "${timestamp}" "${level}" "${component_formatted}" "${message}"
}

# Human-friendly format for interactive
log_interactive() {
  local level="$1"
  local message="$2"
  
  case "${level}" in
    ERROR)
      echo -e "\033[31m[ERROR]\033[0m ${message}"  # Red
      ;;
    WARN)
      echo -e "\033[33m[WARN]\033[0m ${message}"   # Yellow
      ;;
    INFO)
      echo "${message}"  # No prefix for INFO in interactive
      ;;
    DEBUG)
      if [[ "${VERBOSE}" == "true" ]]; then
        echo "[DEBUG] ${message}"
      fi
      ;;
  esac
}

# Log level filtering
should_log_level() {
  local level="$1"
  
  # DEBUG only shown in verbose mode
  if [[ "${level}" == "DEBUG" ]] && [[ "${VERBOSE}" != "true" ]]; then
    return 1
  fi
  
  return 0
}
```

### Progress Milestones
```bash
# Log progress milestones in non-interactive mode
log_progress_milestone() {
  local processed="$1"
  local total="$2"
  local percent=$(( processed * 100 / total ))
  
  # Log every 10% or every 50 files
  if (( processed % 50 == 0 )) || (( percent % 10 == 0 )); then
    log "INFO" "SCAN" "Milestone: ${processed}/${total} files processed (${percent}%)"
  fi
}

# Usage
for file in "${files[@]}"; do
  process_file "${file}"
  ((processed++))
  
  if [[ "${IS_INTERACTIVE}" == "true" ]]; then
    show_progress "${percent}" "${processed}" "${total}" "${skipped}" "${file}" "${plugin}"
  else
    log_progress_milestone "${processed}" "${total}"
  fi
done
```

### Error Context Logging
```bash
# Rich error logging with context
log_error_with_context() {
  local operation="$1"
  local error_message="$2"
  shift 2
  local context=("$@")
  
  log "ERROR" "${operation}" "${error_message}"
  
  # Log context details
  for ctx in "${context[@]}"; do
    log "ERROR" "${operation}" "  Context: ${ctx}"
  done
}

# Usage
log_error_with_context "PLUGIN" "Failed to execute plugin" \
  "Plugin: ocrmypdf" \
  "File: /path/to/document.pdf" \
  "Exit code: 1" \
  "Stderr: Permission denied"
```

### Component Tags
Standardized component tags:
- `INIT` - Initialization and mode detection
- `SCAN` - Directory scanning and file discovery
- `PLUGIN` - Plugin loading and execution
- `WORKSPACE` - Workspace operations and migrations
- `TOOL` - Tool verification and installation
- `TEMPLATE` - Template engine operations
- `REPORT` - Report generation
- `MAIN` - Main orchestration and general operations

## Dependencies
- **feature_0016** (Mode Detection) - Must know mode to choose log format
- Date/time utilities for ISO 8601 timestamps

## Estimated Effort
Medium (3-4 hours) - Refactor existing logging, add structured format, testing

## Notes
- Existing log calls throughout codebase may need updates for component tagging
- Consider log rotation strategy for long-running or frequently scheduled tasks
- Structured logs should be parseable by common tools (jq, grep, awk, log aggregators)
- Future enhancement: JSON-formatted logs for even better parsing

## Example Output Comparison

### Interactive Mode
```
Analyzing 152 files...
Processing document.pdf with ocrmypdf plugin
[WARN] Plugin ocrmypdf not installed, skipping
Analysis complete: 152 files processed
```

### Non-Interactive Mode
```
[2026-02-10T14:30:00Z] [INFO] [MAIN    ] Starting analysis of 152 files
[2026-02-10T14:30:00Z] [DEBUG][INIT    ] Running in non-interactive mode (automated)
[2026-02-10T14:30:00Z] [INFO] [SCAN    ] Discovered 152 files in /docs
[2026-02-10T14:30:05Z] [INFO] [PLUGIN  ] Processing file 1/152: document.pdf using ocrmypdf
[2026-02-10T14:30:05Z] [WARN] [TOOL    ] Plugin ocrmypdf not installed, skipping (non-interactive mode)
[2026-02-10T14:30:10Z] [INFO] [SCAN    ] Milestone: 50/152 files processed (33%)
[2026-02-10T14:42:34Z] [INFO] [MAIN    ] Analysis complete: 152 files processed, 3 skipped, 149 reports generated
[2026-02-10T14:42:34Z] [INFO] [MAIN    ] Exit code: 0
```

## Transition History
- [2026-02-10] Created by Requirements Engineer Agent - derived from req_0058 Non-Interactive Mode Behavior
- [2026-02-11] Moved from Backlog to Implementing - all acceptance criteria verified, dependencies satisfied (feature_0016 done)
- [2026-02-12] Moved from Implementing to Done - implementation complete, all tests pass

## Implementation Details

- **Files Modified**: `scripts/components/core/logging.sh`
- **Files Created**: `tests/unit/test_structured_logging.sh`
- **Architecture review**: IDR-0017 (APPROVED)
- **Security review**: `07_interactive_mode_security.md` (APPROVED, F5 addressed: log injection prevention)
