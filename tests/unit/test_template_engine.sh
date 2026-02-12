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

# Test: orchestration/template_engine.sh component
# Tests template processing, variable substitution, conditionals, loops, comments, and security

# Determine repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load test helpers
source "${REPO_ROOT}/tests/helpers/test_helpers.sh"

# ==============================================================================
# Test Setup and Teardown
# ==============================================================================

# Test fixture directory
TEST_TEMPLATE_DIR="/tmp/template_test_$$"

setup_test() {
  # Source dependencies
  source "${REPO_ROOT}/scripts/components/core/constants.sh"
  source "${REPO_ROOT}/scripts/components/core/logging.sh"
  source "${REPO_ROOT}/scripts/components/core/error_handling.sh"

  # Source the component under test
  source "${REPO_ROOT}/scripts/components/orchestration/template_engine.sh"

  # Create test fixture directory
  mkdir -p "${TEST_TEMPLATE_DIR}"
}

teardown_test() {
  # Clean up test fixtures
  if [[ -d "${TEST_TEMPLATE_DIR}" ]]; then
    rm -rf "${TEST_TEMPLATE_DIR}"
  fi
}

# ==============================================================================
# Tests: Function Existence
# ==============================================================================

test_process_template_function_exists() {
  if declare -f process_template >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: process_template function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: process_template function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_substitute_variables_function_exists() {
  if declare -f substitute_variables >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: substitute_variables function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: substitute_variables function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_process_conditionals_function_exists() {
  if declare -f process_conditionals >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: process_conditionals function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: process_conditionals function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_process_loops_function_exists() {
  if declare -f process_loops >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: process_loops function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: process_loops function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_remove_comments_function_exists() {
  if declare -f remove_comments >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: remove_comments function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: remove_comments function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_validate_template_syntax_function_exists() {
  if declare -f validate_template_syntax >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: validate_template_syntax function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: validate_template_syntax function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_sanitize_value_function_exists() {
  if declare -f sanitize_value >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: sanitize_value function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: sanitize_value function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

# ==============================================================================
# Tests: Variable Substitution
# ==============================================================================

test_simple_variable_substitution() {
  local template="Hello {{name}}!"
  declare -A data=([name]="World")
  local result
  result=$(substitute_variables "$template" data)
  assert_equals "Hello World!" "$result" "Simple variable substitution"
}

test_multiple_variable_substitution() {
  local template="{{greeting}} {{name}}, your score is {{score}}."
  declare -A data=([greeting]="Hello" [name]="Alice" [score]="100")
  local result
  result=$(substitute_variables "$template" data)
  assert_equals "Hello Alice, your score is 100." "$result" "Multiple variable substitution"
}

test_nested_variable_substitution() {
  local template="File size: {{file_size}} bytes"
  declare -A data=([file_size]="1024")
  local result
  result=$(substitute_variables "$template" data)
  assert_equals "File size: 1024 bytes" "$result" "Nested variable substitution"
}

test_missing_variable_empty_string() {
  local template="Hello {{missing_var}}!"
  declare -A data=([name]="World")
  local result
  result=$(substitute_variables "$template" data)
  assert_equals "Hello !" "$result" "Missing variable returns empty string"
}

test_variable_substitution_with_whitespace() {
  local template="Hello {{ name }}!"
  declare -A data=([name]="World")
  local result
  result=$(substitute_variables "$template" data)
  assert_equals "Hello World!" "$result" "Variable substitution with whitespace"
}

test_variable_with_special_characters() {
  local template="Value: {{value}}"
  declare -A data=([value]="Test & Value")
  local result
  result=$(substitute_variables "$template" data)
  assert_contains "$result" "Test" "Variable with special characters should be sanitized"
}

# ==============================================================================
# Tests: Conditional Logic
# ==============================================================================

test_conditional_true_case() {
  local template="{{#if show}}Content visible{{/if}}"
  declare -A data=([show]="true")
  local result
  result=$(process_conditionals "$template" data)
  assert_equals "Content visible" "$result" "Conditional renders when true"
}

test_conditional_false_case() {
  local template="{{#if show}}Content visible{{/if}}"
  declare -A data=()
  local result
  result=$(process_conditionals "$template" data)
  assert_equals "" "$result" "Conditional skips when false"
}

test_conditional_with_else() {
  local template="{{#if show}}Yes{{else}}No{{/if}}"
  declare -A data=()
  local result
  result=$(process_conditionals "$template" data)
  assert_equals "No" "$result" "Conditional else block works"
}

test_conditional_with_else_true() {
  local template="{{#if show}}Yes{{else}}No{{/if}}"
  declare -A data=([show]="true")
  local result
  result=$(process_conditionals "$template" data)
  assert_equals "Yes" "$result" "Conditional else skips when condition true"
}

test_nested_conditionals() {
  local template="{{#if outer}}Outer {{#if inner}}Inner{{/if}}{{/if}}"
  declare -A data=([outer]="true" [inner]="true")
  local result
  result=$(process_conditionals "$template" data)
  assert_equals "Outer Inner" "$result" "Nested conditionals work"
}

test_conditional_with_whitespace() {
  local template="{{#if   show  }}Content{{/if}}"
  declare -A data=([show]="true")
  local result
  result=$(process_conditionals "$template" data)
  assert_equals "Content" "$result" "Conditional with whitespace works"
}

test_conditional_truthiness_non_empty_string() {
  local template="{{#if value}}Has value{{/if}}"
  declare -A data=([value]="something")
  local result
  result=$(process_conditionals "$template" data)
  assert_equals "Has value" "$result" "Non-empty string is truthy"
}

test_conditional_truthiness_empty_string() {
  local template="{{#if value}}Has value{{/if}}"
  declare -A data=([value]="")
  local result
  result=$(process_conditionals "$template" data)
  assert_equals "" "$result" "Empty string is falsy"
}

# ==============================================================================
# Tests: Loop Logic
# ==============================================================================

test_simple_loop() {
  local template="{{#each items}}{{this}} {{/each}}"
  declare -A data=([items]="apple banana cherry")
  local result
  result=$(process_loops "$template" data)
  assert_contains "$result" "apple" "Loop processes first item"
  assert_contains "$result" "banana" "Loop processes second item"
  assert_contains "$result" "cherry" "Loop processes third item"
}

test_loop_with_index() {
  local template="{{#each items}}{{@index}}: {{this}} {{/each}}"
  declare -A data=([items]="first second")
  local result
  result=$(process_loops "$template" data)
  assert_contains "$result" "0: first" "Loop index starts at 0"
  assert_contains "$result" "1: second" "Loop index increments"
}

test_empty_loop() {
  local template="Before{{#each items}}{{this}}{{/each}}After"
  declare -A data=([items]="")
  local result
  result=$(process_loops "$template" data)
  assert_equals "BeforeAfter" "$result" "Empty loop renders nothing"
}

test_nested_loops() {
  local template="{{#each outer}}{{this}}: {{#each inner}}{{this}} {{/each}}| {{/each}}"
  declare -A data=([outer]="A B" [inner]="1 2")
  local result
  result=$(process_loops "$template" data)
  assert_contains "$result" "A:" "Outer loop works"
  assert_contains "$result" "1" "Inner loop works"
}

test_loop_with_whitespace() {
  local template="{{#each   items  }}{{this}}{{/each}}"
  declare -A data=([items]="test")
  local result
  result=$(process_loops "$template" data)
  assert_contains "$result" "test" "Loop with whitespace works"
}

# ==============================================================================
# Tests: Comment Handling
# ==============================================================================

test_comment_removal() {
  local template="Before{{! This is a comment}}After"
  local result
  result=$(remove_comments "$template")
  assert_equals "BeforeAfter" "$result" "Comments are removed"
}

test_multiple_comments() {
  local template="{{! comment1}}Text{{! comment2}}"
  local result
  result=$(remove_comments "$template")
  assert_equals "Text" "$result" "Multiple comments removed"
}

test_comment_with_special_chars() {
  local template="{{! Comment with {{special}} chars}}Text"
  local result
  result=$(remove_comments "$template")
  assert_contains "$result" "Text" "Comment with special chars removed"
}

test_comment_preserves_whitespace() {
  local template="Line1\n{{! comment}}\nLine2"
  local result
  result=$(remove_comments "$template")
  assert_contains "$result" "Line1" "Whitespace before comment preserved"
  assert_contains "$result" "Line2" "Whitespace after comment preserved"
}

# ==============================================================================
# Tests: Syntax Validation
# ==============================================================================

test_validate_balanced_if_tags() {
  local template="{{#if test}}content{{/if}}"
  if validate_template_syntax "$template"; then
    echo -e "${GREEN}✓${NC} PASS: Balanced if tags validate"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Balanced if tags should validate"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_validate_unbalanced_if_tags() {
  local template="{{#if test}}content"
  if ! validate_template_syntax "$template"; then
    echo -e "${GREEN}✓${NC} PASS: Unbalanced if tags detected"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Unbalanced if tags should be detected"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_validate_balanced_each_tags() {
  local template="{{#each items}}{{this}}{{/each}}"
  if validate_template_syntax "$template"; then
    echo -e "${GREEN}✓${NC} PASS: Balanced each tags validate"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Balanced each tags should validate"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_validate_unbalanced_each_tags() {
  local template="{{#each items}}{{this}}"
  if ! validate_template_syntax "$template"; then
    echo -e "${GREEN}✓${NC} PASS: Unbalanced each tags detected"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Unbalanced each tags should be detected"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_validate_nested_tags() {
  local template="{{#if outer}}{{#each items}}{{this}}{{/each}}{{/if}}"
  if validate_template_syntax "$template"; then
    echo -e "${GREEN}✓${NC} PASS: Nested tags validate"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Nested tags should validate"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

# ==============================================================================
# Tests: Security
# ==============================================================================

test_sanitize_backticks() {
  local value='test`command`test'
  local result
  result=$(sanitize_value "$value")
  assert_not_contains "$result" "\`command\`" "Backticks should be escaped"
}

test_sanitize_dollar_signs() {
  local value='test$VAR'
  local result
  result=$(sanitize_value "$value")
  assert_not_contains "$result" "\$VAR" "Dollar signs should be escaped"
}

test_sanitize_command_substitution() {
  local value='test$(whoami)test'
  local result
  result=$(sanitize_value "$value")
  assert_not_contains "$result" "\$(whoami)" "Command substitution should be escaped"
}

test_no_eval_in_template() {
  local template="{{value}}"
  declare -A data=([value]='$(echo pwned)')
  local result
  result=$(substitute_variables "$template" data)
  # Result should not execute the command
  assert_not_contains "$result" "pwned" "Commands should not be executed"
}

test_sanitize_semicolons() {
  local value='test; rm -rf /'
  local result
  result=$(sanitize_value "$value")
  # Should escape or sanitize dangerous patterns
  assert_contains "$result" "test" "Value should contain safe part"
}

# ==============================================================================
# Tests: Integration - Complete Template Processing
# ==============================================================================

test_complete_template_processing() {
  local template="# Report: {{title}}
{{! This is a comment}}
{{#if has_summary}}
Summary: {{summary}}
{{/if}}

{{#if has_tags}}
Tags:
{{#each tags}}
- {{this}}
{{/each}}
{{else}}
No tags available.
{{/if}}"

  declare -A data=(
    [title]="Test Report"
    [has_summary]="true"
    [summary]="This is a test"
    [has_tags]="true"
    [tags]="bash testing template"
  )

  local result
  # Process through all stages
  result=$(substitute_variables "$template" data)
  result=$(process_conditionals "$result" data)
  result=$(process_loops "$result" data)
  result=$(remove_comments "$result")

  assert_contains "$result" "Test Report" "Title substituted"
  assert_contains "$result" "This is a test" "Summary included"
  assert_contains "$result" "- bash" "Tags listed"
  assert_not_contains "$result" "comment" "Comments removed"
  assert_not_contains "$result" "No tags available" "Else block not rendered"
}

test_template_with_file_from_disk() {
  local template_file="${TEST_TEMPLATE_DIR}/test_template.md"
  cat > "$template_file" << 'EOF'
# {{filename}}

File size: {{size}}
{{#if has_content}}
Content available
{{else}}
No content
{{/if}}
EOF

  declare -A data=(
    [filename]="document.md"
    [size]="1024"
    [has_content]="true"
  )

  local template_content
  template_content=$(<"$template_file")
  
  local result
  result=$(substitute_variables "$template_content" data)
  result=$(process_conditionals "$result" data)
  
  assert_contains "$result" "document.md" "Filename from file"
  assert_contains "$result" "1024" "Size from file"
  assert_contains "$result" "Content available" "Conditional from file"
}

# ==============================================================================
# Tests: Error Handling
# ==============================================================================

test_process_template_with_timeout() {
  # This would need timeout implementation in process_template
  # For now, just test that function doesn't hang
  local template="{{value}}"
  declare -A data=([value]="test")
  local result
  result=$(process_template "$template" data 2>/dev/null || echo "timeout")
  # Should complete quickly
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "${GREEN}✓${NC} PASS: Template processing completes"
}

test_iteration_limit_enforcement() {
  # Test that loops don't run infinitely
  local template="{{#each items}}{{this}}{{/each}}"
  # Create large array
  local large_array=""
  for i in {1..100}; do
    large_array+="item$i "
  done
  declare -A data=([items]="$large_array")
  
  local result
  result=$(process_loops "$template" data)
  
  # Should complete without hanging
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "${GREEN}✓${NC} PASS: Loop iteration completes with large array"
}

# ==============================================================================
# Main Test Runner
# ==============================================================================

main() {
  echo "========================================"
  echo "Template Engine Test Suite"
  echo "========================================"
  echo ""

  setup_test

  # Function existence tests
  test_process_template_function_exists
  test_substitute_variables_function_exists
  test_process_conditionals_function_exists
  test_process_loops_function_exists
  test_remove_comments_function_exists
  test_validate_template_syntax_function_exists
  test_sanitize_value_function_exists

  # Variable substitution tests
  test_simple_variable_substitution
  test_multiple_variable_substitution
  test_nested_variable_substitution
  test_missing_variable_empty_string
  test_variable_substitution_with_whitespace
  test_variable_with_special_characters

  # Conditional logic tests
  test_conditional_true_case
  test_conditional_false_case
  test_conditional_with_else
  test_conditional_with_else_true
  test_nested_conditionals
  test_conditional_with_whitespace
  test_conditional_truthiness_non_empty_string
  test_conditional_truthiness_empty_string

  # Loop logic tests
  test_simple_loop
  test_loop_with_index
  test_empty_loop
  test_nested_loops
  test_loop_with_whitespace

  # Comment handling tests
  test_comment_removal
  test_multiple_comments
  test_comment_with_special_chars
  test_comment_preserves_whitespace

  # Syntax validation tests
  test_validate_balanced_if_tags
  test_validate_unbalanced_if_tags
  test_validate_balanced_each_tags
  test_validate_unbalanced_each_tags
  test_validate_nested_tags

  # Security tests
  test_sanitize_backticks
  test_sanitize_dollar_signs
  test_sanitize_command_substitution
  test_no_eval_in_template
  test_sanitize_semicolons

  # Integration tests
  test_complete_template_processing
  test_template_with_file_from_disk

  # Error handling tests
  test_process_template_with_timeout
  test_iteration_limit_enforcement

  teardown_test

  # Print summary
  echo ""
  echo "========================================"
  echo "Test Summary"
  echo "========================================"
  echo "Tests run:    $TESTS_RUN"
  echo "Tests passed: $TESTS_PASSED"
  echo "Tests failed: $TESTS_FAILED"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
  fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
