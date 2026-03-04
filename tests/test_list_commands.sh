#!/bin/bash
# Test suite for doc.doc.sh list command surface (FEATURE_0008)
# Run from repository root: bash tests/test_list_commands.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOC_DOC_SH="$REPO_ROOT/doc.doc.sh"

PASS=0
FAIL=0
TOTAL=0

# ---------------------------------------------------------------------------
# Test helper functions
# ---------------------------------------------------------------------------

assert_eq() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
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
  local test_name="$1"
  local expected="$2"
  local actual="$3"
  TOTAL=$((TOTAL + 1))
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $test_name (exit code $actual)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Expected exit code: $expected"
    echo "    Actual exit code:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
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
  local test_name="$1"
  local not_expected="$2"
  local actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$not_expected"; then
    echo "  FAIL: $test_name"
    echo "    Expected NOT to contain: $not_expected"
    echo "    Actual: $actual"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

# ---------------------------------------------------------------------------

echo "============================================"
echo "  FEATURE_0008 list command Test Suite"
echo "============================================"
echo ""

# ===========================================================================
# Group 1: list --plugin <name> --commands  (ALREADY IMPLEMENTED)
# ===========================================================================
echo "--- Group 1: list --plugin <name> --commands (implemented) ---"
echo ""

echo "--- Group 1a: list --plugin stat --commands ---"

output=$("$DOC_DOC_SH" list --plugin stat --commands 2>&1)
exit_code=$?
assert_exit_code "stat --commands exits 0" "0" "$exit_code"
assert_contains "stat --commands contains 'install'" "install" "$output"
assert_contains "stat --commands contains 'installed'" "installed" "$output"
assert_contains "stat --commands contains 'process'" "process" "$output"

echo ""
echo "--- Group 1b: list --plugin file --commands ---"

output=$("$DOC_DOC_SH" list --plugin file --commands 2>&1)
exit_code=$?
assert_exit_code "file --commands exits 0" "0" "$exit_code"
assert_contains "file --commands contains 'install'" "install" "$output"
assert_contains "file --commands contains 'installed'" "installed" "$output"
assert_contains "file --commands contains 'process'" "process" "$output"

echo ""
echo "--- Group 1c: alphabetical sort ---"

output=$("$DOC_DOC_SH" list --plugin stat --commands 2>&1)
sorted_commands=$(echo "$output" | awk 'NF>0 {print $1}' | sort)
actual_commands=$(echo "$output" | awk 'NF>0 {print $1}')
assert_eq "stat --commands output is alphabetically sorted" "$sorted_commands" "$actual_commands"

echo ""
echo "--- Group 1d: --commands without --plugin exits 1 ---"

output=$("$DOC_DOC_SH" list --commands 2>&1)
exit_code=$?
assert_exit_code "--commands without --plugin exits 1" "1" "$exit_code"
assert_contains "--commands without --plugin shows error" "Error" "$output"

echo ""
echo "--- Group 1e: --plugin stat without --commands exits 1 ---"

output=$("$DOC_DOC_SH" list --plugin stat 2>&1)
exit_code=$?
assert_exit_code "--plugin without --commands exits 1" "1" "$exit_code"
assert_contains "--plugin without --commands shows error" "Error" "$output"

echo ""
echo "--- Group 1f: --plugin nonexistent --commands exits 1 ---"

output=$("$DOC_DOC_SH" list --plugin nonexistent --commands 2>&1)
exit_code=$?
assert_exit_code "--plugin nonexistent --commands exits 1" "1" "$exit_code"
assert_contains "--plugin nonexistent --commands shows error" "Error" "$output"

echo ""

# ===========================================================================
# Group 2: list plugins  (FEATURE_0008 — not yet implemented)
# ===========================================================================
echo "--- Group 2: list plugins (FEATURE_0008 — not yet implemented) ---"
echo ""

output=$("$DOC_DOC_SH" list plugins 2>&1)
exit_code=$?
assert_exit_code "list plugins exits 0" "0" "$exit_code"
assert_contains "list plugins output includes 'stat'" "stat" "$output"
assert_contains "list plugins output includes 'file'" "file" "$output"
assert_contains "list plugins shows activation status" "active" "$output"

echo ""

# ===========================================================================
# Group 3: list plugins active  (FEATURE_0008 — not yet implemented)
# ===========================================================================
echo "--- Group 3: list plugins active (FEATURE_0008 — not yet implemented) ---"
echo ""

output=$("$DOC_DOC_SH" list plugins active 2>&1)
exit_code=$?
assert_exit_code "list plugins active exits 0" "0" "$exit_code"
assert_contains "list plugins active includes 'stat'" "stat" "$output"
assert_contains "list plugins active includes 'file'" "file" "$output"

echo ""

# ===========================================================================
# Group 4: list plugins inactive  (FEATURE_0008 — not yet implemented)
# ===========================================================================
echo "--- Group 4: list plugins inactive (FEATURE_0008 — not yet implemented) ---"
echo ""

output=$("$DOC_DOC_SH" list plugins inactive 2>&1)
exit_code=$?
assert_exit_code "list plugins inactive exits 0" "0" "$exit_code"
assert_not_contains "list plugins inactive does NOT include 'stat' (stat is active)" "stat" "$output"
assert_not_contains "list plugins inactive does NOT include 'file' (file is active)" "file" "$output"

echo ""

# ===========================================================================
# Group 5: Error handling (mix)
# ===========================================================================
echo "--- Group 5: Error handling ---"
echo ""

echo "--- Group 5a: list plugins unknown_arg exits 1 ---"

output=$("$DOC_DOC_SH" list plugins unknown_arg 2>&1)
exit_code=$?
assert_exit_code "list plugins unknown_arg exits 1" "1" "$exit_code"
assert_contains "list plugins unknown_arg shows error" "Error" "$output"

echo ""
echo "--- Group 5b: list with no arguments ---"

output=$("$DOC_DOC_SH" list 2>&1)
exit_code=$?
assert_exit_code "list with no arguments exits 1" "1" "$exit_code"

echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
