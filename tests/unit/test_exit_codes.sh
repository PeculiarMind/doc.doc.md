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

# Unit Tests: Exit Codes
# Tests that the script uses correct exit codes for different scenarios

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/doc.doc.sh"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Exit Codes"

# Test 1: EXIT_SUCCESS (0) for successful help
test_exit_success_help() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -h
  
  assert_exit_code 0 $exit_code "Help should exit with EXIT_SUCCESS (0)"
}

# Test 2: EXIT_SUCCESS (0) for successful version
test_exit_success_version() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --version
  
  assert_exit_code 0 $exit_code "Version should exit with EXIT_SUCCESS (0)"
}

# Test 3: EXIT_INVALID_ARGS (1) for invalid arguments
test_exit_invalid_args() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -x
  
  assert_exit_code 1 $exit_code "Invalid option should exit with EXIT_INVALID_ARGS (1)"
}

# Test 4: EXIT_INVALID_ARGS (1) for unexpected arguments
test_exit_invalid_args_unexpected() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" unexpected
  
  assert_exit_code 1 $exit_code "Unexpected argument should exit with EXIT_INVALID_ARGS (1)"
}

# Test 5: Exit code constants defined in script
test_exit_code_constants_defined() {
  local content
  content=$(cat "$SCRIPT_PATH")
  
  assert_contains "$content" "EXIT_SUCCESS=0" "EXIT_SUCCESS should be defined as 0"
  assert_contains "$content" "EXIT_INVALID_ARGS=1" "EXIT_INVALID_ARGS should be defined as 1"
  assert_contains "$content" "EXIT_FILE_ERROR=2" "EXIT_FILE_ERROR should be defined as 2"
  assert_contains "$content" "EXIT_PLUGIN_ERROR=3" "EXIT_PLUGIN_ERROR should be defined as 3"
  assert_contains "$content" "EXIT_REPORT_ERROR=4" "EXIT_REPORT_ERROR should be defined as 4"
  assert_contains "$content" "EXIT_WORKSPACE_ERROR=5" "EXIT_WORKSPACE_ERROR should be defined as 5"
}

# Test 6: Exit codes are readonly constants
test_exit_codes_readonly() {
  local content
  content=$(cat "$SCRIPT_PATH")
  
  # Check if exit codes are defined as readonly
  if echo "$content" | grep -q "readonly.*EXIT_SUCCESS\|EXIT_SUCCESS.*readonly"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Exit codes should be readonly constants"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Exit codes should be defined as readonly"
  fi
}

# Run all tests
test_exit_success_help
test_exit_success_version
test_exit_invalid_args
test_exit_invalid_args_unexpected
test_exit_code_constants_defined
test_exit_codes_readonly

finish_test_suite "Exit Codes"
exit $?
