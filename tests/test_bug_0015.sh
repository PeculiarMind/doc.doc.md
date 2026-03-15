#!/bin/bash
# Test suite for BUG_0015: run command incompatible with interactive plugin commands
# Run from repository root: bash tests/test_bug_0015.sh

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

# --- Setup: create spy15 test plugin with interactive command ---

SPY_PLUGIN_DIR="$PLUGIN_DIR/spy15"
TEST_TMPDIR="$(mktemp -d)"

cleanup() {
  rm -rf "$SPY_PLUGIN_DIR" "$TEST_TMPDIR"
}
trap cleanup EXIT

mkdir -p "$SPY_PLUGIN_DIR"

# Spy plugin with both interactive and non-interactive commands
cat > "$SPY_PLUGIN_DIR/descriptor.json" << 'DESCEOF'
{
  "name": "spy15",
  "version": "1.0.0",
  "description": "Spy plugin for testing BUG_0015 interactive command support",
  "active": true,
  "commands": {
    "interact": {
      "description": "Interactive command that receives positional args",
      "command": "interact.sh",
      "interactive": true,
      "input": {
        "pluginStorage": {
          "type": "string",
          "description": "Plugin storage directory. Derived automatically from -o.",
          "required": true
        },
        "inputDirectory": {
          "type": "string",
          "description": "Path to directory of input documents.",
          "required": true
        }
      },
      "output": {}
    },
    "batch": {
      "description": "Non-interactive command that receives JSON on stdin",
      "command": "batch.sh",
      "input": {
        "pluginStorage": {
          "type": "string",
          "description": "Plugin storage directory.",
          "required": true
        },
        "filePath": {
          "type": "string",
          "description": "Path to file to process.",
          "required": true
        }
      },
      "output": {
        "result": {
          "type": "string",
          "description": "Processing result."
        }
      }
    }
  }
}
DESCEOF

# Interactive command: prints positional args received (does NOT read stdin JSON)
cat > "$SPY_PLUGIN_DIR/interact.sh" << 'EOF'
#!/bin/bash
# Spy: echo positional args so tests can verify them
echo "ARG1=$1"
echo "ARG2=$2"
echo "ARGC=$#"
EOF
chmod +x "$SPY_PLUGIN_DIR/interact.sh"

# Non-interactive command: reads JSON from stdin (existing behavior)
cat > "$SPY_PLUGIN_DIR/batch.sh" << 'EOF'
#!/bin/bash
cat
EOF
chmod +x "$SPY_PLUGIN_DIR/batch.sh"

# Create test directories
mkdir -p "$TEST_TMPDIR/output"
mkdir -p "$TEST_TMPDIR/input"
echo "test content" > "$TEST_TMPDIR/input/doc1.txt"

echo "============================================"
echo "  BUG_0015: Interactive plugin commands"
echo "============================================"
echo ""

# =========================================
# Group 1: Interactive command receives positional args
# =========================================
echo "--- Group 1: interactive command receives positional args ---"

out=$("$CLI" run spy15 interact -o "$TEST_TMPDIR/output" -d "$TEST_TMPDIR/input" 2>&1); ec=$?
assert_exit_code "interactive command exits 0" 0 "$ec"
assert_contains "interactive command receives pluginStorage as arg1" "ARG1=" "$out"
assert_contains "interactive command receives inputDirectory as arg2" "ARG2=" "$out"
# Verify the actual path values
assert_contains "arg1 contains .doc.doc.md/spy15" ".doc.doc.md/spy15" "$out"
assert_contains "arg2 is the input directory" "$TEST_TMPDIR/input" "$out"
assert_contains "interactive command receives exactly 2 args" "ARGC=2" "$out"

# =========================================
# Group 2: Non-interactive command still receives JSON via stdin
# =========================================
echo ""
echo "--- Group 2: non-interactive command still receives JSON via stdin ---"

out=$("$CLI" run spy15 batch -o "$TEST_TMPDIR/output" --file "$TEST_TMPDIR/input/doc1.txt" 2>&1); ec=$?
assert_exit_code "non-interactive command exits 0" 0 "$ec"
assert_contains "non-interactive command receives JSON with pluginStorage" "pluginStorage" "$out"
assert_contains "non-interactive command receives JSON with filePath" "filePath" "$out"

# =========================================
# Group 3: Interactive command does NOT receive JSON on stdin
# =========================================
echo ""
echo "--- Group 3: interactive command does NOT receive JSON on stdin ---"

out=$("$CLI" run spy15 interact -o "$TEST_TMPDIR/output" -d "$TEST_TMPDIR/input" 2>&1); ec=$?
assert_not_contains "interactive command stdout has no JSON braces" "{" "$out"
assert_not_contains "interactive command stdout has no 'pluginStorage' JSON key" '"pluginStorage"' "$out"

# =========================================
# Group 4: descriptor.json "interactive" field is respected
# =========================================
echo ""
echo "--- Group 4: crm114 train descriptor has interactive field ---"

# Check that crm114 descriptor now has interactive: true for train
crm114_desc="$PLUGIN_DIR/crm114/descriptor.json"
interactive_val=$(jq -r '.commands.train.interactive // "missing"' "$crm114_desc" 2>/dev/null)
assert_eq "crm114 train has interactive: true" "true" "$interactive_val"

# Check that input_dir has been renamed to inputDirectory
input_dir_val=$(jq -r '.commands.train.input.input_dir // "missing"' "$crm114_desc" 2>/dev/null)
assert_eq "crm114 train no longer has input_dir field" "missing" "$input_dir_val"

inputDirectory_val=$(jq -r '.commands.train.input.inputDirectory // "missing"' "$crm114_desc" 2>/dev/null)
assert_not_contains "crm114 train has inputDirectory field" "missing" "$inputDirectory_val"

# Check descriptions no longer mention "positional argument"
ps_desc=$(jq -r '.commands.train.input.pluginStorage.description' "$crm114_desc" 2>/dev/null)
assert_not_contains "pluginStorage description no longer mentions positional" "positional" "$ps_desc"

id_desc=$(jq -r '.commands.train.input.inputDirectory.description' "$crm114_desc" 2>/dev/null)
assert_not_contains "inputDirectory description no longer mentions positional" "positional" "$id_desc"

# =========================================
# Group 5: Backward compatibility — existing non-interactive commands unaffected
# =========================================
echo ""
echo "--- Group 5: backward compatibility ---"

# crm114 learn (non-interactive) should still work with JSON
out=$("$CLI" run crm114 learn --help 2>&1); ec=$?
assert_exit_code "crm114 learn --help still exits 0" 0 "$ec"

# crm114 listCategories (non-interactive) should still get JSON
out=$("$CLI" run crm114 listCategories --help 2>&1); ec=$?
assert_exit_code "crm114 listCategories --help still exits 0" 0 "$ec"

# Feature 0043 and 0044 tests should still pass (run their core scenarios)
out=$("$CLI" run spy15 batch --plugin-storage "$TEST_TMPDIR/output" --file "$TEST_TMPDIR/input/doc1.txt" 2>&1); ec=$?
assert_exit_code "non-interactive --plugin-storage still works" 0 "$ec"
assert_contains "non-interactive JSON contains pluginStorage" "pluginStorage" "$out"

# =========================================
# Group 6: Help text reflects interactive mode
# =========================================
echo ""
echo "--- Group 6: help text reflects interactive mode ---"

out=$("$CLI" run spy15 interact --help 2>&1); ec=$?
assert_exit_code "interactive command --help exits 0" 0 "$ec"
assert_contains "interactive help shows command description" "Interactive command" "$out"

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
