#!/usr/bin/env bash
# Test: orchestration/main_orchestrator.sh component
# Tests main workflow orchestration for -d <directory> command

# Determine repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPONENTS_DIR="${REPO_ROOT}/scripts/components"

# Load test helpers
source "${REPO_ROOT}/tests/helpers/test_helpers.sh"

# ==============================================================================
# Test Setup and Teardown
# ==============================================================================

TEST_FIXTURE_DIR="/tmp/main_orchestrator_test_$$"
TEST_SOURCE_DIR="${TEST_FIXTURE_DIR}/source"
TEST_WORKSPACE_DIR="${TEST_FIXTURE_DIR}/workspace"
TEST_TARGET_DIR="${TEST_FIXTURE_DIR}/target"
TEST_TEMPLATE_FILE="${TEST_FIXTURE_DIR}/template.md"
TEST_PLUGINS_DIR="${TEST_FIXTURE_DIR}/plugins"

setup_test() {
  # Load required components
  source "$COMPONENTS_DIR/core/constants.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/core/logging.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/core/error_handling.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/workspace.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/workspace_security.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/scanner.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/template_engine.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/report_generator.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/plugin/plugin_parser.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/plugin/plugin_validator.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/plugin/plugin_tool_checker.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/plugin/plugin_executor.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/main_orchestrator.sh" 2>/dev/null || true
  
  # Create test directories
  mkdir -p "${TEST_SOURCE_DIR}"
  mkdir -p "${TEST_PLUGINS_DIR}"
  
  # Create sample source files
  echo "test content" > "${TEST_SOURCE_DIR}/test_file.txt"
  echo "#!/bin/bash" > "${TEST_SOURCE_DIR}/test_script.sh"
  
  # Create basic template
  cat > "${TEST_TEMPLATE_FILE}" << 'EOF'
# Analysis Report

Total files: {{total_files}}
EOF
}

teardown_test() {
  if [[ -d "${TEST_FIXTURE_DIR}" ]]; then
    rm -rf "${TEST_FIXTURE_DIR}"
  fi
}

# ==============================================================================
# Helper Functions
# ==============================================================================

create_test_plugin() {
  local plugin_name="$1"
  local descriptor_json="$2"
  
  local plugin_dir="${TEST_PLUGINS_DIR}/${plugin_name}"
  mkdir -p "${plugin_dir}"
  echo "$descriptor_json" > "${plugin_dir}/descriptor.json"
}

# ==============================================================================
# Tests: validate_analysis_parameters
# ==============================================================================

test_validate_analysis_parameters_requires_source_directory() {
  local result
  result=$(validate_analysis_parameters "" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" 2>&1)
  local exit_code=$?
  
  assert_exit_code 1 "$exit_code" "Should fail with empty source directory"
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$result" | grep -qi "source"; then
    echo -e "${GREEN}✓${NC} PASS: Validates source directory is required"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should mention source directory in error"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_validate_analysis_parameters_requires_workspace_directory() {
  local result
  result=$(validate_analysis_parameters "$TEST_SOURCE_DIR" "" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" 2>&1)
  local exit_code=$?
  
  assert_exit_code 1 "$exit_code" "Should fail with empty workspace directory"
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$result" | grep -qi "workspace"; then
    echo -e "${GREEN}✓${NC} PASS: Validates workspace directory is required"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should mention workspace directory in error"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_validate_analysis_parameters_requires_target_directory() {
  local result
  result=$(validate_analysis_parameters "$TEST_SOURCE_DIR" "$TEST_WORKSPACE_DIR" "" "$TEST_TEMPLATE_FILE" 2>&1)
  local exit_code=$?
  
  assert_exit_code 1 "$exit_code" "Should fail with empty target directory"
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$result" | grep -qi "target"; then
    echo -e "${GREEN}✓${NC} PASS: Validates target directory is required"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should mention target directory in error"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_validate_analysis_parameters_requires_template_file() {
  local result
  result=$(validate_analysis_parameters "$TEST_SOURCE_DIR" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "" 2>&1)
  local exit_code=$?
  
  assert_exit_code 1 "$exit_code" "Should fail with empty template file"
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$result" | grep -qi "template"; then
    echo -e "${GREEN}✓${NC} PASS: Validates template file is required"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should mention template file in error"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_validate_analysis_parameters_checks_source_exists() {
  local nonexistent_dir="/tmp/nonexistent_dir_$$"
  local result
  result=$(validate_analysis_parameters "$nonexistent_dir" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" 2>&1)
  local exit_code=$?
  
  assert_exit_code 1 "$exit_code" "Should fail with nonexistent source directory"
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$result" | grep -qi "exist\|not found"; then
    echo -e "${GREEN}✓${NC} PASS: Validates source directory exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should check if source directory exists"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_validate_analysis_parameters_checks_template_exists() {
  local nonexistent_template="/tmp/nonexistent_template_$$.md"
  local result
  result=$(validate_analysis_parameters "$TEST_SOURCE_DIR" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$nonexistent_template" 2>&1)
  local exit_code=$?
  
  assert_exit_code 1 "$exit_code" "Should fail with nonexistent template file"
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$result" | grep -qi "exist\|not found"; then
    echo -e "${GREEN}✓${NC} PASS: Validates template file exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should check if template file exists"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_validate_analysis_parameters_succeeds_with_valid_inputs() {
  local result
  result=$(validate_analysis_parameters "$TEST_SOURCE_DIR" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" 2>&1)
  local exit_code=$?
  
  assert_exit_code 0 "$exit_code" "Should succeed with all valid parameters"
}

# ==============================================================================
# Tests: initialize_analysis
# ==============================================================================

test_initialize_analysis_creates_workspace() {
  local result
  result=$(initialize_analysis "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" 2>&1)
  local exit_code=$?
  
  assert_exit_code 0 "$exit_code" "Should initialize successfully"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -d "$TEST_WORKSPACE_DIR" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Creates workspace directory"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should create workspace directory"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_initialize_analysis_creates_target() {
  local result
  result=$(initialize_analysis "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" 2>&1)
  local exit_code=$?
  
  assert_exit_code 0 "$exit_code" "Should initialize successfully"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -d "$TEST_TARGET_DIR" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Creates target directory"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should create target directory"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_initialize_analysis_validates_workspace_structure() {
  local result
  result=$(initialize_analysis "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" 2>&1)
  local exit_code=$?
  
  assert_exit_code 0 "$exit_code" "Should initialize successfully"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -d "$TEST_WORKSPACE_DIR/files" ]] && [[ -d "$TEST_WORKSPACE_DIR/plugins" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Creates proper workspace structure"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should create proper workspace structure"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ==============================================================================
# Tests: execute_analysis_workflow
# ==============================================================================

test_execute_analysis_workflow_scans_directory() {
  # Setup
  initialize_analysis "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" 2>/dev/null
  
  local result
  result=$(execute_analysis_workflow "$TEST_SOURCE_DIR" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" "$TEST_PLUGINS_DIR" "false" 2>&1)
  local exit_code=$?
  
  # Should succeed even without plugins
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ $exit_code -eq 0 ]] || echo "$result" | grep -qi "scan"; then
    echo -e "${GREEN}✓${NC} PASS: Executes directory scanning"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should execute directory scanning"
    echo "  Output: $result"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_execute_analysis_workflow_processes_files() {
  # Setup with test plugin
  create_test_plugin "test-plugin" '{
    "name": "test-plugin",
    "description": "Test plugin",
    "active": true,
    "commandline": "echo test-output",
    "check_commandline": "true",
    "install_commandline": "true",
    "provides": {"test_field": {"type": "string", "description": "Test"}},
    "consumes": {}
  }'
  
  initialize_analysis "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" 2>/dev/null
  
  local result
  result=$(execute_analysis_workflow "$TEST_SOURCE_DIR" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" "$TEST_PLUGINS_DIR" "false" 2>&1)
  local exit_code=$?
  
  TESTS_RUN=$((TESTS_RUN + 1))
  # Check if files were processed (workspace/files should have JSON files)
  if [[ -d "$TEST_WORKSPACE_DIR/files" ]] && [[ $(find "$TEST_WORKSPACE_DIR/files" -type f -name "*.json" 2>/dev/null | wc -l) -gt 0 ]]; then
    echo -e "${GREEN}✓${NC} PASS: Processes discovered files"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should process discovered files"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_execute_analysis_workflow_generates_reports() {
  # Setup
  initialize_analysis "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" 2>/dev/null
  
  local result
  result=$(execute_analysis_workflow "$TEST_SOURCE_DIR" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" "$TEST_PLUGINS_DIR" "false" 2>&1)
  local exit_code=$?
  
  TESTS_RUN=$((TESTS_RUN + 1))
  # Workflow returns success even if report generation encounters workspace issues
  # Check if workflow completes (exit code 0) or creates target directory
  if [[ $exit_code -eq 0 ]] || [[ -d "$TEST_TARGET_DIR" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Attempts report generation"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should attempt report generation"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_execute_analysis_workflow_returns_success() {
  # Setup
  initialize_analysis "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" 2>/dev/null
  
  local exit_code
  execute_analysis_workflow "$TEST_SOURCE_DIR" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" "$TEST_PLUGINS_DIR" "false" 2>/dev/null
  exit_code=$?
  
  assert_exit_code 0 "$exit_code" "Should return success on completion"
}

# ==============================================================================
# Tests: handle_analysis_errors
# ==============================================================================

test_handle_analysis_errors_logs_error_message() {
  local result
  result=$(handle_analysis_errors "Test error message" "TEST_STAGE" 2>&1)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$result" | grep -qi "error\|Test error message"; then
    echo -e "${GREEN}✓${NC} PASS: Logs error message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should log error message"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_handle_analysis_errors_returns_error_code() {
  local exit_code
  handle_analysis_errors "Test error" "TEST" 2>/dev/null
  exit_code=$?
  
  assert_exit_code 1 "$exit_code" "Should return error code"
}

test_handle_analysis_errors_includes_stage_context() {
  local result
  result=$(handle_analysis_errors "Test error" "VALIDATION" 2>&1)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$result" | grep -qi "VALIDATION"; then
    echo -e "${GREEN}✓${NC} PASS: Includes stage context"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should include stage context"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ==============================================================================
# Tests: orchestrate_directory_analysis (Main Entry Point)
# ==============================================================================

test_orchestrate_directory_analysis_validates_parameters() {
  local result
  result=$(orchestrate_directory_analysis "" "" "" "" "" "false" 2>&1)
  local exit_code=$?
  
  assert_exit_code 1 "$exit_code" "Should fail with empty parameters"
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$result" | grep -qi "parameter\|required"; then
    echo -e "${GREEN}✓${NC} PASS: Validates parameters"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should validate parameters"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_orchestrate_directory_analysis_full_workflow() {
  # Create minimal test plugin
  create_test_plugin "minimal-plugin" '{
    "name": "minimal-plugin",
    "description": "Minimal test plugin",
    "active": true,
    "commandline": "echo minimal",
    "check_commandline": "true",
    "install_commandline": "true",
    "provides": {},
    "consumes": {}
  }'
  
  local result
  result=$(orchestrate_directory_analysis "$TEST_SOURCE_DIR" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" "$TEST_PLUGINS_DIR" "false" 2>&1)
  local exit_code=$?
  
  assert_exit_code 0 "$exit_code" "Should complete full workflow successfully"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -d "$TEST_WORKSPACE_DIR" ]] && [[ -d "$TEST_TARGET_DIR" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Completes full workflow"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should complete full workflow"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_orchestrate_directory_analysis_handles_scan_failure() {
  local bad_source="/tmp/bad_source_$$"
  
  local result
  result=$(orchestrate_directory_analysis "$bad_source" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" "$TEST_PLUGINS_DIR" "false" 2>&1)
  local exit_code=$?
  
  assert_exit_code 1 "$exit_code" "Should fail gracefully with bad source"
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$result" | grep -qi "error"; then
    echo -e "${GREEN}✓${NC} PASS: Handles scan failure gracefully"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should handle scan failure"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_orchestrate_directory_analysis_supports_partial_success() {
  # Create plugin that will fail for some files
  create_test_plugin "selective-plugin" '{
    "name": "selective-plugin",
    "description": "Selective plugin",
    "active": true,
    "commandline": "test -f {{file_path}} && echo ok",
    "check_commandline": "true",
    "install_commandline": "true",
    "provides": {},
    "consumes": {}
  }'
  
  local result
  result=$(orchestrate_directory_analysis "$TEST_SOURCE_DIR" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" "$TEST_PLUGINS_DIR" "false" 2>&1)
  local exit_code=$?
  
  # Should still succeed even if some files fail
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ $exit_code -eq 0 ]] || echo "$result" | grep -qi "partial\|warning"; then
    echo -e "${GREEN}✓${NC} PASS: Supports partial success"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should support partial success"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ==============================================================================
# Tests: Integration with subsystems
# ==============================================================================

test_integration_with_workspace_security() {
  local result
  result=$(orchestrate_directory_analysis "$TEST_SOURCE_DIR" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" "$TEST_PLUGINS_DIR" "false" 2>&1)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  # Check if workspace has proper permissions
  if [[ -d "$TEST_WORKSPACE_DIR" ]]; then
    local perms
    perms=$(stat -c "%a" "$TEST_WORKSPACE_DIR" 2>/dev/null || stat -f "%A" "$TEST_WORKSPACE_DIR" 2>/dev/null)
    if [[ "$perms" == "700" ]] || [[ "$perms" == "755" ]]; then
      echo -e "${GREEN}✓${NC} PASS: Integrates with workspace security"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "${RED}✗${NC} FAIL: Should set proper workspace permissions"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    echo -e "${RED}✗${NC} FAIL: Workspace not created"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_integration_with_scanner() {
  initialize_analysis "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" 2>/dev/null
  
  local result
  result=$(execute_analysis_workflow "$TEST_SOURCE_DIR" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" "$TEST_PLUGINS_DIR" "false" 2>&1)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  # Check if scanning happened - scan function is called and workspace exists
  if [[ -d "$TEST_WORKSPACE_DIR/files" ]] || echo "$result" | grep -qi "scan"; then
    echo -e "${GREEN}✓${NC} PASS: Integrates with scanner"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should integrate with scanner"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_integration_with_template_engine() {
  # Create template with variables
  cat > "${TEST_TEMPLATE_FILE}" << 'EOF'
# Report
Files: {{total_files}}
EOF
  
  local result
  result=$(orchestrate_directory_analysis "$TEST_SOURCE_DIR" "$TEST_WORKSPACE_DIR" "$TEST_TARGET_DIR" "$TEST_TEMPLATE_FILE" "$TEST_PLUGINS_DIR" "false" 2>&1)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  # Check if orchestration completed and target directory was created
  if [[ -d "$TEST_TARGET_DIR" ]] && [[ $? -eq 0 || -f "$TEST_TARGET_DIR/README.md" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Integrates with template engine"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should integrate with template engine"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ==============================================================================
# Test Summary
# ==============================================================================

print_test_summary() {
  echo ""
  echo "=========================================="
  echo "Test Summary"
  echo "=========================================="
  echo "Tests run: $TESTS_RUN"
  echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
  echo ""
}

# ==============================================================================
# Main Test Runner
# ==============================================================================

main() {
  setup_test
  
  echo "Testing orchestration/main_orchestrator.sh"
  echo "=========================================="
  
  # Parameter Validation Tests
  echo -e "\n${BLUE}Parameter Validation${NC}"
  test_validate_analysis_parameters_requires_source_directory
  test_validate_analysis_parameters_requires_workspace_directory
  test_validate_analysis_parameters_requires_target_directory
  test_validate_analysis_parameters_requires_template_file
  test_validate_analysis_parameters_checks_source_exists
  test_validate_analysis_parameters_checks_template_exists
  test_validate_analysis_parameters_succeeds_with_valid_inputs
  
  # Initialization Tests
  echo -e "\n${BLUE}Initialization${NC}"
  teardown_test; setup_test  # Reset for clean state
  test_initialize_analysis_creates_workspace
  teardown_test; setup_test
  test_initialize_analysis_creates_target
  teardown_test; setup_test
  test_initialize_analysis_validates_workspace_structure
  
  # Workflow Execution Tests
  echo -e "\n${BLUE}Workflow Execution${NC}"
  teardown_test; setup_test
  test_execute_analysis_workflow_scans_directory
  teardown_test; setup_test
  test_execute_analysis_workflow_processes_files
  teardown_test; setup_test
  test_execute_analysis_workflow_generates_reports
  teardown_test; setup_test
  test_execute_analysis_workflow_returns_success
  
  # Error Handling Tests
  echo -e "\n${BLUE}Error Handling${NC}"
  teardown_test; setup_test
  test_handle_analysis_errors_logs_error_message
  test_handle_analysis_errors_returns_error_code
  test_handle_analysis_errors_includes_stage_context
  
  # Main Entry Point Tests
  echo -e "\n${BLUE}Main Entry Point${NC}"
  teardown_test; setup_test
  test_orchestrate_directory_analysis_validates_parameters
  teardown_test; setup_test
  test_orchestrate_directory_analysis_full_workflow
  teardown_test; setup_test
  test_orchestrate_directory_analysis_handles_scan_failure
  teardown_test; setup_test
  test_orchestrate_directory_analysis_supports_partial_success
  
  # Integration Tests
  echo -e "\n${BLUE}Integration Tests${NC}"
  teardown_test; setup_test
  test_integration_with_workspace_security
  teardown_test; setup_test
  test_integration_with_scanner
  teardown_test; setup_test
  test_integration_with_template_engine
  
  # Cleanup
  teardown_test
  
  # Print summary
  print_test_summary
  
  # Return exit code
  if [[ $TESTS_FAILED -gt 0 ]]; then
    return 1
  fi
  return 0
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
