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

# Unit Tests: Plugin Listing
# Tests plugin discovery and listing functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/doc.doc.sh"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Plugin Listing"

# ==============================================================================
# Tests
# ==============================================================================

# Test 1: -p list command displays plugins
test_plugin_list_command() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -p list
  
  assert_exit_code 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Available Plugins" "Output should contain header"
  assert_contains "$output" "stat" "Should show stat plugin"
}

# Test 2: --plugin list long form works
test_plugin_list_long_form() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --plugin list
  
  assert_exit_code 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Available Plugins" "Output should contain header"
}

# Test 3: -v -p list shows verbose output
test_plugin_list_with_verbose() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -v -p list
  
  assert_exit_code 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Listing available plugins" "Should show listing message"
  assert_contains "$output" "Available Plugins" "Output should contain header"
}

# Test 4: Plugin list shows ACTIVE/INACTIVE status
test_plugin_list_shows_active_status() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -p list
  
  assert_contains "$output" "ACTIVE" "Should show ACTIVE or INACTIVE indicator"
}

# Test 5: Invalid plugin subcommand shows error
test_plugin_list_invalid_subcommand() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -p invalid
  
  assert_exit_code 1 $exit_code "Exit code should be 1"
  assert_contains "$output" "Unknown plugin subcommand" "Should show error message"
  assert_contains "$output" "Available subcommands" "Should show available subcommands"
}

# Test 6: -p without subcommand shows error
test_plugin_list_missing_subcommand() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -p
  
  assert_exit_code 1 $exit_code "Exit code should be 1"
  assert_contains "$output" "requires a subcommand" "Should show error message"
}

# Test 7: Unimplemented plugin subcommand shows error
test_plugin_list_unimplemented_subcommand() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -p info
  
  assert_exit_code 1 $exit_code "Exit code should be 1"
  assert_contains "$output" "not yet implemented" "Should show not implemented message"
}

# Test 8: Plugin list shows actual stat plugin
test_plugin_list_with_real_plugins() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" -p list
  
  assert_exit_code 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "stat" "Should show stat plugin"
  assert_contains "$output" "Retrieves file statistics" "Should show stat description"
}

# Run all tests
test_plugin_list_command
test_plugin_list_long_form
test_plugin_list_with_verbose
test_plugin_list_shows_active_status
test_plugin_list_invalid_subcommand
test_plugin_list_missing_subcommand
test_plugin_list_unimplemented_subcommand
test_plugin_list_with_real_plugins

# ==============================================================================
# Summary
# ==============================================================================

finish_test_suite "Plugin Listing"
