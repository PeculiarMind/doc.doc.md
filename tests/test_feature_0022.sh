#!/bin/bash
# Test suite for FEATURE_0022: Extract Plugin Execution Module
# Run from repository root: bash tests/test_feature_0022.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_EXEC="$REPO_ROOT/doc.doc.md/components/plugin_execution.sh"

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
echo "  FEATURE_0022: Extract Plugin Execution"
echo "============================================"
echo ""

# =========================================
# Group 1: plugin_execution.sh exists and is sourced
# =========================================
echo "--- Group 1: plugin_execution.sh exists and is sourced ---"

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_EXEC" ]; then
  echo "  PASS: components/plugin_execution.sh exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: components/plugin_execution.sh does not exist"
  FAIL=$((FAIL + 1))
fi

source_line="$(grep -cE 'source.*(plugin_execution\.sh|PLUGIN_EXEC)' "$CLI" 2>/dev/null)" || source_line="0"
TOTAL=$((TOTAL + 1))
if [ "$source_line" -gt 0 ]; then
  echo "  PASS: doc.doc.sh sources plugin_execution.sh"
  PASS=$((PASS + 1))
else
  echo "  FAIL: doc.doc.sh does not source plugin_execution.sh"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: Execution function present
# =========================================
echo ""
echo "--- Group 2: Execution function present in plugin_execution.sh ---"

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_EXEC" ]; then
  has_run="$(grep -c '^run_plugin()' "$PLUGIN_EXEC" 2>/dev/null)" || has_run="0"
  if [ "$has_run" -gt 0 ]; then
    echo "  PASS: plugin_execution.sh contains run_plugin()"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: plugin_execution.sh missing run_plugin()"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: plugin_execution.sh does not exist"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 3: No management logic in plugin_execution.sh
# =========================================
echo ""
echo "--- Group 3: No management logic in plugin_execution.sh ---"

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_EXEC" ]; then
  has_discover="$(grep -c '^discover_plugins()' "$PLUGIN_EXEC" 2>/dev/null)" || has_discover="0"
  if [ "$has_discover" -eq 0 ]; then
    echo "  PASS: plugin_execution.sh has no discover_plugins()"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: plugin_execution.sh still contains discover_plugins()"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: plugin_execution.sh does not exist"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_EXEC" ]; then
  has_active="$(grep -c '^get_plugin_active_status()' "$PLUGIN_EXEC" 2>/dev/null)" || has_active="0"
  if [ "$has_active" -eq 0 ]; then
    echo "  PASS: plugin_execution.sh has no get_plugin_active_status()"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: plugin_execution.sh still contains get_plugin_active_status()"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: plugin_execution.sh does not exist"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 4: Documented public interface
# =========================================
echo ""
echo "--- Group 4: Documented public interface ---"

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_EXEC" ]; then
  header_comment="$(head -5 "$PLUGIN_EXEC" | grep -c '#')" || header_comment="0"
  if [ "$header_comment" -gt 0 ]; then
    echo "  PASS: plugin_execution.sh has header comments"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: plugin_execution.sh missing header comments"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: plugin_execution.sh does not exist"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 5: Process command works end-to-end
# =========================================
echo ""
echo "--- Group 5: Process command works end-to-end ---"

INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
echo "hello world" > "$INPUT_DIR/test.txt"

output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" 2>&1)
exit_code=$?
assert_exit_code "process exits 0" "0" "$exit_code"
assert_contains "process output has filePath" "filePath" "$output"

# Verify sidecar created
TOTAL=$((TOTAL + 1))
if [ -f "$OUTPUT_DIR/test.txt.md" ]; then
  echo "  PASS: sidecar .md file created"
  PASS=$((PASS + 1))
else
  echo "  FAIL: sidecar .md file not created"
  FAIL=$((FAIL + 1))
fi

# Exit codes 0/1 tested
output=$(bash "$CLI" process -d "/nonexistent" -o "$OUTPUT_DIR" 2>&1)
exit_code=$?
assert_exit_code "process with bad dir exits 1" "1" "$exit_code"

echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

exit $FAIL
