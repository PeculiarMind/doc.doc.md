# Requirement: Interactive Mode Behavior

**ID**: req_0057

## Status
State: Accepted  
Created: 2026-02-10  
Last Updated: 2026-02-10

## Overview
The system shall detect when running in interactive mode (user at terminal) and provide enhanced user experience through prompts, confirmations, live progress displays, and human-friendly messages.

## Description
When the toolkit runs in interactive mode (user present at terminal), it provides a rich user experience with real-time feedback, confirmation prompts for potentially disruptive operations, and dynamic progress displays. Interactive mode is detected by verifying both stdin and stdout are connected to terminals using POSIX tests (`[ -t 0 ] && [ -t 1 ]`). This mode prioritizes user control and visibility through prompts for missing tool installation, live progress bars showing current execution status, and helpful error messages with actionable suggestions.

## Motivation
From CLI Interface Concept (08_0003_cli_interface_concept.md) which describes detecting interactive mode and adapting behavior for optimal user experience. Users running commands manually expect immediate feedback, progress visibility, and the ability to intervene in operations.

Split from req_0045 (Non-Interactive Mode Detection and Handling) to separate interactive and non-interactive concerns for clearer implementation and testing.

## Category
- Type: Functional
- Priority: Medium

## Acceptance Criteria

### Mode Detection
- [ ] System detects interactive mode by testing if stdin is a terminal (`[ -t 0 ]`)
- [ ] System detects interactive mode by testing if stdout is a terminal (`[ -t 1 ]`)
- [ ] Both stdin and stdout must be terminals for interactive mode (logical AND)
- [ ] Mode detection performed early in script execution (before any prompts)
- [ ] Mode stored in global variable (e.g., `IS_INTERACTIVE=true`)
- [ ] Verbose mode logs detected mode ("Running in interactive mode")

### User Prompts and Confirmations
- [ ] Missing tool installation prompts user for confirmation
- [ ] Prompts include clear options (e.g., [y/N] for yes/no with default)
- [ ] User can decline optional operations gracefully
- [ ] Invalid prompt responses re-prompt user with guidance

### Live Progress Display
- [ ] Progress display updates in place without scrolling (using carriage return `\r` or ANSI cursor control)
- [ ] Progress bar displayed: 40-character bar that fills as processing advances
- [ ] Progress percentage centered in bar: Percentage value (0-100%) displayed in the center of the progress bar
- [ ] Progress bar uses filled characters (█) for completed portion and empty characters (░) for remaining portion
- [ ] Progress includes count of files processed (incrementing counter)
- [ ] Progress includes count of files skipped (incrementing counter when applicable)
- [ ] Progress displays currently processed file path (truncated if needed to fit terminal width)
- [ ] Progress displays currently executing plugin name
- [ ] Progress format consistent and easy to read at a glance
- [ ] Progress display clears or finalizes when analysis completes
- [ ] Progress display updates at reasonable frequency (not per-byte, but per-file or per-plugin)
- [ ] Terminal width detection used to prevent line wrapping in progress display

### Progress Display Format Example
```
Progress: ████████████████░░░░░░░░░░░░░░░░░░░░░░░░ 42%
Files processed: 64/152
Files skipped: 3
Processing: documents/reports/quarterly_review_2025.pdf
Executing plugin: ocrmypdf
```

### Error Handling and Messages
- [ ] Errors include suggestions for user action ("Try installing X with: apt install X")
- [ ] Help messages formatted for human readability (word wrapping acceptable)
- [ ] Error messages concise and user-facing ("Analyzing 152 files...")
- [ ] ANSI colors acceptable for emphasis and readability

### Testing Support
- [ ] Mode detection can be forced via environment variable (`DOC_DOC_INTERACTIVE=true`)
- [ ] Test suite includes tests for interactive behavior
- [ ] Interactive prompts can be mocked/simulated in tests

## Related Requirements
- req_0058 (Non-Interactive Mode Behavior) - complementary requirement for automation
- req_0045 (Non-Interactive Mode Detection and Handling) - obsoleted parent requirement
- req_0008 (Installation Prompts) - implements prompts only in interactive mode
- req_0006 (Verbose Logging Mode) - logging behavior adapts to mode

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

### Live Progress Display Implementation
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
```

### Prompt Implementation
```bash
# Prompt for missing tool installation
if [[ "${IS_INTERACTIVE}" == "true" ]]; then
  read -p "Install missing tool? [y/N] " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    install_tool
  else
    log "INFO" "Skipping tool installation"
  fi
fi
```

### Environment Variable Override
```bash
# For testing or explicit control
export DOC_DOC_INTERACTIVE=true   # Force interactive

# In script
if [[ -n "${DOC_DOC_INTERACTIVE}" ]]; then
  IS_INTERACTIVE="${DOC_DOC_INTERACTIVE}"
else
  detect_interactive_mode
fi
```

## Transition History
- [2026-02-10] Created by Requirements Engineer Agent - split from req_0045 to separate interactive mode concerns
- [2026-02-10] Moved to accepted (inherits acceptance status from req_0045)
