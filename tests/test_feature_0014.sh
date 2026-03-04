#!/bin/bash
# Test suite for FEATURE_0014: install single plugin command
# Run from repository root: bash tests/test_feature_0014.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

PASS=0
FAIL=0
TOTAL=0

TEST_PLUGIN_NAME="test_plugin_0014_$$"
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
  "description": "Test plugin for FEATURE_0014",
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

write_install_sh() {
  local exit_code="${1:-0}"
  cat > "$TEST_PLUGIN_DIR/install.sh" <<EOF
#!/bin/bash
echo "install.sh ran"
exit $exit_code
EOF
  chmod +x "$TEST_PLUGIN_DIR/install.sh"
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
echo "  FEATURE_0014: install single plugin"
echo "============================================"
echo ""

# =========================================
# Group 1: Already installed - skip install.sh
# =========================================
echo "--- Group 1: Already installed ---"

setup_test_plugin
write_installed_sh "true"
write_install_sh "0"

output=$(bash "$CLI" install --plugin "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "already installed exits 0" "0" "$exit_code"
assert_contains "already installed message shown" "already installed" "$output"

# install.sh should NOT have run (no "install.sh ran" in output)
TOTAL=$((TOTAL + 1))
if echo "$output" | grep -qF "install.sh ran"; then
  echo "  FAIL: install.sh should not run when already installed"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: install.sh not invoked when already installed"
  PASS=$((PASS + 1))
fi

# =========================================
# Group 2: Not installed - run install.sh
# =========================================
echo ""
echo "--- Group 2: Not installed ---"

setup_test_plugin
write_installed_sh "false"
write_install_sh "0"

output=$(bash "$CLI" install --plugin "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "install runs when not installed exits 0" "0" "$exit_code"
assert_contains "install.sh ran output shown" "install.sh ran" "$output"

# =========================================
# Group 3: No install.sh - informational skip
# =========================================
echo ""
echo "--- Group 3: No install.sh ---"

setup_test_plugin
write_installed_sh "false"
# No install.sh

output=$(bash "$CLI" install --plugin "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "no install.sh exits 0" "0" "$exit_code"
assert_contains "no install.sh shows skip message" "skipping" "$output"

# =========================================
# Group 4: No installed.sh - treat as not installed
# =========================================
echo ""
echo "--- Group 4: No installed.sh ---"

setup_test_plugin
write_install_sh "0"
# No installed.sh

output=$(bash "$CLI" install --plugin "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "no installed.sh: install runs, exits 0" "0" "$exit_code"
assert_contains "no installed.sh: install.sh ran" "install.sh ran" "$output"

# =========================================
# Group 5: Plugin doesn't exist
# =========================================
echo ""
echo "--- Group 5: Plugin not found ---"

output=$(bash "$CLI" install --plugin "nonexistent_xyz" 2>&1)
exit_code=$?
assert_exit_code "nonexistent plugin exits non-zero" "1" "$exit_code"
assert_contains "nonexistent plugin error" "not found" "$output"

# =========================================
# Group 6: Missing --plugin argument
# =========================================
echo ""
echo "--- Group 6: Missing argument ---"

output=$(bash "$CLI" install 2>&1)
exit_code=$?
assert_exit_code "install with no args exits non-zero" "1" "$exit_code"
assert_contains "missing --plugin prints error" "required" "$output"

# =========================================
# Group 7: Short form -p
# =========================================
echo ""
echo "--- Group 7: Short form -p ---"

setup_test_plugin
write_installed_sh "false"
write_install_sh "0"

output=$(bash "$CLI" install -p "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "install -p exits 0" "0" "$exit_code"

# =========================================
# Group 8: Help text
# =========================================
echo ""
echo "--- Group 8: Help text ---"

output=$(bash "$CLI" --help 2>&1)
assert_contains "--help includes install command" "install" "$output"

output=$(bash "$CLI" install --help 2>&1)
exit_code=$?
assert_exit_code "install --help exits 0" "0" "$exit_code"
assert_contains "install --help shows --plugin" "--plugin" "$output"
assert_contains "install --help shows plugins --all" "plugins --all" "$output"

# =========================================
# Group 9: install.sh fails
# =========================================
echo ""
echo "--- Group 9: install.sh failure ---"

setup_test_plugin
write_installed_sh "false"
write_install_sh "1"

output=$(bash "$CLI" install --plugin "$TEST_PLUGIN_NAME" 2>&1)
exit_code=$?
assert_exit_code "failed install.sh exits non-zero" "1" "$exit_code"
assert_contains "failed install shows error" "Error" "$output"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
