#!/usr/bin/env bash
# Test: core/constants.sh component

# Determine repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load test helpers
source "${REPO_ROOT}/tests/helpers/test_helpers.sh"

# ==============================================================================
# Test Setup
# ==============================================================================

setup_test() {
  # Source the component
  source "${REPO_ROOT}/scripts/components/core/constants.sh"
}

# ==============================================================================
# Tests
# ==============================================================================

test_script_metadata_constants() {
  assert_equals "doc.doc.sh" "${SCRIPT_NAME}" "SCRIPT_NAME constant"
  assert_equals "1.0.0" "${SCRIPT_VERSION}" "SCRIPT_VERSION constant"
  assert_equals "GPL-3.0" "${SCRIPT_LICENSE}" "SCRIPT_LICENSE constant"
  
  # Check non-empty constants
  if [[ -n "${SCRIPT_DIR}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: SCRIPT_DIR constant is not empty"
  else
    echo -e "${RED}✗${NC} FAIL: SCRIPT_DIR constant should not be empty"
  fi
  
  if [[ -n "${SCRIPT_COPYRIGHT}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: SCRIPT_COPYRIGHT constant is not empty"
  else
    echo -e "${RED}✗${NC} FAIL: SCRIPT_COPYRIGHT constant should not be empty"
  fi
}

test_exit_code_constants() {
  assert_equals "0" "${EXIT_SUCCESS}" "EXIT_SUCCESS constant"
  assert_equals "1" "${EXIT_INVALID_ARGS}" "EXIT_INVALID_ARGS constant"
  assert_equals "2" "${EXIT_FILE_ERROR}" "EXIT_FILE_ERROR constant"
  assert_equals "3" "${EXIT_PLUGIN_ERROR}" "EXIT_PLUGIN_ERROR constant"
  assert_equals "4" "${EXIT_REPORT_ERROR}" "EXIT_REPORT_ERROR constant"
  assert_equals "5" "${EXIT_WORKSPACE_ERROR}" "EXIT_WORKSPACE_ERROR constant"
}

test_constants_are_readonly() {
  # Try to modify a constant (should fail silently or error)
  local test_result=0
  SCRIPT_NAME="modified" 2>/dev/null || test_result=$?
  
  # Constant should still have original value
  assert_equals "doc.doc.sh" "${SCRIPT_NAME}" "Constant immutability"
}

# ==============================================================================
# Test Execution
# ==============================================================================

echo "=== Running Test Suite: Component core/constants.sh ==="
echo

setup_test

test_script_metadata_constants
test_exit_code_constants
test_constants_are_readonly

echo
echo "=== Test Suite Complete: Component core/constants.sh ==="
