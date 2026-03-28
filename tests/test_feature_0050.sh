#!/bin/bash
# Test suite for FEATURE_0050: Language Identification Plugin (langid)
# TDD: Tests define the contract BEFORE implementation
# Run from repository root: bash tests/test_feature_0050.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LANGID_PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins/langid"

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

# Check if langid is installed — tests that need it will skip if not
LANGID_AVAILABLE=false
if python3 -c "import langid" >/dev/null 2>&1; then
  LANGID_AVAILABLE=true
fi

# ============================================================
# Group 1: Plugin structure validation
# ============================================================

echo ""
echo "=== Group 1: Plugin structure ==="

echo ""
echo "--- Test 1.1: Plugin directory exists ---"
TOTAL=$((TOTAL + 1))
if [ -d "$LANGID_PLUGIN_DIR" ]; then
  echo "  PASS: Plugin directory exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Plugin directory missing: $LANGID_PLUGIN_DIR"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "--- Test 1.2: Required files exist ---"
for f in descriptor.json main.sh install.sh installed.sh; do
  TOTAL=$((TOTAL + 1))
  if [ -f "$LANGID_PLUGIN_DIR/$f" ]; then
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
  if [ -x "$LANGID_PLUGIN_DIR/$f" ]; then
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
if jq empty "$LANGID_PLUGIN_DIR/descriptor.json" 2>/dev/null; then
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
  val=$(jq -r ".$field" "$LANGID_PLUGIN_DIR/descriptor.json" 2>/dev/null)
  if [ -n "$val" ] && [ "$val" != "null" ]; then
    echo "  PASS: descriptor has $field"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: descriptor missing $field"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "--- Test 1.6: descriptor.json name is 'langid' ---"
TOTAL=$((TOTAL + 1))
name=$(jq -r '.name' "$LANGID_PLUGIN_DIR/descriptor.json" 2>/dev/null)
if [ "$name" = "langid" ]; then
  echo "  PASS: name is 'langid'"
  PASS=$((PASS + 1))
else
  echo "  FAIL: name is '$name', expected 'langid'"
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
output=$(bash "$LANGID_PLUGIN_DIR/installed.sh" 2>&1) || ec=$?
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
if [ "$LANGID_AVAILABLE" = "true" ]; then
  if [ "$installed_val" = "true" ]; then
    echo "  PASS: installed is true (langid is available)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: installed should be true (langid is available)"
    FAIL=$((FAIL + 1))
  fi
else
  if [ "$installed_val" = "false" ]; then
    echo "  PASS: installed is false (langid is not available)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: installed should be false (langid is not available)"
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
output=$(bash "$LANGID_PLUGIN_DIR/install.sh" 2>&1) || ec=$?
if [ "$LANGID_AVAILABLE" = "true" ]; then
  assert_exit_code "install.sh exits 0 (langid available)" "0" "$ec"
else
  TOTAL=$((TOTAL + 1))
  echo "  SKIP: install.sh skipped (langid not installed)"
  SKIP=$((SKIP + 1))
fi

# ============================================================
# Group 4: process command — English text detection
# ============================================================

echo ""
echo "=== Group 4: Language detection — English ==="

if [ "$LANGID_AVAILABLE" = "true" ]; then
  echo ""
  echo "--- Test 4.1: languageCode is 'en' for English text ---"
  test_text="The quick brown fox jumps over the lazy dog. This is a simple English sentence used for testing language identification."
  input_json=$(jq -n --arg dt "$test_text" --arg fp "/tmp/test.txt" '{filePath: $fp, documentText: $dt}')
  ec=0
  output=$(echo "$input_json" | bash "$LANGID_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  assert_exit_code "main.sh exits 0 with English text" "0" "$ec"

  lang_code=$(echo "$output" | jq -r '.languageCode' 2>/dev/null)
  assert_eq "languageCode is 'en'" "en" "$lang_code"

  echo ""
  echo "--- Test 4.2: languageConfidence is a negative float ---"
  TOTAL=$((TOTAL + 1))
  lang_conf=$(echo "$output" | jq -r '.languageConfidence' 2>/dev/null)
  # languageConfidence should be a negative number (log-probability)
  if echo "$lang_conf" | grep -qE '^-[0-9]'; then
    echo "  PASS: languageConfidence is negative ($lang_conf)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: languageConfidence should be negative, got '$lang_conf'"
    FAIL=$((FAIL + 1))
  fi
else
  echo ""
  echo "--- Tests 4.1-4.2: SKIP (langid not installed, 3 assertions) ---"
  for _ in 1 2 3; do
    TOTAL=$((TOTAL + 1))
    SKIP=$((SKIP + 1))
  done
fi

# ============================================================
# Group 5: process command — Non-English text detection
# ============================================================

echo ""
echo "=== Group 5: Language detection — German ==="

if [ "$LANGID_AVAILABLE" = "true" ]; then
  echo ""
  echo "--- Test 5.1: languageCode is 'de' for German text ---"
  german_text="Der schnelle braune Fuchs springt über den faulen Hund. Dies ist ein einfacher deutscher Satz zur Spracherkennung."
  input_json=$(jq -n --arg dt "$german_text" --arg fp "/tmp/test.txt" '{filePath: $fp, documentText: $dt}')
  ec=0
  output=$(echo "$input_json" | bash "$LANGID_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  assert_exit_code "main.sh exits 0 with German text" "0" "$ec"

  lang_code=$(echo "$output" | jq -r '.languageCode' 2>/dev/null)
  assert_eq "languageCode is 'de'" "de" "$lang_code"
else
  echo ""
  echo "--- Tests 5.1: SKIP (langid not installed) ---"
  for _ in 1 2; do
    TOTAL=$((TOTAL + 1))
    SKIP=$((SKIP + 1))
  done
fi

# ============================================================
# Group 6: Skip when no text available
# ============================================================

echo ""
echo "=== Group 6: Skip when no text ==="

echo ""
echo "--- Test 6.1: Exit 65 when no text fields present ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" '{filePath: $fp}')
ec=0
echo "$input_json" | bash "$LANGID_PLUGIN_DIR/main.sh" >/dev/null 2>&1 || ec=$?
assert_exit_code "Exit 65 when no text fields" "65" "$ec"

echo ""
echo "--- Test 6.2: Exit 65 when all text fields are empty ---"
input_json=$(jq -n --arg fp "/tmp/test.txt" '{filePath: $fp, documentText: "", ocrText: "", textContent: ""}')
ec=0
echo "$input_json" | bash "$LANGID_PLUGIN_DIR/main.sh" >/dev/null 2>&1 || ec=$?
assert_exit_code "Exit 65 when all text fields empty" "65" "$ec"

# ============================================================
# Group 7: Text field priority order
# ============================================================

echo ""
echo "=== Group 7: Text field priority ==="

if [ "$LANGID_AVAILABLE" = "true" ]; then
  echo ""
  echo "--- Test 7.1: documentText is preferred over ocrText ---"
  # documentText in German, ocrText in English — should detect German
  german_text="Der schnelle braune Fuchs springt über den faulen Hund. Dies ist ein einfacher deutscher Satz zur Spracherkennung."
  english_text="The quick brown fox jumps over the lazy dog. This is a simple English sentence."
  input_json=$(jq -n --arg dt "$german_text" --arg ot "$english_text" --arg fp "/tmp/test.txt" '{filePath: $fp, documentText: $dt, ocrText: $ot}')
  ec=0
  output=$(echo "$input_json" | bash "$LANGID_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  assert_exit_code "main.sh exits 0 with both fields" "0" "$ec"

  lang_code=$(echo "$output" | jq -r '.languageCode' 2>/dev/null)
  assert_eq "documentText preferred (detected 'de')" "de" "$lang_code"

  echo ""
  echo "--- Test 7.2: ocrText fallback when documentText empty ---"
  input_json=$(jq -n --arg ot "$english_text" --arg fp "/tmp/test.txt" '{filePath: $fp, documentText: "", ocrText: $ot}')
  ec=0
  output=$(echo "$input_json" | bash "$LANGID_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  assert_exit_code "main.sh exits 0 with ocrText fallback" "0" "$ec"

  lang_code=$(echo "$output" | jq -r '.languageCode' 2>/dev/null)
  assert_eq "ocrText fallback (detected 'en')" "en" "$lang_code"

  echo ""
  echo "--- Test 7.3: textContent fallback ---"
  input_json=$(jq -n --arg tc "$english_text" --arg fp "/tmp/test.txt" '{filePath: $fp, textContent: $tc}')
  ec=0
  output=$(echo "$input_json" | bash "$LANGID_PLUGIN_DIR/main.sh" 2>/dev/null) || ec=$?
  assert_exit_code "main.sh exits 0 with textContent" "0" "$ec"

  lang_code=$(echo "$output" | jq -r '.languageCode' 2>/dev/null)
  assert_eq "textContent (detected 'en')" "en" "$lang_code"
else
  echo ""
  echo "--- Tests 7.1-7.3: SKIP (langid not installed) ---"
  for _ in 1 2 3 4 5 6; do
    TOTAL=$((TOTAL + 1))
    SKIP=$((SKIP + 1))
  done
fi

# ============================================================
# Group 8: Valid JSON output
# ============================================================

echo ""
echo "=== Group 8: Valid JSON output ==="

if [ "$LANGID_AVAILABLE" = "true" ]; then
  echo ""
  echo "--- Test 8.1: stdout is valid JSON ---"
  test_text="The quick brown fox jumps over the lazy dog."
  input_json=$(jq -n --arg dt "$test_text" --arg fp "/tmp/test.txt" '{filePath: $fp, documentText: $dt}')
  output=$(echo "$input_json" | bash "$LANGID_PLUGIN_DIR/main.sh" 2>/dev/null) || true
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
  for field in languageCode languageConfidence; do
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

  echo ""
  echo "--- Test 8.3: languageCode is two-letter string ---"
  TOTAL=$((TOTAL + 1))
  lang_code=$(echo "$output" | jq -r '.languageCode' 2>/dev/null)
  if [[ "$lang_code" =~ ^[a-z]{2}$ ]]; then
    echo "  PASS: languageCode is valid ISO 639-1 format ($lang_code)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: languageCode is not two-letter format: '$lang_code'"
    FAIL=$((FAIL + 1))
  fi
else
  echo ""
  echo "--- Tests 8.1-8.3: SKIP (langid not installed) ---"
  for _ in 1 2 3 4; do
    TOTAL=$((TOTAL + 1))
    SKIP=$((SKIP + 1))
  done
fi

# ---- summary ----

echo ""
echo "==========================================="
echo "  FEATURE_0050 Results: $PASS passed, $FAIL failed, $SKIP skipped out of $TOTAL"
echo "==========================================="
echo ""

exit "$FAIL"
