#!/bin/bash
# Test suite for FEATURE_0011: install all plugins command
# Run from repository root: bash tests/test_feature_0011.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

PASS=0
FAIL=0
TOTAL=0

TEST_PLUGIN_A="test_plugin_0011a_$$"
TEST_PLUGIN_B="test_plugin_0011b_$$"
TEST_PLUGIN_C="test_plugin_0011c_$$"

cleanup() {
  for name in "$TEST_PLUGIN_A" "$TEST_PLUGIN_B" "$TEST_PLUGIN_C"; do
    local d="$PLUGIN_DIR/$name"
    [ -d "$d" ] && rm -rf "$d"
  done
}
trap cleanup EXIT

make_plugin() {
  local name="$1"
  local dir="$PLUGIN_DIR/$name"
  rm -rf "$dir"
  mkdir -p "$dir"
  cat > "$dir/descriptor.json" <<EOF
{
  "name": "$name",
  "version": "1.0.0",
  "description": "Test plugin $name",
  "active": true,
  "commands": {}
}
EOF
}

write_installed_sh() {
  local name="$1" val="$2"
  local dir="$PLUGIN_DIR/$name"
  cat > "$dir/installed.sh" <<EOF
#!/bin/bash
jq -n --argjson v $val '{installed: \$v}'
exit 0
EOF
  chmod +x "$dir/installed.sh"
}

write_install_sh() {
  local name="$1" exit_code="${2:-0}"
  local dir="$PLUGIN_DIR/$name"
  cat > "$dir/install.sh" <<EOF
#!/bin/bash
echo "install.sh ran for $name"
exit $exit_code
EOF
  chmod +x "$dir/install.sh"
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
echo "  FEATURE_0011: install all plugins"
echo "============================================"
echo ""

# =========================================
# Group 1: All already installed
# =========================================
echo "--- Group 1: All already installed ---"

make_plugin "$TEST_PLUGIN_A"
write_installed_sh "$TEST_PLUGIN_A" "true"
write_install_sh "$TEST_PLUGIN_A" "0"

output=$(bash "$CLI" install plugins --all 2>&1)
exit_code=$?
assert_exit_code "all already installed exits 0" "0" "$exit_code"
assert_contains "shows already installed for plugin A" "already installed" "$output"
assert_not_contains "does not run install.sh for already installed" \
  "install.sh ran for $TEST_PLUGIN_A" "$output"

# =========================================
# Group 2: One plugin needs installing
# =========================================
echo ""
echo "--- Group 2: Install needed ---"

make_plugin "$TEST_PLUGIN_B"
write_installed_sh "$TEST_PLUGIN_B" "false"
write_install_sh "$TEST_PLUGIN_B" "0"

output=$(bash "$CLI" install plugins --all 2>&1)
exit_code=$?
assert_exit_code "install needed exits 0" "0" "$exit_code"
assert_contains "install.sh ran for plugin B" "install.sh ran for $TEST_PLUGIN_B" "$output"

# =========================================
# Group 3: No install.sh - skip with message
# =========================================
echo ""
echo "--- Group 3: No install.sh ---"

make_plugin "$TEST_PLUGIN_C"
write_installed_sh "$TEST_PLUGIN_C" "false"
# No install.sh for C

output=$(bash "$CLI" install plugins --all 2>&1)
exit_code=$?
assert_exit_code "no install.sh exits 0" "0" "$exit_code"
assert_contains "no install.sh shows skip message" "skipping" "$output"

# =========================================
# Group 4: No installed.sh - treat as not installed
# =========================================
echo ""
echo "--- Group 4: No installed.sh ---"

# Reuse plugin C (no installed.sh), give it install.sh
write_install_sh "$TEST_PLUGIN_C" "0"
rm -f "$PLUGIN_DIR/$TEST_PLUGIN_C/installed.sh"

output=$(bash "$CLI" install plugins --all 2>&1)
exit_code=$?
assert_exit_code "no installed.sh: install runs, exits 0" "0" "$exit_code"
assert_contains "no installed.sh: install.sh ran" "install.sh ran for $TEST_PLUGIN_C" "$output"

# =========================================
# Group 5: Partial failure - continue with others
# =========================================
echo ""
echo "--- Group 5: Partial failure ---"

# Plugin B fails to install
write_installed_sh "$TEST_PLUGIN_B" "false"
write_install_sh "$TEST_PLUGIN_B" "1"

# Plugin C succeeds
write_installed_sh "$TEST_PLUGIN_C" "false"
write_install_sh "$TEST_PLUGIN_C" "0"

output=$(bash "$CLI" install plugins --all 2>&1)
exit_code=$?
assert_exit_code "partial failure exits non-zero" "1" "$exit_code"
assert_contains "partial failure: C still ran" "install.sh ran for $TEST_PLUGIN_C" "$output"
assert_contains "partial failure: error reported for B" "Error" "$output"

# =========================================
# Group 6: Help text
# =========================================
echo ""
echo "--- Group 6: Help text ---"

output=$(bash "$CLI" --help 2>&1)
# install plugins --all now in install --help (FEATURE_0038)
install_help=$(bash "$CLI" install --help 2>&1)
assert_contains "install --help includes install plugins --all" "install plugins --all" "$install_help"

output=$(bash "$CLI" install --help 2>&1)
assert_exit_code "install --help exits 0" "0" "$?"
assert_contains "install --help mentions plugins --all" "plugins --all" "$output"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
