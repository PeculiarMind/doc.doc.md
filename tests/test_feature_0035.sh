#!/bin/bash
# Test suite for FEATURE_0035: file plugin ADR-004 exit code compliance verification
# Validates exit 0/1 and confirms exit 65 is never used
# Run from repository root: bash tests/test_feature_0035.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FILE_PLUGIN="$REPO_ROOT/doc.doc.md/plugins/file/main.sh"

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

echo "============================================"
echo "  FEATURE_0035: file plugin ADR-004"
echo "  Exit Code Compliance Verification"
echo "============================================"
echo ""

# =========================================
# Group 1: Code documentation
# =========================================
echo "--- Group 1: Code documentation ---"

TOTAL=$((TOTAL + 1))
if grep -q 'ADR-004' "$FILE_PLUGIN" 2>/dev/null; then
  echo "  PASS: file/main.sh references ADR-004"
  PASS=$((PASS + 1))
else
  echo "  FAIL: file/main.sh does not reference ADR-004"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if grep -q 'exit 65 not applicable' "$FILE_PLUGIN" 2>/dev/null; then
  echo "  PASS: file/main.sh states exit 65 not applicable"
  PASS=$((PASS + 1))
else
  echo "  FAIL: file/main.sh does not state exit 65 not applicable"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if ! grep -v '^#' "$FILE_PLUGIN" | grep -q 'exit 65' 2>/dev/null; then
  echo "  PASS: file plugin does not use exit 65 (all types handled)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: file plugin should not use exit 65"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: Exit 0 for readable files
# =========================================
echo ""
echo "--- Group 2: Exit 0 for readable files ---"

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

# Test with a text file
echo "Hello World" > "$TEST_DIR/test.txt"
json_input=$(jq -n --arg filePath "$TEST_DIR/test.txt" '{filePath: $filePath}')
stdout_output=$(echo "$json_input" | bash "$FILE_PLUGIN" 2>/dev/null)
exit_code=$?

assert_exit_code "exit 0 for readable text file" "0" "$exit_code"

TOTAL=$((TOTAL + 1))
if echo "$stdout_output" | jq empty 2>/dev/null; then
  echo "  PASS: stdout is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: stdout is not valid JSON"
  FAIL=$((FAIL + 1))
fi

assert_contains "output contains mimeType field" "mimeType" "$stdout_output"

# Test with a binary file
dd if=/dev/zero of="$TEST_DIR/test.bin" bs=64 count=1 2>/dev/null
json_input2=$(jq -n --arg filePath "$TEST_DIR/test.bin" '{filePath: $filePath}')
exit_code2=0
echo "$json_input2" | bash "$FILE_PLUGIN" >/dev/null 2>/dev/null || exit_code2=$?
assert_exit_code "exit 0 for binary file" "0" "$exit_code2"

# =========================================
# Group 3: Exit 1 for error cases
# =========================================
echo ""
echo "--- Group 3: Exit 1 for error cases ---"

# Non-existent file
json_bad=$(jq -n --arg filePath "/tmp/nonexistent_file_test_0035" '{filePath: $filePath}')
exit_code=0
echo "$json_bad" | bash "$FILE_PLUGIN" >/dev/null 2>/dev/null || exit_code=$?
assert_exit_code "exit 1 for non-existent file" "1" "$exit_code"

# Missing filePath
json_empty=$(jq -n '{}')
exit_code=0
echo "$json_empty" | bash "$FILE_PLUGIN" >/dev/null 2>/dev/null || exit_code=$?
assert_exit_code "exit 1 for missing filePath" "1" "$exit_code"

# Restricted path
json_proc=$(jq -n --arg filePath "/proc/1/mem" '{filePath: $filePath}')
exit_code=0
echo "$json_proc" | bash "$FILE_PLUGIN" >/dev/null 2>/dev/null || exit_code=$?
assert_exit_code "exit 1 for restricted path /proc/1/mem" "1" "$exit_code"

# =========================================
# Group 4: Exit 65 never produced
# =========================================
echo ""
echo "--- Group 4: Exit 65 never produced ---"

# Confirm no code path returns 65
TOTAL=$((TOTAL + 1))
# Check non-comment lines only for actual 'exit 65' statements
if ! grep -v '^#' "$FILE_PLUGIN" | grep -q 'exit 65' 2>/dev/null; then
  echo "  PASS: No exit 65 in file plugin source code"
  PASS=$((PASS + 1))
else
  echo "  FAIL: exit 65 found in file plugin source code"
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
