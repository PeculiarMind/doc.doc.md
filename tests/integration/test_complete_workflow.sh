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

# Integration Tests: Complete Workflow
# Tests integration of multiple components working together

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/doc.doc.sh"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Complete Workflow Integration"

# Test 1: Help flag works with verbose flag
test_help_with_verbose() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -v -h
  
  assert_contains "$output" "Usage" "Help should work with verbose flag"
  assert_exit_code 0 $exit_code "Help with verbose should exit with code 0"
}

# Test 2: Verbose flag order independence
test_verbose_order_independence() {
  local output1 exit_code1 output2 exit_code2
  
  run_command output1 exit_code1 "$SCRIPT_PATH" -v --help
  run_command output2 exit_code2 "$SCRIPT_PATH" --help -v
  
  assert_exit_code 0 $exit_code1 "Flags should work in any order (1)"
  assert_exit_code 0 $exit_code2 "Flags should work in any order (2)"
}

# Test 3: Script can be called from different directories
test_different_working_directories() {
  local output exit_code
  
  # Call from /tmp
  cd /tmp
  run_command output exit_code "$SCRIPT_PATH" --version
  assert_exit_code 0 $exit_code "Script should work from different working directory"
  
  # Return to original directory
  cd "$PROJECT_ROOT"
}

# Test 4: Script location determined dynamically
test_dynamic_script_location() {
  local content
  content=$(cat "$SCRIPT_PATH")
  
  # Script should determine its own location (SCRIPT_DIR)
  assert_contains "$content" "SCRIPT_DIR" "Script should define SCRIPT_DIR variable"
  
  if echo "$content" | grep -q "dirname.*BASH_SOURCE"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Script determines location dynamically"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Script should determine location using BASH_SOURCE"
  fi
}

# Test 5: Multiple verbose flags don't cause errors
test_multiple_verbose_flags() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -v -v --version
  
  assert_exit_code 0 $exit_code "Multiple verbose flags should not cause error"
}

# Test 6: Script constants are properly defined
test_constants_defined() {
  local content
  content=$(cat "$SCRIPT_PATH")
  
  assert_contains "$content" "SCRIPT_NAME" "SCRIPT_NAME constant should be defined"
  assert_contains "$content" "SCRIPT_VERSION" "SCRIPT_VERSION constant should be defined"
}

# Test 7: Functions are modular (not monolithic)
test_modular_functions() {
  local content
  content=$(cat "$SCRIPT_PATH")
  
  # Should have multiple function definitions
  local func_count
  func_count=$(echo "$content" | grep -c "^[a-z_]*() {" || true)
  
  if [[ $func_count -ge 5 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Script uses modular functions (found $func_count functions)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Script should have multiple functions for modularity (found $func_count)"
  fi
}

# Test 8: No hardcoded absolute paths
test_no_hardcoded_paths() {
  local content
  content=$(cat "$SCRIPT_PATH")
  
  # Check for suspicious hardcoded paths (excluding shebang)
  if echo "$content" | tail -n +2 | grep -qE '^[^#]*"/home/|^[^#]*"/usr/local/|^[^#]*"/opt/'; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Script should not contain hardcoded absolute paths"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: No hardcoded absolute paths found"
  fi
}

# Run all tests
test_help_with_verbose
test_verbose_order_independence
test_different_working_directories
test_dynamic_script_location
test_multiple_verbose_flags
test_constants_defined
test_modular_functions
test_no_hardcoded_paths

finish_test_suite "Complete Workflow Integration"
exit $?
