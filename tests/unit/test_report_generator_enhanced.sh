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

# Test: Enhanced report_generator.sh component (feature_0010)
# Tests all acceptance criteria from feature specification

# Determine repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load test helpers
source "${REPO_ROOT}/tests/helpers/test_helpers.sh"

# ==============================================================================
# Test Setup and Teardown
# ==============================================================================

TEST_REPORT_DIR="/tmp/report_gen_enhanced_test_$$"
TEST_WORKSPACE_DIR="${TEST_REPORT_DIR}/workspace"
TEST_TEMPLATE_FILE="${TEST_REPORT_DIR}/test.template"

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
  mkdir -p "${TEST_WORKSPACE_DIR}/files"
  
  # Create a sample template
  cat > "${TEST_TEMPLATE_FILE}" << 'EOF'
# Analysis Report: {{filename}}

**Generated**: {{generation_time}}

## File Information

- **Path**: `{{file_path}}`
- **Size**: {{file_size_human}}
- **Type**: {{file_type}}

## Content

{{#if content}}
Content exists: {{content}}
{{/if}}

{{#if tags}}
### Tags
{{#each tags}}
- {{this}} (index: {{@index}})
{{/each}}
{{/if}}
EOF

  # Create sample workspace JSON
  cat > "${TEST_WORKSPACE_DIR}/files/test_file1.json" << 'EOF'
{
  "file_path": "/test/file1.txt",
  "file_path_relative": "file1.txt",
  "file_size": 1024,
  "file_type": "text/plain",
  "last_scanned": "2026-02-12T10:00:00Z",
  "content": "Sample content",
  "tags": "tag1 tag2 tag3"
}
EOF

  cat > "${TEST_WORKSPACE_DIR}/files/test_file2.json" << 'EOF'
{
  "file_path": "/test/file2.md",
  "file_path_relative": "file2.md",
  "file_size": 2048,
  "file_type": "text/markdown",
  "last_scanned": "2026-02-12T11:00:00Z"
}
EOF
}

teardown_test() {
  if [[ -d "${TEST_REPORT_DIR}" ]]; then
    rm -rf "${TEST_REPORT_DIR}"
  fi
}

# ==============================================================================
# Tests: Function Existence
# ==============================================================================

test_load_template_function_exists() {
  if declare -f load_template >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: load_template function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: load_template function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_merge_workspace_data_function_exists() {
  if declare -f merge_workspace_data >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: merge_workspace_data function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: merge_workspace_data function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_write_report_function_exists() {
  if declare -f write_report >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: write_report function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: write_report function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_human_readable_size_function_exists() {
  if declare -f human_readable_size >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: human_readable_size function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: human_readable_size function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_format_date_iso8601_function_exists() {
  if declare -f format_date_iso8601 >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: format_date_iso8601 function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: format_date_iso8601 function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

# ==============================================================================
# Tests: Template Loading and Caching
# ==============================================================================

test_load_template_reads_file() {
  local output exit_code
  run_command output exit_code load_template "${TEST_TEMPLATE_FILE}"
  
  if [[ $exit_code -eq 0 ]] && [[ "$output" == *"Analysis Report"* ]]; then
    echo -e "${GREEN}✓${NC} PASS: load_template reads template file"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: load_template should read template content"
    echo "  Output: $output"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_load_template_handles_missing_file() {
  local output exit_code
  run_command output exit_code load_template "/nonexistent/template.md"
  
  if [[ $exit_code -ne 0 ]]; then
    echo -e "${GREEN}✓${NC} PASS: load_template handles missing file"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: load_template should fail on missing file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_load_template_validates_readability() {
  local unreadable_file="${TEST_REPORT_DIR}/unreadable.template"
  touch "$unreadable_file"
  chmod 000 "$unreadable_file"
  
  local output exit_code
  run_command output exit_code load_template "$unreadable_file"
  
  if [[ $exit_code -ne 0 ]]; then
    echo -e "${GREEN}✓${NC} PASS: load_template validates file readability"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: load_template should fail on unreadable file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  
  chmod 644 "$unreadable_file"
  rm -f "$unreadable_file"
  TESTS_RUN=$((TESTS_RUN + 1))
}

# ==============================================================================
# Tests: Data Merging with Helper Functions
# ==============================================================================

test_merge_workspace_data_includes_metadata() {
  local json_data='{"file_path":"/test.txt","file_size":1024,"file_type":"text"}'
  
  local output exit_code
  run_command output exit_code merge_workspace_data "$json_data"
  
  if [[ $exit_code -eq 0 ]] && echo "$output" | jq -e '.file_path' >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} PASS: merge_workspace_data includes metadata"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: merge_workspace_data should include metadata fields"
    echo "  Output: $output"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_merge_workspace_data_adds_human_readable_size() {
  local json_data='{"file_path":"/test.txt","file_size":1024}'
  
  local output exit_code
  run_command output exit_code merge_workspace_data "$json_data"
  
  if [[ $exit_code -eq 0 ]] && echo "$output" | jq -e '.file_size_human' >/dev/null 2>&1; then
    local size_human
    size_human=$(echo "$output" | jq -r '.file_size_human')
    if [[ "$size_human" == "1KB" || "$size_human" == "1.0KB" ]]; then
      echo -e "${GREEN}✓${NC} PASS: merge_workspace_data adds human readable size"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "${RED}✗${NC} FAIL: file_size_human format incorrect: $size_human"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    echo -e "${RED}✗${NC} FAIL: merge_workspace_data should add file_size_human"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_merge_workspace_data_adds_generation_time() {
  local json_data='{"file_path":"/test.txt"}'
  
  local output exit_code
  run_command output exit_code merge_workspace_data "$json_data"
  
  if [[ $exit_code -eq 0 ]] && echo "$output" | jq -e '.generation_time' >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} PASS: merge_workspace_data adds generation_time"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: merge_workspace_data should add generation_time"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_merge_workspace_data_adds_filename() {
  local json_data='{"file_path":"/path/to/test.txt"}'
  
  local output exit_code
  run_command output exit_code merge_workspace_data "$json_data"
  
  if [[ $exit_code -eq 0 ]] && echo "$output" | jq -e '.filename' >/dev/null 2>&1; then
    local filename
    filename=$(echo "$output" | jq -r '.filename')
    if [[ "$filename" == "test.txt" ]]; then
      echo -e "${GREEN}✓${NC} PASS: merge_workspace_data adds filename"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "${RED}✗${NC} FAIL: filename incorrect: $filename"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    echo -e "${RED}✗${NC} FAIL: merge_workspace_data should add filename"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

# ==============================================================================
# Tests: Helper Functions
# ==============================================================================

test_human_readable_size_formats_bytes() {
  local output exit_code
  run_command output exit_code human_readable_size 512
  
  if [[ $exit_code -eq 0 ]] && [[ "$output" == "512B" || "$output" == "512.0B" ]]; then
    echo -e "${GREEN}✓${NC} PASS: human_readable_size formats bytes"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Expected bytes format, got: $output"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_human_readable_size_formats_kilobytes() {
  local output exit_code
  run_command output exit_code human_readable_size 1024
  
  if [[ $exit_code -eq 0 ]] && [[ "$output" == "1KB" || "$output" == "1.0KB" ]]; then
    echo -e "${GREEN}✓${NC} PASS: human_readable_size formats kilobytes"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Expected KB format, got: $output"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_human_readable_size_formats_megabytes() {
  local output exit_code
  run_command output exit_code human_readable_size 1048576
  
  if [[ $exit_code -eq 0 ]] && [[ "$output" == "1MB" || "$output" == "1.0MB" ]]; then
    echo -e "${GREEN}✓${NC} PASS: human_readable_size formats megabytes"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Expected MB format, got: $output"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_human_readable_size_formats_gigabytes() {
  local output exit_code
  run_command output exit_code human_readable_size 1073741824
  
  if [[ $exit_code -eq 0 ]] && [[ "$output" == "1GB" || "$output" == "1.0GB" ]]; then
    echo -e "${GREEN}✓${NC} PASS: human_readable_size formats gigabytes"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Expected GB format, got: $output"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_format_date_iso8601_formats_current_time() {
  local output exit_code
  run_command output exit_code format_date_iso8601
  
  if [[ $exit_code -eq 0 ]] && [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    echo -e "${GREEN}✓${NC} PASS: format_date_iso8601 formats current time"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Expected ISO8601 format, got: $output"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_format_date_iso8601_formats_timestamp() {
  local output exit_code
  run_command output exit_code format_date_iso8601 1707739200
  
  if [[ $exit_code -eq 0 ]] && [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    echo -e "${GREEN}✓${NC} PASS: format_date_iso8601 formats timestamp"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Expected ISO8601 format, got: $output"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

# ==============================================================================
# Tests: Report Writing
# ==============================================================================

test_write_report_creates_file() {
  local target_file="${TEST_REPORT_DIR}/test_report.md"
  local content="# Test Report"
  
  local output exit_code
  run_command output exit_code write_report "$target_file" "$content"
  
  if [[ $exit_code -eq 0 ]] && [[ -f "$target_file" ]]; then
    echo -e "${GREEN}✓${NC} PASS: write_report creates file"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: write_report should create file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_write_report_atomic_write() {
  local target_file="${TEST_REPORT_DIR}/atomic_test.md"
  local content="# Atomic Test"
  
  local output exit_code
  run_command output exit_code write_report "$target_file" "$content"
  
  if [[ $exit_code -eq 0 ]]; then
    local written_content
    written_content=$(<"$target_file")
    if [[ "$written_content" == "$content" ]]; then
      echo -e "${GREEN}✓${NC} PASS: write_report performs atomic write"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "${RED}✗${NC} FAIL: Content mismatch after write"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    echo -e "${RED}✗${NC} FAIL: write_report failed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_write_report_creates_parent_directory() {
  local target_file="${TEST_REPORT_DIR}/subdir/nested/report.md"
  local content="# Nested Report"
  
  local output exit_code
  run_command output exit_code write_report "$target_file" "$content"
  
  if [[ $exit_code -eq 0 ]] && [[ -f "$target_file" ]]; then
    echo -e "${GREEN}✓${NC} PASS: write_report creates parent directories"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: write_report should create parent directories"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_write_report_handles_write_failure() {
  local unwritable_dir="${TEST_REPORT_DIR}/unwritable"
  mkdir -p "$unwritable_dir"
  chmod 000 "$unwritable_dir"
  
  local target_file="$unwritable_dir/report.md"
  local content="# Test"
  
  local output exit_code
  run_command output exit_code write_report "$target_file" "$content"
  
  if [[ $exit_code -ne 0 ]]; then
    echo -e "${GREEN}✓${NC} PASS: write_report handles write failure"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: write_report should fail on unwritable directory"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  
  chmod 755 "$unwritable_dir"
  rm -rf "$unwritable_dir"
  TESTS_RUN=$((TESTS_RUN + 1))
}

# ==============================================================================
# Tests: Per-File Report Generation
# ==============================================================================

test_generate_reports_creates_per_file_reports() {
  local target_dir="${TEST_REPORT_DIR}/reports"
  
  local output exit_code
  run_command output exit_code generate_reports "${TEST_WORKSPACE_DIR}" "$target_dir" "${TEST_TEMPLATE_FILE}"
  
  if [[ $exit_code -eq 0 ]] && [[ -d "$target_dir" ]]; then
    local report_count
    report_count=$(find "$target_dir" -name "*.md" -type f | wc -l)
    if [[ $report_count -ge 2 ]]; then
      echo -e "${GREEN}✓${NC} PASS: generate_reports creates per-file reports"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "${RED}✗${NC} FAIL: Expected at least 2 reports, got: $report_count"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    echo -e "${RED}✗${NC} FAIL: generate_reports should create reports"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_generate_reports_creates_target_directory() {
  local target_dir="${TEST_REPORT_DIR}/new_reports"
  
  local output exit_code
  run_command output exit_code generate_reports "${TEST_WORKSPACE_DIR}" "$target_dir" "${TEST_TEMPLATE_FILE}"
  
  if [[ $exit_code -eq 0 ]] && [[ -d "$target_dir" ]]; then
    echo -e "${GREEN}✓${NC} PASS: generate_reports creates target directory"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: generate_reports should create target directory"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_generate_reports_integrates_with_template_engine() {
  local target_dir="${TEST_REPORT_DIR}/template_integration"
  
  local output exit_code
  run_command output exit_code generate_reports "${TEST_WORKSPACE_DIR}" "$target_dir" "${TEST_TEMPLATE_FILE}"
  
  if [[ $exit_code -eq 0 ]]; then
    local report_file
    report_file=$(find "$target_dir" -name "*.md" -type f | head -n 1)
    if [[ -f "$report_file" ]]; then
      local report_content
      report_content=$(<"$report_file")
      if [[ "$report_content" == *"Analysis Report"* ]] && [[ "$report_content" == *"File Information"* ]]; then
        echo -e "${GREEN}✓${NC} PASS: generate_reports integrates with template engine"
        TESTS_PASSED=$((TESTS_PASSED + 1))
      else
        echo -e "${RED}✗${NC} FAIL: Report content doesn't match template"
        TESTS_FAILED=$((TESTS_FAILED + 1))
      fi
    else
      echo -e "${RED}✗${NC} FAIL: No report file found"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    echo -e "${RED}✗${NC} FAIL: generate_reports failed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_generate_reports_handles_missing_template() {
  local target_dir="${TEST_REPORT_DIR}/no_template"
  
  local output exit_code
  run_command output exit_code generate_reports "${TEST_WORKSPACE_DIR}" "$target_dir" "/nonexistent/template.md"
  
  if [[ $exit_code -ne 0 ]]; then
    echo -e "${GREEN}✓${NC} PASS: generate_reports handles missing template"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: generate_reports should fail on missing template"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_generate_reports_handles_empty_workspace() {
  local empty_workspace="${TEST_REPORT_DIR}/empty_workspace"
  mkdir -p "$empty_workspace/files"
  local target_dir="${TEST_REPORT_DIR}/empty_reports"
  
  local output exit_code
  run_command output exit_code generate_reports "$empty_workspace" "$target_dir" "${TEST_TEMPLATE_FILE}"
  
  if [[ $exit_code -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} PASS: generate_reports handles empty workspace"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: generate_reports should handle empty workspace gracefully"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_generate_reports_continues_after_individual_failure() {
  # Create invalid JSON to test error handling
  cat > "${TEST_WORKSPACE_DIR}/files/invalid.json" << 'EOF'
{ invalid json }
EOF
  
  local target_dir="${TEST_REPORT_DIR}/partial_reports"
  
  local output exit_code
  run_command output exit_code generate_reports "${TEST_WORKSPACE_DIR}" "$target_dir" "${TEST_TEMPLATE_FILE}"
  
  # Should still generate reports for valid files
  if [[ -d "$target_dir" ]]; then
    local report_count
    report_count=$(find "$target_dir" -name "*.md" -type f | wc -l)
    if [[ $report_count -ge 2 ]]; then
      echo -e "${GREEN}✓${NC} PASS: generate_reports continues after individual failure"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "${RED}✗${NC} FAIL: Should generate reports for valid files despite errors"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    echo -e "${RED}✗${NC} FAIL: No reports generated"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

# ==============================================================================
# Tests: Error Handling
# ==============================================================================

test_generate_reports_validates_workspace_dir() {
  local target_dir="${TEST_REPORT_DIR}/reports"
  
  local output exit_code
  run_command output exit_code generate_reports "/nonexistent/workspace" "$target_dir" "${TEST_TEMPLATE_FILE}"
  
  if [[ $exit_code -ne 0 ]]; then
    echo -e "${GREEN}✓${NC} PASS: generate_reports validates workspace directory"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: generate_reports should fail on invalid workspace"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_generate_reports_validates_target_dir() {
  local output exit_code
  run_command output exit_code generate_reports "${TEST_WORKSPACE_DIR}" "" "${TEST_TEMPLATE_FILE}"
  
  if [[ $exit_code -ne 0 ]]; then
    echo -e "${GREEN}✓${NC} PASS: generate_reports validates target directory"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: generate_reports should fail on empty target directory"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

# ==============================================================================
# Main Test Execution
# ==============================================================================

main() {
  echo "======================================"
  echo "Enhanced Report Generator Tests (TDD)"
  echo "Feature: 0010 - Report Generator"
  echo "======================================"
  echo ""
  
  setup_test
  
  # Function existence tests
  echo "Testing function existence..."
  test_load_template_function_exists
  test_merge_workspace_data_function_exists
  test_write_report_function_exists
  test_human_readable_size_function_exists
  test_format_date_iso8601_function_exists
  echo ""
  
  # Template loading tests
  echo "Testing template loading..."
  test_load_template_reads_file
  test_load_template_handles_missing_file
  test_load_template_validates_readability
  echo ""
  
  # Data merging tests
  echo "Testing data merging..."
  test_merge_workspace_data_includes_metadata
  test_merge_workspace_data_adds_human_readable_size
  test_merge_workspace_data_adds_generation_time
  test_merge_workspace_data_adds_filename
  echo ""
  
  # Helper function tests
  echo "Testing helper functions..."
  test_human_readable_size_formats_bytes
  test_human_readable_size_formats_kilobytes
  test_human_readable_size_formats_megabytes
  test_human_readable_size_formats_gigabytes
  test_format_date_iso8601_formats_current_time
  test_format_date_iso8601_formats_timestamp
  echo ""
  
  # Report writing tests
  echo "Testing report writing..."
  test_write_report_creates_file
  test_write_report_atomic_write
  test_write_report_creates_parent_directory
  test_write_report_handles_write_failure
  echo ""
  
  # Per-file report generation tests
  echo "Testing per-file report generation..."
  test_generate_reports_creates_per_file_reports
  test_generate_reports_creates_target_directory
  test_generate_reports_integrates_with_template_engine
  test_generate_reports_handles_missing_template
  test_generate_reports_handles_empty_workspace
  test_generate_reports_continues_after_individual_failure
  echo ""
  
  # Error handling tests
  echo "Testing error handling..."
  test_generate_reports_validates_workspace_dir
  test_generate_reports_validates_target_dir
  echo ""
  
  teardown_test
  
  # Print summary
  echo ""
  echo "========================================"
  echo "Test Summary"
  echo "========================================"
  echo "Tests run:    $TESTS_RUN"
  echo "Tests passed: $TESTS_PASSED"
  echo "Tests failed: $TESTS_FAILED"
  echo ""
  
  # Exit with appropriate code
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "Some tests failed!"
    exit 1
  else
    echo "All tests passed!"
    exit 0
  fi
}

# Run tests
main
