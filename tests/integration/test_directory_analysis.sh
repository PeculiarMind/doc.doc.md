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

# Integration Tests: Directory Analysis Workflow
# Tests the end-to-end directory scan and plugin analysis pipeline

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/doc.doc.sh"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Directory Analysis Integration"

# Helper: create a temporary test environment
setup_test_env() {
  local test_dir
  test_dir=$(mktemp -d "/tmp/doc_doc_test_XXXXXX")

  # Create source directory with test files
  mkdir -p "$test_dir/source"
  echo "Hello World" > "$test_dir/source/file1.txt"
  echo "Test Data" > "$test_dir/source/file2.txt"
  echo '{"key": "value"}' > "$test_dir/source/data.json"

  # Create workspace, target, template directories/files
  mkdir -p "$test_dir/workspace"
  mkdir -p "$test_dir/target"
  echo "template content" > "$test_dir/template.md"

  echo "$test_dir"
}

# Helper: cleanup test environment
cleanup_test_env() {
  local test_dir="$1"
  rm -rf "$test_dir" 2>/dev/null || true
}

# Test 1: Directory scan discovers files and creates workspace data
test_directory_scan_discovers_files() {
  local test_dir
  test_dir=$(setup_test_env)

  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" \
    -d "$test_dir/source" \
    -w "$test_dir/workspace" \
    -t "$test_dir/target" \
    -m "$test_dir/template.md"

  assert_exit_code 0 $exit_code "Directory analysis should complete successfully"

  # Workspace should have files/ directory with JSON data
  local workspace_files
  workspace_files=$(find "$test_dir/workspace/files" -name "*.json" -type f 2>/dev/null | wc -l)

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$workspace_files" -ge 1 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Workspace contains $workspace_files JSON file(s) from scanned files"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Expected workspace JSON files, found $workspace_files"
  fi

  assert_contains "$output" "Analysis complete" "Output should contain analysis summary"

  cleanup_test_env "$test_dir"
}

# Test 2: Stat plugin executes and workspace JSON contains stat results
test_stat_plugin_results() {
  local test_dir
  test_dir=$(setup_test_env)

  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" \
    -d "$test_dir/source" \
    -w "$test_dir/workspace" \
    -t "$test_dir/target" \
    -m "$test_dir/template.md"

  assert_exit_code 0 $exit_code "Analysis with stat plugin should succeed"

  # Check that at least one workspace JSON file contains stat results
  local found_stat_data=false
  for json_file in "$test_dir/workspace/files"/*.json; do
    [[ -f "$json_file" ]] || continue
    if jq -e '.stat.file_last_modified' "$json_file" >/dev/null 2>&1 && \
       jq -e '.stat.file_size' "$json_file" >/dev/null 2>&1 && \
       jq -e '.stat.file_owner' "$json_file" >/dev/null 2>&1; then
      found_stat_data=true
      break
    fi
  done

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$found_stat_data" == "true" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Workspace JSON contains stat plugin results (file_last_modified, file_size, file_owner)"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Expected stat plugin results in workspace JSON"
    # Show debug info
    for json_file in "$test_dir/workspace/files"/*.json; do
      [[ -f "$json_file" ]] || continue
      echo "  Debug: $(cat "$json_file" 2>/dev/null | head -c 200)"
      break
    done
  fi

  cleanup_test_env "$test_dir"
}

# Test 3: Progress is suppressed in non-interactive mode
test_progress_suppressed_noninteractive() {
  local test_dir
  test_dir=$(setup_test_env)

  local output exit_code
  run_command output exit_code env DOC_DOC_INTERACTIVE=false "$SCRIPT_PATH" \
    -d "$test_dir/source" \
    -w "$test_dir/workspace" \
    -t "$test_dir/target" \
    -m "$test_dir/template.md"

  assert_exit_code 0 $exit_code "Non-interactive analysis should succeed"

  # Progress bar characters should not appear in non-interactive output
  assert_not_contains "$output" "████" "Progress bar should not appear in non-interactive mode"
  assert_not_contains "$output" "░░░░" "Progress bar empty chars should not appear in non-interactive mode"

  cleanup_test_env "$test_dir"
}

# Test 4: Error handling when source directory doesn't exist
test_error_nonexistent_source() {
  local test_dir
  test_dir=$(setup_test_env)

  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" \
    -d "/tmp/nonexistent_dir_doc_doc_test" \
    -w "$test_dir/workspace" \
    -t "$test_dir/target" \
    -m "$test_dir/template.md"

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ $exit_code -ne 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Non-existent source directory returns error exit code"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Expected error exit code for non-existent source directory, got $exit_code"
  fi

  assert_contains "$output" "does not exist" "Error message should mention directory does not exist"

  cleanup_test_env "$test_dir"
}

# Test 5: Workspace is initialized correctly
test_workspace_initialization() {
  local test_dir
  test_dir=$(setup_test_env)

  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" \
    -d "$test_dir/source" \
    -w "$test_dir/workspace" \
    -t "$test_dir/target" \
    -m "$test_dir/template.md"

  assert_exit_code 0 $exit_code "Analysis should succeed for workspace initialization test"

  # Check workspace directory structure
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -d "$test_dir/workspace/files" ]] && [[ -d "$test_dir/workspace/plugins" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Workspace has correct directory structure (files/ and plugins/)"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Workspace missing expected directories"
  fi

  # Check workspace.json exists with last_full_scan
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -f "$test_dir/workspace/workspace.json" ]] && \
     jq -e '.last_full_scan' "$test_dir/workspace/workspace.json" >/dev/null 2>&1; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: workspace.json contains last_full_scan timestamp"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: workspace.json missing or lacks last_full_scan"
  fi

  cleanup_test_env "$test_dir"
}

# Test 6: Reports are generated in target directory (bug_0001 regression test)
test_target_directory_has_reports() {
  local test_dir
  test_dir=$(setup_test_env)

  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" \
    -d "$test_dir/source" \
    -w "$test_dir/workspace" \
    -t "$test_dir/target" \
    -m "$test_dir/template.md"

  assert_exit_code 0 $exit_code "Analysis should succeed for target directory report test"

  # Check that report files exist in target directory
  local report_count
  report_count=$(find "$test_dir/target" -name "*.md" -type f 2>/dev/null | wc -l)

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$report_count" -ge 1 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Target directory contains $report_count report file(s)"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Expected report files in target directory, found $report_count"
  fi

  # Verify report content is non-empty
  local first_report
  first_report=$(find "$test_dir/target" -name "*.md" -type f 2>/dev/null | head -1)
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -n "$first_report" ]] && [[ -s "$first_report" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Report file has content"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Report file should have content"
  fi

  assert_contains "$output" "Report generation complete" "Output should confirm report generation"

  cleanup_test_env "$test_dir"
}

# Run all tests
test_directory_scan_discovers_files
test_stat_plugin_results
test_progress_suppressed_noninteractive
test_error_nonexistent_source
test_workspace_initialization
test_target_directory_has_reports

finish_test_suite "Directory Analysis Integration"
exit $?
