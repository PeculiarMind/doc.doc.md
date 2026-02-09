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
COMPONENTS_DIR="$PROJECT_ROOT/scripts/components"

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

# Test 4: Script location determined dynamically in constants.sh component
test_dynamic_script_location() {
  local main_content component_content
  main_content=$(cat "$SCRIPT_PATH")
  component_content=$(cat "$COMPONENTS_DIR/core/constants.sh")
  
  # Main script should load components directory
  assert_contains "$main_content" "COMPONENTS_DIR" "Main script should define COMPONENTS_DIR"
  
  # constants.sh should define SCRIPT_DIR using BASH_SOURCE
  assert_contains "$component_content" "SCRIPT_DIR" "constants.sh should define SCRIPT_DIR variable"
  
  if echo "$component_content" | grep -q "dirname.*BASH_SOURCE"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Script determines location dynamically"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: constants.sh should determine location using BASH_SOURCE"
  fi
}

# Test 5: Multiple verbose flags don't cause errors
test_multiple_verbose_flags() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -v -v --version
  
  assert_exit_code 0 $exit_code "Multiple verbose flags should not cause error"
}

# Test 6: Script constants properly defined in constants.sh component
test_constants_defined() {
  local content
  content=$(cat "$COMPONENTS_DIR/core/constants.sh")
  
  assert_contains "$content" "SCRIPT_NAME" "SCRIPT_NAME constant should be defined in constants.sh"
  assert_contains "$content" "SCRIPT_VERSION" "SCRIPT_VERSION constant should be defined in constants.sh"
}

# Test 7: Modular architecture with component loading
test_modular_functions() {
  local main_content
  main_content=$(cat "$SCRIPT_PATH")
  
  # In modular architecture, main script should be lightweight
  # Functions should be in component files, main script orchestrates
  local func_count component_func_count
  func_count=$(echo "$main_content" | grep -c "^[a-z_]*() {" || true)
  
  # Count functions across all component files
  component_func_count=$(find "$COMPONENTS_DIR" -name "*.sh" -exec grep -c "^[a-z_]*() {" {} \; | awk '{s+=$1} END {print s}')
  
  # Main script should have few functions (source_component, main), components have the rest
  if [[ $func_count -ge 2 ]] && [[ $component_func_count -ge 20 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}\u2713${NC} PASS: Modular architecture with $func_count main functions and $component_func_count component functions"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}\u2717${NC} FAIL: Expected modular architecture (main: $func_count, components: $component_func_count)"
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
