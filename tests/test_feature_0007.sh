#!/bin/bash
# Test suite for FEATURE_0007: file plugin first in chain and MIME type filter gate
# Run from repository root: bash tests/test_feature_0007.sh
#
# Tests FAIL before implementation. They are written to PASS after implementation of:
#   1. MIME type criterion support in filter.py (criteria containing '/')
#   2. file plugin enforced as position-0 in the processing chain (doc.doc.sh)
#   3. MIME filter gate applied after file plugin runs for each file (doc.doc.sh)

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOC_DOC_SH="$REPO_ROOT/doc.doc.sh"
FILTER_PY="$REPO_ROOT/doc.doc.md/components/filter.py"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"
FILE_DESCRIPTOR="$PLUGIN_DIR/file/descriptor.json"

PASS=0
FAIL=0
TOTAL=0

# ---- Cleanup ----

cleanup() {
  # Restore file plugin descriptor if it was modified
  if [ -n "${SAVED_FILE_DESCRIPTOR:-}" ] && [ -f "$SAVED_FILE_DESCRIPTOR" ]; then
    cp "$SAVED_FILE_DESCRIPTOR" "$FILE_DESCRIPTOR" 2>/dev/null || true
    rm -f "$SAVED_FILE_DESCRIPTOR"
  fi
  # Remove test directory
  if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
    chmod -R u+rw "$TEST_DIR" 2>/dev/null || true
    rm -rf "$TEST_DIR"
  fi
}
trap cleanup EXIT

# ---- Test helpers ----

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
  local not_expected="$2"
  local actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$not_expected"; then
    echo "  FAIL: $test_name"
    echo "    Expected NOT to contain: $not_expected"
    echo "    Actual: $actual"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

assert_json_valid() {
  local test_name="$1"
  local json="$2"
  TOTAL=$((TOTAL + 1))
  if echo "$json" | jq empty 2>/dev/null; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name (output is not valid JSON)"
    echo "    Actual: $json"
    FAIL=$((FAIL + 1))
  fi
}

# ---- Setup: create test files of known MIME types ----

TEST_DIR=$(mktemp -d)

# text/plain
echo "Hello, World!" > "$TEST_DIR/text_file.txt"
echo "Another text file" > "$TEST_DIR/another.txt"

# image/png — minimal valid 1x1 PNG binary
printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82' \
  > "$TEST_DIR/image_file.png"

# text/html (file command detects by content)
printf '<!DOCTYPE html>\n<html><head><title>Test</title></head><body>Hello</body></html>\n' \
  > "$TEST_DIR/page.html"

# Subdirectory with another file
mkdir -p "$TEST_DIR/subdir"
echo "nested file" > "$TEST_DIR/subdir/nested.txt"

echo "============================================"
echo "  FEATURE_0007 Test Suite"
echo "============================================"
echo ""

# ===========================================================================
# SECTION 1: filter.py — MIME type criterion matching (unit tests)
#
# After implementation, filter.py recognises criteria containing '/' as
# MIME type criteria and matches them against MIME type strings (not paths).
# Glob patterns like 'image/*' are also supported via fnmatch.
#
# These tests pass MIME type strings as the "path" input to filter.py,
# verifying the core matching logic that filter.py must implement.
# ===========================================================================
echo "--- filter.py: MIME type criterion — exact match ---"

# MIME exact match: text/plain matches text/plain
output=$(echo "text/plain" | python3 "$FILTER_PY" --include "text/plain")
assert_eq "MIME exact match: text/plain includes text/plain" "text/plain" "$output"

# MIME exact match: application/pdf does not match text/plain criterion
output=$(echo "application/pdf" | python3 "$FILTER_PY" --include "text/plain")
assert_eq "MIME exact match: application/pdf excluded by text/plain criterion" "" "$output"

# MIME exact match: image/png matches image/png exclude criterion → no output
output=$(echo "image/png" | python3 "$FILTER_PY" --exclude "image/png")
assert_eq "MIME exact exclude: image/png excluded by image/png criterion" "" "$output"

# MIME exact match: text/plain NOT excluded by image/png criterion → passes through
output=$(echo "text/plain" | python3 "$FILTER_PY" --exclude "image/png")
assert_eq "MIME exact exclude: text/plain not excluded by image/png criterion" "text/plain" "$output"

echo ""
echo "--- filter.py: MIME type criterion — glob patterns ---"

# Glob: image/* matches image/jpeg
output=$(echo "image/jpeg" | python3 "$FILTER_PY" --include "image/*")
assert_eq "MIME glob: image/* includes image/jpeg" "image/jpeg" "$output"

# Glob: image/* matches image/png
output=$(echo "image/png" | python3 "$FILTER_PY" --include "image/*")
assert_eq "MIME glob: image/* includes image/png" "image/png" "$output"

# Glob: image/* does NOT match text/plain
output=$(echo "text/plain" | python3 "$FILTER_PY" --include "image/*")
assert_eq "MIME glob: image/* does not include text/plain" "" "$output"

# Glob: text/* matches text/plain
output=$(echo "text/plain" | python3 "$FILTER_PY" --include "text/*")
assert_eq "MIME glob: text/* includes text/plain" "text/plain" "$output"

# Glob: text/* matches text/html
output=$(echo "text/html" | python3 "$FILTER_PY" --include "text/*")
assert_eq "MIME glob: text/* includes text/html" "text/html" "$output"

# Glob: text/* does NOT match application/pdf
output=$(echo "application/pdf" | python3 "$FILTER_PY" --include "text/*")
assert_eq "MIME glob: text/* does not include application/pdf" "" "$output"

# Glob exclude: image/* excludes image/jpeg
output=$(echo "image/jpeg" | python3 "$FILTER_PY" --exclude "image/*")
assert_eq "MIME glob exclude: image/* excludes image/jpeg" "" "$output"

# Glob exclude: image/* does NOT exclude text/plain
output=$(echo "text/plain" | python3 "$FILTER_PY" --exclude "image/*")
assert_eq "MIME glob exclude: image/* does not exclude text/plain" "text/plain" "$output"

echo ""
echo "--- filter.py: MIME type criterion — AND/OR logic ---"

# OR within single --include: text/plain,application/pdf includes both
output=$(printf 'text/plain\napplication/pdf\nimage/jpeg\n' \
  | python3 "$FILTER_PY" --include "text/plain,application/pdf")
assert_eq "MIME OR in include: text/plain,application/pdf" \
  "$(printf 'text/plain\napplication/pdf')" "$output"

# OR within single --exclude: image/png,image/jpeg excludes both
output=$(printf 'image/png\nimage/jpeg\ntext/plain\n' \
  | python3 "$FILTER_PY" --exclude "image/png,image/jpeg")
assert_eq "MIME OR in exclude: image/png,image/jpeg" "text/plain" "$output"

# AND between --include params: text/* AND application/json
# Only a type that satisfies BOTH is included — impossible here → empty
output=$(printf 'text/plain\napplication/json\napplication/pdf\n' \
  | python3 "$FILTER_PY" --include "text/*" --include "application/json")
assert_eq "MIME AND between includes: text/* AND application/json → empty" "" "$output"

# AND between --exclude params: only excluded if matches ALL exclude criteria
# Exclude .log AND text/* → only text/plain matches both (it's text/* and ends in... wait)
# Use simpler case: --exclude image/png --exclude image/jpeg
# image/png matches image/png but not image/jpeg → NOT excluded (AND logic)
# image/jpeg matches image/jpeg but not image/png → NOT excluded
# Neither matches both → all pass through
output=$(printf 'image/png\nimage/jpeg\ntext/plain\n' \
  | python3 "$FILTER_PY" --exclude "image/png" --exclude "image/jpeg")
assert_eq "MIME AND between excludes: must match ALL to be excluded → all pass" \
  "$(printf 'image/png\nimage/jpeg\ntext/plain')" "$output"

echo ""
echo "--- filter.py: MIME criteria do not accidentally match file paths ---"

# A MIME criterion 'text/plain' should NOT match a file path '/path/to/file.txt'
# After implementation, MIME criteria are applied to mimeType values, not file paths.
# Current filter.py also returns no output here (fnmatch fails), which is the correct
# MIME-aware behavior: file paths are not evaluated against MIME criteria.
output=$(echo "/home/user/documents/file.txt" | python3 "$FILTER_PY" --include "text/plain")
assert_eq "MIME criterion does not accidentally match file path" "" "$output"

output=$(echo "/photos/image.png" | python3 "$FILTER_PY" --include "image/*")
assert_eq "MIME glob criterion does not accidentally match image path" "" "$output"

echo ""
echo "--- filter.py: existing extension and glob criteria still work ---"

# Extension criteria still work unchanged
output=$(printf '/path/file.txt\n/path/file.pdf\n/path/file.log\n' \
  | python3 "$FILTER_PY" --include ".txt,.pdf")
assert_eq "backward compat: include .txt,.pdf still works" \
  "$(printf '/path/file.txt\n/path/file.pdf')" "$output"

output=$(printf '/path/file.txt\n/path/file.log\n' \
  | python3 "$FILTER_PY" --exclude ".log")
assert_eq "backward compat: exclude .log still works" "/path/file.txt" "$output"

# Glob path criteria still work unchanged
output=$(printf '/docs/2024/file.txt\n/docs/2025/file.txt\n' \
  | python3 "$FILTER_PY" --include "**/2024/**")
assert_eq "backward compat: glob **/2024/** still works" "/docs/2024/file.txt" "$output"

output=$(printf '/path/file.txt\n/temp/file.txt\n' \
  | python3 "$FILTER_PY" --exclude "**/temp/**")
assert_eq "backward compat: exclude glob **/temp/** still works" "/path/file.txt" "$output"

# ===========================================================================
# SECTION 2: file plugin first — enforcement tests (integration)
#
# doc.doc.sh must place the file plugin at position 0 in the execution order.
# If the file plugin is not active, process must abort with a specific error.
#
# These tests FAIL before implementation because doc.doc.sh currently does not
# enforce file-first ordering and does not abort when the file plugin is inactive.
# ===========================================================================
echo ""
echo "--- Integration: file plugin must be active for process command ---"

# Save the file plugin descriptor and temporarily disable the file plugin
SAVED_FILE_DESCRIPTOR=$(mktemp)
cp "$FILE_DESCRIPTOR" "$SAVED_FILE_DESCRIPTOR"
jq '.active = false' "$FILE_DESCRIPTOR" > "${FILE_DESCRIPTOR}.tmp" \
  && mv "${FILE_DESCRIPTOR}.tmp" "$FILE_DESCRIPTOR"

output=$("$DOC_DOC_SH" process -d "$TEST_DIR" 2>&1)
exit_code=$?

# Restore immediately
cp "$SAVED_FILE_DESCRIPTOR" "$FILE_DESCRIPTOR"
rm -f "$SAVED_FILE_DESCRIPTOR"
SAVED_FILE_DESCRIPTOR=""

assert_exit_code "process exits with 1 when file plugin is inactive" "1" "$exit_code"
assert_contains "error message references file plugin" \
  "file plugin must be active" "$output"

echo ""
echo "--- Integration: file plugin absent from plugin directory ---"

# Test: if the file plugin directory is absent, process must abort.
# We simulate this by temporarily renaming the file plugin directory.
FILE_PLUGIN_DIR="$PLUGIN_DIR/file"
FILE_PLUGIN_DIR_BACKUP="$PLUGIN_DIR/_file_backup_test_$$"

mv "$FILE_PLUGIN_DIR" "$FILE_PLUGIN_DIR_BACKUP"

output=$("$DOC_DOC_SH" process -d "$TEST_DIR" 2>&1)
exit_code=$?

# Restore immediately
mv "$FILE_PLUGIN_DIR_BACKUP" "$FILE_PLUGIN_DIR"

assert_exit_code "process exits with 1 when file plugin directory is absent" "1" "$exit_code"
assert_contains "error message references file plugin when dir absent" \
  "file plugin" "$output"

echo ""
echo "--- Integration: file plugin is always first in execution order ---"

# When processing a file, mimeType must be present in the output, proving
# the file plugin ran. More importantly, the file plugin must run BEFORE
# other plugins so its output is available to the MIME filter gate.
# We test this by verifying mimeType is present in all output entries
# (it would be absent if stat ran first and file plugin was skipped by gate).
output=$("$DOC_DOC_SH" process -d "$TEST_DIR" 2>/dev/null)
exit_code=$?
assert_exit_code "process succeeds with file plugin active" "0" "$exit_code"

mime_count=$(echo "$output" | jq '[.[] | select(.mimeType != null)] | length' 2>/dev/null || echo "0")
total_count=$(echo "$output" | jq 'length' 2>/dev/null || echo "0")
assert_eq "all output entries have mimeType (file plugin ran first for each)" \
  "$total_count" "$mime_count"

# ===========================================================================
# SECTION 3: MIME filter gate — integration tests
#
# After file plugin runs for each file, doc.doc evaluates the mimeType
# output against --include/--exclude criteria. Files whose MIME type does
# not satisfy the criteria are silently skipped (not included in output).
#
# These tests FAIL before implementation because doc.doc.sh currently passes
# file paths (not MIME types) to filter.py, so MIME criteria never match.
# ===========================================================================
echo ""
echo "--- Integration: MIME include filter — text/plain ---"

# Only text/plain files should appear; PNG and other types silently skipped.
# TEST_DIR contains: text_file.txt, another.txt (text/plain),
#                    image_file.png (image/png), page.html (text/html),
#                    subdir/nested.txt (text/plain) — 3 text/plain total.
output=$("$DOC_DOC_SH" process -d "$TEST_DIR" -i "text/plain" 2>/dev/null)
exit_code=$?
assert_exit_code "process --include text/plain exits with 0" "0" "$exit_code"
assert_json_valid "process --include text/plain output is valid JSON" "$output"

file_count=$(echo "$output" | jq 'length' 2>/dev/null || echo "-1")
# Should include only text/plain files (text_file.txt, another.txt, subdir/nested.txt = 3)
TOTAL=$((TOTAL + 1))
if [ "$file_count" -gt 0 ] && [ "$file_count" -lt 5 ] 2>/dev/null; then
  echo "  PASS: --include text/plain returns only text/plain files ($file_count found)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: --include text/plain should return only text/plain files, got $file_count files"
  FAIL=$((FAIL + 1))
fi

# PNG must NOT appear in output
assert_not_contains "--include text/plain excludes image_file.png" "image_file.png" "$output"

# All output entries must have mimeType = text/plain
TOTAL=$((TOTAL + 1))
non_plain_count=$(echo "$output" | jq '[.[] | select(.mimeType != "text/plain")] | length' 2>/dev/null || echo "0")
if [ "$non_plain_count" = "0" ]; then
  echo "  PASS: all included files have mimeType text/plain"
  PASS=$((PASS + 1))
else
  echo "  FAIL: found $non_plain_count non-text/plain entries in --include text/plain output"
  echo "    Output: $output"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "--- Integration: MIME exclude filter — image/png ---"

# All files except image/png should appear.
output=$("$DOC_DOC_SH" process -d "$TEST_DIR" -e "image/png" 2>/dev/null)
exit_code=$?
assert_exit_code "process --exclude image/png exits with 0" "0" "$exit_code"

# PNG must NOT be in the output
assert_not_contains "--exclude image/png skips image_file.png" "image_file.png" "$output"

# text files must still be in output
assert_contains "--exclude image/png keeps text_file.txt" "text_file.txt" "$output"

# Count: total files in TEST_DIR minus the 1 png = should be at least 4
non_png_count=$(echo "$output" | jq 'length' 2>/dev/null || echo "0")
TOTAL=$((TOTAL + 1))
if [ "$non_png_count" -ge 4 ] 2>/dev/null; then
  echo "  PASS: --exclude image/png returns all non-PNG files ($non_png_count)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: --exclude image/png should return >=4 files, got $non_png_count"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "--- Integration: MIME include filter — image/* glob ---"

# Only image/* files should appear (just image_file.png in test dir).
output=$("$DOC_DOC_SH" process -d "$TEST_DIR" -i "image/*" 2>/dev/null)
exit_code=$?
assert_exit_code "process --include image/* exits with 0" "0" "$exit_code"

file_count=$(echo "$output" | jq 'length' 2>/dev/null || echo "0")
assert_eq "--include image/* returns exactly 1 file (the PNG)" "1" "$file_count"

assert_contains "--include image/* keeps image_file.png" "image_file.png" "$output"
assert_not_contains "--include image/* excludes text_file.txt" "text_file.txt" "$output"

echo ""
echo "--- Integration: MIME exclude filter — text/* glob ---"

# All text/* files should be skipped; only non-text files remain.
output=$("$DOC_DOC_SH" process -d "$TEST_DIR" -e "text/*" 2>/dev/null)
exit_code=$?
assert_exit_code "process --exclude text/* exits with 0" "0" "$exit_code"

assert_not_contains "--exclude text/* skips text_file.txt" "text_file.txt" "$output"
assert_not_contains "--exclude text/* skips another.txt" "another.txt" "$output"
assert_contains "--exclude text/* keeps image_file.png" "image_file.png" "$output"

# Only image/png should remain
file_count=$(echo "$output" | jq 'length' 2>/dev/null || echo "0")
assert_eq "--exclude text/* returns only non-text files (1 PNG)" "1" "$file_count"

echo ""
echo "--- Integration: MIME include with OR — text/plain,image/png ---"

# text/plain OR image/png should include both text files and the PNG.
output=$("$DOC_DOC_SH" process -d "$TEST_DIR" -i "text/plain,image/png" 2>/dev/null)
exit_code=$?
assert_exit_code "process --include text/plain,image/png exits with 0" "0" "$exit_code"

assert_contains "--include text/plain,image/png keeps text_file.txt" "text_file.txt" "$output"
assert_contains "--include text/plain,image/png keeps image_file.png" "image_file.png" "$output"

# page.html (text/html) should NOT be included (not text/plain and not image/png)
assert_not_contains "--include text/plain,image/png excludes page.html" "page.html" "$output"

echo ""
echo "--- Integration: skipped files produce no output entry ---"

# When a file is MIME-filtered out, it must not appear in the JSON output at all.
output=$("$DOC_DOC_SH" process -d "$TEST_DIR" -i "image/png" 2>/dev/null)

# image_file.png should be present
assert_contains "skipped files absent: image_file.png present" "image_file.png" "$output"

# text files must be completely absent (no partial entries)
assert_not_contains "skipped files absent: text_file.txt not in output" "text_file.txt" "$output"
assert_not_contains "skipped files absent: another.txt not in output" "another.txt" "$output"
assert_not_contains "skipped files absent: nested.txt not in output" "nested.txt" "$output"

# Output must be a valid, complete JSON array
assert_json_valid "output with MIME filter is valid JSON array" "$output"

echo ""
echo "--- Integration: no MIME criteria — backward compatibility ---"

# Without MIME criteria, all files are processed as before (no filtering by MIME).
output=$("$DOC_DOC_SH" process -d "$TEST_DIR" 2>/dev/null)
exit_code=$?
assert_exit_code "process without MIME filter exits with 0" "0" "$exit_code"

file_count=$(echo "$output" | jq 'length' 2>/dev/null || echo "0")
# Should return all 5 files: text_file.txt, another.txt, image_file.png, page.html, subdir/nested.txt
assert_eq "no MIME filter processes all 5 files" "5" "$file_count"

echo ""
echo "--- Integration: extension filter still works alongside MIME criteria ---"

# Extension-based filter must still work unchanged alongside MIME filter gate.
output=$("$DOC_DOC_SH" process -d "$TEST_DIR" -i ".txt" 2>/dev/null)
exit_code=$?
assert_exit_code "extension filter -i .txt exits with 0" "0" "$exit_code"

file_count=$(echo "$output" | jq 'length' 2>/dev/null || echo "0")
# .txt files: text_file.txt, another.txt, subdir/nested.txt = 3
assert_eq "extension filter -i .txt returns 3 txt files" "3" "$file_count"

assert_not_contains "extension filter -i .txt excludes image_file.png" "image_file.png" "$output"
assert_not_contains "extension filter -i .txt excludes page.html" "page.html" "$output"

echo ""
echo "--- Integration: MIME filter returns empty array when no files match ---"

# No files in test dir have MIME type application/pdf → returns [].
output=$("$DOC_DOC_SH" process -d "$TEST_DIR" -i "application/pdf" 2>/dev/null)
exit_code=$?
assert_exit_code "process --include application/pdf (no matches) exits with 0" "0" "$exit_code"
assert_eq "--include application/pdf with no matching files returns []" "[]" "$output"

# ---- Summary ----

echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
