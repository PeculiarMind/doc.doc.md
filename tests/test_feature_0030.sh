#!/bin/bash
# Test suite for FEATURE_0030: Screen clear and ASCII art banner
# Run from repository root: bash tests/test_feature_0030.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
UI_SH="$REPO_ROOT/doc.doc.md/components/ui.sh"

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

assert_contains() {
  local test_name="$1" expected="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$expected"; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Expected to contain: $expected"
    echo "    Actual: $(echo "$actual" | head -3)"
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
echo "  FEATURE_0030: Screen Clear & ASCII Banner"
echo "============================================"
echo ""

# =========================================
# Group 1: ui_show_banner function exists
# =========================================
echo "--- Group 1: Banner function exists in ui.sh ---"

TOTAL=$((TOTAL + 1))
if grep -q '^ui_show_banner()' "$UI_SH" 2>/dev/null; then
  echo "  PASS: ui_show_banner defined in ui.sh"
  PASS=$((PASS + 1))
else
  echo "  FAIL: ui_show_banner not defined in ui.sh"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: Banner content
# =========================================
echo ""
echo "--- Group 2: Banner content ---"

banner_content=$(grep -A 30 'ui_show_banner' "$UI_SH")
assert_contains "banner has ASCII art" "____/" "$banner_content"
assert_contains "banner has tagline" "document your documents" "$banner_content"
assert_contains "banner has PAPER STACK" "PAPER STACK" "$banner_content"

# =========================================
# Group 3: Banner goes to stderr
# =========================================
echo ""
echo "--- Group 3: Banner output to stderr ---"

assert_contains "screen clear to stderr" ">&2" "$banner_content"

# =========================================
# Group 4: TTY gate
# =========================================
echo ""
echo "--- Group 4: TTY gate ---"

TOTAL=$((TOTAL + 1))
if grep -q '\[ -t 2 \]' "$UI_SH" 2>/dev/null; then
  echo "  PASS: TTY gate [ -t 2 ] present"
  PASS=$((PASS + 1))
else
  echo "  FAIL: TTY gate [ -t 2 ] not found"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 5: Non-interactive suppression
# =========================================
echo ""
echo "--- Group 5: Non-interactive suppression ---"

# When not a TTY, banner function should return without printing
source "$UI_SH" 2>/dev/null

# In a non-TTY context (pipe), ui_show_banner should produce nothing
banner_stderr=$(ui_show_banner 2>&1)
TOTAL=$((TOTAL + 1))
if [ -z "$banner_stderr" ]; then
  echo "  PASS: Banner suppressed in non-TTY mode"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Banner should be suppressed in non-TTY mode"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed (total: $TOTAL)"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
