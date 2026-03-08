#!/bin/bash
# Test suite for BUG_0013: markitdown plugin install.sh missing optional extras
#
# The install.sh ran 'pip install markitdown' instead of
# 'pip install markitdown[pptx,docx,xlsx,xls]'.  Since markitdown 0.1.0,
# optional extras are required for file-format support.  Without them the
# plugin installs successfully but fails to convert DOCX, XLSX, PPTX, or XLS.
#
# Run from repository root: bash tests/test_bug_0013.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_SH="$REPO_ROOT/doc.doc.md/plugins/markitdown/install.sh"
MAIN_SH="$REPO_ROOT/doc.doc.md/plugins/markitdown/main.sh"
DOCS_DIR="$SCRIPT_DIR/docs"

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

# Run a conversion test for a single format.
# Arguments: <label> <mime_type> <file_path>
# Skips gracefully when the test document does not exist or markitdown is absent.
run_conversion_test() {
  local label="$1" mime="$2" doc_file="$3"

  if [ ! -f "$doc_file" ]; then
    echo "  SKIP: no $label test document available (expected: $doc_file)"
    return
  fi

  if ! command -v markitdown >/dev/null 2>&1; then
    echo "  SKIP: markitdown not installed — cannot test $label conversion"
    return
  fi

  local input_json exit_code output doc_text
  input_json="{\"filePath\":\"$doc_file\",\"mimeType\":\"$mime\"}"
  exit_code=0
  output=$(echo "$input_json" | bash "$MAIN_SH" 2>&1) || exit_code=$?

  assert_exit_code "$label conversion exits 0" "0" "$exit_code"

  doc_text=$(echo "$output" | jq -r '.documentText // empty' 2>/dev/null || true)
  TOTAL=$((TOTAL + 1))
  if [ -n "$doc_text" ]; then
    echo "  PASS: $label documentText is non-empty"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label documentText is empty or missing"
    echo "    Output: $output"
    FAIL=$((FAIL + 1))
  fi
}

echo "============================================"
echo "  BUG_0013: markitdown install.sh missing"
echo "  optional extras [pptx,docx,xlsx,xls]"
echo "============================================"
echo ""

# =========================================
# Group 1: Static source inspection
# Verify install.sh references the extras package spec.
# This acts as a regression guard — if the fix is accidentally
# reverted, this group fails immediately.
# =========================================
echo "--- Group 1: install.sh contains correct extras package spec ---"

TOTAL=$((TOTAL + 1))
if grep -qF 'markitdown[pptx,docx,xlsx,xls]' "$INSTALL_SH" 2>/dev/null; then
  echo "  PASS: install.sh contains markitdown[pptx,docx,xlsx,xls]"
  PASS=$((PASS + 1))
else
  echo "  FAIL: install.sh does not contain markitdown[pptx,docx,xlsx,xls]"
  echo "    Relevant lines: $(grep 'markitdown' "$INSTALL_SH" 2>/dev/null || echo '(no markitdown line found)')"
  FAIL=$((FAIL + 1))
fi

# All four individual extras must be present (handles future reordering)
for extra in pptx docx xlsx xls; do
  TOTAL=$((TOTAL + 1))
  if grep -q "$extra" "$INSTALL_SH" 2>/dev/null; then
    echo "  PASS: install.sh references extra: $extra"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: install.sh missing extra: $extra"
    FAIL=$((FAIL + 1))
  fi
done

# Bare 'pip install markitdown' without extras must NOT appear
TOTAL=$((TOTAL + 1))
if grep -E "pip install markitdown([^[]|$)" "$INSTALL_SH" 2>/dev/null | grep -qvF '['; then
  echo "  FAIL: install.sh still contains bare 'pip install markitdown' without extras"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: install.sh does not contain bare markitdown install without extras"
  PASS=$((PASS + 1))
fi

# =========================================
# Group 2: DOCX conversion
# Uses tests/docs/README-MSWORD.docx.
# =========================================
echo ""
echo "--- Group 2: DOCX conversion ---"
run_conversion_test \
  "DOCX" \
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document" \
  "$DOCS_DIR/README-MSWORD.docx"

# =========================================
# Group 3: XLSX conversion
# Skipped if no XLSX test document is present in tests/docs/.
# =========================================
echo ""
echo "--- Group 3: XLSX conversion ---"
run_conversion_test \
  "XLSX" \
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" \
  "$DOCS_DIR/test.xlsx"

# =========================================
# Group 4: PPTX conversion
# Skipped if no PPTX test document is present in tests/docs/.
# =========================================
echo ""
echo "--- Group 4: PPTX conversion ---"
run_conversion_test \
  "PPTX" \
  "application/vnd.openxmlformats-officedocument.presentationml.presentation" \
  "$DOCS_DIR/test.pptx"

# =========================================
# Group 5: XLS conversion
# Skipped if no XLS test document is present in tests/docs/.
# =========================================
echo ""
echo "--- Group 5: XLS conversion ---"
run_conversion_test \
  "XLS" \
  "application/vnd.ms-excel" \
  "$DOCS_DIR/test.xls"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed (total: $TOTAL)"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
