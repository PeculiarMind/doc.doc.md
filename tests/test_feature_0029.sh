#!/bin/bash
# Test suite for FEATURE_0029: Move usage/help strings to ui.sh with ui_ prefix
# Run from repository root: bash tests/test_feature_0029.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
UI_SH="$REPO_ROOT/doc.doc.md/components/ui.sh"
DOC_DOC_SH="$REPO_ROOT/doc.doc.sh"

PASS=0
FAIL=0
TOTAL=0

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

separator() { echo; echo "--- $1 ---"; }

# ============================================================
# Group 1: ui_* function definitions exist in ui.sh
# ============================================================
separator "Group 1: ui_* functions defined in ui.sh"

grep -q '^ui_usage()' "$UI_SH"; _rc=$?
assert_true "ui_usage defined in ui.sh" "$_rc"

grep -q '^ui_usage_activate()' "$UI_SH"; _rc=$?
assert_true "ui_usage_activate defined in ui.sh" "$_rc"

grep -q '^ui_usage_deactivate()' "$UI_SH"; _rc=$?
assert_true "ui_usage_deactivate defined in ui.sh" "$_rc"

grep -q '^ui_usage_install()' "$UI_SH"; _rc=$?
assert_true "ui_usage_install defined in ui.sh" "$_rc"

grep -q '^ui_usage_installed()' "$UI_SH"; _rc=$?
assert_true "ui_usage_installed defined in ui.sh" "$_rc"

grep -q '^ui_usage_tree()' "$UI_SH"; _rc=$?
assert_true "ui_usage_tree defined in ui.sh" "$_rc"

# ============================================================
# Group 2: Old bare names NOT directly defined in doc.doc.sh
# ============================================================
separator "Group 2: Old-name functions not defined in doc.doc.sh"

grep -q '^usage()' "$DOC_DOC_SH"; _rc=$?
assert_false "usage() not defined in doc.doc.sh" "$_rc"

grep -q '^usage_activate()' "$DOC_DOC_SH"; _rc=$?
assert_false "usage_activate() not defined in doc.doc.sh" "$_rc"

grep -q '^usage_deactivate()' "$DOC_DOC_SH"; _rc=$?
assert_false "usage_deactivate() not defined in doc.doc.sh" "$_rc"

grep -q '^usage_install()' "$DOC_DOC_SH"; _rc=$?
assert_false "usage_install() not defined in doc.doc.sh" "$_rc"

grep -q '^usage_installed()' "$DOC_DOC_SH"; _rc=$?
assert_false "usage_installed() not defined in doc.doc.sh" "$_rc"

grep -q '^usage_tree()' "$DOC_DOC_SH"; _rc=$?
assert_false "usage_tree() not defined in doc.doc.sh" "$_rc"

# ============================================================
# Group 3: CLI help output still works (backward compatibility)
# ============================================================
separator "Group 3: CLI help output backward compatibility"

out="$(bash "$CLI" --help 2>&1)"
rc=$?
assert_exit_code "--help exits 0" 0 "$rc"
assert_contains "--help output contains 'process'" "process" "$out"
assert_contains "--help output contains 'activate'" "activate" "$out"
assert_contains "--help output contains 'tree'" "tree" "$out"
assert_contains "--help output contains 'install'" "install" "$out"
assert_contains "--help output contains 'installed'" "installed" "$out"

out="$(bash "$CLI" activate --help 2>&1)"
rc=$?
assert_exit_code "activate --help exits 0" 0 "$rc"
assert_contains "activate --help mentions '--plugin'" "--plugin" "$out"

out="$(bash "$CLI" deactivate --help 2>&1)"
rc=$?
assert_exit_code "deactivate --help exits 0" 0 "$rc"
assert_contains "deactivate --help mentions '--plugin'" "--plugin" "$out"

out="$(bash "$CLI" install --help 2>&1)"
rc=$?
assert_exit_code "install --help exits 0" 0 "$rc"
assert_contains "install --help mentions '--plugin'" "--plugin" "$out"

out="$(bash "$CLI" installed --help 2>&1)"
rc=$?
assert_exit_code "installed --help exits 0" 0 "$rc"
assert_contains "installed --help mentions '--plugin'" "--plugin" "$out"

out="$(bash "$CLI" tree --help 2>&1)"
rc=$?
assert_exit_code "tree --help exits 0" 0 "$rc"
assert_contains "tree --help mentions 'dependency'" "dependency" "$out"

# ============================================================
# Group 4: ui_* functions carry inline origin comment
# ============================================================
separator "Group 4: Inline origin comments present in ui.sh"

grep -q 'FEATURE_0029' "$UI_SH"; _rc=$?
assert_true "ui_usage has FEATURE_0029 comment" "$_rc"

echo
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"
echo

[ "$FAIL" -eq 0 ]
