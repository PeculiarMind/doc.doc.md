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

# Unit Tests: Script Structure and Initialization
# Tests the basic structure, shebang, and script metadata

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/doc.doc.sh"
COMPONENTS_DIR="$PROJECT_ROOT/scripts/components"

# Source test helpers
source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Script Structure and Initialization"

# Test 1: Script file exists
test_script_exists() {
  assert_file_exists "$SCRIPT_PATH" "doc.doc.sh script should exist"
}

# Test 2: Script is executable
test_script_executable() {
  assert_file_executable "$SCRIPT_PATH" "doc.doc.sh should be executable"
}

# Test 3: Script has proper shebang
test_shebang() {
  local shebang
  shebang=$(head -n 1 "$SCRIPT_PATH")
  assert_contains "$shebang" "#!/usr/bin/env bash" "Script should have correct shebang"
}

# Test 4: SCRIPT_VERSION constant defined in constants.sh component
test_version_constant() {
  local main_content components_content
  main_content=$(cat "$SCRIPT_PATH")
  components_content=$(cat "$COMPONENTS_DIR/core/constants.sh")
  
  # Check if main script sources constants component
  assert_contains "$main_content" "source_component" "Main script should load components"
  
  # Check if constants component defines SCRIPT_VERSION
  assert_contains "$components_content" "SCRIPT_VERSION" "constants.sh should define SCRIPT_VERSION constant"
}

# Test 5: Exit code constants defined in constants.sh component
test_exit_code_constants() {
  local content
  content=$(cat "$COMPONENTS_DIR/core/constants.sh")
  assert_contains "$content" "EXIT_SUCCESS" "constants.sh should define EXIT_SUCCESS constant"
  assert_contains "$content" "EXIT_INVALID_ARGS" "constants.sh should define EXIT_INVALID_ARGS constant"
  assert_contains "$content" "EXIT_FILE_ERROR" "constants.sh should define EXIT_FILE_ERROR constant"
  assert_contains "$content" "EXIT_PLUGIN_ERROR" "constants.sh should define EXIT_PLUGIN_ERROR constant"
  assert_contains "$content" "EXIT_REPORT_ERROR" "constants.sh should define EXIT_REPORT_ERROR constant"
  assert_contains "$content" "EXIT_WORKSPACE_ERROR" "constants.sh should define EXIT_WORKSPACE_ERROR constant"
}

# Test 6: Script uses bash strict mode
test_bash_strict_mode() {
  local content
  content=$(cat "$SCRIPT_PATH")
  assert_contains "$content" "set -" "Script should use set command for strict mode"
}

# Test 7: VERBOSE flag defined in logging.sh component
test_verbose_flag() {
  local content
  content=$(cat "$COMPONENTS_DIR/core/logging.sh")
  assert_contains "$content" "VERBOSE" "logging.sh should define VERBOSE flag"
}

# Test 8: Functions exist in component modules
test_functions_exist() {
  local main_content help_content version_content args_content log_content
  main_content=$(cat "$SCRIPT_PATH")
  help_content=$(cat "$COMPONENTS_DIR/ui/help_system.sh")
  version_content=$(cat "$COMPONENTS_DIR/ui/version_info.sh")
  args_content=$(cat "$COMPONENTS_DIR/ui/argument_parser.sh")
  log_content=$(cat "$COMPONENTS_DIR/core/logging.sh")
  
  # Verify main script loads components
  assert_contains "$main_content" "source_component" "Main script should load component modules"
  
  # Verify functions exist in respective components
  assert_contains "$help_content" "show_help" "help_system.sh should have show_help function"
  assert_contains "$version_content" "show_version" "version_info.sh should have show_version function"
  assert_contains "$args_content" "parse_arguments" "argument_parser.sh should have parse_arguments function"
  assert_contains "$log_content" "log" "logging.sh should have log function"
}

# Run all tests
test_script_exists
test_script_executable
test_shebang
test_version_constant
test_exit_code_constants
test_bash_strict_mode
test_verbose_flag
test_functions_exist

finish_test_suite "Script Structure and Initialization"
exit $?
