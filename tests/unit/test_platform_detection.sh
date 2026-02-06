#!/usr/bin/env bash
# Unit Tests: Platform Detection
# Tests the platform detection functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/doc.doc.sh"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Platform Detection"

# Test 1: detect_platform function exists
test_detect_platform_exists() {
  local content
  content=$(cat "$SCRIPT_PATH")
  
  assert_contains "$content" "detect_platform" "Script should define detect_platform function"
}

# Test 2: Platform detection uses /etc/os-release
test_uses_os_release() {
  local content
  content=$(cat "$SCRIPT_PATH")
  
  assert_contains "$content" "/etc/os-release" "Platform detection should use /etc/os-release"
}

# Test 3: Platform detection has fallback
test_platform_fallback() {
  local content
  content=$(cat "$SCRIPT_PATH")
  
  # Should have fallback for when /etc/os-release is missing
  if echo "$content" | grep -A 20 "detect_platform" | grep -q "generic\|else"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Platform detection should have fallback"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Platform detection should default to 'generic' if detection fails"
  fi
}

# Test 4: Platform stored in variable
test_platform_variable() {
  local content
  content=$(cat "$SCRIPT_PATH")
  
  assert_contains "$content" "PLATFORM" "Platform should be stored in PLATFORM variable"
}

# Test 5: Platform detection logged in verbose mode
test_platform_logged() {
  local content
  content=$(cat "$SCRIPT_PATH")
  
  # detect_platform should call log function
  if echo "$content" | grep -A 20 "detect_platform" | grep -q "log"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Platform detection should log in verbose mode"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Platform detection should use log() for verbose output"
  fi
}

# Test 6: Platform detection checks file existence
test_checks_file_existence() {
  local content
  content=$(cat "$SCRIPT_PATH")
  
  # Should check if /etc/os-release exists before sourcing
  if echo "$content" | grep -A 20 "detect_platform" | grep -qE "\-f /etc/os-release|\-e /etc/os-release"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Should check if /etc/os-release exists"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Should check file existence before sourcing"
  fi
}

# Run all tests
test_detect_platform_exists
test_uses_os_release
test_platform_fallback
test_platform_variable
test_platform_logged
test_checks_file_existence

finish_test_suite "Platform Detection"
exit $?
