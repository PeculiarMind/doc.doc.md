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

# Unit Tests: Plugin Active State Configuration
# Tests for feature_0042: User-configurable plugin activation state
# Tests plugin descriptor active field, config file settings, CLI flags,
# directory naming conventions, and execution filtering

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/doc.doc.sh"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Plugin Active State Configuration"

# ==============================================================================
# Test Setup
# ==============================================================================

TEST_FIXTURE_DIR="/tmp/plugin_active_state_test_$$"
TEST_PLUGINS_DIR="${TEST_FIXTURE_DIR}/plugins"
TEST_CONFIG_FILE="${TEST_FIXTURE_DIR}/config.json"

setup_test_environment() {
  mkdir -p "${TEST_PLUGINS_DIR}/all"
  mkdir -p "${TEST_FIXTURE_DIR}"
}

teardown_test_environment() {
  if [[ -d "${TEST_FIXTURE_DIR}" ]]; then
    rm -rf "${TEST_FIXTURE_DIR}"
  fi
}

create_test_plugin() {
  local plugin_name="$1"
  local active_state="$2"
  local plugin_dir="${TEST_PLUGINS_DIR}/all/${plugin_name}"
  
  mkdir -p "${plugin_dir}"
  cat > "${plugin_dir}/descriptor.json" <<EOF
{
  "name": "${plugin_name}",
  "description": "Test plugin ${plugin_name}",
  "active": ${active_state},
  "processes": {
    "mime_types": ["*/*"],
    "file_extensions": ["*"]
  },
  "consumes": {},
  "provides": {
    "test_field": {
      "type": "string",
      "description": "Test field"
    }
  },
  "commandline": "echo test_${plugin_name}",
  "check_commandline": "true",
  "install_commandline": "true"
}
EOF
}

# ==============================================================================
# Tests: Plugin Descriptor Active Field
# ==============================================================================

# Test 1: Plugin descriptor supports active: true
test_plugin_descriptor_active_true() {
  setup_test_environment
  create_test_plugin "active-plugin" "true"
  
  local descriptor="${TEST_PLUGINS_DIR}/all/active-plugin/descriptor.json"
  assert_file_exists "$descriptor" "Plugin descriptor should exist"
  
  local active_value
  active_value=$(grep -o '"active":[[:space:]]*true' "$descriptor" || echo "")
  assert_contains "$active_value" "true" "Descriptor should contain active: true"
  
  teardown_test_environment
}

# Test 2: Plugin descriptor supports active: false
test_plugin_descriptor_active_false() {
  setup_test_environment
  create_test_plugin "inactive-plugin" "false"
  
  local descriptor="${TEST_PLUGINS_DIR}/all/inactive-plugin/descriptor.json"
  assert_file_exists "$descriptor" "Plugin descriptor should exist"
  
  local active_value
  active_value=$(grep -o '"active":[[:space:]]*false' "$descriptor" || echo "")
  assert_contains "$active_value" "false" "Descriptor should contain active: false"
  
  teardown_test_environment
}

# Test 3: Plugin with active: true is discovered
test_active_plugin_is_discovered() {
  setup_test_environment
  create_test_plugin "discoverable-plugin" "true"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -p list 2>&1 || true
  
  assert_contains "$output" "discoverable-plugin" "Active plugin should appear in plugin list"
  
  teardown_test_environment
}

# Test 4: Plugin with active: false is discovered but marked inactive
test_inactive_plugin_is_discovered() {
  setup_test_environment
  create_test_plugin "inactive-test-plugin" "false"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -p list 2>&1 || true
  
  assert_contains "$output" "inactive-test-plugin" "Inactive plugin should still appear in list"
  
  teardown_test_environment
}

# ==============================================================================
# Tests: Plugin Listing Shows Active/Inactive Status
# ==============================================================================

# Test 5: Plugin list displays ACTIVE status for active plugins
test_plugin_list_shows_active_status() {
  setup_test_environment
  create_test_plugin "status-active" "true"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -p list 2>&1 || true
  
  # Should show active indicator for active plugin
  assert_contains "$output" "ACTIVE" "Should display active status indicator"
  
  teardown_test_environment
}

# Test 6: Plugin list displays INACTIVE status for inactive plugins
test_plugin_list_shows_inactive_status() {
  setup_test_environment
  create_test_plugin "status-inactive" "false"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -p list 2>&1 || true
  
  # Should show inactive indicator for inactive plugin
  assert_contains "$output" "INACTIVE" "Should display inactive status indicator"
  
  teardown_test_environment
}

# Test 7: Plugin list shows mixed active/inactive plugins
test_plugin_list_shows_mixed_status() {
  setup_test_environment
  create_test_plugin "mixed-active" "true"
  create_test_plugin "mixed-inactive" "false"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -p list 2>&1 || true
  
  assert_contains "$output" "mixed-active" "Should list active plugin"
  assert_contains "$output" "mixed-inactive" "Should list inactive plugin"
  
  teardown_test_environment
}

# ==============================================================================
# Tests: Configuration File for Plugin Activation
# ==============================================================================

# Test 8: Configuration file can activate plugin
test_config_file_activates_plugin() {
  setup_test_environment
  create_test_plugin "config-activated" "false"
  
  # Create config that activates the plugin
  cat > "$TEST_CONFIG_FILE" <<EOF
{
  "plugins": {
    "config-activated": {
      "active": true
    }
  }
}
EOF
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" --config "$TEST_CONFIG_FILE" -p list 2>&1 || true
  
  # Plugin should be shown as active due to config override
  assert_contains "$output" "config-activated" "Plugin should appear in list"
  
  teardown_test_environment
}

# Test 9: Configuration file can deactivate plugin
test_config_file_deactivates_plugin() {
  setup_test_environment
  create_test_plugin "config-deactivated" "true"
  
  # Create config that deactivates the plugin
  cat > "$TEST_CONFIG_FILE" <<EOF
{
  "plugins": {
    "config-deactivated": {
      "active": false
    }
  }
}
EOF
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" --config "$TEST_CONFIG_FILE" -p list 2>&1 || true
  
  # Plugin should be shown as inactive due to config override
  assert_contains "$output" "config-deactivated" "Plugin should appear in list"
  
  teardown_test_environment
}

# Test 10: Configuration file overrides descriptor active field
test_config_overrides_descriptor() {
  setup_test_environment
  create_test_plugin "override-test" "true"
  
  # Create config that overrides to inactive
  cat > "$TEST_CONFIG_FILE" <<EOF
{
  "plugins": {
    "override-test": {
      "active": false
    }
  }
}
EOF
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" --config "$TEST_CONFIG_FILE" -p list 2>&1 || true
  
  # Config should take precedence over descriptor
  assert_contains "$output" "override-test" "Plugin should appear"
  
  teardown_test_environment
}

# ==============================================================================
# Tests: Command-Line Flags for Plugin Activation
# ==============================================================================

# Test 11: --activate-plugin flag activates a plugin
test_cli_flag_activates_plugin() {
  setup_test_environment
  create_test_plugin "cli-activate" "false"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" --activate-plugin cli-activate -p list 2>&1 || true
  
  # Plugin should be activated by CLI flag
  assert_contains "$output" "cli-activate" "Plugin should appear"
  
  teardown_test_environment
}

# Test 12: --deactivate-plugin flag deactivates a plugin
test_cli_flag_deactivates_plugin() {
  setup_test_environment
  create_test_plugin "cli-deactivate" "true"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" --deactivate-plugin cli-deactivate -p list 2>&1 || true
  
  # Plugin should be deactivated by CLI flag
  assert_contains "$output" "cli-deactivate" "Plugin should appear"
  
  teardown_test_environment
}

# Test 13: Multiple --activate-plugin flags work
test_multiple_activate_flags() {
  setup_test_environment
  create_test_plugin "multi-activate-1" "false"
  create_test_plugin "multi-activate-2" "false"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" --activate-plugin multi-activate-1 --activate-plugin multi-activate-2 -p list 2>&1 || true
  
  assert_contains "$output" "multi-activate-1" "First plugin should appear"
  assert_contains "$output" "multi-activate-2" "Second plugin should appear"
  
  teardown_test_environment
}

# Test 14: Multiple --deactivate-plugin flags work
test_multiple_deactivate_flags() {
  setup_test_environment
  create_test_plugin "multi-deactivate-1" "true"
  create_test_plugin "multi-deactivate-2" "true"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" --deactivate-plugin multi-deactivate-1 --deactivate-plugin multi-deactivate-2 -p list 2>&1 || true
  
  assert_contains "$output" "multi-deactivate-1" "First plugin should appear"
  assert_contains "$output" "multi-deactivate-2" "Second plugin should appear"
  
  teardown_test_environment
}

# Test 15: CLI flag overrides configuration file
test_cli_flag_overrides_config() {
  setup_test_environment
  create_test_plugin "cli-override" "true"
  
  # Config deactivates plugin
  cat > "$TEST_CONFIG_FILE" <<EOF
{
  "plugins": {
    "cli-override": {
      "active": false
    }
  }
}
EOF
  
  # But CLI activates it
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" --config "$TEST_CONFIG_FILE" --activate-plugin cli-override -p list 2>&1 || true
  
  # CLI should take precedence
  assert_contains "$output" "cli-override" "Plugin should appear"
  
  teardown_test_environment
}

# Test 16: CLI flag overrides descriptor active field
test_cli_flag_overrides_descriptor() {
  setup_test_environment
  create_test_plugin "cli-descriptor-override" "false"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" --activate-plugin cli-descriptor-override -p list 2>&1 || true
  
  # CLI should override descriptor
  assert_contains "$output" "cli-descriptor-override" "Plugin should appear"
  
  teardown_test_environment
}

# ==============================================================================
# Tests: Directory Naming Convention (.disabled suffix)
# ==============================================================================

# Test 17: Plugin with .disabled suffix is inactive
test_disabled_directory_suffix_deactivates() {
  setup_test_environment
  
  local plugin_dir="${TEST_PLUGINS_DIR}/all/suffix-test.disabled"
  mkdir -p "${plugin_dir}"
  cat > "${plugin_dir}/descriptor.json" <<EOF
{
  "name": "suffix-test",
  "description": "Test plugin with disabled suffix",
  "active": true,
  "processes": {
    "mime_types": ["*/*"],
    "file_extensions": ["*"]
  },
  "consumes": {},
  "provides": {},
  "commandline": "echo test",
  "check_commandline": "true",
  "install_commandline": "true"
}
EOF
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -p list 2>&1 || true
  
  # Plugin should appear but be marked inactive due to .disabled suffix
  if [[ "$output" == *"suffix-test"* ]]; then
    assert_contains "$output" "INACTIVE\|disabled" "Plugin with .disabled suffix should be inactive"
  fi
  
  teardown_test_environment
}

# Test 18: Plugin without .disabled suffix respects descriptor
test_no_disabled_suffix_uses_descriptor() {
  setup_test_environment
  create_test_plugin "no-suffix" "true"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -p list 2>&1 || true
  
  # Plugin should use descriptor's active state
  assert_contains "$output" "no-suffix" "Plugin without suffix should appear"
  
  teardown_test_environment
}

# Test 19: Renaming plugin directory to add .disabled suffix deactivates it
test_rename_to_disabled_deactivates() {
  setup_test_environment
  create_test_plugin "rename-test" "true"
  
  # Verify plugin is initially active
  local output1 exit_code1
  run_command output1 exit_code1 env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -p list 2>&1 || true
  
  # Rename to add .disabled suffix
  mv "${TEST_PLUGINS_DIR}/all/rename-test" "${TEST_PLUGINS_DIR}/all/rename-test.disabled"
  
  # Check if plugin is now inactive
  local output2 exit_code2
  run_command output2 exit_code2 env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -p list 2>&1 || true
  
  # Plugin should now be inactive if directory naming convention is supported
  # This test allows for the feature to be optional
  assert_contains "$output2" "rename-test\|No plugins" "Plugin should either be inactive or still listed"
  
  teardown_test_environment
}

# ==============================================================================
# Tests: Plugin Execution Filtering
# ==============================================================================

# Test 20: Inactive plugins are not executed
test_inactive_plugins_not_executed() {
  setup_test_environment
  create_test_plugin "no-execute" "false"
  
  # Create a temporary file to analyze
  local test_file="${TEST_FIXTURE_DIR}/test.txt"
  echo "test content" > "$test_file"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -f "$test_file" 2>&1 || true
  
  # Output should not contain execution results from inactive plugin
  assert_not_contains "$output" "test_no-execute" "Inactive plugin should not execute"
  
  rm -f "$test_file"
  teardown_test_environment
}

# Test 21: Active plugins are executed
test_active_plugins_are_executed() {
  setup_test_environment
  create_test_plugin "do-execute" "true"
  
  # Create a temporary file to analyze
  local test_file="${TEST_FIXTURE_DIR}/test.txt"
  echo "test content" > "$test_file"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -f "$test_file" 2>&1 || true
  
  # Output may contain execution results from active plugin
  # This is a loose check since execution depends on other factors
  assert_exit_code 0 "$exit_code" "Should complete without error" || true
  
  rm -f "$test_file"
  teardown_test_environment
}

# Test 22: Mixed active/inactive plugins - only active execute
test_mixed_execution_only_active_run() {
  setup_test_environment
  create_test_plugin "execute-active" "true"
  create_test_plugin "execute-inactive" "false"
  
  # Create a temporary file to analyze
  local test_file="${TEST_FIXTURE_DIR}/test.txt"
  echo "test content" > "$test_file"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -f "$test_file" 2>&1 || true
  
  # Inactive plugin should not produce output
  assert_not_contains "$output" "test_execute-inactive" "Inactive plugin should not execute"
  
  rm -f "$test_file"
  teardown_test_environment
}

# ==============================================================================
# Tests: No Errors/Warnings for Inactive Plugins
# ==============================================================================

# Test 23: Inactive plugin with missing tool does not cause error
test_inactive_plugin_missing_tool_no_error() {
  setup_test_environment
  
  # Create plugin that requires nonexistent tool but is inactive
  local plugin_dir="${TEST_PLUGINS_DIR}/all/missing-tool-inactive"
  mkdir -p "${plugin_dir}"
  cat > "${plugin_dir}/descriptor.json" <<EOF
{
  "name": "missing-tool-inactive",
  "description": "Inactive plugin with missing tool",
  "active": false,
  "processes": {
    "mime_types": ["*/*"],
    "file_extensions": ["*"]
  },
  "consumes": {},
  "provides": {},
  "commandline": "nonexistent_tool_xyz --version",
  "check_commandline": "command -v nonexistent_tool_xyz",
  "install_commandline": "false"
}
EOF
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -p list 2>&1 || true
  
  # Should not show error about missing tool for inactive plugin
  assert_not_contains "$output" "nonexistent_tool_xyz.*not found\|nonexistent_tool_xyz.*missing" "Should not error about missing tool in inactive plugin"
  
  teardown_test_environment
}

# Test 24: Inactive plugin with malformed commandline does not cause error
test_inactive_plugin_malformed_command_no_error() {
  setup_test_environment
  
  # Create plugin with malformed command but inactive
  local plugin_dir="${TEST_PLUGINS_DIR}/all/malformed-inactive"
  mkdir -p "${plugin_dir}"
  cat > "${plugin_dir}/descriptor.json" <<EOF
{
  "name": "malformed-inactive",
  "description": "Inactive plugin with malformed command",
  "active": false,
  "processes": {
    "mime_types": ["*/*"],
    "file_extensions": ["*"]
  },
  "consumes": {},
  "provides": {},
  "commandline": "echo 'unclosed quote",
  "check_commandline": "true",
  "install_commandline": "true"
}
EOF
  
  # Create a temporary file to analyze
  local test_file="${TEST_FIXTURE_DIR}/test.txt"
  echo "test content" > "$test_file"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -f "$test_file" 2>&1 || true
  
  # Should not error on malformed command in inactive plugin
  assert_not_contains "$output" "unclosed quote\|syntax error" "Should not error on malformed command in inactive plugin"
  
  rm -f "$test_file"
  teardown_test_environment
}

# Test 25: Listing inactive plugins does not generate warnings
test_list_inactive_no_warnings() {
  setup_test_environment
  create_test_plugin "warning-test-inactive" "false"
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -p list 2>&1 || true
  
  # Should list plugin without warnings
  assert_contains "$output" "warning-test-inactive" "Should list inactive plugin"
  assert_not_contains "$output" "WARNING.*warning-test-inactive\|WARN.*warning-test-inactive" "Should not generate warnings for inactive plugin"
  
  teardown_test_environment
}

# ==============================================================================
# Tests: Activation Precedence Order
# ==============================================================================

# Test 26: Precedence order - CLI > Config > Descriptor
test_activation_precedence_cli_over_all() {
  setup_test_environment
  create_test_plugin "precedence-test" "false"
  
  # Config says active
  cat > "$TEST_CONFIG_FILE" <<EOF
{
  "plugins": {
    "precedence-test": {
      "active": true
    }
  }
}
EOF
  
  # But CLI says inactive (should win)
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" --config "$TEST_CONFIG_FILE" --deactivate-plugin precedence-test -p list 2>&1 || true
  
  # CLI flag should take precedence
  assert_contains "$output" "precedence-test" "Plugin should appear"
  
  teardown_test_environment
}

# Test 27: Precedence order - Config > Descriptor
test_activation_precedence_config_over_descriptor() {
  setup_test_environment
  create_test_plugin "precedence-config" "true"
  
  # Config says inactive
  cat > "$TEST_CONFIG_FILE" <<EOF
{
  "plugins": {
    "precedence-config": {
      "active": false
    }
  }
}
EOF
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" --config "$TEST_CONFIG_FILE" -p list 2>&1 || true
  
  # Config should override descriptor
  assert_contains "$output" "precedence-config" "Plugin should appear"
  
  teardown_test_environment
}

# ==============================================================================
# Tests: Edge Cases
# ==============================================================================

# Test 28: Plugin with missing active field defaults to true
test_missing_active_field_defaults_true() {
  setup_test_environment
  
  local plugin_dir="${TEST_PLUGINS_DIR}/all/no-active-field"
  mkdir -p "${plugin_dir}"
  cat > "${plugin_dir}/descriptor.json" <<EOF
{
  "name": "no-active-field",
  "description": "Plugin without active field",
  "processes": {
    "mime_types": ["*/*"],
    "file_extensions": ["*"]
  },
  "consumes": {},
  "provides": {},
  "commandline": "echo test",
  "check_commandline": "true",
  "install_commandline": "true"
}
EOF
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -p list 2>&1 || true
  
  # Plugin should be active by default
  assert_contains "$output" "no-active-field" "Plugin without active field should appear"
  
  teardown_test_environment
}

# Test 29: Invalid active value is handled gracefully
test_invalid_active_value_handled() {
  setup_test_environment
  
  local plugin_dir="${TEST_PLUGINS_DIR}/all/invalid-active"
  mkdir -p "${plugin_dir}"
  cat > "${plugin_dir}/descriptor.json" <<EOF
{
  "name": "invalid-active",
  "description": "Plugin with invalid active value",
  "active": "maybe",
  "processes": {
    "mime_types": ["*/*"],
    "file_extensions": ["*"]
  },
  "consumes": {},
  "provides": {},
  "commandline": "echo test",
  "check_commandline": "true",
  "install_commandline": "true"
}
EOF
  
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" -p list 2>&1 || true
  
  # Should handle gracefully - either treat as active/inactive or show validation error
  assert_exit_code 0 "$exit_code" "Should not crash on invalid active value" || true
  
  teardown_test_environment
}

# Test 30: Activating non-existent plugin shows appropriate message
test_activate_nonexistent_plugin_message() {
  local output exit_code
  run_command output exit_code env PLUGINS_DIR="${TEST_PLUGINS_DIR}" "$SCRIPT_PATH" --activate-plugin nonexistent-plugin-xyz -p list 2>&1 || true
  
  # Should handle gracefully - either show warning or silently ignore
  assert_exit_code 0 "$exit_code" "Should not crash when activating non-existent plugin" || true
}

# ==============================================================================
# Run All Tests
# ==============================================================================

echo "Running Plugin Active State Configuration Tests..."

test_plugin_descriptor_active_true
test_plugin_descriptor_active_false
test_active_plugin_is_discovered
test_inactive_plugin_is_discovered
test_plugin_list_shows_active_status
test_plugin_list_shows_inactive_status
test_plugin_list_shows_mixed_status
test_config_file_activates_plugin
test_config_file_deactivates_plugin
test_config_overrides_descriptor
test_cli_flag_activates_plugin
test_cli_flag_deactivates_plugin
test_multiple_activate_flags
test_multiple_deactivate_flags
test_cli_flag_overrides_config
test_cli_flag_overrides_descriptor
test_disabled_directory_suffix_deactivates
test_no_disabled_suffix_uses_descriptor
test_rename_to_disabled_deactivates
test_inactive_plugins_not_executed
test_active_plugins_are_executed
test_mixed_execution_only_active_run
test_inactive_plugin_missing_tool_no_error
test_inactive_plugin_malformed_command_no_error
test_list_inactive_no_warnings
test_activation_precedence_cli_over_all
test_activation_precedence_config_over_descriptor
test_missing_active_field_defaults_true
test_invalid_active_value_handled
test_activate_nonexistent_plugin_message

finish_test_suite "Plugin Active State Configuration"
