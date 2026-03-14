#!/bin/bash
# Test suite for FEATURE_0003: CRM114 Text Classification Plugin
# Run from repository root: bash tests/test_feature_0003.sh
#
# Tests cover plugin structure, installed/install status, main.sh behaviour,
# pluginStorage validation (REQ_SEC_005), ADR-004 exit code compliance, and
# integration with doc.doc.sh list/tree commands.
# CRM114 is rarely available in CI — tests that need it are SKIPped.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOC_DOC_SH="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins/crm114"

PASS=0
FAIL=0
SKIP_COUNT=0
TOTAL=0

# ---- Cleanup ----

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
if command -v crm >/dev/null 2>&1 || command -v cssutil >/dev/null 2>&1; then
  CRM114_AVAILABLE=true
fi

# ---- Helpers ----

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
    echo "    Should NOT contain: $unexpected"
    echo "    Actual: $actual"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
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

skip_test() {
  local test_name="$1"
  local reason="$2"
  TOTAL=$((TOTAL + 1))
  SKIP_COUNT=$((SKIP_COUNT + 1))
  echo "  SKIP: $test_name — $reason"
}

echo "============================================"
echo "  FEATURE_0003 CRM114 Plugin Test Suite"
echo "============================================"
echo ""
echo "  CRM114 available: $CRM114_AVAILABLE"
echo ""

# =========================================
# Group 1: Plugin structure
# =========================================
echo "--- Group 1: Plugin structure ---"

# descriptor.json exists
TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_DIR/descriptor.json" ]; then
  echo "  PASS: descriptor.json exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor.json does not exist"
  FAIL=$((FAIL + 1))
fi

# main.sh exists and is executable
TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_DIR/main.sh" ]; then
  echo "  PASS: main.sh exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: main.sh does not exist"
  FAIL=$((FAIL + 1))
fi
TOTAL=$((TOTAL + 1))
if [ -x "$PLUGIN_DIR/main.sh" ]; then
  echo "  PASS: main.sh is executable"
  PASS=$((PASS + 1))
else
  echo "  FAIL: main.sh is NOT executable"
  FAIL=$((FAIL + 1))
fi

# installed.sh exists and is executable
TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_DIR/installed.sh" ]; then
  echo "  PASS: installed.sh exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: installed.sh does not exist"
  FAIL=$((FAIL + 1))
fi
TOTAL=$((TOTAL + 1))
if [ -x "$PLUGIN_DIR/installed.sh" ]; then
  echo "  PASS: installed.sh is executable"
  PASS=$((PASS + 1))
else
  echo "  FAIL: installed.sh is NOT executable"
  FAIL=$((FAIL + 1))
fi

# install.sh exists and is executable
TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_DIR/install.sh" ]; then
  echo "  PASS: install.sh exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: install.sh does not exist"
  FAIL=$((FAIL + 1))
fi
TOTAL=$((TOTAL + 1))
if [ -x "$PLUGIN_DIR/install.sh" ]; then
  echo "  PASS: install.sh is executable"
  PASS=$((PASS + 1))
else
  echo "  FAIL: install.sh is NOT executable"
  FAIL=$((FAIL + 1))
fi

# descriptor.json is valid JSON
TOTAL=$((TOTAL + 1))
if jq empty "$PLUGIN_DIR/descriptor.json" 2>/dev/null; then
  echo "  PASS: descriptor.json is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor.json is NOT valid JSON"
  FAIL=$((FAIL + 1))
fi

desc=$(cat "$PLUGIN_DIR/descriptor.json")

# descriptor.json contains "crm114" name
assert_json_field "descriptor.json name is 'crm114'" "$desc" "name" "crm114"

# descriptor.json defines process command
TOTAL=$((TOTAL + 1))
if echo "$desc" | jq -e ".commands.process" >/dev/null 2>&1; then
  echo "  PASS: descriptor defines process command"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor missing process command"
  FAIL=$((FAIL + 1))
fi

# descriptor.json defines installed command
TOTAL=$((TOTAL + 1))
if echo "$desc" | jq -e ".commands.installed" >/dev/null 2>&1; then
  echo "  PASS: descriptor defines installed command"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor missing installed command"
  FAIL=$((FAIL + 1))
fi

# descriptor.json defines install command
TOTAL=$((TOTAL + 1))
if echo "$desc" | jq -e ".commands.install" >/dev/null 2>&1; then
  echo "  PASS: descriptor defines install command"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor missing install command"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: installed.sh reports status
# =========================================
echo ""
echo "--- Group 2: installed.sh reports status ---"

installed_output=$("$PLUGIN_DIR/installed.sh" 2>/dev/null)
installed_exit=$?

# installed.sh exits 0
assert_exit_code "installed.sh exits 0" "0" "$installed_exit"

# installed.sh outputs valid JSON
TOTAL=$((TOTAL + 1))
if echo "$installed_output" | jq empty 2>/dev/null; then
  echo "  PASS: installed.sh output is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: installed.sh output is NOT valid JSON"
  FAIL=$((FAIL + 1))
fi

# installed.sh reports correct status based on crm114 availability
if [ "$CRM114_AVAILABLE" = "true" ]; then
  assert_json_field "installed.sh reports installed=true" "$installed_output" "installed" "true"
else
  assert_json_field "installed.sh reports installed=false" "$installed_output" "installed" "false"
fi

assert_json_field_type "installed field is boolean" "$installed_output" "installed" "boolean"

# =========================================
# Group 3: install.sh reports status
# =========================================
echo ""
echo "--- Group 3: install.sh reports status ---"

if [ "$CRM114_AVAILABLE" = "false" ]; then
  install_output=$("$PLUGIN_DIR/install.sh" 2>/dev/null)
  install_exit=$?

  # If crm114 not available, install.sh exits 1 (no sudo/apt in CI)
  assert_exit_code "install.sh exits 1 when crm114 unavailable" "1" "$install_exit"

  # install.sh outputs valid JSON with success and message fields
  TOTAL=$((TOTAL + 1))
  if echo "$install_output" | jq empty 2>/dev/null; then
    echo "  PASS: install.sh output is valid JSON"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: install.sh output is NOT valid JSON"
    FAIL=$((FAIL + 1))
  fi

  assert_json_field_type "install.sh 'success' is boolean" "$install_output" "success" "boolean"
  assert_json_field "install.sh 'success' is false" "$install_output" "success" "false"
  assert_json_field_type "install.sh 'message' is string" "$install_output" "message" "string"
else
  skip_test "install.sh failure path" "crm114 already installed"
fi

# =========================================
# Group 4: main.sh process command (crm114 not installed)
# =========================================
echo ""
echo "--- Group 4: main.sh process command ---"

if [ "$CRM114_AVAILABLE" = "false" ]; then
  # Create a valid test file and an empty pluginStorage directory
  test_file="$TEST_DIR/sample.txt"
  echo "This is test content for classification." > "$test_file"
  empty_storage="$TEST_DIR/crm_storage_empty"
  mkdir -p "$empty_storage"

  # No trained categories (.css files) in pluginStorage → exits 65 (skip)
  main_output=$(echo "{\"filePath\":\"$test_file\",\"pluginStorage\":\"$empty_storage\"}" \
    | bash "$PLUGIN_DIR/main.sh" 2>/dev/null)
  main_exit=$?

  assert_exit_code "main.sh exits 65 with no trained categories" "65" "$main_exit"

  # Verify JSON output has "message" field when skipping
  TOTAL=$((TOTAL + 1))
  if echo "$main_output" | jq -e ".message" >/dev/null 2>&1; then
    echo "  PASS: skip output contains 'message' field"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: skip output missing 'message' field"
    echo "    Output: $main_output"
    FAIL=$((FAIL + 1))
  fi
else
  skip_test "main.sh skip when no categories" "crm114 installed — would not skip"
  skip_test "main.sh message field on skip" "crm114 installed — would not skip"
fi

# =========================================
# Group 5: Plugin appears in tree and list commands
# =========================================
echo ""
echo "--- Group 5: Plugin in tree and list ---"

# crm114 appears in list plugins output
if [ -x "$DOC_DOC_SH" ]; then
  list_output=$("$DOC_DOC_SH" list plugins 2>/dev/null) || list_output=""
  assert_contains "crm114 in 'list plugins'" "crm114" "$list_output"

  tree_output=$("$DOC_DOC_SH" tree 2>/dev/null) || tree_output=""
  assert_contains "crm114 in 'tree' output" "crm114" "$tree_output"
else
  skip_test "crm114 in list plugins" "doc.doc.sh not executable"
  skip_test "crm114 in tree output" "doc.doc.sh not executable"
fi

# =========================================
# Group 6: pluginStorage validation (REQ_SEC_005)
# =========================================
echo ""
echo "--- Group 6: pluginStorage validation (REQ_SEC_005) ---"

test_file_sec="$TEST_DIR/security_test.txt"
echo "Security test content." > "$test_file_sec"

# main.sh rejects empty pluginStorage → exits 65
empty_ps_output=$(echo "{\"filePath\":\"$test_file_sec\",\"pluginStorage\":\"\"}" \
  | bash "$PLUGIN_DIR/main.sh" 2>/dev/null)
empty_ps_exit=$?
assert_exit_code "main.sh rejects empty pluginStorage (exit 65)" "65" "$empty_ps_exit"

# main.sh rejects nonexistent pluginStorage → exits 65
nonexist_ps_output=$(echo "{\"filePath\":\"$test_file_sec\",\"pluginStorage\":\"/tmp/nonexistent_crm_storage_$$\"}" \
  | bash "$PLUGIN_DIR/main.sh" 2>/dev/null)
nonexist_ps_exit=$?
assert_exit_code "main.sh rejects nonexistent pluginStorage (exit 65)" "65" "$nonexist_ps_exit"

# =========================================
# Group 7: ADR-004 exit code compliance
# =========================================
echo ""
echo "--- Group 7: ADR-004 exit code compliance ---"

# Collect exit codes from various scenarios to verify only 0, 65, or 1
valid_exit_codes="0 1 65"
adr004_pass=true

# Scenario A: empty pluginStorage
code_a=$empty_ps_exit
# Scenario B: nonexistent pluginStorage
code_b=$nonexist_ps_exit

# Scenario C: valid storage but no .css models
if [ -n "${main_exit:-}" ]; then
  code_c=$main_exit
else
  code_c=65
fi

# Scenario D: missing filePath entirely
code_d_output=$(echo '{"pluginStorage":"/tmp"}' | bash "$PLUGIN_DIR/main.sh" 2>/dev/null) || true
code_d=$?

for code_label_pair in "A:$code_a" "B:$code_b" "C:$code_c" "D:$code_d"; do
  label="${code_label_pair%%:*}"
  code="${code_label_pair##*:}"
  case "$code" in
    0|1|65)
      ;;
    *)
      adr004_pass=false
      ;;
  esac
done

TOTAL=$((TOTAL + 1))
if [ "$adr004_pass" = "true" ]; then
  echo "  PASS: all observed exit codes are 0, 1, or 65 (ADR-004 compliant)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: non-compliant exit codes detected (expected only 0, 1, or 65)"
  echo "    Codes: A=$code_a B=$code_b C=$code_c D=$code_d"
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
