#!/usr/bin/env bash
# Copyright (c) 2026 doc.doc.md Project
# This file is part of doc.doc.md.
#
# doc.doc.md is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# doc.doc.md is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with doc.doc.md. If not, see <https://www.gnu.org/licenses/>.

# Component: progress_display.sh
# Purpose: Interactive progress display for long-running operations
# Dependencies: core/mode_detection.sh, core/logging.sh
# Exports: render_progress_bar(), show_progress(), clear_progress(), get_terminal_width(), truncate_path()
# Side Effects: Writes to stderr/stdout for display

# ==============================================================================
# Internal Helpers
# ==============================================================================

# Sanitize a file path for safe terminal display (SC-INT-001, CWE-150)
# Strips ANSI escape sequences and non-printable control characters
_sanitize_display_path() {
  local path="$1"
  # Remove ANSI escape sequences: ESC[ ... m/A/B/K/J/H and OSC sequences ESC] ... BEL/ST
  local sanitized
  sanitized=$(printf '%s' "$path" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/\x1b\][^\x07]*\x07//g; s/\x1b\][^\x1b]*\x1b\\//g')
  # Remove remaining control characters (0x00-0x1F except space, and 0x7F)
  sanitized=$(printf '%s' "$sanitized" | LC_ALL=C tr -d '\000-\037\177')
  printf '%s' "$sanitized"
}

# ==============================================================================
# Terminal Width Detection
# ==============================================================================

# Detect terminal width, defaults to 80 if not available
get_terminal_width() {
  local width
  if [[ -t 1 ]]; then
    width=$(tput cols 2>/dev/null || echo "80")
  else
    width=80
  fi
  echo "$width"
}

# ==============================================================================
# Path Truncation
# ==============================================================================

# Truncate file paths to fit within a given width
# Truncates from the left (prefix), preserving the file name
# Arguments:
#   $1 - File path to truncate
#   $2 - Maximum width
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

# ==============================================================================
# Progress Bar Rendering
# ==============================================================================

# Render a 40-character progress bar with filled and empty characters
# Percentage is centered within the bar
# Arguments:
#   $1 - Percentage (0-100)
# Output:
#   Progress bar string like "[████████████████░░░░░░░░░░░░░░░░░░░░░░░░  42%]"
render_progress_bar() {
  if [[ "${IS_INTERACTIVE:-}" != "true" ]]; then
    return
  fi

  local percent="$1"
  local bar_width=40

  # Clamp percentage to 0-100
  if (( percent < 0 )); then
    percent=0
  elif (( percent > 100 )); then
    percent=100
  fi

  local filled_width=$(( percent * bar_width / 100 ))
  local empty_width=$(( bar_width - filled_width ))

  # Build the progress bar
  local filled=""
  local empty=""
  if (( filled_width > 0 )); then
    filled=$(printf '%*s' "$filled_width" '' | tr ' ' '█')
  fi
  if (( empty_width > 0 )); then
    empty=$(printf '%*s' "$empty_width" '' | tr ' ' '░')
  fi
  local bar="${filled}${empty}"

  # Insert percentage in the center of the bar
  local percent_str
  percent_str=$(printf "%3d%%" "$percent")
  local center_pos=$(( (bar_width - 4) / 2 ))
  local bar_with_percent="${bar:0:$center_pos}${percent_str}${bar:$((center_pos+4))}"

  printf "[%s]" "$bar_with_percent"
}

# ==============================================================================
# Progress Display
# ==============================================================================

# Number of lines in the progress display (for cursor movement)
_PROGRESS_DISPLAY_LINES=5

# Show multi-line progress display with in-place updates
# Only displays in interactive mode (IS_INTERACTIVE=true)
# Arguments:
#   $1 - Percentage (0-100)
#   $2 - Files processed count
#   $3 - Total file count
#   $4 - Files skipped count
#   $5 - Current file path
#   $6 - Current plugin name
show_progress() {
  if [[ "${IS_INTERACTIVE:-}" != "true" ]]; then
    return
  fi

  local percent="$1"
  local processed="$2"
  local total="$3"
  local skipped="$4"
  local current_file="$5"
  local current_plugin="$6"

  # Sanitize file path and plugin name for safe display (SC-INT-001)
  current_file="$(_sanitize_display_path "$current_file")"
  current_plugin="$(_sanitize_display_path "$current_plugin")"

  # Truncate file path to fit terminal width
  local term_width
  term_width=$(get_terminal_width)
  local label_prefix="Processing: "
  local max_path_width=$(( term_width - ${#label_prefix} - 1 ))
  if (( max_path_width < 10 )); then
    max_path_width=10
  fi
  current_file=$(truncate_path "$current_file" "$max_path_width")

  # Render progress bar
  local bar
  bar=$(render_progress_bar "$percent")

  # Clear previous display and show progress (in-place update)
  printf "\r\033[K"
  printf "Progress: %s\n" "$bar"
  printf "\033[KFiles processed: %d/%d\n" "$processed" "$total"
  printf "\033[KFiles skipped: %d\n" "$skipped"
  printf "\033[KProcessing: %s\n" "$current_file"
  printf "\033[KExecuting plugin: %s" "$current_plugin"
  # Move cursor back up for next update
  printf "\033[%dA\r" "$_PROGRESS_DISPLAY_LINES"
}

# Clear/finalize the progress display when operation completes
clear_progress() {
  if [[ "${IS_INTERACTIVE:-}" != "true" ]]; then
    return
  fi

  # Clear all lines of the progress display
  local i
  for (( i = 0; i < _PROGRESS_DISPLAY_LINES; i++ )); do
    printf "\r\033[K\n"
  done
}
