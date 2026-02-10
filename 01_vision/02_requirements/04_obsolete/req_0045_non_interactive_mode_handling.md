# Requirement: Non-Interactive Mode Detection and Handling

**ID**: req_0045

## Status
State: Obsolete  
Created: 2026-02-09  
Last Updated: 2026-02-10

**Obsoleted By**: req_0057 (Interactive Mode Behavior), req_0058 (Non-Interactive Mode Behavior)

## Overview
The system shall detect whether it is running in interactive or non-interactive mode and adjust behavior accordingly, particularly for prompts, confirmations, progress display, and error handling.

## Description
The CLI Interface Concept (08_0003) describes detecting interactive vs non-interactive mode and adapting behavior. When running interactively (user at terminal), the toolkit can prompt for missing tool installation, ask for migration confirmations, and display progress. When running non-interactively (cron jobs, scripts, CI/CD), prompts would block indefinitely, so the system must use sensible defaults, log instead of prompt, and fail gracefully with clear error messages. Detection uses standard POSIX test for terminal attachment (`[ -t 0 ]` for stdin, `[ -t 1 ]` for stdout). Non-interactive mode behavior prioritizes automation-friendly operation: no prompts, machine-readable output options, predictable exit codes, and comprehensive logging.

## Motivation
From CLI Interface Concept (08_0003_cli_interface_concept.md):
```bash
is_interactive() {
  [ -t 0 ] && [ -t 1 ]  # stdin and stdout are terminals
}

if is_interactive; then
  read -p "Install missing tool? [y/N] " response
else
  log "WARN" "CLI" "Tool not available, skipping plugin"
fi
```

From quality scenario R1: "Scheduled task (cron) triggers analysis, runs automatically at 2 AM daily, executes without hangs, completes with exit code 0."

Unattended operation is a core use case. Without proper non-interactive handling, cron jobs would hang on prompts or fail mysteriously.

## Category
- Type: Functional
- Priority: Medium

## Acceptance Criteria

### Mode Detection
- [ ] System detects interactive mode by testing if stdin is a terminal (`[ -t 0 ]`)
- [ ] System detects interactive mode by testing if stdout is a terminal (`[ -t 1 ]`)
- [ ] Both stdin and stdout must be terminals for interactive mode (logical AND)
- [ ] Mode detection performed early in script execution (before any prompts)
- [ ] Mode stored in global variable (e.g., `IS_INTERACTIVE=true/false`)
- [ ] Verbose mode logs detected mode ("Running in interactive mode" or "Running in non-interactive mode")

### Interactive Mode Behavior
- [ ] Missing tool installation prompts user for confirmation
- [ ] Workspace migration prompts user for confirmation if migration is complex
- [ ] **Live progress display** shows real-time execution status (updated in place)
- [ ] Progress indicators displayed for long-running operations (dynamic counters, not scrolling logs)
- [ ] Errors include suggestions for user action ("Try installing X with: apt install X")
- [ ] Help messages formatted for human readability (word wrapping, colors acceptable)

### Interactive Mode Live Progress Display
- [ ] Progress display updates in place without scrolling (using carriage return `\r` or ANSI cursor control)
- [ ] **Progress bar displayed**: 40-character bar that fills as processing advances
- [ ] **Progress percentage centered in bar**: Percentage value (0-100%) displayed in the center of the progress bar
- [ ] Progress bar uses filled characters for completed portion and empty characters for remaining portion
- [ ] Progress includes count of files processed (incrementing counter)
- [ ] Progress includes count of files skipped (incrementing counter when applicable)
- [ ] Progress displays currently processed file path (truncated if needed to fit terminal width)
- [ ] Progress displays currently executing plugin name
- [ ] Progress format consistent and easy to read at a glance
- [ ] Progress display clears or finalizes when analysis completes
- [ ] Progress display updates at reasonable frequency (not per-byte, but per-file or per-plugin)
- [ ] Terminal width detection used to prevent line wrapping in progress display

**Example Progress Display Format:**
```
Progress: ████████████████░░░░░░░░░░░░░░░░░░░░░░░░ 42%
Files processed: 64/152
Files skipped: 3
Processing: documents/reports/quarterly_review_2025.pdf
Executing plugin: ocrmypdf
```

### Non-Interactive Mode Behavior
- [ ] No prompts or user input requests (all operations automatic or fail)
- [ ] Missing tools logged as warnings, plugins skipped without prompting
- [ ] Workspace migrations auto-applied for minor versions, fail for major versions requiring confirmation
- [ ] Progress indicators suppressed (or limited to periodic log entries)
- [ ] Errors include actionable information for automated retry logic
- [ ] Output format consistent and parseable (no ANSI colors, predictable structure)

### Defaults for Non-Interactive
- [ ] Missing optional tools: skip associated plugins, continue analysis
- [ ] Minor workspace migration: apply automatically, log migration
- [ ] Major workspace migration: fail with clear error, do not prompt
- [ ] Target/workspace directory creation: create automatically if possible
- [ ] Invalid arguments: fail immediately with exit code, do not prompt for correction

### Logging Differences
- [ ] Interactive mode: concise user-facing messages ("Analyzing 152 files...")
- [ ] Non-interactive mode: detailed logging for audit trail ("2026-02-09T14:30:00Z [INFO] Starting analysis of 152 files")
- [ ] Non-interactive mode logs include timestamps for all messages
- [ ] Non-interactive mode logs structured for parsing (consistent format)

### Error Handling
- [ ] Interactive mode errors suggest next steps for user
- [ ] Non-interactive mode errors include full context (paths, versions, conditions)
- [ ] Exit codes consistent and documented regardless of mode
- [ ] Non-interactive mode never exits with ambiguous "something failed" error

### Testing Support
- [ ] Mode detection can be overridden for testing (`FORCE_INTERACTIVE=true/false`)
- [ ] Test suite includes tests for both interactive and non-interactive behavior
- [ ] CI/CD pipelines test non-interactive mode exclusively

## Related Requirements
- **req_0057 (Interactive Mode Behavior)** - replacement requirement for interactive mode
- **req_0058 (Non-Interactive Mode Behavior)** - replacement requirement for non-interactive mode
- req_0008 (Installation Prompts) - prompts only in interactive mode
- req_0044 (Workspace Format Migration) - migration prompts only in interactive mode
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

# Usage throughout code
if [[ "${IS_INTERACTIVE}" == "true" ]]; then
  # Interactive behavior
  read -p "Install missing tool? [y/N] " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    install_tool
  fi
else
  # Non-interactive behavior
  log "WARN" "Tool not available, skipping plugin (non-interactive mode)"
fi
```

### Live Progress Display Implementation (Interactive Mode)
```bash
# Progress bar rendering function
render_progress_bar() {
  local percent="$1"
  local bar_width=40
  local filled_width=$(( percent * bar_width / 100 ))
  local empty_width=$(( bar_width - filled_width ))
  
  # Build the progress bar
  local filled=$(printf '%*s' "$filled_width" '' | tr ' ' '█')
  local empty=$(printf '%*s' "$empty_width" '' | tr ' ' '░')
  local bar="${filled}${empty}"
  
  # Insert percentage in the center of the bar
  local percent_str=$(printf "%3d%%" "$percent")
  local center_pos=$(( (bar_width - 4) / 2 ))
  local bar_with_percent="${bar:0:$center_pos}${percent_str}${bar:$((center_pos+4))}"
  
  printf "[%s]" "$bar_with_percent"
}

# Progress display function
show_progress() {
  local percent="$1"
  local processed="$2"
  local total="$3"
  local skipped="$4"
  local current_file="$5"
  local current_plugin="$6"
  
  # Only display in interactive mode
  if [[ "${IS_INTERACTIVE}" != "true" ]]; then
    return
  fi
  
  # Clear previous display and show progress
  printf "\r\033[K"  # Clear line
  printf "%s\n" "$(render_progress_bar "${percent}")"
  printf "Files processed: %d/%d\n" "${processed}" "${total}"
  printf "Files skipped: %d\n" "${skipped}"
  printf "Processing: %s\n" "${current_file}"
  printf "Executing plugin: %s" "${current_plugin}"
  printf "\033[5A"  # Move cursor up 5 lines for next update
}

# Clear progress display when done
clear_progress() {
  if [[ "${IS_INTERACTIVE}" == "true" ]]; then
    printf "\r\033[K\033[4B\n"  # Clear and move down
  fi
}

# Usage in main analysis loop
for file in "${files[@]}"; do
  percent=$(( processed * 100 / total ))
  show_progress "${percent}" "${processed}" "${total}" "${skipped}" "${file}" "${plugin_name}"
  
  # Actual processing...
  process_file "${file}"
  
  ((processed++))
done

clear_progress
echo "Analysis complete: ${processed} files processed"
```

### Prompt vs Log Decision Matrix

| Scenario | Interactive | Non-Interactive |
|----------|-------------|-----------------|
| Missing optional tool | Prompt to install | Log warning, skip plugin |
| Minor workspace migration | Auto-migrate, notify | Auto-migrate, log |
| Major workspace migration | Prompt for confirmation | Fail with error |
| Invalid arguments | Show error, suggest help | Show error, exit with code |
| Target dir doesn't exist | Create or prompt | Create automatically |
| Long operation | **Live progress display (in-place updates)** | Periodic log entries (scrolling) |
| Progress updates | Dynamic counters, current file/plugin | Timestamped log entries |

### Automation-Friendly Output Example
```bash
# Interactive mode - Live progress display (updates in place, not scrolling)
Progress: ████████████████░░░░░░░░░░░░░░░░░░░░░░░░ 42%
Files processed: 64/152
Files skipped: 3
Processing: documents/reports/quarterly_review_2025.pdf
Executing plugin: ocrmypdf

# (Above display refreshes in place as processing continues)

# When complete:
Progress: ████████████████████████████████████████ 100%
Files processed: 152/152
Files skipped: 3
Plugins executed: ocrmypdf, stat, file

# Non-interactive mode - Scrolling log entries with timestamps
[2026-02-09T14:30:00Z] [INFO] Starting analysis
[2026-02-09T14:30:00Z] [INFO] Discovered 152 files
[2026-02-09T14:30:00Z] [INFO] Processing file 1/152: manual.pdf
[2026-02-09T14:30:05Z] [INFO] Processing file 2/152: guide.pdf
[2026-02-09T14:30:10Z] [INFO] Processing file 10/152: report.pdf (milestone)
...
[2026-02-09T14:42:34Z] [INFO] Analysis complete: 152 files processed, 3 skipped, 149 reports generated
```

### Environment Variable Override
```bash
# For testing or explicit control
export DOC_DOC_INTERACTIVE=true   # Force interactive
export DOC_DOC_INTERACTIVE=false  # Force non-interactive

# In script
if [[ -n "${DOC_DOC_INTERACTIVE}" ]]; then
  IS_INTERACTIVE="${DOC_DOC_INTERACTIVE}"
else
  detect_interactive_mode
fi
```

## Transition History
- [2026-02-09] Created in funnel by Requirements Engineer Agent - extracted from CLI Interface Concept analysis
- [2026-02-09] Refined to add interactive mode live progress display specification (dynamic counters, in-place updates)
- [2026-02-09] Enhanced progress display with 40-char progress bar specification (percentage centered in bar)
- [2026-02-09] Moved to analyze for detailed analysis
- [2026-02-09] Moved to accepted by user - ready for implementation
- [2026-02-10] Split into req_0057 (Interactive Mode Behavior) and req_0058 (Non-Interactive Mode Behavior) for clearer separation of concerns
- [2026-02-10] Moved to obsolete by Requirements Engineer Agent - replaced by req_0057 and req_0058
