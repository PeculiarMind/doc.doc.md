#!/bin/bash
# Test suite for FEATURE_0047: OTS Text Summarizer Plugin
# TDD: Tests define the contract BEFORE implementation
# Run from repository root: bash tests/test_feature_0047.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OTS_PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins/ots"

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

# Check if ots is installed — tests that need it will skip if not
OTS_AVAILABLE=false
if command -v ots >/dev/null 2>&1; then
  OTS_AVAILABLE=true
fi

# ============================================================
# Group 1: Plugin structure validation
# ============================================================

echo ""
echo "=== Group 1: Plugin structure ==="

echo ""
echo "--- Test 1.1: Plugin directory exists ---"
TOTAL=$((TOTAL + 1))
if [ -d "$OTS_PLUGIN_DIR" ]; then
  echo "  PASS: Plugin directory exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Plugin directory missing: $OTS_PLUGIN_DIR"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "--- Test 1.2: Required files exist ---"
for f in descriptor.json main.sh install.sh installed.sh; do
  TOTAL=$((TOTAL + 1))
  if [ -f "$OTS_PLUGIN_DIR/$f" ]; then
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
  if [ -x "$OTS_PLUGIN_DIR/$f" ]; then
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
if jq empty "$OTS_PLUGIN_DIR/descriptor.json" 2>/dev/null; then
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
  val=$(jq -r ".$field" "$OTS_PLUGIN_DIR/descriptor.json" 2>/dev/null)
  if [ -n "$val" ] && [ "$val" != "null" ]; then
    echo "  PASS: descriptor has $field"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: descriptor missing $field"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "--- Test 1.6: descriptor.json name is 'ots' ---"
TOTAL=$((TOTAL + 1))
name=$(jq -r '.name' "$OTS_PLUGIN_DIR/descriptor.json" 2>/dev/null)
if [ "$name" = "ots" ]; then
  echo "  PASS: name is 'ots'"
  PASS=$((PASS + 1))
else
  echo "  FAIL: name is '$name', expected 'ots'"
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
output=$(bash "$OTS_PLUGIN_DIR/installed.sh" 2>&1) || ec=$?
assert_exit_code "installed.sh exits 0" "0" "$ec"

echo ""
echo "--- Test 2.2: installed.sh returns JSON ---"
TOTAL=$((TOTAL + 1))
if echo "$output" | jq empty 2>/dev/null; then
  echo "  PASS: installed.sh returns valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: installed.sh does not return valid JSON"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "--- Test 2.3: installed.sh reports correct state ---"
TOTAL=$((TOTAL + 1))
installed_val=$(echo "$output" | jq -r '.installed' 2>/dev/null)
if [ "$OTS_AVAILABLE" = "true" ]; then
  if [ "$installed_val" = "true" ]; then
    echo "  PASS: installed is true (ots is available)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: installed should be true (ots is available)"
    FAIL=$((FAIL + 1))
  fi
else
  if [ "$installed_val" = "false" ]; then
    echo "  PASS: installed is false (ots is not available)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: installed should be false (ots is not available)"
    FAIL=$((FAIL + 1))
  fi
fi

# ============================================================
# Group 3: install.sh
# ============================================================

echo ""
echo "=== Group 3: install.sh ==="

echo ""
echo "--- Test 3.1: install.sh exits 0 ---"
ec=0
output=$(bash "$OTS_PLUGIN_DIR/install.sh" 2>&1) || ec=$?
# install.sh should exit 0 if ots is available, non-zero otherwise
if [ "$OTS_AVAILABLE" = "true" ]; then
  assert_exit_code "install.sh exits 0 (ots available)" "0" "$ec"
else
  TOTAL=$((TOTAL + 1))
  echo "  SKIP: install.sh skipped (ots not installed, cannot install without root)"
  SKIP=$((SKIP + 1))
fi

# ============================================================
# Group 4: process command — textContent field (highest priority)
# ============================================================

echo ""
echo "=== Group 4: process via textContent ==="

if [ "$OTS_AVAILABLE" = "true" ]; then
  echo ""
  echo "--- Test 4.1: Summary produced from textContent ---"
  test_text="The quick brown fox jumps over the lazy dog. The dog barked at the fox. The fox ran away quickly. The brown fox was very fast. The lazy dog stayed behind. The fox found a new place to hide. The dog went back to sleep. The end of the story."
  input_json=$(jq -n --arg tc "$test_text" --arg fp "/tmp/test.txt" '{filePath: $fp, textContent: $tc}')
  ec=0
  output=$(echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  assert_exit_code "main.sh exits 0 with textContent" "0" "$ec"

  echo ""
  echo "--- Test 4.2: Output contains summaryText field ---"
  TOTAL=$((TOTAL + 1))
  summary_text=$(echo "$output" | jq -r '.summaryText' 2>/dev/null)
  if [ -n "$summary_text" ] && [ "$summary_text" != "null" ]; then
    echo "  PASS: summaryText is present"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: summaryText is missing or null"
    FAIL=$((FAIL + 1))
  fi

  echo ""
  echo "--- Test 4.3: Output contains summaryRatio field ---"
  TOTAL=$((TOTAL + 1))
  ratio=$(echo "$output" | jq -r '.summaryRatio' 2>/dev/null)
  if [ -n "$ratio" ] && [ "$ratio" != "null" ]; then
    echo "  PASS: summaryRatio is present ($ratio)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: summaryRatio is missing or null"
    FAIL=$((FAIL + 1))
  fi

  echo ""
  echo "--- Test 4.4: Default summaryRatio is 20 ---"
  assert_eq "Default summaryRatio is 20" "20" "$ratio"
else
  echo ""
  echo "--- Tests 4.1-4.4: SKIP (ots not installed) ---"
  for _ in 1 2 3 4; do
    TOTAL=$((TOTAL + 1))
    SKIP=$((SKIP + 1))
  done
fi

# ============================================================
# Group 5: process command — ocrText fallback
# ============================================================

echo ""
echo "=== Group 5: ocrText fallback ==="

if [ "$OTS_AVAILABLE" = "true" ]; then
  echo ""
  echo "--- Test 5.1: Falls back to ocrText when textContent is empty ---"
  ocr_text="The quick brown fox jumps over the lazy dog. The dog barked at the fox. The fox ran away quickly. The brown fox was very fast."
  input_json=$(jq -n --arg ot "$ocr_text" --arg fp "/tmp/test.txt" '{filePath: $fp, textContent: "", ocrText: $ot}')
  ec=0
  output=$(echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  assert_exit_code "main.sh exits 0 with ocrText fallback" "0" "$ec"

  TOTAL=$((TOTAL + 1))
  summary_text=$(echo "$output" | jq -r '.summaryText' 2>/dev/null)
  if [ -n "$summary_text" ] && [ "$summary_text" != "null" ]; then
    echo "  PASS: summaryText from ocrText"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: summaryText missing from ocrText"
    FAIL=$((FAIL + 1))
  fi
else
  echo ""
  echo "--- Tests 5.1: SKIP (ots not installed) ---"
  for _ in 1 2; do
    TOTAL=$((TOTAL + 1))
    SKIP=$((SKIP + 1))
  done
fi

# ============================================================
# Group 6: process command — documentText fallback
# ============================================================

echo ""
echo "=== Group 6: documentText fallback ==="

if [ "$OTS_AVAILABLE" = "true" ]; then
  echo ""
  echo "--- Test 6.1: Falls back to documentText when textContent and ocrText are empty ---"
  doc_text="The quick brown fox jumps over the lazy dog. The dog barked at the fox. The fox ran away quickly."
  input_json=$(jq -n --arg dt "$doc_text" --arg fp "/tmp/test.txt" '{filePath: $fp, documentText: $dt}')
  ec=0
  output=$(echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  assert_exit_code "main.sh exits 0 with documentText fallback" "0" "$ec"

  TOTAL=$((TOTAL + 1))
  summary_text=$(echo "$output" | jq -r '.summaryText' 2>/dev/null)
  if [ -n "$summary_text" ] && [ "$summary_text" != "null" ]; then
    echo "  PASS: summaryText from documentText"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: summaryText missing from documentText"
    FAIL=$((FAIL + 1))
  fi
else
  echo ""
  echo "--- Tests 6.1: SKIP (ots not installed) ---"
  for _ in 1 2; do
    TOTAL=$((TOTAL + 1))
    SKIP=$((SKIP + 1))
  done
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
echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" >/dev/null 2>&1 || ec=$?
assert_exit_code "Exit 65 when no text fields" "65" "$ec"

echo ""
echo "--- Test 7.2: Exit 65 when all text fields are empty ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" '{filePath: $fp, textContent: "", ocrText: "", documentText: ""}')
ec=0
echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" >/dev/null 2>&1 || ec=$?
assert_exit_code "Exit 65 when all text fields empty" "65" "$ec"

# ============================================================
# Group 8: Custom summaryRatio
# ============================================================

echo ""
echo "=== Group 8: summaryRatio handling ==="

if [ "$OTS_AVAILABLE" = "true" ]; then
  echo ""
  echo "--- Test 8.1: Custom summaryRatio is passed through ---"
  test_text="The quick brown fox jumps over the lazy dog. The dog barked at the fox. The fox ran away quickly. The brown fox was very fast. The lazy dog stayed behind."
  input_json=$(jq -n --arg tc "$test_text" --arg fp "/tmp/test.txt" --argjson sr 50 '{filePath: $fp, textContent: $tc, summaryRatio: $sr}')
  ec=0
  output=$(echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  assert_exit_code "main.sh exits 0 with custom ratio" "0" "$ec"

  ratio=$(echo "$output" | jq -r '.summaryRatio' 2>/dev/null)
  assert_eq "summaryRatio is 50" "50" "$ratio"

  echo ""
  echo "--- Test 8.2: Invalid summaryRatio falls back to default (20) ---"
  input_json=$(jq -n --arg tc "$test_text" --arg fp "/tmp/test.txt" --arg sr "invalid" '{filePath: $fp, textContent: $tc, summaryRatio: $sr}')
  ec=0
  output=$(echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  assert_exit_code "main.sh exits 0 with invalid ratio" "0" "$ec"

  ratio=$(echo "$output" | jq -r '.summaryRatio' 2>/dev/null)
  assert_eq "summaryRatio fallback to 20" "20" "$ratio"

  echo ""
  echo "--- Test 8.3: summaryRatio 0 falls back to default (20) ---"
  input_json=$(jq -n --arg tc "$test_text" --arg fp "/tmp/test.txt" --argjson sr 0 '{filePath: $fp, textContent: $tc, summaryRatio: $sr}')
  ec=0
  output=$(echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  ratio=$(echo "$output" | jq -r '.summaryRatio' 2>/dev/null)
  assert_eq "summaryRatio 0 fallback to 20" "20" "$ratio"

  echo ""
  echo "--- Test 8.4: summaryRatio 101 falls back to default (20) ---"
  input_json=$(jq -n --arg tc "$test_text" --arg fp "/tmp/test.txt" --argjson sr 101 '{filePath: $fp, textContent: $tc, summaryRatio: $sr}')
  ec=0
  output=$(echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  ratio=$(echo "$output" | jq -r '.summaryRatio' 2>/dev/null)
  assert_eq "summaryRatio 101 fallback to 20" "20" "$ratio"
else
  echo ""
  echo "--- Tests 8.1-8.4: SKIP (ots not installed) ---"
  for _ in 1 2 3 4 5 6; do
    TOTAL=$((TOTAL + 1))
    SKIP=$((SKIP + 1))
  done
fi

# ============================================================
# Group 9: languageCode dictionary selection
# ============================================================

echo ""
echo "=== Group 9: languageCode handling ==="

if [ "$OTS_AVAILABLE" = "true" ]; then
  test_text="The quick brown fox jumps over the lazy dog. The dog barked at the fox. The fox ran away quickly. The brown fox was very fast."

  echo ""
  echo "--- Test 9.1: languageCode absent — summaryLanguage is null ---"
  input_json=$(jq -n --arg tc "$test_text" --arg fp "/tmp/test.txt" '{filePath: $fp, textContent: $tc}')
  ec=0
  output=$(echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  lang=$(echo "$output" | jq -r '.summaryLanguage' 2>/dev/null)
  assert_eq "summaryLanguage is null when languageCode absent" "null" "$lang"

  echo ""
  echo "--- Test 9.2: languageCode with no matching dictionary — summaryLanguage is null ---"
  input_json=$(jq -n --arg tc "$test_text" --arg fp "/tmp/test.txt" --arg lc "zh" '{filePath: $fp, textContent: $tc, languageCode: $lc}')
  ec=0
  output=$(echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  lang=$(echo "$output" | jq -r '.summaryLanguage' 2>/dev/null)
  assert_eq "summaryLanguage is null for unknown dict" "null" "$lang"

  echo ""
  echo "--- Test 9.3: Invalid/malicious languageCode rejected ---"
  input_json=$(jq -n --arg tc "$test_text" --arg fp "/tmp/test.txt" --arg lc "../etc/passwd" '{filePath: $fp, textContent: $tc, languageCode: $lc}')
  ec=0
  output=$(echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  assert_exit_code "main.sh exits 0 with malicious languageCode" "0" "$ec"
  lang=$(echo "$output" | jq -r '.summaryLanguage' 2>/dev/null)
  assert_eq "summaryLanguage is null for malicious input" "null" "$lang"

  echo ""
  echo "--- Test 9.4: languageCode with matching dictionary ---"
  # Check if en.xml dictionary exists
  if [ -f "/usr/share/ots/en.xml" ]; then
    input_json=$(jq -n --arg tc "$test_text" --arg fp "/tmp/test.txt" --arg lc "en" '{filePath: $fp, textContent: $tc, languageCode: $lc}')
    ec=0
    output=$(echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
    assert_exit_code "main.sh exits 0 with languageCode en" "0" "$ec"
    lang=$(echo "$output" | jq -r '.summaryLanguage' 2>/dev/null)
    assert_eq "summaryLanguage is 'en'" "en" "$lang"
  else
    TOTAL=$((TOTAL + 1))
    echo "  SKIP: en.xml dictionary not found"
    SKIP=$((SKIP + 1))
    TOTAL=$((TOTAL + 1))
    echo "  SKIP: en.xml dictionary not found"
    SKIP=$((SKIP + 1))
  fi
else
  echo ""
  echo "--- Tests 9.1-9.4: SKIP (ots not installed) ---"
  for _ in 1 2 3 4 5 6; do
    TOTAL=$((TOTAL + 1))
    SKIP=$((SKIP + 1))
  done
fi

# ============================================================
# Group 10: Valid JSON output
# ============================================================

echo ""
echo "=== Group 10: Valid JSON output ==="

if [ "$OTS_AVAILABLE" = "true" ]; then
  echo ""
  echo "--- Test 10.1: stdout is valid JSON ---"
  test_text="The quick brown fox jumps over the lazy dog. The dog barked at the fox."
  input_json=$(jq -n --arg tc "$test_text" --arg fp "/tmp/test.txt" '{filePath: $fp, textContent: $tc}')
  output=$(echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" 2>/dev/null) || true
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
  echo "--- Test 10.2: Output has all required fields ---"
  for field in summaryText summaryRatio summaryLanguage; do
    TOTAL=$((TOTAL + 1))
    val=$(echo "$output" | jq ".$field" 2>/dev/null)
    if [ -n "$val" ] && [ "$val" != "" ]; then
      echo "  PASS: output has $field"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: output missing $field"
      FAIL=$((FAIL + 1))
    fi
  done

  echo ""
  echo "--- Test 10.3: No files written to disk ---"
  TOTAL=$((TOTAL + 1))
  test_text="The quick brown fox jumps over the lazy dog."
  input_json=$(jq -n --arg tc "$test_text" --arg fp "/tmp/test.txt" '{filePath: $fp, textContent: $tc}')
  tmpdir=$(mktemp -d)
  (cd "$tmpdir" && echo "$input_json" | bash "$OTS_PLUGIN_DIR/main.sh" >/dev/null 2>&1) || true
  file_count=$(find "$tmpdir" -type f | wc -l)
  rm -rf "$tmpdir"
  if [ "$file_count" -eq 0 ]; then
    echo "  PASS: No files written to disk"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: Files were written to disk ($file_count files)"
    FAIL=$((FAIL + 1))
  fi
else
  echo ""
  echo "--- Tests 10.1-10.3: SKIP (ots not installed) ---"
  for _ in 1 2 3 4 5; do
    TOTAL=$((TOTAL + 1))
    SKIP=$((SKIP + 1))
  done
fi

# ---- summary ----

echo ""
echo "==========================================="
echo "  FEATURE_0047 Results: $PASS passed, $FAIL failed, $SKIP skipped out of $TOTAL"
echo "==========================================="
echo ""

exit "$FAIL"
