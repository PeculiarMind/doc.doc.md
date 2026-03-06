#!/bin/bash
# Test suite for FEATURE_0020: Extract UI Module
# Run from repository root: bash tests/test_feature_0020.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
UI_MODULE="$REPO_ROOT/doc.doc.md/components/ui.sh"

PASS=0
FAIL=0
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
echo "  FEATURE_0020: Extract UI Module"
echo "============================================"
echo ""

# =========================================
# Group 1: ui.sh exists and is sourced
# =========================================
echo "--- Group 1: ui.sh exists and is sourced ---"

TOTAL=$((TOTAL + 1))
if [ -f "$UI_MODULE" ]; then
  echo "  PASS: components/ui.sh exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: components/ui.sh does not exist"
  FAIL=$((FAIL + 1))
fi

# Check doc.doc.sh sources ui.sh (via variable or direct path)
source_line="$(grep -cE 'source.*(ui\.sh|UI_COMPONENT)' "$CLI" 2>/dev/null)" || source_line="0"
TOTAL=$((TOTAL + 1))
if [ "$source_line" -gt 0 ]; then
  echo "  PASS: doc.doc.sh sources ui.sh"
  PASS=$((PASS + 1))
else
  echo "  FAIL: doc.doc.sh does not source ui.sh"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: --help output unchanged
# =========================================
echo ""
echo "--- Group 2: --help output byte-for-byte identical ---"

help_output=$(bash "$CLI" --help 2>&1)
exit_code=$?
assert_exit_code "--help exits 0" "0" "$exit_code"
assert_contains "help shows 'process'" "process" "$help_output"
assert_contains "help shows 'list'" "list" "$help_output"
assert_contains "help shows 'activate'" "activate" "$help_output"
assert_contains "help shows 'deactivate'" "deactivate" "$help_output"
assert_contains "help shows 'install'" "install" "$help_output"
assert_contains "help shows 'installed'" "installed" "$help_output"
assert_contains "help shows 'tree'" "tree" "$help_output"
assert_contains "help shows '--help'" "--help" "$help_output"
assert_contains "help shows examples" "Examples:" "$help_output"
assert_contains "help shows 'Usage:'" "Usage:" "$help_output"

# =========================================
# Group 3: No inline help text in doc.doc.sh
# =========================================
echo ""
echo "--- Group 3: No inline help text in doc.doc.sh ---"

# doc.doc.sh should NOT contain the usage() function definition
usage_def="$(grep -c '^usage()' "$CLI" 2>/dev/null)" || usage_def="0"
TOTAL=$((TOTAL + 1))
if [ "$usage_def" -eq 0 ]; then
  echo "  PASS: doc.doc.sh has no usage() function definition"
  PASS=$((PASS + 1))
else
  echo "  FAIL: doc.doc.sh still contains usage() function definition"
  FAIL=$((FAIL + 1))
fi

# doc.doc.sh should NOT contain inline cat <<EOF help blocks
# (the usage function with heredoc should be in ui.sh)
inline_help="$(grep -c 'cat <<EOF' "$CLI" 2>/dev/null)" || inline_help="0"
TOTAL=$((TOTAL + 1))
if [ "$inline_help" -eq 0 ]; then
  echo "  PASS: doc.doc.sh has no inline help heredocs"
  PASS=$((PASS + 1))
else
  echo "  FAIL: doc.doc.sh still contains $inline_help inline help heredoc(s)"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 4: ui.sh has documented public interface
# =========================================
echo ""
echo "--- Group 4: ui.sh public interface documented ---"

# Check for header comment in ui.sh
TOTAL=$((TOTAL + 1))
if [ -f "$UI_MODULE" ]; then
  header_comment="$(head -5 "$UI_MODULE" | grep -c '#')" || header_comment="0"
  if [ "$header_comment" -gt 0 ]; then
    echo "  PASS: ui.sh has header comments"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ui.sh missing header comments"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: ui.sh does not exist (cannot check header)"
  FAIL=$((FAIL + 1))
fi

# Check ui.sh contains the usage function
TOTAL=$((TOTAL + 1))
if [ -f "$UI_MODULE" ]; then
  has_usage="$(grep -c '^usage()' "$UI_MODULE" 2>/dev/null)" || has_usage="0"
  if [ "$has_usage" -gt 0 ]; then
    echo "  PASS: ui.sh contains usage() function"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ui.sh does not contain usage() function"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: ui.sh does not exist (cannot check usage)"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 5: Subcommand help still works
# =========================================
echo ""
echo "--- Group 5: Subcommand help output preserved ---"

activate_help=$(bash "$CLI" activate --help 2>&1)
exit_code=$?
assert_exit_code "activate --help exits 0" "0" "$exit_code"
assert_contains "activate help mentions --plugin" "--plugin" "$activate_help"

deactivate_help=$(bash "$CLI" deactivate --help 2>&1)
exit_code=$?
assert_exit_code "deactivate --help exits 0" "0" "$exit_code"
assert_contains "deactivate help mentions --plugin" "--plugin" "$deactivate_help"

install_help=$(bash "$CLI" install --help 2>&1)
exit_code=$?
assert_exit_code "install --help exits 0" "0" "$exit_code"
assert_contains "install help mentions plugins --all" "plugins --all" "$install_help"

installed_help=$(bash "$CLI" installed --help 2>&1)
exit_code=$?
assert_exit_code "installed --help exits 0" "0" "$exit_code"
assert_contains "installed help mentions --plugin" "--plugin" "$installed_help"

tree_help=$(bash "$CLI" tree --help 2>&1)
exit_code=$?
assert_exit_code "tree --help exits 0" "0" "$exit_code"
assert_contains "tree help mentions dependency" "dependency" "$tree_help"

# =========================================
# Group 6: Error messages work
# =========================================
echo ""
echo "--- Group 6: Error messages preserved ---"

err_output=$(bash "$CLI" nonsense 2>&1)
exit_code=$?
assert_exit_code "unknown command exits 1" "1" "$exit_code"
assert_contains "unknown command shows error" "Error:" "$err_output"

echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

exit $FAIL
