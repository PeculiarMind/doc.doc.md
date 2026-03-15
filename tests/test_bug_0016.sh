#!/bin/bash
# Test suite for BUG_0016: Help shows JSON field names instead of CLI flags,
# and csslearn/cssunlearn not checked by installed.sh
# Run from repository root: bash tests/test_bug_0016.sh

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

# --- Setup: create spy16 test plugin with interactive + usage block ---

SPY_PLUGIN_DIR="$PLUGIN_DIR/spy16"
TEST_TMPDIR="$(mktemp -d)"

cleanup() {
  rm -rf "$SPY_PLUGIN_DIR" "$TEST_TMPDIR"
}
trap cleanup EXIT

mkdir -p "$SPY_PLUGIN_DIR"

# Spy plugin with interactive command that has a "usage" block and a non-interactive command
cat > "$SPY_PLUGIN_DIR/descriptor.json" << 'DESCEOF'
{
  "name": "spy16",
  "version": "1.0.0",
  "description": "Spy plugin for testing BUG_0016 help and installed check",
  "active": true,
  "commands": {
    "interact": {
      "description": "Interactive command with usage block",
      "command": "interact.sh",
      "interactive": true,
      "input": {
        "pluginStorage": {
          "type": "string",
          "description": "Plugin storage directory.",
          "required": true
        },
        "inputDirectory": {
          "type": "string",
          "description": "Path to directory of input documents.",
          "required": true
        }
      },
      "usage": [
        {
          "flag": "-o <output-dir>",
          "description": "Output directory. pluginStorage is derived as <output-dir>/.doc.doc.md/spy16/"
        },
        {
          "flag": "-d <input-dir>",
          "description": "Input directory containing documents to process."
        }
      ],
      "output": {}
    },
    "batch": {
      "description": "Non-interactive command with no usage block",
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

cat > "$SPY_PLUGIN_DIR/interact.sh" << 'EOF'
#!/bin/bash
echo "ARG1=$1"
echo "ARG2=$2"
EOF
chmod +x "$SPY_PLUGIN_DIR/interact.sh"

cat > "$SPY_PLUGIN_DIR/batch.sh" << 'EOF'
#!/bin/bash
cat
EOF
chmod +x "$SPY_PLUGIN_DIR/batch.sh"

mkdir -p "$TEST_TMPDIR/output" "$TEST_TMPDIR/input"

echo "============================================"
echo "  BUG_0016: Help text & installed check"
echo "============================================"
echo ""

# =========================================
# Group 1: Interactive command help shows CLI flags from "usage" block
# =========================================
echo "--- Group 1: interactive command help shows CLI flags ---"

out=$("$CLI" run spy16 interact --help 2>&1); ec=$?
assert_exit_code "interactive --help exits 0" 0 "$ec"
assert_contains "interactive help shows -o flag" "-o <output-dir>" "$out"
assert_contains "interactive help shows -d flag" "-d <input-dir>" "$out"
assert_contains "interactive help shows -o description" "Output directory" "$out"
assert_contains "interactive help shows -d description" "Input directory" "$out"

# =========================================
# Group 2: Interactive command help does NOT show raw JSON field names
# =========================================
echo ""
echo "--- Group 2: interactive command help hides JSON field names ---"

out=$("$CLI" run spy16 interact --help 2>&1); ec=$?
assert_not_contains "interactive help has no 'pluginStorage' as field" "pluginStorage" "$out"
assert_not_contains "interactive help has no 'inputDirectory' as field" "inputDirectory" "$out"
assert_not_contains "interactive help has no 'Input fields:' header" "Input fields:" "$out"

# =========================================
# Group 3: Non-interactive command help still shows input/output fields
# =========================================
echo ""
echo "--- Group 3: non-interactive command help shows input fields ---"

out=$("$CLI" run spy16 batch --help 2>&1); ec=$?
assert_exit_code "non-interactive --help exits 0" 0 "$ec"
assert_contains "non-interactive help shows pluginStorage field" "pluginStorage" "$out"
assert_contains "non-interactive help shows filePath field" "filePath" "$out"
assert_contains "non-interactive help shows 'Input fields:' header" "Input fields:" "$out"

# =========================================
# Group 4: crm114 train --help shows CLI flags, not JSON fields
# =========================================
echo ""
echo "--- Group 4: crm114 train --help shows CLI flags ---"

out=$("$CLI" run crm114 train --help 2>&1); ec=$?
assert_exit_code "crm114 train --help exits 0" 0 "$ec"
assert_contains "crm114 train help shows -o flag" "-o" "$out"
assert_contains "crm114 train help shows -d flag" "-d" "$out"
assert_not_contains "crm114 train help has no '--inputDirectory'" "--inputDirectory" "$out"
assert_not_contains "crm114 train help has no 'inputDirectory' raw field" "inputDirectory" "$out"

# =========================================
# Group 5: crm114 learn/unlearn --help still shows input fields (non-interactive)
# =========================================
echo ""
echo "--- Group 5: crm114 non-interactive commands unchanged ---"

out=$("$CLI" run crm114 learn --help 2>&1); ec=$?
assert_exit_code "crm114 learn --help exits 0" 0 "$ec"
assert_contains "crm114 learn help shows 'Input fields:'" "Input fields:" "$out"
assert_contains "crm114 learn help shows category field" "category" "$out"

out=$("$CLI" run crm114 unlearn --help 2>&1); ec=$?
assert_exit_code "crm114 unlearn --help exits 0" 0 "$ec"
assert_contains "crm114 unlearn help shows 'Input fields:'" "Input fields:" "$out"

# =========================================
# Group 6: crm114 descriptor.json has usage block for train command
# =========================================
echo ""
echo "--- Group 6: crm114 descriptor has usage block ---"

crm114_desc="$PLUGIN_DIR/crm114/descriptor.json"
usage_len=$(jq -r '.commands.train.usage // [] | length' "$crm114_desc" 2>/dev/null)
assert_eq "crm114 train has usage array with entries" "true" "$([ "$usage_len" -gt 0 ] && echo true || echo false)"

has_o_flag=$(jq -r '.commands.train.usage[]? | select(.flag | test("-o")) | .flag' "$crm114_desc" 2>/dev/null)
assert_contains "crm114 train usage has -o flag" "-o" "$has_o_flag"

has_d_flag=$(jq -r '.commands.train.usage[]? | select(.flag | test("-d")) | .flag' "$crm114_desc" 2>/dev/null)
assert_contains "crm114 train usage has -d flag" "-d" "$has_d_flag"

# =========================================
# Group 7: learn.sh and unlearn.sh use "crm -e" instead of csslearn/cssunlearn
# =========================================
echo ""
echo "--- Group 7: learn.sh and unlearn.sh use crm -e ---"

learn_src=$(cat "$PLUGIN_DIR/crm114/learn.sh" 2>/dev/null)
assert_not_contains "learn.sh does not call csslearn" "csslearn" "$learn_src"
assert_contains "learn.sh uses crm for learning" "crm" "$learn_src"

unlearn_src=$(cat "$PLUGIN_DIR/crm114/unlearn.sh" 2>/dev/null)
assert_not_contains "unlearn.sh does not call cssunlearn" "cssunlearn" "$unlearn_src"
assert_contains "unlearn.sh uses crm for unlearning" "crm" "$unlearn_src"

# =========================================
# Group 8: train.sh uses "crm -e" instead of csslearn/cssunlearn
# =========================================
echo ""
echo "--- Group 8: train.sh uses crm -e ---"

train_src=$(cat "$PLUGIN_DIR/crm114/train.sh" 2>/dev/null)
assert_not_contains "train.sh does not call csslearn" "csslearn" "$train_src"
assert_not_contains "train.sh does not call cssunlearn" "cssunlearn" "$train_src"
assert_contains "train.sh uses crm for learning" "crm" "$train_src"

# =========================================
# Group 9: installed.sh checks for crm binary (not csslearn/cssunlearn)
# =========================================
echo ""
echo "--- Group 9: installed.sh checks crm binary ---"

installed_src=$(cat "$PLUGIN_DIR/crm114/installed.sh" 2>/dev/null)
assert_contains "installed.sh checks for crm" "crm" "$installed_src"
assert_not_contains "installed.sh does not reference csslearn" "csslearn" "$installed_src"
assert_not_contains "installed.sh does not reference cssunlearn" "cssunlearn" "$installed_src"

# =========================================
# Group 10: Backward compatibility — existing tests still pass
# =========================================
echo ""
echo "--- Group 10: backward compatibility ---"

out=$("$CLI" run crm114 listCategories --help 2>&1); ec=$?
assert_exit_code "crm114 listCategories --help still exits 0" 0 "$ec"

out=$("$CLI" run crm114 --help 2>&1); ec=$?
assert_exit_code "crm114 --help still exits 0" 0 "$ec"
assert_contains "crm114 --help still shows train" "train" "$out"

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
