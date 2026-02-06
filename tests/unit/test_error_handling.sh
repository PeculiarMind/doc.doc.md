#!/usr/bin/env bash
# Unit Tests: Error Handling
# Tests the error handling framework

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/doc.doc.sh"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Error Handling"

# Test 1: Script uses bash strict mode
test_bash_strict_mode() {
  local content
  content=$(cat "$SCRIPT_PATH")
  
  # Should have set -e, set -u, and/or set -o pipefail
  if echo "$content" | grep -qE "set -[euo]+|set -o pipefail"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Script uses bash strict mode"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Script should use strict mode (set -euo pipefail)"
  fi
}

# Test 2: Error messages go to stderr
test_errors_to_stderr() {
  local stdout stderr
  
  stdout=$("$SCRIPT_PATH" -x 2>/dev/null) || true
  stderr=$("$SCRIPT_PATH" -x 2>&1 >/dev/null) || true
  
  if [[ -n "$stderr" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Error messages go to stderr"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Error messages should go to stderr"
  fi
}

# Test 3: Error messages include context
test_error_context() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -x
  
  # Error message should include what went wrong (option name)
  assert_contains "$output" "-x" "Error message should include context (the invalid option)"
}

# Test 4: Errors trigger appropriate exit codes
test_error_exit_codes() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -x
  
  # Invalid argument should exit with code 1
  assert_exit_code 1 $exit_code "Errors should trigger appropriate exit codes"
}

# Test 5: Error messages are user-friendly
test_user_friendly_errors() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -x
  
  # Error should contain "Error" or "error" keyword
  if echo "$output" | grep -qiE "error|unknown|invalid"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Error messages are user-friendly"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Error messages should be clear and user-friendly"
  fi
}

# Run all tests
test_bash_strict_mode
test_errors_to_stderr
test_error_context
test_error_exit_codes
test_user_friendly_errors

finish_test_suite "Error Handling"
exit $?
