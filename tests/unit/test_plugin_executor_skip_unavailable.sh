#!/usr/bin/env bash
# Test: Plugin Executor Skips Unavailable Plugins (Feature 43)
# Tests that execute_plugin skips plugins in UNAVAILABLE_PLUGINS array

# Determine repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPONENTS_DIR="${REPO_ROOT}/scripts/components"

# Load test helpers
source "${REPO_ROOT}/tests/helpers/test_helpers.sh"

# ==============================================================================
# Test Setup and Teardown
# ==============================================================================

TEST_FIXTURE_DIR="/tmp/plugin_executor_skip_test_$$"

setup_test() {
  source "$COMPONENTS_DIR/core/constants.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/core/logging.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/core/error_handling.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/plugin/plugin_parser.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/plugin/plugin_validator.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/plugin/plugin_tool_checker.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/workspace.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/plugin/plugin_executor.sh" 2>/dev/null || true

  mkdir -p "${TEST_FIXTURE_DIR}"
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
# Tests: execute_plugin with UNAVAILABLE_PLUGINS
# ==============================================================================

test_execute_plugin_skips_unavailable_plugin() {
  local plugins_dir="${TEST_FIXTURE_DIR}/skip_test"
  mkdir -p "$plugins_dir"

  # Create a plugin
  create_plugin_fixture "$plugins_dir" "test-plugin" '{
    "name": "test-plugin",
    "description": "Test plugin",
    "active": true,
    "commandline": "echo test-output",
    "check_commandline": "true",
    "install_commandline": "true"
  }'

  # Mark the plugin as unavailable
  declare -gA UNAVAILABLE_PLUGINS
  UNAVAILABLE_PLUGINS["test-plugin"]="tool_missing"

  # Try to execute the plugin
  local output
  output=$(execute_plugin "test-plugin" "$plugins_dir" '{}' 2>&1)
  local exit_code=$?

  # Should fail with exit code 1
  assert_exit_code 1 "$exit_code" "execute_plugin should fail for unavailable plugins"
  
  # Should not contain the output from the plugin command
  assert_not_contains "$output" "test-output" "unavailable plugin should not execute"
}

test_execute_plugin_runs_available_plugin() {
  local plugins_dir="${TEST_FIXTURE_DIR}/run_test"
  mkdir -p "$plugins_dir"

  # Create a plugin
  create_plugin_fixture "$plugins_dir" "available-plugin" '{
    "name": "available-plugin",
    "description": "Available test plugin",
    "active": true,
    "commandline": "echo available-output",
    "check_commandline": "true",
    "install_commandline": "true"
  }'

  # Clear UNAVAILABLE_PLUGINS (plugin is available)
  declare -gA UNAVAILABLE_PLUGINS
  UNAVAILABLE_PLUGINS=()

  # Try to execute the plugin
  local output
  output=$(execute_plugin "available-plugin" "$plugins_dir" '{}' 2>&1)
  local exit_code=$?

  # Should succeed
  assert_exit_code 0 "$exit_code" "execute_plugin should succeed for available plugins"
  
  # Should contain the output from the plugin command
  assert_contains "$output" "available-output" "available plugin should execute and produce output"
}

test_execute_plugin_runs_when_not_in_unavailable_list() {
  local plugins_dir="${TEST_FIXTURE_DIR}/not_in_list"
  mkdir -p "$plugins_dir"

  # Create a plugin
  create_plugin_fixture "$plugins_dir" "other-plugin" '{
    "name": "other-plugin",
    "description": "Other test plugin",
    "active": true,
    "commandline": "echo other-output",
    "check_commandline": "true",
    "install_commandline": "true"
  }'

  # Mark a different plugin as unavailable
  declare -gA UNAVAILABLE_PLUGINS
  UNAVAILABLE_PLUGINS["different-plugin"]="tool_missing"

  # Try to execute other-plugin (which is not in the unavailable list)
  local output
  output=$(execute_plugin "other-plugin" "$plugins_dir" '{}' 2>&1)
  local exit_code=$?

  # Should succeed
  assert_exit_code 0 "$exit_code" "execute_plugin should succeed when plugin is not in unavailable list"
  
  # Should contain the output from the plugin command
  assert_contains "$output" "other-output" "plugin not in unavailable list should execute"
}

# ==============================================================================
# Test Runner
# ==============================================================================

main() {
  echo ""
  echo "======================================================================"
  echo "Plugin Executor Skip Unavailable Tests (Feature 43)"
  echo "======================================================================"
  echo ""
  
  # Run all tests
  setup_test
  test_execute_plugin_skips_unavailable_plugin
  teardown_test
  
  setup_test
  test_execute_plugin_runs_available_plugin
  teardown_test
  
  setup_test
  test_execute_plugin_runs_when_not_in_unavailable_list
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
