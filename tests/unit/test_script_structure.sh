#!/usr/bin/env bash
# Unit Tests: Script Structure and Initialization
# Tests the basic structure, shebang, and script metadata

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/doc.doc.sh"

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

# Test 4: Script defines version constant
test_version_constant() {
  local content
  content=$(cat "$SCRIPT_PATH")
  assert_contains "$content" "SCRIPT_VERSION" "Script should define SCRIPT_VERSION constant"
}

# Test 5: Script defines exit code constants
test_exit_code_constants() {
  local content
  content=$(cat "$SCRIPT_PATH")
  assert_contains "$content" "EXIT_SUCCESS" "Script should define EXIT_SUCCESS constant"
  assert_contains "$content" "EXIT_INVALID_ARGS" "Script should define EXIT_INVALID_ARGS constant"
  assert_contains "$content" "EXIT_FILE_ERROR" "Script should define EXIT_FILE_ERROR constant"
  assert_contains "$content" "EXIT_PLUGIN_ERROR" "Script should define EXIT_PLUGIN_ERROR constant"
  assert_contains "$content" "EXIT_REPORT_ERROR" "Script should define EXIT_REPORT_ERROR constant"
  assert_contains "$content" "EXIT_WORKSPACE_ERROR" "Script should define EXIT_WORKSPACE_ERROR constant"
}

# Test 6: Script uses bash strict mode
test_bash_strict_mode() {
  local content
  content=$(cat "$SCRIPT_PATH")
  assert_contains "$content" "set -" "Script should use set command for strict mode"
}

# Test 7: Script defines VERBOSE flag
test_verbose_flag() {
  local content
  content=$(cat "$SCRIPT_PATH")
  assert_contains "$content" "VERBOSE" "Script should define VERBOSE flag"
}

# Test 8: Script has modular functions
test_functions_exist() {
  local content
  content=$(cat "$SCRIPT_PATH")
  assert_contains "$content" "show_help" "Script should have show_help function"
  assert_contains "$content" "show_version" "Script should have show_version function"
  assert_contains "$content" "parse_arguments" "Script should have parse_arguments function"
  assert_contains "$content" "log" "Script should have log function"
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
