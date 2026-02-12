# Feature: Interactive Live Progress Display

**ID**: 0017  
**Type**: Feature Implementation  
**Status**: Done  
**Created**: 2026-02-10  
**Updated**: 2026-02-12  
**Completed**: 2026-02-12  
**Priority**: Medium

## Overview
Implement live progress display system for interactive mode that shows real-time execution status with in-place updates, progress bar, file counts, and current processing information without scrolling output.

## Description
Create a dynamic progress display system that provides rich visual feedback during long-running operations when running in interactive mode. The display updates in place using ANSI escape codes and carriage returns, showing a 40-character progress bar with centered percentage, counts of processed and skipped files, the current file being processed, and the executing plugin name.

The progress display must be efficient (not updating per-byte), handle terminal width correctly to prevent wrapping, and cleanly finalize when operations complete. This feature only activates in interactive mode; non-interactive mode uses structured logging instead.

## Business Value
- Provides users with real-time visibility into long-running operations
- Reduces perceived wait time through visual feedback
- Helps users understand current execution context (which file, which plugin)
- Enables users to estimate completion time and identify bottlenecks
- Improves user experience and reduces abandonment of long operations
- Professional appearance appropriate for production CLI tools

## Related Requirements
- [req_0057](../../01_vision/02_requirements/03_accepted/req_0057_interactive_mode_behavior.md) - Interactive Mode Behavior (PRIMARY)
- [req_0002](../../01_vision/02_requirements/03_accepted/req_0002_recursive_directory_scanning.md) - Recursive Directory Scanning (progress context)

## Acceptance Criteria

### Progress Bar Display
- [ ] 40-character progress bar displayed with filled (█) and empty (░) characters
- [ ] Progress percentage (0-100%) centered within the progress bar
- [ ] Progress bar updates as processing advances through file list
- [ ] Progress bar formula: `filled_width = percent * bar_width / 100`
- [ ] Percentage formatted as "XXX%" (3 digits, right-aligned)

### File Counters
- [ ] Display "Files processed: X/Y" with current and total counts
- [ ] Display "Files skipped: N" counter (increments when files are skipped)
- [ ] Counters update in real-time as files are processed
- [ ] Total file count established during directory scan phase

### Current Execution Context
- [ ] Display currently processed file path
- [ ] File path truncated if needed to fit terminal width
- [ ] Display currently executing plugin name
- [ ] Context updates immediately when changing files or plugins

### In-Place Updates
- [ ] Progress display updates in place without scrolling (using `\r` carriage return or ANSI cursor control)
- [ ] Previous display cleared before showing updated content (`\033[K` clear line)
- [ ] Cursor positioned correctly for multi-line updates (`\033[nA` cursor up, `\033[nB` cursor down)
- [ ] No scrolling log entries during progress display

### Display Lifecycle
- [ ] Progress display only shown in interactive mode (`IS_INTERACTIVE=true`)
- [ ] Progress display suppressed completely in non-interactive mode
- [ ] Display initializes when long-running operation begins
- [ ] Display updates at reasonable frequency (per-file or per-plugin, not per-byte)
- [ ] Display clears or finalizes when operation completes
- [ ] Final summary displayed after progress clears (files processed, completion message)

### Terminal Compatibility
- [ ] Terminal width detection used to prevent line wrapping
- [ ] Graceful degradation if terminal width unavailable (assume 80 columns)
- [ ] ANSI escape codes only used in interactive mode
- [ ] Progress display works in common terminals (bash, zsh, xterm, gnome-terminal, iTerm2)

### Example Format
```
Progress: ████████████████░░░░░░░░░░░░░░░░░░░░░░░░ 42%
Files processed: 64/152
Files skipped: 3
Processing: documents/reports/quarterly_review_2025.pdf
Executing plugin: ocrmypdf
```

## Technical Considerations

### Implementation
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
  
  printf "Progress: [%s]" "$bar_with_percent"
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
  render_progress_bar "${percent}"
  printf "\n"
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

### Performance Considerations
- Update frequency: per-file or per-plugin, not more frequent
- Avoid excessive terminal writes (throttle updates if needed)
- Calculate percentage efficiently (integer arithmetic)
- Cache terminal width detection result

### Terminal Width Detection
```bash
get_terminal_width() {
  local width
  if [[ -t 1 ]]; then
    width=$(tput cols 2>/dev/null || echo "80")
  else
    width=80  # Default for non-terminal
  fi
  echo "$width"
}

# Truncate file path to fit terminal
truncate_path() {
  local path="$1"
  local max_width="$2"
  
  if [[ ${#path} -le $max_width ]]; then
    echo "$path"
  else
    local truncated_width=$((max_width - 3))
    echo "...${path: -$truncated_width}"
  fi
}
```

## Dependencies
- **feature_0016** (Mode Detection) - Must detect interactive mode first
- Logging system for fallback in non-interactive mode
- ANSI escape code support in terminal

## Estimated Effort
Medium (4-6 hours) - Display rendering logic, terminal handling, testing across terminals

## Notes
- Testing requires interactive terminal simulation
- Consider adding option to disable progress display even in interactive mode (`--no-progress`)
- Progress display should be a component that's easy to unit test
- Future enhancement: Multiple concurrent progress displays for parallel operations

## Transition History
- [2026-02-10] Created by Requirements Engineer Agent - derived from req_0057 Interactive Mode Behavior
- [2026-02-11] Moved from Backlog to Implementing - all acceptance criteria verified, dependencies satisfied (feature_0016 done)
- [2026-02-12] Moved from Implementing to Done - implementation complete, all tests pass

## Implementation Details

- **Files Created**: `scripts/components/ui/progress_display.sh`, `tests/unit/test_progress_display.sh`
- **Files Modified**: `scripts/doc.doc.sh`
- **Architecture review**: IDR-0017 (APPROVED)
- **Security review**: `07_interactive_mode_security.md` (APPROVED)
