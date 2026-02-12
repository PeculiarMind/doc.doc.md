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

# Unit Tests: Advanced Help System (Feature 0014)
# TDD Red Phase: Tests written before implementation
# These tests define the expected behavior for:
#   --help-plugins   Plugin documentation
#   --help-template  Template syntax reference
#   --help-examples  Usage examples

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/doc.doc.sh"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Advanced Help System (Feature 0014)"

# ==============================================================================
# --help-plugins Tests
# ==============================================================================

# Test 1: --help-plugins flag is recognized
test_help_plugins_flag() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --help-plugins
  
  assert_exit_code 0 $exit_code "--help-plugins should exit with code 0"
}

# Test 2: --help-plugins shows plugin overview
test_help_plugins_overview() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --help-plugins
  
  assert_contains "$output" "Plugin" "--help-plugins should mention plugins"
}

# Test 3: --help-plugins shows plugin discovery info
test_help_plugins_discovery() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --help-plugins
  
  assert_contains "$output" "plugins/" "--help-plugins should mention plugin directories"
}

# Test 4: --help-plugins shows descriptor format
test_help_plugins_descriptor() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --help-plugins
  
  assert_contains "$output" "descriptor" "--help-plugins should reference descriptor format"
}

# ==============================================================================
# --help-template Tests
# ==============================================================================

# Test 5: --help-template flag is recognized
test_help_template_flag() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --help-template
  
  assert_exit_code 0 $exit_code "--help-template should exit with code 0"
}

# Test 6: --help-template shows template syntax
test_help_template_syntax() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --help-template
  
  assert_contains "$output" "Template" "--help-template should mention templates"
}

# Test 7: --help-template shows variable substitution
test_help_template_variables() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --help-template
  
  assert_contains "$output" "variable" "--help-template should explain variable substitution"
}

# ==============================================================================
# --help-examples Tests
# ==============================================================================

# Test 8: --help-examples flag is recognized
test_help_examples_flag() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --help-examples
  
  assert_exit_code 0 $exit_code "--help-examples should exit with code 0"
}

# Test 9: --help-examples shows usage scenarios
test_help_examples_scenarios() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --help-examples
  
  assert_contains "$output" "doc.doc.sh" "--help-examples should include command examples"
}

# Test 10: --help-examples shows automation guidance
test_help_examples_automation() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --help-examples
  
  assert_contains "$output" "Automation" "--help-examples should include automation examples"
}

# ==============================================================================
# Main help cross-references advanced topics
# ==============================================================================

# Test 11: Main help references advanced help topics
test_main_help_references_advanced() {
  local output exit_code
  run_command output exit_code "$SCRIPT_PATH" --help
  
  assert_contains "$output" "--help-plugins" "Main help should reference --help-plugins"
  assert_contains "$output" "--help-template" "Main help should reference --help-template"
  assert_contains "$output" "--help-examples" "Main help should reference --help-examples"
}

# Run all tests
test_help_plugins_flag
test_help_plugins_overview
test_help_plugins_discovery
test_help_plugins_descriptor
test_help_template_flag
test_help_template_syntax
test_help_template_variables
test_help_examples_flag
test_help_examples_scenarios
test_help_examples_automation
test_main_help_references_advanced

finish_test_suite "Advanced Help System (Feature 0014)"
exit $?
