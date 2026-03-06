#!/bin/bash
# Test suite for BUG_0007: List Command Path Traversal via --plugin Argument
# Run from repository root: bash tests/test_bug_0007.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

PASS=0
FAIL=0
TOTAL=0

BAIT_DESCRIPTOR="/tmp/descriptor.json"

cleanup() {
  rm -f "$BAIT_DESCRIPTOR"
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
echo "  BUG_0007: List Command Path Traversal via --plugin Argument"
echo "============================================"
echo ""

# =========================================
# Setup: create bait descriptor.json at /tmp
# This proves traversal would succeed without the fix.
# =========================================
cat > "$BAIT_DESCRIPTOR" <<'BAIT'
{
  "name": "bait",
  "version": "0.0.1",
  "description": "Bait descriptor to prove path traversal",
  "active": true,
  "commands": {
    "leaked": {
      "description": "This command should never be visible",
      "command": "leaked.sh",
      "input": {},
      "output": {}
    }
  }
}
BAIT

# Compute the relative traversal from PLUGIN_DIR to /tmp portably.
# Count directory depth of PLUGIN_DIR and prepend that many '../' segments.
_canonical_plugin_dir="$(cd "$PLUGIN_DIR" && pwd -P)"
_depth=$(echo "$_canonical_plugin_dir" | tr -cd '/' | wc -c)
TRAVERSAL=""
for _i in $(seq 1 "$_depth"); do
  TRAVERSAL="../$TRAVERSAL"
done
TRAVERSAL="${TRAVERSAL}tmp"

# =========================================
# Group 1: --parameters rejects path traversal
# =========================================
echo "--- Group 1: --parameters rejects path traversal ---"

output=$(bash "$CLI" list --plugin "$TRAVERSAL" --parameters 2>&1)
exit_code=$?

assert_exit_code "traversal --parameters exits non-zero" "1" "$exit_code"
assert_contains "traversal --parameters reports error" "Error" "$output"
assert_not_contains "traversal --parameters does not leak bait command" "leaked" "$output"
assert_not_contains "traversal --parameters does not show bait description" "Bait descriptor" "$output"

# =========================================
# Group 2: --commands rejects path traversal
# =========================================
echo ""
echo "--- Group 2: --commands rejects path traversal ---"

output=$(bash "$CLI" list --plugin "$TRAVERSAL" --commands 2>&1)
exit_code=$?

assert_exit_code "traversal --commands exits non-zero" "1" "$exit_code"
assert_contains "traversal --commands reports error" "Error" "$output"
assert_not_contains "traversal --commands does not leak bait command" "leaked" "$output"
assert_not_contains "traversal --commands does not show bait description" "Bait descriptor" "$output"

# =========================================
# Group 3: Various traversal patterns rejected
# =========================================
echo ""
echo "--- Group 3: Various traversal patterns rejected (--parameters) ---"

traversal_patterns=(
  "$TRAVERSAL"
  "../../.."
  "../file"
  "file/../../stat"
  "file/$TRAVERSAL"
)

for pattern in "${traversal_patterns[@]}"; do
  output=$(bash "$CLI" list --plugin "$pattern" --parameters 2>&1)
  exit_code=$?

  assert_exit_code "pattern '$pattern' exits non-zero" "1" "$exit_code"
  assert_contains "pattern '$pattern' reports error" "Error" "$output"
  assert_not_contains "pattern '$pattern' does not leak content" "leaked" "$output"
done

# =========================================
# Group 4: Legitimate plugin names still work (regression)
# =========================================
echo ""
echo "--- Group 4: Legitimate plugins still work (regression) ---"

# --commands for 'file' plugin
output=$(bash "$CLI" list --plugin file --commands 2>&1)
exit_code=$?

assert_exit_code "file --commands succeeds" "0" "$exit_code"
assert_contains "file --commands lists 'process'" "process" "$output"

# --parameters for 'file' plugin
output=$(bash "$CLI" list --plugin file --parameters 2>&1)
exit_code=$?

assert_exit_code "file --parameters succeeds" "0" "$exit_code"
assert_contains "file --parameters lists 'filePath'" "filePath" "$output"

# --commands for 'stat' plugin
output=$(bash "$CLI" list --plugin stat --commands 2>&1)
exit_code=$?

assert_exit_code "stat --commands succeeds" "0" "$exit_code"
assert_contains "stat --commands lists 'process'" "process" "$output"

# =========================================
# Group 5: Plugin name containing '..' is rejected
# =========================================
echo ""
echo "--- Group 5: Plugin name with '..' is rejected ---"

output=$(bash "$CLI" list --plugin ".." --commands 2>&1)
exit_code=$?

assert_exit_code "'..' --commands exits non-zero" "1" "$exit_code"
assert_contains "'..' --commands reports error" "Error" "$output"

output=$(bash "$CLI" list --plugin ".." --parameters 2>&1)
exit_code=$?

assert_exit_code "'..' --parameters exits non-zero" "1" "$exit_code"
assert_contains "'..' --parameters reports error" "Error" "$output"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
