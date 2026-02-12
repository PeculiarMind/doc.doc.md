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

# Unit Tests: User Prompt and Confirmation System
# Tests the prompt system functionality for feature_0018

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/doc.doc.sh"
COMPONENTS_DIR="$PROJECT_ROOT/scripts/components"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Prompt System"

# ============================================================================
# Test 1: prompt_yes_no function exists
# ============================================================================
test_prompt_yes_no_exists() {
  local content

  if [[ -f "$COMPONENTS_DIR/ui/prompt_system.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/ui/prompt_system.sh")
    assert_contains "$content" "prompt_yes_no" "Component should define prompt_yes_no function"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: prompt_system.sh component does not exist"
  fi
}

# ============================================================================
# Test 2: prompt_tool_installation function exists
# ============================================================================
test_prompt_tool_installation_exists() {
  local content

  if [[ -f "$COMPONENTS_DIR/ui/prompt_system.sh" ]]; then
    content=$(cat "$COMPONENTS_DIR/ui/prompt_system.sh")
    assert_contains "$content" "prompt_tool_installation" "Component should define prompt_tool_installation function"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: prompt_system.sh component does not exist"
  fi
}

# ============================================================================
# Test 3: Non-interactive mode returns default (default=n returns 1)
# ============================================================================
test_non_interactive_default_n() {
  if [[ -f "$COMPONENTS_DIR/ui/prompt_system.sh" ]]; then
    local exit_code=0
    (
      IS_INTERACTIVE=false
      unset DOC_DOC_PROMPT_RESPONSE
      source "$COMPONENTS_DIR/core/logging.sh"
      source "$COMPONENTS_DIR/ui/prompt_system.sh"
      prompt_yes_no "Test question?" "n"
    ) 2>/dev/null || exit_code=$?

    assert_equals "1" "$exit_code" "Non-interactive with default=n should return 1 (no)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: prompt_system.sh component does not exist"
  fi
}

# ============================================================================
# Test 4: Non-interactive mode with default=y returns 0
# ============================================================================
test_non_interactive_default_y() {
  if [[ -f "$COMPONENTS_DIR/ui/prompt_system.sh" ]]; then
    local exit_code=0
    (
      IS_INTERACTIVE=false
      unset DOC_DOC_PROMPT_RESPONSE
      source "$COMPONENTS_DIR/core/logging.sh"
      source "$COMPONENTS_DIR/ui/prompt_system.sh"
      prompt_yes_no "Test question?" "y"
    ) 2>/dev/null || exit_code=$?

    assert_equals "0" "$exit_code" "Non-interactive with default=y should return 0 (yes)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: prompt_system.sh component does not exist"
  fi
}

# ============================================================================
# Test 5: DOC_DOC_PROMPT_RESPONSE=y overrides and returns 0
# ============================================================================
test_prompt_response_override_yes() {
  if [[ -f "$COMPONENTS_DIR/ui/prompt_system.sh" ]]; then
    local exit_code=0
    (
      IS_INTERACTIVE=false
      DOC_DOC_PROMPT_RESPONSE=y
      export DOC_DOC_PROMPT_RESPONSE
      source "$COMPONENTS_DIR/core/logging.sh"
      source "$COMPONENTS_DIR/ui/prompt_system.sh"
      prompt_yes_no "Test question?" "n"
    ) 2>/dev/null || exit_code=$?

    assert_equals "0" "$exit_code" "DOC_DOC_PROMPT_RESPONSE=y should return 0 (yes)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: prompt_system.sh component does not exist"
  fi
}

# ============================================================================
# Test 6: DOC_DOC_PROMPT_RESPONSE=n overrides and returns 1
# ============================================================================
test_prompt_response_override_no() {
  if [[ -f "$COMPONENTS_DIR/ui/prompt_system.sh" ]]; then
    local exit_code=0
    (
      IS_INTERACTIVE=false
      DOC_DOC_PROMPT_RESPONSE=n
      export DOC_DOC_PROMPT_RESPONSE
      source "$COMPONENTS_DIR/core/logging.sh"
      source "$COMPONENTS_DIR/ui/prompt_system.sh"
      prompt_yes_no "Test question?" "y"
    ) 2>/dev/null || exit_code=$?

    assert_equals "1" "$exit_code" "DOC_DOC_PROMPT_RESPONSE=n should return 1 (no)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: prompt_system.sh component does not exist"
  fi
}

# ============================================================================
# Test 7: prompt_tool_installation declines in non-interactive mode
# ============================================================================
test_tool_installation_non_interactive_declines() {
  if [[ -f "$COMPONENTS_DIR/ui/prompt_system.sh" ]]; then
    local exit_code=0
    (
      IS_INTERACTIVE=false
      unset DOC_DOC_PROMPT_RESPONSE
      source "$COMPONENTS_DIR/core/logging.sh"
      source "$COMPONENTS_DIR/ui/prompt_system.sh"
      prompt_tool_installation "test-tool" "echo installed"
    ) 2>/dev/null || exit_code=$?

    assert_equals "1" "$exit_code" "Tool installation should decline in non-interactive mode"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: prompt_system.sh component does not exist"
  fi
}

# ============================================================================
# Test 8: Log messages include auto-decision for non-interactive mode
# ============================================================================
test_non_interactive_logs_decision() {
  if [[ -f "$COMPONENTS_DIR/ui/prompt_system.sh" ]]; then
    local output
    output=$(
      IS_INTERACTIVE=false
      unset DOC_DOC_PROMPT_RESPONSE
      source "$COMPONENTS_DIR/core/logging.sh"
      source "$COMPONENTS_DIR/ui/prompt_system.sh"
      prompt_yes_no "Install something?" "n" 2>&1 || true
    )

    assert_contains "$output" "auto-declining" "Log should mention auto-declining in non-interactive mode"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: prompt_system.sh component does not exist"
  fi
}

# ============================================================================
# Test 9: Log messages include auto-accepting for default=y non-interactive
# ============================================================================
test_non_interactive_logs_accept() {
  if [[ -f "$COMPONENTS_DIR/ui/prompt_system.sh" ]]; then
    local output
    output=$(
      IS_INTERACTIVE=false
      unset DOC_DOC_PROMPT_RESPONSE
      source "$COMPONENTS_DIR/core/logging.sh"
      source "$COMPONENTS_DIR/ui/prompt_system.sh"
      prompt_yes_no "Continue?" "y" 2>&1 || true
    )

    assert_contains "$output" "auto-accepting" "Log should mention auto-accepting in non-interactive mode"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: prompt_system.sh component does not exist"
  fi
}

# ============================================================================
# Test 10: DOC_DOC_PROMPT_RESPONSE log messages include override info
# ============================================================================
test_prompt_response_logs_override() {
  if [[ -f "$COMPONENTS_DIR/ui/prompt_system.sh" ]]; then
    local output
    output=$(
      IS_INTERACTIVE=false
      DOC_DOC_PROMPT_RESPONSE=y
      export DOC_DOC_PROMPT_RESPONSE
      source "$COMPONENTS_DIR/core/logging.sh"
      source "$COMPONENTS_DIR/ui/prompt_system.sh"
      prompt_yes_no "Do thing?" "n" 2>&1 || true
    )

    assert_contains "$output" "DOC_DOC_PROMPT_RESPONSE" "Log should mention DOC_DOC_PROMPT_RESPONSE override"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: prompt_system.sh component does not exist"
  fi
}

# ============================================================================
# Test 11: Component is loaded by main script
# ============================================================================
test_component_loaded_in_main_script() {
  local content

  if [[ -f "$SCRIPT_PATH" ]]; then
    content=$(cat "$SCRIPT_PATH")

    if echo "$content" | grep -q "prompt_system.sh"; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Main script should load prompt_system component"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Main script should source prompt_system.sh"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Main script does not exist"
  fi
}

# ============================================================================
# Test 12: Component does NOT use eval (security requirement F4)
# ============================================================================
test_no_eval_used() {
  if [[ -f "$COMPONENTS_DIR/ui/prompt_system.sh" ]]; then
    local content
    content=$(cat "$COMPONENTS_DIR/ui/prompt_system.sh")

    # Check that eval is not used for command execution
    if echo "$content" | grep -qE '^\s*eval\s'; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Component should NOT use eval (security finding F4)"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Component does not use eval for command execution"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: prompt_system.sh component does not exist"
  fi
}

# ============================================================================
# Test 13: IS_INTERACTIVE check is present (mode-aware)
# ============================================================================
test_mode_awareness() {
  if [[ -f "$COMPONENTS_DIR/ui/prompt_system.sh" ]]; then
    local content
    content=$(cat "$COMPONENTS_DIR/ui/prompt_system.sh")
    assert_contains "$content" "IS_INTERACTIVE" "Component should check IS_INTERACTIVE for mode awareness"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: prompt_system.sh component does not exist"
  fi
}

# ============================================================================
# Test 14: Tool installation with DOC_DOC_PROMPT_RESPONSE=y executes command
# ============================================================================
test_tool_installation_with_override_yes() {
  if [[ -f "$COMPONENTS_DIR/ui/prompt_system.sh" ]]; then
    local exit_code=0
    (
      IS_INTERACTIVE=false
      DOC_DOC_PROMPT_RESPONSE=y
      export DOC_DOC_PROMPT_RESPONSE
      source "$COMPONENTS_DIR/core/logging.sh"
      source "$COMPONENTS_DIR/ui/prompt_system.sh"
      prompt_tool_installation "test-tool" "echo success"
    ) 2>/dev/null || exit_code=$?

    assert_equals "0" "$exit_code" "Tool installation should succeed when DOC_DOC_PROMPT_RESPONSE=y and command succeeds"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: prompt_system.sh component does not exist"
  fi
}

# ============================================================================
# Run all tests
# ============================================================================
test_prompt_yes_no_exists
test_prompt_tool_installation_exists
test_non_interactive_default_n
test_non_interactive_default_y
test_prompt_response_override_yes
test_prompt_response_override_no
test_tool_installation_non_interactive_declines
test_non_interactive_logs_decision
test_non_interactive_logs_accept
test_prompt_response_logs_override
test_component_loaded_in_main_script
test_no_eval_used
test_mode_awareness
test_tool_installation_with_override_yes

finish_test_suite "Prompt System"
exit $?
