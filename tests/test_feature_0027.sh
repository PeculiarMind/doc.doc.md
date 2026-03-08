#!/bin/bash
# Test suite for FEATURE_0027: Move cmd_* functions to component modules
# Run from repository root: bash tests/test_feature_0027.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_MGMT_SH="$REPO_ROOT/doc.doc.md/components/plugin_management.sh"
PLUGIN_EXEC_SH="$REPO_ROOT/doc.doc.md/components/plugin_execution.sh"
DOC_DOC_SH="$REPO_ROOT/doc.doc.sh"

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
echo "  FEATURE_0027: Move cmd_* to Components"
echo "============================================"
echo ""

# =========================================
# Group 1: doc.doc.sh line count
# =========================================
echo "--- Group 1: doc.doc.sh line count <=500 ---"

line_count=$(wc -l < "$DOC_DOC_SH")
TOTAL=$((TOTAL + 1))
if [ "$line_count" -le 500 ]; then
  echo "  PASS: doc.doc.sh has $line_count lines (<=500)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: doc.doc.sh has $line_count lines (must be <=500)"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: cmd_* NOT defined in doc.doc.sh
# =========================================
echo ""
echo "--- Group 2: cmd_* functions NOT in doc.doc.sh ---"

for func in cmd_activate cmd_deactivate cmd_install cmd_installed cmd_list cmd_tree; do
  TOTAL=$((TOTAL + 1))
  if grep -q "^${func}()" "$DOC_DOC_SH" 2>/dev/null; then
    echo "  FAIL: $func should NOT be defined in doc.doc.sh"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $func is NOT defined in doc.doc.sh"
    PASS=$((PASS + 1))
  fi
done

# =========================================
# Group 3: process_file NOT in doc.doc.sh
# =========================================
echo ""
echo "--- Group 3: process_file NOT in doc.doc.sh ---"

TOTAL=$((TOTAL + 1))
if grep -q "^process_file()" "$DOC_DOC_SH" 2>/dev/null; then
  echo "  FAIL: process_file should NOT be defined in doc.doc.sh"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: process_file is NOT defined in doc.doc.sh"
  PASS=$((PASS + 1))
fi

# =========================================
# Group 4: plugin_management.sh CONTAINS cmd_* functions
# =========================================
echo ""
echo "--- Group 4: cmd_* functions defined in plugin_management.sh ---"

for func in cmd_activate cmd_deactivate cmd_install cmd_installed cmd_list cmd_tree; do
  TOTAL=$((TOTAL + 1))
  if grep -q "^${func}()" "$PLUGIN_MGMT_SH" 2>/dev/null; then
    echo "  PASS: $func defined in plugin_management.sh"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $func NOT found in plugin_management.sh"
    FAIL=$((FAIL + 1))
  fi
done

# =========================================
# Group 5: plugin_execution.sh CONTAINS process_file
# =========================================
echo ""
echo "--- Group 5: process_file defined in plugin_execution.sh ---"

TOTAL=$((TOTAL + 1))
if grep -q "^process_file()" "$PLUGIN_EXEC_SH" 2>/dev/null; then
  echo "  PASS: process_file defined in plugin_execution.sh"
  PASS=$((PASS + 1))
else
  echo "  FAIL: process_file NOT found in plugin_execution.sh"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 6: CLI smoke tests — commands still work
# =========================================
echo ""
echo "--- Group 6: CLI smoke tests ---"

# --help still works
help_output=$(bash "$CLI" --help 2>&1)
exit_code=$?
assert_exit_code "--help exits 0" "0" "$exit_code"
assert_contains "--help output mentions 'process'" "process" "$help_output"

# list plugins works
list_output=$(bash "$CLI" list plugins 2>&1)
exit_code=$?
assert_exit_code "list plugins exits 0" "0" "$exit_code"

# tree works
tree_output=$(bash "$CLI" tree 2>&1)
exit_code=$?
assert_exit_code "tree exits 0" "0" "$exit_code"

# process command works
INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
echo "smoke test" > "$INPUT_DIR/smoke.txt"
json_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" 2>/dev/null)
exit_code=$?
assert_exit_code "process exits 0" "0" "$exit_code"
assert_contains "process output has filePath" "filePath" "$json_output"
rm -rf "$INPUT_DIR" "$OUTPUT_DIR"
INPUT_DIR=""
OUTPUT_DIR=""

echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

exit $FAIL
