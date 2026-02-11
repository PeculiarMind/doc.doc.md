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

# Unit Tests: Plugin Validation
# Tests plugin descriptor validation and security checks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

# Source required components for testing
SCRIPT_DIR_COMP="$PROJECT_ROOT/scripts"
COMPONENTS_DIR="$SCRIPT_DIR_COMP/components"

# Mock SCRIPT_DIR for components that need it
export SCRIPT_DIR="$SCRIPT_DIR_COMP"

# Source dependencies
source "$COMPONENTS_DIR/core/constants.sh" 2>/dev/null || true
source "$COMPONENTS_DIR/core/logging.sh" 2>/dev/null || true
source "$COMPONENTS_DIR/plugin/plugin_parser.sh" 2>/dev/null || true
source "$COMPONENTS_DIR/plugin/plugin_validator.sh" 2>/dev/null || true

# Test fixture directory
TEST_FIXTURE_DIR="/tmp/test_plugin_validation_$$"

# ==============================================================================
# Setup / Teardown
# ==============================================================================

setup_fixtures() {
  mkdir -p "${TEST_FIXTURE_DIR}/valid_plugin"
  mkdir -p "${TEST_FIXTURE_DIR}/bad_name"
  mkdir -p "${TEST_FIXTURE_DIR}/inject_plugin"
  mkdir -p "${TEST_FIXTURE_DIR}/traversal_plugin"
  mkdir -p "${TEST_FIXTURE_DIR}/sandbox_plugin"
  mkdir -p "${TEST_FIXTURE_DIR}/bad_type"
  mkdir -p "${TEST_FIXTURE_DIR}/missing_field"

  # Valid descriptor
  cat > "${TEST_FIXTURE_DIR}/valid_plugin/descriptor.json" <<'EOF'
{
  "name": "valid_plugin",
  "description": "A valid test plugin for validation testing.",
  "active": true,
  "processes": {
    "mime_types": ["text/plain"],
    "file_extensions": [".txt"]
  },
  "consumes": {
    "file_path_absolute": {
      "type": "string",
      "description": "Absolute path to the file."
    }
  },
  "provides": {
    "file_size": {
      "type": "integer",
      "description": "Size of the file in bytes."
    }
  },
  "commandline": "wc -c '${file_path_absolute}'",
  "check_commandline": "which wc",
  "install_commandline": "apt install coreutils"
}
EOF

  # Missing required field (no commandline)
  cat > "${TEST_FIXTURE_DIR}/missing_field/descriptor.json" <<'EOF'
{
  "name": "missing_field",
  "description": "Plugin missing commandline field.",
  "active": true,
  "check_commandline": "echo ok",
  "install_commandline": "true"
}
EOF

  # Invalid plugin name (too short)
  cat > "${TEST_FIXTURE_DIR}/bad_name/descriptor.json" <<'EOF'
{
  "name": "ab",
  "description": "Plugin with a name that is too short.",
  "active": true,
  "commandline": "echo hello",
  "check_commandline": "echo ok",
  "install_commandline": "true"
}
EOF

  # Command injection (semicolon)
  cat > "${TEST_FIXTURE_DIR}/inject_plugin/descriptor.json" <<'EOF'
{
  "name": "inject_plugin",
  "description": "Plugin with command injection attempt.",
  "active": true,
  "commandline": "echo hello; rm -rf /",
  "check_commandline": "echo ok",
  "install_commandline": "true"
}
EOF

  # Path traversal
  cat > "${TEST_FIXTURE_DIR}/traversal_plugin/descriptor.json" <<'EOF'
{
  "name": "traversal_plugin",
  "description": "Plugin with path traversal.",
  "active": true,
  "commandline": "cat file",
  "check_commandline": "echo ok",
  "install_commandline": "true"
}
EOF

  # Sandbox incompatible (sudo)
  cat > "${TEST_FIXTURE_DIR}/sandbox_plugin/descriptor.json" <<'EOF'
{
  "name": "sandbox_plugin",
  "description": "Plugin that uses sudo.",
  "active": true,
  "commandline": "sudo cat /etc/shadow",
  "check_commandline": "echo ok",
  "install_commandline": "true"
}
EOF

  # Invalid data type in provides
  cat > "${TEST_FIXTURE_DIR}/bad_type/descriptor.json" <<'EOF'
{
  "name": "bad_type",
  "description": "Plugin with invalid data type in provides.",
  "active": true,
  "commandline": "echo hello",
  "check_commandline": "echo ok",
  "install_commandline": "true",
  "provides": {
    "result": {
      "type": "float",
      "description": "An invalid type."
    }
  }
}
EOF
}

cleanup_fixtures() {
  rm -rf "${TEST_FIXTURE_DIR}"
}

# ==============================================================================
# Tests
# ==============================================================================

start_test_suite "Plugin Validation"

setup_fixtures

# Test 1: Valid descriptor passes validation
test_valid_descriptor() {
  local exit_code=0
  validate_plugin_descriptor "${TEST_FIXTURE_DIR}/valid_plugin/descriptor.json" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Valid descriptor passes validation"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Valid descriptor passes validation (exit code: ${exit_code})"
  fi
}

# Test 2: Missing required field fails validation
test_missing_required_field() {
  local exit_code=0
  validate_plugin_descriptor "${TEST_FIXTURE_DIR}/missing_field/descriptor.json" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -ne 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Missing required field fails validation"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Missing required field should fail validation"
  fi
}

# Test 3: Invalid plugin name (too short) fails validation
test_invalid_plugin_name() {
  local exit_code=0
  validate_plugin_descriptor "${TEST_FIXTURE_DIR}/bad_name/descriptor.json" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -ne 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Invalid plugin name (too short) fails validation"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Invalid plugin name should fail validation"
  fi
}

# Test 4: Command injection patterns detected (semicolon)
test_command_injection_detected() {
  local exit_code=0
  validate_plugin_descriptor "${TEST_FIXTURE_DIR}/inject_plugin/descriptor.json" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -ne 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Command injection pattern detected"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Command injection should fail validation"
  fi
}

# Test 5: Valid plugin name passes
test_valid_plugin_name() {
  local exit_code=0
  validate_plugin_descriptor "${TEST_FIXTURE_DIR}/valid_plugin/descriptor.json" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Valid plugin name passes validation"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Valid plugin name should pass validation"
  fi
}

# Test 6: Invalid data type in provides fails
test_invalid_data_type() {
  local exit_code=0
  validate_plugin_descriptor "${TEST_FIXTURE_DIR}/bad_type/descriptor.json" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -ne 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Invalid data type in provides fails validation"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Invalid data type should fail validation"
  fi
}

# Test 7: Path traversal detected
test_path_traversal_detected() {
  local exit_code=0
  validate_plugin_descriptor "${TEST_FIXTURE_DIR}/../test_plugin_validation_$$/traversal_plugin/descriptor.json" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -ne 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Path traversal detected"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Path traversal should fail validation"
  fi
}

# Test 8: Sandbox-incompatible command detected (sudo)
test_sandbox_incompatible() {
  local exit_code=0
  validate_plugin_descriptor "${TEST_FIXTURE_DIR}/sandbox_plugin/descriptor.json" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -ne 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Sandbox-incompatible command detected"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Sandbox-incompatible command should fail validation"
  fi
}

# Run all tests
test_valid_descriptor
test_missing_required_field
test_invalid_plugin_name
test_command_injection_detected
test_valid_plugin_name
test_invalid_data_type
test_path_traversal_detected
test_sandbox_incompatible

# ==============================================================================
# Cleanup and Summary
# ==============================================================================

cleanup_fixtures

finish_test_suite "Plugin Validation"
