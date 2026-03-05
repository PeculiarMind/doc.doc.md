#!/bin/bash
# Test suite for BUG_0008: Process Output Sidecar Boundary Check Uses Bare String Prefix
# Run from repository root: bash tests/test_bug_0008.sh
#
# The boundary check on the sidecar path used a bare prefix match:
#   if [[ "$canonical_sidecar" != "${canonical_out}"* ]]; then
# This is flawed because a sibling directory like /tmp/output_evil passes
# the check when canonical_out=/tmp/output, since /tmp/output_evil starts
# with /tmp/output.
#
# The fix requires an exact match OR a slash-delimited prefix:
#   if [[ "$canonical_sidecar" != "${canonical_out}" && \
#          "$canonical_sidecar" != "${canonical_out}/"* ]]; then

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"

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

assert_file_exists() {
  local test_name="$1" path="$2"
  TOTAL=$((TOTAL + 1))
  if [ -f "$path" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name (file not found: $path)"
    FAIL=$((FAIL + 1))
  fi
}

echo "============================================"
echo "  BUG_0008: Process Output Sidecar Boundary"
echo "           Check Uses Bare String Prefix"
echo "============================================"
echo ""

# =========================================
# Group 1: Source contains the fixed boundary check pattern
# The correct pattern uses a trailing slash to prevent sibling-directory bypass:
#   != "${canonical_out}/"*
# =========================================
echo "--- Group 1: Source code contains correct boundary check ---"

source_code=$(cat "$CLI")

# The fixed code must contain the slash-delimited prefix check
assert_contains \
  "source contains slash-delimited prefix check (canonical_out}/\"*)" \
  '!= "${canonical_out}/"*' \
  "$source_code"

# The fixed code must also contain the exact-match arm
assert_contains \
  "source contains exact-match check (canonical_out}\")" \
  '!= "${canonical_out}"' \
  "$source_code"

# =========================================
# Group 2: Source does NOT contain the flawed bare-prefix pattern
# The old flawed pattern was:
#   != "${canonical_out}"*
# (without a trailing slash before the wildcard)
# We check that the bare form does NOT appear on the boundary-check line.
# =========================================
echo ""
echo "--- Group 2: Flawed bare-prefix pattern is absent ---"

# Extract only boundary-check lines that test canonical_out with a glob
boundary_lines=$(grep -n 'canonical_out}' "$CLI" | grep '\*' || true)

# The flawed pattern: "* after closing brace+quote with no slash
# i.e.  ${canonical_out}"*  (quote immediately followed by asterisk)
# In the fixed version the asterisk is preceded by /"  so we should
# NOT find the pattern  canonical_out}"*  (brace-quote-star with no slash).
TOTAL=$((TOTAL + 1))
if echo "$boundary_lines" | grep -qF '${canonical_out}"*'; then
  # Found the bare prefix pattern — check if it is the OLD unfixed form.
  # The fixed file will have  ${canonical_out}/"*  but NEVER  ${canonical_out}"*
  # (without slash).  Filter out lines that contain the fixed slash form.
  unfixed_lines=$(echo "$boundary_lines" | grep -F '${canonical_out}"*' | grep -vF '${canonical_out}/"*' || true)
  if [ -n "$unfixed_lines" ]; then
    echo "  FAIL: flawed bare-prefix pattern still present in source"
    echo "    Line(s): $unfixed_lines"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: bare-prefix pattern only appears in fixed slash form"
    PASS=$((PASS + 1))
  fi
else
  echo "  PASS: no bare-prefix boundary check found (already fixed)"
  PASS=$((PASS + 1))
fi

# =========================================
# Group 3: Regression — process with -o still works correctly
# =========================================
echo ""
echo "--- Group 3: Regression — process with -o produces output ---"

INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
echo "hello world" > "$INPUT_DIR/sample.txt"
mkdir -p "$INPUT_DIR/sub"
echo "nested content" > "$INPUT_DIR/sub/deep.txt"

output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" 2>/dev/null)
exit_code=$?

assert_exit_code "process with -o exits 0" "0" "$exit_code"

# Verify JSON output on stdout
TOTAL=$((TOTAL + 1))
if echo "$output" | jq empty 2>/dev/null; then
  echo "  PASS: stdout is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: stdout is NOT valid JSON"
  FAIL=$((FAIL + 1))
fi

# Verify sidecar files were created
assert_file_exists "sidecar for sample.txt" "$OUTPUT_DIR/sample.txt.md"
assert_file_exists "sidecar for sub/deep.txt" "$OUTPUT_DIR/sub/deep.txt.md"

# =========================================
# Group 4: Regression — stderr reports processing
# =========================================
echo ""
echo "--- Group 4: Regression — stderr shows progress ---"

REGR_OUT=$(mktemp -d)
stderr_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$REGR_OUT" 2>&1 >/dev/null)
assert_contains "stderr mentions Processed" "Processed:" "$stderr_output"
rm -rf "$REGR_OUT"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
