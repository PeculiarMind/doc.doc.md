#!/bin/bash
# Test suite for FEATURE_0018: List Plugin Parameters
# Run from repository root: bash tests/test_feature_0018.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

PASS=0
FAIL=0
TOTAL=0

cleanup() {
  for name in "${TEST_PLUGINS[@]:-}"; do
    local d="$PLUGIN_DIR/$name"
    [ -d "$d" ] && rm -rf "$d"
  done
}
TEST_PLUGINS=()
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
  local test_name="$1" unexpected="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$unexpected"; then
    echo "  FAIL: $test_name (should NOT contain: $unexpected)"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

echo "============================================"
echo "  FEATURE_0018: List Plugin Parameters"
echo "============================================"
echo ""

# =========================================
# Group 1: list parameters (all plugins)
# =========================================
echo "--- Group 1: list parameters (all plugins) ---"

output=$(bash "$CLI" list parameters 2>&1)
exit_code=$?
assert_exit_code "list parameters exits 0" "0" "$exit_code"

# Should have header row
assert_contains "list parameters has PLUGIN header" "PLUGIN" "$output"
assert_contains "list parameters has COMMAND header" "COMMAND" "$output"
assert_contains "list parameters has DIRECTION header" "DIRECTION" "$output"
assert_contains "list parameters has PARAMETER header" "PARAMETER" "$output"
assert_contains "list parameters has TYPE header" "TYPE" "$output"

# Should contain entries for known plugins
assert_contains "list parameters has file plugin" "file" "$output"
assert_contains "list parameters has filePath param" "filePath" "$output"
assert_contains "list parameters has process command" "process" "$output"
assert_contains "list parameters has input direction" "input" "$output"
assert_contains "list parameters has output direction" "output" "$output"

# =========================================
# Group 2: list --plugin <name> --parameters
# =========================================
echo ""
echo "--- Group 2: list --plugin <name> --parameters ---"

output=$(bash "$CLI" list --plugin file --parameters 2>&1)
exit_code=$?
assert_exit_code "list --plugin file --parameters exits 0" "0" "$exit_code"

# Should have header row (without PLUGIN column)
assert_contains "single plugin header has COMMAND" "COMMAND" "$output"
assert_contains "single plugin header has DIRECTION" "DIRECTION" "$output"
assert_contains "single plugin header has PARAMETER" "PARAMETER" "$output"
assert_not_contains "single plugin header no PLUGIN column" "PLUGIN" "$output"

# file plugin specifics
assert_contains "file: has filePath input" "filePath" "$output"
assert_contains "file: has mimeType output" "mimeType" "$output"
assert_contains "file: shows input direction" "input" "$output"
assert_contains "file: shows output direction" "output" "$output"
assert_contains "file: shows string type" "string" "$output"
assert_contains "file: shows required" "required" "$output"

# =========================================
# Group 3: --parameters without --plugin is an error
# =========================================
echo ""
echo "--- Group 3: --parameters without --plugin ---"

output=$(bash "$CLI" list --parameters 2>&1)
exit_code=$?
assert_exit_code "--parameters without --plugin exits 1" "1" "$exit_code"
assert_contains "--parameters without --plugin shows error" "Error" "$output"

# =========================================
# Group 4: --plugin without --commands or --parameters is an error
# =========================================
echo ""
echo "--- Group 4: --plugin without --commands or --parameters ---"

output=$(bash "$CLI" list --plugin file 2>&1)
exit_code=$?
assert_exit_code "--plugin only exits 1" "1" "$exit_code"
assert_contains "--plugin only shows error" "Error" "$output"

# =========================================
# Group 5: list parameters with extra arg is an error
# =========================================
echo ""
echo "--- Group 5: list parameters extra_arg is an error ---"

output=$(bash "$CLI" list parameters extra_arg 2>&1)
exit_code=$?
assert_exit_code "list parameters extra_arg exits 1" "1" "$exit_code"
assert_contains "list parameters extra_arg shows error" "Error" "$output"

# =========================================
# Group 6: list --plugin <name> --parameters with stat plugin
# =========================================
echo ""
echo "--- Group 6: stat plugin parameters ---"

output=$(bash "$CLI" list --plugin stat --parameters 2>&1)
exit_code=$?
assert_exit_code "list --plugin stat --parameters exits 0" "0" "$exit_code"

assert_contains "stat: has filePath input" "filePath" "$output"
assert_contains "stat: has fileSize output" "fileSize" "$output"
assert_contains "stat: has fileOwner output" "fileOwner" "$output"

# =========================================
# Group 7: list --plugin nonexistent --parameters is an error
# =========================================
echo ""
echo "--- Group 7: nonexistent plugin ---"

output=$(bash "$CLI" list --plugin nonexistent_xyz --parameters 2>&1)
exit_code=$?
assert_exit_code "nonexistent plugin exits 1" "1" "$exit_code"
assert_contains "nonexistent plugin shows error" "Error" "$output"

# =========================================
# Group 8: list parameters shows ocrmypdf
# =========================================
echo ""
echo "--- Group 8: ocrmypdf parameters in list parameters ---"

output=$(bash "$CLI" list parameters 2>&1)
assert_contains "list parameters has ocrmypdf" "ocrmypdf" "$output"
assert_contains "list parameters has mimeType" "mimeType" "$output"
assert_contains "list parameters has ocrText" "ocrText" "$output"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
