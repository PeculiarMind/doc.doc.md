#!/bin/bash
# Test suite for FEATURE_0019: Process Output Directory
# Run from repository root: bash tests/test_feature_0019.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
DEFAULT_TEMPLATE="$REPO_ROOT/doc.doc.md/templates/default.md"

PASS=0
FAIL=0
TOTAL=0

INPUT_DIR=""
OUTPUT_DIR=""
CUSTOM_TEMPLATE=""

cleanup() {
  [ -n "$INPUT_DIR" ] && [ -d "$INPUT_DIR" ] && rm -rf "$INPUT_DIR"
  [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ] && rm -rf "$OUTPUT_DIR"
  [ -n "$CUSTOM_TEMPLATE" ] && [ -f "$CUSTOM_TEMPLATE" ] && rm -f "$CUSTOM_TEMPLATE"
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

assert_file_exists() {
  local test_name="$1" path="$2"
  TOTAL=$((TOTAL + 1))
  if [ -f "$path" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name (file not found: $path)"
    FAIL=$((FAIL + 1))
  fi
}

echo "============================================"
echo "  FEATURE_0019: Process Output Directory"
echo "============================================"
echo ""

# Setup
INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
echo "hello" > "$INPUT_DIR/test.txt"
mkdir -p "$INPUT_DIR/subdir"
echo "world" > "$INPUT_DIR/subdir/nested.txt"

# =========================================
# Group 1: -o flag required
# =========================================
echo "--- Group 1: -o flag required ---"

output=$(bash "$CLI" process -d "$INPUT_DIR" 2>&1)
exit_code=$?
assert_exit_code "process without -o exits 1" "1" "$exit_code"
assert_contains "missing -o shows error" "Output directory is required" "$output"

# =========================================
# Group 2: Process creates output directory
# =========================================
echo ""
echo "--- Group 2: Output directory creation ---"

NEW_OUT="$OUTPUT_DIR/newdir_$$"
output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$NEW_OUT" 2>/dev/null)
exit_code=$?
assert_exit_code "process with -o exits 0" "0" "$exit_code"

TOTAL=$((TOTAL + 1))
if [ -d "$NEW_OUT" ]; then
  echo "  PASS: output directory was created"
  PASS=$((PASS + 1))
else
  echo "  FAIL: output directory was not created"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 3: Sidecar .md files created
# =========================================
echo ""
echo "--- Group 3: Sidecar .md files created ---"

SIDECAR_OUT="$OUTPUT_DIR/sidecars_$$"
output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$SIDECAR_OUT" 2>/dev/null)
assert_file_exists "sidecar for test.txt" "$SIDECAR_OUT/test.txt.md"
assert_file_exists "sidecar for subdir/nested.txt" "$SIDECAR_OUT/subdir/nested.txt.md"

# =========================================
# Group 4: JSON still output to stdout
# =========================================
echo ""
echo "--- Group 4: JSON output to stdout ---"

JSON_OUT="$OUTPUT_DIR/json_$$"
json_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$JSON_OUT" 2>/dev/null)
exit_code=$?
assert_exit_code "process exits 0" "0" "$exit_code"

TOTAL=$((TOTAL + 1))
if echo "$json_output" | jq empty 2>/dev/null; then
  echo "  PASS: stdout is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: stdout is NOT valid JSON"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 5: Status/progress goes to stderr
# =========================================
echo ""
echo "--- Group 5: Status/progress to stderr ---"

STDERR_OUT="$OUTPUT_DIR/stderr_$$"
stderr_output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$STDERR_OUT" 2>&1 >/dev/null)
assert_contains "stderr shows processed file" "Processed:" "$stderr_output"

# =========================================
# Group 6: --input-directory long form
# =========================================
echo ""
echo "--- Group 6: --input-directory long form ---"

LONG_OUT="$OUTPUT_DIR/long_$$"
output=$(bash "$CLI" process --input-directory "$INPUT_DIR" -o "$LONG_OUT" 2>/dev/null)
exit_code=$?
assert_exit_code "--input-directory works" "0" "$exit_code"

TOTAL=$((TOTAL + 1))
if [ -d "$LONG_OUT" ]; then
  echo "  PASS: --input-directory creates output"
  PASS=$((PASS + 1))
else
  echo "  FAIL: --input-directory did not create output"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 7: --output-directory long form
# =========================================
echo ""
echo "--- Group 7: --output-directory long form ---"

LONGOUT_OUT="$OUTPUT_DIR/longout_$$"
output=$(bash "$CLI" process -d "$INPUT_DIR" --output-directory "$LONGOUT_OUT" 2>/dev/null)
exit_code=$?
assert_exit_code "--output-directory works" "0" "$exit_code"

# =========================================
# Group 8: Custom template -t flag
# =========================================
echo ""
echo "--- Group 8: Custom template -t flag ---"

CUSTOM_TEMPLATE=$(mktemp --suffix=.md)
echo "# {{fileName}} - custom template" > "$CUSTOM_TEMPLATE"

TMPL_OUT="$OUTPUT_DIR/tmpl_$$"
output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$TMPL_OUT" -t "$CUSTOM_TEMPLATE" 2>/dev/null)
exit_code=$?
assert_exit_code "process with -t exits 0" "0" "$exit_code"

TOTAL=$((TOTAL + 1))
if [ -f "$TMPL_OUT/test.txt.md" ]; then
  sidecar_content=$(cat "$TMPL_OUT/test.txt.md")
  if echo "$sidecar_content" | grep -q "custom template"; then
    echo "  PASS: custom template content used in sidecar"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: custom template not used (got: $sidecar_content)"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: sidecar file not created with custom template"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 9: Template file not found error
# =========================================
echo ""
echo "--- Group 9: Invalid template file ---"

ERR_OUT="$OUTPUT_DIR/err_$$"
output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$ERR_OUT" -t "/nonexistent/template.md" 2>&1)
exit_code=$?
assert_exit_code "invalid template exits 1" "1" "$exit_code"
assert_contains "invalid template error message" "Template file not found" "$output"

# =========================================
# Group 10: Sidecar content uses default template placeholders
# =========================================
echo ""
echo "--- Group 10: Default template placeholder replacement ---"

DFTMPL_OUT="$OUTPUT_DIR/dftmpl_$$"
output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$DFTMPL_OUT" 2>/dev/null)

TOTAL=$((TOTAL + 1))
if [ -f "$DFTMPL_OUT/test.txt.md" ]; then
  sidecar_content=$(cat "$DFTMPL_OUT/test.txt.md")
  # fileName placeholder should be replaced (no literal {{fileName}})
  if echo "$sidecar_content" | grep -q '{{fileName}}'; then
    echo "  FAIL: {{fileName}} placeholder was NOT replaced in sidecar"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: placeholders replaced in default template sidecar"
    PASS=$((PASS + 1))
  fi
else
  echo "  FAIL: sidecar file not found"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 11: Help text mentions -o
# =========================================
echo ""
echo "--- Group 11: Help text ---"

output=$(bash "$CLI" --help 2>&1)
assert_contains "help mentions -o" "-o" "$output"
assert_contains "help mentions output-directory" "output-directory" "$output"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
