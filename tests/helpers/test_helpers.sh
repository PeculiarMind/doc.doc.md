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

# Test helper functions for doc.doc.sh test suite

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test assertion functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Values should be equal}"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: $message"
    echo "  Expected: '$expected'"
    echo "  Actual:   '$actual'"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Output should contain expected string}"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [[ "$haystack" == *"$needle"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: $message"
    echo "  Expected substring: '$needle'"
    echo "  In: '$haystack'"
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Output should not contain string}"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [[ "$haystack" != *"$needle"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: $message"
    echo "  Should not contain: '$needle'"
    echo "  In: '$haystack'"
    return 1
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Exit code should match}"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [[ "$expected" -eq "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: $message"
    echo "  Expected exit code: $expected"
    echo "  Actual exit code:   $actual"
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist}"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [[ -f "$file" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: $message"
    echo "  File not found: $file"
    return 1
  fi
}

assert_directory_exists() {
  local dir="$1"
  local message="${2:-Directory should exist}"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [[ -d "$dir" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: $message"
    echo "  Directory not found: $dir"
    return 1
  fi
}

assert_file_executable() {
  local file="$1"
  local message="${2:-File should be executable}"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [[ -x "$file" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: $message"
    echo "  File is not executable: $file"
    return 1
  fi
}

# Test suite management
start_test_suite() {
  local suite_name="$1"
  echo ""
  echo -e "${YELLOW}=== Running Test Suite: $suite_name ===${NC}"
  echo ""
}

finish_test_suite() {
  local suite_name="$1"
  echo ""
  echo -e "${YELLOW}=== Test Suite Complete: $suite_name ===${NC}"
  echo "Tests run: $TESTS_RUN"
  echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
  echo ""
  
  if [[ $TESTS_FAILED -gt 0 ]]; then
    return 1
  fi
  return 0
}

# Capture command output and exit code
run_command() {
  local output_var="$1"
  local exit_code_var="$2"
  shift 2
  local cmd=("$@")
  
  local temp_output
  local temp_exit
  set +e
  temp_output=$("${cmd[@]}" 2>&1)
  temp_exit=$?
  set -e
  
  eval "$output_var=\$temp_output"
  eval "$exit_code_var=\$temp_exit"
}
