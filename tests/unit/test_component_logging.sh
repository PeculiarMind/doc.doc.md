#!/usr/bin/env bash
# Test: core/logging.sh component

# Determine repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load test helpers
source "${REPO_ROOT}/tests/helpers/test_helpers.sh"

# ==============================================================================
# Test Setup
# ==============================================================================

setup_test() {
  # Source dependencies
  source "${REPO_ROOT}/scripts/components/core/constants.sh"
  
  # Source the component
  source "${REPO_ROOT}/scripts/components/core/logging.sh"
}

# ==============================================================================
# Tests
# ==============================================================================

test_log_function_exists() {
  if declare -f log >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: log function exists"
  else
    echo -e "${RED}✗${NC} FAIL: log function should exist"
  fi
}

test_set_log_level_function_exists() {
  if declare -f set_log_level >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: set_log_level function exists"
  else
    echo -e "${RED}✗${NC} FAIL: set_log_level function should exist"
  fi
}

test_is_verbose_function_exists() {
  if declare -f is_verbose >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: is_verbose function exists"
  else
    echo -e "${RED}✗${NC} FAIL: is_verbose function should exist"
  fi
}

test_log_error_messages_always_shown() {
  set_log_level false
  local output
  output=$(log "ERROR" "Test error message" 2>&1)
  assert_contains "${output}" "[ERROR] Test error message" "Error message shown"
}

test_log_warn_messages_always_shown() {
  set_log_level false
  local output
  output=$(log "WARN" "Test warning message" 2>&1)
  assert_contains "${output}" "[WARN] Test warning message" "Warning message shown"
}

test_log_info_messages_hidden_without_verbose() {
  set_log_level false
  local output
  output=$(log "INFO" "Test info message" 2>&1)
  if [[ -z "${output}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Info message hidden without verbose"
  else
    echo -e "${RED}✗${NC} FAIL: Info message should be hidden without verbose"
  fi
}

test_log_info_messages_shown_with_verbose() {
  set_log_level true
  local output
  output=$(log "INFO" "Test info message" 2>&1)
  assert_contains "${output}" "[INFO] Test info message" "Info message shown with verbose"
}

test_log_debug_messages_hidden_without_verbose() {
  set_log_level false
  local output
  output=$(log "DEBUG" "Test debug message" 2>&1)
  if [[ -z "${output}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Debug message hidden without verbose"
  else
    echo -e "${RED}✗${NC} FAIL: Debug message should be hidden without verbose"
  fi
}

test_log_debug_messages_shown_with_verbose() {
  set_log_level true
  local output
  output=$(log "DEBUG" "Test debug message" 2>&1)
  assert_contains "${output}" "[DEBUG] Test debug message" "Debug message shown with verbose"
}

test_is_verbose_returns_correct_status() {
  set_log_level false
  if is_verbose; then
    echo -e "${RED}✗${NC} FAIL: is_verbose should return false when verbose is disabled"
  else
    echo -e "${GREEN}✓${NC} PASS: is_verbose returns false when verbose disabled"
  fi
  
  set_log_level true
  if ! is_verbose; then
    echo -e "${RED}✗${NC} FAIL: is_verbose should return true when verbose is enabled"
  else
    echo -e "${GREEN}✓${NC} PASS: is_verbose returns true when verbose enabled"
  fi
}

# ==============================================================================
# Test Execution
# ==============================================================================

echo "=== Running Test Suite: Component core/logging.sh ==="
echo

setup_test

test_log_function_exists
test_set_log_level_function_exists
test_is_verbose_function_exists
test_log_error_messages_always_shown
test_log_warn_messages_always_shown
test_log_info_messages_hidden_without_verbose
test_log_info_messages_shown_with_verbose
test_log_debug_messages_hidden_without_verbose
test_log_debug_messages_shown_with_verbose
test_is_verbose_returns_correct_status

echo
echo "=== Test Suite Complete: Component core/logging.sh ==="
