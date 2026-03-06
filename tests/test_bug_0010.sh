#!/bin/bash
# Test suite for BUG_0010: JSON data stream pollutes stdout during interactive process run
# Run from repository root: bash tests/test_bug_0010.sh
#
# Two complementary scenarios are verified:
#   A) Non-TTY (pipe) mode  — stdout MUST contain a valid JSON array (Unix pipeline compat).
#   B) TTY (interactive) mode — stdout MUST NOT contain JSON when -o is given and stdout is a TTY.
#
# Scenario B uses the `script` utility to allocate a pseudo-TTY, simulating an interactive shell.
# The test is marked SKIP when `script` is unavailable.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"

PASS=0
FAIL=0
SKIP=0
TOTAL=0

INPUT_DIR=""
OUTPUT_DIR=""

cleanup() {
  [ -n "$INPUT_DIR" ] && [ -d "$INPUT_DIR" ] && rm -rf "$INPUT_DIR"
  [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ] && rm -rf "$OUTPUT_DIR"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Assertion helpers
# ---------------------------------------------------------------------------

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
  local test_name="$1" unexpected="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$unexpected"; then
    echo "  FAIL: $test_name"
    echo "    Expected NOT to contain: $unexpected"
    echo "    Actual: $actual"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

assert_valid_json() {
  local test_name="$1" actual="$2"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | jq empty 2>/dev/null; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name (not valid JSON)"
    echo "    Actual: $actual"
    FAIL=$((FAIL + 1))
  fi
}

skip_test() {
  local test_name="$1" reason="$2"
  TOTAL=$((TOTAL + 1))
  SKIP=$((SKIP + 1))
  echo "  SKIP: $test_name ($reason)"
}

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

echo "============================================"
echo "  BUG_0010: JSON stdout pollution in TTY"
echo "============================================"
echo ""

INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
echo "hello world" > "$INPUT_DIR/test.txt"

# =========================================
# Group 1: Non-TTY (pipe) mode — JSON MUST reach stdout (backward compat)
# =========================================
echo "--- Group 1: Non-TTY pipe mode (backward compat) ---"

PIPE_OUT="$OUTPUT_DIR/pipe_$$"
json_stdout=$(bash "$CLI" process -d "$INPUT_DIR" -o "$PIPE_OUT" 2>/dev/null)
exit_code=$?

assert_exit_code "non-TTY process exits 0" "0" "$exit_code"
assert_valid_json "non-TTY stdout is valid JSON" "$json_stdout"
assert_contains "non-TTY JSON contains filePath" "filePath" "$json_stdout"

# =========================================
# Group 2: Non-TTY mode — stderr carries human-readable lines only
# =========================================
echo ""
echo "--- Group 2: Non-TTY — stderr is human-readable ---"

STDERR_OUT="$OUTPUT_DIR/stderr_$$"
stderr_content=$(bash "$CLI" process -d "$INPUT_DIR" -o "$STDERR_OUT" 2>&1 >/dev/null)

assert_contains "non-TTY stderr has Processed: line" "Processed:" "$stderr_content"
assert_not_contains "non-TTY stderr has no JSON array opener" '"filePath"' "$stderr_content"

# =========================================
# Group 3: Non-TTY mode — stdout carries JSON only (no Processed: lines)
# =========================================
echo ""
echo "--- Group 3: Non-TTY — stdout is JSON only ---"

STDONLY_OUT="$OUTPUT_DIR/stdonly_$$"
stdout_only=$(bash "$CLI" process -d "$INPUT_DIR" -o "$STDONLY_OUT" 2>/dev/null)

assert_not_contains "non-TTY stdout has no Processed: line" "Processed:" "$stdout_only"
assert_not_contains "non-TTY stdout has no Error: line" "Error:" "$stdout_only"

# =========================================
# Group 4: TTY mode — stdout MUST NOT contain JSON when -o is given
#
# Uses `script -q -c` to allocate a pseudo-TTY, making [ -t 1 ] true inside
# the subprocess. The typescript is written to a temp file; we then check
# that no JSON brackets appear in the captured output.
#
# Expected result AFTER fix: no '[' JSON bracket on PTY stdout.
# Current result BEFORE fix: '[' and JSON objects appear → this test FAILS.
# =========================================
echo ""
echo "--- Group 4: TTY mode — no JSON on stdout when -o given (expects FAIL before fix) ---"

if ! command -v script &>/dev/null; then
  skip_test "TTY stdout suppresses JSON" "script utility not available"
else
  TTY_INDIR="$INPUT_DIR"
  TTY_OUT="$OUTPUT_DIR/tty_out_$$"
  TTY_TS=$(mktemp)   # typescript file for `script`

  # Run through a PTY. `script -q -c CMD FILE` writes PTY output to FILE and
  # exits when CMD exits. Redirect stderr of the subprocess to /dev/null so the
  # typescript contains only what would appear on the PTY terminal (stdout).
  script -q -c "bash '$CLI' process -d '$TTY_INDIR' -o '$TTY_OUT' 2>/dev/null" "$TTY_TS" >/dev/null 2>&1
  # Strip the `script` utility's own header/footer lines ("Script started/done on ...")
  # which contain '[' characters unrelated to JSON output, then remove blank lines.
  tty_captured=$(cat "$TTY_TS" 2>/dev/null | tr -d '\r' | grep -v '^Script ' | grep -v '^$')
  rm -f "$TTY_TS"

  # After the fix, TTY stdout should show only the human-readable summary;
  # no raw JSON data should appear.
  assert_not_contains "TTY stdout has no JSON array opener '['" "[" "$tty_captured"
  assert_not_contains "TTY stdout has no JSON filePath key" '"filePath"' "$tty_captured"
fi

# =========================================
# Group 5: TTY mode — human-readable summary still visible
# =========================================
echo ""
echo "--- Group 5: TTY mode — summary line still visible after fix ---"

if ! command -v script &>/dev/null; then
  skip_test "TTY summary visible" "script utility not available"
else
  TTY_SUMOUT="$OUTPUT_DIR/tty_sum_$$"
  TTY_SUMTS=$(mktemp)

  # Capture both stdout and stderr via PTY (stderr not suppressed this time)
  script -q -c "bash '$CLI' process -d '$INPUT_DIR' -o '$TTY_SUMOUT'" "$TTY_SUMTS" >/dev/null 2>&1
  tty_sum_captured=$(cat "$TTY_SUMTS" 2>/dev/null | tr -d '\r')
  rm -f "$TTY_SUMTS"

  assert_contains "TTY shows Processed: summary line" "Processed:" "$tty_sum_captured"
fi

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed, $SKIP skipped"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
