#!/bin/bash
# Test suite for FEATURE_0046: CRM114 Text Classification Plugin
# TDD: Tests define the contract BEFORE implementation; they FAIL until the
#      plugin is implemented.
# Run from repository root: bash tests/test_feature_0046.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins/crm114"

PASS=0
FAIL=0
SKIP=0
TOTAL=0

# ---- assert helpers ----

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
    echo "    Actual: $(echo "$actual" | head -5)"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local test_name="$1" unwanted="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$unwanted"; then
    echo "  FAIL: $test_name"
    echo "    Should not contain: $unwanted"
    echo "    Actual: $(echo "$actual" | head -3)"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

assert_json_valid() {
  local test_name="$1" actual="$2"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | jq empty 2>/dev/null; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Not valid JSON: $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_exists() {
  local test_name="$1" filepath="$2"
  TOTAL=$((TOTAL + 1))
  if [ -f "$filepath" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Expected file: $filepath"
    FAIL=$((FAIL + 1))
  fi
}

assert_executable() {
  local test_name="$1" filepath="$2"
  TOTAL=$((TOTAL + 1))
  if [ -x "$filepath" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Expected executable: $filepath"
    FAIL=$((FAIL + 1))
  fi
}

skip_test() {
  local test_name="$1" reason="$2"
  TOTAL=$((TOTAL + 1))
  SKIP=$((SKIP + 1))
  echo "  SKIP: $test_name ($reason)"
}

# ---- setup/teardown ----

TEST_DIR=""
cleanup() {
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}
trap cleanup EXIT

TEST_DIR=$(mktemp -d)

# Check if crm114 is available
CRM114_AVAILABLE=false
if command -v csslearn >/dev/null 2>&1 && command -v cssunlearn >/dev/null 2>&1; then
  CRM114_AVAILABLE=true
fi

# ============================================================
# Group 1: Plugin structure validation
# ============================================================
echo ""
echo "Group 1: Plugin structure validation"
echo "---"

assert_file_exists "descriptor.json exists" "$PLUGIN_DIR/descriptor.json"
assert_file_exists "process.sh exists" "$PLUGIN_DIR/process.sh"
assert_file_exists "manageCategories.sh exists" "$PLUGIN_DIR/manageCategories.sh"
assert_file_exists "train.sh exists" "$PLUGIN_DIR/train.sh"
assert_file_exists "learn.sh exists" "$PLUGIN_DIR/learn.sh"
assert_file_exists "unlearn.sh exists" "$PLUGIN_DIR/unlearn.sh"
assert_file_exists "listCategories.sh exists" "$PLUGIN_DIR/listCategories.sh"
assert_file_exists "install.sh exists" "$PLUGIN_DIR/install.sh"
assert_file_exists "installed.sh exists" "$PLUGIN_DIR/installed.sh"

assert_executable "process.sh is executable" "$PLUGIN_DIR/process.sh"
assert_executable "manageCategories.sh is executable" "$PLUGIN_DIR/manageCategories.sh"
assert_executable "train.sh is executable" "$PLUGIN_DIR/train.sh"
assert_executable "learn.sh is executable" "$PLUGIN_DIR/learn.sh"
assert_executable "unlearn.sh is executable" "$PLUGIN_DIR/unlearn.sh"
assert_executable "listCategories.sh is executable" "$PLUGIN_DIR/listCategories.sh"
assert_executable "install.sh is executable" "$PLUGIN_DIR/install.sh"
assert_executable "installed.sh is executable" "$PLUGIN_DIR/installed.sh"

# Descriptor is valid JSON
if [ -f "$PLUGIN_DIR/descriptor.json" ]; then
  desc_valid=$(jq empty "$PLUGIN_DIR/descriptor.json" 2>&1)
  assert_eq "descriptor.json is valid JSON" "" "$desc_valid"

  assert_eq "plugin name is crm114" \
    "crm114" \
    "$(jq -r '.name' "$PLUGIN_DIR/descriptor.json")"

  assert_eq "plugin is active" \
    "true" \
    "$(jq -r '.active' "$PLUGIN_DIR/descriptor.json")"

  # All required commands are registered
  for cmd in process manageCategories train learn unlearn listCategories install installed; do
    assert_eq "command '$cmd' registered in descriptor" \
      "true" \
      "$(jq -r --arg c "$cmd" 'if .commands[$c] then "true" else "false" end' "$PLUGIN_DIR/descriptor.json")"
  done

  # manageCategories and train are marked interactive
  assert_eq "manageCategories is interactive" \
    "true" \
    "$(jq -r '.commands.manageCategories.interactive // false | tostring' "$PLUGIN_DIR/descriptor.json")"

  assert_eq "train is interactive" \
    "true" \
    "$(jq -r '.commands.train.interactive // false | tostring' "$PLUGIN_DIR/descriptor.json")"

  # process, learn, unlearn, listCategories are NOT interactive
  for cmd in process learn unlearn listCategories install installed; do
    assert_eq "command '$cmd' is not interactive" \
      "false" \
      "$(jq -r --arg c "$cmd" '.commands[$c].interactive // false | tostring' "$PLUGIN_DIR/descriptor.json")"
  done
fi

# ============================================================
# Group 2: installed.sh — availability check
# ============================================================
echo ""
echo "Group 2: installed.sh"
echo "---"

if [ -x "$PLUGIN_DIR/installed.sh" ]; then
  out=$(bash "$PLUGIN_DIR/installed.sh" 2>&1)
  ec=$?
  assert_exit_code "installed.sh always exits 0" 0 "$ec"
  assert_json_valid "installed.sh returns valid JSON" "$out"
  assert_contains "installed.sh has 'installed' field" '"installed"' "$out"
  installed_val=$(echo "$out" | jq -r 'if .installed == false then "false" else "true" end' 2>/dev/null)
  assert_eq "installed field is boolean (true or false)" \
    "true" \
    "$([ "$installed_val" = "true" ] || [ "$installed_val" = "false" ] && echo "true" || echo "false")"
fi

# ============================================================
# Group 3: install.sh — install command
# ============================================================
echo ""
echo "Group 3: install.sh"
echo "---"

if [ -x "$PLUGIN_DIR/install.sh" ]; then
  out=$(bash "$PLUGIN_DIR/install.sh" 2>&1)
  ec=$?
  assert_json_valid "install.sh returns valid JSON" "$out"
  assert_contains "install.sh has 'success' field" '"success"' "$out"
  assert_contains "install.sh has 'message' field" '"message"' "$out"
fi

# ============================================================
# Group 4: listCategories.sh
# ============================================================
echo ""
echo "Group 4: listCategories.sh"
echo "---"

STORAGE_DIR="$TEST_DIR/storage"
mkdir -p "$STORAGE_DIR"

# Empty storage: returns empty array
out=$(echo '{"pluginStorage": "'"$STORAGE_DIR"'"}' | bash "$PLUGIN_DIR/listCategories.sh" 2>&1)
ec=$?
assert_exit_code "listCategories exits 0 with no models" 0 "$ec"
assert_json_valid "listCategories returns valid JSON" "$out"
assert_eq "listCategories returns empty array when no models" \
  "[]" \
  "$(echo "$out" | jq -r '.categories | tostring')"

# With CSS files present
touch "$STORAGE_DIR/news.css" "$STORAGE_DIR/sport.css" "$STORAGE_DIR/other.css"
out=$(echo '{"pluginStorage": "'"$STORAGE_DIR"'"}' | bash "$PLUGIN_DIR/listCategories.sh" 2>&1)
ec=$?
assert_exit_code "listCategories exits 0 with models present" 0 "$ec"
assert_json_valid "listCategories returns valid JSON with models" "$out"
cats_count=$(echo "$out" | jq '.categories | length')
assert_eq "listCategories returns 3 categories" "3" "$cats_count"
assert_contains "listCategories includes 'news'" '"news"' "$out"
assert_contains "listCategories includes 'sport'" '"sport"' "$out"

# Missing pluginStorage field
out=$(echo '{}' | bash "$PLUGIN_DIR/listCategories.sh" 2>&1)
ec=$?
assert_exit_code "listCategories exits 1 with missing pluginStorage" 1 "$ec"

# Path traversal in pluginStorage
out=$(echo '{"pluginStorage": "/tmp/../etc"}' | bash "$PLUGIN_DIR/listCategories.sh" 2>&1)
ec=$?
assert_exit_code "listCategories rejects path traversal in pluginStorage" 1 "$ec"

# Non-existent pluginStorage returns empty array (not an error)
out=$(echo '{"pluginStorage": "'"$TEST_DIR/nonexistent"'"}' | bash "$PLUGIN_DIR/listCategories.sh" 2>&1)
ec=$?
assert_exit_code "listCategories exits 0 with non-existent storage dir" 0 "$ec"
cats_nonexist=$(echo "$out" | jq '.categories | length')
assert_eq "listCategories returns empty array for non-existent dir" "0" "$cats_nonexist"

# ============================================================
# Group 5: learn.sh — non-interactive learn
# ============================================================
echo ""
echo "Group 5: learn.sh"
echo "---"

LEARN_STORAGE="$TEST_DIR/learn_storage"
mkdir -p "$LEARN_STORAGE"
echo "This is test text about news" > "$TEST_DIR/test_doc.txt"

# Missing category field
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "pluginStorage": "'"$LEARN_STORAGE"'", "textContent": "test text"}' \
  | bash "$PLUGIN_DIR/learn.sh" 2>&1)
ec=$?
assert_exit_code "learn exits 1 with missing category" 1 "$ec"

# Missing pluginStorage field
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "category": "news", "textContent": "test text"}' \
  | bash "$PLUGIN_DIR/learn.sh" 2>&1)
ec=$?
assert_exit_code "learn exits 1 with missing pluginStorage" 1 "$ec"

# Missing text (no textContent or ocrText)
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "category": "news", "pluginStorage": "'"$LEARN_STORAGE"'"}' \
  | bash "$PLUGIN_DIR/learn.sh" 2>&1)
ec=$?
assert_exit_code "learn exits 1 with missing text content" 1 "$ec"

# Path traversal in category name
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "category": "../etc/passwd", "pluginStorage": "'"$LEARN_STORAGE"'", "textContent": "test"}' \
  | bash "$PLUGIN_DIR/learn.sh" 2>&1)
ec=$?
assert_exit_code "learn rejects path traversal in category name" 1 "$ec"

# Path traversal in pluginStorage
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "category": "news", "pluginStorage": "/tmp/../etc", "textContent": "test"}' \
  | bash "$PLUGIN_DIR/learn.sh" 2>&1)
ec=$?
assert_exit_code "learn rejects path traversal in pluginStorage" 1 "$ec"

# Invalid category name (shell metacharacters)
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "category": "news; rm -rf /", "pluginStorage": "'"$LEARN_STORAGE"'", "textContent": "test"}' \
  | bash "$PLUGIN_DIR/learn.sh" 2>&1)
ec=$?
assert_exit_code "learn rejects category name with metacharacters" 1 "$ec"

# Valid category name with CRM114 available
if [ "$CRM114_AVAILABLE" = "true" ]; then
  out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "category": "news", "pluginStorage": "'"$LEARN_STORAGE"'", "textContent": "This is news about sports and politics"}' \
    | bash "$PLUGIN_DIR/learn.sh" 2>&1)
  ec=$?
  assert_exit_code "learn succeeds with valid input and crm114 available" 0 "$ec"
  assert_json_valid "learn returns valid JSON on success" "$out"
  assert_eq "learn returns success true" "true" "$(echo "$out" | jq -r '.success')"
  assert_eq "learn returns category name" "news" "$(echo "$out" | jq -r '.category')"
  assert_file_exists "learn creates CSS file" "$LEARN_STORAGE/news.css"
else
  skip_test "learn succeeds with valid input" "crm114 not installed"
  skip_test "learn returns valid JSON on success" "crm114 not installed"
  skip_test "learn returns success true" "crm114 not installed"
  skip_test "learn returns category name" "crm114 not installed"
  skip_test "learn creates CSS file" "crm114 not installed"
fi

# ============================================================
# Group 6: unlearn.sh — non-interactive unlearn
# ============================================================
echo ""
echo "Group 6: unlearn.sh"
echo "---"

UNLEARN_STORAGE="$TEST_DIR/unlearn_storage"
mkdir -p "$UNLEARN_STORAGE"

# Missing category field
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "pluginStorage": "'"$UNLEARN_STORAGE"'", "textContent": "test text"}' \
  | bash "$PLUGIN_DIR/unlearn.sh" 2>&1)
ec=$?
assert_exit_code "unlearn exits 1 with missing category" 1 "$ec"

# Missing pluginStorage field
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "category": "news", "textContent": "test text"}' \
  | bash "$PLUGIN_DIR/unlearn.sh" 2>&1)
ec=$?
assert_exit_code "unlearn exits 1 with missing pluginStorage" 1 "$ec"

# Missing text
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "category": "news", "pluginStorage": "'"$UNLEARN_STORAGE"'"}' \
  | bash "$PLUGIN_DIR/unlearn.sh" 2>&1)
ec=$?
assert_exit_code "unlearn exits 1 with missing text" 1 "$ec"

# Non-existent CSS file
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "category": "nosuchcat", "pluginStorage": "'"$UNLEARN_STORAGE"'", "textContent": "test text"}' \
  | bash "$PLUGIN_DIR/unlearn.sh" 2>&1)
ec=$?
assert_exit_code "unlearn exits 1 when CSS file does not exist" 1 "$ec"
assert_json_valid "unlearn returns JSON error when CSS file missing" "$out"

# Path traversal in category name
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "category": "../etc/passwd", "pluginStorage": "'"$UNLEARN_STORAGE"'", "textContent": "test"}' \
  | bash "$PLUGIN_DIR/unlearn.sh" 2>&1)
ec=$?
assert_exit_code "unlearn rejects path traversal in category name" 1 "$ec"

# Path traversal in pluginStorage
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "category": "news", "pluginStorage": "/tmp/../etc", "textContent": "test"}' \
  | bash "$PLUGIN_DIR/unlearn.sh" 2>&1)
ec=$?
assert_exit_code "unlearn rejects path traversal in pluginStorage" 1 "$ec"

# ============================================================
# Group 7: process.sh
# ============================================================
echo ""
echo "Group 7: process.sh"
echo "---"

PROCESS_STORAGE="$TEST_DIR/process_storage"

# Exit 65 when pluginStorage does not exist
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "pluginStorage": "'"$TEST_DIR/nostorage"'", "textContent": "some text"}' \
  | bash "$PLUGIN_DIR/process.sh" 2>&1)
ec=$?
assert_exit_code "process exits 65 when pluginStorage does not exist" 65 "$ec"

# Exit 65 when no textContent (or empty)
mkdir -p "$PROCESS_STORAGE"
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "pluginStorage": "'"$PROCESS_STORAGE"'", "textContent": ""}' \
  | bash "$PLUGIN_DIR/process.sh" 2>&1)
ec=$?
assert_exit_code "process exits 65 when textContent is empty" 65 "$ec"

# Exit 65 when no CSS files in storage
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "pluginStorage": "'"$PROCESS_STORAGE"'", "textContent": "some text"}' \
  | bash "$PLUGIN_DIR/process.sh" 2>&1)
ec=$?
assert_exit_code "process exits 65 when no trained categories" 65 "$ec"

# Missing pluginStorage field
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "textContent": "some text"}' \
  | bash "$PLUGIN_DIR/process.sh" 2>&1)
ec=$?
assert_exit_code "process exits 1 with missing pluginStorage" 1 "$ec"

# Path traversal in pluginStorage
out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "pluginStorage": "/tmp/../etc", "textContent": "test"}' \
  | bash "$PLUGIN_DIR/process.sh" 2>&1)
ec=$?
assert_exit_code "process rejects path traversal in pluginStorage" 1 "$ec"

# With CSS files and crm114 available: classifies and returns categories
if [ "$CRM114_AVAILABLE" = "true" ]; then
  CLASSIFY_STORAGE="$TEST_DIR/classify_storage"
  mkdir -p "$CLASSIFY_STORAGE"
  # Create dummy CSS files via csslearn
  echo "This is news about politics" | csslearn "$CLASSIFY_STORAGE/news.css" 2>/dev/null || true
  echo "This is sports news" | csslearn "$CLASSIFY_STORAGE/sport.css" 2>/dev/null || true

  out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "pluginStorage": "'"$CLASSIFY_STORAGE"'", "textContent": "politics and government news"}' \
    | bash "$PLUGIN_DIR/process.sh" 2>&1)
  ec=$?
  assert_exit_code "process exits 0 with trained categories and crm114" 0 "$ec"
  assert_json_valid "process returns valid JSON" "$out"
  assert_contains "process output has 'categories' key" '"categories"' "$out"
  cats_type=$(echo "$out" | jq -r '.categories | type')
  assert_eq "process categories is array" "array" "$cats_type"
else
  skip_test "process exits 0 with trained categories and crm114" "crm114 not installed"
  skip_test "process returns valid JSON" "crm114 not installed"
  skip_test "process output has 'categories' key" "crm114 not installed"
  skip_test "process categories is array" "crm114 not installed"
fi

# ============================================================
# Group 8: Plugin in CLI list and tree
# ============================================================
echo ""
echo "Group 8: Plugin in CLI list and tree"
echo "---"

out=$("$CLI" list plugins 2>&1)
assert_contains "crm114 appears in 'list plugins' output" "crm114" "$out"

out=$("$CLI" tree 2>&1)
assert_contains "crm114 appears in 'tree' output" "crm114" "$out"

# ============================================================
# Group 9: run command integration (non-interactive commands)
# ============================================================
echo ""
echo "Group 9: run command integration"
echo "---"

RUN_STORAGE="$TEST_DIR/run_storage"
mkdir -p "$RUN_STORAGE"

# listCategories via run (non-interactive, no -o needed — pass pluginStorage in JSON)
out=$("$CLI" run crm114 listCategories -- "pluginStorage=$RUN_STORAGE" 2>&1)
ec=$?
assert_exit_code "run crm114 listCategories exits 0" 0 "$ec"
assert_json_valid "run crm114 listCategories returns valid JSON" "$out"
assert_eq "run crm114 listCategories returns empty array" \
  "[]" \
  "$(echo "$out" | jq -r '.categories | tostring')"

# installed via run
out=$("$CLI" run crm114 installed 2>&1)
ec=$?
assert_exit_code "run crm114 installed exits 0" 0 "$ec"
assert_json_valid "run crm114 installed returns valid JSON" "$out"

# ============================================================
# Group 10: Security — category name sanitization
# ============================================================
echo ""
echo "Group 10: Security — input validation"
echo "---"

SEC_STORAGE="$TEST_DIR/sec_storage"
mkdir -p "$SEC_STORAGE"

INVALID_CATS=(
  "../traversal"
  "cat/subdir"
  "cat name"
  "cat*name"
  'cat$name'
  "cat;name"
  "cat\`name"
  "cat|name"
  "cat>name"
)

for bad_cat in "${INVALID_CATS[@]}"; do
  out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "category": "'"$bad_cat"'", "pluginStorage": "'"$SEC_STORAGE"'", "textContent": "test"}' \
    | bash "$PLUGIN_DIR/learn.sh" 2>&1)
  ec=$?
  assert_exit_code "learn rejects invalid category: '$bad_cat'" 1 "$ec"
done

# Valid category names should be accepted (even if crm114 not installed, validation passes)
VALID_CATS=("news" "sport-news" "category_one" "cat.sub" "CatName123")
for good_cat in "${VALID_CATS[@]}"; do
  # Just test that the error is NOT about invalid category name
  out=$(echo '{"filePath": "'"$TEST_DIR/test_doc.txt"'", "category": "'"$good_cat"'", "pluginStorage": "'"$SEC_STORAGE"'", "textContent": "test"}' \
    | bash "$PLUGIN_DIR/learn.sh" 2>&1)
  ec=$?
  assert_not_contains "learn accepts valid category '$good_cat' (no sanitization error)" "invalid category" "$out"
done

# ============================================================
# Summary
# ============================================================
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped (total: $TOTAL)"
echo "============================================"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
