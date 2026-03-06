#!/bin/bash
# Test suite for FEATURE_0026: Interactive Progress Display for Process Command
# Run from repository root: bash tests/test_feature_0026.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
UI_SH="$REPO_ROOT/doc.doc.md/components/ui.sh"

PASS=0
FAIL=0
TOTAL=0

INPUT_DIR=""
OUTPUT_DIR=""

cleanup() {
  [ -n "$INPUT_DIR" ] && [ -d "$INPUT_DIR" ] && rm -rf "$INPUT_DIR"
  [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ] && rm -rf "$OUTPUT_DIR"
}
trap cleanup EXIT

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
echo "  FEATURE_0026: Interactive Progress Display"
echo "============================================"
echo ""

# =========================================
# Group 1: Progress functions exist in ui.sh
# =========================================
echo "--- Group 1: Progress functions defined in ui.sh ---"

for func in ui_progress_init ui_progress_update ui_progress_done; do
  TOTAL=$((TOTAL + 1))
  if grep -q "^${func}()" "$UI_SH" 2>/dev/null; then
    echo "  PASS: $func defined in ui.sh"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $func not defined in ui.sh"
    FAIL=$((FAIL + 1))
  fi
done

# =========================================
# Group 2: --no-progress flag suppresses ANSI
# =========================================
echo ""
echo "--- Group 2: --no-progress flag suppresses ANSI output ---"

INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
echo "hello world" > "$INPUT_DIR/test.txt"

# Run with --no-progress
stderr_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" --no-progress 2>&1 1>/dev/null)
exit_code=$?
assert_exit_code "--no-progress exits 0" "0" "$exit_code"

# ANSI escape sequences start with ESC[ (0x1b 0x5b)
TOTAL=$((TOTAL + 1))
if echo "$stderr_output" | grep -qP '\x1b\['; then
  echo "  FAIL: --no-progress should suppress all ANSI escape codes"
  echo "    Found ANSI codes in stderr"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: --no-progress suppresses ANSI escape codes"
  PASS=$((PASS + 1))
fi

# Cleanup for next group
rm -rf "$INPUT_DIR" "$OUTPUT_DIR"

# =========================================
# Group 3: --progress flag is accepted
# =========================================
echo ""
echo "--- Group 3: --progress flag is accepted ---"

INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
echo "test file" > "$INPUT_DIR/file1.txt"

# --progress should not cause an error
output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" --progress 2>&1)
exit_code=$?
assert_exit_code "--progress exits 0" "0" "$exit_code"

# Cleanup for next group
rm -rf "$INPUT_DIR" "$OUTPUT_DIR"

# =========================================
# Group 4: Non-interactive (piped) suppresses ANSI
# =========================================
echo ""
echo "--- Group 4: Non-interactive mode suppresses ANSI ---"

INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
echo "file content" > "$INPUT_DIR/data.txt"

# Piped output (non-TTY) should not contain ANSI codes
stderr_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" 2>&1 1>/dev/null)
exit_code=$?
assert_exit_code "piped process exits 0" "0" "$exit_code"

TOTAL=$((TOTAL + 1))
if echo "$stderr_output" | grep -qP '\x1b\['; then
  echo "  FAIL: piped mode should not emit ANSI escape codes"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: piped mode does not emit ANSI escape codes"
  PASS=$((PASS + 1))
fi

# Cleanup for next group
rm -rf "$INPUT_DIR" "$OUTPUT_DIR"

# =========================================
# Group 5: Summary line printed after processing
# =========================================
echo ""
echo "--- Group 5: Summary line after processing ---"

INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
echo "sample" > "$INPUT_DIR/a.txt"
echo "sample" > "$INPUT_DIR/b.txt"

stderr_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" --no-progress 2>&1 1>/dev/null)
exit_code=$?
assert_exit_code "process with 2 files exits 0" "0" "$exit_code"
assert_contains "summary line mentions Processed" "Processed" "$stderr_output"
assert_contains "summary line mentions documents" "documents" "$stderr_output"

# Cleanup for next group
rm -rf "$INPUT_DIR" "$OUTPUT_DIR"

# =========================================
# Group 6: Backward compatibility
# =========================================
echo ""
echo "--- Group 6: Backward compatibility ---"

INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
echo "compat test" > "$INPUT_DIR/compat.txt"

# Standard process without progress flags still works
json_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" 2>/dev/null)
exit_code=$?
assert_exit_code "process without flags exits 0" "0" "$exit_code"
assert_contains "JSON output has filePath" "filePath" "$json_output"

TOTAL=$((TOTAL + 1))
if [ -f "$OUTPUT_DIR/compat.txt.md" ]; then
  echo "  PASS: sidecar file created without progress flags"
  PASS=$((PASS + 1))
else
  echo "  FAIL: sidecar file not created without progress flags"
  FAIL=$((FAIL + 1))
fi

# Cleanup for next group
rm -rf "$INPUT_DIR" "$OUTPUT_DIR"

# =========================================
# Group 7: Help text documents new flags
# =========================================
echo ""
echo "--- Group 7: Help text documents new flags ---"

help_output=$(bash "$CLI" --help 2>&1)
assert_contains "help mentions --progress" "--progress" "$help_output"
assert_contains "help mentions --no-progress" "--no-progress" "$help_output"

# =========================================
# Group 8: JSON stdout is not polluted by progress
# =========================================
echo ""
echo "--- Group 8: JSON stdout not polluted ---"

INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
echo "json test" > "$INPUT_DIR/jsonfile.txt"

json_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" --no-progress 2>/dev/null)
exit_code=$?
assert_exit_code "process with --no-progress exits 0" "0" "$exit_code"

TOTAL=$((TOTAL + 1))
if echo "$json_output" | jq empty 2>/dev/null; then
  echo "  PASS: stdout is valid JSON with --no-progress"
  PASS=$((PASS + 1))
else
  echo "  FAIL: stdout is not valid JSON with --no-progress"
  echo "    Output: $json_output"
  FAIL=$((FAIL + 1))
fi

json_output2=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" --progress 2>/dev/null)
TOTAL=$((TOTAL + 1))
if echo "$json_output2" | jq empty 2>/dev/null; then
  echo "  PASS: stdout is valid JSON with --progress"
  PASS=$((PASS + 1))
else
  echo "  FAIL: stdout is not valid JSON with --progress"
  echo "    Output: $json_output2"
  FAIL=$((FAIL + 1))
fi

# Cleanup
rm -rf "$INPUT_DIR" "$OUTPUT_DIR"

echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

exit $FAIL
