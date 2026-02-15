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

# Test Suite: Templates Directory Structure (Feature 0026)
# Purpose: Verify templates directory structure and organization
# Created: 2026-02-13

# Determine script directory for relative path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Load test helpers
source "${SCRIPT_DIR}/../helpers/test_helpers.sh"

# ==============================================================================
# Test Suite Setup
# ==============================================================================

suite_name="Templates Directory Structure"

# ==============================================================================
# Test Cases
# ==============================================================================

# Test: Templates directory exists
test_templates_directory_exists() {
  local templates_dir="${PROJECT_ROOT}/scripts/templates"
  
  if [[ -d "${templates_dir}" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Templates directory exists at scripts/templates/"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Templates directory does not exist at scripts/templates/"
  fi
}

# Test: Default template exists
test_default_template_exists() {
  local default_template="${PROJECT_ROOT}/scripts/templates/default.md"
  assert_file_exists "${default_template}" "Default template exists at scripts/templates/default.md"
}

# Test: Templates directory README exists
test_templates_readme_exists() {
  local readme="${PROJECT_ROOT}/scripts/templates/README.md"
  assert_file_exists "${readme}" "Templates directory README exists"
}

# Test: Default template is valid markdown
test_default_template_valid() {
  local default_template="${PROJECT_ROOT}/scripts/templates/default.md"
  
  if [[ ! -f "${default_template}" ]]; then
    echo -e "${YELLOW}⊘${NC} SKIP: Default template does not exist"
    return
  fi
  
  # Check if file is not empty
  if [[ -s "${default_template}" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Default template is not empty"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Default template is empty"
  fi
}

# Test: Default template contains placeholder variables
test_default_template_has_placeholders() {
  local default_template="${PROJECT_ROOT}/scripts/templates/default.md"
  
  if [[ ! -f "${default_template}" ]]; then
    echo -e "${YELLOW}⊘${NC} SKIP: Default template does not exist"
    return
  fi
  
  local content
  content=$(cat "${default_template}")
  
  # Check for common placeholder patterns - using grep for more reliable matching
  # Support both ${variable} shell-style and {{variable}} mustache-style syntax
  if echo "${content}" | grep -qE '\$\{\w+\}|\{\{\w+\}\}'; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Default template contains placeholder variables"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Default template does not contain expected placeholder variables"
  fi
}

# Test: Templates directory is discoverable from script
test_templates_path_resolution() {
  local script_dir="${PROJECT_ROOT}/scripts"
  local templates_dir="${script_dir}/templates"
  
  # Verify path exists and is accessible
  if [[ -d "${templates_dir}" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Templates directory is accessible from scripts directory"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Templates directory is not accessible from scripts directory"
  fi
}

# Test: Template files use .md extension
test_template_files_extension() {
  local templates_dir="${PROJECT_ROOT}/scripts/templates"
  
  if [[ ! -d "${templates_dir}" ]]; then
    echo -e "${YELLOW}⊘${NC} SKIP: Templates directory does not exist"
    return
  fi
  
  local non_md_templates=0
  while IFS= read -r -d '' file; do
    if [[ ! "${file}" =~ \.md$ ]] && [[ "$(basename "${file}")" != "README.md" ]]; then
      ((non_md_templates++))
    fi
  done < <(find "${templates_dir}" -maxdepth 1 -type f -print0 2>/dev/null || true)
  
  if [[ ${non_md_templates} -eq 0 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: All template files use .md extension"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Found ${non_md_templates} template file(s) without .md extension"
  fi
}

# Test: Old template location documented or migrated
test_old_template_migration() {
  local old_template="${PROJECT_ROOT}/scripts/template.doc.doc.md"
  local templates_dir="${PROJECT_ROOT}/scripts/templates"
  
  # Either old template should not exist, or templates directory should exist
  if [[ ! -f "${old_template}" ]] || [[ -d "${templates_dir}" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Template migration handled (old template removed or new structure exists)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Old template exists but new templates directory structure not created"
  fi
}

# ==============================================================================
# Test Suite Execution
# ==============================================================================

# Run all tests
run_test_suite() {
  start_test_suite "${suite_name}"
  
  test_templates_directory_exists
  test_default_template_exists
  test_templates_readme_exists
  test_default_template_valid
  test_default_template_has_placeholders
  test_templates_path_resolution
  test_template_files_extension
  test_old_template_migration
  
  finish_test_suite "${suite_name}"
}

# Execute test suite
run_test_suite
exit $?
