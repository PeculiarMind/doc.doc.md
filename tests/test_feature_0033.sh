#!/bin/bash
# Test suite for FEATURE_0033: markitdown plugin ADR-004 exit code compliance
# Validates the three-state exit code contract for the markitdown plugin
# Run from repository root: bash tests/test_feature_0033.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MARKITDOWN_SH="$REPO_ROOT/doc.doc.md/plugins/markitdown/main.sh"

PASS=0
FAIL=0
TOTAL=0

cleanup() {
  :
}
trap cleanup EXIT

assert_eq() {
  local test_name="$1" expected="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Expected: $expected"
    echo "    Actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_exit_code() {
  local test_name="$1" expected="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $test_name (exit $actual)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Expected exit: $expected"
    echo "    Actual exit:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local test_name="$1" expected="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$expected"; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Expected to contain: $expected"
    echo "    Actual: $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local test_name="$1" unwanted="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$unwanted"; then
    echo "  FAIL: $test_name"
    echo "    Should not contain: $unwanted"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

echo "============================================"
echo "  FEATURE_0033: markitdown ADR-004"
echo "  Exit Code Compliance"
echo "============================================"
echo ""

# =========================================
# Group 1: Header comment references ADR-004
# =========================================
echo "--- Group 1: Code documentation ---"

TOTAL=$((TOTAL + 1))
if grep -q 'ADR-004' "$MARKITDOWN_SH" 2>/dev/null; then
  echo "  PASS: markitdown/main.sh references ADR-004 in header"
  PASS=$((PASS + 1))
else
  echo "  FAIL: markitdown/main.sh does not reference ADR-004"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if grep -q 'exit 65' "$MARKITDOWN_SH" 2>/dev/null; then
  echo "  PASS: markitdown/main.sh uses exit 65 for unsupported MIME"
  PASS=$((PASS + 1))
else
  echo "  FAIL: markitdown/main.sh does not use exit 65"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if grep -q 'EX_DATAERR' "$MARKITDOWN_SH" 2>/dev/null; then
  echo "  PASS: markitdown/main.sh mentions EX_DATAERR"
  PASS=$((PASS + 1))
else
  echo "  FAIL: markitdown/main.sh does not mention EX_DATAERR"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: Exit 65 for unsupported MIME type
# =========================================
echo ""
echo "--- Group 2: Exit 65 for unsupported MIME type ---"

# Create a temporary test file
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
echo "test content" > "$TEST_DIR/test.txt"

# Test with unsupported MIME type (text/plain is NOT supported by markitdown)
json_input=$(jq -n --arg filePath "$TEST_DIR/test.txt" --arg mimeType "text/plain" '{filePath: $filePath, mimeType: $mimeType}')
stdout_output=$(echo "$json_input" | bash "$MARKITDOWN_SH" 2>/dev/null) || true
exit_code=0
echo "$json_input" | bash "$MARKITDOWN_SH" >/dev/null 2>/dev/null || exit_code=$?

assert_exit_code "exit 65 for unsupported MIME type text/plain" "65" "$exit_code"

# Validate stdout is JSON with message field
TOTAL=$((TOTAL + 1))
if echo "$stdout_output" | jq empty 2>/dev/null; then
  echo "  PASS: stdout is valid JSON for exit 65"
  PASS=$((PASS + 1))
else
  echo "  FAIL: stdout is not valid JSON for exit 65"
  FAIL=$((FAIL + 1))
fi

assert_contains "stdout contains 'message' field" "message" "$stdout_output"
assert_contains "message mentions 'skipped'" "skipped" "$stdout_output"

# Verify nothing on stderr for skip case
stderr_output=$(echo "$json_input" | bash "$MARKITDOWN_SH" 2>&1 >/dev/null) || true
assert_eq "no stderr output for skip case" "" "$stderr_output"

# =========================================
# Group 3: Exit 1 for missing filePath
# =========================================
echo ""
echo "--- Group 3: Exit 1 for error cases ---"

json_input_no_path=$(jq -n '{mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"}')
exit_code=0
echo "$json_input_no_path" | bash "$MARKITDOWN_SH" >/dev/null 2>/dev/null || exit_code=$?
assert_exit_code "exit 1 for missing filePath" "1" "$exit_code"

# Test with non-existent file
json_input_bad=$(jq -n --arg filePath "/tmp/nonexistent_file_for_test.docx" --arg mimeType "application/vnd.openxmlformats-officedocument.wordprocessingml.document" '{filePath: $filePath, mimeType: $mimeType}')
exit_code=0
echo "$json_input_bad" | bash "$MARKITDOWN_SH" >/dev/null 2>/dev/null || exit_code=$?
assert_exit_code "exit 1 for non-existent file" "1" "$exit_code"

# =========================================
# Group 4: No exit codes other than 0, 65, 1
# =========================================
echo ""
echo "--- Group 4: Only exit codes 0, 65, 1 used ---"

TOTAL=$((TOTAL + 1))
# Check that no other exit codes are used (searching for exit N where N is not 0, 1, or 65)
other_exits=$(grep -nE 'exit [0-9]+' "$MARKITDOWN_SH" | grep -vE 'exit (0|1|65)$' | grep -vE 'exit (0|1|65)[^0-9]' || true)
if [ -z "$other_exits" ]; then
  echo "  PASS: No exit codes other than 0, 65, 1"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Found unexpected exit codes: $other_exits"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed (total: $TOTAL)"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
