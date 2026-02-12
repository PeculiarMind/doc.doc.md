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

# Unit Tests: Interactive Progress Display
# Tests the progress display functionality for feature_0017

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/doc.doc.sh"
COMPONENTS_DIR="$PROJECT_ROOT/scripts/components"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Progress Display"

# ============================================================================
# Test 1: render_progress_bar function exists
# ============================================================================
test_render_progress_bar_exists() {
  local content

  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/ui/progress_display.sh")
    assert_contains "$content" "render_progress_bar" "Component should define render_progress_bar function"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 2: show_progress function exists
# ============================================================================
test_show_progress_exists() {
  local content

  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/ui/progress_display.sh")
    assert_contains "$content" "show_progress" "Component should define show_progress function"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 3: clear_progress function exists
# ============================================================================
test_clear_progress_exists() {
  local content

  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/ui/progress_display.sh")
    assert_contains "$content" "clear_progress" "Component should define clear_progress function"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 4: get_terminal_width function exists
# ============================================================================
test_get_terminal_width_exists() {
  local content

  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/ui/progress_display.sh")
    assert_contains "$content" "get_terminal_width" "Component should define get_terminal_width function"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 5: truncate_path function exists
# ============================================================================
test_truncate_path_exists() {
  local content

  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/ui/progress_display.sh")
    assert_contains "$content" "truncate_path" "Component should define truncate_path function"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 6: render_progress_bar at 0%
# ============================================================================
test_render_progress_bar_0_percent() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    # Source component in a subshell with interactive mode forced
    local output
    output=$(
      IS_INTERACTIVE=true
      source "$COMPONENTS_DIR/ui/progress_display.sh"
      render_progress_bar 0
    )
    assert_contains "$output" "0%" "Progress bar at 0% should contain '0%'"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 7: render_progress_bar at 50%
# ============================================================================
test_render_progress_bar_50_percent() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    local output
    output=$(
      IS_INTERACTIVE=true
      source "$COMPONENTS_DIR/ui/progress_display.sh"
      render_progress_bar 50
    )
    assert_contains "$output" "50%" "Progress bar at 50% should contain '50%'"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 8: render_progress_bar at 100%
# ============================================================================
test_render_progress_bar_100_percent() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    local output
    output=$(
      IS_INTERACTIVE=true
      source "$COMPONENTS_DIR/ui/progress_display.sh"
      render_progress_bar 100
    )
    assert_contains "$output" "100%" "Progress bar at 100% should contain '100%'"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 9: truncate_path with short path (no truncation needed)
# ============================================================================
test_truncate_path_short() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    local output
    output=$(
      source "$COMPONENTS_DIR/ui/progress_display.sh"
      truncate_path "short/path.txt" 50
    )
    assert_equals "short/path.txt" "$output" "Short path should not be truncated"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 10: truncate_path with long path (truncation needed)
# ============================================================================
test_truncate_path_long() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    local output
    output=$(
      source "$COMPONENTS_DIR/ui/progress_display.sh"
      truncate_path "very/long/deeply/nested/directory/structure/with/many/parts/file.txt" 30
    )
    # Should start with "..." and be within max_width
    assert_contains "$output" "..." "Long path should be truncated with '...'"

    # Verify the length is within the limit
    local len=${#output}
    if [[ $len -le 30 ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Truncated path length ($len) is within limit (30)"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Truncated path length ($len) exceeds limit (30)"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 11: get_terminal_width returns a number
# ============================================================================
test_get_terminal_width_returns_number() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    local output
    output=$(
      source "$COMPONENTS_DIR/ui/progress_display.sh"
      get_terminal_width
    )
    if [[ "$output" =~ ^[0-9]+$ ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: get_terminal_width returns a number ($output)"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: get_terminal_width should return a number, got: '$output'"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 12: show_progress suppressed in non-interactive mode
# ============================================================================
test_show_progress_suppressed_non_interactive() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    local output
    output=$(
      IS_INTERACTIVE=false
      source "$COMPONENTS_DIR/ui/progress_display.sh"
      show_progress 42 64 152 3 "test/file.txt" "stat"
    )
    # In non-interactive mode, show_progress should produce no output
    if [[ -z "$output" ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: show_progress produces no output in non-interactive mode"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: show_progress should be suppressed in non-interactive mode"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 13: show_progress produces output in interactive mode
# ============================================================================
test_show_progress_produces_output_interactive() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    local output
    output=$(
      IS_INTERACTIVE=true
      source "$COMPONENTS_DIR/ui/progress_display.sh"
      show_progress 42 64 152 3 "test/file.txt" "stat" 2>&1
    )
    # In interactive mode, show_progress should produce output
    if [[ -n "$output" ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: show_progress produces output in interactive mode"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: show_progress should produce output in interactive mode"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 14: show_progress output contains expected content
# ============================================================================
test_show_progress_content() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    local output
    output=$(
      IS_INTERACTIVE=true
      source "$COMPONENTS_DIR/ui/progress_display.sh"
      show_progress 42 64 152 3 "documents/report.pdf" "stat" 2>&1
    )
    assert_contains "$output" "64/152" "Progress should show files processed count"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 15: clear_progress suppressed in non-interactive mode
# ============================================================================
test_clear_progress_non_interactive() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    local output
    output=$(
      IS_INTERACTIVE=false
      source "$COMPONENTS_DIR/ui/progress_display.sh"
      clear_progress
    )
    if [[ -z "$output" ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: clear_progress produces no output in non-interactive mode"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: clear_progress should be suppressed in non-interactive mode"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 16: clear_progress runs in interactive mode
# ============================================================================
test_clear_progress_interactive() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    local output
    output=$(
      IS_INTERACTIVE=true
      source "$COMPONENTS_DIR/ui/progress_display.sh"
      clear_progress 2>&1
    )
    # In interactive mode, clear_progress should produce some ANSI output
    if [[ -n "$output" ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: clear_progress produces output in interactive mode"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: clear_progress should produce output in interactive mode"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 17: Component is loaded by main script
# ============================================================================
test_component_loaded_in_main_script() {
  local content

  if [[ -f "$SCRIPT_PATH" ]]; then
    content=$(cat "$SCRIPT_PATH")

    if echo "$content" | grep -q "progress_display.sh"; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Main script should load progress_display component"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Main script should source progress_display.sh"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Main script does not exist"
  fi
}

# ============================================================================
# Test 18: Progress bar uses 40-character width
# ============================================================================
test_progress_bar_width() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    local content
    content=$(cat "$COMPONENTS_DIR/ui/progress_display.sh")
    assert_contains "$content" "bar_width=40" "Progress bar should use 40-character width"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 19: ANSI codes only used in interactive mode
# ============================================================================
test_ansi_gated_on_interactive() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    local content
    content=$(cat "$COMPONENTS_DIR/ui/progress_display.sh")
    assert_contains "$content" "IS_INTERACTIVE" "Component should check IS_INTERACTIVE for ANSI gating"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Test 20: File path sanitization exists (security requirement F1)
# ============================================================================
test_path_sanitization_exists() {
  if [[ -f "$COMPONENTS_DIR/ui/progress_display.sh" ]]; then
    local content
    content=$(cat "$COMPONENTS_DIR/ui/progress_display.sh")
    assert_contains "$content" "_sanitize_display_path" "Component should sanitize file paths for display"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: progress_display.sh component does not exist"
  fi
}

# ============================================================================
# Run all tests
# ============================================================================
test_render_progress_bar_exists
test_show_progress_exists
test_clear_progress_exists
test_get_terminal_width_exists
test_truncate_path_exists
test_render_progress_bar_0_percent
test_render_progress_bar_50_percent
test_render_progress_bar_100_percent
test_truncate_path_short
test_truncate_path_long
test_get_terminal_width_returns_number
test_show_progress_suppressed_non_interactive
test_show_progress_produces_output_interactive
test_show_progress_content
test_clear_progress_non_interactive
test_clear_progress_interactive
test_component_loaded_in_main_script
test_progress_bar_width
test_ansi_gated_on_interactive
test_path_sanitization_exists

finish_test_suite "Progress Display"
exit $?
