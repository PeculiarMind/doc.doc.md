#!/bin/bash
# Test suite for FEATURE_0012: activate plugin command
# Run from repository root: bash tests/test_feature_0012.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

PASS=0
FAIL=0
TOTAL=0

cleanup() {
  if [ -n "${TEST_PLUGIN_DIR:-}" ] && [ -d "$TEST_PLUGIN_DIR" ]; then
    rm -rf "$TEST_PLUGIN_DIR"
  fi
  # Restore real plugin descriptors from backup if modified
  for bak in "$PLUGIN_DIR"/*/descriptor.json.bak; do
    [ -f "$bak" ] || continue
    local orig="${bak%.bak}"
    mv "$bak" "$orig"
  done
}
trap cleanup EXIT

# Create a temp plugin dir under the real plugin dir so PLUGIN_DIR resolution works
TEST_PLUGIN_NAME="test_plugin_0012_$$"
TEST_PLUGIN_DIR="$PLUGIN_DIR/$TEST_PLUGIN_NAME"

setup_test_plugin() {
  local active="${1:-false}"
  rm -rf "$TEST_PLUGIN_DIR"
  mkdir -p "$TEST_PLUGIN_DIR"
  cat > "$TEST_PLUGIN_DIR/descriptor.json" <<EOF
{
  "name": "$TEST_PLUGIN_NAME",
  "version": "1.0.0",
  "description": "Test plugin for FEATURE_0012",
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
echo "  FEATURE_0012: activate plugin"
echo "============================================"
echo ""

# =========================================
# Group 1: Happy path - activating inactive plugin
# =========================================
echo "--- Group 1: Happy path ---"

setup_test_plugin "false"
output=$(bash "$CLI" activate --plugin "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "activate inactive plugin exits 0" "0" "$exit_code"
assert_contains "activate prints confirmation" "activated" "$output"

# Verify descriptor was updated
active_val=$(jq -r '.active' "$TEST_PLUGIN_DIR/descriptor.json")
assert_eq "descriptor active is true after activate" "true" "$active_val"

# Short form -p
setup_test_plugin "false"
output=$(bash "$CLI" activate -p "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "activate with -p exits 0" "0" "$exit_code"
active_val=$(jq -r '.active' "$TEST_PLUGIN_DIR/descriptor.json")
assert_eq "descriptor active is true with -p" "true" "$active_val"

# =========================================
# Group 2: Already active
# =========================================
echo ""
echo "--- Group 2: Already active ---"

setup_test_plugin "true"
output=$(bash "$CLI" activate --plugin "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "activate already-active plugin exits 0" "0" "$exit_code"
assert_contains "already active message shown" "already active" "$output"

# =========================================
# Group 3: Error handling
# =========================================
echo ""
echo "--- Group 3: Error handling ---"

output=$(bash "$CLI" activate --plugin "nonexistent_plugin_xyz" 2>&1)
exit_code=$?
assert_exit_code "nonexistent plugin exits non-zero" "1" "$exit_code"
assert_contains "nonexistent plugin error to stderr" "not found" "$output"

# Missing --plugin argument
output=$(bash "$CLI" activate 2>&1)
exit_code=$?
assert_exit_code "missing --plugin exits non-zero" "1" "$exit_code"
assert_contains "missing --plugin prints usage error" "required" "$output"

# =========================================
# Group 4: Help text
# =========================================
echo ""
echo "--- Group 4: Help text ---"

output=$(bash "$CLI" --help 2>&1)
assert_contains "--help includes activate command" "activate" "$output"
assert_contains "--help includes --plugin for activate" "activate --plugin" "$output"

output=$(bash "$CLI" activate --help 2>&1)
exit_code=$?
assert_exit_code "activate --help exits 0" "0" "$exit_code"
assert_contains "activate --help describes command" "--plugin" "$output"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
