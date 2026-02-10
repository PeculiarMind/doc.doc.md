---
title: Mode-Aware Behavior Concept
arc42-chapter: 8
---

## 0010 Mode-Aware Behavior Concept

## Table of Contents

- [Purpose](#purpose)
- [Rationale](#rationale)
- [Mode Detection Strategy](#mode-detection-strategy)
- [Behavioral Adaptations by Mode](#behavioral-adaptations-by-mode)
- [Component Integration Pattern](#component-integration-pattern)
- [Implementation Guidelines](#implementation-guidelines)
- [Mode Override and Testing](#mode-override-and-testing)
- [Related Requirements](#related-requirements)

The system adapts its behavior based on execution context (interactive vs. non-interactive) to provide optimal user experience when run manually and reliable unattended operation when automated.

### Purpose

Mode-aware behavior enables the system to:
- **Provide Rich UX**: When user is present, show live progress, colors, prompts for control
- **Enable Automation**: When running unattended, operate without blocking, use structured logs, apply sensible defaults
- **Prevent Hangs**: Avoid blocking on user input in scripts, cron jobs, CI/CD pipelines
- **Maintain Quality**: Ensure reliability quality goal R1 (cron job execution) is met
- **Support Both Contexts**: Single codebase serves both interactive and automated use cases

### Rationale

**Dual Use Case Requirements**:
- **Interactive Users**: Expect immediate feedback, live progress, ability to intervene, helpful prompts
- **Automated Systems**: Require non-blocking execution, machine-parseable logs, predictable exit codes, no user interaction
- **Single Binary**: Maintaining separate versions would create maintenance burden and drift

**Quality Goals Alignment**:
- **Reliability R1**: Cron job execution requires zero user interaction, must complete autonomously
- **Usability U1**: Interactive users benefit from rich feedback and control
- **Efficiency E3**: Progress visibility helps users understand performance in interactive mode

**Technical Reality**:
- Terminal attachment (`-t` test) is reliable indicator of execution context
- Bash scripts can detect terminal presence using POSIX standard tests
- Behavioral adaptation is common pattern in mature CLI tools (git, docker, npm)

### Mode Detection Strategy

**Detection Algorithm**:

```bash
# Detect interactive mode early in initialization
detect_interactive_mode() {
  # Check for environment variable override first
  if [[ -n "${DOC_DOC_INTERACTIVE}" ]]; then
    IS_INTERACTIVE="${DOC_DOC_INTERACTIVE}"
    log "DEBUG" "INIT" "Interactive mode forced via environment: ${IS_INTERACTIVE}"
    return
  fi
  
  # Auto-detect based on terminal attachment
  # Both stdin AND stdout must be terminals for interactive mode
  if [ -t 0 ] && [ -t 1 ]; then
    IS_INTERACTIVE=true
  else
    IS_INTERACTIVE=false
  fi
  
  log "DEBUG" "INIT" "Mode detection: interactive=${IS_INTERACTIVE}"
}
```

**Detection Criteria**:
- **Interactive Mode**: Both stdin (`-t 0`) and stdout (`-t 1`) are connected to terminals
- **Non-Interactive Mode**: Either stdin or stdout is NOT a terminal (pipes, redirects, background processes)

**Environment Override**: `DOC_DOC_INTERACTIVE=true|false` forces mode for testing or explicit control

**Examples**:
```bash
# Interactive (both stdin/stdout are terminal)
$ ./doc.doc.sh -d ./docs -t ./reports

# Non-interactive (stdout redirected)
$ ./doc.doc.sh -d ./docs -t ./reports > output.log

# Non-interactive (stdin redirected)
$ echo "" | ./doc.doc.sh -d ./docs -t ./reports

# Non-interactive (cron job, no terminal attached)
0 2 * * * /opt/doc.doc/scripts/doc.doc.sh -d /data -t /reports

# Non-interactive (CI/CD pipeline)
RUN ./doc.doc.sh -d . -t reports/

# Forced interactive (testing)
$ DOC_DOC_INTERACTIVE=true ./doc.doc.sh -d ./docs -t ./reports
```

### Behavioral Adaptations by Mode

#### User Interaction

| Behavior | Interactive Mode | Non-Interactive Mode |
|----------|------------------|----------------------|
| **User Prompts** | Display yes/no confirmations for optional operations | Never prompt - use default or fail with clear error |
| **Tool Installation** | Prompt user "Install missing tool X? [y/N]" | Log warning, skip plugin, continue analysis |
| **Migration Decisions** | Prompt user "Migrate workspace? [Y/n]" | Auto-migrate if safe, fail if breaking change |
| **Error Recovery** | Prompt user for action or retry | Apply default recovery strategy or fail |

**Example**: Missing optional tool (ocrmypdf)
- **Interactive**: `"Tool ocrmypdf not found. Install? [y/N]"` → User decides
- **Non-Interactive**: `"[WARN] [TOOL] ocrmypdf not found, skipping plugin"` → Automatic skip

#### Progress Reporting

| Aspect | Interactive Mode | Non-Interactive Mode |
|--------|------------------|----------------------|
| **Display Format** | Live progress bar with in-place updates | Milestone-based discrete log entries |
| **Update Strategy** | Update in place using ANSI codes | New log line for each milestone |
| **Progress Bar** | 40-char bar: `████████░░░░░░░░ 42%` | No progress bar |
| **File Counter** | Live: "Files processed: 64/152" | Periodic: "Milestone: 50/152 (33%)" |
| **Current Context** | Show current file and plugin | Log at transition points only |
| **Scrolling** | Updates in place (no scrolling) | All output scrolls normally |

**Example**: Processing 152 files

**Interactive**:
```
Progress: ████████████████░░░░░░░░░░░░░░░░░░░░░░░░ 42%
Files processed: 64/152
Files skipped: 3
Processing: documents/reports/quarterly_review_2025.pdf
Executing plugin: ocrmypdf
```

**Non-Interactive**:
```
[2026-02-10T14:30:00Z] [INFO] [MAIN] Starting analysis of 152 files
[2026-02-10T14:30:10Z] [INFO] [SCAN] Milestone: 50/152 files processed (33%)
[2026-02-10T14:30:20Z] [INFO] [SCAN] Milestone: 100/152 files processed (66%)
[2026-02-10T14:42:34Z] [INFO] [MAIN] Analysis complete: 152 processed, 3 skipped
```

#### Logging Format

| Aspect | Interactive Mode | Non-Interactive Mode |
|--------|------------------|----------------------|
| **Timestamps** | Optional (verbose mode only) | Always included (ISO 8601 UTC) |
| **Format** | Human-friendly, concise | Structured, machine-parseable |
| **Component Tags** | Optional | Always included (fixed-width) |
| **Colors** | ANSI colors for emphasis | No colors |
| **Detail Level** | Concise messages | Full context (paths, versions, conditions) |
| **Error Messages** | User-facing suggestions | Actionable for automated retry logic |

**Example**: Plugin execution failure

**Interactive**:
```
[ERROR] Failed to execute plugin 'ocrmypdf'
Try installing ocrmypdf: apt install ocrmypdf
```

**Non-Interactive**:
```
[2026-02-10T14:30:15Z] [ERROR] [PLUGIN] Failed to execute plugin
[2026-02-10T14:30:15Z] [ERROR] [PLUGIN]   Plugin: ocrmypdf
[2026-02-10T14:30:15Z] [ERROR] [PLUGIN]   File: /data/documents/report.pdf
[2026-02-10T14:30:15Z] [ERROR] [PLUGIN]   Exit code: 127
[2026-02-10T14:30:15Z] [ERROR] [PLUGIN]   Error: command not found
```

#### Output Formatting

| Aspect | Interactive Mode | Non-Interactive Mode |
|--------|------------------|----------------------|
| **Help Messages** | Word-wrapped for readability | Fixed width (80 columns) |
| **Error Display** | Colored, emphasized | Plain text, structured |
| **Summary Output** | Friendly: "Analysis complete! 152 files processed." | Structured: `"[INFO] [MAIN] Analysis complete: 152 processed, 3 skipped, exit_code=0"` |

### Component Integration Pattern

**Mandatory Pattern for All Components**:

Every component that produces user-facing output or requires decisions MUST check mode before choosing behavior:

```bash
# Pattern: Check mode before behavior
if [[ "${IS_INTERACTIVE}" == "true" ]]; then
  # Interactive behavior: prompts, live progress, colors
  show_live_progress "${processed}" "${total}"
else
  # Non-interactive behavior: automatic, logging-based
  log_progress_milestone "${processed}" "${total}"
fi
```

**Components Affected**:

1. **core/logging.sh**: Format logs based on mode
2. **ui/argument_parser.sh**: Error messages adapt to mode
3. **ui/help_system.sh**: Output format adapts to mode
4. **ui/progress_display.sh**: Only activates in interactive mode
5. **ui/prompt_system.sh**: Only prompts in interactive mode
6. **plugin/plugin_discovery.sh**: Tool installation decision based on mode
7. **plugin/plugin_executor.sh**: Progress reporting based on mode
8. **orchestration/scanner.sh**: Progress updates based on mode
9. **orchestration/report_generator.sh**: Status output based on mode

### Implementation Guidelines

**Component Requirements**:

1. **Early Detection**: Mode detection MUST occur before any user-facing output
2. **Global Access**: `IS_INTERACTIVE` variable MUST be accessible to all components
3. **Default Behavior**: If mode detection fails, default to non-interactive (fail-safe)
4. **No Assumptions**: Never assume terminal capabilities, always check mode first
5. **Test Both Modes**: All features MUST be tested in both interactive and non-interactive modes

**Anti-Patterns to Avoid**:

❌ **Never**: Block on user input without checking mode
```bash
# BAD: Will hang in non-interactive mode
read -p "Continue? [y/n] " response
```

❌ **Never**: Use ANSI codes without checking mode
```bash
# BAD: Garbage characters in logs
echo -e "\033[32mSuccess\033[0m" | tee logfile.log
```

❌ **Never**: Assume terminal width or capabilities
```bash
# BAD: May not work in all contexts
tput cols  # Fails if not a terminal
```

✅ **Always**: Check mode before interactive behavior
```bash
# GOOD: Mode-aware prompting
if [[ "${IS_INTERACTIVE}" == "true" ]]; then
  read -p "Continue? [y/n] " response
else
  response="y"  # Default in non-interactive
  log "INFO" "MAIN" "Auto-continuing (non-interactive mode)"
fi
```

### Mode Override and Testing

**Environment Variable Override**:

```bash
# Force interactive mode (useful for testing)
export DOC_DOC_INTERACTIVE=true
./doc.doc.sh -d ./docs -t ./reports

# Force non-interactive mode (test automation behavior)
export DOC_DOC_INTERACTIVE=false
./doc.doc.sh -d ./docs -t ./reports
```

**Testing Requirements**:

1. **Unit Tests**: Test both code paths (interactive and non-interactive) for each component
2. **Integration Tests**: Verify mode detection works correctly in various contexts
3. **CI/CD Tests**: Run in non-interactive mode by default (simulates production automation)
4. **Interactive Tests**: Use mode override to test interactive features in automated tests

**Test Scenarios**:
- Terminal attached: `./doc.doc.sh` (interactive expected)
- Output redirected: `./doc.doc.sh > output.log` (non-interactive expected)
- Input from pipe: `echo "" | ./doc.doc.sh` (non-interactive expected)
- Background process: `./doc.doc.sh &` (non-interactive expected)
- Forced mode: `DOC_DOC_INTERACTIVE=true ./doc.doc.sh > output.log` (interactive despite redirect)

### Related Requirements

- [req_0057](../../02_requirements/03_accepted/req_0057_interactive_mode_behavior.md) - Interactive Mode Behavior
- [req_0058](../../02_requirements/03_accepted/req_0058_non_interactive_mode_behavior.md) - Non-Interactive Mode Behavior
- [req_0006](../../02_requirements/03_accepted/req_0006_verbose_logging_mode.md) - Verbose Logging Mode
- [req_0008](../../02_requirements/03_accepted/req_0008_installation_prompts.md) - Installation Prompts
- [req_0020](../../02_requirements/03_accepted/req_0020_error_handling.md) - Error Handling
- [req_0044](../../02_requirements/03_accepted/req_0044_workspace_format_migration.md) - Workspace Format Migration

**Features Implementing This Concept**:
- [feature_0016](../../../02_agile_board/01_funnel/feature_0016_mode_detection.md) - Mode Detection
- [feature_0017](../../../02_agile_board/01_funnel/feature_0017_interactive_progress_display.md) - Interactive Progress Display
- [feature_0018](../../../02_agile_board/01_funnel/feature_0018_user_prompt_system.md) - User Prompt System
- [feature_0019](../../../02_agile_board/01_funnel/feature_0019_structured_logging.md) - Structured Logging
