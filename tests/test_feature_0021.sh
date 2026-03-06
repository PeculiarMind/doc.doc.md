#!/bin/bash
# Test suite for FEATURE_0021: Extract Plugin Management Module
# Run from repository root: bash tests/test_feature_0021.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_MGMT="$REPO_ROOT/doc.doc.md/components/plugin_management.sh"

PASS=0
FAIL=0
TOTAL=0

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
echo "  FEATURE_0021: Extract Plugin Management"
echo "============================================"
echo ""

# =========================================
# Group 1: plugin_management.sh exists and is sourced
# =========================================
echo "--- Group 1: plugin_management.sh exists and is sourced ---"

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_MGMT" ]; then
  echo "  PASS: components/plugin_management.sh exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: components/plugin_management.sh does not exist"
  FAIL=$((FAIL + 1))
fi

source_line="$(grep -cE 'source.*(plugin_management\.sh|PLUGIN_MGMT)' "$CLI" 2>/dev/null)" || source_line="0"
TOTAL=$((TOTAL + 1))
if [ "$source_line" -gt 0 ]; then
  echo "  PASS: doc.doc.sh sources plugin_management.sh"
  PASS=$((PASS + 1))
else
  echo "  FAIL: doc.doc.sh does not source plugin_management.sh"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: Management functions present
# =========================================
echo ""
echo "--- Group 2: Management functions present in plugin_management.sh ---"

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_MGMT" ]; then
  has_discover="$(grep -c '^discover_plugins()' "$PLUGIN_MGMT" 2>/dev/null)" || has_discover="0"
  if [ "$has_discover" -gt 0 ]; then
    echo "  PASS: plugin_management.sh contains discover_plugins()"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: plugin_management.sh missing discover_plugins()"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: plugin_management.sh does not exist"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_MGMT" ]; then
  has_discover_all="$(grep -c '^discover_all_plugins()' "$PLUGIN_MGMT" 2>/dev/null)" || has_discover_all="0"
  if [ "$has_discover_all" -gt 0 ]; then
    echo "  PASS: plugin_management.sh contains discover_all_plugins()"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: plugin_management.sh missing discover_all_plugins()"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: plugin_management.sh does not exist"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_MGMT" ]; then
  has_active="$(grep -c '^get_plugin_active_status()' "$PLUGIN_MGMT" 2>/dev/null)" || has_active="0"
  if [ "$has_active" -gt 0 ]; then
    echo "  PASS: plugin_management.sh contains get_plugin_active_status()"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: plugin_management.sh missing get_plugin_active_status()"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: plugin_management.sh does not exist"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 3: No execution logic in plugin_management.sh
# =========================================
echo ""
echo "--- Group 3: No execution logic in plugin_management.sh ---"

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_MGMT" ]; then
  has_run="$(grep -c '^run_plugin()' "$PLUGIN_MGMT" 2>/dev/null)" || has_run="0"
  if [ "$has_run" -eq 0 ]; then
    echo "  PASS: plugin_management.sh has no run_plugin()"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: plugin_management.sh still contains run_plugin()"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: plugin_management.sh does not exist"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 4: Documented public interface
# =========================================
echo ""
echo "--- Group 4: Documented public interface ---"

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_MGMT" ]; then
  header_comment="$(head -5 "$PLUGIN_MGMT" | grep -c '#')" || header_comment="0"
  if [ "$header_comment" -gt 0 ]; then
    echo "  PASS: plugin_management.sh has header comments"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: plugin_management.sh missing header comments"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: plugin_management.sh does not exist"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 5: Management CLI commands still work
# =========================================
echo ""
echo "--- Group 5: Management CLI commands still work ---"

# list plugins
list_output=$(bash "$CLI" list plugins 2>&1)
exit_code=$?
assert_exit_code "list plugins exits 0" "0" "$exit_code"
assert_contains "list plugins shows stat" "stat" "$list_output"
assert_contains "list plugins shows file" "file" "$list_output"

# list plugins active
active_output=$(bash "$CLI" list plugins active 2>&1)
exit_code=$?
assert_exit_code "list plugins active exits 0" "0" "$exit_code"

# activate/deactivate cycle (use stat as test plugin)
bash "$CLI" deactivate --plugin stat 2>&1 >/dev/null
deact_output=$(bash "$CLI" list plugins inactive 2>&1)
assert_contains "stat appears as inactive after deactivate" "stat" "$deact_output"
bash "$CLI" activate --plugin stat 2>&1 >/dev/null
act_output=$(bash "$CLI" list plugins active 2>&1)
assert_contains "stat appears as active after activate" "stat" "$act_output"

# installed check
installed_output=$(bash "$CLI" installed --plugin stat 2>&1)
exit_code=$?
assert_exit_code "installed stat exits 0" "0" "$exit_code"
assert_contains "installed shows stat" "stat" "$installed_output"

# tree
tree_output=$(bash "$CLI" tree 2>&1)
exit_code=$?
assert_exit_code "tree exits 0" "0" "$exit_code"
assert_contains "tree shows stat" "stat" "$tree_output"

echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

exit $FAIL
