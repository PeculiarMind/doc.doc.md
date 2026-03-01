#!/bin/bash
# Test suite for stat and file plugins (FEATURE_0002)
# Run from repository root: bash tests/test_plugins.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STAT_DIR="$REPO_ROOT/doc.doc.md/plugins/stat"
FILE_DIR="$REPO_ROOT/doc.doc.md/plugins/file"

PASS=0
FAIL=0
TOTAL=0

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

assert_json_field() {
  local test_name="$1"
  local json="$2"
  local field="$3"
  local expected="$4"
  local actual
  actual=$(echo "$json" | jq -r ".$field")
  assert_eq "$test_name" "$expected" "$actual"
}

assert_json_field_type() {
  local test_name="$1"
  local json="$2"
  local field="$3"
  local expected_type="$4"
  local actual_type
  actual_type=$(echo "$json" | jq -r ".$field | type")
  assert_eq "$test_name" "$expected_type" "$actual_type"
}

# Setup: create test files
TEST_DIR=$(mktemp -d)
echo "Hello, World!" > "$TEST_DIR/test.txt"
echo '{"key": "value"}' > "$TEST_DIR/test.json"
# Minimal valid PNG (1x1 pixel, white)
printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82' > "$TEST_DIR/test.png"
touch "$TEST_DIR/empty.txt"

echo "============================================"
echo "  FEATURE_0002 Plugin Test Suite"
echo "============================================"
echo ""

# =========================================
# stat plugin tests
# =========================================
echo "--- stat plugin: installed.sh ---"

output=$("$STAT_DIR/installed.sh")
exit_code=$?
assert_exit_code "installed.sh exits with 0" "0" "$exit_code"
assert_json_field "installed.sh returns installed=true" "$output" "installed" "true"
assert_json_field_type "installed.sh installed is boolean" "$output" "installed" "boolean"

echo ""
echo "--- stat plugin: install.sh ---"

output=$("$STAT_DIR/install.sh")
exit_code=$?
assert_exit_code "install.sh exits with 0" "0" "$exit_code"
assert_json_field "install.sh returns success=true" "$output" "success" "true"
assert_json_field_type "install.sh success is boolean" "$output" "success" "boolean"
assert_json_field "install.sh returns correct message" "$output" "message" "stat command already available"

echo ""
echo "--- stat plugin: main.sh (valid input) ---"

output=$(echo "{\"filePath\":\"$TEST_DIR/test.txt\"}" | "$STAT_DIR/main.sh")
exit_code=$?
assert_exit_code "main.sh exits with 0 for valid file" "0" "$exit_code"
assert_json_field_type "fileSize is number" "$output" "fileSize" "number"
assert_json_field_type "fileOwner is string" "$output" "fileOwner" "string"
assert_json_field_type "fileModified is string" "$output" "fileModified" "string"
assert_json_field_type "fileMetadataChanged is string" "$output" "fileMetadataChanged" "string"
# Verify fileSize is correct (14 bytes: "Hello, World!\n")
assert_json_field "fileSize is correct" "$output" "fileSize" "14"

echo ""
echo "--- stat plugin: main.sh (error cases) ---"

# Missing filePath
output=$(echo '{}' | "$STAT_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "main.sh exits with 1 for missing filePath" "1" "$exit_code"

# Non-existent file
output=$(echo '{"filePath":"/nonexistent/file.txt"}' | "$STAT_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "main.sh exits with 1 for non-existent file" "1" "$exit_code"

# Malformed JSON
output=$(echo 'not json' | "$STAT_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "main.sh exits with 1 for malformed JSON" "1" "$exit_code"

# Empty input
output=$(echo '' | "$STAT_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "main.sh exits with 1 for empty input" "1" "$exit_code"

# Unreadable file
unreadable="$TEST_DIR/unreadable.txt"
touch "$unreadable" && chmod 000 "$unreadable"
output=$(echo "{\"filePath\":\"$unreadable\"}" | "$STAT_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "main.sh exits with 1 for unreadable file" "1" "$exit_code"
chmod 644 "$unreadable"

# =========================================
# file plugin tests
# =========================================
echo ""
echo "--- file plugin: installed.sh ---"

output=$("$FILE_DIR/installed.sh")
exit_code=$?
assert_exit_code "installed.sh exits with 0" "0" "$exit_code"
assert_json_field "installed.sh returns installed=true" "$output" "installed" "true"
assert_json_field_type "installed.sh installed is boolean" "$output" "installed" "boolean"

echo ""
echo "--- file plugin: install.sh ---"

output=$("$FILE_DIR/install.sh")
exit_code=$?
assert_exit_code "install.sh exits with 0" "0" "$exit_code"
assert_json_field "install.sh returns success=true" "$output" "success" "true"
assert_json_field_type "install.sh success is boolean" "$output" "success" "boolean"
assert_json_field "install.sh returns correct message" "$output" "message" "file command already available"

echo ""
echo "--- file plugin: main.sh (valid input) ---"

# Text file
output=$(echo "{\"filePath\":\"$TEST_DIR/test.txt\"}" | "$FILE_DIR/main.sh")
exit_code=$?
assert_exit_code "main.sh exits with 0 for text file" "0" "$exit_code"
assert_json_field "text file mimeType is text/plain" "$output" "mimeType" "text/plain"
assert_json_field_type "mimeType is string" "$output" "mimeType" "string"

# JSON file
output=$(echo "{\"filePath\":\"$TEST_DIR/test.json\"}" | "$FILE_DIR/main.sh")
exit_code=$?
assert_exit_code "main.sh exits with 0 for json file" "0" "$exit_code"
# JSON files are detected as application/json or text/plain depending on system
actual_mime=$(echo "$output" | jq -r '.mimeType')
TOTAL=$((TOTAL + 1))
if [ "$actual_mime" = "application/json" ] || [ "$actual_mime" = "text/plain" ]; then
  echo "  PASS: json file mimeType is acceptable ($actual_mime)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: json file mimeType expected application/json or text/plain, got $actual_mime"
  FAIL=$((FAIL + 1))
fi

# PNG file
output=$(echo "{\"filePath\":\"$TEST_DIR/test.png\"}" | "$FILE_DIR/main.sh")
exit_code=$?
assert_exit_code "main.sh exits with 0 for png file" "0" "$exit_code"
assert_json_field "png file mimeType is image/png" "$output" "mimeType" "image/png"

# Empty file
output=$(echo "{\"filePath\":\"$TEST_DIR/empty.txt\"}" | "$FILE_DIR/main.sh")
exit_code=$?
assert_exit_code "main.sh exits with 0 for empty file" "0" "$exit_code"
assert_json_field_type "empty file mimeType is string" "$output" "mimeType" "string"

echo ""
echo "--- file plugin: main.sh (error cases) ---"

# Missing filePath
output=$(echo '{}' | "$FILE_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "main.sh exits with 1 for missing filePath" "1" "$exit_code"

# Non-existent file
output=$(echo '{"filePath":"/nonexistent/file.txt"}' | "$FILE_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "main.sh exits with 1 for non-existent file" "1" "$exit_code"

# Malformed JSON
output=$(echo 'not json' | "$FILE_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "main.sh exits with 1 for malformed JSON" "1" "$exit_code"

# Unreadable file
unreadable="$TEST_DIR/unreadable2.txt"
touch "$unreadable" && chmod 000 "$unreadable"
output=$(echo "{\"filePath\":\"$unreadable\"}" | "$FILE_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "main.sh exits with 1 for unreadable file" "1" "$exit_code"
chmod 644 "$unreadable"

# =========================================
# Cross-check: scripts are executable
# =========================================
echo ""
echo "--- Script permissions ---"

for script in "$STAT_DIR/main.sh" "$STAT_DIR/installed.sh" "$STAT_DIR/install.sh" \
              "$FILE_DIR/main.sh" "$FILE_DIR/installed.sh" "$FILE_DIR/install.sh"; do
  TOTAL=$((TOTAL + 1))
  if [ -x "$script" ]; then
    echo "  PASS: $(basename "$(dirname "$script")")/$(basename "$script") is executable"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $(basename "$(dirname "$script")")/$(basename "$script") is NOT executable"
    FAIL=$((FAIL + 1))
  fi
done

# =========================================
# Cross-check: scripts have correct shebang
# =========================================
echo ""
echo "--- Shebang lines ---"

for script in "$STAT_DIR/main.sh" "$STAT_DIR/installed.sh" "$STAT_DIR/install.sh" \
              "$FILE_DIR/main.sh" "$FILE_DIR/installed.sh" "$FILE_DIR/install.sh"; do
  TOTAL=$((TOTAL + 1))
  first_line=$(head -1 "$script")
  if [ "$first_line" = "#!/bin/bash" ]; then
    echo "  PASS: $(basename "$(dirname "$script")")/$(basename "$script") has #!/bin/bash shebang"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $(basename "$(dirname "$script")")/$(basename "$script") shebang is '$first_line'"
    FAIL=$((FAIL + 1))
  fi
done

# =========================================
# Cross-check: stdout is pure JSON (no non-JSON output)
# =========================================
echo ""
echo "--- JSON output validation ---"

# stat main.sh output must be valid JSON
output=$(echo "{\"filePath\":\"$TEST_DIR/test.txt\"}" | "$STAT_DIR/main.sh" 2>/dev/null)
TOTAL=$((TOTAL + 1))
if echo "$output" | jq empty 2>/dev/null; then
  echo "  PASS: stat main.sh stdout is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: stat main.sh stdout is NOT valid JSON"
  FAIL=$((FAIL + 1))
fi

# file main.sh output must be valid JSON
output=$(echo "{\"filePath\":\"$TEST_DIR/test.txt\"}" | "$FILE_DIR/main.sh" 2>/dev/null)
TOTAL=$((TOTAL + 1))
if echo "$output" | jq empty 2>/dev/null; then
  echo "  PASS: file main.sh stdout is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: file main.sh stdout is NOT valid JSON"
  FAIL=$((FAIL + 1))
fi

# Cleanup
rm -rf "$TEST_DIR"

# Summary
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
