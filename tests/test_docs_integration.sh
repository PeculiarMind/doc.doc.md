#!/bin/bash
# Integration test suite for doc.doc.sh process command
# Exercises real fixture files committed to tests/docs/
# Run from repository root: bash tests/test_docs_integration.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOC_DOC_SH="$REPO_ROOT/doc.doc.sh"
DOCS_DIR="$REPO_ROOT/tests/docs"

PASS=0
FAIL=0
TOTAL=0

# Cleanup trap for temp files
_STDERR_TMP=""
cleanup() {
  [ -n "${_STDERR_TMP:-}" ] && rm -f "$_STDERR_TMP"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Test helper functions
# ---------------------------------------------------------------------------

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

# assert_json_count <test_name> <expected_count> <json>
# Checks that jq 'length' of the given JSON equals expected_count.
assert_json_count() {
  local test_name="$1"
  local expected="$2"
  local json="$3"
  local actual
  actual=$(echo "$json" | jq 'length' 2>/dev/null)
  assert_eq "$test_name" "$expected" "$actual"
}

# assert_json_field_contains <test_name> <field> <expected_substring> <entry_json>
# Extracts .field from entry_json and asserts the value contains expected_substring.
assert_json_field_contains() {
  local test_name="$1"
  local field="$2"
  local expected="$3"
  local entry="$4"
  local actual
  actual=$(echo "$entry" | jq -r --arg f "$field" '.[$f] // ""')
  assert_contains "$test_name" "$expected" "$actual"
}

# assert_gt_zero <test_name> <number>
# Asserts that number is greater than zero.
assert_gt_zero() {
  local test_name="$1"
  local actual="$2"
  TOTAL=$((TOTAL + 1))
  if [ "$actual" -gt 0 ] 2>/dev/null; then
    echo "  PASS: $test_name ($actual)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Expected: > 0"
    echo "    Actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

# ---------------------------------------------------------------------------
# Helpers: per-file assertion block
# ---------------------------------------------------------------------------

# _assert_file_entry <filename> <expected_mime>
# Runs 4 assertions for one fixture file using the shared $output variable.
_assert_file_entry() {
  local filename="$1"
  local expected_mime="$2"

  local entry
  entry=$(echo "$output" | jq --arg f "$filename" '.[] | select(.filePath | contains($f))')

  assert_eq "$filename: mimeType" \
    "$expected_mime" "$(echo "$entry" | jq -r '.mimeType')"

  local fs
  fs=$(echo "$entry" | jq '.fileSize')
  assert_gt_zero "$filename: fileSize > 0" "$fs"

  local fm
  fm=$(echo "$entry" | jq -r '.fileModified')
  assert_contains "$filename: fileModified is non-empty (ISO-8601 contains T)" "T" "$fm"

  assert_json_field_contains \
    "$filename: filePath contains filename" "filePath" "$filename" "$entry"
}

# ---------------------------------------------------------------------------
# Capture main output once; reused by Groups 1–3
# ---------------------------------------------------------------------------

echo "============================================"
echo "  Integration Test Suite — tests/docs"
echo "============================================"
echo ""

output=$("$DOC_DOC_SH" process -d "$DOCS_DIR" 2>/dev/null)
main_exit=$?

# ---------------------------------------------------------------------------
# Group 1: Overall output shape
# ---------------------------------------------------------------------------
echo "--- Group 1: Overall output shape ---"

assert_exit_code "process -d ./tests/docs exits 0" "0" "$main_exit"

echo "$output" | jq '.' > /dev/null 2>&1
assert_exit_code "stdout is valid JSON" "0" "$?"

assert_json_count "JSON array has exactly 4 elements" "4" "$output"

all_have_filepath=$(echo "$output" | jq '[.[] | has("filePath")] | all')
assert_eq "all elements have filePath field" "true" "$all_have_filepath"

echo ""

# ---------------------------------------------------------------------------
# Group 2: Per-file assertions
# ---------------------------------------------------------------------------
echo "--- Group 2: Per-file assertions ---"

_assert_file_entry "README-PDF.pdf"             "application/pdf"
_assert_file_entry "README-Screenshot-GIF.gif"  "image/gif"
_assert_file_entry "README-Screenshot-JPG.jpg"  "image/jpeg"
_assert_file_entry "README-Screenshot-PNG.png"  "image/png"

echo ""

# ---------------------------------------------------------------------------
# Group 3: Extension/glob filter
# ---------------------------------------------------------------------------
echo "--- Group 3: Extension/glob filter ---"

assert_json_count "include .pdf → exactly 1 result" "1" \
  "$("$DOC_DOC_SH" process -d "$DOCS_DIR" -i ".pdf" 2>/dev/null)"

assert_json_count "include .gif → exactly 1 result" "1" \
  "$("$DOC_DOC_SH" process -d "$DOCS_DIR" -i ".gif" 2>/dev/null)"

assert_json_count "include .jpg → exactly 1 result" "1" \
  "$("$DOC_DOC_SH" process -d "$DOCS_DIR" -i ".jpg" 2>/dev/null)"

assert_json_count "include .png → exactly 1 result" "1" \
  "$("$DOC_DOC_SH" process -d "$DOCS_DIR" -i ".png" 2>/dev/null)"

assert_json_count "exclude .gif,.jpg,.png → exactly 1 result (PDF)" "1" \
  "$("$DOC_DOC_SH" process -d "$DOCS_DIR" -e ".gif,.jpg,.png" 2>/dev/null)"

assert_json_count "include .gif,.jpg,.png → exactly 3 results" "3" \
  "$("$DOC_DOC_SH" process -d "$DOCS_DIR" -i ".gif,.jpg,.png" 2>/dev/null)"

echo ""

# ---------------------------------------------------------------------------
# Group 4: MIME type filter
# BUG_0003 — MIME type filtering not yet implemented in filter.py
# ---------------------------------------------------------------------------
echo "--- Group 4: MIME type filter (BUG_0003) ---"

assert_json_count "include application/pdf → exactly 1 result" "1" \
  "$("$DOC_DOC_SH" process -d "$DOCS_DIR" -i "application/pdf" 2>/dev/null)"

assert_json_count "include image/jpeg → exactly 1 result" "1" \
  "$("$DOC_DOC_SH" process -d "$DOCS_DIR" -i "image/jpeg" 2>/dev/null)"

assert_json_count "include image/* → exactly 3 results (GIF, JPG, PNG)" "3" \
  "$("$DOC_DOC_SH" process -d "$DOCS_DIR" -i "image/*" 2>/dev/null)"

assert_json_count "exclude image/* → exactly 1 result (only PDF remains)" "1" \
  "$("$DOC_DOC_SH" process -d "$DOCS_DIR" -e "image/*" 2>/dev/null)"

echo ""

# ---------------------------------------------------------------------------
# Group 5: ocrmypdf graceful degradation
# ---------------------------------------------------------------------------
echo "--- Group 5: ocrmypdf graceful degradation ---"

_STDERR_TMP=$(mktemp)
output5=$("$DOC_DOC_SH" process -d "$DOCS_DIR" 2>"$_STDERR_TMP")
stderr5=$(cat "$_STDERR_TMP")

assert_contains "stderr contains ocrmypdf failure message" \
  "Plugin 'ocrmypdf' failed" "$stderr5"

echo "$output5" | jq '.' > /dev/null 2>&1
assert_exit_code "despite ocrmypdf errors, stdout is valid JSON" "0" "$?"

assert_json_count "despite ocrmypdf errors, JSON array has 4 elements" "4" "$output5"

all_have_mimetype=$(echo "$output5" | jq '[.[] | has("mimeType")] | all')
assert_eq "all 4 entries have mimeType (stat+file results present despite ocrmypdf failure)" \
  "true" "$all_have_mimetype"

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
