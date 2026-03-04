#!/bin/bash
# Test suite for FEATURE_0013: deactivate plugin command
# Run from repository root: bash tests/test_feature_0013.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

PASS=0
FAIL=0
TOTAL=0

TEST_PLUGIN_NAME="test_plugin_0013_$$"
TEST_PLUGIN_DIR="$PLUGIN_DIR/$TEST_PLUGIN_NAME"

cleanup() {
  [ -d "${TEST_PLUGIN_DIR:-}" ] && rm -rf "$TEST_PLUGIN_DIR"
}
trap cleanup EXIT

setup_test_plugin() {
  local active="${1:-true}"
  rm -rf "$TEST_PLUGIN_DIR"
  mkdir -p "$TEST_PLUGIN_DIR"
  cat > "$TEST_PLUGIN_DIR/descriptor.json" <<EOF
{
  "name": "$TEST_PLUGIN_NAME",
  "version": "1.0.0",
  "description": "Test plugin for FEATURE_0013",
  "active": $active,
  "commands": {}
}
EOF
}

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
echo "  FEATURE_0013: deactivate plugin"
echo "============================================"
echo ""

# =========================================
# Group 1: Happy path - deactivating active plugin
# =========================================
echo "--- Group 1: Happy path ---"

setup_test_plugin "true"
output=$(bash "$CLI" deactivate --plugin "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "deactivate active plugin exits 0" "0" "$exit_code"
assert_contains "deactivate prints confirmation" "deactivated" "$output"

active_val=$(jq -r '.active' "$TEST_PLUGIN_DIR/descriptor.json")
assert_eq "descriptor active is false after deactivate" "false" "$active_val"

# Short form -p
setup_test_plugin "true"
output=$(bash "$CLI" deactivate -p "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "deactivate with -p exits 0" "0" "$exit_code"
active_val=$(jq -r '.active' "$TEST_PLUGIN_DIR/descriptor.json")
assert_eq "descriptor active is false with -p" "false" "$active_val"

# =========================================
# Group 2: Already inactive
# =========================================
echo ""
echo "--- Group 2: Already inactive ---"

setup_test_plugin "false"
output=$(bash "$CLI" deactivate --plugin "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "deactivate already-inactive plugin exits 0" "0" "$exit_code"
assert_contains "already inactive message shown" "already inactive" "$output"

# =========================================
# Group 3: Error handling
# =========================================
echo ""
echo "--- Group 3: Error handling ---"

output=$(bash "$CLI" deactivate --plugin "nonexistent_plugin_xyz" 2>&1)
exit_code=$?
assert_exit_code "nonexistent plugin exits non-zero" "1" "$exit_code"
assert_contains "nonexistent plugin error mentions not found" "not found" "$output"

output=$(bash "$CLI" deactivate 2>&1)
exit_code=$?
assert_exit_code "missing --plugin exits non-zero" "1" "$exit_code"
assert_contains "missing --plugin prints usage error" "required" "$output"

# =========================================
# Group 4: Help text
# =========================================
echo ""
echo "--- Group 4: Help text ---"

output=$(bash "$CLI" --help 2>&1)
assert_contains "--help includes deactivate" "deactivate" "$output"

output=$(bash "$CLI" deactivate --help 2>&1)
exit_code=$?
assert_exit_code "deactivate --help exits 0" "0" "$exit_code"
assert_contains "deactivate --help shows --plugin" "--plugin" "$output"

# =========================================
# Group 5: Idempotency (activate then deactivate then deactivate again)
# =========================================
echo ""
echo "--- Group 5: Idempotency ---"

setup_test_plugin "true"
bash "$CLI" deactivate --plugin "$TEST_PLUGIN_NAME" >/dev/null 2>&1
active_val=$(jq -r '.active' "$TEST_PLUGIN_DIR/descriptor.json")
assert_eq "after first deactivate: active=false" "false" "$active_val"

output=$(bash "$CLI" deactivate --plugin "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "second deactivate exits 0" "0" "$exit_code"
assert_contains "second deactivate shows already inactive" "already inactive" "$output"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
