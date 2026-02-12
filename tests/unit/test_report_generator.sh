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

# Test: orchestration/report_generator.sh component
# Tests report generation, target directory validation, and output file creation

# Determine repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load test helpers
source "${REPO_ROOT}/tests/helpers/test_helpers.sh"

# ==============================================================================
# Test Setup and Teardown
# ==============================================================================

TEST_REPORT_DIR="/tmp/report_gen_test_$$"

setup_test() {
  # Source dependencies
  source "${REPO_ROOT}/scripts/components/core/constants.sh"
  source "${REPO_ROOT}/scripts/components/core/logging.sh"
  source "${REPO_ROOT}/scripts/components/core/error_handling.sh"
  source "${REPO_ROOT}/scripts/components/orchestration/workspace.sh"
  source "${REPO_ROOT}/scripts/components/orchestration/template_engine.sh"

  # Source the component under test
  source "${REPO_ROOT}/scripts/components/orchestration/report_generator.sh"

  # Create test fixture directory
  mkdir -p "${TEST_REPORT_DIR}"
}

teardown_test() {
  if [[ -d "${TEST_REPORT_DIR}" ]]; then
    rm -rf "${TEST_REPORT_DIR}"
  fi
}

# ==============================================================================
# Tests: Function Existence
# ==============================================================================

test_generate_reports_function_exists() {
  if declare -f generate_reports >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: generate_reports function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: generate_reports function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_generate_aggregated_report_function_exists() {
  if declare -f generate_aggregated_report >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: generate_aggregated_report function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: generate_aggregated_report function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_init_target_directory_function_exists() {
  if declare -f init_target_directory >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: init_target_directory function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: init_target_directory function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

# ==============================================================================
# Tests: Target Directory Initialization
# ==============================================================================

test_init_target_directory_creates_directory() {
  local target_dir="${TEST_REPORT_DIR}/new_target"

  local output exit_code
  run_command output exit_code init_target_directory "$target_dir"

  assert_exit_code 0 "$exit_code" "init_target_directory should succeed"

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -d "$target_dir" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Target directory was created"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Target directory should be created"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_init_target_directory_handles_existing() {
  local target_dir="${TEST_REPORT_DIR}/existing_target"
  mkdir -p "$target_dir"
  echo "marker" > "$target_dir/marker.txt"

  local output exit_code
  run_command output exit_code init_target_directory "$target_dir"

  assert_exit_code 0 "$exit_code" "Should handle existing target directory"

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -f "$target_dir/marker.txt" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Existing files preserved in target directory"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should preserve existing files"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_init_target_directory_rejects_empty_argument() {
  local output exit_code
  run_command output exit_code init_target_directory ""

  assert_exit_code 1 "$exit_code" "Should reject empty target directory argument"
}

test_init_target_directory_rejects_path_traversal() {
  local output exit_code
  run_command output exit_code init_target_directory "${TEST_REPORT_DIR}/../../../etc/hack"

  assert_exit_code 1 "$exit_code" "Should reject path traversal attempts"
}

# ==============================================================================
# Tests: Report Generation
# ==============================================================================

test_generate_reports_creates_output_files() {
  local ws_dir="${TEST_REPORT_DIR}/workspace"
  local target_dir="${TEST_REPORT_DIR}/target"
  local template_file="${TEST_REPORT_DIR}/template.md"

  # Setup workspace with test data
  init_workspace "$ws_dir" 2>/dev/null
  echo '# ${filename}' > "$template_file"

  # Save some workspace data
  save_workspace "$ws_dir" "testhash1" '{"file_path":"/test/file1.txt","stat":{"file_size":100}}' 2>/dev/null

  local output exit_code
  run_command output exit_code generate_reports "$ws_dir" "$target_dir" "$template_file"

  assert_exit_code 0 "$exit_code" "generate_reports should succeed"

  # Check output files exist in target directory
  local output_count
  output_count=$(find "$target_dir" -name "*.md" -type f 2>/dev/null | wc -l)

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$output_count" -ge 1 ]]; then
    echo -e "${GREEN}✓${NC} PASS: Report files created in target directory ($output_count files)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Expected report files in target directory, found $output_count"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_generate_reports_rejects_empty_workspace() {
  local target_dir="${TEST_REPORT_DIR}/target_empty"
  local template_file="${TEST_REPORT_DIR}/template_empty.md"
  echo '# Report' > "$template_file"

  local output exit_code
  run_command output exit_code generate_reports "" "$target_dir" "$template_file"

  assert_exit_code 1 "$exit_code" "Should reject empty workspace directory"
}

test_generate_reports_rejects_empty_target() {
  local ws_dir="${TEST_REPORT_DIR}/workspace_notarget"
  init_workspace "$ws_dir" 2>/dev/null
  local template_file="${TEST_REPORT_DIR}/template_notarget.md"
  echo '# Report' > "$template_file"

  local output exit_code
  run_command output exit_code generate_reports "$ws_dir" "" "$template_file"

  assert_exit_code 1 "$exit_code" "Should reject empty target directory"
}

test_generate_reports_rejects_missing_template() {
  local ws_dir="${TEST_REPORT_DIR}/workspace_notemplate"
  local target_dir="${TEST_REPORT_DIR}/target_notemplate"
  init_workspace "$ws_dir" 2>/dev/null

  local output exit_code
  run_command output exit_code generate_reports "$ws_dir" "$target_dir" "/nonexistent/template.md"

  assert_exit_code 1 "$exit_code" "Should reject missing template file"
}

test_generate_reports_handles_empty_workspace_gracefully() {
  local ws_dir="${TEST_REPORT_DIR}/workspace_nodata"
  local target_dir="${TEST_REPORT_DIR}/target_nodata"
  local template_file="${TEST_REPORT_DIR}/template_nodata.md"

  init_workspace "$ws_dir" 2>/dev/null
  echo '# Report' > "$template_file"

  # No workspace data files exist
  local output exit_code
  run_command output exit_code generate_reports "$ws_dir" "$target_dir" "$template_file"

  assert_exit_code 0 "$exit_code" "Should succeed even with empty workspace (no files to report)"
}

# ==============================================================================
# Tests: Aggregated Report
# ==============================================================================

test_generate_aggregated_report_creates_file() {
  local ws_dir="${TEST_REPORT_DIR}/workspace_agg"
  local target_dir="${TEST_REPORT_DIR}/target_agg"

  init_workspace "$ws_dir" 2>/dev/null
  mkdir -p "$target_dir"

  save_workspace "$ws_dir" "agghash1" '{"file_path":"/test/a.txt","stat":{"file_size":50}}' 2>/dev/null
  save_workspace "$ws_dir" "agghash2" '{"file_path":"/test/b.txt","stat":{"file_size":75}}' 2>/dev/null

  local output exit_code
  run_command output exit_code generate_aggregated_report "$ws_dir" "$target_dir/summary.md"

  assert_exit_code 0 "$exit_code" "generate_aggregated_report should succeed"
  assert_file_exists "$target_dir/summary.md" "Aggregated report file should be created"
}

# ==============================================================================
# Test Execution
# ==============================================================================

main() {
  start_test_suite "orchestration/report_generator.sh"

  setup_test

  # Function existence tests
  test_generate_reports_function_exists
  test_generate_aggregated_report_function_exists
  test_init_target_directory_function_exists

  # Target directory initialization tests
  test_init_target_directory_creates_directory
  test_init_target_directory_handles_existing
  test_init_target_directory_rejects_empty_argument
  test_init_target_directory_rejects_path_traversal

  # Report generation tests
  test_generate_reports_creates_output_files
  test_generate_reports_rejects_empty_workspace
  test_generate_reports_rejects_empty_target
  test_generate_reports_rejects_missing_template
  test_generate_reports_handles_empty_workspace_gracefully

  # Aggregated report tests
  test_generate_aggregated_report_creates_file

  teardown_test

  finish_test_suite "orchestration/report_generator.sh"
}

# Run tests
main

exit $?
