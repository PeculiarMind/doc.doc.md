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

# System Tests: End-to-End Scenarios
# Tests complete user scenarios from start to finish

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/doc.doc.sh"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "End-to-End User Scenarios"

# Test 1: User requests help
test_user_requests_help() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --help
  
  assert_contains "$output" "Usage" "User should see usage information"
  assert_contains "$output" "Example" "User should see examples"
  assert_exit_code 0 $exit_code "Help request should complete successfully"
}

# Test 2: User checks version
test_user_checks_version() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --version
  
  assert_contains "$output" "version" "User should see version information"
  assert_exit_code 0 $exit_code "Version check should complete successfully"
}

# Test 3: User makes typo in option
test_user_typo() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --hlep
  
  assert_contains "$output" "Error" "User should see clear error message"
  assert_exit_code 1 $exit_code "Invalid option should exit with error code"
}

# Test 4: User runs script with no arguments
test_user_no_arguments() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH"
  
  # Should either show help or meaningful error
  if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Script handles no arguments gracefully"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Script should handle no arguments with exit code 0 or 1"
  fi
}

# Test 5: User combines valid flags
test_user_combines_flags() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -v --help
  
  assert_exit_code 0 $exit_code "User should be able to combine valid flags"
}

# Test 6: Script behavior is consistent across invocations
test_consistent_behavior() {
  local output1 exit_code1 output2 exit_code2
  
  run_command output1 exit_code1 "$SCRIPT_PATH" --version
  run_command output2 exit_code2 "$SCRIPT_PATH" --version
  
  assert_equals "$output1" "$output2" "Script output should be consistent"
  assert_equals "$exit_code1" "$exit_code2" "Exit codes should be consistent"
}

# Test 7: Script provides useful feedback on errors
test_useful_error_feedback() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -z
  
  assert_contains "$output" "Error" "Error message should be clear"
  # Should show help or guidance after error
  if echo "$output" | grep -qiE "usage|help|try.*--help"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Error provides guidance to user"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Error should guide user (e.g., show help)"
  fi
}

# Test 8: Professional output format
test_professional_output() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --version
  
  # Output should not have debug artifacts, stray characters, etc.
  if echo "$output" | grep -qE "^[a-zA-Z0-9 .,:;()\-_/\n]+$"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Output is clean and professional"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Output should be clean without debug artifacts"
  fi
}

# Run all tests
test_user_requests_help
test_user_checks_version
test_user_typo
test_user_no_arguments
test_user_combines_flags
test_consistent_behavior
test_useful_error_feedback
test_professional_output

finish_test_suite "End-to-End User Scenarios"
exit $?
