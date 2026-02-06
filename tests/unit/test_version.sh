#!/usr/bin/env bash
# Unit Tests: Version Information
# Tests the version display functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/doc.doc.sh"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Version Information"

# Test 1: --version flag shows version
test_version_flag() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --version
  
  assert_contains "$output" "version" "--version should display version information"
  assert_exit_code 0 $exit_code "--version should exit with code 0"
}

# Test 2: Version follows semantic versioning
test_semantic_versioning() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --version
  
  # Look for pattern like X.Y.Z
  if echo "$output" | grep -qE '[0-9]+\.[0-9]+\.[0-9]+'; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Version follows semantic versioning format"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Version should follow semantic versioning (X.Y.Z)"
    echo "  Output: $output"
  fi
}

# Test 3: Version includes script name
test_version_includes_name() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --version
  
  assert_contains "$output" "doc.doc" "Version output should include script name"
}

# Test 4: Version includes copyright information
test_version_copyright() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --version
  
  assert_contains "$output" "Copyright" "Version should include copyright information"
}

# Test 5: Version includes license information
test_version_license() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --version
  
  assert_contains "$output" "License" "Version should include license information"
}

# Run all tests
test_version_flag
test_semantic_versioning
test_version_includes_name
test_version_copyright
test_version_license

finish_test_suite "Version Information"
exit $?
