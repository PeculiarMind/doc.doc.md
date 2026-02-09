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

# Unit Tests: Verbose Logging
# Tests the verbose logging infrastructure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/doc.doc.sh"
COMPONENTS_DIR="$PROJECT_ROOT/scripts/components"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Verbose Logging"

# Test 1: VERBOSE variable exists in logging.sh component
test_verbose_flag_enables_logging() {
  local content
  content=$(cat "$COMPONENTS_DIR/core/logging.sh")
  
  assert_contains "$content" "VERBOSE" "logging.sh component should have VERBOSE variable"
}

# Test 2: Log function exists in logging.sh component
test_log_function_exists() {
  local content
  content=$(cat "$COMPONENTS_DIR/core/logging.sh")
  
  assert_contains "$content" "log()" "logging.sh should define log() function"
}

# Test 3: Log function checks VERBOSE flag
test_log_checks_verbose_flag() {
  local content
  content=$(cat "$COMPONENTS_DIR/core/logging.sh")
  
  # Log function should check VERBOSE variable
  if echo "$content" | grep -A 10 "log()" | grep -q "VERBOSE"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: log() function should check VERBOSE flag"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: log() function should check VERBOSE flag"
  fi
}

# Test 4: Log function supports multiple levels
test_log_levels() {
  local content
  content=$(cat "$COMPONENTS_DIR/core/logging.sh")
  
  # Log function should accept level parameter (INFO, WARN, ERROR, DEBUG)
  if echo "$content" | grep -A 20 "log()" | grep -qE "INFO|WARN|ERROR|DEBUG"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: log() function should support log levels"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: log() function should support INFO, WARN, ERROR, DEBUG levels"
  fi
}

# Test 5: Verbose output goes to stderr
test_verbose_output_to_stderr() {
  local content
  content=$(cat "$COMPONENTS_DIR/core/logging.sh")
  
  # Log function should redirect to stderr (>&2)
  if echo "$content" | grep -A 20 "log()" | grep -q ">&2\|>&2"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Verbose output should go to stderr"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Log output should be redirected to stderr"
  fi
}

# Test 6: Log messages have consistent prefix
test_log_prefix() {
  local content
  content=$(cat "$COMPONENTS_DIR/core/logging.sh")
  
  # Log function should add prefix like [INFO], [ERROR], etc.
  if echo "$content" | grep -A 20 "log()" | grep -qE '\[.*\]|\$\{.*\}'; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Log messages should have consistent prefix"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Log messages should include level prefix"
  fi
}

# Test 7: ERROR and WARN always shown (even without -v)
test_error_warn_always_shown() {
  local content
  content=$(cat "$COMPONENTS_DIR/core/logging.sh")
  
  # ERROR and WARN should be shown regardless of VERBOSE flag
  if echo "$content" | grep -A 20 "log()" | grep -E 'ERROR.*WARN|level.*==.*"ERROR".*level.*==.*"WARN"'; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: ERROR and WARN should always be shown"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: ERROR and WARN should be shown without -v flag"
  fi
}

# Run all tests
test_verbose_flag_enables_logging
test_log_function_exists
test_log_checks_verbose_flag
test_log_levels
test_verbose_output_to_stderr
test_log_prefix
test_error_warn_always_shown

finish_test_suite "Verbose Logging"
exit $?
