#!/bin/bash
# Test suite for FEATURE_0038: Per-Command --help and Trimmed Global Help
# Run from repository root: bash tests/test_feature_0038.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
UI_SH="$REPO_ROOT/doc.doc.md/components/ui.sh"

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
    echo "    Actual: $(echo "$actual" | head -5)"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local test_name="$1" unwanted="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$unwanted"; then
    echo "  FAIL: $test_name"
    echo "    Should not contain: $unwanted"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

echo "============================================"
echo "  FEATURE_0038: Per-Command --help"
echo "  and Trimmed Global Help"
echo "============================================"
echo ""

# =========================================
# Group 1: Global --help (trimmed)
# =========================================
echo "--- Group 1: Global --help (trimmed) ---"

global_help=""
exit_code=0
global_help=$(bash "$CLI" --help 2>&1) || exit_code=$?

assert_exit_code "global --help exits 0" "0" "$exit_code"
assert_contains "global help has command list" "Commands:" "$global_help"
assert_contains "global help lists process command" "process" "$global_help"
assert_contains "global help lists setup command" "setup" "$global_help"
assert_contains "global help has examples" "Examples:" "$global_help"
assert_contains "global help footer mentions per-command help" "<command> --help" "$global_help"

# Global help should NOT contain full option blocks for individual commands
assert_not_contains "global help omits process option -d detail" "--input-directory" "$global_help"
assert_not_contains "global help omits --echo option detail" "--echo" "$global_help"

# All examples start with ./
TOTAL=$((TOTAL + 1))
example_lines=$(echo "$global_help" | grep -E '^\s+\./doc\.doc\.sh')
bare_lines=$(echo "$global_help" | grep -E '^\s+doc\.doc\.sh' | grep -v '\./doc\.doc\.sh' | grep -v 'Usage:' | grep -v 'Run ')
if [ -n "$example_lines" ] && [ -z "$bare_lines" ]; then
  echo "  PASS: all global examples start with ./"
  PASS=$((PASS + 1))
else
  echo "  FAIL: some global examples don't start with ./"
  FAIL=$((FAIL + 1))
fi

# -h works same as --help
h_help=""
h_help=$(bash "$CLI" -h 2>&1) || true
assert_eq "global -h matches --help" "$global_help" "$h_help"

# No arguments shows global help
no_args_help=""
no_args_help=$(bash "$CLI" 2>&1) || true
assert_eq "no arguments shows global help" "$global_help" "$no_args_help"

# =========================================
# Group 2: Per-command --help - process
# =========================================
echo ""
echo "--- Group 2: process --help ---"

process_help=""
exit_code=0
process_help=$(bash "$CLI" process --help 2>&1) || exit_code=$?

assert_exit_code "process --help exits 0" "0" "$exit_code"
assert_contains "process help has options" "Options:" "$process_help"
assert_contains "process help has --input-directory" "--input-directory" "$process_help"
assert_contains "process help has --echo" "--echo" "$process_help"
assert_contains "process help has --base-path" "--base-path" "$process_help"
assert_contains "process help has examples" "Examples:" "$process_help"

# =========================================
# Group 3: Per-command --help - list
# =========================================
echo ""
echo "--- Group 3: list --help ---"

list_help=""
exit_code=0
list_help=$(bash "$CLI" list --help 2>&1) || exit_code=$?

assert_exit_code "list --help exits 0" "0" "$exit_code"
assert_contains "list help has usage" "Usage:" "$list_help"
assert_contains "list help has options" "plugins" "$list_help"

# =========================================
# Group 4: Per-command --help - activate, deactivate
# =========================================
echo ""
echo "--- Group 4: activate/deactivate --help ---"

activate_help=""
exit_code=0
activate_help=$(bash "$CLI" activate --help 2>&1) || exit_code=$?
assert_exit_code "activate --help exits 0" "0" "$exit_code"
assert_contains "activate help has --plugin" "--plugin" "$activate_help"

deactivate_help=""
exit_code=0
deactivate_help=$(bash "$CLI" deactivate --help 2>&1) || exit_code=$?
assert_exit_code "deactivate --help exits 0" "0" "$exit_code"
assert_contains "deactivate help has --plugin" "--plugin" "$deactivate_help"

# =========================================
# Group 5: Per-command --help - install, installed
# =========================================
echo ""
echo "--- Group 5: install/installed --help ---"

install_help=""
exit_code=0
install_help=$(bash "$CLI" install --help 2>&1) || exit_code=$?
assert_exit_code "install --help exits 0" "0" "$exit_code"
assert_contains "install help has --plugin" "--plugin" "$install_help"
assert_contains "install help has examples" "Examples:" "$install_help"

installed_help=""
exit_code=0
installed_help=$(bash "$CLI" installed --help 2>&1) || exit_code=$?
assert_exit_code "installed --help exits 0" "0" "$exit_code"
assert_contains "installed help has --plugin" "--plugin" "$installed_help"

# =========================================
# Group 6: Per-command --help - tree, setup
# =========================================
echo ""
echo "--- Group 6: tree/setup --help ---"

tree_help=""
exit_code=0
tree_help=$(bash "$CLI" tree --help 2>&1) || exit_code=$?
assert_exit_code "tree --help exits 0" "0" "$exit_code"
assert_contains "tree help has Usage" "Usage:" "$tree_help"

setup_help=""
exit_code=0
setup_help=$(bash "$CLI" setup --help 2>&1) || exit_code=$?
assert_exit_code "setup --help exits 0" "0" "$exit_code"
assert_contains "setup help has --yes" "--yes" "$setup_help"
assert_contains "setup help has examples" "Examples:" "$setup_help"

# =========================================
# Group 7: --help before argument validation
# =========================================
echo ""
echo "--- Group 7: --help before argument validation ---"

# process --help should work without -d (no spurious error)
exit_code=0
output=$(bash "$CLI" process --help 2>&1) || exit_code=$?
assert_exit_code "process --help works without -d" "0" "$exit_code"
assert_not_contains "no spurious error for missing -d" "Error:" "$output"

# =========================================
# Group 8: Example formatting rule
# =========================================
echo ""
echo "--- Group 8: Example formatting ---"

# Check all per-command help examples start with ./
for cmd in process list activate deactivate install installed tree setup; do
  cmd_output=$(bash "$CLI" "$cmd" --help 2>&1) || true
  TOTAL=$((TOTAL + 1))
  # Check for any bare doc.doc.sh in examples (not preceded by ./)
  if echo "$cmd_output" | grep -E '^\s+doc\.doc\.sh' | grep -v '\./doc\.doc\.sh' | grep -vq 'Usage:\|Run ' 2>/dev/null; then
    echo "  FAIL: $cmd --help has examples without ./ prefix"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $cmd --help examples use ./ prefix"
    PASS=$((PASS + 1))
  fi
done

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed (total: $TOTAL)"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
