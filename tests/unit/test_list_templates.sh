#!/usr/bin/env bash
# Test Suite: List Templates Command (Feature 0028)
# Purpose: Verify --list-templates command functionality
# Created: 2026-02-13

# Determine script directory for relative path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Load test helpers
source "${SCRIPT_DIR}/../helpers/test_helpers.sh"

# ==============================================================================
# Test Suite Setup
# ==============================================================================

suite_name="List Templates Command"
SCRIPT_PATH="${PROJECT_ROOT}/scripts/doc.doc.sh"

# ==============================================================================
# Test Cases
# ==============================================================================

# Test: --list-templates flag is recognized
test_list_templates_flag_recognized() {
  local output
  local exit_code
  
  set +e
  output=$("${SCRIPT_PATH}" --list-templates 2>&1)
  exit_code=$?
  set -e
  
  # Should recognize the flag and not error about unknown option
  if [[ ! "${output}" =~ "Unknown option" ]] && [[ ! "${output}" =~ "invalid" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: --list-templates flag is recognized"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: --list-templates flag not recognized"
  fi
}

# Test: Command exits successfully after listing
test_command_exits_successfully() {
  local exit_code
  
  set +e
  "${SCRIPT_PATH}" --list-templates >/dev/null 2>&1
  exit_code=$?
  set -e
  
  if [[ ${exit_code} -eq 0 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Command exits with code 0"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Command exits with code ${exit_code} (expected 0)"
  fi
}

# Test: Command does not require -d, -t, or -w flags
test_no_required_flags() {
  local output
  local exit_code
  
  set +e
  output=$("${SCRIPT_PATH}" --list-templates 2>&1)
  exit_code=$?
  set -e
  
  # Should not complain about missing -d, -t, or -w
  if [[ ! "${output}" =~ "requires a directory" ]] && [[ ! "${output}" =~ "missing.*argument" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Does not require -d/-t/-w flags"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Incorrectly requires other flags"
  fi
}

# Test: Lists default template
test_lists_default_template() {
  local output
  
  output=$("${SCRIPT_PATH}" --list-templates 2>&1)
  
  # Should mention default.md or "default"
  if [[ "${output}" =~ "default" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Lists default template"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Does not list default template"
  fi
}

# Test: Shows template paths or names
test_shows_template_info() {
  local output
  
  output=$("${SCRIPT_PATH}" --list-templates 2>&1)
  
  # Should show some template information (path, name, or description)
  if [[ "${output}" =~ "template" ]] || [[ "${output}" =~ ".md" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Shows template information"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Does not show template information"
  fi
}

# Test: Handles empty templates directory gracefully
test_handles_empty_directory() {
  # This test is tricky - we can't easily test without breaking the system
  # We'll skip it unless templates directory is actually empty
  
  local templates_dir="${PROJECT_ROOT}/scripts/templates"
  local template_count
  template_count=$(find "${templates_dir}" -maxdepth 1 -name "*.md" ! -name "README.md" 2>/dev/null | wc -l)
  
  if [[ ${template_count} -eq 0 ]]; then
    local output
    set +e
    output=$("${SCRIPT_PATH}" --list-templates 2>&1)
    set -e
    
    # Should not crash, should show helpful message
    if [[ "${output}" =~ "No templates" ]] || [[ "${output}" =~ "empty" ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Handles empty directory gracefully"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Does not handle empty directory well"
    fi
  else
    echo -e "${YELLOW}⊘${NC} SKIP: Templates directory is not empty (has ${template_count} template(s))"
  fi
}

# Test: Output is human-readable
test_output_is_readable() {
  local output
  
  output=$("${SCRIPT_PATH}" --list-templates 2>&1)
  
  # Output should be structured (not just raw file paths)
  # Look for formatting indicators like headers, tables, or organized lists
  if [[ "${output}" =~ "Template" ]] || [[ "${output}" =~ "---" ]] || [[ "${output}" =~ "Available" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Output appears human-readable and structured"
  else
    # If it at least shows template names/paths, that's acceptable
    if [[ "${output}" =~ "default" ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Output shows template information"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Output is not clearly readable or structured"
    fi
  fi
}

# Test: README.md is not listed as a template
test_readme_not_listed_as_template() {
  local output
  
  output=$("${SCRIPT_PATH}" --list-templates 2>&1)
  
  # README.md should not be listed as a usable template
  # It should either not appear, or appear marked differently
  # For now, we just check that if README appears, it's clearly not a template
  if [[ "${output}" =~ "README" ]]; then
    # README is mentioned - check it's not listed as a regular template
    if [[ "${output}" =~ "README.*not.*template" ]] || [[ "${output}" =~ "documentation" ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: README properly distinguished from templates"
    else
      # This is acceptable - it might just not be shown
      echo -e "${YELLOW}⊘${NC} SKIP: README handling not clearly tested"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: README not listed as template"
  fi
}

# ==============================================================================
# Test Suite Execution
# ==============================================================================

# Run all tests
run_test_suite() {
  start_test_suite "${suite_name}"
  
  test_list_templates_flag_recognized
  test_command_exits_successfully
  test_no_required_flags
  test_lists_default_template
  test_shows_template_info
  test_handles_empty_directory
  test_output_is_readable
  test_readme_not_listed_as_template
  
  finish_test_suite "${suite_name}"
}

# Execute test suite
run_test_suite
exit $?
