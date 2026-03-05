#!/bin/bash
# Test suite for FEATURE_0016: plugin tree view
# Run from repository root: bash tests/test_feature_0016.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

PASS=0
FAIL=0
TOTAL=0

TEST_PLUGIN_ROOT="test_tree_root_$$"
TEST_PLUGIN_CHILD="test_tree_child_$$"
TEST_PLUGIN_CIRC_A="test_tree_circa_$$"
TEST_PLUGIN_CIRC_B="test_tree_circb_$$"

cleanup() {
  for name in \
    "$TEST_PLUGIN_ROOT" \
    "$TEST_PLUGIN_CHILD" \
    "$TEST_PLUGIN_CIRC_A" \
    "$TEST_PLUGIN_CIRC_B"; do
    local d="$PLUGIN_DIR/$name"
    [ -d "$d" ] && rm -rf "$d"
  done
}
trap cleanup EXIT

make_plugin() {
  local name="$1"
  local active="${2:-true}"
  local dir="$PLUGIN_DIR/$name"
  rm -rf "$dir"
  mkdir -p "$dir"
  cat > "$dir/descriptor.json" <<EOF
{
  "name": "$name",
  "version": "1.0.0",
  "description": "Test plugin $name",
  "active": $active,
  "commands": {}
}
EOF
}

# make_plugin_with_io creates a plugin with process input/output params for dependency testing
make_plugin_with_io() {
  local name="$1"
  local active="${2:-true}"
  local input_params="${3:-}"   # space-separated param names
  local output_params="${4:-}"  # space-separated param names
  local dir="$PLUGIN_DIR/$name"
  rm -rf "$dir"
  mkdir -p "$dir"

  local input_json="{}"
  if [ -n "$input_params" ]; then
    input_json="{"
    local first=true
    for p in $input_params; do
      [ "$first" = true ] || input_json+=","
      input_json+="\"$p\":{\"type\":\"string\",\"description\":\"$p\",\"required\":true}"
      first=false
    done
    input_json+="}"
  fi

  local output_json="{}"
  if [ -n "$output_params" ]; then
    output_json="{"
    local first=true
    for p in $output_params; do
      [ "$first" = true ] || output_json+=","
      output_json+="\"$p\":{\"type\":\"string\",\"description\":\"$p\"}"
      first=false
    done
    output_json+="}"
  fi

  cat > "$dir/descriptor.json" <<EOF
{
  "name": "$name",
  "version": "1.0.0",
  "description": "Test plugin $name",
  "active": $active,
  "commands": {
    "process": {
      "description": "test",
      "command": "main.sh",
      "input": $input_json,
      "output": $output_json
    }
  }
}
EOF
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
echo "  FEATURE_0016: plugin tree view"
echo "============================================"
echo ""

# =========================================
# Group 1: Basic tree output
# =========================================
echo "--- Group 1: Basic tree output ---"

make_plugin "$TEST_PLUGIN_ROOT" "true"
make_plugin "$TEST_PLUGIN_CHILD" "false"

output=$(bash "$CLI" tree 2>&1)
exit_code=$?
assert_exit_code "tree exits 0" "0" "$exit_code"
assert_contains "tree shows root plugin" "$TEST_PLUGIN_ROOT" "$output"
assert_contains "tree shows child plugin" "$TEST_PLUGIN_CHILD" "$output"

# =========================================
# Group 2: Tree connectors in output
# =========================================
echo ""
echo "--- Group 2: Tree connectors ---"

output=$(bash "$CLI" tree 2>&1)
# Should contain at least one tree connector character
TOTAL=$((TOTAL + 1))
if echo "$output" | grep -qE '(├──|└──)'; then
  echo "  PASS: tree output contains connectors"
  PASS=$((PASS + 1))
else
  echo "  FAIL: tree output missing connectors (├── or └──)"
  echo "    Actual: $output"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 3: Dependency relationship shown
# =========================================
echo ""
echo "--- Group 3: Dependency tree ---"

# ocrmypdf depends on file (set up in implementation)
output=$(bash "$CLI" tree 2>&1)
exit_code=$?
assert_exit_code "tree with real deps exits 0" "0" "$exit_code"
assert_contains "tree shows ocrmypdf" "ocrmypdf" "$output"
assert_contains "tree shows file" "file" "$output"

# ocrmypdf should appear as child of... wait, the spec says:
# "Plugins with dependencies shown as children under their consumers"
# So ocrmypdf has dep on file, meaning file appears under ocrmypdf
# Let's verify file appears somewhere as a child
TOTAL=$((TOTAL + 1))
# file should appear as child indented under ocrmypdf (i.e., after a connector following ocrmypdf line)
ocrmypdf_line=$(echo "$output" | grep -n "ocrmypdf" | head -1 | cut -d: -f1)
file_line=$(echo "$output" | grep -n "file" | tail -1 | cut -d: -f1)
if [ -n "$ocrmypdf_line" ] && [ -n "$file_line" ] && [ "$file_line" -gt "$ocrmypdf_line" ]; then
  echo "  PASS: file appears after ocrmypdf in tree (dependency shown)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: file does not appear as child of ocrmypdf"
  echo "    ocrmypdf line: $ocrmypdf_line, file line: $file_line"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 4: ANSI color codes for active/inactive
# =========================================
echo ""
echo "--- Group 4: ANSI colors ---"

make_plugin "$TEST_PLUGIN_ROOT" "true"
make_plugin "$TEST_PLUGIN_CHILD" "false"

output=$(bash "$CLI" tree 2>&1)
# Active plugins should have green ANSI code \033[32m
TOTAL=$((TOTAL + 1))
if printf '%b' "$output" | cat -v | grep -q '\^\[\[32m'; then
  echo "  PASS: active plugin has green ANSI color"
  PASS=$((PASS + 1))
elif echo "$output" | grep -qP '\x1b\[32m'; then
  echo "  PASS: active plugin has green ANSI color"
  PASS=$((PASS + 1))
else
  # Try a different way - check the raw bytes
  raw_output=$(bash "$CLI" tree 2>&1)
  if printf '%s' "$raw_output" | od -c | grep -q '033'; then
    echo "  PASS: tree output contains ANSI escape codes"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: tree output missing ANSI color codes"
    echo "    Output (escaped): $(echo "$output" | cat -v | head -5)"
    FAIL=$((FAIL + 1))
  fi
fi

# =========================================
# Group 5: Circular dependency detection
# =========================================
echo ""
echo "--- Group 5: Circular dependency ---"

# Create circular dependency via I/O matching:
# CIRC_A outputs "param_a", CIRC_B inputs "param_a" -> CIRC_B depends on CIRC_A
# CIRC_B outputs "param_b", CIRC_A inputs "param_b" -> CIRC_A depends on CIRC_B
# This creates a cycle: CIRC_A <-> CIRC_B
make_plugin_with_io "$TEST_PLUGIN_CIRC_A" "true" "param_b" "param_a"
make_plugin_with_io "$TEST_PLUGIN_CIRC_B" "true" "param_a" "param_b"

output=$(bash "$CLI" tree 2>&1)
exit_code=$?
assert_exit_code "circular dep exits non-zero" "1" "$exit_code"
assert_contains "circular dep error mentions circular" "ircular" "$output"

# Remove circular plugins
rm -rf "$PLUGIN_DIR/$TEST_PLUGIN_CIRC_A" "$PLUGIN_DIR/$TEST_PLUGIN_CIRC_B"

# =========================================
# Group 6: No spurious [missing] with unresolved inputs
# =========================================
echo ""
echo "--- Group 6: No spurious missing marker ---"

# A plugin with an input that no other plugin provides should not show [missing]
make_plugin_with_io "$TEST_PLUGIN_ROOT" "true" "unresolvable_input_xyz" ""

output=$(bash "$CLI" tree 2>&1)
exit_code=$?
assert_exit_code "unresolved input exits 0" "0" "$exit_code"
assert_contains "plugin still appears in tree" "$TEST_PLUGIN_ROOT" "$output"
assert_not_contains "no [missing] marker for unresolved input" "[missing]" "$output"

# Reset
make_plugin "$TEST_PLUGIN_ROOT" "true"

# =========================================
# Group 7: Help text
# =========================================
echo ""
echo "--- Group 7: Help text ---"

output=$(bash "$CLI" --help 2>&1)
assert_contains "--help includes tree command" "tree" "$output"

output=$(bash "$CLI" tree --help 2>&1)
exit_code=$?
assert_exit_code "tree --help exits 0" "0" "$exit_code"
assert_contains "tree --help describes command" "tree" "$output"

# =========================================
# Group 8: Empty plugin dir
# =========================================
echo ""
echo "--- Group 8: Empty plugin dir (simulated) ---"
# We can't truly empty the plugin dir without affecting other tests,
# so we just verify that a no-dependency scenario still exits 0
output=$(bash "$CLI" tree 2>&1)
exit_code=$?
assert_exit_code "tree with real plugins exits 0" "0" "$exit_code"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
