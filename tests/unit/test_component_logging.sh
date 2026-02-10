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
  output=$(log "ERROR" "TEST" "Test error message" 2>&1)
  assert_contains "${output}" "[ERROR]" "Error message shown"
  assert_contains "${output}" "[TEST]" "Component shown in error message"
  assert_contains "${output}" "Test error message" "Message content shown"
}

test_log_warn_messages_always_shown() {
  set_log_level false
  local output
  output=$(log "WARN" "TEST" "Test warning message" 2>&1)
  assert_contains "${output}" "[WARN]" "Warning message shown"
  assert_contains "${output}" "[TEST]" "Component shown in warning message"
  assert_contains "${output}" "Test warning message" "Message content shown"
}

test_log_info_messages_hidden_without_verbose() {
  set_log_level false
  local output
  output=$(log "INFO" "TEST" "Test info message" 2>&1)
  if [[ -z "${output}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Info message hidden without verbose"
  else
    echo -e "${RED}✗${NC} FAIL: Info message should be hidden without verbose"
  fi
}

test_log_info_messages_shown_with_verbose() {
  set_log_level true
  local output
  output=$(log "INFO" "TEST" "Test info message" 2>&1)
  assert_contains "${output}" "[INFO]" "Info message shown with verbose"
  assert_contains "${output}" "[TEST]" "Component shown in info message"
  assert_contains "${output}" "Test info message" "Message content shown"
}

test_log_debug_messages_hidden_without_verbose() {
  set_log_level false
  local output
  output=$(log "DEBUG" "TEST" "Test debug message" 2>&1)
  if [[ -z "${output}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Debug message hidden without verbose"
  else
    echo -e "${RED}✗${NC} FAIL: Debug message should be hidden without verbose"
  fi
}

test_log_debug_messages_shown_with_verbose() {
  set_log_level true
  local output
  output=$(log "DEBUG" "TEST" "Test debug message" 2>&1)
  assert_contains "${output}" "[DEBUG]" "Debug message shown with verbose"
  assert_contains "${output}" "[TEST]" "Component shown in debug message"
  assert_contains "${output}" "Test debug message" "Message content shown"
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

test_log_format_includes_timestamp() {
  set_log_level true
  local output
  output=$(log "INFO" "TEST" "Test message" 2>&1)
  # Check for ISO 8601 timestamp format: YYYY-MM-DDTHH:MM:SS
  if [[ "${output}" =~ \[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\] ]]; then
    echo -e "${GREEN}✓${NC} PASS: Log includes ISO 8601 timestamp"
  else
    echo -e "${RED}✗${NC} FAIL: Log should include ISO 8601 timestamp"
  fi
}

test_log_format_matches_specification() {
  set_log_level true
  local output
  output=$(log "INFO" "COMPONENT" "Test message" 2>&1)
  # Format should be: [TIMESTAMP] [LEVEL] [COMPONENT] Message
  if [[ "${output}" =~ ^\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\]\ \[INFO\]\ \[COMPONENT\]\ Test\ message$ ]]; then
    echo -e "${GREEN}✓${NC} PASS: Log format matches specification [TIMESTAMP] [LEVEL] [COMPONENT] Message"
  else
    echo -e "${RED}✗${NC} FAIL: Log format should match [TIMESTAMP] [LEVEL] [COMPONENT] Message"
  fi
}

test_log_preserves_special_characters() {
  set_log_level true
  local output
  output=$(log "INFO" "TEST" "Message with 'quotes' and \"double quotes\"" 2>&1)
  assert_contains "${output}" "'quotes'" "Single quotes preserved"
  assert_contains "${output}" "\"double quotes\"" "Double quotes preserved"
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
test_log_format_includes_timestamp
test_log_format_matches_specification
test_log_preserves_special_characters

echo
echo "=== Test Suite Complete: Component core/logging.sh ==="
