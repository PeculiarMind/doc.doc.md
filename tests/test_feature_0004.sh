#!/bin/bash
# Test suite for FEATURE_0004: list --plugin <name> --commands
# Run from repository root: bash tests/test_feature_0004.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOC_DOC_SH="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

PASS=0
FAIL=0
TOTAL=0

# ---- Cleanup ----

cleanup() {
  if [ -n "${TMP_PLUGIN_DIR:-}" ] && [ -d "$TMP_PLUGIN_DIR" ]; then
    rm -rf "$TMP_PLUGIN_DIR"
  fi
}
trap cleanup EXIT

# ---- Helpers ----

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

echo "============================================"
echo "  FEATURE_0004 Test Suite"
echo "============================================"
echo ""

# =========================================
# Help / usage
# =========================================
echo "--- help output documents list command ---"

output=$("$DOC_DOC_SH" --help 2>&1)
exit_code=$?
assert_exit_code "--help exits with 0" "0" "$exit_code"
assert_contains "--help documents list command" "list" "$output"
assert_contains "--help documents --plugin flag" "--plugin" "$output"
assert_contains "--help documents --commands flag" "--commands" "$output"

echo ""

# =========================================
# Command parsing: valid combinations
# =========================================
echo "--- list --plugin stat --commands ---"

output=$("$DOC_DOC_SH" list --plugin stat --commands 2>&1)
exit_code=$?
assert_exit_code "list --plugin stat --commands exits with 0" "0" "$exit_code"

echo ""
echo "--- list --commands --plugin stat (reverse order) ---"

output=$("$DOC_DOC_SH" list --commands --plugin stat 2>&1)
exit_code=$?
assert_exit_code "list --commands --plugin stat exits with 0" "0" "$exit_code"

echo ""

# =========================================
# Output format
# =========================================
echo "--- output format ---"

output=$("$DOC_DOC_SH" list --plugin stat --commands 2>/dev/null)

# Each line should contain a tab-separated name and description
assert_contains "output contains 'install'" "install" "$output"
assert_contains "output contains 'installed'" "installed" "$output"
assert_contains "output contains 'process'" "process" "$output"

# Verify sorted alphabetically: install < installed < process
line1=$(echo "$output" | sed -n '1p')
line2=$(echo "$output" | sed -n '2p')
line3=$(echo "$output" | sed -n '3p')
assert_contains "first line is 'install'" "install" "$line1"
assert_contains "second line is 'installed'" "installed" "$line2"
assert_contains "third line is 'process'" "process" "$line3"

# Verify tab-separated format
TOTAL=$((TOTAL + 1))
if echo "$line1" | grep -qP '^\S+\t\S+'; then
  echo "  PASS: output lines use tab separator"
  PASS=$((PASS + 1))
else
  # fallback: grep without -P
  if echo "$line1" | grep -q $'\t'; then
    echo "  PASS: output lines use tab separator"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: output lines do not use tab separator"
    echo "    Line1: $line1"
    FAIL=$((FAIL + 1))
  fi
fi

# Output goes to stdout (exit 0 means stdout captured correctly)
stdout_output=$("$DOC_DOC_SH" list --plugin stat --commands)
exit_code=$?
assert_exit_code "output to stdout, exit 0" "0" "$exit_code"
assert_contains "stdout contains install" "install" "$stdout_output"

echo ""

# =========================================
# file plugin output
# =========================================
echo "--- list --plugin file --commands ---"

output=$("$DOC_DOC_SH" list --plugin file --commands 2>/dev/null)
exit_code=$?
assert_exit_code "list --plugin file --commands exits with 0" "0" "$exit_code"
assert_contains "file plugin output contains 'process'" "process" "$output"
assert_contains "file plugin output contains 'install'" "install" "$output"
assert_contains "file plugin output contains 'installed'" "installed" "$output"

echo ""

# =========================================
# Error cases
# =========================================
echo "--- error: --plugin without --commands ---"

output=$("$DOC_DOC_SH" list --plugin stat 2>&1)
exit_code=$?
assert_exit_code "--plugin without --commands exits with 1" "1" "$exit_code"
assert_contains "--plugin without --commands shows error" "Error" "$output"

echo ""
echo "--- error: --commands without --plugin ---"

output=$("$DOC_DOC_SH" list --commands 2>&1)
exit_code=$?
assert_exit_code "--commands without --plugin exits with 1" "1" "$exit_code"
assert_contains "--commands without --plugin shows error" "Error" "$output"

echo ""
echo "--- error: unknown plugin ---"

output=$("$DOC_DOC_SH" list --plugin nonexistent_plugin --commands 2>&1)
exit_code=$?
assert_exit_code "unknown plugin exits with 1" "1" "$exit_code"
assert_contains "unknown plugin shows error" "Error" "$output"

echo ""
echo "--- error: missing descriptor.json ---"

# Create a plugin dir without a descriptor
TMP_PLUGIN_DIR=$(mktemp -d)
mkdir -p "$TMP_PLUGIN_DIR/testplugin"
# Override PLUGIN_DIR by setting env and calling with a modified script is complex;
# instead test by temporarily placing the plugin in the real dir with no descriptor
REAL_PLUGIN_DIR="$PLUGIN_DIR"
mkdir -p "$REAL_PLUGIN_DIR/testplugin_nodesc"
output=$("$DOC_DOC_SH" list --plugin testplugin_nodesc --commands 2>&1)
exit_code=$?
rmdir "$REAL_PLUGIN_DIR/testplugin_nodesc"
assert_exit_code "missing descriptor exits with 1" "1" "$exit_code"
assert_contains "missing descriptor shows error" "Error" "$output"

echo ""
echo "--- error: invalid JSON descriptor ---"

# Create a plugin dir with an invalid descriptor
mkdir -p "$REAL_PLUGIN_DIR/testplugin_badjson"
echo "not valid json" > "$REAL_PLUGIN_DIR/testplugin_badjson/descriptor.json"
output=$("$DOC_DOC_SH" list --plugin testplugin_badjson --commands 2>&1)
exit_code=$?
rm -rf "$REAL_PLUGIN_DIR/testplugin_badjson"
assert_exit_code "invalid JSON descriptor exits with 1" "1" "$exit_code"
assert_contains "invalid JSON descriptor shows error" "Error" "$output"

echo ""

# Summary
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
