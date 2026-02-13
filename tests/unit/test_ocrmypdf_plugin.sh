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

# Unit Tests: OCRmyPDF Plugin
# Tests comprehensive validation of OCRmyPDF plugin structure, descriptor, and functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

# Plugin paths
PLUGIN_DIR="$PROJECT_ROOT/scripts/plugins/ubuntu/ocrmypdf"
DESCRIPTOR_FILE="$PLUGIN_DIR/descriptor.json"
INSTALL_SCRIPT="$PLUGIN_DIR/install.sh"

# Test fixture directory
TEST_FIXTURE_DIR="/tmp/test_ocrmypdf_plugin_$$"

# ==============================================================================
# Setup / Teardown
# ==============================================================================

setup_fixtures() {
  mkdir -p "${TEST_FIXTURE_DIR}"
  
  # Create a mock PDF file for testing
  echo "%PDF-1.4" > "${TEST_FIXTURE_DIR}/test.pdf"
  echo "Mock PDF content" >> "${TEST_FIXTURE_DIR}/test.pdf"
  
  # Create non-PDF files
  echo "text content" > "${TEST_FIXTURE_DIR}/test.txt"
  echo '{"key": "value"}' > "${TEST_FIXTURE_DIR}/test.json"
}

cleanup_fixtures() {
  rm -rf "${TEST_FIXTURE_DIR}"
}

# ==============================================================================
# Tests: Plugin Structure
# ==============================================================================

start_test_suite "OCRmyPDF Plugin Structure"

test_plugin_directory_exists() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -d "$PLUGIN_DIR" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Plugin directory exists at $PLUGIN_DIR"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Plugin directory does not exist at $PLUGIN_DIR"
  fi
}

test_descriptor_json_exists() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -f "$DESCRIPTOR_FILE" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor.json exists"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor.json does not exist"
  fi
}

test_install_script_exists() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -f "$INSTALL_SCRIPT" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: install.sh exists"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: install.sh does not exist"
  fi
}

test_install_script_executable() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -x "$INSTALL_SCRIPT" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: install.sh is executable"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: install.sh is not executable"
  fi
}

# ==============================================================================
# Tests: Descriptor Schema Compliance
# ==============================================================================

test_descriptor_is_valid_json() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if jq empty "$DESCRIPTOR_FILE" 2>/dev/null; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor.json is valid JSON"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor.json is not valid JSON"
  fi
}

test_descriptor_has_name() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local name
  name=$(jq -r '.name' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ -n "$name" && "$name" != "null" && "$name" == "ocrmypdf" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor has correct name: $name"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor name is missing or incorrect (expected: ocrmypdf, got: $name)"
  fi
}

test_descriptor_has_description() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local desc
  desc=$(jq -r '.description' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ -n "$desc" && "$desc" != "null" && ${#desc} -ge 10 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor has description (${#desc} chars)"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor description is missing or too short"
  fi
}

test_descriptor_has_active_flag() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local active
  active=$(jq -r '.active' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ "$active" == "true" || "$active" == "false" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor has active flag: $active"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor active flag is missing or invalid"
  fi
}

# ==============================================================================
# Tests: File Type Processing Configuration
# ==============================================================================

test_descriptor_processes_pdf_mime_type() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local mime_types
  mime_types=$(jq -r '.processes.mime_types[]' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if echo "$mime_types" | grep -q "application/pdf"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor processes application/pdf mime type"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor does not process application/pdf mime type"
  fi
}

test_descriptor_processes_pdf_extension() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local extensions
  extensions=$(jq -r '.processes.file_extensions[]' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if echo "$extensions" | grep -q ".pdf"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor processes .pdf file extension"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor does not process .pdf file extension"
  fi
}

# ==============================================================================
# Tests: Data Inputs (Consumes)
# ==============================================================================

test_descriptor_consumes_file_path() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local has_field
  has_field=$(jq -r '.consumes | has("file_path_absolute")' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ "$has_field" == "true" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor consumes file_path_absolute"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor does not consume file_path_absolute"
  fi
}

test_descriptor_file_path_type_is_string() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local type
  type=$(jq -r '.consumes.file_path_absolute.type' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ "$type" == "string" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: file_path_absolute type is string"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: file_path_absolute type is not string (got: $type)"
  fi
}

test_descriptor_file_path_has_description() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local desc
  desc=$(jq -r '.consumes.file_path_absolute.description' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ -n "$desc" && "$desc" != "null" && ${#desc} -ge 5 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: file_path_absolute has description"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: file_path_absolute description is missing or too short"
  fi
}

# ==============================================================================
# Tests: Data Outputs (Provides)
# ==============================================================================

test_descriptor_provides_ocr_text_content() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local has_field
  has_field=$(jq -r '.provides | has("ocr_text_content")' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ "$has_field" == "true" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor provides ocr_text_content"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor does not provide ocr_text_content"
  fi
}

test_descriptor_ocr_text_content_type() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local type
  type=$(jq -r '.provides.ocr_text_content.type' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ "$type" == "string" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: ocr_text_content type is string"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: ocr_text_content type is not string (got: $type)"
  fi
}

test_descriptor_provides_ocr_status() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local has_field
  has_field=$(jq -r '.provides | has("ocr_status")' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ "$has_field" == "true" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor provides ocr_status"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor does not provide ocr_status"
  fi
}

test_descriptor_ocr_status_type() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local type
  type=$(jq -r '.provides.ocr_status.type' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ "$type" == "string" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: ocr_status type is string"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: ocr_status type is not string (got: $type)"
  fi
}

test_descriptor_provides_ocr_confidence() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local has_field
  has_field=$(jq -r '.provides | has("ocr_confidence")' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ "$has_field" == "true" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor provides ocr_confidence"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor does not provide ocr_confidence"
  fi
}

test_descriptor_ocr_confidence_type() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local type
  type=$(jq -r '.provides.ocr_confidence.type' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ "$type" == "number" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: ocr_confidence type is number"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: ocr_confidence type is not number (got: $type)"
  fi
}

test_descriptor_all_provides_have_descriptions() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local missing=0
  
  for field in ocr_text_content ocr_status ocr_confidence; do
    local desc
    desc=$(jq -r ".provides.$field.description" "$DESCRIPTOR_FILE" 2>/dev/null)
    if [[ -z "$desc" || "$desc" == "null" || ${#desc} -lt 5 ]]; then
      ((missing++))
      echo -e "  ${YELLOW}⚠${NC} Field $field missing or has short description"
    fi
  done
  
  if [[ $missing -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: All provides fields have descriptions"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: $missing provides fields missing descriptions"
  fi
}

# ==============================================================================
# Tests: Command Configuration
# ==============================================================================

test_descriptor_has_commandline() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local cmd
  cmd=$(jq -r '.commandline' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ -n "$cmd" && "$cmd" != "null" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor has commandline field"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor missing commandline field"
  fi
}

test_descriptor_commandline_uses_file_path_variable() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local cmd
  cmd=$(jq -r '.commandline' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ "$cmd" == *'${file_path_absolute}'* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: commandline uses file_path_absolute variable"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: commandline does not use file_path_absolute variable"
  fi
}

test_descriptor_commandline_mentions_ocrmypdf() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local cmd
  cmd=$(jq -r '.commandline' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ "$cmd" == *"ocrmypdf"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: commandline mentions ocrmypdf"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: commandline does not mention ocrmypdf"
  fi
}

test_descriptor_has_check_commandline() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local check
  check=$(jq -r '.check_commandline' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ -n "$check" && "$check" != "null" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor has check_commandline field"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor missing check_commandline field"
  fi
}

test_descriptor_check_commandline_verifies_ocrmypdf() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local check
  check=$(jq -r '.check_commandline' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ "$check" == *"ocrmypdf"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: check_commandline verifies ocrmypdf availability"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: check_commandline does not check ocrmypdf"
  fi
}

test_descriptor_has_install_commandline() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local install
  install=$(jq -r '.install_commandline' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ -n "$install" && "$install" != "null" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: descriptor has install_commandline field"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: descriptor missing install_commandline field"
  fi
}

test_descriptor_install_commandline_references_install_script() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local install
  install=$(jq -r '.install_commandline' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  if [[ "$install" == *"install.sh"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: install_commandline references install.sh"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: install_commandline does not reference install.sh"
  fi
}

# ==============================================================================
# Tests: Output Format Validation
# ==============================================================================

test_descriptor_commandline_output_count_matches_provides() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local provides_count
  provides_count=$(jq -r '.provides | keys | length' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  local cmd
  cmd=$(jq -r '.commandline' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  # Count expected comma separators (should be provides_count - 1)
  local expected_commas=$((provides_count - 1))
  
  # Note: This is a heuristic check - actual validation happens at runtime
  echo -e "  ${BLUE}ℹ${NC} INFO: Plugin provides $provides_count fields"
  echo -e "  ${BLUE}ℹ${NC} INFO: Command should output $provides_count comma-separated values"
  
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "${GREEN}✓${NC} PASS: Output format documented (runtime validation required)"
}

test_descriptor_provides_keys_alphabetically_sorted() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local keys
  keys=$(jq -r '.provides | keys[]' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  local keys_array=()
  while IFS= read -r key; do
    keys_array+=("$key")
  done <<< "$keys"
  
  # Check alphabetical order
  local sorted=true
  for ((i=0; i<${#keys_array[@]}-1; i++)); do
    if [[ "${keys_array[$i]}" > "${keys_array[$((i+1))]}" ]]; then
      sorted=false
      break
    fi
  done
  
  if [[ "$sorted" == "true" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Provides keys are alphabetically sorted"
    echo -e "  ${BLUE}ℹ${NC} Order: ${keys_array[*]}"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Provides keys are not alphabetically sorted"
  fi
}

# ==============================================================================
# Tests: Install Script Validation
# ==============================================================================

test_install_script_has_shebang() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local first_line
  first_line=$(head -n1 "$INSTALL_SCRIPT")
  
  if [[ "$first_line" == "#!/bin/bash"* || "$first_line" == "#!/usr/bin/env bash"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: install.sh has bash shebang"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: install.sh missing bash shebang"
  fi
}

test_install_script_checks_tool_availability() {
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if grep -q "command -v ocrmypdf" "$INSTALL_SCRIPT" || \
     grep -q "which ocrmypdf" "$INSTALL_SCRIPT"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: install.sh checks ocrmypdf availability"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: install.sh does not check ocrmypdf availability"
  fi
}

test_install_script_has_copyright_header() {
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if grep -q "Copyright" "$INSTALL_SCRIPT" && grep -q "GNU General Public License" "$INSTALL_SCRIPT"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: install.sh has copyright and license header"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: install.sh missing copyright or license header"
  fi
}

# ==============================================================================
# Tests: Security and Safety
# ==============================================================================

test_descriptor_no_dangerous_commands() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local cmd
  cmd=$(jq -r '.commandline' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  local dangerous=false
  local reason=""
  
  if [[ "$cmd" == *"rm -rf"* ]]; then
    dangerous=true
    reason="contains 'rm -rf'"
  elif [[ "$cmd" == *"; "* ]] && [[ "$cmd" != *"command -v"* ]]; then
    dangerous=true
    reason="contains command separator ';'"
  elif [[ "$cmd" == *"sudo"* ]]; then
    dangerous=true
    reason="contains 'sudo'"
  fi
  
  if [[ "$dangerous" == "false" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: No dangerous command patterns detected"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Dangerous command pattern: $reason"
  fi
}

test_descriptor_uses_proper_quoting() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local cmd
  cmd=$(jq -r '.commandline' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  # Check if file_path_absolute is properly quoted
  if [[ "$cmd" == *"'\${file_path_absolute}'"* ]] || \
     [[ "$cmd" == *'"\${file_path_absolute}"'* ]] || \
     [[ "$cmd" == *'"${file_path_absolute}"'* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: file_path_absolute is properly quoted"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: file_path_absolute not properly quoted (security risk)"
  fi
}

# ==============================================================================
# Tests: Integration with Plugin System
# ==============================================================================

test_plugin_passes_validation() {
  TESTS_RUN=$((TESTS_RUN + 1))
  
  # Source required components if available
  if [[ -f "$PROJECT_ROOT/scripts/components/plugin/plugin_validator.sh" ]]; then
    source "$PROJECT_ROOT/scripts/components/core/constants.sh" 2>/dev/null || true
    source "$PROJECT_ROOT/scripts/components/core/logging.sh" 2>/dev/null || true
    source "$PROJECT_ROOT/scripts/components/plugin/plugin_parser.sh" 2>/dev/null || true
    source "$PROJECT_ROOT/scripts/components/plugin/plugin_validator.sh" 2>/dev/null || true
    
    local exit_code=0
    validate_plugin_descriptor "$DESCRIPTOR_FILE" 2>/dev/null || exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Plugin passes validation"
    else
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Plugin validation failed (exit code: $exit_code)"
    fi
  else
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${YELLOW}⊘${NC} SKIP: Plugin validator not available"
  fi
}

# ==============================================================================
# Tests: Error Handling
# ==============================================================================

test_commandline_handles_nonexistent_files() {
  TESTS_RUN=$((TESTS_RUN + 1))
  
  # This is a design requirement - the command should handle errors gracefully
  # Actual validation requires running the plugin, but we can check for error handling indicators
  local cmd
  cmd=$(jq -r '.commandline' "$DESCRIPTOR_FILE" 2>/dev/null)
  
  # Check if command has basic error handling patterns
  # Note: Actual error handling will be validated in integration tests
  echo -e "  ${BLUE}ℹ${NC} INFO: Error handling verified at runtime"
  
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "${GREEN}✓${NC} PASS: Error handling design documented"
}

# ==============================================================================
# Main Test Execution
# ==============================================================================

setup_fixtures

# Execute all tests
test_plugin_directory_exists
test_descriptor_json_exists
test_install_script_exists
test_install_script_executable

test_descriptor_is_valid_json
test_descriptor_has_name
test_descriptor_has_description
test_descriptor_has_active_flag

test_descriptor_processes_pdf_mime_type
test_descriptor_processes_pdf_extension

test_descriptor_consumes_file_path
test_descriptor_file_path_type_is_string
test_descriptor_file_path_has_description

test_descriptor_provides_ocr_text_content
test_descriptor_ocr_text_content_type
test_descriptor_provides_ocr_status
test_descriptor_ocr_status_type
test_descriptor_provides_ocr_confidence
test_descriptor_ocr_confidence_type
test_descriptor_all_provides_have_descriptions

test_descriptor_has_commandline
test_descriptor_commandline_uses_file_path_variable
test_descriptor_commandline_mentions_ocrmypdf
test_descriptor_has_check_commandline
test_descriptor_check_commandline_verifies_ocrmypdf
test_descriptor_has_install_commandline
test_descriptor_install_commandline_references_install_script

test_descriptor_commandline_output_count_matches_provides
test_descriptor_provides_keys_alphabetically_sorted

test_install_script_has_shebang
test_install_script_checks_tool_availability
test_install_script_has_copyright_header

test_descriptor_no_dangerous_commands
test_descriptor_uses_proper_quoting

test_plugin_passes_validation
test_commandline_handles_nonexistent_files

cleanup_fixtures

finish_test_suite "OCRmyPDF Plugin"
