#!/bin/bash
# Test suite for FEATURE_0049: Word Coverage Plugin
# TDD: Tests define the contract BEFORE implementation
# Run from repository root: bash tests/test_feature_0049.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WC_PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins/wordcoverage"

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
echo "--- Test 1.6: descriptor.json name is 'wordcoverage' ---"
TOTAL=$((TOTAL + 1))
name=$(jq -r '.name' "$WC_PLUGIN_DIR/descriptor.json" 2>/dev/null)
if [ "$name" = "wordcoverage" ]; then
  echo "  PASS: name is 'wordcoverage'"
  PASS=$((PASS + 1))
else
  echo "  FAIL: name is '$name', expected 'wordcoverage'"
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
# Group 4: Coverage calculation — wordCount > maxWords
# ============================================================

echo ""
echo "=== Group 4: Coverage when wordCount > maxWords ==="

echo ""
echo "--- Test 4.1: Coverage for 500 words with default maxWords (100) ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" --argjson wc 500 '{filePath: $fp, wordCount: $wc}')
ec=0
output=$(echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
assert_exit_code "main.sh exits 0" "0" "$ec"

coverage=$(echo "$output" | jq -r '.summaryCoveragePercent' 2>/dev/null)
assert_eq "Coverage is 20.00 (100/500*100)" "20.00" "$coverage"

max_words=$(echo "$output" | jq -r '.summaryMaxWords' 2>/dev/null)
assert_eq "summaryMaxWords is 100" "100" "$max_words"

echo ""
echo "--- Test 4.2: Coverage for 1000 words with maxWords=250 ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" --argjson wc 1000 --argjson mw 250 '{filePath: $fp, wordCount: $wc, maxWords: $mw}')
ec=0
output=$(echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
coverage=$(echo "$output" | jq -r '.summaryCoveragePercent' 2>/dev/null)
assert_eq "Coverage is 25.00 (250/1000*100)" "25.00" "$coverage"

echo ""
echo "--- Test 4.3: Coverage for 300 words with maxWords=100 ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" --argjson wc 300 '{filePath: $fp, wordCount: $wc}')
ec=0
output=$(echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
coverage=$(echo "$output" | jq -r '.summaryCoveragePercent' 2>/dev/null)
assert_eq "Coverage is 33.33 (100/300*100)" "33.33" "$coverage"

# ============================================================
# Group 5: Coverage calculation — wordCount <= maxWords
# ============================================================

echo ""
echo "=== Group 5: Coverage when wordCount <= maxWords ==="

echo ""
echo "--- Test 5.1: Coverage is 100.0 when wordCount == maxWords ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" --argjson wc 100 '{filePath: $fp, wordCount: $wc}')
ec=0
output=$(echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
coverage=$(echo "$output" | jq -r '.summaryCoveragePercent' 2>/dev/null)
assert_eq "Coverage is 100.0 when wordCount == maxWords" "100.0" "$coverage"

echo ""
echo "--- Test 5.2: Coverage is 100.0 when wordCount < maxWords ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" --argjson wc 50 '{filePath: $fp, wordCount: $wc}')
ec=0
output=$(echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
coverage=$(echo "$output" | jq -r '.summaryCoveragePercent' 2>/dev/null)
assert_eq "Coverage is 100.0 when wordCount < maxWords" "100.0" "$coverage"

# ============================================================
# Group 6: Skip when wordCount missing or zero
# ============================================================

echo ""
echo "=== Group 6: Skip behavior ==="

echo ""
echo "--- Test 6.1: Exit 65 when wordCount is absent ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" '{filePath: $fp}')
ec=0
echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" >/dev/null 2>&1 || ec=$?
assert_exit_code "Exit 65 when wordCount absent" "65" "$ec"

echo ""
echo "--- Test 6.2: Exit 65 when wordCount is zero ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" --argjson wc 0 '{filePath: $fp, wordCount: $wc}')
ec=0
echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" >/dev/null 2>&1 || ec=$?
assert_exit_code "Exit 65 when wordCount is zero" "65" "$ec"

# ============================================================
# Group 7: maxWords handling
# ============================================================

echo ""
echo "=== Group 7: maxWords handling ==="

echo ""
echo "--- Test 7.1: Custom maxWords is respected ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" --argjson wc 200 --argjson mw 50 '{filePath: $fp, wordCount: $wc, maxWords: $mw}')
ec=0
output=$(echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
max_words=$(echo "$output" | jq -r '.summaryMaxWords' 2>/dev/null)
assert_eq "summaryMaxWords is 50" "50" "$max_words"

echo ""
echo "--- Test 7.2: Invalid maxWords falls back to default (100) ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" --argjson wc 200 --arg mw "invalid" '{filePath: $fp, wordCount: $wc, maxWords: $mw}')
ec=0
output=$(echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
max_words=$(echo "$output" | jq -r '.summaryMaxWords' 2>/dev/null)
assert_eq "summaryMaxWords falls back to 100" "100" "$max_words"

echo ""
echo "--- Test 7.3: maxWords 0 falls back to default (100) ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" --argjson wc 200 --argjson mw 0 '{filePath: $fp, wordCount: $wc, maxWords: $mw}')
ec=0
output=$(echo "$input_json" | bash "$WC_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
max_words=$(echo "$output" | jq -r '.summaryMaxWords' 2>/dev/null)
assert_eq "summaryMaxWords 0 falls back to 100" "100" "$max_words"

# ============================================================
# Group 8: Valid JSON output
# ============================================================

echo ""
echo "=== Group 8: Valid JSON output ==="

echo ""
echo "--- Test 8.1: stdout is valid JSON ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" --argjson wc 200 '{filePath: $fp, wordCount: $wc}')
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
echo "--- Test 8.2: Output has both required fields ---"
for field in summaryMaxWords summaryCoveragePercent; do
  TOTAL=$((TOTAL + 1))
  val=$(echo "$output" | jq ".$field" 2>/dev/null)
  if [ -n "$val" ] && [ "$val" != "null" ] && [ "$val" != "" ]; then
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
echo "  FEATURE_0049 Results: $PASS passed, $FAIL failed, $SKIP skipped out of $TOTAL"
echo "==========================================="
echo ""

exit "$FAIL"
