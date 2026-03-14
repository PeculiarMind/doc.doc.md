#!/bin/bash
# Test suite for FEATURE_0044: run command — derive pluginStorage from -d / -o
# Run from repository root: bash tests/test_feature_0044.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

PASS=0
FAIL=0
SKIP=0
TOTAL=0

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

assert_json_field() {
  local test_name="$1" field="$2" expected="$3" actual_json="$4"
  TOTAL=$((TOTAL + 1))
  local got
  got=$(echo "$actual_json" | jq -r "$field" 2>/dev/null)
  if [ "$got" = "$expected" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Field $field: expected '$expected', got '$got'"
    echo "    JSON: $actual_json"
    FAIL=$((FAIL + 1))
  fi
}

assert_json_field_suffix() {
  local test_name="$1" field="$2" expected_suffix="$3" actual_json="$4"
  TOTAL=$((TOTAL + 1))
  local got
  got=$(echo "$actual_json" | jq -r "$field" 2>/dev/null)
  if [[ "$got" == *"$expected_suffix" ]]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Field $field: expected to end with '$expected_suffix', got '$got'"
    FAIL=$((FAIL + 1))
  fi
}

# --- Setup: create spy44 test plugin ---

SPY_PLUGIN_DIR="$PLUGIN_DIR/spy44"
TEST_TMPDIR=$(mktemp -d)

cleanup() {
  rm -rf "$SPY_PLUGIN_DIR" "$TEST_TMPDIR"
}
trap cleanup EXIT

mkdir -p "$SPY_PLUGIN_DIR"

cat > "$SPY_PLUGIN_DIR/descriptor.json" << 'DESCEOF'
{
  "name": "spy44",
  "version": "1.0.0",
  "description": "Spy plugin for testing FEATURE_0044 -d/-o flag support",
  "active": true,
  "commands": {
    "echo": {
      "description": "Echo stdin JSON back to stdout",
      "command": "echo.sh",
      "input": {
        "pluginStorage": {
          "type": "string",
          "description": "Path to plugin storage directory",
          "required": true
        },
        "filePath": {
          "type": "string",
          "description": "Path to the input file",
          "required": false
        }
      }
    },
    "simple": {
      "description": "A command that does not need pluginStorage",
      "command": "echo.sh"
    }
  }
}
DESCEOF

cat > "$SPY_PLUGIN_DIR/echo.sh" << 'EOF'
#!/bin/bash
cat
EOF
chmod +x "$SPY_PLUGIN_DIR/echo.sh"

echo "============================================"
echo "  FEATURE_0044: run command -d / -o flags"
echo "  (derive pluginStorage from output-dir)"
echo "============================================"
echo ""

# =========================================
# Group 1: -o flag derives pluginStorage
# =========================================
echo "--- Group 1: -o flag derives pluginStorage ---"

OUT_DIR="$TEST_TMPDIR/output1"
mkdir -p "$OUT_DIR"
out=$("$CLI" run spy44 echo -o "$OUT_DIR" 2>&1); ec=$?
assert_exit_code "run spy44 echo -o exits 0" 0 "$ec"
assert_json_field_suffix "-o derives pluginStorage with correct suffix" ".pluginStorage" "/.doc.doc.md/spy44" "$out"

# Verify directory was created
if [ -d "$OUT_DIR/.doc.doc.md/spy44" ]; then
  TOTAL=$((TOTAL + 1))
  echo "  PASS: pluginStorage directory created under output dir"
  PASS=$((PASS + 1))
else
  TOTAL=$((TOTAL + 1))
  echo "  FAIL: pluginStorage directory NOT created under output dir"
  echo "    Expected: $OUT_DIR/.doc.doc.md/spy44/ to exist"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: -d flag sets inputDirectory
# =========================================
echo ""
echo "--- Group 2: -d flag sets inputDirectory ---"

INPUT_DIR="$TEST_TMPDIR/input2"
mkdir -p "$INPUT_DIR"
OUT_DIR2="$TEST_TMPDIR/output2"
mkdir -p "$OUT_DIR2"
out=$("$CLI" run spy44 echo -d "$INPUT_DIR" -o "$OUT_DIR2" 2>&1); ec=$?
assert_exit_code "run spy44 echo -d -o exits 0" 0 "$ec"
assert_json_field_suffix "-d sets inputDirectory" ".inputDirectory" "/input2" "$out"
assert_json_field_suffix "-o still derives pluginStorage" ".pluginStorage" "/.doc.doc.md/spy44" "$out"

# =========================================
# Group 3: --plugin-storage still works as manual override
# =========================================
echo ""
echo "--- Group 3: --plugin-storage still works ---"

out=$("$CLI" run spy44 echo --plugin-storage /tmp/manual-store 2>&1); ec=$?
assert_exit_code "--plugin-storage still works exits 0" 0 "$ec"
assert_json_field "--plugin-storage maps to pluginStorage" ".pluginStorage" "/tmp/manual-store" "$out"

# =========================================
# Group 4: -o takes precedence over --plugin-storage
# =========================================
echo ""
echo "--- Group 4: -o takes precedence over --plugin-storage ---"

OUT_DIR4="$TEST_TMPDIR/output4"
mkdir -p "$OUT_DIR4"
out=$("$CLI" run spy44 echo -o "$OUT_DIR4" --plugin-storage /tmp/should-be-ignored 2>/dev/null); ec=$?
assert_exit_code "-o + --plugin-storage exits 0" 0 "$ec"
assert_json_field_suffix "-o-derived storage takes precedence" ".pluginStorage" "/.doc.doc.md/spy44" "$out"

# Verify warning on stderr (capture stderr separately)
stderr_out=$("$CLI" run spy44 echo -o "$OUT_DIR4" --plugin-storage /tmp/should-be-ignored 2>&1 1>/dev/null); ec=$?
assert_contains "-o + --plugin-storage emits warning" "Warning" "$stderr_out"

# =========================================
# Group 5: -d validated to exist
# =========================================
echo ""
echo "--- Group 5: -d validation ---"

out=$("$CLI" run spy44 echo -d /nonexistent/path/12345 -o "$TEST_TMPDIR" 2>&1); ec=$?
assert_exit_code "-d with nonexistent dir exits 1" 1 "$ec"
assert_contains "-d nonexistent shows error" "not exist" "$out"

# =========================================
# Group 6: Security - output dir canonicalization and traversal prevention
# =========================================
echo ""
echo "--- Group 6: Security - path canonicalization ---"

OUT_DIR6="$TEST_TMPDIR/output6"
mkdir -p "$OUT_DIR6"
out=$("$CLI" run spy44 echo -o "$OUT_DIR6" 2>&1); ec=$?
assert_exit_code "-o canonicalization exits 0" 0 "$ec"
# The pluginStorage should be an absolute canonical path (no .. components)
ps_val=$(echo "$out" | jq -r '.pluginStorage // ""' 2>/dev/null)
TOTAL=$((TOTAL + 1))
if [[ "$ps_val" != *".."* ]] && [[ "$ps_val" == /* ]]; then
  echo "  PASS: pluginStorage is canonical absolute path"
  PASS=$((PASS + 1))
else
  echo "  FAIL: pluginStorage is not canonical"
  echo "    Got: $ps_val"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 7: Help text documents -d and -o
# =========================================
echo ""
echo "--- Group 7: Help text includes -d and -o ---"

out=$("$CLI" run --help 2>&1); ec=$?
assert_contains "run --help documents -o option" "-o" "$out"
assert_contains "run --help documents -d option" "-d" "$out"

out=$("$CLI" run spy44 --help 2>&1); ec=$?
assert_exit_code "run spy44 --help exits 0" 0 "$ec"

# =========================================
# Group 8: command-level --help mentions -o derives pluginStorage
# =========================================
echo ""
echo "--- Group 8: command --help notes -o derives pluginStorage ---"

out=$("$CLI" run spy44 echo --help 2>&1); ec=$?
assert_exit_code "run spy44 echo --help exits 0" 0 "$ec"

# =========================================
# Group 9: Combined with other flags
# =========================================
echo ""
echo "--- Group 9: Combined flags ---"

OUT_DIR9="$TEST_TMPDIR/output9"
mkdir -p "$OUT_DIR9"
out=$("$CLI" run spy44 echo -o "$OUT_DIR9" --file /tmp/test.txt --category ham -- extra=42 2>&1); ec=$?
assert_exit_code "combined -o + other flags exits 0" 0 "$ec"
assert_json_field_suffix "combined: pluginStorage derived" ".pluginStorage" "/.doc.doc.md/spy44" "$out"
assert_json_field "combined: filePath" ".filePath" "/tmp/test.txt" "$out"
assert_json_field "combined: category" ".category" "ham" "$out"
assert_json_field "combined: extra" ".extra" "42" "$out"

# =========================================
# Group 10: Existing test_feature_0043 compatibility
# =========================================
echo ""
echo "--- Group 10: Backward compatibility ---"

# No-flag invocation still produces empty JSON
out=$("$CLI" run spy44 echo 2>&1); ec=$?
assert_exit_code "echo with no flags still exits 0" 0 "$ec"
assert_json_field "no flags: still produces empty JSON" "." "{}" "$out"

# --plugin-storage alone (no -o) still works
out=$("$CLI" run spy44 echo --plugin-storage /tmp/bc 2>&1); ec=$?
assert_exit_code "--plugin-storage alone exits 0" 0 "$ec"
assert_json_field "--plugin-storage alone sets pluginStorage" ".pluginStorage" "/tmp/bc" "$out"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
if [ "$SKIP" -gt 0 ]; then
  echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped (of $TOTAL total)"
else
  echo "  Results: $PASS passed, $FAIL failed (total: $TOTAL)"
fi
echo "============================================"
[ "$FAIL" -eq 0 ]
