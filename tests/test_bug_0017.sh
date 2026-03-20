#!/bin/bash
# Test suite for BUG_0017: CRM114 train loop does not prompt for category creation
# TDD: Tests define the contract BEFORE implementation; they FAIL until the
#      fix is implemented.
# Run from repository root: bash tests/test_bug_0017.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CRM114_PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins/crm114"

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

# ---- test setup / teardown ----

TEST_TMP=""

setup() {
  TEST_TMP=$(mktemp -d)
  mkdir -p "$TEST_TMP/storage"
}

teardown() {
  [ -n "$TEST_TMP" ] && rm -rf "$TEST_TMP"
}

# ---- helper: build JSON input for train.sh ----

build_train_json() {
  local file_path="$1"
  local plugin_storage="$2"
  local text_content="${3:-}"
  jq -n \
    --arg fp "$file_path" \
    --arg ps "$plugin_storage" \
    --arg tc "$text_content" \
    '{filePath: $fp, pluginStorage: $ps, textContent: $tc}'
}

# ---- helper: run train.sh with simulated tty via named pipe ----
# train.sh reads user input from /dev/tty.  To test interactively we
# override /dev/tty for the child process by bind-mounting a FIFO
# (requires no special privileges when done inside an unshare namespace).
# Fallback: when /dev/tty is unavailable the script must still behave
# correctly (exit 65 when no categories can be created).

run_train_with_input() {
  local input_json="$1"
  local tty_input="$2"   # string to feed as if typed at /dev/tty
  local tty_file="$TEST_TMP/fake_tty_input"
  # Use a regular file (reliable across all environments)
  printf '%s' "$tty_input" > "$tty_file"
  local out
  out=$(echo "$input_json" | CRM114_TTY_OVERRIDE="$tty_file" bash "$CRM114_PLUGIN_DIR/train.sh" 2>&1) || true
  rm -f "$tty_file"
  echo "$out"
}

run_train_exit_code() {
  local input_json="$1"
  local tty_input="$2"
  local tty_file="$TEST_TMP/fake_tty_exit"
  printf '%s' "$tty_input" > "$tty_file"
  local ec=0
  echo "$input_json" | CRM114_TTY_OVERRIDE="$tty_file" bash "$CRM114_PLUGIN_DIR/train.sh" >/dev/null 2>&1 || ec=$?
  rm -f "$tty_file"
  echo "$ec"
}

# ============================================================
# Group 1: Inline category creation when no categories exist
# ============================================================

echo ""
echo "=== Group 1: Inline category creation when no categories exist ==="

# Test 1.1: Empty storage — EOF on tty → exit 65, no old static message
echo ""
echo "--- Test 1.1: Empty storage + EOF → exit 65, no old message ---"
setup
input_json=$(build_train_json "/tmp/test.txt" "$TEST_TMP/storage" "hello world")
ec=$(run_train_exit_code "$input_json" "")
assert_exit_code "Exit 65 when EOF with no categories" "65" "$ec"
output=$(run_train_with_input "$input_json" "")
assert_not_contains "No old manageCategories message" \
  "Run 'doc.doc.sh run crm114 manageCategories" "$output"
teardown

# Test 1.2: Missing storage dir — created automatically, exit 65 without old message
echo ""
echo "--- Test 1.2: Missing storage dir → created, exit 65, no old message ---"
setup
rm -rf "$TEST_TMP/storage"
input_json=$(build_train_json "/tmp/test.txt" "$TEST_TMP/storage" "hello world")
ec=$(run_train_exit_code "$input_json" "")
assert_exit_code "Exit 65 when storage dir missing and EOF" "65" "$ec"
assert_file_exists "Storage dir created" "$TEST_TMP/storage"
output=$(run_train_with_input "$input_json" "")
assert_not_contains "No old manageCategories message on missing dir" \
  "Run 'doc.doc.sh run crm114 manageCategories" "$output"
teardown

# Test 1.3: Category name validation — invalid names rejected
echo ""
echo "--- Test 1.3: Invalid category names rejected inline ---"
setup
input_json=$(build_train_json "/tmp/test.txt" "$TEST_TMP/storage" "hello world")
output=$(run_train_with_input "$input_json" "bad name!
")
assert_contains "Invalid category name rejected" "Invalid" "$output"
teardown

# Test 1.4: Prompt text shown when no categories exist
echo ""
echo "--- Test 1.4: Prompt text shown for category creation ---"
setup
input_json=$(build_train_json "/tmp/test.txt" "$TEST_TMP/storage" "hello world")
output=$(run_train_with_input "$input_json" "")
assert_contains "Category creation prompt shown" "category" "$output"
teardown

# ============================================================
# Group 2: Existing categories — behavior unchanged
# ============================================================

echo ""
echo "=== Group 2: Existing categories — behavior unchanged ==="

# Test 2.1: With existing categories, no creation prompt shown
echo ""
echo "--- Test 2.1: Existing categories skip creation prompt ---"
setup
touch "$TEST_TMP/storage/testcat.css"
input_json=$(build_train_json "/tmp/test.txt" "$TEST_TMP/storage" "hello world")
# feed 's' for skip on the single category
output=$(run_train_with_input "$input_json" "s
")
assert_not_contains "No creation prompt" "Enter one or more category names" "$output"
assert_contains "Document header shown" "Document" "$output"
teardown

# Test 2.2: Per-document category prompts work with existing categories
echo ""
echo "--- Test 2.2: Per-document t/u/s prompts shown ---"
setup
touch "$TEST_TMP/storage/spam.css"
input_json=$(build_train_json "/tmp/test.txt" "$TEST_TMP/storage" "hello world")
output=$(run_train_with_input "$input_json" "s
")
assert_contains "Category name in prompt" "spam" "$output"
teardown

# ============================================================
# Group 3: Security constraints maintained
# ============================================================

echo ""
echo "=== Group 3: Security constraints maintained ==="

# Test 3.1: Path traversal in pluginStorage still rejected
echo ""
echo "--- Test 3.1: Path traversal rejection ---"
setup
input_json=$(build_train_json "/tmp/test.txt" "$TEST_TMP/../etc/passwd" "hello world")
ec=0
echo "$input_json" | bash "$CRM114_PLUGIN_DIR/train.sh" >/dev/null 2>&1 || ec=$?
assert_exit_code "Path traversal exits 1" "1" "$ec"
teardown

# Test 3.2: Missing filePath still rejected
echo ""
echo "--- Test 3.2: Missing filePath rejection ---"
setup
input_json=$(jq -n --arg ps "$TEST_TMP/storage" '{pluginStorage: $ps, textContent: "hello"}')
ec=0
echo "$input_json" | bash "$CRM114_PLUGIN_DIR/train.sh" >/dev/null 2>&1 || ec=$?
assert_exit_code "Missing filePath exits 1" "1" "$ec"
teardown

# Test 3.3: Missing pluginStorage still rejected
echo ""
echo "--- Test 3.3: Missing pluginStorage rejection ---"
setup
input_json=$(jq -n --arg fp "/tmp/test.txt" '{filePath: $fp, textContent: "hello"}')
ec=0
echo "$input_json" | bash "$CRM114_PLUGIN_DIR/train.sh" >/dev/null 2>&1 || ec=$?
assert_exit_code "Missing pluginStorage exits 1" "1" "$ec"
teardown

# ============================================================
# Group 4: manageCategories independence
# ============================================================

echo ""
echo "=== Group 4: manageCategories independence ==="

# Test 4.1: manageCategories still works independently
echo ""
echo "--- Test 4.1: manageCategories works independently ---"
setup
output=""
output=$(CRM114_TTY_OVERRIDE=/dev/null bash "$CRM114_PLUGIN_DIR/manageCategories.sh" "$TEST_TMP/storage" 2>&1) || true
assert_contains "manageCategories shows management header" "Category Management" "$output"
teardown

# ---- summary ----

echo ""
echo "==========================================="
echo "  BUG_0017 Results: $PASS passed, $FAIL failed, $SKIP skipped out of $TOTAL"
echo "==========================================="
echo ""

exit "$FAIL"
