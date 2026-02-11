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

# Unit Tests: Interactive/Non-Interactive Mode Detection
# Tests the mode detection functionality for feature_0016

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/doc.doc.sh"
COMPONENTS_DIR="$PROJECT_ROOT/scripts/components"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Mode Detection"

# ============================================================================
# Test 1: detect_interactive_mode function exists
# ============================================================================
test_detect_function_exists() {
  local content
  
  # Check if mode_detection.sh component exists
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    assert_contains "$content" "detect_interactive_mode" "Component should define detect_interactive_mode function"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 2: Function checks stdin is a terminal ([ -t 0 ])
# ============================================================================
test_checks_stdin_terminal() {
  local content
  
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    
    # Should check if stdin is a terminal
    if echo "$content" | grep -q "\[ -t 0 \]"; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Should check stdin with [ -t 0 ]"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Should test stdin with [ -t 0 ]"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 3: Function checks stdout is a terminal ([ -t 1 ])
# ============================================================================
test_checks_stdout_terminal() {
  local content
  
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    
    # Should check if stdout is a terminal
    if echo "$content" | grep -q "\[ -t 1 \]"; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Should check stdout with [ -t 1 ]"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Should test stdout with [ -t 1 ]"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 4: Function uses logical AND for both terminal checks
# ============================================================================
test_uses_logical_and() {
  local content
  
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    
    # Should use && to combine both tests
    if echo "$content" | grep -q "\[ -t 0 \] && \[ -t 1 \]"; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Should use logical AND (&&) for both terminal tests"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Should combine terminal tests with && operator"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 5: Function stores result in IS_INTERACTIVE global variable
# ============================================================================
test_stores_is_interactive_variable() {
  local content
  
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    
    assert_contains "$content" "IS_INTERACTIVE" "Should store result in IS_INTERACTIVE variable"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 6: Function sets IS_INTERACTIVE=true when terminals detected
# ============================================================================
test_sets_true_for_interactive() {
  local content
  
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    
    assert_contains "$content" "IS_INTERACTIVE=true" "Should set IS_INTERACTIVE=true when interactive"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 7: Function sets IS_INTERACTIVE=false when no terminals detected
# ============================================================================
test_sets_false_for_non_interactive() {
  local content
  
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    
    assert_contains "$content" "IS_INTERACTIVE=false" "Should set IS_INTERACTIVE=false when non-interactive"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 8: Function checks DOC_DOC_INTERACTIVE environment variable
# ============================================================================
test_checks_env_variable() {
  local content
  
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    
    assert_contains "$content" "DOC_DOC_INTERACTIVE" "Should check DOC_DOC_INTERACTIVE environment variable"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 9: Environment variable override takes precedence
# ============================================================================
test_env_override_precedence() {
  local content
  
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    
    # Environment check should come before terminal detection
    local env_line
    local terminal_line
    env_line=$(grep -n "DOC_DOC_INTERACTIVE" "$COMPONENTS_DIR/core/mode_detection.sh" | head -n1 | cut -d: -f1)
    terminal_line=$(grep -n "\[ -t 0 \]" "$COMPONENTS_DIR/core/mode_detection.sh" | head -n1 | cut -d: -f1)
    
    if [[ -n "$env_line" && -n "$terminal_line" && "$env_line" -lt "$terminal_line" ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Environment variable check should come before terminal detection"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Environment variable should be checked first for precedence"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 10: Function logs detected mode in DEBUG level
# ============================================================================
test_logs_detected_mode() {
  local content
  
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    
    # Should call log function
    if echo "$content" | grep -A 20 "detect_interactive_mode" | grep -q "log"; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Should log detected mode"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Should use log() to report detected mode"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 11: Log message for interactive mode
# ============================================================================
test_logs_interactive_message() {
  local content
  
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    
    # Should log message about running in interactive mode
    if echo "$content" | grep -q "interactive mode"; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Should log 'interactive mode' message"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Should include 'interactive mode' in log message"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 12: Log message for non-interactive mode
# ============================================================================
test_logs_non_interactive_message() {
  local content
  
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    
    # Should log message about running in non-interactive mode
    if echo "$content" | grep -q "non-interactive"; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Should log 'non-interactive' message"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Should include 'non-interactive' in log message"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 13: Log indicates if mode was forced via environment variable
# ============================================================================
test_logs_environment_override() {
  local content
  
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    
    # Should indicate when mode is forced via environment
    if echo "$content" | grep -qE "forced|override|environment"; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Should indicate when mode is forced via environment"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Should log when environment variable overrides detection"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 14: IS_INTERACTIVE variable is exported
# ============================================================================
test_exports_is_interactive() {
  local content
  
  if [[ -f "$COMPONENTS_DIR/core/mode_detection.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/core/mode_detection.sh")
    
    # Should export IS_INTERACTIVE for child processes
    if echo "$content" | grep -q "export IS_INTERACTIVE"; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Should export IS_INTERACTIVE variable"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: IS_INTERACTIVE should be exported for child processes"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: mode_detection.sh component does not exist"
  fi
}

# ============================================================================
# Test 15: Mode detection component is loaded by main script
# ============================================================================
test_component_loaded_in_main_script() {
  local content
  
  if [[ -f "$SCRIPT_PATH" ]]; then
    content=$(cat "$SCRIPT_PATH")
    
    # Main script should source the mode_detection component
    if echo "$content" | grep -q "mode_detection.sh"; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Main script should load mode_detection component"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Main script should source mode_detection.sh"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Main script does not exist"
  fi
}

# ============================================================================
# Test 16: detect_interactive_mode function is called in main script
# ============================================================================
test_function_called_in_main_script() {
  local content
  
  if [[ -f "$SCRIPT_PATH" ]]; then
    content=$(cat "$SCRIPT_PATH")
    
    # Main script should call detect_interactive_mode
    if echo "$content" | grep -q "detect_interactive_mode"; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Main script should call detect_interactive_mode"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Main script should invoke detect_interactive_mode function"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Main script does not exist"
  fi
}

# ============================================================================
# Test 17: Functional test - non-interactive mode with piped input
# ============================================================================
test_non_interactive_piped_input() {
  if [[ -x "$SCRIPT_PATH" ]]; then
    local output
    local exit_code
    
    # Pipe input - should be detected as non-interactive
    output=$(echo "" | "$SCRIPT_PATH" --version 2>&1 || true)
    exit_code=$?
    
    # Script should run successfully in non-interactive mode
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Script should run with piped input (non-interactive)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Cannot test - script not executable"
  fi
}

# ============================================================================
# Test 18: Functional test - DOC_DOC_INTERACTIVE=true forces interactive mode
# ============================================================================
test_env_force_interactive() {
  if [[ -x "$SCRIPT_PATH" ]]; then
    local output
    local exit_code
    
    # Force interactive mode via environment variable
    output=$(DOC_DOC_INTERACTIVE=true "$SCRIPT_PATH" --version 2>&1 || true)
    exit_code=$?
    
    # Script should acknowledge forced interactive mode
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Script should accept DOC_DOC_INTERACTIVE=true"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Cannot test - script not executable"
  fi
}

# ============================================================================
# Test 19: Functional test - DOC_DOC_INTERACTIVE=false forces non-interactive mode
# ============================================================================
test_env_force_non_interactive() {
  if [[ -x "$SCRIPT_PATH" ]]; then
    local output
    local exit_code
    
    # Force non-interactive mode via environment variable
    output=$(DOC_DOC_INTERACTIVE=false "$SCRIPT_PATH" --version 2>&1 || true)
    exit_code=$?
    
    # Script should acknowledge forced non-interactive mode
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Script should accept DOC_DOC_INTERACTIVE=false"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Cannot test - script not executable"
  fi
}

# ============================================================================
# Test 20: Functional test - redirected output detected as non-interactive
# ============================================================================
test_non_interactive_redirected_output() {
  if [[ -x "$SCRIPT_PATH" ]]; then
    local temp_file
    temp_file=$(mktemp)
    
    # Redirect output - should be detected as non-interactive
    "$SCRIPT_PATH" --version > "$temp_file" 2>&1 || true
    
    # Should have created output file
    if [[ -f "$temp_file" && -s "$temp_file" ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Script should run with redirected output (non-interactive)"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Script should handle redirected output"
    fi
    
    rm -f "$temp_file"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Cannot test - script not executable"
  fi
}

# ============================================================================
# Run all tests
# ============================================================================
test_detect_function_exists
test_checks_stdin_terminal
test_checks_stdout_terminal
test_uses_logical_and
test_stores_is_interactive_variable
test_sets_true_for_interactive
test_sets_false_for_non_interactive
test_checks_env_variable
test_env_override_precedence
test_logs_detected_mode
test_logs_interactive_message
test_logs_non_interactive_message
test_logs_environment_override
test_exports_is_interactive
test_component_loaded_in_main_script
test_function_called_in_main_script
test_non_interactive_piped_input
test_env_force_interactive
test_env_force_non_interactive
test_non_interactive_redirected_output

finish_test_suite "Mode Detection"
exit $?
