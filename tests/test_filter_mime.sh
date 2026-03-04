#!/bin/bash
# Test suite for MIME type filtering in filter.py and doc.doc.sh (BUG_0003)
# Verifies that MIME type criteria (e.g. "text/plain", "application/pdf",
# "image/*") are correctly matched against actual file MIME types.
#
# These tests are expected to FAIL until BUG_0003 is fixed in filter.py.
# Run from repository root: bash tests/test_filter_mime.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOC_DOC_SH="$REPO_ROOT/doc.doc.sh"
FILTER_PY="$REPO_ROOT/doc.doc.md/components/filter.py"

PASS=0
FAIL=0
TOTAL=0

cleanup() {
  if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
    chmod -R u+rw "$TEST_DIR" 2>/dev/null || true
    rm -rf "$TEST_DIR"
  fi
}
trap cleanup EXIT

assert_eq() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
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
  local test_name="$1"
  local expected="$2"
  local actual="$3"
  TOTAL=$((TOTAL + 1))
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $test_name (exit code $actual)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Expected exit code: $expected"
    echo "    Actual exit code:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
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
  local test_name="$1"
  local unexpected="$2"
  local actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$unexpected"; then
    echo "  FAIL: $test_name"
    echo "    Expected NOT to contain: $unexpected"
    echo "    Actual: $actual"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

# ---------------------------------------------------------------------------
# Setup: create files with known MIME types
# ---------------------------------------------------------------------------
TEST_DIR=$(mktemp -d)

# text/plain
echo "Hello World"        > "$TEST_DIR/hello.txt"
echo "# Markdown doc"     > "$TEST_DIR/doc.md"

# application/json → text/plain on some systems; but json is distinct
printf '{"key":"value"}\n' > "$TEST_DIR/data.json"

# Create a minimal valid PNG (1×1 white pixel) → image/png
printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82' \
  > "$TEST_DIR/image.png"

# Verify MIME detection is available (skip MIME tests gracefully if not)
if ! command -v file >/dev/null 2>&1; then
  echo "WARNING: 'file' command not available — skipping MIME type tests"
  exit 0
fi

TXT_MIME=$(file --mime-type -b "$TEST_DIR/hello.txt")
PNG_MIME=$(file --mime-type -b "$TEST_DIR/image.png")

echo "============================================"
echo "  BUG_0003 Test Suite — MIME Type Filtering"
echo "============================================"
echo ""
echo "  Setup MIME types detected on this system:"
echo "    hello.txt  → $TXT_MIME"
echo "    doc.md     → $(file --mime-type -b "$TEST_DIR/doc.md")"
echo "    data.json  → $(file --mime-type -b "$TEST_DIR/data.json")"
echo "    image.png  → $PNG_MIME"
echo ""

# ---------------------------------------------------------------------------
# filter.py unit tests — MIME include
# ---------------------------------------------------------------------------
echo "--- filter.py: include by MIME type (text/plain) ---"

# Feed all four file paths; only text/plain files should be returned
output=$(printf '%s\n' \
  "$TEST_DIR/hello.txt" \
  "$TEST_DIR/doc.md" \
  "$TEST_DIR/data.json" \
  "$TEST_DIR/image.png" \
  | python3 "$FILTER_PY" --include "text/plain")

assert_contains "include text/plain keeps hello.txt" "$TEST_DIR/hello.txt" "$output"
assert_contains "include text/plain keeps doc.md"    "$TEST_DIR/doc.md"    "$output"
assert_not_contains "include text/plain excludes image.png" "$TEST_DIR/image.png" "$output"

echo ""
echo "--- filter.py: include by exact MIME type (image/png) ---"

output=$(printf '%s\n' \
  "$TEST_DIR/hello.txt" \
  "$TEST_DIR/image.png" \
  | python3 "$FILTER_PY" --include "image/png")

assert_not_contains "include image/png excludes hello.txt" "$TEST_DIR/hello.txt" "$output"
assert_contains     "include image/png keeps image.png"    "$TEST_DIR/image.png" "$output"

echo ""
echo "--- filter.py: include by glob MIME type (image/*) ---"

output=$(printf '%s\n' \
  "$TEST_DIR/hello.txt" \
  "$TEST_DIR/image.png" \
  | python3 "$FILTER_PY" --include "image/*")

assert_not_contains "include image/* excludes hello.txt" "$TEST_DIR/hello.txt" "$output"
assert_contains     "include image/* keeps image.png"    "$TEST_DIR/image.png" "$output"

echo ""
echo "--- filter.py: exclude by MIME type (image/png) ---"

output=$(printf '%s\n' \
  "$TEST_DIR/hello.txt" \
  "$TEST_DIR/image.png" \
  | python3 "$FILTER_PY" --exclude "image/png")

assert_contains     "exclude image/png keeps hello.txt"    "$TEST_DIR/hello.txt" "$output"
assert_not_contains "exclude image/png removes image.png"  "$TEST_DIR/image.png" "$output"

echo ""
echo "--- filter.py: exclude by glob MIME type (image/*) ---"

output=$(printf '%s\n' \
  "$TEST_DIR/hello.txt" \
  "$TEST_DIR/image.png" \
  | python3 "$FILTER_PY" --exclude "image/*")

assert_contains     "exclude image/* keeps hello.txt"   "$TEST_DIR/hello.txt" "$output"
assert_not_contains "exclude image/* removes image.png" "$TEST_DIR/image.png" "$output"

echo ""
echo "--- filter.py: MIME include combined with extension include (AND logic) ---"

# Include text/plain AND include *.txt  →  only hello.txt (not doc.md)
output=$(printf '%s\n' \
  "$TEST_DIR/hello.txt" \
  "$TEST_DIR/doc.md" \
  | python3 "$FILTER_PY" --include "text/plain" --include "*.txt")

assert_contains     "MIME+ext AND: keeps hello.txt" "$TEST_DIR/hello.txt" "$output"
assert_not_contains "MIME+ext AND: drops doc.md"    "$TEST_DIR/doc.md"    "$output"

echo ""
echo "--- filter.py: no MIME criteria — extension filter still works ---"

output=$(printf '%s\n' \
  "$TEST_DIR/hello.txt" \
  "$TEST_DIR/image.png" \
  | python3 "$FILTER_PY" --include ".txt")

assert_contains     "extension filter unaffected by MIME fix: .txt kept"       "$TEST_DIR/hello.txt" "$output"
assert_not_contains "extension filter unaffected by MIME fix: .png excluded"   "$TEST_DIR/image.png" "$output"

echo ""
echo "--- filter.py: no MIME criteria — glob filter still works ---"

output=$(printf '%s\n' \
  "$TEST_DIR/hello.txt" \
  "$TEST_DIR/image.png" \
  | python3 "$FILTER_PY" --include "*.png")

assert_not_contains "glob filter unaffected: .txt excluded" "$TEST_DIR/hello.txt" "$output"
assert_contains     "glob filter unaffected: .png kept"     "$TEST_DIR/image.png" "$output"

# ---------------------------------------------------------------------------
# Integration tests — doc.doc.sh process with MIME type filter
# ---------------------------------------------------------------------------
echo ""
echo "--- Integration: doc.doc.sh process -i text/plain ---"

INT_DIR=$(mktemp -d)
echo "plain text file" > "$INT_DIR/note.txt"
echo "markdown file"   > "$INT_DIR/readme.md"
printf '\x89PNG\r\n\x1a\n' > "$INT_DIR/icon.png"

output=$("$DOC_DOC_SH" process -d "$INT_DIR" -i "text/plain" 2>/dev/null)
exit_code=$?
rm -rf "$INT_DIR"

assert_exit_code "process -i text/plain exits 0" "0" "$exit_code"

# Should return at least 1 file (note.txt, readme.md are text/plain)
file_count=$(echo "$output" | jq 'length' 2>/dev/null || echo "0")
TOTAL=$((TOTAL + 1))
if [ "$file_count" -gt 0 ] 2>/dev/null; then
  echo "  PASS: process -i text/plain returns >0 files (got $file_count)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: process -i text/plain returned 0 files — MIME type criterion not matched"
  echo "    Got: $output"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
