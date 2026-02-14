#!/usr/bin/env bash
# Test: Plugin Installation Verification (Feature 43)
# Tests verify_plugin_installation function and unavailable plugin tracking

# Determine repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPONENTS_DIR="${REPO_ROOT}/scripts/components"

# Load test helpers
source "${REPO_ROOT}/tests/helpers/test_helpers.sh"

# ==============================================================================
# Test Setup and Teardown
# ==============================================================================

TEST_FIXTURE_DIR="/tmp/plugin_verification_test_$$"

setup_test() {
  source "$COMPONENTS_DIR/core/constants.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/core/logging.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/core/error_handling.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/workspace.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/main_orchestrator.sh" 2>/dev/null || true

  mkdir -p "${TEST_FIXTURE_DIR}"
  
  # Clear the global UNAVAILABLE_PLUGINS array
  declare -gA UNAVAILABLE_PLUGINS
  UNAVAILABLE_PLUGINS=()
}

teardown_test() {
  if [[ -d "${TEST_FIXTURE_DIR}" ]]; then
    rm -rf "${TEST_FIXTURE_DIR}"
  fi
}

# ==============================================================================
# Fixture Helpers
# ==============================================================================

# Create a plugin fixture with descriptor.json
# Arguments: $1=plugins_dir $2=plugin_name $3=descriptor_json
create_plugin_fixture() {
  local plugins_dir="$1"
  local plugin_name="$2"
  local descriptor_json="$3"
  mkdir -p "${plugins_dir}/${plugin_name}"
  echo "$descriptor_json" > "${plugins_dir}/${plugin_name}/descriptor.json"
}

# ==============================================================================
# Tests: verify_plugin_installation
# ==============================================================================

test_verify_plugin_installation_succeeds_with_available_tools() {
  local plugins_dir="${TEST_FIXTURE_DIR}/available_tools"
  mkdir -p "$plugins_dir"

  # Plugin with a check command that will succeed (true command)
  create_plugin_fixture "$plugins_dir" "test-plugin" '{
    "name": "test-plugin",
    "description": "Test plugin with available tool",
    "active": true,
    "commandline": "echo test",
    "check_commandline": "command -v echo",
    "install_commandline": "echo install"
  }'

  # Run verification
  verify_plugin_installation "$plugins_dir" 2>/dev/null
  local exit_code=$?

  assert_exit_code 0 "$exit_code" "verify_plugin_installation should succeed with available tools"
  
  # Check that UNAVAILABLE_PLUGINS is empty
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${#UNAVAILABLE_PLUGINS[@]} -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} PASS: UNAVAILABLE_PLUGINS should be empty when all tools are available"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: UNAVAILABLE_PLUGINS should be empty"
    echo "  Found: ${#UNAVAILABLE_PLUGINS[@]} unavailable plugins"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_verify_plugin_installation_tracks_unavailable_tools() {
  local plugins_dir="${TEST_FIXTURE_DIR}/unavailable_tools"
  mkdir -p "$plugins_dir"

  # Plugin with a check command that will fail
  create_plugin_fixture "$plugins_dir" "missing-tool" '{
    "name": "missing-tool",
    "description": "Plugin with missing tool",
    "active": true,
    "commandline": "nonexistent_command",
    "check_commandline": "command -v nonexistent_command_that_does_not_exist_12345",
    "install_commandline": "apt install nonexistent"
  }'

  # Run verification
  verify_plugin_installation "$plugins_dir" 2>/dev/null
  local exit_code=$?

  assert_exit_code 0 "$exit_code" "verify_plugin_installation should succeed even with unavailable tools"
  
  # Check that missing-tool is in UNAVAILABLE_PLUGINS
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -v UNAVAILABLE_PLUGINS["missing-tool"] ]]; then
    echo -e "${GREEN}✓${NC} PASS: missing-tool should be tracked in UNAVAILABLE_PLUGINS"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: missing-tool should be in UNAVAILABLE_PLUGINS"
    echo "  UNAVAILABLE_PLUGINS keys: ${!UNAVAILABLE_PLUGINS[@]}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_verify_plugin_installation_skips_inactive_plugins() {
  local plugins_dir="${TEST_FIXTURE_DIR}/inactive_plugins"
  mkdir -p "$plugins_dir"

  # Inactive plugin with missing tool
  create_plugin_fixture "$plugins_dir" "inactive-plugin" '{
    "name": "inactive-plugin",
    "description": "Inactive plugin",
    "active": false,
    "commandline": "nonexistent_command",
    "check_commandline": "command -v nonexistent_command_inactive",
    "install_commandline": "apt install nonexistent"
  }'

  # Run verification
  verify_plugin_installation "$plugins_dir" 2>/dev/null
  local exit_code=$?

  assert_exit_code 0 "$exit_code" "verify_plugin_installation should succeed"
  
  # Check that inactive-plugin is NOT in UNAVAILABLE_PLUGINS
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -v UNAVAILABLE_PLUGINS["inactive-plugin"] ]]; then
    echo -e "${GREEN}✓${NC} PASS: inactive plugins should not be checked"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: inactive-plugin should not be in UNAVAILABLE_PLUGINS"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_verify_plugin_installation_handles_missing_check_command() {
  local plugins_dir="${TEST_FIXTURE_DIR}/no_check_command"
  mkdir -p "$plugins_dir"

  # Plugin without check_commandline
  create_plugin_fixture "$plugins_dir" "no-check" '{
    "name": "no-check",
    "description": "Plugin without check command",
    "active": true,
    "commandline": "echo test"
  }'

  # Run verification
  verify_plugin_installation "$plugins_dir" 2>/dev/null
  local exit_code=$?

  assert_exit_code 0 "$exit_code" "verify_plugin_installation should succeed"
  
  # Check that no-check is in UNAVAILABLE_PLUGINS (no check = can't verify)
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -v UNAVAILABLE_PLUGINS["no-check"] ]]; then
    echo -e "${GREEN}✓${NC} PASS: plugins without check_commandline should be tracked"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: no-check should be in UNAVAILABLE_PLUGINS"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_verify_plugin_installation_respects_activation_overrides() {
  local plugins_dir="${TEST_FIXTURE_DIR}/override_plugins"
  mkdir -p "$plugins_dir"

  # Active plugin with missing tool
  create_plugin_fixture "$plugins_dir" "override-plugin" '{
    "name": "override-plugin",
    "description": "Plugin to be overridden",
    "active": true,
    "commandline": "nonexistent_command",
    "check_commandline": "command -v nonexistent_override_command",
    "install_commandline": "apt install nonexistent"
  }'

  # Set CLI override to disable the plugin
  declare -gA PLUGIN_ACTIVATION_OVERRIDES
  PLUGIN_ACTIVATION_OVERRIDES["override-plugin"]="false"

  # Run verification
  verify_plugin_installation "$plugins_dir" 2>/dev/null
  local exit_code=$?

  assert_exit_code 0 "$exit_code" "verify_plugin_installation should succeed"
  
  # Check that override-plugin is NOT checked (because it's disabled via override)
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -v UNAVAILABLE_PLUGINS["override-plugin"] ]]; then
    echo -e "${GREEN}✓${NC} PASS: plugins disabled via CLI override should not be checked"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: override-plugin should not be in UNAVAILABLE_PLUGINS"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  
  # Clean up
  unset PLUGIN_ACTIVATION_OVERRIDES
}

test_verify_plugin_installation_mixed_availability() {
  local plugins_dir="${TEST_FIXTURE_DIR}/mixed_plugins"
  mkdir -p "$plugins_dir"

  # Available plugin
  create_plugin_fixture "$plugins_dir" "available-plugin" '{
    "name": "available-plugin",
    "description": "Available plugin",
    "active": true,
    "commandline": "echo test",
    "check_commandline": "command -v echo",
    "install_commandline": "echo install"
  }'

  # Unavailable plugin
  create_plugin_fixture "$plugins_dir" "unavailable-plugin" '{
    "name": "unavailable-plugin",
    "description": "Unavailable plugin",
    "active": true,
    "commandline": "missing_cmd",
    "check_commandline": "command -v missing_cmd_mixed",
    "install_commandline": "apt install missing"
  }'

  # Run verification
  verify_plugin_installation "$plugins_dir" 2>/dev/null
  local exit_code=$?

  assert_exit_code 0 "$exit_code" "verify_plugin_installation should succeed"
  
  # Check that only unavailable-plugin is tracked
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ${#UNAVAILABLE_PLUGINS[@]} -eq 1 ]] && [[ -v UNAVAILABLE_PLUGINS["unavailable-plugin"] ]]; then
    echo -e "${GREEN}✓${NC} PASS: only unavailable plugins should be tracked"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: should have exactly 1 unavailable plugin"
    echo "  Found: ${#UNAVAILABLE_PLUGINS[@]} unavailable plugins"
    echo "  Keys: ${!UNAVAILABLE_PLUGINS[@]}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  
  # Check that available-plugin is NOT in UNAVAILABLE_PLUGINS
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -v UNAVAILABLE_PLUGINS["available-plugin"] ]]; then
    echo -e "${GREEN}✓${NC} PASS: available-plugin should not be tracked"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: available-plugin should not be in UNAVAILABLE_PLUGINS"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ==============================================================================
# Test Runner
# ==============================================================================

main() {
  echo ""
  echo "======================================================================"
  echo "Plugin Installation Verification Tests (Feature 43)"
  echo "======================================================================"
  echo ""
  
  # Run all tests
  setup_test
  test_verify_plugin_installation_succeeds_with_available_tools
  teardown_test
  
  setup_test
  test_verify_plugin_installation_tracks_unavailable_tools
  teardown_test
  
  setup_test
  test_verify_plugin_installation_skips_inactive_plugins
  teardown_test
  
  setup_test
  test_verify_plugin_installation_handles_missing_check_command
  teardown_test
  
  setup_test
  test_verify_plugin_installation_respects_activation_overrides
  teardown_test
  
  setup_test
  test_verify_plugin_installation_mixed_availability
  teardown_test
  
  # Print summary
  echo ""
  echo "======================================================================"
  echo -e "Test Summary: ${GREEN}${TESTS_PASSED} passed${NC}, ${RED}${TESTS_FAILED} failed${NC}, ${TESTS_RUN} total"
  echo "======================================================================"
  echo ""
  
  # Exit with error if any tests failed
  if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
  fi
  
  exit 0
}

main "$@"
