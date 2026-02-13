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

# Unit Tests: Version Information
# Tests the version display functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/doc.doc.sh"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Version Information"

# Test 1: --version flag shows version
test_version_flag() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --version
  
  assert_contains "$output" "version" "--version should display version information"
  assert_exit_code 0 $exit_code "--version should exit with code 0"
}

# Test 2: Version follows Semantic Timestamp Versioning (ADR-0012)
test_semantic_timestamp_versioning() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --version
  
  # Look for pattern like YYYY_NAME_MMDD.SECONDS
  if echo "$output" | grep -qE '[0-9]{4}_[A-Z][A-Za-z]+_[0-9]{4}\.[0-9]+'; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Version follows Semantic Timestamp Versioning format (ADR-0012)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Version should follow Semantic Timestamp Versioning (YYYY_NAME_MMDD.SECONDS)"
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
test_semantic_timestamp_versioning
test_version_includes_name
test_version_copyright
test_version_license

finish_test_suite "Version Information"
exit $?
