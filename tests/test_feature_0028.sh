#!/bin/bash
# Test suite for FEATURE_0028: plugin_info.py component for tree and table logic
# Run from repository root: bash tests/test_feature_0028.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_MGMT_SH="$REPO_ROOT/doc.doc.md/components/plugin_management.sh"
PLUGIN_INFO_PY="$REPO_ROOT/doc.doc.md/components/plugin_info.py"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

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
    echo "    Actual: $actual"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

assert_true() {
  local test_name="$1" result="$2"
  TOTAL=$((TOTAL + 1))
  if [ "$result" = "0" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    FAIL=$((FAIL + 1))
  fi
}

assert_false() {
  local test_name="$1" result="$2"
  TOTAL=$((TOTAL + 1))
  if [ "$result" != "0" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    FAIL=$((FAIL + 1))
  fi
}

echo "============================================"
echo "  FEATURE_0028: plugin_info.py component"
echo "============================================"
echo ""

# =========================================
# Group 1: plugin_info.py exists
# =========================================
echo "--- Group 1: plugin_info.py exists ---"

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_INFO_PY" ]; then
  echo "  PASS: plugin_info.py exists at $PLUGIN_INFO_PY"
  PASS=$((PASS + 1))
else
  echo "  FAIL: plugin_info.py not found at $PLUGIN_INFO_PY"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if [ -x "$PLUGIN_INFO_PY" ]; then
  echo "  PASS: plugin_info.py is executable"
  PASS=$((PASS + 1))
else
  echo "  FAIL: plugin_info.py is not executable"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: column command no longer in plugin_management.sh
# =========================================
echo ""
echo "--- Group 2: column command removed from plugin_management.sh ---"

TOTAL=$((TOTAL + 1))
if grep -q 'column -t' "$PLUGIN_MGMT_SH"; then
  echo "  FAIL: plugin_management.sh still contains 'column -t'"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: plugin_management.sh does not contain 'column -t'"
  PASS=$((PASS + 1))
fi

# =========================================
# Group 3: doc.doc.sh list parameters still works
# =========================================
echo ""
echo "--- Group 3: list parameters output works ---"

output=$(bash "$CLI" list parameters 2>&1)
exit_code=$?
assert_exit_code "list parameters exits 0" "0" "$exit_code"
assert_contains "list parameters has PLUGIN header" "PLUGIN" "$output"
assert_contains "list parameters has COMMAND header" "COMMAND" "$output"
assert_contains "list parameters has DIRECTION header" "DIRECTION" "$output"
assert_contains "list parameters has file plugin" "file" "$output"
assert_contains "list parameters has process command" "process" "$output"

# =========================================
# Group 4: doc.doc.sh tree still works
# =========================================
echo ""
echo "--- Group 4: tree command still works ---"

output=$(bash "$CLI" tree 2>&1)
exit_code=$?
assert_exit_code "tree exits 0" "0" "$exit_code"
assert_contains "tree shows file plugin" "file" "$output"
assert_contains "tree shows stat plugin" "stat" "$output"
TOTAL=$((TOTAL + 1))
if echo "$output" | grep -qE '(├──|└──)'; then
  echo "  PASS: tree output contains connectors (├── or └──)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: tree output missing connectors"
  echo "    Actual: $output"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 5: list --plugin stat --parameters works
# =========================================
echo ""
echo "--- Group 5: list --plugin stat --parameters ---"

output=$(bash "$CLI" list --plugin stat --parameters 2>&1)
exit_code=$?
assert_exit_code "list --plugin stat --parameters exits 0" "0" "$exit_code"
assert_contains "stat parameters has COMMAND header" "COMMAND" "$output"
assert_contains "stat parameters has DIRECTION header" "DIRECTION" "$output"
assert_contains "stat parameters has PARAMETER header" "PARAMETER" "$output"
assert_contains "stat parameters has filePath" "filePath" "$output"
assert_contains "stat parameters has fileSize" "fileSize" "$output"
assert_not_contains "stat parameters no PLUGIN column" "PLUGIN" "$output"

# =========================================
# Group 6: list --plugin stat --commands works
# =========================================
echo ""
echo "--- Group 6: list --plugin stat --commands ---"

output=$(bash "$CLI" list --plugin stat --commands 2>&1)
exit_code=$?
assert_exit_code "list --plugin stat --commands exits 0" "0" "$exit_code"
assert_contains "stat commands has install" "install" "$output"
assert_contains "stat commands has process" "process" "$output"

# =========================================
# Group 7: plugin_info.py exits non-zero for invalid directory
# =========================================
echo ""
echo "--- Group 7: plugin_info.py error handling ---"

output=$(python3 "$PLUGIN_INFO_PY" tree /nonexistent_path_xyz_abc 2>&1)
exit_code=$?
assert_exit_code "plugin_info.py tree invalid dir exits 1" "1" "$exit_code"
assert_contains "plugin_info.py tree invalid dir error to stderr" "Error" "$(python3 "$PLUGIN_INFO_PY" tree /nonexistent_path_xyz_abc 2>&1 || true)"

# =========================================
# Group 8: plugin_info.py table exits 0 with valid TSV from stdin
# =========================================
echo ""
echo "--- Group 8: plugin_info.py table mode ---"

table_output=$(printf 'PLUGIN\tCOMMAND\tDIRECTION\nfile\tprocess\tinput\n' | python3 "$PLUGIN_INFO_PY" table 2>&1)
exit_code=$?
assert_exit_code "plugin_info.py table exits 0 with valid TSV" "0" "$exit_code"
assert_contains "plugin_info.py table output has PLUGIN" "PLUGIN" "$table_output"
assert_contains "plugin_info.py table output has file" "file" "$table_output"
assert_contains "plugin_info.py table output has process" "process" "$table_output"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
