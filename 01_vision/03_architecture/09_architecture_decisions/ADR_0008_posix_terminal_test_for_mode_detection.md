# ADR-0008: POSIX Terminal Test for Mode Detection

**ID**: ADR-0008  
**Status**: Accepted  
**Created**: 2026-02-10  
**Last Updated**: 2026-02-10

## Context

The system must operate in two distinct contexts:
1. **Interactive mode**: User at terminal, expects rich UX (prompts, progress bars, colors)
2. **Non-interactive mode**: Automated execution (cron, CI/CD), requires non-blocking operation

Failure to detect and adapt to execution context causes:
- Scripts hanging indefinitely on prompts in automation
- Unreadable ANSI escape codes in log files
- Mysterious failures in cron jobs without clear diagnostics

Requirements [req_0057](../../02_requirements/03_accepted/req_0057_interactive_mode_behavior.md) and [req_0058](../../02_requirements/03_accepted/req_0058_non_interactive_mode_behavior.md) mandate mode-aware behavior.

Quality goal **Reliability R1** explicitly requires successful cron job execution without hangs.

## Decision

Use POSIX standard terminal tests (`[ -t 0 ] && [ -t 1 ]`) to detect interactive mode, requiring both stdin AND stdout to be terminals for interactive classification. Store detection result in global `IS_INTERACTIVE` variable accessible throughout execution. Support `DOC_DOC_INTERACTIVE` environment variable override for testing and explicit control.

## Rationale

**Why POSIX Terminal Tests (`-t` operator)**:

✅ **Standard**: POSIX sh standard, works across bash, zsh, dash, ksh  
✅ **Reliable**: Direct kernel check via `isatty()` system call  
✅ **Accurate**: Correctly identifies pipes, redirects, background processes  
✅ **Fast**: No external process execution, nanosecond-level overhead  
✅ **Portable**: Works on Linux, macOS, BSD, WSL without modification  

**Why Both stdin AND stdout Required**:

Interactive mode means the user can both provide input AND see output directly. Examples:
- `./doc.doc.sh` - Both terminal: **Interactive** ✅
- `./doc.doc.sh > file.log` - stdout redirected: **Non-Interactive** ❌ (output not visible to user)
- `echo "" | ./doc.doc.sh` - stdin redirected: **Non-Interactive** ❌ (cannot accept user input)
- `./doc.doc.sh &` - Background: **Non-Interactive** ❌ (no terminal attachment)

Requiring both prevents:
- Prompting when output goes to log file (user can't see prompt)
- Displaying progress bars when output is piped (causes corruption)

**Why Global Variable (`IS_INTERACTIVE`)**:

- Central detection point early in initialization
- All components access same detection result (consistency)
- No repeated detection overhead (detect once, use many times)
- Simple boolean check throughout codebase

**Why Environment Variable Override**:

- **Testing**: Force mode in automated tests without terminal simulation
- **Explicit Control**: Users can override auto-detection when needed (rare)
- **Debugging**: Reproduce interactive behavior in non-interactive context
- **CI/CD**: Force non-interactive even if terminal emulation present

## Alternatives Considered

### Check Only stdin (`[ -t 0 ]`)
```bash
if [ -t 0 ]; then
  IS_INTERACTIVE=true
fi
```

- ✅ Simple single check
- ❌ Fails when output redirected: `./doc.doc.sh > log` still prompts (bad)
- ❌ Progress bars corrupt log files
- **Decision**: Insufficient - must check both streams

### Check Only stdout (`[ -t 1 ]`)
```bash
if [ -t 1 ]; then
  IS_INTERACTIVE=true
fi
```

- ✅ Simple single check
- ❌ Fails when input piped: `echo "" | ./doc.doc.sh` tries to prompt (hangs)
- ❌ Cannot read user responses
- **Decision**: Insufficient - must check both streams

### Check stdin OR stdout (Logical OR)
```bash
if [ -t 0 ] || [ -t 1 ]; then
  IS_INTERACTIVE=true
fi
```

- ✅ More permissive
- ❌ `./doc.doc.sh > log` is interactive (wrong - can't see output)
- ❌ `echo "" | ./doc.doc.sh` is interactive (wrong - can't read input)
- **Decision**: Too permissive - causes same issues as partial checks

### Check `$TERM` Environment Variable
```bash
if [[ -n "${TERM}" ]] && [[ "${TERM}" != "dumb" ]]; then
  IS_INTERACTIVE=true
fi
```

- ✅ Indicates terminal emulator present
- ❌ `$TERM` set even in redirected contexts: `TERM=xterm ./doc.doc.sh > log`
- ❌ Cron jobs may inherit `$TERM` from user environment
- ❌ False positives common
- **Decision**: Unreliable - `$TERM` doesn't indicate actual attachment

### Read from `/proc/self/fd/0` and `/proc/self/fd/1`
```bash
if [[ -t /proc/self/fd/0 ]] && [[ -t /proc/self/fd/1 ]]; then
  IS_INTERACTIVE=true
fi
```

- ✅ Explicit file descriptor check
- ❌ `/proc` not available on macOS (Linux-specific)
- ❌ More verbose than `-t` operator
- ❌ No advantage over POSIX `-t`
- **Decision**: Non-portable, unnecessary complexity

### Check Parent Process (`ps -o comm= -p $PPID`)
```bash
parent=$(ps -o comm= -p $PPID)
if [[ "$parent" =~ ^(bash|zsh|fish|sh)$ ]]; then
  IS_INTERACTIVE=true
fi
```

- ✅ Detects shell parent
- ❌ Heuristic, not definitive (shell doesn't mean user present)
- ❌ Fails for: cron (no shell parent), systemd (no shell), wrapper scripts
- ❌ Race condition (parent may exit during check)
- ❌ Requires external `ps` command (overhead)
- **Decision**: Unreliable heuristic, fails in automation

### Configuration File Setting (`~/.doc.doc.rc`)
```bash
source ~/.doc.doc.rc
# User sets: INTERACTIVE_MODE=true
```

- ✅ Explicit user control
- ❌ Requires users to configure (friction)
- ❌ Wrong default causes hangs until user configures
- ❌ Different machines need different configs
- ❌ Cron vs. interactive need different configs for same user
- **Decision**: Too much user burden, not automatic

### Always Interactive (Prompt with Timeout)
```bash
read -t 10 -p "Continue? [Y/n] " response
# Timeout = auto-yes
```

- ✅ No detection needed
- ❌ 10-second delay on every decision in automation (unacceptable)
- ❌ Accumulates: 5 decisions = 50 seconds wasted
- ❌ Still produces prompt text in logs (ugly)
- **Decision**: Terrible UX for automation

### Always Non-Interactive (No Prompts Ever)
```bash
# Never prompt, always use defaults
```

- ✅ Simple, no mode detection
- ❌ Poor interactive UX (no user control)
- ❌ Violates req_0057 (interactive mode behavior)
- ❌ Tool installation decisions auto-applied (surprise)
- **Decision**: Unacceptable for interactive users

## Consequences

### Positive

✅ **Reliable Detection**: Terminal tests are definitive, not heuristic  
✅ **No False Positives**: Correctly identifies all non-interactive contexts  
✅ **Zero Overhead**: Native shell operator, no external commands  
✅ **Portable**: Works across all POSIX-compliant shells and platforms  
✅ **Testable**: Environment variable override enables automated testing  
✅ **Consistent**: Single detection result used throughout execution  
✅ **Fail-Safe**: Detection failure defaults to non-interactive (safe)  

### Negative

❌ **Global State**: `IS_INTERACTIVE` variable is global (mitigated: read-only after detection)  
❌ **Detection Timing**: Must detect before any output (mitigated: detect in initialization)  
❌ **SSH Edge Cases**: SSH with/without PTY allocation requires careful testing  

### Risks

**Risk 1: Component Bypasses Mode Check**
- **Scenario**: Developer adds blocking prompt without checking `IS_INTERACTIVE`
- **Impact**: Script hangs in automation
- **Mitigation**: Code review guidelines, automated tests in non-interactive mode, linting rules

**Risk 2: False Classification**
- **Scenario**: Unusual terminal emulation confuses detection
- **Impact**: Wrong behavior for user's context
- **Mitigation**: Environment variable override provides escape hatch, testing across platforms

**Risk 3: Mode Change During Execution**
- **Scenario**: User backgrounds process with Ctrl+Z after starting interactively
- **Impact**: Mode state no longer accurate
- **Mitigation**: Acceptable - mode determined at startup, not re-detected (common practice)

## Implementation Notes

### Detection Implementation

```bash
# core/mode_detection.sh

# Global variable (read-only after initialization)
IS_INTERACTIVE=false

# Detect interactive mode
# Must be called before any user-facing output
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
  
  # Make read-only to prevent accidental modification
  readonly IS_INTERACTIVE
}

# Export for use by child processes if needed
export IS_INTERACTIVE
```

### Usage Pattern

```bash
# All components check mode before behavior choice
if [[ "${IS_INTERACTIVE}" == "true" ]]; then
  # Interactive: prompts, live progress, colors
  show_live_progress "${current}" "${total}"
else
  # Non-interactive: automatic, logging-based
  log_progress_milestone "${current}" "${total}"
fi
```

### Testing

```bash
# Test non-interactive behavior
DOC_DOC_INTERACTIVE=false ./run_tests.sh

# Test interactive behavior (even without terminal)
DOC_DOC_INTERACTIVE=true ./run_tests.sh

# CI/CD ensures non-interactive mode by default
# (no terminal attached to CI runners)
```

## Related Items

- [req_0057](../../02_requirements/03_accepted/req_0057_interactive_mode_behavior.md) - Interactive Mode Behavior
- [req_0058](../../02_requirements/03_accepted/req_0058_non_interactive_mode_behavior.md) - Non-Interactive Mode Behavior
- [08_0010_mode_aware_behavior](../08_concepts/08_0010_mode_aware_behavior.md) - Mode-Aware Behavior Concept
- [feature_0016](../../../02_agile_board/01_funnel/feature_0016_mode_detection.md) - Mode Detection Feature
- Quality Goal R1 (Cron Job Execution)
