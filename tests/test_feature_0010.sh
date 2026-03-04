#!/bin/bash
# Test suite for FEATURE_0010: ocrmypdf convert command
# Run from repository root: bash tests/test_feature_0010.sh
#
# Tests cover:
# - convert.sh exists and is executable
# - descriptor.json has convert command defined with required fields
# - convert.sh rejects missing filePath (no ocrmypdf required)
# - convert.sh errors clearly when ocrmypdf is not installed
# - convert.sh rejects unsupported MIME types (requires ocrmypdf)
# - Integration: successful conversion (requires ocrmypdf)

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins/ocrmypdf"

PASS=0
FAIL=0
TOTAL=0

# ---- Cleanup ----
cleanup() {
  if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
    chmod -R u+rw "$TEST_DIR" 2>/dev/null || true
    rm -rf "$TEST_DIR"
  fi
}
trap cleanup EXIT

TEST_DIR=$(mktemp -d)

# ---- Helpers ----

assert_eq() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
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
  local test_name="$1"
  local expected="$2"
  local actual="$3"
  TOTAL=$((TOTAL + 1))
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $test_name (exit code $actual)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Expected exit code: $expected"
    echo "    Actual exit code:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
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

assert_json_field_exists() {
  local test_name="$1"
  local json="$2"
  local field="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$json" | jq -e ".$field" >/dev/null 2>&1; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name (field '$field' not found)"
    FAIL=$((FAIL + 1))
  fi
}

echo "============================================"
echo "  FEATURE_0010 ocrmypdf Convert Command Test Suite"
echo "============================================"
echo ""

# =========================================
# Group 1: Plugin structure
# =========================================
echo "--- Group 1: Plugin structure ---"

# convert.sh exists
TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_DIR/convert.sh" ]; then
  echo "  PASS: convert.sh exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: convert.sh does not exist"
  FAIL=$((FAIL + 1))
fi

# convert.sh is executable
TOTAL=$((TOTAL + 1))
if [ -x "$PLUGIN_DIR/convert.sh" ]; then
  echo "  PASS: convert.sh is executable"
  PASS=$((PASS + 1))
else
  echo "  FAIL: convert.sh is NOT executable"
  FAIL=$((FAIL + 1))
fi

# convert.sh has #!/bin/bash shebang
TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_DIR/convert.sh" ]; then
  first_line=$(head -1 "$PLUGIN_DIR/convert.sh")
  if [ "$first_line" = "#!/bin/bash" ]; then
    echo "  PASS: convert.sh has #!/bin/bash shebang"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: convert.sh shebang is '$first_line'"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  SKIP: convert.sh missing — cannot check shebang"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: descriptor.json has convert command
# =========================================
echo ""
echo "--- Group 2: descriptor.json convert command ---"

desc=$(cat "$PLUGIN_DIR/descriptor.json" 2>/dev/null || echo '{}')

# convert command is declared
TOTAL=$((TOTAL + 1))
if echo "$desc" | jq -e '.commands.convert' >/dev/null 2>&1; then
  echo "  PASS: descriptor.json declares 'convert' command"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor.json missing 'convert' command"
  FAIL=$((FAIL + 1))
fi

# convert input: filePath
TOTAL=$((TOTAL + 1))
if echo "$desc" | jq -e '.commands.convert.input.filePath' >/dev/null 2>&1; then
  echo "  PASS: descriptor convert input declares 'filePath'"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor convert input missing 'filePath'"
  FAIL=$((FAIL + 1))
fi

# convert input: outputPath
TOTAL=$((TOTAL + 1))
if echo "$desc" | jq -e '.commands.convert.input.outputPath' >/dev/null 2>&1; then
  echo "  PASS: descriptor convert input declares 'outputPath'"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor convert input missing 'outputPath'"
  FAIL=$((FAIL + 1))
fi

# convert input: imageDpi
TOTAL=$((TOTAL + 1))
if echo "$desc" | jq -e '.commands.convert.input.imageDpi' >/dev/null 2>&1; then
  echo "  PASS: descriptor convert input declares 'imageDpi'"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor convert input missing 'imageDpi'"
  FAIL=$((FAIL + 1))
fi

# convert output: outputPdf
TOTAL=$((TOTAL + 1))
if echo "$desc" | jq -e '.commands.convert.output.outputPdf' >/dev/null 2>&1; then
  echo "  PASS: descriptor convert output declares 'outputPdf'"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor convert output missing 'outputPdf'"
  FAIL=$((FAIL + 1))
fi

# convert output: success
TOTAL=$((TOTAL + 1))
if echo "$desc" | jq -e '.commands.convert.output.success' >/dev/null 2>&1; then
  echo "  PASS: descriptor convert output declares 'success'"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor convert output missing 'success'"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 3: convert.sh error cases (no ocrmypdf required)
# =========================================
echo ""
echo "--- Group 3: convert.sh error cases (no ocrmypdf required) ---"

if [ ! -f "$PLUGIN_DIR/convert.sh" ]; then
  echo "  SKIP: convert.sh missing — skipping error case tests"
  FAIL=$((FAIL + 3))
else
  # Missing filePath: piping {} should exit 1 with "Missing required parameter"
  # This check happens BEFORE the ocrmypdf check, so it works regardless of ocrmypdf
  combined=$(echo '{}' | "$PLUGIN_DIR/convert.sh" 2>&1)
  exit_code=$?
  assert_exit_code "missing filePath: exits 1" "1" "$exit_code"
  assert_contains "missing filePath: output contains 'Missing required parameter'" \
    "Missing required parameter" "$combined"

  # Malformed JSON: should exit 1
  combined=$(echo 'not json' | "$PLUGIN_DIR/convert.sh" 2>&1)
  exit_code=$?
  assert_exit_code "malformed JSON: exits 1" "1" "$exit_code"
fi

# =========================================
# Group 4: ocrmypdf not installed test
# =========================================
echo ""
echo "--- Group 4: ocrmypdf not installed ---"

if [ ! -f "$PLUGIN_DIR/convert.sh" ]; then
  echo "  SKIP: convert.sh missing — skipping not-installed test"
  FAIL=$((FAIL + 2))
elif ! command -v ocrmypdf >/dev/null 2>&1; then
  # ocrmypdf is not installed — test that convert.sh reports this clearly
  combined=$(echo '{"filePath":"/tmp/fake.jpg"}' | "$PLUGIN_DIR/convert.sh" 2>&1)
  exit_code=$?
  assert_exit_code "ocrmypdf not installed: exits 1" "1" "$exit_code"
  assert_contains "ocrmypdf not installed: output mentions 'not installed'" \
    "not installed" "$combined"
else
  echo "  SKIP: ocrmypdf is installed — not-installed tests not applicable"
  TOTAL=$((TOTAL + 2))
  PASS=$((PASS + 2))
fi

# =========================================
# Group 5: unsupported MIME type (requires ocrmypdf)
# =========================================
echo ""
echo "--- Group 5: unsupported MIME type (skipped if ocrmypdf not installed) ---"

if [ ! -f "$PLUGIN_DIR/convert.sh" ]; then
  echo "  SKIP: convert.sh missing — skipping MIME type tests"
elif ! command -v ocrmypdf >/dev/null 2>&1; then
  echo "  SKIP: ocrmypdf not installed — MIME type check happens after ocrmypdf check"
else
  txt_file="$TEST_DIR/test.txt"
  echo "plain text content" > "$txt_file"

  combined=$(echo "{\"filePath\":\"$txt_file\"}" | "$PLUGIN_DIR/convert.sh" 2>&1)
  exit_code=$?
  assert_exit_code "unsupported MIME (text): exits 1" "1" "$exit_code"
  assert_contains "unsupported MIME (text): output mentions 'Unsupported file type'" \
    "Unsupported file type" "$combined"
fi

# =========================================
# Group 6: integration tests (requires ocrmypdf)
# =========================================
echo ""
echo "--- Group 6: integration tests (skipped if ocrmypdf not installed) ---"

if [ ! -f "$PLUGIN_DIR/convert.sh" ]; then
  echo "  SKIP: convert.sh missing — skipping integration tests"
elif ! command -v ocrmypdf >/dev/null 2>&1; then
  echo "  SKIP: ocrmypdf not installed — skipping integration tests"
else
  # Find a real image for testing
  test_img=""
  for candidate in "$REPO_ROOT/tests/docs/README-Screenshot-JPG.jpg" \
                   "$REPO_ROOT/tests/docs/README-Screenshot-PNG.png"; do
    if [ -f "$candidate" ]; then
      test_img="$candidate"
      break
    fi
  done

  if [ -n "$test_img" ]; then
    out_pdf="$TEST_DIR/output.pdf"
    output=$(echo "{\"filePath\":\"$test_img\",\"outputPath\":\"$out_pdf\"}" \
      | "$PLUGIN_DIR/convert.sh" 2>/dev/null)
    exit_code=$?
    assert_exit_code "convert image to PDF: exits 0" "0" "$exit_code"

    TOTAL=$((TOTAL + 1))
    if echo "$output" | jq empty 2>/dev/null; then
      echo "  PASS: convert output is valid JSON"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: convert output is NOT valid JSON"
      FAIL=$((FAIL + 1))
    fi

    success_val=$(echo "$output" | jq -r '.success' 2>/dev/null)
    assert_eq "convert output has success: true" "true" "$success_val"

    TOTAL=$((TOTAL + 1))
    output_pdf=$(echo "$output" | jq -r '.outputPdf' 2>/dev/null)
    if [ -f "$output_pdf" ]; then
      echo "  PASS: outputPdf file exists at $output_pdf"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: outputPdf file does not exist (got: $output_pdf)"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "  SKIP: no test image available — skipping integration tests"
  fi
fi

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
