#!/usr/bin/env bash
# Test Suite: Precise Plugin Listing (Feature 0039)
# Purpose: Verify enhanced plugin listing with inputs/outputs
# Created: 2026-02-13

# Determine script directory for relative path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Load test helpers
source "${SCRIPT_DIR}/../helpers/test_helpers.sh"

# ==============================================================================
# Test Suite Setup
# ==============================================================================

suite_name="Precise Plugin Listing"
SCRIPT_PATH="${PROJECT_ROOT}/scripts/doc.doc.sh"

# ==============================================================================
# Test Cases
# ==============================================================================

# Test: Plugin listing includes plugin name
test_listing_includes_name() {
  local output
  
  output=$("${SCRIPT_PATH}" -p list 2>&1)
  
  # Should include at least the stat plugin name
  if [[ "${output}" =~ "stat" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Listing includes plugin names"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Plugin names not shown"
  fi
}

# Test: Plugin listing shows active state
test_listing_shows_active_state() {
  local output
  
  output=$("${SCRIPT_PATH}" -p list 2>&1)
  
  # Should show active/inactive status
  if [[ "${output}" =~ "ACTIVE" ]] || [[ "${output}" =~ "INACTIVE" ]] || [[ "${output}" =~ "enabled" ]] || [[ "${output}" =~ "disabled" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Shows active state"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Active state not shown"
  fi
}

# Test: Plugin listing shows required inputs (consumes)
test_listing_shows_inputs() {
  local output
  
  output=$("${SCRIPT_PATH}" -p list 2>&1)
  
  # Should show what the plugin consumes
  if [[ "${output}" =~ "Consumes" ]] || [[ "${output}" =~ "Input" ]] || [[ "${output}" =~ "Requires" ]] || [[ "${output}" =~ "file_path_absolute" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Shows required inputs"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Required inputs not shown"
  fi
}

# Test: Plugin listing shows provided outputs (provides)
test_listing_shows_outputs() {
  local output
  
  output=$("${SCRIPT_PATH}" -p list 2>&1)
  
  # Should show what the plugin provides
  if [[ "${output}" =~ "Provides" ]] || [[ "${output}" =~ "Output" ]] || [[ "${output}" =~ "Returns" ]] || [[ "${output}" =~ "file_last_modified" ]] || [[ "${output}" =~ "file_size" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Shows provided outputs"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Provided outputs not shown"
  fi
}

# Test: Output is structured and readable
test_output_is_structured() {
  local output
  
  output=$("${SCRIPT_PATH}" -p list 2>&1)
  
  # Output should have clear structure (headers, sections, etc.)
  if [[ "${output}" =~ "Available Plugins" ]] || [[ "${output}" =~ "===" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Output is structured"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Output lacks structure"
  fi
}

# Test: Handles malformed descriptors gracefully
test_handles_malformed_descriptors() {
  # Create a temporary malformed descriptor
  local temp_plugin_dir="${PROJECT_ROOT}/scripts/plugins/ubuntu/test_malformed_$$"
  mkdir -p "${temp_plugin_dir}"
  
  # Create a malformed descriptor (invalid JSON)
  echo "{ invalid json" > "${temp_plugin_dir}/descriptor.json"
  
  local output
  local exit_code
  
  set +e
  output=$("${SCRIPT_PATH}" -p list 2>&1)
  exit_code=$?
  set -e
  
  # Clean up
  rm -rf "${temp_plugin_dir}"
  
  # Should not crash, should either skip the plugin or show error
  if [[ ${exit_code} -eq 0 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Handles malformed descriptors without crashing"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Crashes on malformed descriptor (exit code: ${exit_code})"
  fi
}

# Test: Shows plugin description
test_shows_description() {
  local output
  
  output=$("${SCRIPT_PATH}" -p list 2>&1)
  
  # Should include descriptions
  if [[ "${output}" =~ "Retrieves file statistics" ]] || [[ "${output}" =~ "description" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Shows plugin descriptions"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Plugin descriptions not shown"
  fi
}

# Test: Multiple plugins listed correctly
test_multiple_plugins_listed() {
  local output
  
  output=$("${SCRIPT_PATH}" -p list 2>&1)
  
  # Count how many plugins are shown (look for [ACTIVE] or [INACTIVE] markers)
  local plugin_count
  plugin_count=$(echo "${output}" | grep -c "\[ACTIVE\]\|\[INACTIVE\]" || echo "0")
  
  if [[ ${plugin_count} -ge 1 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Plugins listed (found ${plugin_count} plugin(s))"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: No plugins found in listing"
  fi
}

# ==============================================================================
# Test Suite Execution
# ==============================================================================

# Run all tests
run_test_suite() {
  start_test_suite "${suite_name}"
  
  test_listing_includes_name
  test_listing_shows_active_state
  test_listing_shows_inputs
  test_listing_shows_outputs
  test_output_is_structured
  test_handles_malformed_descriptors
  test_shows_description
  test_multiple_plugins_listed
  
  finish_test_suite "${suite_name}"
}

# Execute test suite
run_test_suite
exit $?
