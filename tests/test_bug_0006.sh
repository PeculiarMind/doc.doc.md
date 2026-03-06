#!/bin/bash
# Test suite for BUG_0006: markitdown plugin missing stdin size limit
# Run from repository root: bash tests/test_bug_0006.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"
PLUGIN_SCRIPT="$PLUGIN_DIR/markitdown/main.sh"

PASS=0
FAIL=0
TOTAL=0

cleanup() {
  [ -n "${TMP_FILE:-}" ] && rm -f "$TMP_FILE"
  [ -n "${OVERSIZED_PAYLOAD:-}" ] && rm -f "$OVERSIZED_PAYLOAD"
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
  local test_name="$1" unexpected="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$unexpected"; then
    echo "  FAIL: $test_name (should NOT contain: $unexpected)"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

echo "============================================"
echo "  BUG_0006: markitdown plugin missing stdin size limit"
echo "============================================"
echo ""

# =========================================
# Group 1: Script source uses head -c 1048576
# =========================================
echo "--- Group 1: stdin reading uses head -c 1048576 ---"

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_SCRIPT" ]; then
  echo "  PASS: markitdown/main.sh exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: markitdown/main.sh not found at $PLUGIN_SCRIPT"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if grep -q 'head -c 1048576' "$PLUGIN_SCRIPT"; then
  echo "  PASS: markitdown/main.sh uses head -c 1048576 for stdin"
  PASS=$((PASS + 1))
else
  echo "  FAIL: markitdown/main.sh should use head -c 1048576 for stdin"
  FAIL=$((FAIL + 1))
fi

# Ensure there is no bare 'cat' used for reading all of stdin
TOTAL=$((TOTAL + 1))
if grep -F '$(cat)' "$PLUGIN_SCRIPT" | grep -qv '^#'; then
  echo "  FAIL: markitdown/main.sh still uses bare cat for stdin (no size limit)"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: markitdown/main.sh does not use bare cat for stdin"
  PASS=$((PASS + 1))
fi

# =========================================
# Group 2: Valid small payload is accepted (regression)
# =========================================
echo ""
echo "--- Group 2: valid small payload regression test ---"

TMP_FILE="$(mktemp /tmp/bug0006_test_XXXXXX.txt)"
echo "test content" > "$TMP_FILE"

small_payload='{"filePath":"'"$TMP_FILE"'","mimeType":"application/vnd.openxmlformats-officedocument.wordprocessingml.document"}'
output=$(echo "$small_payload" | bash "$PLUGIN_SCRIPT" 2>&1)
exit_code=$?

# The plugin will fail because markitdown binary is likely not installed,
# but it should NOT fail due to stdin reading issues.
# It should get past JSON parsing and fail at markitdown invocation or file type check.
assert_not_contains "small payload does not produce JSON parse error" "parse error" "$output"

# =========================================
# Group 3: Oversized payload is truncated
# =========================================
echo ""
echo "--- Group 3: oversized payload is truncated ---"

OVERSIZED_PAYLOAD="$(mktemp /tmp/bug0006_oversized_XXXXXX)"
# Build a payload larger than 1MB: valid JSON prefix + padding beyond 1048576 bytes
printf '{"filePath":"/tmp/test","mimeType":"application/msword","pad":"' > "$OVERSIZED_PAYLOAD"
dd if=/dev/zero bs=1024 count=1100 2>/dev/null | tr '\0' 'A' >> "$OVERSIZED_PAYLOAD"
printf '"}' >> "$OVERSIZED_PAYLOAD"

output=$(bash "$PLUGIN_SCRIPT" < "$OVERSIZED_PAYLOAD" 2>&1)
exit_code=$?

# With head -c 1048576, the payload is truncated so jq parsing should fail
# (the JSON is cut mid-string). The plugin should exit non-zero.
TOTAL=$((TOTAL + 1))
if [ "$exit_code" -ne 0 ]; then
  echo "  PASS: oversized payload exits non-zero (exit $exit_code)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: oversized payload should exit non-zero"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
