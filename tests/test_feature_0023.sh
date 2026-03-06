#!/bin/bash
# Test suite for FEATURE_0023: Orchestration Cleanup
# Run from repository root: bash tests/test_feature_0023.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
COMPONENTS="$REPO_ROOT/doc.doc.md/components"

PASS=0
FAIL=0
TOTAL=0

INPUT_DIR=""
OUTPUT_DIR=""

cleanup() {
  [ -n "$INPUT_DIR" ] && [ -d "$INPUT_DIR" ] && rm -rf "$INPUT_DIR"
  [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ] && rm -rf "$OUTPUT_DIR"
}
trap cleanup EXIT

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
echo "  FEATURE_0023: Orchestration Cleanup"
echo "============================================"
echo ""

# =========================================
# Group 1: All 4 modules sourced
# =========================================
echo "--- Group 1: doc.doc.sh sources all 4 modules ---"

for mod in ui.sh plugin_management.sh plugin_execution.sh templates.sh; do
  TOTAL=$((TOTAL + 1))
  if [ -f "$COMPONENTS/$mod" ]; then
    echo "  PASS: components/$mod exists"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: components/$mod does not exist"
    FAIL=$((FAIL + 1))
  fi
done

# Check all 4 are sourced (check for the module filename in source line or variable declaration)
for mod in ui.sh plugin_management.sh plugin_execution.sh templates.sh; do
  mod_pattern="${mod%.sh}"
  count="$(grep -cE "(source|COMPONENT).*${mod_pattern}" "$CLI" 2>/dev/null)" || count="0"
  TOTAL=$((TOTAL + 1))
  if [ "$count" -gt 0 ]; then
    echo "  PASS: doc.doc.sh references $mod"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: doc.doc.sh does not reference $mod"
    FAIL=$((FAIL + 1))
  fi
done

# =========================================
# Group 2: doc.doc.sh is thin (no inline help, no lifecycle)
# =========================================
echo ""
echo "--- Group 2: doc.doc.sh is reduced to thin dispatcher ---"

# No usage() function definition
usage_def="$(grep -c '^usage()' "$CLI" 2>/dev/null)" || usage_def="0"
assert_eq "no usage() in doc.doc.sh" "0" "$usage_def"

# No cat <<EOF (inline help heredocs)
heredoc_count="$(grep -c 'cat <<EOF' "$CLI" 2>/dev/null)" || heredoc_count="0"
assert_eq "no inline help heredocs in doc.doc.sh" "0" "$heredoc_count"

# No render_template_json (moved to templates.sh)
template_def="$(grep -c '^render_template_json()' "$CLI" 2>/dev/null)" || template_def="0"
assert_eq "no render_template_json() in doc.doc.sh" "0" "$template_def"

# =========================================
# Group 3: All CLI commands work identically
# =========================================
echo ""
echo "--- Group 3: All CLI commands work ---"

# help
help_output=$(bash "$CLI" --help 2>&1)
exit_code=$?
assert_exit_code "--help exits 0" "0" "$exit_code"
assert_contains "help shows Usage" "Usage:" "$help_output"

# list plugins
list_output=$(bash "$CLI" list plugins 2>&1)
exit_code=$?
assert_exit_code "list plugins exits 0" "0" "$exit_code"
assert_contains "list shows stat" "stat" "$list_output"

# activate/deactivate
bash "$CLI" deactivate --plugin stat >/dev/null 2>&1
bash "$CLI" activate --plugin stat >/dev/null 2>&1
act_output=$(bash "$CLI" list plugins active 2>&1)
assert_contains "stat active after activate" "stat" "$act_output"

# install
install_help=$(bash "$CLI" install --help 2>&1)
exit_code=$?
assert_exit_code "install --help exits 0" "0" "$exit_code"

# installed
installed_output=$(bash "$CLI" installed --plugin stat 2>&1)
exit_code=$?
assert_exit_code "installed stat exits 0" "0" "$exit_code"

# tree
tree_output=$(bash "$CLI" tree 2>&1)
exit_code=$?
assert_exit_code "tree exits 0" "0" "$exit_code"

# process
INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
echo "test content" > "$INPUT_DIR/test.txt"
process_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" 2>&1)
exit_code=$?
assert_exit_code "process exits 0" "0" "$exit_code"
assert_contains "process output has filePath" "filePath" "$process_output"

TOTAL=$((TOTAL + 1))
if [ -f "$OUTPUT_DIR/test.txt.md" ]; then
  echo "  PASS: process creates sidecar .md file"
  PASS=$((PASS + 1))
else
  echo "  FAIL: process did not create sidecar .md file"
  FAIL=$((FAIL + 1))
fi

# error handling
err_output=$(bash "$CLI" nonsense 2>&1)
exit_code=$?
assert_exit_code "unknown command exits 1" "1" "$exit_code"
assert_contains "unknown command shows Error" "Error:" "$err_output"

echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

exit $FAIL
