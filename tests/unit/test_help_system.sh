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

# Unit Tests: Help System
# Tests the help display functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/doc.doc.sh"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Help System"

# Test 1: -h flag shows help
test_help_short_flag() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  assert_contains "$output" "Usage" "-h should display help with Usage section"
  assert_exit_code 0 $exit_code "-h should exit with code 0"
}

# Test 2: --help flag shows help
test_help_long_flag() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --help
  
  assert_contains "$output" "Usage" "--help should display help with Usage section"
  assert_exit_code 0 $exit_code "--help should exit with code 0"
}

# Test 3: Help shows script name
test_help_shows_script_name() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  assert_contains "$output" "doc.doc" "Help should include script name"
}

# Test 4: Help shows available options
test_help_shows_options() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  assert_contains "$output" "-h" "Help should document -h flag"
  assert_contains "$output" "--help" "Help should document --help flag"
  assert_contains "$output" "-v" "Help should document -v flag"
  assert_contains "$output" "--verbose" "Help should document --verbose flag"
  assert_contains "$output" "--version" "Help should document --version flag"
}

# Test 5: Help shows examples
test_help_shows_examples() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  assert_contains "$output" "Example" "Help should include usage examples"
}

# Test 6: Help shows description of options
test_help_option_descriptions() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  assert_contains "$output" "help" "Help should describe help option"
  assert_contains "$output" "verbose" "Help should describe verbose option"
  assert_contains "$output" "version" "Help should describe version option"
}

# Test 7: Help output format is readable
test_help_formatting() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  # Check that help output has reasonable structure (multiple lines)
  local line_count
  line_count=$(echo "$output" | wc -l)
  
  if [[ $line_count -gt 5 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Help output should be multi-line and formatted"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Help output should be multi-line (got $line_count lines)"
  fi
}

# Test 8: Help documents all implemented options (-d, -m, -t, -w, -f)
test_help_documents_implemented_options() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  assert_contains "$output" "-d" "Help should document -d flag"
  assert_contains "$output" "-m" "Help should document -m flag"
  assert_contains "$output" "-t" "Help should document -t flag"
  assert_contains "$output" "-w" "Help should document -w flag"
  assert_contains "$output" "-f" "Help should document -f flag"
  assert_contains "$output" "-p" "Help should document -p flag"
  assert_contains "$output" "--plugin" "Help should document --plugin flag"
}

# Test 9: Help accurately describes -d as source directory
test_help_d_description_accuracy() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  assert_contains "$output" "Source directory" "Help -d should describe source directory"
  assert_not_contains "$output" "-d.*future" "Help -d should not be marked as future"
}

# Test 10: Help accurately describes -m as template file
test_help_m_description_accuracy() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  assert_contains "$output" "Template file" "Help -m should describe template file"
}

# Test 11: Help accurately describes -t as target directory
test_help_t_description_accuracy() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  assert_contains "$output" "Target directory" "Help -t should describe target directory"
}

# Test 12: Help accurately describes -w as workspace directory
test_help_w_description_accuracy() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  assert_contains "$output" "Workspace directory" "Help -w should describe workspace directory"
}

# Test 13: Help accurately describes -f as force full rescan
test_help_f_description_accuracy() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  assert_contains "$output" "full rescan" "Help -f should describe full rescan"
}

# Test 14: Help does not contain stale '(future)' markers for implemented features
test_help_no_stale_future_markers() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  # Count occurrences of "(future)" - none should remain for implemented options
  local future_count
  future_count=$(echo "$output" | grep -c "(future)" || true)
  
  if [[ $future_count -eq 0 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Help contains no stale '(future)' markers"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Help still contains $future_count '(future)' markers"
  fi
}

# Test 15: Help examples include full directory analysis command
test_help_examples_include_analysis() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  assert_contains "$output" "-d ./docs" "Help examples should show -d flag usage"
  assert_contains "$output" "-m template.md" "Help examples should show -m flag usage"
  assert_contains "$output" "-t ./output" "Help examples should show -t flag usage"
  assert_contains "$output" "-w ./workspace" "Help examples should show -w flag usage"
}

# Run all tests
test_help_short_flag
test_help_long_flag
test_help_shows_script_name
test_help_shows_options
test_help_shows_examples
test_help_option_descriptions
test_help_formatting
test_help_documents_implemented_options
test_help_d_description_accuracy
test_help_m_description_accuracy
test_help_t_description_accuracy
test_help_w_description_accuracy
test_help_f_description_accuracy
test_help_no_stale_future_markers
test_help_examples_include_analysis

finish_test_suite "Help System"
exit $?
