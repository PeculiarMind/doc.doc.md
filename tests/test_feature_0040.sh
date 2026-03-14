#!/bin/bash
# Test suite for FEATURE_0040: Full Mustache Template Support via Python
# TDD: These tests define the contract BEFORE implementation.
# Run from repository root: bash tests/test_feature_0040.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MUSTACHE_PY="$REPO_ROOT/doc.doc.md/components/mustache_render.py"
TEMPLATES_SH="$REPO_ROOT/doc.doc.md/components/templates.sh"
DEFAULT_TEMPLATE="$REPO_ROOT/doc.doc.md/templates/default.md"

PASS=0
FAIL=0
TOTAL=0

TMPDIR_TEST=""

cleanup() {
  [ -n "$TMPDIR_TEST" ] && [ -d "$TMPDIR_TEST" ] && rm -rf "$TMPDIR_TEST"
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
    echo "    Actual: $(echo "$actual" | head -3)"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local test_name="$1" unwanted="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$unwanted"; then
    echo "  FAIL: $test_name"
    echo "    Should not contain: $unwanted"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

echo "============================================"
echo "  FEATURE_0040: Full Mustache Template"
echo "  Support via Python"
echo "============================================"
echo ""

TMPDIR_TEST=$(mktemp -d)

# =========================================
# Group 1: mustache_render.py exists and is executable
# =========================================
echo "--- Group 1: mustache_render.py exists and is executable ---"

TOTAL=$((TOTAL + 1))
if [ -f "$MUSTACHE_PY" ]; then
  echo "  PASS: mustache_render.py exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: mustache_render.py not found at $MUSTACHE_PY"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if [ -x "$MUSTACHE_PY" ]; then
  echo "  PASS: mustache_render.py is executable"
  PASS=$((PASS + 1))
else
  echo "  FAIL: mustache_render.py is not executable"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: Basic variable substitution
# =========================================
echo ""
echo "--- Group 2: Basic variable substitution ---"

# 2a: Simple variable replacement
TPL_BASIC="$TMPDIR_TEST/basic.mustache"
echo -n 'Hello {{name}}!' > "$TPL_BASIC"

output=""
exit_code=0
output=$(python3 "$MUSTACHE_PY" "$TPL_BASIC" '{"name":"World"}' 2>/dev/null) || exit_code=$?
assert_exit_code "basic substitution exits 0" "0" "$exit_code"
assert_eq "basic substitution renders correctly" "Hello World!" "$output"

# 2b: HTML entities are escaped by default
TPL_ESCAPE="$TMPDIR_TEST/escape.mustache"
echo -n '{{value}}' > "$TPL_ESCAPE"

output=""
exit_code=0
output=$(python3 "$MUSTACHE_PY" "$TPL_ESCAPE" '{"value":"<b>bold</b>"}' 2>/dev/null) || exit_code=$?
assert_exit_code "escaped variable exits 0" "0" "$exit_code"
assert_contains "HTML angle brackets are escaped" "&lt;" "$output"
assert_not_contains "raw < not present in escaped output" "<b>" "$output"

# 2c: Triple-brace unescaped variables
TPL_UNESCAPED="$TMPDIR_TEST/unescaped.mustache"
echo -n '{{{value}}}' > "$TPL_UNESCAPED"

output=""
exit_code=0
output=$(python3 "$MUSTACHE_PY" "$TPL_UNESCAPED" '{"value":"<b>bold</b>"}' 2>/dev/null) || exit_code=$?
assert_exit_code "unescaped variable exits 0" "0" "$exit_code"
assert_contains "triple-brace renders raw HTML" "<b>bold</b>" "$output"

# =========================================
# Group 3: Sections and inverted sections
# =========================================
echo ""
echo "--- Group 3: Sections and inverted sections ---"

# 3a: Truthy section rendered
TPL_SECTION="$TMPDIR_TEST/section.mustache"
echo -n '{{#section}}shown{{/section}}' > "$TPL_SECTION"

output=""
exit_code=0
output=$(python3 "$MUSTACHE_PY" "$TPL_SECTION" '{"section":true}' 2>/dev/null) || exit_code=$?
assert_exit_code "truthy section exits 0" "0" "$exit_code"
assert_eq "truthy section renders content" "shown" "$output"

# 3b: Falsy section hidden
output=""
exit_code=0
output=$(python3 "$MUSTACHE_PY" "$TPL_SECTION" '{"section":false}' 2>/dev/null) || exit_code=$?
assert_exit_code "falsy section exits 0" "0" "$exit_code"
assert_eq "falsy section renders empty" "" "$output"

# 3c: Inverted section with falsy value
TPL_INVERTED="$TMPDIR_TEST/inverted.mustache"
echo -n '{{^section}}shown{{/section}}' > "$TPL_INVERTED"

output=""
exit_code=0
output=$(python3 "$MUSTACHE_PY" "$TPL_INVERTED" '{"section":false}' 2>/dev/null) || exit_code=$?
assert_exit_code "inverted section exits 0" "0" "$exit_code"
assert_eq "inverted section renders when falsy" "shown" "$output"

# 3d: Array loop
TPL_LOOP="$TMPDIR_TEST/loop.mustache"
echo -n '{{#items}}{{.}},{{/items}}' > "$TPL_LOOP"

output=""
exit_code=0
output=$(python3 "$MUSTACHE_PY" "$TPL_LOOP" '{"items":["a","b","c"]}' 2>/dev/null) || exit_code=$?
assert_exit_code "array loop exits 0" "0" "$exit_code"
assert_eq "array loop renders items" "a,b,c," "$output"

# =========================================
# Group 4: Comments
# =========================================
echo ""
echo "--- Group 4: Comments ---"

TPL_COMMENT="$TMPDIR_TEST/comment.mustache"
echo -n 'before{{! this is a comment}}after' > "$TPL_COMMENT"

output=""
exit_code=0
output=$(python3 "$MUSTACHE_PY" "$TPL_COMMENT" '{}' 2>/dev/null) || exit_code=$?
assert_exit_code "comment template exits 0" "0" "$exit_code"
assert_eq "comment is omitted from output" "beforeafter" "$output"

# =========================================
# Group 5: fileName derivation from filePath
# =========================================
echo ""
echo "--- Group 5: fileName derivation ---"

TPL_FILENAME="$TMPDIR_TEST/filename.mustache"
echo -n 'Name: {{fileName}}' > "$TPL_FILENAME"

output=""
exit_code=0
output=$(python3 "$MUSTACHE_PY" "$TPL_FILENAME" '{"filePath":"/path/to/file.txt"}' 2>/dev/null) || exit_code=$?
assert_exit_code "fileName derivation exits 0" "0" "$exit_code"
assert_eq "fileName derived from filePath" "Name: file.txt" "$output"

# Verify filePath itself still works alongside derived fileName
TPL_BOTH="$TMPDIR_TEST/both.mustache"
echo -n '{{fileName}} at {{filePath}}' > "$TPL_BOTH"

output=""
exit_code=0
output=$(python3 "$MUSTACHE_PY" "$TPL_BOTH" '{"filePath":"/path/to/file.txt"}' 2>/dev/null) || exit_code=$?
assert_exit_code "fileName + filePath exits 0" "0" "$exit_code"
assert_eq "fileName and filePath both render" "file.txt at /path/to/file.txt" "$output"

# =========================================
# Group 6: Error handling
# =========================================
echo ""
echo "--- Group 6: Error handling ---"

# 6a: Missing template file exits 1
exit_code=0
python3 "$MUSTACHE_PY" "$TMPDIR_TEST/nonexistent.mustache" '{}' >/dev/null 2>&1 || exit_code=$?
assert_exit_code "missing template file exits 1" "1" "$exit_code"

# 6b: Invalid JSON exits 1
TPL_ERR="$TMPDIR_TEST/err.mustache"
echo -n 'test' > "$TPL_ERR"

exit_code=0
python3 "$MUSTACHE_PY" "$TPL_ERR" '{invalid json}' >/dev/null 2>&1 || exit_code=$?
assert_exit_code "invalid JSON exits 1" "1" "$exit_code"

# 6c: Missing chevron library — skipped (hard to simulate without altering Python env)
echo "  SKIP: missing chevron library (cannot safely simulate)"

# =========================================
# Group 7: render_template_json integration
# =========================================
echo ""
echo "--- Group 7: render_template_json integration ---"

TEST_JSON='{"filePath":"/docs/readme.txt","fileSize":"1234","fileOwner":"user1","fileCreated":"2025-01-01","fileModified":"2025-06-01","fileMetadataChanged":"2025-06-01","mimeType":"text/plain","documentText":"Hello world","ocrText":""}'

# 7a: Source templates.sh and call render_template_json with default template
output=""
exit_code=0
output=$(source "$TEMPLATES_SH" && render_template_json "$DEFAULT_TEMPLATE" "$TEST_JSON" 2>/dev/null) || exit_code=$?
assert_exit_code "render_template_json exits 0" "0" "$exit_code"

# 7b: Verify output contains expected rendered values
assert_contains "output contains fileName" "readme.txt" "$output"
assert_contains "output contains filePath" "/docs/readme.txt" "$output"
assert_contains "output contains fileSize" "1234" "$output"
assert_contains "output contains fileOwner" "user1" "$output"
assert_contains "output contains mimeType" "text/plain" "$output"
assert_contains "output contains documentText" "Hello world" "$output"

# 7c: Verify no unresolved placeholders remain
assert_not_contains "no unresolved {{fileName}}" "{{fileName}}" "$output"
assert_not_contains "no unresolved {{filePath}}" "{{filePath}}" "$output"
assert_not_contains "no unresolved {{fileSize}}" "{{fileSize}}" "$output"
assert_not_contains "no unresolved {{fileOwner}}" "{{fileOwner}}" "$output"
assert_not_contains "no unresolved {{mimeType}}" "{{mimeType}}" "$output"
assert_not_contains "no unresolved {{documentText}}" "{{documentText}}" "$output"

# 7d: Backward compatibility — compare with legacy bash substitution
# Reconstruct what the old bash implementation would produce
legacy_output=""
legacy_exit=0
legacy_render() {
  local template="$1"
  local result_json="$2"
  local content
  content="$(cat "$template")"
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    local val
    val="$(echo "$result_json" | jq -r --arg k "$key" '.[$k] // empty')"
    content="${content//\{\{${key}\}\}/${val}}"
  done < <(echo "$result_json" | jq -r 'keys[]')
  local fp
  fp=$(echo "$result_json" | jq -r '.filePath // empty')
  if [ -n "$fp" ]; then
    local fname
    fname="$(basename "$fp")"
    content="${content//\{\{fileName\}\}/${fname}}"
  fi
  printf '%s' "$content"
}
legacy_output=$(legacy_render "$DEFAULT_TEMPLATE" "$TEST_JSON") || legacy_exit=$?
assert_eq "backward compatible with legacy bash render" "$legacy_output" "$output"

# =========================================
# Group 8: No eval/exec in template content
# =========================================
echo ""
echo "--- Group 8: No eval/exec in mustache_render.py ---"

TOTAL=$((TOTAL + 1))
if [ -f "$MUSTACHE_PY" ]; then
  if grep -qE 'eval\(|exec\(' "$MUSTACHE_PY"; then
    echo "  FAIL: mustache_render.py contains eval( or exec("
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: mustache_render.py does not use eval() or exec()"
    PASS=$((PASS + 1))
  fi
else
  echo "  FAIL: mustache_render.py not found — cannot check for eval/exec"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed (total: $TOTAL)"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
