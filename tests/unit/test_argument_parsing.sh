#!/usr/bin/env bash
# Unit Tests: Argument Parsing
# Tests command-line argument parsing logic

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/doc.doc.sh"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Argument Parsing"

# Test 1: Invalid option shows error
test_invalid_option() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -x
  
  assert_contains "$output" "Error" "Invalid option should show error message"
  assert_exit_code 1 $exit_code "Invalid option should exit with code 1 (EXIT_INVALID_ARGS)"
}

# Test 2: Unknown option shows error and help
test_unknown_option_shows_help() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --invalid
  
  assert_contains "$output" "Error" "Unknown option should show error"
  assert_exit_code 1 $exit_code "Unknown option should exit with code 1"
}

# Test 3: -v flag is recognized
test_verbose_flag_short() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -v --help
  
  # When verbose is set, help should still work
  assert_exit_code 0 $exit_code "-v flag should be recognized"
}

# Test 4: --verbose flag is recognized
test_verbose_flag_long() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --verbose --help
  
  assert_exit_code 0 $exit_code "--verbose flag should be recognized"
}

# Test 5: Multiple flags can be combined
test_multiple_flags() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -v -h
  
  assert_exit_code 0 $exit_code "Multiple flags should be parsed correctly"
}

# Test 6: Unexpected positional argument shows error
test_unexpected_argument() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" unexpected_arg
  
  assert_contains "$output" "Error" "Unexpected argument should show error"
  assert_exit_code 1 $exit_code "Unexpected argument should exit with code 1"
}

# Test 7: Empty arguments (no args) handling
test_no_arguments() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH"
  
  # Script might show help or error when no args provided
  # Should exit with appropriate code (0 for help, or 1 for error)
  if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: No arguments handled with exit code 0 or 1"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: No arguments should exit with 0 or 1, got $exit_code"
  fi
}

# Test 8: Error messages go to stderr
test_error_to_stderr() {
  local stdout stderr combined exit_code
  
  # Capture stdout and stderr separately
  stdout=$("$SCRIPT_PATH" -x 2>/dev/null) || true
  stderr=$("$SCRIPT_PATH" -x 2>&1 >/dev/null) || true
  
  # Error message should be in stderr, not stdout
  if [[ -n "$stderr" ]] && [[ -z "$stdout" || "$stdout" == "" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Error messages go to stderr"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Error messages should go to stderr"
  fi
}

# Run all tests
test_invalid_option
test_unknown_option_shows_help
test_verbose_flag_short
test_verbose_flag_long
test_multiple_flags
test_unexpected_argument
test_no_arguments
test_error_to_stderr

finish_test_suite "Argument Parsing"
exit $?
