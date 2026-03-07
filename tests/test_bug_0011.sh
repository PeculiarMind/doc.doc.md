#!/bin/bash
# Test suite for BUG_0011: Plugin silent skip for unsupported MIME types
# Validates that exit 65 (ADR-004 intentional skip) is handled silently
# Run from repository root: bash tests/test_bug_0011.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_EXEC="$REPO_ROOT/doc.doc.md/components/plugin_execution.sh"

PASS=0
FAIL=0
TOTAL=0

INPUT_DIR=""
OUTPUT_DIR=""

cleanup() {
  [ -n "$INPUT_DIR" ] && [ -d "$INPUT_DIR" ] && rm -rf "$INPUT_DIR"
  [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ] && rm -rf "$OUTPUT_DIR"
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
echo "  BUG_0011: Plugin Silent Skip for"
echo "  Unsupported MIME Types"
echo "============================================"
echo ""

# =========================================
# Group 1: plugin_execution.sh exit code propagation
# =========================================
echo "--- Group 1: run_plugin exit code propagation ---"

# Check that run_plugin propagates exit 65
TOTAL=$((TOTAL + 1))
if grep -q 'return 65' "$PLUGIN_EXEC" 2>/dev/null; then
  echo "  PASS: run_plugin propagates exit 65"
  PASS=$((PASS + 1))
else
  echo "  FAIL: run_plugin does not propagate exit 65"
  FAIL=$((FAIL + 1))
fi

# Check that process_file handles exit 65 as silent skip
TOTAL=$((TOTAL + 1))
if grep -q 'plugin_rc.*-eq 65' "$PLUGIN_EXEC" 2>/dev/null || grep -q '"$plugin_rc" -eq 65' "$PLUGIN_EXEC" 2>/dev/null; then
  echo "  PASS: process_file branches on exit 65"
  PASS=$((PASS + 1))
else
  echo "  FAIL: process_file does not branch on exit 65"
  FAIL=$((FAIL + 1))
fi

# Check the ADR-004 comment is in the header
TOTAL=$((TOTAL + 1))
if grep -q 'ADR-004' "$PLUGIN_EXEC" 2>/dev/null; then
  echo "  PASS: plugin_execution.sh references ADR-004"
  PASS=$((PASS + 1))
else
  echo "  FAIL: plugin_execution.sh does not reference ADR-004"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: Integration test - process with mixed files
# =========================================
echo ""
echo "--- Group 2: Integration - no error for unsupported MIME types ---"

INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)

# Create test files
echo "Hello World" > "$INPUT_DIR/test.txt"
echo "Another file" > "$INPUT_DIR/test2.txt"

# Run process and capture stderr
stderr_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" --no-progress 2>&1 >/dev/null)
exit_code=$?

assert_exit_code "process exits 0 with mixed files" "0" "$exit_code"
assert_not_contains "no 'Plugin.*failed' errors in stderr" "failed for file" "$stderr_output"

# =========================================
# Group 3: file plugin fast-path unaffected
# =========================================
echo ""
echo "--- Group 3: file plugin fast-path unaffected ---"

# The file plugin should still work normally — never exits 65
TOTAL=$((TOTAL + 1))
file_plugin="$REPO_ROOT/doc.doc.md/plugins/file/main.sh"
# Check for actual 'exit 65' statements (not comments about exit 65)
if ! grep -v '^#' "$file_plugin" | grep -q 'exit 65' 2>/dev/null; then
  echo "  PASS: file plugin does not use exit 65 (all MIME types handled)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: file plugin should not use exit 65"
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
