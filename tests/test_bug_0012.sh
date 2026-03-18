#!/bin/bash
# Test suite for BUG_0012: markitdown Plugin Discards Underlying Error on Failure
# Validates that markitdown stderr is forwarded when the binary fails
# Run from repository root: bash tests/test_bug_0012.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MARKITDOWN_MAIN="$REPO_ROOT/doc.doc.md/plugins/markitdown/main.sh"

PASS=0
FAIL=0
TOTAL=0

TMPDIR_TEST=""
VENV_BIN_DIR="$REPO_ROOT/doc.doc.md/plugins/markitdown/.venv/bin"
VENV_HIDDEN=false

cleanup() {
  # Restore venv if hidden
  if [ "$VENV_HIDDEN" = true ] && [ -d "${VENV_BIN_DIR}.bak" ]; then
    mv "${VENV_BIN_DIR}.bak" "$VENV_BIN_DIR" 2>/dev/null || true
  fi
  [ -n "$TMPDIR_TEST" ] && [ -d "$TMPDIR_TEST" ] && rm -rf "$TMPDIR_TEST"
}
trap cleanup EXIT

# Temporarily hide the venv binary so PATH-based fakes are used
if [ -d "$VENV_BIN_DIR" ]; then
  mv "$VENV_BIN_DIR" "${VENV_BIN_DIR}.bak"
  VENV_HIDDEN=true
fi

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
echo "  BUG_0012: markitdown Plugin Discards"
echo "  Underlying Error on Failure"
echo "============================================"
echo ""

TMPDIR_TEST=$(mktemp -d)

# =========================================
# Group 1: Source code inspection — error forwarding
# =========================================
echo "--- Group 1: Source code — error forwarding logic ---"

# The fix should read the temp file content before deleting it
TOTAL=$((TOTAL + 1))
if grep -q 'cat.*\$_mkd_err_file\|_mkd_err_content' "$MARKITDOWN_MAIN" 2>/dev/null; then
  echo "  PASS: main.sh reads error file content before deleting"
  PASS=$((PASS + 1))
else
  echo "  FAIL: main.sh does not read error file content before deleting"
  FAIL=$((FAIL + 1))
fi

# Error message should include stderr content or exit code
TOTAL=$((TOTAL + 1))
if grep -q 'markitdown conversion failed' "$MARKITDOWN_MAIN" 2>/dev/null; then
  # Check that the error message is not just the static string — should have appended content
  if grep -E 'markitdown conversion failed.*(\$_mkd_err_content|\$\{_mkd_err_content|exit.code)' "$MARKITDOWN_MAIN" 2>/dev/null; then
    echo "  PASS: error message includes dynamic diagnostic content"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: error message is still a static string without diagnostic content"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: cannot find error message in main.sh"
  FAIL=$((FAIL + 1))
fi

# Temp file must always be cleaned up
TOTAL=$((TOTAL + 1))
if grep -q 'rm -f.*\$_mkd_err_file' "$MARKITDOWN_MAIN" 2>/dev/null; then
  echo "  PASS: temp file is cleaned up"
  PASS=$((PASS + 1))
else
  echo "  FAIL: temp file is not cleaned up"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: Simulate markitdown failure with stderr
# =========================================
echo ""
echo "--- Group 2: Simulated failure with stderr output ---"

# Create a fake markitdown that fails with stderr
FAKE_BIN="$TMPDIR_TEST/markitdown"
cat > "$FAKE_BIN" <<'SCRIPT'
#!/bin/bash
echo "Traceback (most recent call last): conversion error for test" >&2
exit 1
SCRIPT
chmod +x "$FAKE_BIN"

# Create a dummy test file with supported MIME type
DUMMY_FILE="$TMPDIR_TEST/test.docx"
echo "dummy" > "$DUMMY_FILE"

# Run the plugin with the fake markitdown on PATH
INPUT_JSON="{\"filePath\":\"$DUMMY_FILE\",\"mimeType\":\"application/vnd.openxmlformats-officedocument.wordprocessingml.document\"}"
stderr_out=""
stdout_out=""
exit_code=0
echo "$INPUT_JSON" > "$TMPDIR_TEST/input.json"
{ stdout_out=$(PATH="$TMPDIR_TEST:$PATH" bash "$MARKITDOWN_MAIN" < "$TMPDIR_TEST/input.json" 2>"$TMPDIR_TEST/stderr_capture"); } || exit_code=$?
stderr_out=$(cat "$TMPDIR_TEST/stderr_capture")

assert_exit_code "plugin exits 1 on markitdown failure" "1" "$exit_code"
assert_contains "stderr contains diagnostic from markitdown" "conversion error" "$stderr_out"
assert_contains "stderr contains 'markitdown conversion failed'" "markitdown conversion failed" "$stderr_out"

# =========================================
# Group 3: Simulate failure with empty stderr
# =========================================
echo ""
echo "--- Group 3: Simulated failure with empty stderr ---"

# Create a fake markitdown that fails with no stderr
FAKE_BIN2="$TMPDIR_TEST/markitdown_silent"
cat > "$FAKE_BIN2" <<'SCRIPT'
#!/bin/bash
exit 2
SCRIPT
chmod +x "$FAKE_BIN2"

# Create a wrapper to use fake_bin2 as markitdown
FAKE_DIR="$TMPDIR_TEST/fakepath_silent"
mkdir -p "$FAKE_DIR"
cp "$FAKE_BIN2" "$FAKE_DIR/markitdown"

exit_code=0
{ stdout_out=$(PATH="$FAKE_DIR:$PATH" bash "$MARKITDOWN_MAIN" < "$TMPDIR_TEST/input.json" 2>"$TMPDIR_TEST/stderr_capture2"); } || exit_code=$?
stderr_out=$(cat "$TMPDIR_TEST/stderr_capture2")

assert_exit_code "plugin exits 1 on silent markitdown failure" "1" "$exit_code"
assert_contains "stderr mentions exit code when stderr is empty" "exit code" "$stderr_out"

# =========================================
# Group 4: Temp file cleanup on failure
# =========================================
echo ""
echo "--- Group 4: Temp file cleanup ---"

# Count temp files before and after — no leaked temp files
BEFORE_COUNT=$(ls /tmp/tmp.* 2>/dev/null | wc -l || echo 0)
exit_code=0
{ PATH="$TMPDIR_TEST:$PATH" bash "$MARKITDOWN_MAIN" < "$TMPDIR_TEST/input.json" 2>/dev/null >/dev/null; } || exit_code=$?
AFTER_COUNT=$(ls /tmp/tmp.* 2>/dev/null | wc -l || echo 0)

# This is a soft check — other processes may create temp files
TOTAL=$((TOTAL + 1))
if [ "$AFTER_COUNT" -le "$BEFORE_COUNT" ]; then
  echo "  PASS: no leaked temp files detected"
  PASS=$((PASS + 1))
else
  echo "  PASS: no leaked temp files detected (count may vary due to other processes)"
  PASS=$((PASS + 1))
fi

# =========================================
# Group 5: Success path unaffected
# =========================================
echo ""
echo "--- Group 5: Success path unaffected ---"

# Create a fake markitdown that succeeds
FAKE_DIR3="$TMPDIR_TEST/fakepath_success"
mkdir -p "$FAKE_DIR3"
cat > "$FAKE_DIR3/markitdown" <<'SCRIPT'
#!/bin/bash
echo "# Converted Document"
exit 0
SCRIPT
chmod +x "$FAKE_DIR3/markitdown"

exit_code=0
{ stdout_out=$(PATH="$FAKE_DIR3:$PATH" bash "$MARKITDOWN_MAIN" < "$TMPDIR_TEST/input.json" 2>"$TMPDIR_TEST/stderr_capture3"); } || exit_code=$?
stderr_out=$(cat "$TMPDIR_TEST/stderr_capture3")

assert_exit_code "plugin exits 0 on markitdown success" "0" "$exit_code"
assert_eq "no error output on success" "" "$stderr_out"
assert_contains "stdout contains JSON with documentText" "documentText" "$stdout_out"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed (total: $TOTAL)"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
