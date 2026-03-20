#!/bin/bash
# Test suite for FEATURE_0048: WC Word Count Plugin
# TDD: Tests define the contract BEFORE implementation
# Run from repository root: bash tests/test_feature_0048.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WC_PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins/wc"

PASS=0
FAIL=0
SKIP=0
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
    echo "    Actual: $(echo "$actual" | head -5)"
    FAIL=$((FAIL + 1))
  fi
}

# ============================================================
# Group 1: Plugin structure validation
# ============================================================

echo ""
echo "=== Group 1: Plugin structure ==="

echo ""
echo "--- Test 1.1: Plugin directory exists ---"
TOTAL=$((TOTAL + 1))
if [ -d "$WC_PLUGIN_DIR" ]; then
  echo "  PASS: Plugin directory exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Plugin directory missing: $WC_PLUGIN_DIR"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "--- Test 1.2: Required files exist ---"
for f in descriptor.json main.sh install.sh installed.sh; do
  TOTAL=$((TOTAL + 1))
  if [ -f "$WC_PLUGIN_DIR/$f" ]; then
    echo "  PASS: $f exists"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $f missing"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "--- Test 1.3: Scripts are executable ---"
for f in main.sh install.sh installed.sh; do
  TOTAL=$((TOTAL + 1))
  if [ -x "$WC_PLUGIN_DIR/$f" ]; then
    echo "  PASS: $f is executable"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $f is not executable"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "--- Test 1.4: descriptor.json is valid JSON ---"
TOTAL=$((TOTAL + 1))
if jq empty "$WC_PLUGIN_DIR/descriptor.json" 2>/dev/null; then
  echo "  PASS: descriptor.json is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor.json is not valid JSON"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "--- Test 1.5: descriptor.json has required fields ---"
for field in name version description active; do
  TOTAL=$((TOTAL + 1))
  val=$(jq -r ".$field" "$WC_PLUGIN_DIR/descriptor.json" 2>/dev/null)
  if [ -n "$val" ] && [ "$val" != "null" ]; then
    echo "  PASS: descriptor has $field"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: descriptor missing $field"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "--- Test 1.6: descriptor.json name is 'wc' ---"
TOTAL=$((TOTAL + 1))
name=$(jq -r '.name' "$WC_PLUGIN_DIR/descriptor.json" 2>/dev/null)
if [ "$name" = "wc" ]; then
  echo "  PASS: name is 'wc'"
  PASS=$((PASS + 1))
else
  echo "  FAIL: name is '$name', expected 'wc'"
  FAIL=$((FAIL + 1))
fi

# ============================================================
# Group 2: installed.sh
# ============================================================

echo ""
echo "=== Group 2: installed.sh ==="

echo ""
echo "--- Test 2.1: installed.sh exits 0 ---"
ec=0
output=$(bash "$WC_PLUGIN_DIR/installed.sh" 2>&1) || ec=$?
assert_exit_code "installed.sh exits 0" "0" "$ec"

echo ""
echo "--- Test 2.2: installed.sh returns JSON with installed: true ---"
TOTAL=$((TOTAL + 1))
installed_val=$(echo "$output" | jq -r '.installed' 2>/dev/null)
if [ "$installed_val" = "true" ]; then
  echo "  PASS: installed is true"
  PASS=$((PASS + 1))
else
  echo "  FAIL: installed is '$installed_val'"
  FAIL=$((FAIL + 1))
fi

# ============================================================
# Group 3: install.sh
# ============================================================

echo ""
echo "=== Group 3: install.sh ==="

echo ""
echo "--- Test 3.1: install.sh exits 0 ---"
ec=0
output=$(bash "$WC_PLUGIN_DIR/install.sh" 2>&1) || ec=$?
assert_exit_code "install.sh exits 0" "0" "$ec"

# ============================================================
# Group 4: process command (main.sh) — textContent field
# ============================================================

echo ""
echo "=== Group 4: process via textContent ==="

echo ""
echo "--- Test 4.1: Correct counts for known text via textContent ---"
# "hello world\nfoo bar baz\n" = 2 lines, 5 words
test_text="hello world
foo bar baz"
input_json=$(jq -n --arg tc "$test_text" --arg fp "/tmp/test.txt" '{filePath: $fp, textContent: $tc}')
ec=0
output=$(echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
assert_exit_code "main.sh exits 0 with textContent" "0" "$ec"

wc_val=$(printf '%s' "$test_text" | wc -w | tr -d ' ')
TOTAL=$((TOTAL + 1))
json_wc=$(echo "$output" | jq -r '.wordCount' 2>/dev/null)
if [ "$json_wc" = "$wc_val" ]; then
  echo "  PASS: wordCount matches wc output ($wc_val)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: wordCount is '$json_wc', expected '$wc_val'"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
json_lc=$(echo "$output" | jq -r '.lineCount' 2>/dev/null)
lc_val=$(printf '%s' "$test_text" | wc -l | tr -d ' ')
if [ "$json_lc" = "$lc_val" ]; then
  echo "  PASS: lineCount matches ($lc_val)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: lineCount is '$json_lc', expected '$lc_val'"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
json_cc=$(echo "$output" | jq -r '.charCount' 2>/dev/null)
cc_val=$(printf '%s' "$test_text" | wc -m | tr -d ' ')
if [ "$json_cc" = "$cc_val" ]; then
  echo "  PASS: charCount matches ($cc_val)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: charCount is '$json_cc', expected '$cc_val'"
  FAIL=$((FAIL + 1))
fi

# ============================================================
# Group 5: process command — ocrText fallback
# ============================================================

echo ""
echo "=== Group 5: ocrText fallback ==="

echo ""
echo "--- Test 5.1: Falls back to ocrText when textContent is empty ---"
ocr_text="ocr line one
ocr line two
ocr line three"
input_json=$(jq -n --arg ot "$ocr_text" --arg fp "/tmp/test.txt" '{filePath: $fp, textContent: "", ocrText: $ot}')
ec=0
output=$(echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
assert_exit_code "main.sh exits 0 with ocrText fallback" "0" "$ec"

wc_val=$(printf '%s' "$ocr_text" | wc -w | tr -d ' ')
TOTAL=$((TOTAL + 1))
json_wc=$(echo "$output" | jq -r '.wordCount' 2>/dev/null)
if [ "$json_wc" = "$wc_val" ]; then
  echo "  PASS: wordCount from ocrText ($wc_val)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: wordCount is '$json_wc', expected '$wc_val'"
  FAIL=$((FAIL + 1))
fi

# ============================================================
# Group 6: process command — documentText fallback
# ============================================================

echo ""
echo "=== Group 6: documentText fallback ==="

echo ""
echo "--- Test 6.1: Falls back to documentText when textContent and ocrText are empty ---"
doc_text="document text here"
input_json=$(jq -n --arg dt "$doc_text" --arg fp "/tmp/test.txt" '{filePath: $fp, documentText: $dt}')
ec=0
output=$(echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
assert_exit_code "main.sh exits 0 with documentText fallback" "0" "$ec"

wc_val=$(printf '%s' "$doc_text" | wc -w | tr -d ' ')
TOTAL=$((TOTAL + 1))
json_wc=$(echo "$output" | jq -r '.wordCount' 2>/dev/null)
if [ "$json_wc" = "$wc_val" ]; then
  echo "  PASS: wordCount from documentText ($wc_val)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: wordCount is '$json_wc', expected '$wc_val'"
  FAIL=$((FAIL + 1))
fi

# ============================================================
# Group 7: Skip when no text available
# ============================================================

echo ""
echo "=== Group 7: Skip when no text ==="

echo ""
echo "--- Test 7.1: Exit 65 when no text fields present ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" '{filePath: $fp}')
ec=0
echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" >/dev/null 2>&1 || ec=$?
assert_exit_code "Exit 65 when no text fields" "65" "$ec"

echo ""
echo "--- Test 7.2: Exit 65 when all text fields are empty ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" '{filePath: $fp, textContent: "", ocrText: "", documentText: ""}')
ec=0
echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" >/dev/null 2>&1 || ec=$?
assert_exit_code "Exit 65 when all text fields empty" "65" "$ec"

# ============================================================
# Group 8: Output is valid JSON
# ============================================================

echo ""
echo "=== Group 8: Valid JSON output ==="

echo ""
echo "--- Test 8.1: stdout is valid JSON ---"
test_text="valid json test"
input_json=$(jq -n --arg tc "$test_text" --arg fp "/tmp/test.txt" '{filePath: $fp, textContent: $tc}')
output=$(echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" 2>/dev/null) || true
TOTAL=$((TOTAL + 1))
if echo "$output" | jq empty 2>/dev/null; then
  echo "  PASS: stdout is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: stdout is not valid JSON"
  echo "    Output: $output"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "--- Test 8.2: Output has all three count fields ---"
for field in lineCount wordCount charCount; do
  TOTAL=$((TOTAL + 1))
  val=$(echo "$output" | jq -r ".$field" 2>/dev/null)
  if [ -n "$val" ] && [ "$val" != "null" ]; then
    echo "  PASS: output has $field"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: output missing $field"
    FAIL=$((FAIL + 1))
  fi
done

# ---- summary ----

echo ""
echo "==========================================="
echo "  FEATURE_0048 Results: $PASS passed, $FAIL failed, $SKIP skipped out of $TOTAL"
echo "==========================================="
echo ""

exit "$FAIL"
