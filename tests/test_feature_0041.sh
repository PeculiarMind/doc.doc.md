#!/bin/bash
# Test suite for FEATURE_0041: Plugin Storage Plumbing (pluginStorage attribute)
# TDD: These tests define the contract BEFORE implementation.
# Run from repository root: bash tests/test_feature_0041.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOC_DOC_SH="$REPO_ROOT/doc.doc.sh"
PLUGIN_EXEC="$REPO_ROOT/doc.doc.md/components/plugin_execution.sh"
BUILTIN_PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

PASS=0
FAIL=0
TOTAL=0

TMPDIR_TEST=""
_DEACTIVATED_PLUGINS=()

cleanup() {
  # Re-activate any plugins we deactivated for the test
  for _p in "${_DEACTIVATED_PLUGINS[@]+"${_DEACTIVATED_PLUGINS[@]}"}"; do
    local _desc="$BUILTIN_PLUGIN_DIR/$_p/descriptor.json"
    if [ -f "$_desc" ]; then
      local _tmp
      _tmp=$(jq '.active = true' "$_desc") && echo "$_tmp" > "$_desc"
    fi
  done
  [ -n "$TMPDIR_TEST" ] && [ -d "$TMPDIR_TEST" ] && rm -rf "$TMPDIR_TEST"
}
trap cleanup EXIT

# Deactivate plugins whose dependencies are not installed to avoid
# interactive prompts or non-zero exits during 'process' invocations.
for _plugin_name in markitdown ocrmypdf crm114; do
  _inst_sh="$BUILTIN_PLUGIN_DIR/$_plugin_name/installed.sh"
  _desc_json="$BUILTIN_PLUGIN_DIR/$_plugin_name/descriptor.json"
  if [ -x "$_inst_sh" ] && [ -f "$_desc_json" ]; then
    _is_active=$(jq -r '.active' "$_desc_json")
    if [ "$_is_active" = "true" ]; then
      _check=$(bash "$_inst_sh" 2>/dev/null | jq -r 'if .installed == false then "false" else "true" end' 2>/dev/null) || _check="false"
      if [ "$_check" = "false" ]; then
        _tmp=$(jq '.active = false' "$_desc_json") && echo "$_tmp" > "$_desc_json"
        _DEACTIVATED_PLUGINS+=("$_plugin_name")
      fi
    fi
  fi
done

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
echo "  FEATURE_0041: Plugin Storage Plumbing"
echo "  (pluginStorage attribute)"
echo "============================================"
echo ""

TMPDIR_TEST=$(mktemp -d)

# =========================================
# Group 1: Storage directory creation during process
# =========================================
echo "--- Group 1: Storage directory creation during process ---"

G1_INPUT="$TMPDIR_TEST/g1_input"
G1_OUTPUT="$TMPDIR_TEST/g1_output"
mkdir -p "$G1_INPUT" "$G1_OUTPUT"
echo "Hello storage test" > "$G1_INPUT/sample.txt"

exit_code=0
bash "$DOC_DOC_SH" process -d "$G1_INPUT" -o "$G1_OUTPUT" --no-progress 2>/dev/null || exit_code=$?
assert_exit_code "process command exits 0" "0" "$exit_code"

TOTAL=$((TOTAL + 1))
if [ -d "$G1_OUTPUT/.doc.doc.md" ]; then
  echo "  PASS: .doc.doc.md/ directory created under output"
  PASS=$((PASS + 1))
else
  echo "  FAIL: .doc.doc.md/ directory not created under output"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if [ -d "$G1_OUTPUT/.doc.doc.md/file" ]; then
  echo "  PASS: .doc.doc.md/file/ storage directory exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: .doc.doc.md/file/ storage directory not found"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if [ -d "$G1_OUTPUT/.doc.doc.md/stat" ]; then
  echo "  PASS: .doc.doc.md/stat/ storage directory exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: .doc.doc.md/stat/ storage directory not found"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: pluginStorage in JSON input (spy plugin)
# =========================================
echo ""
echo "--- Group 2: pluginStorage in JSON input ---"

G2_OUTPUT="$TMPDIR_TEST/g2_output"
SPY_PLUGIN_BASE="$TMPDIR_TEST/spy_plugins"
SPY_DUMP="$TMPDIR_TEST/spy_input.json"
mkdir -p "$G2_OUTPUT" "$SPY_PLUGIN_BASE/spy"

cat > "$SPY_PLUGIN_BASE/spy/descriptor.json" <<'JSON'
{
  "name": "spy",
  "version": "1.0.0",
  "description": "Test spy plugin that captures stdin",
  "active": true,
  "commands": {
    "process": {
      "command": "main.sh"
    }
  }
}
JSON

# Spy plugin: captures JSON stdin to a dump file, then outputs cleaned JSON
cat > "$SPY_PLUGIN_BASE/spy/main.sh" <<SCRIPT
#!/bin/bash
input=\$(cat)
echo "\$input" > "$SPY_DUMP"
echo "\$input" | jq 'del(.pluginStorage)'
SCRIPT
chmod +x "$SPY_PLUGIN_BASE/spy/main.sh"

G2_INPUT_FILE="$TMPDIR_TEST/g2_input/testfile.txt"
mkdir -p "$TMPDIR_TEST/g2_input"
echo "spy test content" > "$G2_INPUT_FILE"

# Source plugin_execution.sh and call run_plugin with the expected
# 5-argument signature: <name> <file> <plugin_dir> <output_dir> [context_json]
spy_exit=0
(
  source "$PLUGIN_EXEC"
  run_plugin "spy" "$G2_INPUT_FILE" "$SPY_PLUGIN_BASE" "$G2_OUTPUT" '{"filePath":"'"$G2_INPUT_FILE"'"}'
) >/dev/null 2>&1 || spy_exit=$?

TOTAL=$((TOTAL + 1))
if [ -f "$SPY_DUMP" ]; then
  echo "  PASS: spy plugin received input (dump file exists)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: spy plugin did not receive input (no dump file)"
  FAIL=$((FAIL + 1))
fi

spy_storage=""
if [ -f "$SPY_DUMP" ]; then
  spy_storage=$(jq -r '.pluginStorage // empty' "$SPY_DUMP" 2>/dev/null)
fi

TOTAL=$((TOTAL + 1))
if [ -n "$spy_storage" ]; then
  echo "  PASS: pluginStorage field present in JSON input to plugin"
  PASS=$((PASS + 1))
else
  echo "  FAIL: pluginStorage field missing from JSON input to plugin"
  echo "    Captured JSON: $(cat "$SPY_DUMP" 2>/dev/null | head -1)"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if [ -d "$G2_OUTPUT/.doc.doc.md/spy" ]; then
  echo "  PASS: .doc.doc.md/spy/ directory created by run_plugin"
  PASS=$((PASS + 1))
else
  echo "  FAIL: .doc.doc.md/spy/ directory not created by run_plugin"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 3: --echo mode does not create storage
# =========================================
echo ""
echo "--- Group 3: --echo mode does not create storage ---"

G3_INPUT="$TMPDIR_TEST/g3_input"
mkdir -p "$G3_INPUT"
echo "Echo test content" > "$G3_INPUT/echo_test.txt"

exit_code=0
bash "$DOC_DOC_SH" process -d "$G3_INPUT" --echo --no-progress >/dev/null 2>/dev/null || exit_code=$?
assert_exit_code "--echo process exits 0" "0" "$exit_code"

TOTAL=$((TOTAL + 1))
if [ -d "$G3_INPUT/.doc.doc.md" ]; then
  echo "  FAIL: .doc.doc.md/ should not be created in input dir during echo mode"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: no .doc.doc.md/ in input dir during echo mode"
  PASS=$((PASS + 1))
fi

# Verify nothing leaked into the current working directory either
TOTAL=$((TOTAL + 1))
if [ -d ".doc.doc.md" ]; then
  echo "  FAIL: .doc.doc.md/ should not be created in cwd during echo mode"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: no .doc.doc.md/ in cwd during echo mode"
  PASS=$((PASS + 1))
fi

# =========================================
# Group 4: pluginStorage path is absolute and canonical
# =========================================
echo ""
echo "--- Group 4: pluginStorage path is absolute and canonical ---"

TOTAL=$((TOTAL + 1))
if [ -n "$spy_storage" ]; then
  case "$spy_storage" in
    /*)
      echo "  PASS: pluginStorage starts with / (absolute path)"
      PASS=$((PASS + 1))
      ;;
    *)
      echo "  FAIL: pluginStorage is not an absolute path"
      echo "    Value: $spy_storage"
      FAIL=$((FAIL + 1))
      ;;
  esac
else
  echo "  FAIL: pluginStorage not available (depends on Group 2)"
  echo "    Skipped: no value captured from spy"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if [ -n "$spy_storage" ]; then
  if echo "$spy_storage" | grep -qE '/\.\./|/\./'; then
    echo "  FAIL: pluginStorage contains non-canonical segments (/../ or /./)"
    echo "    Value: $spy_storage"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: pluginStorage path is canonical (no /../ or /./)"
    PASS=$((PASS + 1))
  fi
else
  echo "  FAIL: pluginStorage not available (depends on Group 2)"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 5: Security - pluginStorage is under output directory
# =========================================
echo ""
echo "--- Group 5: pluginStorage is under output directory ---"

G2_CANONICAL_OUT=$(readlink -f "$G2_OUTPUT")

TOTAL=$((TOTAL + 1))
if [ -n "$spy_storage" ]; then
  case "$spy_storage" in
    "${G2_CANONICAL_OUT}"/*)
      echo "  PASS: pluginStorage starts with canonical output dir"
      PASS=$((PASS + 1))
      ;;
    *)
      echo "  FAIL: pluginStorage escapes output directory"
      echo "    Output dir: $G2_CANONICAL_OUT"
      echo "    Storage:    $spy_storage"
      FAIL=$((FAIL + 1))
      ;;
  esac
else
  echo "  FAIL: pluginStorage not available (depends on Group 2)"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if [ -n "$spy_storage" ]; then
  expected_prefix="${G2_CANONICAL_OUT}/.doc.doc.md/spy"
  case "$spy_storage" in
    "${expected_prefix}"*)
      echo "  PASS: pluginStorage follows .doc.doc.md/<pluginname>/ convention"
      PASS=$((PASS + 1))
      ;;
    *)
      echo "  FAIL: pluginStorage does not follow expected convention"
      echo "    Expected prefix: $expected_prefix"
      echo "    Actual:          $spy_storage"
      FAIL=$((FAIL + 1))
      ;;
  esac
else
  echo "  FAIL: pluginStorage not available (depends on Group 2)"
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
