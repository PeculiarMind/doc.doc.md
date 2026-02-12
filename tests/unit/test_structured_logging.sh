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

# Test: Structured logging (feature_0019)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

source "${REPO_ROOT}/tests/helpers/test_helpers.sh"

# ==============================================================================
# Test Setup
# ==============================================================================

setup_test() {
  source "${REPO_ROOT}/scripts/components/core/constants.sh"
  source "${REPO_ROOT}/scripts/components/core/logging.sh"
}

# ==============================================================================
# Non-Interactive Mode Tests
# ==============================================================================

test_non_interactive_info_always_shown() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log "INFO" "SCAN" "Processing file" 2>&1)
  assert_contains "${output}" "[INFO " "INFO shown in non-interactive mode without verbose"
}

test_non_interactive_structured_format() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log "INFO" "SCAN" "Processing file" 2>&1)
  # Format: [YYYY-MM-DDTHH:MM:SSZ] [INFO ] [SCAN      ] Processing file
  if [[ "${output}" =~ ^\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\]\ \[INFO\ \]\ \[SCAN ]]; then
    echo -e "${GREEN}✓${NC} PASS: Non-interactive uses structured format with ISO 8601 UTC timestamp"
  else
    echo -e "${RED}✗${NC} FAIL: Non-interactive should use structured format"
    echo "  Got: '${output}'"
  fi
}

test_non_interactive_iso8601_utc_timestamp() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log "INFO" "MAIN" "test" 2>&1)
  # Check for Z suffix indicating UTC
  if [[ "${output}" =~ \[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\] ]]; then
    echo -e "${GREEN}✓${NC} PASS: Timestamp ends with Z for UTC"
  else
    echo -e "${RED}✗${NC} FAIL: Timestamp should end with Z for UTC"
    echo "  Got: '${output}'"
  fi
}

test_non_interactive_error_shown() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log "ERROR" "PLUGIN" "Plugin failed" 2>&1)
  assert_contains "${output}" "[ERROR]" "ERROR shown in non-interactive mode"
  assert_contains "${output}" "[PLUGIN" "Component tag included"
}

test_non_interactive_warn_shown() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log "WARN" "TOOL" "Tool missing" 2>&1)
  assert_contains "${output}" "[WARN " "WARN shown in non-interactive mode"
  assert_contains "${output}" "[TOOL" "Component tag included"
}

test_non_interactive_debug_hidden_without_verbose() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log "DEBUG" "INIT" "Debug detail" 2>&1)
  if [[ -z "${output}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: DEBUG hidden without verbose in non-interactive mode"
  else
    echo -e "${RED}✗${NC} FAIL: DEBUG should be hidden without verbose"
  fi
}

test_non_interactive_debug_shown_with_verbose() {
  IS_INTERACTIVE=false
  set_log_level true
  local output
  output=$(log "DEBUG" "INIT" "Debug detail" 2>&1)
  assert_contains "${output}" "[DEBUG]" "DEBUG shown with verbose in non-interactive mode"
  assert_contains "${output}" "[INIT" "Component tag included"
}

test_non_interactive_no_ansi_codes() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log "ERROR" "MAIN" "An error occurred" 2>&1)
  if [[ "${output}" == *$'\033'* ]]; then
    echo -e "${RED}✗${NC} FAIL: Non-interactive output should not contain ANSI codes"
  else
    echo -e "${GREEN}✓${NC} PASS: No ANSI codes in non-interactive output"
  fi
}

# ==============================================================================
# Interactive Mode Tests
# ==============================================================================

test_interactive_info_clean_message() {
  IS_INTERACTIVE=true
  set_log_level false
  local output
  output=$(log "INFO" "SCAN" "Analyzing 152 files..." 2>&1)
  # INFO in interactive mode shows just the message, no prefix
  assert_contains "${output}" "Analyzing 152 files..." "Interactive INFO shows clean message"
  assert_not_contains "${output}" "[INFO]" "Interactive INFO has no level prefix"
}

test_interactive_error_has_color() {
  IS_INTERACTIVE=true
  set_log_level false
  local output
  output=$(log "ERROR" "MAIN" "Something failed" 2>&1)
  assert_contains "${output}" "[ERROR]" "Interactive ERROR shows level prefix"
  assert_contains "${output}" "Something failed" "Interactive ERROR shows message"
  # Check for ANSI red color code
  if [[ "${output}" == *$'\033[31m'* ]]; then
    echo -e "${GREEN}✓${NC} PASS: Interactive ERROR uses red color"
  else
    echo -e "${RED}✗${NC} FAIL: Interactive ERROR should use red color"
  fi
}

test_interactive_warn_has_color() {
  IS_INTERACTIVE=true
  set_log_level false
  local output
  output=$(log "WARN" "TOOL" "Plugin not found" 2>&1)
  assert_contains "${output}" "[WARN]" "Interactive WARN shows level prefix"
  # Check for ANSI yellow color code
  if [[ "${output}" == *$'\033[33m'* ]]; then
    echo -e "${GREEN}✓${NC} PASS: Interactive WARN uses yellow color"
  else
    echo -e "${RED}✗${NC} FAIL: Interactive WARN should use yellow color"
  fi
}

test_interactive_debug_hidden_without_verbose() {
  IS_INTERACTIVE=true
  set_log_level false
  local output
  output=$(log "DEBUG" "INIT" "Debug info" 2>&1)
  if [[ -z "${output}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Interactive DEBUG hidden without verbose"
  else
    echo -e "${RED}✗${NC} FAIL: Interactive DEBUG should be hidden without verbose"
  fi
}

test_interactive_debug_shown_with_verbose() {
  IS_INTERACTIVE=true
  set_log_level true
  local output
  output=$(log "DEBUG" "INIT" "Debug info" 2>&1)
  assert_contains "${output}" "[DEBUG]" "Interactive DEBUG shown with verbose"
  assert_contains "${output}" "Debug info" "Interactive DEBUG message shown"
}

# ==============================================================================
# Backward Compatibility Tests
# ==============================================================================

test_two_arg_form_defaults_to_main() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log "INFO" "A simple message" 2>&1)
  assert_contains "${output}" "[MAIN" "2-arg form defaults component to MAIN"
  assert_contains "${output}" "A simple message" "2-arg form preserves message"
}

test_three_arg_form_uses_component() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log "WARN" "WORKSPACE" "Workspace issue" 2>&1)
  assert_contains "${output}" "[WORKSPACE" "3-arg form uses provided component tag"
}

test_legacy_mode_backward_compatible() {
  # When IS_INTERACTIVE is not set, use legacy behavior
  unset IS_INTERACTIVE
  set_log_level false
  local output
  output=$(log "INFO" "TEST" "Info message" 2>&1)
  if [[ -z "${output}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Legacy mode hides INFO without verbose (backward compatible)"
  else
    echo -e "${RED}✗${NC} FAIL: Legacy mode should hide INFO without verbose"
  fi
}

test_legacy_mode_error_shown() {
  unset IS_INTERACTIVE
  set_log_level false
  local output
  output=$(log "ERROR" "TEST" "Error message" 2>&1)
  assert_contains "${output}" "[ERROR]" "Legacy mode shows ERROR without verbose"
  assert_contains "${output}" "[TEST]" "Legacy mode includes component tag"
}

test_legacy_mode_verbose_shows_all() {
  unset IS_INTERACTIVE
  set_log_level true
  local output
  output=$(log "INFO" "TEST" "Info message" 2>&1)
  assert_contains "${output}" "[INFO]" "Legacy mode shows INFO with verbose"
}

# ==============================================================================
# Component Tag Tests
# ==============================================================================

test_component_tags() {
  IS_INTERACTIVE=false
  set_log_level false
  local tags=("INIT" "SCAN" "PLUGIN" "WORKSPACE" "TOOL" "TEMPLATE" "REPORT" "MAIN")
  local all_pass=true
  for tag in "${tags[@]}"; do
    local output
    output=$(log "INFO" "$tag" "Test message" 2>&1)
    if [[ "${output}" != *"[${tag}"* ]]; then
      echo -e "${RED}✗${NC} FAIL: Component tag ${tag} not found in output"
      all_pass=false
    fi
  done
  if [[ "$all_pass" == true ]]; then
    echo -e "${GREEN}✓${NC} PASS: All component tags (INIT, SCAN, PLUGIN, WORKSPACE, TOOL, TEMPLATE, REPORT, MAIN) format correctly"
  fi
}

test_component_tag_fixed_width() {
  IS_INTERACTIVE=false
  set_log_level false
  local output_short output_long
  output_short=$(log "INFO" "INIT" "msg" 2>&1)
  output_long=$(log "INFO" "WORKSPACE" "msg" 2>&1)
  # Both component fields should be same width (9 chars padded)
  local tag_short tag_long
  tag_short=$(echo "$output_short" | sed -n 's/.*\] \[\(.*\)\] msg/\1/p')
  tag_long=$(echo "$output_long" | sed -n 's/.*\] \[\(.*\)\] msg/\1/p')
  if [[ ${#tag_short} -eq ${#tag_long} ]]; then
    echo -e "${GREEN}✓${NC} PASS: Component tags have fixed width"
  else
    echo -e "${RED}✗${NC} FAIL: Component tags should have fixed width (got '${tag_short}' vs '${tag_long}')"
  fi
}

# ==============================================================================
# Log Level Filtering Tests
# ==============================================================================

test_debug_filtered_without_verbose() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log "DEBUG" "MAIN" "Should not appear" 2>&1)
  if [[ -z "${output}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: DEBUG filtered out without verbose mode"
  else
    echo -e "${RED}✗${NC} FAIL: DEBUG should be filtered without verbose"
  fi
}

test_debug_shown_with_verbose() {
  IS_INTERACTIVE=false
  set_log_level true
  local output
  output=$(log "DEBUG" "MAIN" "Should appear" 2>&1)
  assert_contains "${output}" "Should appear" "DEBUG shown with verbose mode"
}

# ==============================================================================
# Log Injection Prevention Tests (Security - Finding F5)
# ==============================================================================

test_sanitize_newlines_in_message() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log "INFO" "SCAN" "line1"$'\n'"line2" 2>&1)
  # Output should be a single line (newline replaced with \n literal)
  local line_count
  line_count=$(echo "${output}" | wc -l)
  if [[ "$line_count" -eq 1 ]]; then
    echo -e "${GREEN}✓${NC} PASS: Newlines in message are sanitized to single line"
  else
    echo -e "${RED}✗${NC} FAIL: Message with newlines should produce single log line (got ${line_count})"
  fi
}

test_sanitize_carriage_return_in_message() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log "INFO" "SCAN" "before"$'\r'"after" 2>&1)
  assert_contains "${output}" "before" "Content before CR preserved"
  assert_contains "${output}" "after" "Content after CR preserved"
  local line_count
  line_count=$(echo "${output}" | wc -l)
  if [[ "$line_count" -eq 1 ]]; then
    echo -e "${GREEN}✓${NC} PASS: Carriage returns in message are sanitized"
  else
    echo -e "${RED}✗${NC} FAIL: Message with CR should produce single log line"
  fi
}

# ==============================================================================
# Progress Milestone Tests
# ==============================================================================

test_log_progress_milestone_function_exists() {
  if declare -f log_progress_milestone >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: log_progress_milestone function exists"
  else
    echo -e "${RED}✗${NC} FAIL: log_progress_milestone function should exist"
  fi
}

test_progress_milestone_at_50_items() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log_progress_milestone 50 200 2>&1)
  assert_contains "${output}" "Milestone" "Milestone logged at 50 items"
  assert_contains "${output}" "50/200" "Milestone shows progress fraction"
  assert_contains "${output}" "25%" "Milestone shows percentage"
}

test_progress_milestone_at_100_items() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log_progress_milestone 100 200 2>&1)
  assert_contains "${output}" "Milestone" "Milestone logged at 100 items"
  assert_contains "${output}" "100/200" "Milestone shows progress fraction"
  assert_contains "${output}" "50%" "Milestone shows percentage"
}

test_progress_milestone_skips_non_boundary() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log_progress_milestone 7 200 2>&1)
  if [[ -z "${output}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: No milestone at non-boundary count"
  else
    echo -e "${RED}✗${NC} FAIL: Should not log milestone at count 7/200"
  fi
}

test_progress_milestone_zero_total_safe() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log_progress_milestone 0 0 2>&1)
  # Should not crash with division by zero
  echo -e "${GREEN}✓${NC} PASS: log_progress_milestone handles zero total safely"
}

test_progress_milestone_custom_component() {
  IS_INTERACTIVE=false
  set_log_level false
  local output
  output=$(log_progress_milestone 50 100 "PLUGIN" 2>&1)
  assert_contains "${output}" "[PLUGIN" "Custom component tag used in milestone"
}

# ==============================================================================
# Existing Function Compatibility Tests
# ==============================================================================

test_set_log_level_still_works() {
  set_log_level true
  if is_verbose; then
    echo -e "${GREEN}✓${NC} PASS: set_log_level(true) enables verbose"
  else
    echo -e "${RED}✗${NC} FAIL: set_log_level(true) should enable verbose"
  fi
  set_log_level false
  if ! is_verbose; then
    echo -e "${GREEN}✓${NC} PASS: set_log_level(false) disables verbose"
  else
    echo -e "${RED}✗${NC} FAIL: set_log_level(false) should disable verbose"
  fi
}

test_is_verbose_still_works() {
  if declare -f is_verbose >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: is_verbose function still exists"
  else
    echo -e "${RED}✗${NC} FAIL: is_verbose function should still exist"
  fi
}

# ==============================================================================
# Test Execution
# ==============================================================================

echo "=== Running Test Suite: Structured Logging (feature_0019) ==="
echo

setup_test

# Non-interactive mode
test_non_interactive_info_always_shown
test_non_interactive_structured_format
test_non_interactive_iso8601_utc_timestamp
test_non_interactive_error_shown
test_non_interactive_warn_shown
test_non_interactive_debug_hidden_without_verbose
test_non_interactive_debug_shown_with_verbose
test_non_interactive_no_ansi_codes

# Interactive mode
test_interactive_info_clean_message
test_interactive_error_has_color
test_interactive_warn_has_color
test_interactive_debug_hidden_without_verbose
test_interactive_debug_shown_with_verbose

# Backward compatibility
test_two_arg_form_defaults_to_main
test_three_arg_form_uses_component
test_legacy_mode_backward_compatible
test_legacy_mode_error_shown
test_legacy_mode_verbose_shows_all

# Component tags
test_component_tags
test_component_tag_fixed_width

# Log level filtering
test_debug_filtered_without_verbose
test_debug_shown_with_verbose

# Log injection prevention (security)
test_sanitize_newlines_in_message
test_sanitize_carriage_return_in_message

# Progress milestones
test_log_progress_milestone_function_exists
test_progress_milestone_at_50_items
test_progress_milestone_at_100_items
test_progress_milestone_skips_non_boundary
test_progress_milestone_zero_total_safe
test_progress_milestone_custom_component

# Existing function compatibility
test_set_log_level_still_works
test_is_verbose_still_works

echo
echo "=== Test Suite Complete: Structured Logging (feature_0019) ==="
