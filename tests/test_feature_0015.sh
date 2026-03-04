#!/bin/bash
# Test suite for FEATURE_0015: installed check command
# Run from repository root: bash tests/test_feature_0015.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

PASS=0
FAIL=0
TOTAL=0

TEST_PLUGIN_NAME="test_plugin_0015_$$"
TEST_PLUGIN_DIR="$PLUGIN_DIR/$TEST_PLUGIN_NAME"

cleanup() {
  [ -d "${TEST_PLUGIN_DIR:-}" ] && rm -rf "$TEST_PLUGIN_DIR"
}
trap cleanup EXIT

setup_test_plugin() {
  rm -rf "$TEST_PLUGIN_DIR"
  mkdir -p "$TEST_PLUGIN_DIR"
  cat > "$TEST_PLUGIN_DIR/descriptor.json" <<EOF
{
  "name": "$TEST_PLUGIN_NAME",
  "version": "1.0.0",
  "description": "Test plugin for FEATURE_0015",
  "active": true,
  "commands": {}
}
EOF
}

write_installed_sh() {
  local installed_val="$1"  # "true" or "false"
  cat > "$TEST_PLUGIN_DIR/installed.sh" <<EOF
#!/bin/bash
jq -n --argjson v $installed_val '{installed: \$v}'
exit 0
EOF
  chmod +x "$TEST_PLUGIN_DIR/installed.sh"
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
echo "  FEATURE_0015: installed check command"
echo "============================================"
echo ""

# =========================================
# Group 1: Plugin is installed
# =========================================
echo "--- Group 1: Plugin installed ---"

setup_test_plugin
write_installed_sh "true"

output=$(bash "$CLI" installed --plugin "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "installed plugin exits 0" "0" "$exit_code"
assert_contains "installed output says installed" "installed" "$output"

# Short form -p
output=$(bash "$CLI" installed -p "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "installed -p exits 0" "0" "$exit_code"

# =========================================
# Group 2: Plugin is not installed
# =========================================
echo ""
echo "--- Group 2: Plugin not installed ---"

setup_test_plugin
write_installed_sh "false"

output=$(bash "$CLI" installed --plugin "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "not installed exits 1" "1" "$exit_code"
assert_contains "not installed output says not installed" "not installed" "$output"

# =========================================
# Group 3: No installed.sh
# =========================================
echo ""
echo "--- Group 3: No installed.sh ---"

setup_test_plugin
# No installed.sh

output=$(bash "$CLI" installed --plugin "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "no installed.sh exits 1" "1" "$exit_code"
assert_contains "no installed.sh: informational message" "no installed.sh" "$output"

# =========================================
# Group 4: Plugin doesn't exist
# =========================================
echo ""
echo "--- Group 4: Plugin not found ---"

output=$(bash "$CLI" installed --plugin "nonexistent_xyz_$$" 2>&1)
exit_code=$?
# exit code should be distinct from "not installed" (1); spec says 2 for "error"
assert_exit_code "nonexistent plugin exits 2" "2" "$exit_code"
assert_contains "nonexistent plugin error message" "not found" "$output"

# =========================================
# Group 5: Missing --plugin argument
# =========================================
echo ""
echo "--- Group 5: Missing argument ---"

output=$(bash "$CLI" installed 2>&1)
exit_code=$?
assert_exit_code "installed no args exits 2" "2" "$exit_code"
assert_contains "missing --plugin prints error" "required" "$output"

# =========================================
# Group 6: Help text
# =========================================
echo ""
echo "--- Group 6: Help text ---"

output=$(bash "$CLI" --help 2>&1)
assert_contains "--help includes installed command" "installed" "$output"

output=$(bash "$CLI" installed --help 2>&1)
exit_code=$?
assert_exit_code "installed --help exits 0" "0" "$exit_code"
assert_contains "installed --help describes command" "--plugin" "$output"

# =========================================
# Group 7: Real plugins check
# =========================================
echo ""
echo "--- Group 7: Real plugins ---"

# 'stat' should be installed (stat command is always available)
output=$(bash "$CLI" installed --plugin stat 2>&1)
exit_code=$?
assert_exit_code "stat plugin installed check exits 0" "0" "$exit_code"
assert_contains "stat installed output" "installed" "$output"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
