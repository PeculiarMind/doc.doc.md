#!/usr/bin/env bash
# Test Suite: Output Directory Creation (Bug 0004)
# Purpose: Verify output directory is created and populated with reports
# Created: 2026-02-13

# Determine script directory for relative path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Load test helpers
source "${SCRIPT_DIR}/../helpers/test_helpers.sh"

# ==============================================================================
# Test Suite Setup
# ==============================================================================

suite_name="Output Directory Creation (Bug 0004)"
SCRIPT_PATH="${PROJECT_ROOT}/scripts/doc.doc.sh"

# Test fixtures
TEST_SOURCE_DIR="/tmp/bug_0004_source_$$"
TEST_OUTPUT_DIR="/tmp/bug_0004_output_$$"
TEST_WORKSPACE_DIR="/tmp/bug_0004_workspace_$$"

setup_test_environment() {
  # Create source directory with a test file
  mkdir -p "${TEST_SOURCE_DIR}"
  echo "# Test Document" > "${TEST_SOURCE_DIR}/test.md"
  echo "This is a test file for bug 0004." >> "${TEST_SOURCE_DIR}/test.md"
  
  # Ensure output directory doesn't exist yet
  rm -rf "${TEST_OUTPUT_DIR}"
  
  # Create workspace directory
  mkdir -p "${TEST_WORKSPACE_DIR}"
}

cleanup_test_environment() {
  # Clean up test directories
  rm -rf "${TEST_SOURCE_DIR}"
  rm -rf "${TEST_OUTPUT_DIR}"
  rm -rf "${TEST_WORKSPACE_DIR}"
}

# ==============================================================================
# Test Cases
# ==============================================================================

# Test: Output directory is created when using -t option
test_output_directory_created() {
  setup_test_environment
  
  # Run the script with -t option
  local output
  local exit_code
  
  set +e
  output=$("${SCRIPT_PATH}" -d "${TEST_SOURCE_DIR}" -t "${TEST_OUTPUT_DIR}" -w "${TEST_WORKSPACE_DIR}" 2>&1)
  exit_code=$?
  set -e
  
  # Check if output directory was created BEFORE cleanup
  local dir_exists=false
  if [[ -d "${TEST_OUTPUT_DIR}" ]]; then
    dir_exists=true
  fi
  
  cleanup_test_environment
  
  if [[ "${dir_exists}" == "true" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Output directory created"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Output directory not created"
    echo "  Output: ${output}"
  fi
}

# Test: Output directory is created if it doesn't exist
test_creates_missing_output_directory() {
  setup_test_environment
  
  # Ensure directory doesn't exist
  rm -rf "${TEST_OUTPUT_DIR}"
  
  local output
  set +e
  output=$("${SCRIPT_PATH}" -d "${TEST_SOURCE_DIR}" -t "${TEST_OUTPUT_DIR}" -w "${TEST_WORKSPACE_DIR}" 2>&1)
  set -e
  
  if [[ -d "${TEST_OUTPUT_DIR}" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Missing output directory created"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Missing output directory not created"
  fi
  
  cleanup_test_environment
}

# Test: Output directory contains generated report files
test_output_directory_populated() {
  setup_test_environment
  
  local output
  set +e
  output=$("${SCRIPT_PATH}" -d "${TEST_SOURCE_DIR}" -t "${TEST_OUTPUT_DIR}" -w "${TEST_WORKSPACE_DIR}" 2>&1)
  set -e
  
  # Check if output directory contains files
  local file_count=0
  if [[ -d "${TEST_OUTPUT_DIR}" ]]; then
    file_count=$(find "${TEST_OUTPUT_DIR}" -type f | wc -l)
  fi
  
  cleanup_test_environment
  
  if [[ ${file_count} -gt 0 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Output directory populated with ${file_count} file(s)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Output directory empty (no report files generated)"
  fi
}

# Test: Report files contain expected content
test_report_files_have_content() {
  setup_test_environment
  
  local output
  set +e
  output=$("${SCRIPT_PATH}" -d "${TEST_SOURCE_DIR}" -t "${TEST_OUTPUT_DIR}" -w "${TEST_WORKSPACE_DIR}" 2>&1)
  set -e
  
  # Check if any report file has content
  local has_content=false
  if [[ -d "${TEST_OUTPUT_DIR}" ]]; then
    for file in "${TEST_OUTPUT_DIR}"/*.md; do
      if [[ -f "${file}" ]] && [[ -s "${file}" ]]; then
        has_content=true
        break
      fi
    done
  fi
  
  cleanup_test_environment
  
  if [[ "${has_content}" == "true" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Report files contain content"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Report files are empty or missing"
  fi
}

# Test: Script shows confirmation of report generation
test_confirmation_message() {
  setup_test_environment
  
  local output
  set +e
  output=$("${SCRIPT_PATH}" -d "${TEST_SOURCE_DIR}" -t "${TEST_OUTPUT_DIR}" -w "${TEST_WORKSPACE_DIR}" 2>&1)
  set -e
  
  cleanup_test_environment
  
  # Check if output contains some indication of success
  if [[ "${output}" =~ "success" ]] || [[ "${output}" =~ "complete" ]] || [[ "${output}" =~ "generated" ]] || [[ "${output}" =~ "Report" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Confirmation message shown"
  else
    # This is not a hard requirement, so we'll mark as info
    echo -e "${YELLOW}⊘${NC} INFO: No explicit confirmation message (not critical)"
  fi
}

# Test: Error handling for write failures
test_write_failure_handling() {
  setup_test_environment
  
  # Create a read-only output directory parent
  local readonly_parent="/tmp/bug_0004_readonly_$$"
  mkdir -p "${readonly_parent}"
  chmod 444 "${readonly_parent}"
  
  local readonly_output="${readonly_parent}/output"
  
  local output
  local exit_code
  
  set +e
  output=$("${SCRIPT_PATH}" -d "${TEST_SOURCE_DIR}" -t "${readonly_output}" -w "${TEST_WORKSPACE_DIR}" 2>&1)
  exit_code=$?
  set -e
  
  # Restore permissions and clean up
  chmod 755 "${readonly_parent}"
  rm -rf "${readonly_parent}"
  cleanup_test_environment
  
  # Should fail with appropriate error
  if [[ ${exit_code} -ne 0 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Write failure handled with error"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Write failure not handled properly"
  fi
}

# Test: Works with existing target directory
test_existing_output_directory() {
  setup_test_environment
  
  # Pre-create output directory
  mkdir -p "${TEST_OUTPUT_DIR}"
  
  local output
  local exit_code
  
  set +e
  output=$("${SCRIPT_PATH}" -d "${TEST_SOURCE_DIR}" -t "${TEST_OUTPUT_DIR}" -w "${TEST_WORKSPACE_DIR}" 2>&1)
  exit_code=$?
  set -e
  
  # Check before cleanup
  local dir_still_exists=false
  if [[ -d "${TEST_OUTPUT_DIR}" ]]; then
    dir_still_exists=true
  fi
  
  cleanup_test_environment
  
  # Should work with existing directory
  if [[ ${exit_code} -eq 0 ]] && [[ "${dir_still_exists}" == "true" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Works with existing output directory"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Failed with existing output directory (exit: ${exit_code})"
  fi
}

# ==============================================================================
# Test Suite Execution
# ==============================================================================

# Run all tests
run_test_suite() {
  start_test_suite "${suite_name}"
  
  test_output_directory_created
  test_creates_missing_output_directory
  test_output_directory_populated
  test_report_files_have_content
  test_confirmation_message
  test_write_failure_handling
  test_existing_output_directory
  
  finish_test_suite "${suite_name}"
}

# Execute test suite
run_test_suite
exit $?
