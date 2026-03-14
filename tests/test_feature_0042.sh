#!/bin/bash
# Test suite for FEATURE_0042: CRM114 Model Management Commands
# (learn, unlearn, listCategories, train)
# Run from repository root: bash tests/test_feature_0042.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins/crm114"

PASS=0
FAIL=0
SKIP_COUNT=0
TOTAL=0

cleanup() {
  if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
    chmod -R u+rw "$TEST_DIR" 2>/dev/null || true
    rm -rf "$TEST_DIR"
  fi
}
trap cleanup EXIT

TEST_DIR=$(mktemp -d)

# ---- CRM114 availability flag ----

CRM114_AVAILABLE=false
if command -v csslearn >/dev/null 2>&1 && command -v cssunlearn >/dev/null 2>&1; then
  CRM114_AVAILABLE=true
fi

# ---- Helpers ----

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

assert_json_field() {
  local test_name="$1" json="$2" field="$3" expected="$4"
  local actual
  actual=$(echo "$json" | jq -r ".$field" 2>/dev/null)
  assert_eq "$test_name" "$expected" "$actual"
}

assert_json_field_type() {
  local test_name="$1" json="$2" field="$3" expected_type="$4"
  local actual_type
  actual_type=$(echo "$json" | jq -r ".$field | type" 2>/dev/null)
  assert_eq "$test_name" "$expected_type" "$actual_type"
}

skip_test() {
  local test_name="$1" reason="$2"
  TOTAL=$((TOTAL + 1))
  SKIP_COUNT=$((SKIP_COUNT + 1))
  echo "  SKIP: $test_name — $reason"
}

echo "============================================"
echo "  FEATURE_0042: CRM114 Model Management"
echo "  (learn, unlearn, listCategories, train)"
echo "============================================"
echo ""
echo "  CRM114 (csslearn/cssunlearn) available: $CRM114_AVAILABLE"
echo ""

# =========================================
# Group 1: Plugin structure — new script files
# =========================================
echo "--- Group 1: Plugin structure ---"

for script in learn.sh unlearn.sh listCategories.sh train.sh; do
  TOTAL=$((TOTAL + 1))
  if [ -f "$PLUGIN_DIR/$script" ]; then
    echo "  PASS: $script exists"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $script does not exist"
    FAIL=$((FAIL + 1))
  fi

  TOTAL=$((TOTAL + 1))
  if [ -x "$PLUGIN_DIR/$script" ]; then
    echo "  PASS: $script is executable"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $script is NOT executable"
    FAIL=$((FAIL + 1))
  fi
done

# =========================================
# Group 2: descriptor.json — new commands registered
# =========================================
echo ""
echo "--- Group 2: descriptor.json — new commands registered ---"

desc=$(cat "$PLUGIN_DIR/descriptor.json")

for cmd in learn unlearn listCategories train; do
  TOTAL=$((TOTAL + 1))
  if echo "$desc" | jq -e ".commands.$cmd" >/dev/null 2>&1; then
    echo "  PASS: descriptor defines '$cmd' command"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: descriptor missing '$cmd' command"
    FAIL=$((FAIL + 1))
  fi
done

# Verify each command references the correct .sh file
for cmd_script_pair in "learn:learn.sh" "unlearn:unlearn.sh" "listCategories:listCategories.sh" "train:train.sh"; do
  cmd="${cmd_script_pair%%:*}"
  expected_script="${cmd_script_pair##*:}"
  actual_script=$(echo "$desc" | jq -r ".commands.$cmd.command // empty" 2>/dev/null)
  assert_eq "descriptor '$cmd' references $expected_script" "$expected_script" "$actual_script"
done

# =========================================
# Group 3: listCategories — no models
# =========================================
echo ""
echo "--- Group 3: listCategories — no models ---"

empty_storage="$TEST_DIR/empty_storage"
mkdir -p "$empty_storage"

lc_output=$(echo "{\"pluginStorage\":\"$empty_storage\"}" \
  | bash "$PLUGIN_DIR/listCategories.sh" 2>/dev/null)
lc_exit=$?

assert_exit_code "listCategories exits 0 with empty storage" "0" "$lc_exit"

TOTAL=$((TOTAL + 1))
if echo "$lc_output" | jq empty 2>/dev/null; then
  echo "  PASS: listCategories output is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: listCategories output is NOT valid JSON"
  echo "    Output: $lc_output"
  FAIL=$((FAIL + 1))
fi

assert_json_field_type "listCategories 'categories' is array" "$lc_output" "categories" "array"

categories_count=$(echo "$lc_output" | jq '.categories | length' 2>/dev/null)
assert_eq "listCategories returns empty array for empty storage" "0" "$categories_count"

# Missing pluginStorage field
lc_no_storage_output=$(echo '{}' | bash "$PLUGIN_DIR/listCategories.sh" 2>/dev/null)
lc_no_storage_exit=$?
assert_exit_code "listCategories rejects missing pluginStorage (exit 1)" "1" "$lc_no_storage_exit"

# Nonexistent pluginStorage directory
lc_nonexist_output=$(echo "{\"pluginStorage\":\"/tmp/nonexistent_crm114_storage_$$\"}" \
  | bash "$PLUGIN_DIR/listCategories.sh" 2>/dev/null)
lc_nonexist_exit=$?
assert_exit_code "listCategories rejects nonexistent pluginStorage (exit 1)" "1" "$lc_nonexist_exit"

# =========================================
# Group 4: listCategories — with models
# =========================================
echo ""
echo "--- Group 4: listCategories — with models ---"

model_storage="$TEST_DIR/model_storage"
mkdir -p "$model_storage"
touch "$model_storage/spam.css"
touch "$model_storage/ham.css"
touch "$model_storage/notamodel.txt"  # should be ignored

lc_models_output=$(echo "{\"pluginStorage\":\"$model_storage\"}" \
  | bash "$PLUGIN_DIR/listCategories.sh" 2>/dev/null)
lc_models_exit=$?

assert_exit_code "listCategories exits 0 with models present" "0" "$lc_models_exit"

TOTAL=$((TOTAL + 1))
if echo "$lc_models_output" | jq empty 2>/dev/null; then
  echo "  PASS: listCategories output is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: listCategories output is NOT valid JSON"
  echo "    Output: $lc_models_output"
  FAIL=$((FAIL + 1))
fi

models_count=$(echo "$lc_models_output" | jq '.categories | length' 2>/dev/null)
assert_eq "listCategories returns 2 categories" "2" "$models_count"

# Both spam and ham should appear (order may vary)
lc_categories_joined=$(echo "$lc_models_output" | jq -r '.categories | sort | join(",")' 2>/dev/null)
assert_eq "listCategories returns ham and spam" "ham,spam" "$lc_categories_joined"

# .txt file should NOT appear
TOTAL=$((TOTAL + 1))
if echo "$lc_models_output" | jq -r '.categories[]' 2>/dev/null | grep -q "notamodel"; then
  echo "  FAIL: listCategories should not include non-.css files"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: listCategories ignores non-.css files"
  PASS=$((PASS + 1))
fi

# =========================================
# Group 5: learn — validation
# =========================================
echo ""
echo "--- Group 5: learn — validation ---"

test_text_file="$TEST_DIR/test_document.txt"
echo "This is test document text for training the classifier model." > "$test_text_file"
valid_storage="$TEST_DIR/learn_storage"
mkdir -p "$valid_storage"

# Missing category field
learn_no_cat_exit=0
echo "{\"pluginStorage\":\"$valid_storage\",\"filePath\":\"$test_text_file\"}" \
  | bash "$PLUGIN_DIR/learn.sh" >/dev/null 2>&1 || learn_no_cat_exit=$?
assert_exit_code "learn rejects missing category (exit 1)" "1" "$learn_no_cat_exit"

# Missing pluginStorage field
learn_no_storage_exit=0
echo "{\"category\":\"test\",\"filePath\":\"$test_text_file\"}" \
  | bash "$PLUGIN_DIR/learn.sh" >/dev/null 2>&1 || learn_no_storage_exit=$?
assert_exit_code "learn rejects missing pluginStorage (exit 1)" "1" "$learn_no_storage_exit"

# Missing filePath field
learn_no_filepath_exit=0
echo "{\"category\":\"test\",\"pluginStorage\":\"$valid_storage\"}" \
  | bash "$PLUGIN_DIR/learn.sh" >/dev/null 2>&1 || learn_no_filepath_exit=$?
assert_exit_code "learn rejects missing filePath (exit 1)" "1" "$learn_no_filepath_exit"

# Category with path traversal (..)
learn_traversal_exit=0
echo "{\"category\":\"../evil\",\"pluginStorage\":\"$valid_storage\",\"filePath\":\"$test_text_file\"}" \
  | bash "$PLUGIN_DIR/learn.sh" >/dev/null 2>&1 || learn_traversal_exit=$?
assert_exit_code "learn rejects category with .. (exit 1)" "1" "$learn_traversal_exit"

# Category with slash
learn_slash_exit=0
echo "{\"category\":\"foo/bar\",\"pluginStorage\":\"$valid_storage\",\"filePath\":\"$test_text_file\"}" \
  | bash "$PLUGIN_DIR/learn.sh" >/dev/null 2>&1 || learn_slash_exit=$?
assert_exit_code "learn rejects category with slash (exit 1)" "1" "$learn_slash_exit"

# Category with shell metacharacters (semicolon)
learn_meta_exit=0
echo "{\"category\":\"foo;rm\",\"pluginStorage\":\"$valid_storage\",\"filePath\":\"$test_text_file\"}" \
  | bash "$PLUGIN_DIR/learn.sh" >/dev/null 2>&1 || learn_meta_exit=$?
assert_exit_code "learn rejects category with metacharacters (exit 1)" "1" "$learn_meta_exit"

# =========================================
# Group 6: unlearn — validation
# =========================================
echo ""
echo "--- Group 6: unlearn — validation ---"

unlearn_storage="$TEST_DIR/unlearn_storage"
mkdir -p "$unlearn_storage"

# Missing .css model file
unlearn_no_model_exit=0
unlearn_no_model_output=$(echo "{\"category\":\"nonexistent\",\"pluginStorage\":\"$unlearn_storage\",\"filePath\":\"$test_text_file\"}" \
  | bash "$PLUGIN_DIR/unlearn.sh" 2>/dev/null) || unlearn_no_model_exit=$?
assert_exit_code "unlearn exits 1 when model file does not exist" "1" "$unlearn_no_model_exit"

TOTAL=$((TOTAL + 1))
if echo "$unlearn_no_model_output" | jq empty 2>/dev/null; then
  echo "  PASS: unlearn outputs valid JSON on missing model"
  PASS=$((PASS + 1))
else
  echo "  FAIL: unlearn output is NOT valid JSON on missing model"
  echo "    Output: $unlearn_no_model_output"
  FAIL=$((FAIL + 1))
fi

assert_json_field "unlearn 'success' is false on missing model" "$unlearn_no_model_output" "success" "false"

# Missing category field
unlearn_no_cat_exit=0
echo "{\"pluginStorage\":\"$unlearn_storage\",\"filePath\":\"$test_text_file\"}" \
  | bash "$PLUGIN_DIR/unlearn.sh" >/dev/null 2>&1 || unlearn_no_cat_exit=$?
assert_exit_code "unlearn rejects missing category (exit 1)" "1" "$unlearn_no_cat_exit"

# =========================================
# Group 7: learn/unlearn — with CRM114 available
# =========================================
echo ""
echo "--- Group 7: learn/unlearn with CRM114 (skipped when unavailable) ---"

if [ "$CRM114_AVAILABLE" = "true" ]; then
  crm_storage="$TEST_DIR/crm_storage"
  mkdir -p "$crm_storage"

  # learn: creates .css file and outputs success JSON
  learn_output=$(echo "{\"category\":\"testcat\",\"pluginStorage\":\"$crm_storage\",\"filePath\":\"$test_text_file\"}" \
    | bash "$PLUGIN_DIR/learn.sh" 2>/dev/null)
  learn_exit=$?

  assert_exit_code "learn exits 0 on success" "0" "$learn_exit"
  assert_json_field "learn 'success' is true" "$learn_output" "success" "true"

  TOTAL=$((TOTAL + 1))
  if [ -f "$crm_storage/testcat.css" ]; then
    echo "  PASS: learn creates .css model file"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: learn did not create .css model file"
    FAIL=$((FAIL + 1))
  fi

  # listCategories sees the new model
  lc_after_learn=$(echo "{\"pluginStorage\":\"$crm_storage\"}" \
    | bash "$PLUGIN_DIR/listCategories.sh" 2>/dev/null)
  assert_json_field "listCategories returns 'testcat' after learn" \
    "$lc_after_learn" "categories[0]" "testcat"

  # unlearn: removes text from model
  unlearn_output=$(echo "{\"category\":\"testcat\",\"pluginStorage\":\"$crm_storage\",\"filePath\":\"$test_text_file\"}" \
    | bash "$PLUGIN_DIR/unlearn.sh" 2>/dev/null)
  unlearn_exit=$?

  assert_exit_code "unlearn exits 0 on success" "0" "$unlearn_exit"
  assert_json_field "unlearn 'success' is true" "$unlearn_output" "success" "true"
else
  skip_test "learn creates .css model file" "csslearn not available"
  skip_test "learn exits 0 on success" "csslearn not available"
  skip_test "learn 'success' is true" "csslearn not available"
  skip_test "listCategories sees new model after learn" "csslearn not available"
  skip_test "unlearn exits 0 on success" "cssunlearn not available"
  skip_test "unlearn 'success' is true" "cssunlearn not available"
fi

# =========================================
# Group 8: train — argument validation
# =========================================
echo ""
echo "--- Group 8: train — argument validation ---"

# No arguments → exits 1
train_noargs_exit=0
bash "$PLUGIN_DIR/train.sh" >/dev/null 2>&1 || train_noargs_exit=$?
assert_exit_code "train exits 1 with no arguments" "1" "$train_noargs_exit"

# Nonexistent pluginStorage
train_bad_storage_exit=0
bash "$PLUGIN_DIR/train.sh" "/tmp/nonexistent_train_storage_$$" "$TEST_DIR" >/dev/null 2>&1 \
  || train_bad_storage_exit=$?
assert_exit_code "train exits 1 with nonexistent pluginStorage" "1" "$train_bad_storage_exit"

# Nonexistent input directory
train_storage_dir="$TEST_DIR/train_storage"
mkdir -p "$train_storage_dir"
train_bad_input_exit=0
bash "$PLUGIN_DIR/train.sh" "$train_storage_dir" "/tmp/nonexistent_input_dir_$$" >/dev/null 2>&1 \
  || train_bad_input_exit=$?
assert_exit_code "train exits 1 with nonexistent input directory" "1" "$train_bad_input_exit"

# =========================================
# Group 9: Security — category name sanitization
# =========================================
echo ""
echo "--- Group 9: Security — category name sanitization ---"

sec_storage="$TEST_DIR/sec_storage"
mkdir -p "$sec_storage"

# Valid category names (alphanumeric, dash, underscore, dot)
for valid_cat in "spam" "ham" "my-category" "my_category" "cat.1"; do
  valid_cat_exit=0
  valid_cat_output=$(echo "{\"category\":\"$valid_cat\",\"pluginStorage\":\"$sec_storage\",\"filePath\":\"$test_text_file\"}" \
    | bash "$PLUGIN_DIR/learn.sh" 2>/dev/null) || valid_cat_exit=$?
  # Should not exit 1 due to validation (may exit 1 if csslearn unavailable, but should not be a validation failure)
  # We test that it doesn't fail with validation error message
  TOTAL=$((TOTAL + 1))
  if echo "$valid_cat_output" | grep -qi "invalid category" 2>/dev/null; then
    echo "  FAIL: learn incorrectly rejected valid category '$valid_cat'"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: learn accepts valid category '$valid_cat'"
    PASS=$((PASS + 1))
  fi
done

# Invalid category names (should all be rejected with exit 1)
declare -a invalid_cats=(
  "../traversal"
  "foo/bar"
  "foo;bar"
  "foo\$bar"
  "foo bar"
  "foo|bar"
  "foo&bar"
  "foo>bar"
  "foo<bar"
  "foo\`bar"
)

for invalid_cat in "${invalid_cats[@]}"; do
  inv_exit=0
  echo "{\"category\":\"$invalid_cat\",\"pluginStorage\":\"$sec_storage\",\"filePath\":\"$test_text_file\"}" \
    | bash "$PLUGIN_DIR/learn.sh" >/dev/null 2>&1 || inv_exit=$?
  assert_exit_code "learn rejects invalid category '$invalid_cat'" "1" "$inv_exit"
done

# Ensure no .css file was created for any invalid category
TOTAL=$((TOTAL + 1))
css_count=$(find "$sec_storage" -name "*.css" 2>/dev/null | wc -l)
if [ "$css_count" -eq 0 ]; then
  echo "  PASS: no .css files created for invalid categories (security)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: .css files were created for invalid categories"
  echo "    Files: $(find "$sec_storage" -name "*.css")"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed, $SKIP_COUNT skipped (of $TOTAL total)"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
