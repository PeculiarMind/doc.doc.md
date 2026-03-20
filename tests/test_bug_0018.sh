#!/bin/bash
# Test suite for BUG_0018: process command mirrors full relative path instead of input dir contents
# TDD: Tests define the contract BEFORE implementation
# Run from repository root: bash tests/test_bug_0018.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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

assert_file_exists() {
  local test_name="$1" filepath="$2"
  TOTAL=$((TOTAL + 1))
  if [ -e "$filepath" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    File not found: $filepath"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_not_exists() {
  local test_name="$1" filepath="$2"
  TOTAL=$((TOTAL + 1))
  if [ ! -e "$filepath" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    File should not exist: $filepath"
    FAIL=$((FAIL + 1))
  fi
}

TEST_TMP=""

setup() {
  TEST_TMP=$(mktemp -d)
  # Create test input files
  mkdir -p "$TEST_TMP/input_dir"
  echo "test content" > "$TEST_TMP/input_dir/testfile.txt"
  mkdir -p "$TEST_TMP/input_dir/subdir"
  echo "nested content" > "$TEST_TMP/input_dir/subdir/nested.txt"
  mkdir -p "$TEST_TMP/output"
  
  # Deactivate plugins that may not be installed to avoid hangs
  for p in markitdown ocrmypdf crm114; do
    local desc="$REPO_ROOT/doc.doc.md/plugins/$p/descriptor.json"
    if [ -f "$desc" ]; then
      local tmp=$(mktemp)
      jq '.active = false' "$desc" > "$tmp" && mv "$tmp" "$desc"
    fi
  done
}

teardown() {
  # Re-activate plugins
  for p in markitdown ocrmypdf crm114; do
    local desc="$REPO_ROOT/doc.doc.md/plugins/$p/descriptor.json"
    if [ -f "$desc" ]; then
      local tmp=$(mktemp)
      jq '.active = true' "$desc" > "$tmp" && mv "$tmp" "$desc"
    fi
  done
  [ -n "$TEST_TMP" ] && rm -rf "$TEST_TMP"
}

# ============================================================
# Group 1: Relative path with ./ prefix
# ============================================================

echo ""
echo "=== Group 1: Relative path with ./ prefix ==="

echo ""
echo "--- Test 1.1: Sidecar files directly under output dir (not nested) ---"
setup
cd "$TEST_TMP"
"$REPO_ROOT/doc.doc.sh" process -d ./input_dir/ -o ./output > /dev/null 2>&1 || true
assert_file_exists "Sidecar exists at output/testfile.txt.md" "$TEST_TMP/output/testfile.txt.md"
assert_file_not_exists "No mirrored path output/input_dir/" "$TEST_TMP/output/input_dir"
cd "$REPO_ROOT"
teardown

echo ""
echo "--- Test 1.2: Nested files preserve structure under output dir ---"
setup
cd "$TEST_TMP"
"$REPO_ROOT/doc.doc.sh" process -d ./input_dir/ -o ./output > /dev/null 2>&1 || true
assert_file_exists "Nested sidecar at output/subdir/nested.txt.md" "$TEST_TMP/output/subdir/nested.txt.md"
assert_file_not_exists "No mirrored nested path" "$TEST_TMP/output/input_dir/subdir"
cd "$REPO_ROOT"
teardown

# ============================================================
# Group 2: Relative path without ./ prefix
# ============================================================

echo ""
echo "=== Group 2: Relative path without ./ prefix ==="

echo ""
echo "--- Test 2.1: Plain relative path works ---"
setup
cd "$TEST_TMP"
"$REPO_ROOT/doc.doc.sh" process -d input_dir -o output > /dev/null 2>&1 || true
assert_file_exists "Sidecar at output/testfile.txt.md" "$TEST_TMP/output/testfile.txt.md"
assert_file_not_exists "No mirrored path" "$TEST_TMP/output/input_dir"
cd "$REPO_ROOT"
teardown

# ============================================================
# Group 3: Absolute path
# ============================================================

echo ""
echo "=== Group 3: Absolute path ==="

echo ""
echo "--- Test 3.1: Absolute path works ---"
setup
"$REPO_ROOT/doc.doc.sh" process -d "$TEST_TMP/input_dir" -o "$TEST_TMP/output" > /dev/null 2>&1 || true
assert_file_exists "Sidecar at output/testfile.txt.md" "$TEST_TMP/output/testfile.txt.md"
teardown

# ============================================================
# Group 4: Echo mode uses correct relative path
# ============================================================

echo ""
echo "=== Group 4: Echo mode relative path ==="

echo ""
echo "--- Test 4.1: Echo mode shows filename, not full path ---"
setup
cd "$TEST_TMP"
echo_output=$("$REPO_ROOT/doc.doc.sh" process -d ./input_dir/ --echo 2>/dev/null) || true
TOTAL=$((TOTAL + 1))
if echo "$echo_output" | grep -q "=== testfile.txt ==="; then
  echo "  PASS: Echo mode shows filename without path prefix"
  PASS=$((PASS + 1))
elif echo "$echo_output" | grep -q "=== subdir/nested.txt ==="; then
  echo "  PASS: Echo mode shows relative filename without input dir prefix"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Echo mode should show filename relative to input dir"
  echo "    Actual output: $(echo "$echo_output" | head -5)"
  FAIL=$((FAIL + 1))
fi
cd "$REPO_ROOT"
teardown

# ---- summary ----

echo ""
echo "==========================================="
echo "  BUG_0018 Results: $PASS passed, $FAIL failed out of $TOTAL"
echo "==========================================="
echo ""

exit "$FAIL"
