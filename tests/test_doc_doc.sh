#!/bin/bash
# Test suite for doc.doc.sh CLI and filter engine (FEATURE_0001)
# Run from repository root: bash tests/test_doc_doc.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOC_DOC_SH="$REPO_ROOT/doc.doc.sh"
FILTER_PY="$REPO_ROOT/doc.doc.md/components/filter.py"

PASS=0
FAIL=0
TOTAL=0

# Cleanup trap
cleanup() {
  if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
    chmod -R u+rw "$TEST_DIR" 2>/dev/null || true
    rm -rf "$TEST_DIR"
  fi
}
trap cleanup EXIT

# Test helper functions
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

# Setup: create test directory structure
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/2024" "$TEST_DIR/2025" "$TEST_DIR/temp"
echo "Hello, World!" > "$TEST_DIR/2024/doc.txt"
echo '{"key": "value"}' > "$TEST_DIR/2025/data.json"
echo "report content" > "$TEST_DIR/2025/report.pdf"
echo "log entry" > "$TEST_DIR/temp/debug.log"
echo "csv data" > "$TEST_DIR/data.csv"
touch "$TEST_DIR/empty.txt"

echo "============================================"
echo "  FEATURE_0001 Test Suite"
echo "============================================"
echo ""

# =========================================
# CLI entry point tests
# =========================================
echo "--- CLI: --help ---"

output=$("$DOC_DOC_SH" --help 2>&1)
exit_code=$?
assert_exit_code "--help exits with 0" "0" "$exit_code"
assert_contains "--help shows usage" "Usage:" "$output"
assert_contains "--help shows process command" "process" "$output"
assert_contains "--help shows -d option" "-d" "$output"
assert_contains "--help shows -i option" "-i" "$output"
assert_contains "--help shows -e option" "-e" "$output"

echo ""
echo "--- CLI: no arguments ---"

output=$("$DOC_DOC_SH" 2>&1)
exit_code=$?
assert_exit_code "no args exits with 0 (shows help)" "0" "$exit_code"
assert_contains "no args shows usage" "Usage:" "$output"

echo ""
echo "--- CLI: invalid command ---"

output=$("$DOC_DOC_SH" invalid 2>&1)
exit_code=$?
assert_exit_code "invalid command exits with 1" "1" "$exit_code"
assert_contains "invalid command shows error" "Unknown command" "$output"

echo ""
echo "--- CLI: process without -d ---"

output=$("$DOC_DOC_SH" process 2>&1)
exit_code=$?
assert_exit_code "process without -d exits with 1" "1" "$exit_code"
assert_contains "missing -d shows error" "Input directory is required" "$output"

echo ""
echo "--- CLI: non-existent directory ---"

output=$("$DOC_DOC_SH" process -d /nonexistent/dir 2>&1)
exit_code=$?
assert_exit_code "non-existent dir exits with 1" "1" "$exit_code"
assert_contains "non-existent dir shows error" "does not exist" "$output"

echo ""
echo "--- CLI: unknown option ---"

output=$("$DOC_DOC_SH" process -d "$TEST_DIR" --unknown 2>&1)
exit_code=$?
assert_exit_code "unknown option exits with 1" "1" "$exit_code"
assert_contains "unknown option shows error" "Unknown option" "$output"

echo ""
echo "--- CLI: process --help ---"

output=$("$DOC_DOC_SH" process --help 2>&1)
exit_code=$?
assert_exit_code "process --help exits with 0" "0" "$exit_code"
assert_contains "process --help shows usage" "Usage:" "$output"

# =========================================
# Filter engine tests
# =========================================
echo ""
echo "--- Filter: no filters (all pass) ---"

output=$(printf '/path/to/file.txt\n/path/to/image.png\n' | python3 "$FILTER_PY")
expected=$(printf '/path/to/file.txt\n/path/to/image.png')
assert_eq "no filters passes all files" "$expected" "$output"

echo ""
echo "--- Filter: include extension ---"

output=$(printf '/path/file.txt\n/path/file.pdf\n/path/file.log\n' | python3 "$FILTER_PY" --include ".txt,.pdf")
expected=$(printf '/path/file.txt\n/path/file.pdf')
assert_eq "include .txt,.pdf filters correctly" "$expected" "$output"

echo ""
echo "--- Filter: include glob pattern ---"

output=$(printf '/docs/2024/file.txt\n/docs/2025/file.txt\n' | python3 "$FILTER_PY" --include "**/2024/**")
expected="/docs/2024/file.txt"
assert_eq "include glob **/2024/** filters correctly" "$expected" "$output"

echo ""
echo "--- Filter: AND between include params ---"

output=$(printf '/docs/2024/doc.txt\n/docs/2024/doc.pdf\n/docs/2025/doc.txt\n' | python3 "$FILTER_PY" --include ".txt" --include "**/2024/**")
expected="/docs/2024/doc.txt"
assert_eq "AND between includes: .txt AND **/2024/**" "$expected" "$output"

echo ""
echo "--- Filter: exclude extension ---"

output=$(printf '/path/file.txt\n/path/file.log\n/path/file.pdf\n' | python3 "$FILTER_PY" --exclude ".log")
expected=$(printf '/path/file.txt\n/path/file.pdf')
assert_eq "exclude .log filters correctly" "$expected" "$output"

echo ""
echo "--- Filter: exclude glob ---"

output=$(printf '/path/file.txt\n/temp/file.txt\n' | python3 "$FILTER_PY" --exclude "**/temp/**")
expected="/path/file.txt"
assert_eq "exclude glob **/temp/** works" "$expected" "$output"

echo ""
echo "--- Filter: AND between exclude params ---"

output=$(printf '/temp/debug.log\n/temp/data.csv\n/docs/debug.log\n/docs/data.csv\n' | python3 "$FILTER_PY" --exclude ".log" --exclude "**/temp/**")
# Only excluded if matches BOTH: .log AND in temp dir
# /temp/debug.log matches both -> excluded
# /temp/data.csv matches temp but not .log -> NOT excluded
# /docs/debug.log matches .log but not temp -> NOT excluded
# /docs/data.csv matches neither -> NOT excluded
expected=$(printf '/temp/data.csv\n/docs/debug.log\n/docs/data.csv')
assert_eq "AND between excludes: .log AND **/temp/**" "$expected" "$output"

echo ""
echo "--- Filter: include and exclude combined ---"

output=$(printf '/path/file.txt\n/path/file.log\n/path/file.pdf\n' | python3 "$FILTER_PY" --include ".txt,.log" --exclude ".log")
expected="/path/file.txt"
assert_eq "include .txt,.log exclude .log keeps only .txt" "$expected" "$output"

echo ""
echo "--- Filter: empty input ---"

output=$(echo "" | python3 "$FILTER_PY")
assert_eq "empty input produces empty output" "" "$output"

# =========================================
# Integration tests: process command
# =========================================
echo ""
echo "--- Integration: process all files ---"

output=$("$DOC_DOC_SH" process -d "$TEST_DIR" 2>/dev/null)
exit_code=$?
assert_exit_code "process exits with 0" "0" "$exit_code"

# Validate output is valid JSON array
TOTAL=$((TOTAL + 1))
if echo "$output" | jq empty 2>/dev/null; then
  echo "  PASS: output is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: output is NOT valid JSON"
  FAIL=$((FAIL + 1))
fi

# Count processed files (should be 6: doc.txt, data.json, report.pdf, debug.log, data.csv, empty.txt)
file_count=$(echo "$output" | jq 'length')
assert_eq "processes all 6 files" "6" "$file_count"

echo ""
echo "--- Integration: JSON output has required fields ---"

first_entry=$(echo "$output" | jq '.[0]')
# Check that combined output has filePath, fileSize, fileOwner, fileModified, fileMetadataChanged, mimeType
for field in filePath fileSize fileOwner fileModified fileMetadataChanged mimeType; do
  TOTAL=$((TOTAL + 1))
  if echo "$first_entry" | jq -e ".$field" >/dev/null 2>&1; then
    echo "  PASS: output contains $field"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: output missing $field"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "--- Integration: process with include filter ---"

output=$("$DOC_DOC_SH" process -d "$TEST_DIR" -i ".txt" 2>/dev/null)
file_count=$(echo "$output" | jq 'length')
assert_eq "include .txt returns 2 files" "2" "$file_count"

echo ""
echo "--- Integration: process with exclude filter ---"

output=$("$DOC_DOC_SH" process -d "$TEST_DIR" -e ".log" 2>/dev/null)
file_count=$(echo "$output" | jq 'length')
assert_eq "exclude .log returns 5 files" "5" "$file_count"

echo ""
echo "--- Integration: process with AND include filters ---"

output=$("$DOC_DOC_SH" process -d "$TEST_DIR" -i ".txt" -i "**/2024/**" 2>/dev/null)
file_count=$(echo "$output" | jq 'length')
assert_eq "include .txt AND **/2024/** returns 1 file" "1" "$file_count"

first_path=$(echo "$output" | jq -r '.[0].filePath')
assert_contains "filtered result is 2024/doc.txt" "2024/doc.txt" "$first_path"

echo ""
echo "--- Integration: empty dir returns empty array ---"

empty_dir=$(mktemp -d)
output=$("$DOC_DOC_SH" process -d "$empty_dir" 2>/dev/null)
exit_code=$?
rmdir "$empty_dir"
assert_exit_code "empty dir exits with 0" "0" "$exit_code"
assert_eq "empty dir returns []" "[]" "$output"

echo ""
echo "--- Integration: filter returns no matches ---"

output=$("$DOC_DOC_SH" process -d "$TEST_DIR" -i ".xyz" 2>/dev/null)
exit_code=$?
assert_exit_code "no matches exits with 0" "0" "$exit_code"
assert_eq "no matches returns []" "[]" "$output"

# =========================================
# Script properties
# =========================================
echo ""
echo "--- Script properties ---"

TOTAL=$((TOTAL + 1))
if [ -x "$DOC_DOC_SH" ]; then
  echo "  PASS: doc.doc.sh is executable"
  PASS=$((PASS + 1))
else
  echo "  FAIL: doc.doc.sh is NOT executable"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
first_line=$(head -1 "$DOC_DOC_SH")
if [ "$first_line" = "#!/bin/bash" ]; then
  echo "  PASS: doc.doc.sh has #!/bin/bash shebang"
  PASS=$((PASS + 1))
else
  echo "  FAIL: doc.doc.sh shebang is '$first_line'"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if [ -f "$FILTER_PY" ]; then
  echo "  PASS: filter.py exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: filter.py not found"
  FAIL=$((FAIL + 1))
fi

# Summary
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
