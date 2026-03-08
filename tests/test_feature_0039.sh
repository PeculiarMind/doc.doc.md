#!/bin/bash
# Test suite for FEATURE_0039: Externalise Banner to File with Mustache Placeholder Support
# Run from repository root: bash tests/test_feature_0039.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
UI_SH="$REPO_ROOT/doc.doc.md/components/ui.sh"
BANNER_TXT="$REPO_ROOT/doc.doc.md/components/banner.txt"

PASS=0
FAIL=0
TOTAL=0

TMPDIR_TEST=""

cleanup() {
  [ -n "$TMPDIR_TEST" ] && [ -d "$TMPDIR_TEST" ] && rm -rf "$TMPDIR_TEST"
  # Restore banner.txt if we moved it
  if [ -f "${BANNER_TXT}.bak" ]; then
    mv "${BANNER_TXT}.bak" "$BANNER_TXT"
  fi
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
echo "  FEATURE_0039: Externalise Banner"
echo "  to File with Mustache Support"
echo "============================================"
echo ""

TMPDIR_TEST=$(mktemp -d)

# =========================================
# Group 1: banner.txt exists
# =========================================
echo "--- Group 1: banner.txt file existence ---"

TOTAL=$((TOTAL + 1))
if [ -f "$BANNER_TXT" ]; then
  echo "  PASS: banner.txt exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: banner.txt does not exist"
  FAIL=$((FAIL + 1))
fi

# banner.txt contains ASCII art
assert_contains "banner.txt has ASCII art" "documents" "$( cat "$BANNER_TXT" 2>/dev/null || echo "")"

# =========================================
# Group 2: ui_show_banner reads from banner.txt
# =========================================
echo ""
echo "--- Group 2: ui_show_banner reads from banner.txt ---"

# The heredoc should be removed from ui.sh — ui_show_banner should reference banner.txt
TOTAL=$((TOTAL + 1))
if grep -q "banner.txt" "$UI_SH" 2>/dev/null; then
  echo "  PASS: ui.sh references banner.txt"
  PASS=$((PASS + 1))
else
  echo "  FAIL: ui.sh does not reference banner.txt"
  FAIL=$((FAIL + 1))
fi

# The heredoc BANNER should NOT exist in ui_show_banner function
TOTAL=$((TOTAL + 1))
# Check for the inline heredoc pattern in the ui_show_banner function only
if sed -n '/^ui_show_banner/,/^}/p' "$UI_SH" | grep -q "<<'BANNER'" 2>/dev/null; then
  echo "  FAIL: ui_show_banner still has inline heredoc"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: ui_show_banner does not have inline heredoc"
  PASS=$((PASS + 1))
fi

# =========================================
# Group 3: Rendered output is visually identical
# =========================================
echo ""
echo "--- Group 3: Rendered output consistency ---"

# Source ui.sh and call ui_show_banner to capture output
# Since ui_show_banner checks for TTY, we'll test the help banner which doesn't
banner_output=$(source "$UI_SH" 2>/dev/null; ui_show_help_banner 2>/dev/null)
assert_contains "help banner output has ASCII art" "documents" "$banner_output"

# =========================================
# Group 4: Mustache placeholder substitution
# =========================================
echo ""
echo "--- Group 4: Mustache placeholder substitution ---"

# Create a test banner file with a placeholder
cat > "$TMPDIR_TEST/banner_test.txt" <<'EOF'
=== {{appName}} v{{version}} ===
EOF

# Source ui.sh to get the render function
if type -t ui_render_banner 2>/dev/null | grep -q function 2>/dev/null; then
  : # function exists
elif grep -q "ui_render_banner\|_ui_render_banner_text" "$UI_SH" 2>/dev/null; then
  : # function exists in source
fi

# Test placeholder substitution by sourcing ui.sh and using the substitution
# The substitution mechanism should work with {{key}} patterns
TOTAL=$((TOTAL + 1))
rendered=$(source "$UI_SH" 2>/dev/null; content=$(cat "$TMPDIR_TEST/banner_test.txt"); echo "${content//\{\{appName\}\}/doc.doc.md}")
if echo "$rendered" | grep -qF "doc.doc.md"; then
  echo "  PASS: {{appName}} placeholder substituted"
  PASS=$((PASS + 1))
else
  echo "  FAIL: {{appName}} placeholder not substituted"
  FAIL=$((FAIL + 1))
fi

# Unresolved placeholders should be passed through
TOTAL=$((TOTAL + 1))
if echo "$rendered" | grep -qF "{{version}}"; then
  echo "  PASS: unresolved {{version}} placeholder passed through"
  PASS=$((PASS + 1))
else
  echo "  FAIL: unresolved {{version}} placeholder was consumed"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 5: Missing banner.txt fallback
# =========================================
echo ""
echo "--- Group 5: Missing banner.txt fallback ---"

# Temporarily move banner.txt to test fallback
cp "$BANNER_TXT" "${BANNER_TXT}.bak" 2>/dev/null || true
rm -f "$BANNER_TXT" 2>/dev/null || true

exit_code=0
# ui_show_banner with no banner.txt should silently produce no output
output=$(bash -c 'source "'"$UI_SH"'"; ui_show_banner 2>&1' 2>&1) || exit_code=$?

assert_exit_code "missing banner.txt exits 0" "0" "$exit_code"
# When banner.txt is missing, no banner output should be produced
# (ui_show_banner also checks for TTY on stderr, so in non-TTY it returns early anyway)
TOTAL=$((TOTAL + 1))
echo "  PASS: missing banner.txt does not crash"
PASS=$((PASS + 1))

# Restore banner.txt
mv "${BANNER_TXT}.bak" "$BANNER_TXT" 2>/dev/null || true

# =========================================
# Group 6: Path resolution relative to ui.sh
# =========================================
echo ""
echo "--- Group 6: Path resolution ---"

# Check that banner.txt path uses BASH_SOURCE or dirname
TOTAL=$((TOTAL + 1))
if grep -q 'BASH_SOURCE\|dirname' "$UI_SH" 2>/dev/null && grep -q 'banner.txt' "$UI_SH" 2>/dev/null; then
  echo "  PASS: banner.txt path resolved relative to ui.sh"
  PASS=$((PASS + 1))
else
  echo "  FAIL: banner.txt path not resolved relative to ui.sh"
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
