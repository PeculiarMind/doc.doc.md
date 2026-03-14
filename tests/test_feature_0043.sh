#!/bin/bash
# Test suite for FEATURE_0043: Plugin Command Runner (run command)
# Run from repository root: bash tests/test_feature_0043.sh

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

# --- Setup: create spy43 test plugin ---

SPY_PLUGIN_DIR="$PLUGIN_DIR/spy43"

cleanup() {
  rm -rf "$SPY_PLUGIN_DIR"
}
trap cleanup EXIT

mkdir -p "$SPY_PLUGIN_DIR"

cat > "$SPY_PLUGIN_DIR/descriptor.json" << 'EOF'
{
  "name": "spy43",
  "version": "1.0.0",
  "description": "Spy plugin for testing FEATURE_0043 run command",
  "active": true,
  "commands": {
    "echo": {
      "description": "Echo stdin JSON back to stdout",
      "command": "echo.sh"
    },
    "fail": {
      "description": "Exit with code 42",
      "command": "fail.sh"
    }
  }
}
EOF

cat > "$SPY_PLUGIN_DIR/echo.sh" << 'EOF'
#!/bin/bash
cat
EOF
chmod +x "$SPY_PLUGIN_DIR/echo.sh"

cat > "$SPY_PLUGIN_DIR/fail.sh" << 'EOF'
#!/bin/bash
exit 42
EOF
chmod +x "$SPY_PLUGIN_DIR/fail.sh"

echo "============================================"
echo "  FEATURE_0043: Plugin Command Runner"
echo "  (run command)"
echo "============================================"
echo ""

# =========================================
# Group 1: run with no args → top-level usage, exit 0
# =========================================
echo "--- Group 1: run with no arguments ---"

out=$("$CLI" run 2>&1); ec=$?
assert_exit_code "run with no args exits 0" 0 "$ec"
assert_contains "run with no args shows Usage:" "Usage:" "$out"

# =========================================
# Group 2: run --help → top-level usage with plugin list, exit 0
# =========================================
echo ""
echo "--- Group 2: run --help ---"

out=$("$CLI" run --help 2>&1); ec=$?
assert_exit_code "run --help exits 0" 0 "$ec"
assert_contains "run --help shows Usage:" "Usage:" "$out"
assert_contains "run --help lists crm114 plugin" "crm114" "$out"
assert_contains "run --help lists spy43 plugin" "spy43" "$out"

# =========================================
# Group 3: run <pluginName> --help → command list for that plugin, exit 0
# =========================================
echo ""
echo "--- Group 3: run <pluginName> --help ---"

out=$("$CLI" run spy43 --help 2>&1); ec=$?
assert_exit_code "run spy43 --help exits 0" 0 "$ec"
assert_contains "run spy43 --help shows 'echo' command" "echo" "$out"
assert_contains "run spy43 --help shows 'fail' command" "fail" "$out"
assert_contains "run spy43 --help shows echo description" "Echo stdin JSON" "$out"

out=$("$CLI" run crm114 --help 2>&1); ec=$?
assert_exit_code "run crm114 --help exits 0" 0 "$ec"
assert_contains "run crm114 --help shows listCategories" "listCategories" "$out"
assert_contains "run crm114 --help shows learn" "learn" "$out"
assert_contains "run crm114 --help shows unlearn" "unlearn" "$out"

# =========================================
# Group 4: Error cases
# =========================================
echo ""
echo "--- Group 4: Error cases ---"

# Plugin name with path traversal
out=$("$CLI" run "../malicious" 2>&1); ec=$?
assert_exit_code "path traversal in plugin name exits 1" 1 "$ec"
assert_contains "path traversal shows error" "not found" "$out"

# Unknown plugin
out=$("$CLI" run "nonexistent_plugin_xyz" 2>&1); ec=$?
assert_exit_code "unknown plugin exits 1" 1 "$ec"
assert_contains "unknown plugin shows error" "not found" "$out"

# Plugin specified but no command (and not --help)
out=$("$CLI" run spy43 2>&1); ec=$?
assert_exit_code "run plugin with no command exits 1" 1 "$ec"
assert_contains "run plugin with no command shows error" "required" "$out"

# Unknown command
out=$("$CLI" run spy43 "nonexistent_cmd_xyz" 2>&1); ec=$?
assert_exit_code "unknown command exits 1" 1 "$ec"
assert_contains "unknown command shows error" "not found" "$out"

# =========================================
# Group 5: JSON input construction
# =========================================
echo ""
echo "--- Group 5: JSON input construction ---"

# Empty JSON when no flags
out=$("$CLI" run spy43 echo 2>&1); ec=$?
assert_exit_code "run spy43 echo (no flags) exits 0" 0 "$ec"
assert_json_field "no flags: produces valid JSON object" "." "{}" "$out"

# --file maps to filePath
out=$("$CLI" run spy43 echo --file /tmp/test.txt 2>&1); ec=$?
assert_exit_code "run spy43 echo --file exits 0" 0 "$ec"
assert_json_field "--file maps to filePath" ".filePath" "/tmp/test.txt" "$out"

# --plugin-storage maps to pluginStorage
out=$("$CLI" run spy43 echo --plugin-storage /tmp/store 2>&1); ec=$?
assert_exit_code "run spy43 echo --plugin-storage exits 0" 0 "$ec"
assert_json_field "--plugin-storage maps to pluginStorage" ".pluginStorage" "/tmp/store" "$out"

# --category maps to category
out=$("$CLI" run spy43 echo --category spam 2>&1); ec=$?
assert_exit_code "run spy43 echo --category exits 0" 0 "$ec"
assert_json_field "--category maps to category" ".category" "spam" "$out"

# key=value after -- merged into JSON
out=$("$CLI" run spy43 echo -- myKey=myValue 2>&1); ec=$?
assert_exit_code "run spy43 echo -- key=value exits 0" 0 "$ec"
assert_json_field "key=value after -- merged into JSON" ".myKey" "myValue" "$out"

# All flags combined
out=$("$CLI" run spy43 echo --file /tmp/doc.txt --plugin-storage /tmp/s --category ham -- extra=42 2>&1); ec=$?
assert_exit_code "combined flags exits 0" 0 "$ec"
assert_json_field "combined: filePath" ".filePath" "/tmp/doc.txt" "$out"
assert_json_field "combined: pluginStorage" ".pluginStorage" "/tmp/s" "$out"
assert_json_field "combined: category" ".category" "ham" "$out"
assert_json_field "combined: extra key from --" ".extra" "42" "$out"

# =========================================
# Group 6: Exit code propagation
# =========================================
echo ""
echo "--- Group 6: Exit code propagation ---"

"$CLI" run spy43 fail >/dev/null 2>&1; ec=$?
assert_exit_code "exit code from plugin script propagated (42)" 42 "$ec"

# =========================================
# Group 7: Security — path traversal and command injection prevention
# =========================================
echo ""
echo "--- Group 7: Security ---"

# Deep path traversal in plugin name
out=$("$CLI" run "../../etc/passwd" 2>&1); ec=$?
assert_exit_code "deep path traversal in plugin name exits 1" 1 "$ec"

# Plugin name with slash (treated as path)
out=$("$CLI" run "some/plugin" 2>&1); ec=$?
assert_exit_code "plugin name with slash exits 1" 1 "$ec"

# Command name that tries path traversal — validated against descriptor.json
out=$("$CLI" run crm114 "../../malicious" 2>&1); ec=$?
assert_exit_code "path traversal in command name exits 1" 1 "$ec"
assert_contains "path traversal in command name shows error" "not found" "$out"

# Command name not in descriptor.json (arbitrary script execution prevented)
out=$("$CLI" run crm114 "main.sh" 2>&1); ec=$?
# main.sh is the process command script, but "main.sh" is not a valid command name
assert_exit_code "raw script name as command exits 1" 1 "$ec"
assert_contains "raw script name as command shows error" "not found" "$out"

# =========================================
# Group 8: Main --help lists 'run' command
# =========================================
echo ""
echo "--- Group 8: Main --help includes 'run' ---"

out=$("$CLI" --help 2>&1); ec=$?
assert_exit_code "main --help exits 0" 0 "$ec"
assert_contains "main --help lists 'run' command" "run" "$out"

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
