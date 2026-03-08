#!/bin/bash
# Test suite for FEATURE_0031: Custom base path parameter
# Run from repository root: bash tests/test_feature_0031.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"

PASS=0
FAIL=0
TOTAL=0

INPUT_DIR=""
OUTPUT_DIR=""
BASE_DIR=""

cleanup() {
  [ -n "$INPUT_DIR" ] && [ -d "$INPUT_DIR" ] && rm -rf "$INPUT_DIR"
  [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ] && rm -rf "$OUTPUT_DIR"
  [ -n "$BASE_DIR" ] && [ -d "$BASE_DIR" ] && rm -rf "$BASE_DIR"
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
echo "  FEATURE_0031: Custom Base Path Parameter"
echo "============================================"
echo ""

# =========================================
# Group 1: --base-path flag recognized
# =========================================
echo "--- Group 1: --base-path flag recognized ---"

# --base-path is now in process --help (FEATURE_0038)
help_output=$(bash "$CLI" process --help 2>&1)
assert_contains "--base-path in help text" "--base-path" "$help_output"
assert_contains "-b in help text" "-b" "$help_output"

# =========================================
# Group 2: Without --base-path (backward compat)
# =========================================
echo ""
echo "--- Group 2: Without --base-path (backward compat) ---"

INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
echo "Hello World" > "$INPUT_DIR/test.txt"

bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" --no-progress 2>/dev/null
exit_code=$?
assert_exit_code "process without --base-path exits 0" "0" "$exit_code"

# Check sidecar was created
TOTAL=$((TOTAL + 1))
if [ -f "$OUTPUT_DIR/test.txt.md" ]; then
  echo "  PASS: sidecar file created without --base-path"
  PASS=$((PASS + 1))
else
  echo "  FAIL: sidecar file not created without --base-path"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 3: With --base-path
# =========================================
echo ""
echo "--- Group 3: With --base-path ---"

BASE_DIR=$(mktemp -d)
rm -rf "$OUTPUT_DIR"/*

bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" -b "$BASE_DIR" --no-progress 2>/dev/null
exit_code=$?
assert_exit_code "process with --base-path exits 0" "0" "$exit_code"

# Sidecar should still be created
TOTAL=$((TOTAL + 1))
if [ -f "$OUTPUT_DIR/test.txt.md" ]; then
  echo "  PASS: sidecar file created with --base-path"
  PASS=$((PASS + 1))
else
  echo "  FAIL: sidecar file not created with --base-path"
  FAIL=$((FAIL + 1))
fi

# JSON output should have real path (not base-path rewritten)
json_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" -b "$BASE_DIR" --no-progress 2>/dev/null)
assert_contains "JSON output has real filePath" "$INPUT_DIR" "$json_output"

# =========================================
# Group 4: Invalid --base-path
# =========================================
echo ""
echo "--- Group 4: Invalid --base-path ---"

exit_code=0
error_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" -b "/nonexistent_path_0031" --no-progress 2>&1 >/dev/null) || exit_code=$?
assert_exit_code "invalid --base-path fails" "1" "$exit_code"
assert_contains "error for invalid base-path" "does not exist" "$error_output"

# =========================================
# Group 5: --base-path with --echo
# =========================================
echo ""
echo "--- Group 5: --base-path with --echo ---"

echo_output=$(bash "$CLI" process -d "$INPUT_DIR" --echo -b "$BASE_DIR" --no-progress 2>/dev/null)
exit_code=$?
assert_exit_code "--echo with --base-path exits 0" "0" "$exit_code"
assert_contains "--echo output has content" "test.txt" "$echo_output"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed (total: $TOTAL)"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
