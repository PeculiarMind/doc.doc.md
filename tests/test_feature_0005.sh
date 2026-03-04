#!/bin/bash
# Test suite for FEATURE_0005: ocrmypdf plugin
# Run from repository root: bash tests/test_feature_0005.sh
#
# Tests cover plugin structure, error handling, and (when tools are available) OCR processing.

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

assert_json_field() {
  local test_name="$1"
  local json="$2"
  local field="$3"
  local expected="$4"
  local actual
  actual=$(echo "$json" | jq -r ".$field")
  assert_eq "$test_name" "$expected" "$actual"
}

assert_json_field_type() {
  local test_name="$1"
  local json="$2"
  local field="$3"
  local expected_type="$4"
  local actual_type
  actual_type=$(echo "$json" | jq -r ".$field | type")
  assert_eq "$test_name" "$expected_type" "$actual_type"
}

echo "============================================"
echo "  FEATURE_0005 ocrmypdf Plugin Test Suite"
echo "============================================"
echo ""

# =========================================
# Plugin structure
# =========================================
echo "--- Plugin structure ---"

# Scripts exist
for script in main.sh install.sh installed.sh; do
  TOTAL=$((TOTAL + 1))
  if [ -f "$PLUGIN_DIR/$script" ]; then
    echo "  PASS: $script exists"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $script does not exist"
    FAIL=$((FAIL + 1))
  fi
done

# Scripts are executable
for script in main.sh install.sh installed.sh; do
  TOTAL=$((TOTAL + 1))
  if [ -x "$PLUGIN_DIR/$script" ]; then
    echo "  PASS: $script is executable"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $script is NOT executable"
    FAIL=$((FAIL + 1))
  fi
done

# Scripts have #!/bin/bash shebang
for script in main.sh install.sh installed.sh; do
  TOTAL=$((TOTAL + 1))
  first_line=$(head -1 "$PLUGIN_DIR/$script")
  if [ "$first_line" = "#!/bin/bash" ]; then
    echo "  PASS: $script has #!/bin/bash shebang"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $script shebang is '$first_line'"
    FAIL=$((FAIL + 1))
  fi
done

# descriptor.json exists and is valid JSON
echo ""
echo "--- descriptor.json ---"

TOTAL=$((TOTAL + 1))
if [ -f "$PLUGIN_DIR/descriptor.json" ]; then
  echo "  PASS: descriptor.json exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor.json does not exist"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if jq empty "$PLUGIN_DIR/descriptor.json" 2>/dev/null; then
  echo "  PASS: descriptor.json is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor.json is NOT valid JSON"
  FAIL=$((FAIL + 1))
fi

# Descriptor declares required fields
desc=$(cat "$PLUGIN_DIR/descriptor.json")

# process command input fields
for field in filePath pluginStorage; do
  TOTAL=$((TOTAL + 1))
  if echo "$desc" | jq -e ".commands.process.input.$field" >/dev/null 2>&1; then
    echo "  PASS: descriptor declares process input '$field'"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: descriptor missing process input '$field'"
    FAIL=$((FAIL + 1))
  fi
done

# process command output fields
for field in ocrText pageCount wasCached outputPdf; do
  TOTAL=$((TOTAL + 1))
  if echo "$desc" | jq -e ".commands.process.output.$field" >/dev/null 2>&1; then
    echo "  PASS: descriptor declares process output '$field'"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: descriptor missing process output '$field'"
    FAIL=$((FAIL + 1))
  fi
done

# installed and install commands declared
for cmd in installed install; do
  TOTAL=$((TOTAL + 1))
  if echo "$desc" | jq -e ".commands.$cmd" >/dev/null 2>&1; then
    echo "  PASS: descriptor declares '$cmd' command"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: descriptor missing '$cmd' command"
    FAIL=$((FAIL + 1))
  fi
done

# =========================================
# installed.sh
# =========================================
echo ""
echo "--- installed.sh ---"

output=$("$PLUGIN_DIR/installed.sh")
exit_code=$?
assert_exit_code "installed.sh exits with 0" "0" "$exit_code"

# Output is valid JSON
TOTAL=$((TOTAL + 1))
if echo "$output" | jq empty 2>/dev/null; then
  echo "  PASS: installed.sh output is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: installed.sh output is NOT valid JSON"
  FAIL=$((FAIL + 1))
fi

# Output has 'installed' boolean field
assert_json_field_type "installed.sh 'installed' is boolean" "$output" "installed" "boolean"

# =========================================
# install.sh
# =========================================
echo ""
echo "--- install.sh (structure check only) ---"

# Check script syntax without running it
TOTAL=$((TOTAL + 1))
if bash -n "$PLUGIN_DIR/install.sh" 2>/dev/null; then
  echo "  PASS: install.sh has valid bash syntax"
  PASS=$((PASS + 1))
else
  echo "  FAIL: install.sh has invalid bash syntax"
  FAIL=$((FAIL + 1))
fi

# =========================================
# main.sh error cases (do not require ocrmypdf)
# =========================================
echo ""
echo "--- main.sh error cases ---"

# Missing filePath
output=$(echo '{}' | "$PLUGIN_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "missing filePath exits with 1" "1" "$exit_code"

# Missing pluginStorage
output=$(echo "{\"filePath\":\"/tmp/test.pdf\"}" | "$PLUGIN_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "missing pluginStorage exits with 1" "1" "$exit_code"

# Malformed JSON
output=$(echo 'not json' | "$PLUGIN_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "malformed JSON exits with 1" "1" "$exit_code"

# Non-existent file
output=$(echo '{"filePath":"/nonexistent/file.pdf","pluginStorage":"/tmp/storage"}' \
  | "$PLUGIN_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "non-existent file exits with 1" "1" "$exit_code"

# Non-PDF file
non_pdf="$TEST_DIR/test.txt"
echo "not a pdf" > "$non_pdf"
output=$(echo "{\"filePath\":\"$non_pdf\",\"pluginStorage\":\"$TEST_DIR/storage\"}" \
  | "$PLUGIN_DIR/main.sh" 2>/dev/null)
exit_code=$?
assert_exit_code "non-PDF file exits with 1" "1" "$exit_code"

# Error messages go to stderr, not stdout
error_stdout=$(echo '{}' | "$PLUGIN_DIR/main.sh" 2>/dev/null)
assert_eq "error output not in stdout" "" "$error_stdout"

error_stderr=$(echo '{}' | "$PLUGIN_DIR/main.sh" 2>&1 >/dev/null)
assert_contains "error message in stderr" "Error" "$error_stderr"

# =========================================
# main.sh with ocrmypdf (only if tools available)
# =========================================
echo ""
echo "--- main.sh with ocrmypdf (skipped if tools not installed) ---"

if command -v ocrmypdf >/dev/null 2>&1 && command -v pdftotext >/dev/null 2>&1; then
  # Find a real PDF for testing (use existing test file if available)
  test_pdf=""
  for candidate in /usr/share/doc/*/copyright \
                   "$REPO_ROOT/tests/fixtures/"*.pdf \
                   /tmp/test_ocr_input.pdf; do
    if [ -f "$candidate" ] && file --mime-type -b "$candidate" 2>/dev/null | grep -q "application/pdf"; then
      test_pdf="$candidate"
      break
    fi
  done

  if [ -n "$test_pdf" ]; then
    storage_dir="$TEST_DIR/ocr_storage"

    # First run: fresh OCR
    output=$(echo "{\"filePath\":\"$test_pdf\",\"pluginStorage\":\"$storage_dir\"}" \
      | "$PLUGIN_DIR/main.sh" 2>/dev/null)
    exit_code=$?
    assert_exit_code "main.sh exits with 0 on success" "0" "$exit_code"

    # Validate output is valid JSON
    TOTAL=$((TOTAL + 1))
    if echo "$output" | jq empty 2>/dev/null; then
      echo "  PASS: main.sh output is valid JSON"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: main.sh output is NOT valid JSON"
      FAIL=$((FAIL + 1))
    fi

    assert_json_field_type "ocrText is string" "$output" "ocrText" "string"
    assert_json_field_type "pageCount is number" "$output" "pageCount" "number"
    assert_json_field_type "wasCached is boolean" "$output" "wasCached" "boolean"
    assert_json_field_type "outputPdf is string" "$output" "outputPdf" "string"
    assert_json_field "wasCached is false on first run" "$output" "wasCached" "false"

    output_pdf=$(echo "$output" | jq -r '.outputPdf')
    TOTAL=$((TOTAL + 1))
    if [ -f "$output_pdf" ]; then
      echo "  PASS: outputPdf file exists at $output_pdf"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: outputPdf file does not exist: $output_pdf"
      FAIL=$((FAIL + 1))
    fi

    # Verify output is inside pluginStorage
    TOTAL=$((TOTAL + 1))
    resolved_storage=$(readlink -f "$storage_dir")
    if [[ "$output_pdf" == "$resolved_storage"/* ]]; then
      echo "  PASS: outputPdf is inside pluginStorage"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: outputPdf is outside pluginStorage: $output_pdf"
      FAIL=$((FAIL + 1))
    fi

    # Second run: should use cache
    output2=$(echo "{\"filePath\":\"$test_pdf\",\"pluginStorage\":\"$storage_dir\"}" \
      | "$PLUGIN_DIR/main.sh" 2>/dev/null)
    exit_code=$?
    assert_exit_code "main.sh exits with 0 on cache hit" "0" "$exit_code"
    assert_json_field "wasCached is true on second run" "$output2" "wasCached" "true"
    assert_json_field "outputPdf is same on cache hit" "$output2" "outputPdf" "$output_pdf"
  else
    echo "  SKIP: no test PDF available — skipping OCR integration tests"
  fi
else
  echo "  SKIP: ocrmypdf/pdftotext not installed — skipping OCR integration tests"
fi

# =========================================
# list command shows ocrmypdf plugin commands
# =========================================
echo ""
echo "--- list command integration ---"

DOC_DOC_SH="$REPO_ROOT/doc.doc.sh"
output=$("$DOC_DOC_SH" list --plugin ocrmypdf --commands 2>/dev/null)
exit_code=$?
assert_exit_code "list --plugin ocrmypdf --commands exits with 0" "0" "$exit_code"
assert_contains "lists 'process' command" "process" "$output"
assert_contains "lists 'install' command" "install" "$output"
assert_contains "lists 'installed' command" "installed" "$output"

# Summary
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
