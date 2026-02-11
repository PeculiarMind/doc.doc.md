#!/usr/bin/env bash
# Test: plugin/plugin_executor.sh component
# Tests dependency graph, file filtering, variable substitution, execution, orchestration

# Determine repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPONENTS_DIR="${REPO_ROOT}/scripts/components"

# Load test helpers
source "${REPO_ROOT}/tests/helpers/test_helpers.sh"

# ==============================================================================
# Test Setup and Teardown
# ==============================================================================

TEST_FIXTURE_DIR="/tmp/plugin_executor_test_$$"

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
# Tests: build_dependency_graph
# ==============================================================================

test_build_dependency_graph_returns_plugins_in_order() {
  local plugins_dir="${TEST_FIXTURE_DIR}/graph_order"
  mkdir -p "$plugins_dir"

  # Plugin A provides field_x, Plugin B consumes field_x
  create_plugin_fixture "$plugins_dir" "plugin-a" '{
    "name": "plugin-a",
    "description": "Provider plugin",
    "active": true,
    "commandline": "echo hello",
    "check_commandline": "true",
    "install_commandline": "true",
    "provides": {"field_x": {"type": "string", "description": "X field"}},
    "consumes": {}
  }'

  create_plugin_fixture "$plugins_dir" "plugin-b" '{
    "name": "plugin-b",
    "description": "Consumer plugin",
    "active": true,
    "commandline": "echo world",
    "check_commandline": "true",
    "install_commandline": "true",
    "provides": {},
    "consumes": {"field_x": {"type": "string", "description": "X field"}}
  }'

  local output
  output=$(build_dependency_graph "$plugins_dir" 2>/dev/null)
  local exit_code=$?

  assert_exit_code 0 "$exit_code" "build_dependency_graph should succeed"

  # plugin-a must come before plugin-b
  local pos_a pos_b
  pos_a=$(echo "$output" | grep -n "plugin-a" | cut -d: -f1)
  pos_b=$(echo "$output" | grep -n "plugin-b" | cut -d: -f1)

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -n "$pos_a" ]] && [[ -n "$pos_b" ]] && [[ "$pos_a" -lt "$pos_b" ]]; then
    echo -e "${GREEN}✓${NC} PASS: plugin-a comes before plugin-b in dependency order"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: plugin-a should come before plugin-b"
    echo "  Output: $output"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_build_dependency_graph_detects_circular() {
  local plugins_dir="${TEST_FIXTURE_DIR}/graph_circular"
  mkdir -p "$plugins_dir"

  # Plugin A provides field_x, consumes field_y
  # Plugin B provides field_y, consumes field_x
  create_plugin_fixture "$plugins_dir" "plugin-a" '{
    "name": "plugin-a",
    "description": "Circular A",
    "active": true,
    "commandline": "echo a",
    "check_commandline": "true",
    "install_commandline": "true",
    "provides": {"field_x": {"type": "string", "description": "X"}},
    "consumes": {"field_y": {"type": "string", "description": "Y"}}
  }'

  create_plugin_fixture "$plugins_dir" "plugin-b" '{
    "name": "plugin-b",
    "description": "Circular B",
    "active": true,
    "commandline": "echo b",
    "check_commandline": "true",
    "install_commandline": "true",
    "provides": {"field_y": {"type": "string", "description": "Y"}},
    "consumes": {"field_x": {"type": "string", "description": "X"}}
  }'

  local output exit_code
  run_command output exit_code build_dependency_graph "$plugins_dir"

  assert_exit_code 1 "$exit_code" "build_dependency_graph should detect circular dependency"
}

# ==============================================================================
# Tests: should_execute_plugin
# ==============================================================================

test_should_execute_plugin_matching_extension() {
  local plugins_dir="${TEST_FIXTURE_DIR}/filter_ext"
  mkdir -p "$plugins_dir"

  create_plugin_fixture "$plugins_dir" "md-plugin" '{
    "name": "md-plugin",
    "description": "Markdown plugin",
    "active": true,
    "commandline": "echo test",
    "check_commandline": "true",
    "install_commandline": "true",
    "processes": {
      "file_extensions": [".md", ".txt"],
      "mime_types": ["text/markdown"]
    }
  }'

  # Create a test .md file
  echo "# Test" > "${TEST_FIXTURE_DIR}/test.md"

  local output exit_code
  run_command output exit_code should_execute_plugin "md-plugin" "${TEST_FIXTURE_DIR}/test.md" "$plugins_dir"

  assert_exit_code 0 "$exit_code" "should_execute_plugin returns 0 for matching .md extension"
}

test_should_execute_plugin_wildcard() {
  local plugins_dir="${TEST_FIXTURE_DIR}/filter_wildcard"
  mkdir -p "$plugins_dir"

  create_plugin_fixture "$plugins_dir" "all-plugin" '{
    "name": "all-plugin",
    "description": "Wildcard plugin",
    "active": true,
    "commandline": "echo test",
    "check_commandline": "true",
    "install_commandline": "true",
    "processes": {
      "file_extensions": ["*"],
      "mime_types": []
    }
  }'

  echo "data" > "${TEST_FIXTURE_DIR}/test.xyz"

  local output exit_code
  run_command output exit_code should_execute_plugin "all-plugin" "${TEST_FIXTURE_DIR}/test.xyz" "$plugins_dir"

  assert_exit_code 0 "$exit_code" "should_execute_plugin returns 0 for wildcard extension"
}

test_should_execute_plugin_no_processes_field() {
  local plugins_dir="${TEST_FIXTURE_DIR}/filter_none"
  mkdir -p "$plugins_dir"

  create_plugin_fixture "$plugins_dir" "noproc-plugin" '{
    "name": "noproc-plugin",
    "description": "No processes field",
    "active": true,
    "commandline": "echo test",
    "check_commandline": "true",
    "install_commandline": "true"
  }'

  echo "data" > "${TEST_FIXTURE_DIR}/test.any"

  local output exit_code
  run_command output exit_code should_execute_plugin "noproc-plugin" "${TEST_FIXTURE_DIR}/test.any" "$plugins_dir"

  assert_exit_code 0 "$exit_code" "should_execute_plugin returns 0 when no processes field (applies to all)"
}

test_should_execute_plugin_non_matching() {
  local plugins_dir="${TEST_FIXTURE_DIR}/filter_nomatch"
  mkdir -p "$plugins_dir"

  create_plugin_fixture "$plugins_dir" "pdf-plugin" '{
    "name": "pdf-plugin",
    "description": "PDF only plugin",
    "active": true,
    "commandline": "echo test",
    "check_commandline": "true",
    "install_commandline": "true",
    "processes": {
      "file_extensions": [".pdf"],
      "mime_types": ["application/pdf"]
    }
  }'

  echo "text" > "${TEST_FIXTURE_DIR}/test.txt"

  local output exit_code
  run_command output exit_code should_execute_plugin "pdf-plugin" "${TEST_FIXTURE_DIR}/test.txt" "$plugins_dir"

  assert_exit_code 1 "$exit_code" "should_execute_plugin returns 1 for non-matching file type"
}

# ==============================================================================
# Tests: substitute_variables_secure
# ==============================================================================

test_substitute_variables_replaces_correctly() {
  local result
  result=$(substitute_variables_secure 'echo ${name} ${count}' '{"name":"hello","count":"42"}' 2>/dev/null)
  local exit_code=$?

  assert_exit_code 0 "$exit_code" "substitute_variables_secure should succeed"
  assert_equals "echo hello 42" "$result" "Variables should be replaced with their values"
}

test_substitute_variables_rejects_injection() {
  local output exit_code
  run_command output exit_code substitute_variables_secure 'echo ${name}' '{"name":"hello; rm -rf /"}'

  assert_exit_code 1 "$exit_code" "substitute_variables_secure should reject injection characters"
}

test_substitute_variables_rejects_backtick() {
  local output exit_code
  run_command output exit_code substitute_variables_secure 'echo ${val}' '{"val":"$(whoami)"}'

  assert_exit_code 1 "$exit_code" "substitute_variables_secure should reject dollar-paren injection"
}

test_substitute_variables_rejects_pipe() {
  local output exit_code
  run_command output exit_code substitute_variables_secure 'echo ${val}' '{"val":"foo|bar"}'

  assert_exit_code 1 "$exit_code" "substitute_variables_secure should reject pipe injection"
}

# ==============================================================================
# Tests: execute_plugin
# ==============================================================================

test_execute_plugin_runs_simple_command() {
  local plugins_dir="${TEST_FIXTURE_DIR}/exec_simple"
  mkdir -p "$plugins_dir"

  create_plugin_fixture "$plugins_dir" "echo-plugin" '{
    "name": "echo-plugin",
    "description": "Simple echo plugin",
    "active": true,
    "commandline": "echo hello_world",
    "check_commandline": "echo ok",
    "install_commandline": "true",
    "provides": {},
    "consumes": {}
  }'

  local output
  output=$(execute_plugin "echo-plugin" "$plugins_dir" '{}' 2>/dev/null)
  local exit_code=$?

  assert_exit_code 0 "$exit_code" "execute_plugin should succeed for simple command"
  assert_contains "$output" "hello_world" "execute_plugin should capture stdout"
}

# ==============================================================================
# Tests: Function Existence
# ==============================================================================

test_orchestrate_plugins_function_exists() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if declare -f orchestrate_plugins >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: orchestrate_plugins function exists and is callable"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: orchestrate_plugins function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_execute_plugin_sandboxed_function_exists() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if declare -f execute_plugin_sandboxed >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: execute_plugin_sandboxed function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: execute_plugin_sandboxed function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_substitute_variables_secure_function_exists() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if declare -f substitute_variables_secure >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: substitute_variables_secure function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: substitute_variables_secure function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_should_execute_plugin_function_exists() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if declare -f should_execute_plugin >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: should_execute_plugin function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: should_execute_plugin function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ==============================================================================
# Test Execution
# ==============================================================================

main() {
  start_test_suite "plugin/plugin_executor.sh"

  setup_test

  # Function existence tests
  test_orchestrate_plugins_function_exists
  test_execute_plugin_sandboxed_function_exists
  test_substitute_variables_secure_function_exists
  test_should_execute_plugin_function_exists

  # build_dependency_graph tests
  test_build_dependency_graph_returns_plugins_in_order
  test_build_dependency_graph_detects_circular

  # should_execute_plugin tests
  test_should_execute_plugin_matching_extension
  test_should_execute_plugin_wildcard
  test_should_execute_plugin_no_processes_field
  test_should_execute_plugin_non_matching

  # substitute_variables_secure tests
  test_substitute_variables_replaces_correctly
  test_substitute_variables_rejects_injection
  test_substitute_variables_rejects_backtick
  test_substitute_variables_rejects_pipe

  # execute_plugin tests
  test_execute_plugin_runs_simple_command

  teardown_test

  finish_test_suite "plugin/plugin_executor.sh"
}

# Run tests
main

exit $?
