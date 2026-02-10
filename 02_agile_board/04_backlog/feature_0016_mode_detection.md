# Feature: Interactive/Non-Interactive Mode Detection

**ID**: 0016  
**Type**: Feature Implementation  
**Status**: Backlog  
**Created**: 2026-02-10  
**Updated**: 2026-02-10 (Moved to backlog - approved by architect review)  
**Priority**: High

## Overview
Implement system to detect whether the toolkit is running in interactive mode (user at terminal) or non-interactive mode (scripts, cron, CI/CD) and store this state for behavioral adaptation throughout execution.

## Description
Create the mode detection subsystem that determines execution context by testing terminal attachment using POSIX tests (`[ -t 0 ] && [ -t 1 ]`). This detection runs early in script initialization and stores the result in a global variable accessible throughout the toolkit. The mode determines whether the system should prompt users, display live progress, or operate completely automatically with logging-based feedback.

This is a foundational feature that enables all mode-aware behaviors: user prompts only appear in interactive mode, progress displays adapt based on context, error messages adjust their format and detail level, and logging behavior varies between human-friendly and machine-parseable formats.

## Business Value
- Enables toolkit to run unattended in automated environments (cron, CI/CD) without hanging on prompts
- Provides rich user experience when run interactively with feedback and control
- Critical for automation use cases (scheduled analysis, pipeline integration)
- Prevents system hangs and mysterious failures in non-interactive contexts
- Foundation for all mode-adaptive features

## Related Requirements
- [req_0057](../../01_vision/02_requirements/03_accepted/req_0057_interactive_mode_behavior.md) - Interactive Mode Behavior
- [req_0058](../../01_vision/02_requirements/03_accepted/req_0058_non_interactive_mode_behavior.md) - Non-Interactive Mode Behavior (PRIMARY)
- [req_0045](../../01_vision/02_requirements/04_obsolete/req_0045_non_interactive_mode_handling.md) - Obsoleted parent requirement

## Acceptance Criteria

### Mode Detection
- [ ] System detects interactive mode by testing if stdin is a terminal (`[ -t 0 ]`)
- [ ] System detects interactive mode by testing if stdout is a terminal (`[ -t 1 ]`)
- [ ] Both stdin and stdout must be terminals for interactive mode (logical AND)
- [ ] Mode detection performed early in script execution (before any prompts or user-facing output)
- [ ] Mode stored in global variable accessible throughout script (`IS_INTERACTIVE=true/false`)

### Environment Variable Override
- [ ] System supports `DOC_DOC_INTERACTIVE` environment variable to force mode
- [ ] `DOC_DOC_INTERACTIVE=true` forces interactive mode regardless of terminal detection
- [ ] `DOC_DOC_INTERACTIVE=false` forces non-interactive mode regardless of terminal detection
- [ ] Environment variable override takes precedence over automatic detection
- [ ] Override useful for testing and explicit control scenarios

### Logging and Visibility
- [ ] Verbose mode logs detected mode at startup ("Running in interactive mode" or "Running in non-interactive mode")
- [ ] Log message includes whether mode was auto-detected or forced via environment variable
- [ ] Debug mode logs both stdin and stdout terminal test results

### Integration Points
- [ ] Mode detection function callable from anywhere in script
- [ ] Global `IS_INTERACTIVE` variable accessible to all components
- [ ] Mode detection result available to logging system for format decisions
- [ ] Mode detection result available to prompt system for behavior decisions
- [ ] Mode detection result available to progress display for format decisions

### Testing Support
- [ ] Mode detection can be tested by setting environment variable
- [ ] Test suite includes tests for both interactive and non-interactive detection
- [ ] Mock/simulation of terminal attachment testable
- [ ] CI/CD pipeline validates non-interactive mode detection works correctly

## Technical Considerations

### Implementation
```bash
# Early in script initialization
detect_interactive_mode() {
  # Check for environment variable override first
  if [[ -n "${DOC_DOC_INTERACTIVE}" ]]; then
    IS_INTERACTIVE="${DOC_DOC_INTERACTIVE}"
    log "DEBUG" "INIT" "Interactive mode forced via environment: ${IS_INTERACTIVE}"
    return
  fi
  
  # Auto-detect based on terminal attachment
  if [ -t 0 ] && [ -t 1 ]; then
    IS_INTERACTIVE=true
    log "DEBUG" "INIT" "Running in interactive mode (terminal detected)"
  else
    IS_INTERACTIVE=false
    log "DEBUG" "INIT" "Running in non-interactive mode (no terminal)"
  fi
}

# Call during initialization
detect_interactive_mode

# Export for use by child processes if needed
export IS_INTERACTIVE
```

### Usage Pattern
```bash
# Throughout the codebase
if [[ "${IS_INTERACTIVE}" == "true" ]]; then
  # Interactive behavior: prompts, live progress, colors
  show_live_progress "${processed}" "${total}"
else
  # Non-interactive behavior: automatic, logging-based
  log "INFO" "SCAN" "Processed ${processed}/${total} files"
fi
```

### Edge Cases
- Piped input/output (`echo "data" | ./doc.doc.sh`)
- Redirected output (`./doc.doc.sh > output.log`)
- Background processes (`./doc.doc.sh &`)
- SSH sessions (usually treated as interactive if terminal allocated)
- Screen/tmux sessions (treated as interactive)
- IDE integrated terminals (usually interactive)

## Dependencies
- Requires logging system to be initialized for debug output
- Must run before any user-facing prompts or progress displays
- Core utility loaded before other components

## Estimated Effort
Small (1-2 hours) - Simple detection logic, straightforward implementation

## Notes
- This is a foundational feature - many other features depend on it
- Mode detection should happen as early as possible in script lifecycle
- Consider adding mode indicator to help/version output for transparency

## Transition History
- [2026-02-10] Created by Requirements Engineer Agent - derived from req_0057 and req_0058
