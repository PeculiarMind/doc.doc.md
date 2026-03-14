#!/bin/bash
# Test suite for BUG_0014: run <plugin> <command> --help treated as unknown option
# Run from repository root: bash tests/test_bug_0014.sh

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

# --- Setup: create spy14 test plugin ---

SPY_PLUGIN_DIR="$PLUGIN_DIR/spy14"

cleanup() {
  rm -rf "$SPY_PLUGIN_DIR"
}
trap cleanup EXIT

mkdir -p "$SPY_PLUGIN_DIR"

cat > "$SPY_PLUGIN_DIR/descriptor.json" << 'DESCEOF'
{
  "name": "spy14",
  "version": "1.0.0",
  "description": "Spy plugin for testing BUG_0014 command-level help",
  "active": true,
  "commands": {
    "greet": {
      "description": "Say hello with customizable greeting",
      "command": "greet.sh",
      "input": {
        "name": {
          "type": "string",
          "description": "Name of the person to greet",
          "required": true
        },
        "pluginStorage": {
          "type": "string",
          "description": "Path to storage directory",
          "required": false
        }
      },
      "output": {
        "greeting": {
          "type": "string",
          "description": "The generated greeting message"
        }
      }
    },
    "noop": {
      "description": "Does nothing — no input or output fields declared",
      "command": "noop.sh"
    }
  }
}
DESCEOF

cat > "$SPY_PLUGIN_DIR/greet.sh" << 'EOF'
#!/bin/bash
cat
EOF
chmod +x "$SPY_PLUGIN_DIR/greet.sh"

cat > "$SPY_PLUGIN_DIR/noop.sh" << 'EOF'
#!/bin/bash
echo '{}'
EOF
chmod +x "$SPY_PLUGIN_DIR/noop.sh"

echo "============================================"
echo "  BUG_0014: run <plugin> <command> --help"
echo "  (command-level help)"
echo "============================================"
echo ""

# =========================================
# Group 1: run <plugin> <command> --help exits 0
# =========================================
echo "--- Group 1: command-level --help exits 0 ---"

out=$("$CLI" run spy14 greet --help 2>&1); ec=$?
assert_exit_code "run spy14 greet --help exits 0" 0 "$ec"

out=$("$CLI" run crm114 train --help 2>&1); ec=$?
assert_exit_code "run crm114 train --help exits 0" 0 "$ec"

out=$("$CLI" run crm114 learn --help 2>&1); ec=$?
assert_exit_code "run crm114 learn --help exits 0" 0 "$ec"

# =========================================
# Group 2: command-level --help shows command description
# =========================================
echo ""
echo "--- Group 2: command-level --help shows description ---"

out=$("$CLI" run spy14 greet --help 2>&1); ec=$?
assert_contains "greet --help shows command description" "Say hello with customizable greeting" "$out"

out=$("$CLI" run crm114 learn --help 2>&1); ec=$?
assert_contains "learn --help shows command description" "train a category model" "$out"

# =========================================
# Group 3: command-level --help shows input fields
# =========================================
echo ""
echo "--- Group 3: command-level --help shows input fields ---"

out=$("$CLI" run spy14 greet --help 2>&1); ec=$?
assert_contains "greet --help shows 'name' input field" "name" "$out"
assert_contains "greet --help shows 'pluginStorage' input field" "pluginStorage" "$out"
assert_contains "greet --help shows field type" "string" "$out"
assert_contains "greet --help shows required flag" "required" "$out"

out=$("$CLI" run crm114 learn --help 2>&1); ec=$?
assert_contains "learn --help shows 'category' input field" "category" "$out"
assert_contains "learn --help shows 'filePath' input field" "filePath" "$out"

# =========================================
# Group 4: command-level --help shows output fields
# =========================================
echo ""
echo "--- Group 4: command-level --help shows output fields ---"

out=$("$CLI" run spy14 greet --help 2>&1); ec=$?
assert_contains "greet --help shows 'greeting' output field" "greeting" "$out"

out=$("$CLI" run crm114 learn --help 2>&1); ec=$?
assert_contains "learn --help shows 'success' output field" "success" "$out"

# =========================================
# Group 5: command with no input/output fields declared
# =========================================
echo ""
echo "--- Group 5: command with no declared fields ---"

out=$("$CLI" run spy14 noop --help 2>&1); ec=$?
assert_exit_code "noop --help exits 0" 0 "$ec"
assert_contains "noop --help shows command description" "Does nothing" "$out"

# =========================================
# Group 6: no self-referential error message
# =========================================
echo ""
echo "--- Group 6: no self-referential error message ---"

out=$("$CLI" run spy14 greet --help 2>&1); ec=$?
assert_not_contains "greet --help has no Error: message" "Error:" "$out"
assert_not_contains "greet --help has no 'Unknown option' message" "Unknown option" "$out"

out=$("$CLI" run crm114 train --help 2>&1); ec=$?
assert_not_contains "crm114 train --help has no Error: message" "Error:" "$out"

# =========================================
# Group 7: existing help levels still work
# =========================================
echo ""
echo "--- Group 7: existing help levels unaffected ---"

out=$("$CLI" run --help 2>&1); ec=$?
assert_exit_code "run --help still exits 0" 0 "$ec"
assert_contains "run --help still shows Usage:" "Usage:" "$out"

out=$("$CLI" run crm114 --help 2>&1); ec=$?
assert_exit_code "run crm114 --help still exits 0" 0 "$ec"
assert_contains "run crm114 --help still shows listCategories" "listCategories" "$out"

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
