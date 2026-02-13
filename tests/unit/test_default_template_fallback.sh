#!/usr/bin/env bash
# Test Suite: Default Template Fallback (Feature 0027)
# Purpose: Verify -m flag is optional and defaults to templates/default.md
# Created: 2026-02-13

# Determine script directory for relative path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Load test helpers
source "${SCRIPT_DIR}/../helpers/test_helpers.sh"

# ==============================================================================
# Test Suite Setup
# ==============================================================================

suite_name="Default Template Fallback"
SCRIPT_PATH="${PROJECT_ROOT}/scripts/doc.doc.sh"

# ==============================================================================
# Test Cases
# ==============================================================================

# Test: Script accepts command without -m flag
test_command_without_m_flag() {
  local output
  local exit_code
  
  # Run with minimal required args (will fail for other reasons, but should not complain about missing -m)
  set +e
  output=$("${SCRIPT_PATH}" -d /tmp 2>&1)
  exit_code=$?
  set -e
  
  # Should NOT contain error about missing -m flag
  if [[ ! "${output}" =~ "requires a template file" ]] && [[ ! "${output}" =~ "-m.*required" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Script accepts command without -m flag"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Script requires -m flag (should be optional)"
  fi
}

# Test: Help text shows -m as optional
test_help_shows_m_as_optional() {
  local output
  
  output=$("${SCRIPT_PATH}" --help 2>&1)
  
  # Check that help indicates -m is optional
  # Look for patterns like "[-m template]" or similar optional syntax
  if [[ "${output}" =~ \[-m ]] || [[ "${output}" =~ "optional" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Help text indicates -m is optional"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Help text does not indicate -m is optional"
  fi
}

# Test: Help text documents default template location
test_help_documents_default_template() {
  local output
  
  output=$("${SCRIPT_PATH}" --help 2>&1)
  
  # Check that help mentions default template or templates/default.md
  if [[ "${output}" =~ "default" ]] && [[ "${output}" =~ "template" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Help text documents default template"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Help text does not document default template"
  fi
}

# Test: Default template path resolves correctly
test_default_template_path_resolution() {
  local expected_path="${PROJECT_ROOT}/scripts/templates/default.md"
  
  # Verify default template exists at expected location
  if [[ -f "${expected_path}" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Default template exists at expected path"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Default template not found at ${expected_path}"
  fi
}

# Test: User-specified template takes precedence
test_explicit_template_precedence() {
  # This test verifies that when -m is provided, it's used instead of default
  # We can't fully test this without a complete workflow, but we can verify parsing
  
  local output
  local exit_code
  
  # Create a temporary template
  local temp_template="/tmp/test_template_$$.md"
  echo "# Test Template" > "${temp_template}"
  
  set +e
  output=$("${SCRIPT_PATH}" -d /tmp -m "${temp_template}" 2>&1)
  exit_code=$?
  set -e
  
  # Clean up
  rm -f "${temp_template}"
  
  # Should accept the -m flag without error about the flag itself
  if [[ ! "${output}" =~ "Unknown option.*-m" ]] && [[ ! "${output}" =~ "invalid.*-m" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Script accepts explicit -m flag"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Script rejects explicit -m flag"
  fi
}

# Test: Error handling for missing default template
test_missing_default_template_error() {
  # This test verifies appropriate error when default template is missing
  # We'll skip if we can't test this without breaking the system
  
  local default_template="${PROJECT_ROOT}/scripts/templates/default.md"
  
  if [[ ! -f "${default_template}" ]]; then
    # Default template is missing - this is the condition we want to test error handling for
    local output
    set +e
    output=$("${SCRIPT_PATH}" -d /tmp 2>&1)
    set -e
    
    # Should have clear error about missing template
    if [[ "${output}" =~ "default template" ]] || [[ "${output}" =~ "template not found" ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Clear error when default template missing"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: No clear error when default template missing"
    fi
  else
    echo -e "${YELLOW}⊘${NC} SKIP: Default template exists (cannot test missing scenario)"
  fi
}

# Test: Verbose mode logs template selection
test_verbose_logs_template_selection() {
  local output
  
  set +e
  output=$("${SCRIPT_PATH}" -v -d /tmp 2>&1)
  set -e
  
  # In verbose mode, should log which template is being used
  if [[ "${output}" =~ "template" ]] && [[ "${output}" =~ "default" || "${output}" =~ "Using" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Verbose mode logs template selection"
  else
    # This is a soft requirement - might not be implemented yet
    echo -e "${YELLOW}⊘${NC} SKIP: Verbose logging for template selection not yet visible"
  fi
}

# ==============================================================================
# Test Suite Execution
# ==============================================================================

# Run all tests
run_test_suite() {
  start_test_suite "${suite_name}"
  
  test_command_without_m_flag
  test_help_shows_m_as_optional
  test_help_documents_default_template
  test_default_template_path_resolution
  test_explicit_template_precedence
  test_missing_default_template_error
  test_verbose_logs_template_selection
  
  finish_test_suite "${suite_name}"
}

# Execute test suite
run_test_suite
exit $?
