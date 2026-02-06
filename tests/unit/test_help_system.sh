#!/usr/bin/env bash
# Unit Tests: Help System
# Tests the help display functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/doc.doc.sh"

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

# Run all tests
test_help_short_flag
test_help_long_flag
test_help_shows_script_name
test_help_shows_options
test_help_shows_examples
test_help_option_descriptions
test_help_formatting

finish_test_suite "Help System"
exit $?
