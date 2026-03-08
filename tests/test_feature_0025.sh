#!/bin/bash
# Test suite for FEATURE_0025: Interactive Setup Routine
# Run from repository root: bash tests/test_feature_0025.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"

PASS=0
FAIL=0
TOTAL=0

cleanup() {
  :
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
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

echo "============================================"
echo "  FEATURE_0025: Interactive Setup Routine"
echo "============================================"
echo ""

# =========================================
# Group 1: Setup command exists
# =========================================
echo "--- Group 1: Setup command recognized ---"

help_output=$(bash "$CLI" --help 2>&1)
assert_contains "setup command in help" "setup" "$help_output"

# =========================================
# Group 2: Non-interactive mode (--non-interactive / -n)
# =========================================
echo ""
echo "--- Group 2: Non-interactive mode ---"

output=$(bash "$CLI" setup --non-interactive 2>&1)
exit_code=$?

assert_exit_code "setup --non-interactive exits 0" "0" "$exit_code"
assert_contains "dependency check section" "Dependency Check" "$output"
assert_contains "plugin status section" "Plugin Status" "$output"
assert_contains "summary section" "Summary" "$output"

# Check mandatory dependencies are listed
assert_contains "checks jq" "jq" "$output"
assert_contains "checks python3" "python3" "$output"

# =========================================
# Group 3: Plugins are discovered
# =========================================
echo ""
echo "--- Group 3: Plugin discovery ---"

assert_contains "discovers file plugin" "file" "$output"
assert_contains "discovers stat plugin" "stat" "$output"

# =========================================
# Group 4: Output structure
# =========================================
echo ""
echo "--- Group 4: Output structure ---"

# Non-interactive skips prompts
assert_contains "non-interactive skips prompts" "skipping prompts" "$output"

# =========================================
# Group 5: Help flag
# =========================================
echo ""
echo "--- Group 5: Setup help ---"

setup_help=$(bash "$CLI" setup --help 2>&1)
exit_code=$?
assert_exit_code "setup --help exits 0" "0" "$exit_code"
assert_contains "setup help mentions --yes" "--yes" "$setup_help"
assert_contains "setup help mentions --non-interactive" "--non-interactive" "$setup_help"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed (total: $TOTAL)"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
