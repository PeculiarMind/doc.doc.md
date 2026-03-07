#!/bin/bash
# Test suite for FEATURE_0024: Process --echo dry-run output mode
# Run from repository root: bash tests/test_feature_0024.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"

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
    echo "    Actual: $(echo "$actual" | head -5)"
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
echo "  FEATURE_0024: Process --echo Dry-Run"
echo "============================================"
echo ""

# =========================================
# Group 1: --echo flag recognized
# =========================================
echo "--- Group 1: --echo flag recognized ---"

# Check help text mentions --echo
help_output=$(bash "$CLI" --help 2>&1)
assert_contains "--echo in help text" "--echo" "$help_output"

# =========================================
# Group 2: --echo prints rendered markdown to stdout
# =========================================
echo ""
echo "--- Group 2: --echo prints rendered markdown to stdout ---"

INPUT_DIR=$(mktemp -d)
echo "Hello World" > "$INPUT_DIR/test.txt"

output=$(bash "$CLI" process -d "$INPUT_DIR" --echo --no-progress 2>/dev/null)
exit_code=$?

assert_exit_code "--echo exits 0" "0" "$exit_code"
assert_contains "--echo output contains file delimiter" "===" "$output"
assert_contains "--echo output contains filename" "test.txt" "$output"

# =========================================
# Group 3: --echo does not write files
# =========================================
echo ""
echo "--- Group 3: --echo does not write files ---"

# Verify no output directory was created
TOTAL=$((TOTAL + 1))
if [ ! -d "$INPUT_DIR/output" ]; then
  echo "  PASS: --echo does not create output directory"
  PASS=$((PASS + 1))
else
  echo "  FAIL: --echo created an output directory"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 4: --echo and -o are mutually exclusive
# =========================================
echo ""
echo "--- Group 4: --echo and -o mutual exclusivity ---"

OUTPUT_DIR=$(mktemp -d)
exit_code=0
error_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" --echo 2>&1 >/dev/null) || exit_code=$?

assert_exit_code "--echo and -o fails" "1" "$exit_code"
assert_contains "error message for mutual exclusivity" "mutually exclusive" "$error_output"

# =========================================
# Group 5: Multiple files with delimiters
# =========================================
echo ""
echo "--- Group 5: Multiple files with delimiters ---"

echo "Second file" > "$INPUT_DIR/test2.txt"
output=$(bash "$CLI" process -d "$INPUT_DIR" --echo --no-progress 2>/dev/null)

# Count delimiters
delimiter_count=$(echo "$output" | grep -c '===' || true)
TOTAL=$((TOTAL + 1))
if [ "$delimiter_count" -ge 2 ]; then
  echo "  PASS: Multiple files have delimiters ($delimiter_count)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Expected at least 2 delimiters, got $delimiter_count"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 6: --echo works with --template
# =========================================
echo ""
echo "--- Group 6: --echo works with existing flags ---"

# Use existing default template
output=$(bash "$CLI" process -d "$INPUT_DIR" --echo --no-progress 2>/dev/null)
exit_code=$?
assert_exit_code "--echo with default template exits 0" "0" "$exit_code"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed (total: $TOTAL)"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
