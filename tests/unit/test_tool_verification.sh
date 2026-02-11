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

# Unit Tests: Tool Verification
# Tests plugin tool availability checking and installation guidance

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
source "$COMPONENTS_DIR/plugin/plugin_tool_checker.sh" 2>/dev/null || true

# Test fixture directory
TEST_FIXTURE_DIR="/tmp/test_tool_verification_$$"

# ==============================================================================
# Setup / Teardown
# ==============================================================================

setup_fixtures() {
  mkdir -p "${TEST_FIXTURE_DIR}/available_tool"
  mkdir -p "${TEST_FIXTURE_DIR}/missing_tool"
  mkdir -p "${TEST_FIXTURE_DIR}/all_available"

  # Plugin with an available tool (stat exists on all systems)
  cat > "${TEST_FIXTURE_DIR}/available_tool/descriptor.json" <<'EOF'
{
  "name": "available_tool",
  "description": "Plugin with a tool that should be available.",
  "active": true,
  "commandline": "stat '${file_path_absolute}'",
  "check_commandline": "which stat",
  "install_commandline": "apt install coreutils"
}
EOF

  # Plugin with a missing tool
  cat > "${TEST_FIXTURE_DIR}/missing_tool/descriptor.json" <<'EOF'
{
  "name": "missing_tool",
  "description": "Plugin with a tool that does not exist.",
  "active": true,
  "commandline": "nonexistent_tool_xyz '${file_path_absolute}'",
  "check_commandline": "which nonexistent_tool_xyz",
  "install_commandline": "apt install nonexistent_tool_xyz"
}
EOF

  # Directory with only available tools
  mkdir -p "${TEST_FIXTURE_DIR}/all_available/stat_plugin"
  cat > "${TEST_FIXTURE_DIR}/all_available/stat_plugin/descriptor.json" <<'EOF'
{
  "name": "stat_plugin",
  "description": "Plugin using stat.",
  "active": true,
  "commandline": "stat '${file_path_absolute}'",
  "check_commandline": "which stat",
  "install_commandline": "apt install coreutils"
}
EOF
}

cleanup_fixtures() {
  rm -rf "${TEST_FIXTURE_DIR}"
}

# ==============================================================================
# Tests
# ==============================================================================

start_test_suite "Tool Verification"

setup_fixtures

# Test 1: Available tool (stat) is detected as available
test_available_tool_detected() {
  local exit_code=0
  check_tool_availability "which stat" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Available tool (stat) is detected as available"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Available tool (stat) should be detected as available (exit code: ${exit_code})"
  fi
}

# Test 2: Missing tool (nonexistent_tool_xyz) is detected as missing
test_missing_tool_detected() {
  local exit_code=0
  check_tool_availability "which nonexistent_tool_xyz" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -ne 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Missing tool (nonexistent_tool_xyz) is detected as missing"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Missing tool should be detected as missing"
  fi
}

# Test 3: Tool status report includes plugin name
test_status_report_includes_plugin_name() {
  local output
  output=$(get_plugin_tool_status "${TEST_FIXTURE_DIR}/available_tool" 2>/dev/null) || true

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "${output}" == *"available_tool"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Tool status report includes plugin name"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Tool status report should include plugin name"
    echo "  Output: '${output}'"
  fi
}

# Test 4: get_install_guidance returns install_commandline from descriptor
test_install_guidance_returns_command() {
  local guidance
  guidance=$(get_install_guidance "apt install coreutils" "ubuntu" 2>/dev/null) || true

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "${guidance}" == "apt install coreutils" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: get_install_guidance returns install_commandline from descriptor"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: get_install_guidance should return install command"
    echo "  Expected: 'apt install coreutils'"
    echo "  Actual:   '${guidance}'"
  fi
}

# Test 5: verify_plugin_tools returns 0 when all tools available
test_verify_all_available() {
  local exit_code=0
  verify_plugin_tools "${TEST_FIXTURE_DIR}/all_available" "false" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: verify_plugin_tools returns 0 when all tools available"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: verify_plugin_tools should return 0 when all tools available (exit code: ${exit_code})"
  fi
}

# Test 6: verify_plugin_tools returns non-zero when tool missing
test_verify_missing_tool() {
  local exit_code=0
  verify_plugin_tools "${TEST_FIXTURE_DIR}/missing_tool" "false" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -ne 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: verify_plugin_tools returns non-zero when tool missing"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: verify_plugin_tools should return non-zero when tool missing"
  fi
}

# Test 7: check_tool_availability returns 0 for existing command
test_check_existing_command() {
  local exit_code=0
  check_tool_availability "which bash" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: check_tool_availability returns 0 for existing command"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: check_tool_availability should return 0 for existing command (exit code: ${exit_code})"
  fi
}

# Test 8: check_tool_availability returns 1 for non-existing command
test_check_nonexisting_command() {
  local exit_code=0
  check_tool_availability "which totally_fake_command_12345" 2>/dev/null || exit_code=$?

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${exit_code} -ne 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: check_tool_availability returns 1 for non-existing command"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: check_tool_availability should return 1 for non-existing command"
  fi
}

# Run all tests
test_available_tool_detected
test_missing_tool_detected
test_status_report_includes_plugin_name
test_install_guidance_returns_command
test_verify_all_available
test_verify_missing_tool
test_check_existing_command
test_check_nonexisting_command

# ==============================================================================
# Cleanup and Summary
# ==============================================================================

cleanup_fixtures

finish_test_suite "Tool Verification"
