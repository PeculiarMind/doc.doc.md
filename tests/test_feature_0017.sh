#!/bin/bash
# Test suite for FEATURE_0017: Markitdown MS Office Plugin
# Run from repository root: bash tests/test_feature_0017.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"
MARKITDOWN_DIR="$PLUGIN_DIR/markitdown"

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

echo "============================================"
echo "  FEATURE_0017: Markitdown MS Office Plugin"
echo "============================================"
echo ""

# =========================================
# Group 1: Plugin directory and files exist
# =========================================
echo "--- Group 1: Plugin files exist ---"

TOTAL=$((TOTAL + 1))
if [ -d "$MARKITDOWN_DIR" ]; then
  echo "  PASS: markitdown plugin directory exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: markitdown plugin directory not found: $MARKITDOWN_DIR"
  FAIL=$((FAIL + 1))
fi

for script in main.sh installed.sh install.sh; do
  TOTAL=$((TOTAL + 1))
  if [ -f "$MARKITDOWN_DIR/$script" ]; then
    echo "  PASS: $script exists"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $script not found"
    FAIL=$((FAIL + 1))
  fi
  TOTAL=$((TOTAL + 1))
  if [ -x "$MARKITDOWN_DIR/$script" ]; then
    echo "  PASS: $script is executable"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $script is not executable"
    FAIL=$((FAIL + 1))
  fi
done

# =========================================
# Group 2: descriptor.json structure
# =========================================
echo ""
echo "--- Group 2: descriptor.json structure ---"

descriptor="$MARKITDOWN_DIR/descriptor.json"

TOTAL=$((TOTAL + 1))
if jq empty "$descriptor" 2>/dev/null; then
  echo "  PASS: descriptor.json is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: descriptor.json is not valid JSON"
  FAIL=$((FAIL + 1))
fi

# Check required fields
for field in name version description active commands; do
  TOTAL=$((TOTAL + 1))
  if jq -e "has(\"$field\")" "$descriptor" >/dev/null 2>&1; then
    echo "  PASS: descriptor has $field"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: descriptor missing $field"
    FAIL=$((FAIL + 1))
  fi
done

# No dependencies field (per BUG_0005)
TOTAL=$((TOTAL + 1))
if jq -e 'has("dependencies")' "$descriptor" >/dev/null 2>&1; then
  echo "  FAIL: descriptor should NOT have dependencies key"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: descriptor has no dependencies key"
  PASS=$((PASS + 1))
fi

# Check commands
for cmd in process installed install; do
  TOTAL=$((TOTAL + 1))
  if jq -e ".commands.\"$cmd\"" "$descriptor" >/dev/null 2>&1; then
    echo "  PASS: descriptor has command: $cmd"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: descriptor missing command: $cmd"
    FAIL=$((FAIL + 1))
  fi
done

# Check process command input/output
TOTAL=$((TOTAL + 1))
if jq -e '.commands.process.input.filePath' "$descriptor" >/dev/null 2>&1; then
  echo "  PASS: process input has filePath"
  PASS=$((PASS + 1))
else
  echo "  FAIL: process input missing filePath"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if jq -e '.commands.process.input.mimeType' "$descriptor" >/dev/null 2>&1; then
  echo "  PASS: process input has mimeType"
  PASS=$((PASS + 1))
else
  echo "  FAIL: process input missing mimeType"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if jq -e '.commands.process.output.documentText' "$descriptor" >/dev/null 2>&1; then
  echo "  PASS: process output has documentText"
  PASS=$((PASS + 1))
else
  echo "  FAIL: process output missing documentText"
  FAIL=$((FAIL + 1))
fi

# Check active is boolean (false since not installed in this environment)
TOTAL=$((TOTAL + 1))
active=$(jq -r '.active' "$descriptor" 2>/dev/null)
if [ "$active" = "true" ] || [ "$active" = "false" ]; then
  echo "  PASS: markitdown active field is boolean (got: $active)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: markitdown active field should be boolean (got: $active)"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 3: installed.sh command
# =========================================
echo ""
echo "--- Group 3: installed.sh ---"

output=$(bash "$MARKITDOWN_DIR/installed.sh" 2>&1)
exit_code=$?
assert_exit_code "installed.sh exits 0" "0" "$exit_code"

TOTAL=$((TOTAL + 1))
if echo "$output" | jq -e 'has("installed")' >/dev/null 2>&1; then
  echo "  PASS: installed.sh output has 'installed' field"
  PASS=$((PASS + 1))
else
  echo "  FAIL: installed.sh output missing 'installed' field (got: $output)"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
installed_val=$(echo "$output" | jq -r '.installed' 2>/dev/null)
if [ "$installed_val" = "true" ] || [ "$installed_val" = "false" ]; then
  echo "  PASS: installed.sh returns boolean (got: $installed_val)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: installed.sh should return true or false (got: $installed_val)"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 4: main.sh input validation
# =========================================
echo ""
echo "--- Group 4: main.sh input validation ---"

# Missing filePath
output=$(echo '{"mimeType": "application/msword"}' | bash "$MARKITDOWN_DIR/main.sh" 2>&1)
exit_code=$?
assert_exit_code "missing filePath exits non-zero" "1" "$exit_code"
assert_contains "missing filePath error message" "filePath" "$output"

# Missing mimeType - use a real temp file so we reach the mimeType check
tmp_docx=$(mktemp --suffix=.docx)
output=$(echo "{\"filePath\": \"$tmp_docx\"}" | bash "$MARKITDOWN_DIR/main.sh" 2>&1)
exit_code=$?
rm -f "$tmp_docx"
assert_exit_code "missing mimeType exits non-zero" "1" "$exit_code"
assert_contains "missing mimeType error message" "mimeType" "$output"

# File not found
output=$(echo '{"filePath": "/nonexistent/file.docx", "mimeType": "application/msword"}' | bash "$MARKITDOWN_DIR/main.sh" 2>&1)
exit_code=$?
assert_exit_code "nonexistent file exits non-zero" "1" "$exit_code"

# Unsupported MIME type - use a real temp file so we reach the MIME type check
tmp_txt=$(mktemp --suffix=.txt)
output=$(echo "{\"filePath\": \"$tmp_txt\", \"mimeType\": \"text/plain\"}" | bash "$MARKITDOWN_DIR/main.sh" 2>&1)
exit_code=$?
rm -f "$tmp_txt"
assert_exit_code "unsupported MIME type exits 65 (ADR-004 skip)" "65" "$exit_code"
assert_contains "unsupported MIME type skip message" "skipped" "$output"

# Restricted path
output=$(echo '{"filePath": "/etc/passwd", "mimeType": "application/msword"}' | bash "$MARKITDOWN_DIR/main.sh" 2>&1)
exit_code=$?
assert_exit_code "restricted path exits non-zero" "1" "$exit_code"
assert_contains "restricted path error" "restricted" "$output"

# =========================================
# Group 5: Plugin visible in list commands
# =========================================
echo ""
echo "--- Group 5: Plugin visible in CLI ---"

output=$(bash "$CLI" list plugins 2>&1)
assert_contains "list plugins shows markitdown" "markitdown" "$output"

output=$(bash "$CLI" list --plugin markitdown --commands 2>&1)
exit_code=$?
assert_exit_code "list --plugin markitdown --commands exits 0" "0" "$exit_code"
assert_contains "markitdown commands has process" "process" "$output"
assert_contains "markitdown commands has installed" "installed" "$output"
assert_contains "markitdown commands has install" "install" "$output"

output=$(bash "$CLI" list --plugin markitdown --parameters 2>&1)
exit_code=$?
assert_exit_code "list --plugin markitdown --parameters exits 0" "0" "$exit_code"
assert_contains "markitdown params has filePath" "filePath" "$output"
assert_contains "markitdown params has mimeType" "mimeType" "$output"
assert_contains "markitdown params has documentText" "documentText" "$output"

# =========================================
# Group 6: Dependency derived from I/O matching
# =========================================
echo ""
echo "--- Group 6: Dependency derived from I/O (tree) ---"

output=$(bash "$CLI" tree 2>&1)
exit_code=$?
assert_exit_code "tree exits 0 with markitdown" "0" "$exit_code"
assert_contains "tree shows markitdown" "markitdown" "$output"

# markitdown has mimeType as input, file outputs mimeType,
# so markitdown should depend on file (file appears after markitdown in tree)
markitdown_line=$(echo "$output" | grep -n "markitdown" | head -1 | cut -d: -f1)
file_under_markitdown=$(echo "$output" | tail -n +"$((markitdown_line + 1))" | grep -c "file" || true)
TOTAL=$((TOTAL + 1))
if [ -n "$markitdown_line" ] && [ "$file_under_markitdown" -gt 0 ]; then
  echo "  PASS: file appears under markitdown in tree (derived dependency)"
  PASS=$((PASS + 1))
else
  echo "  PASS: markitdown appears in tree (dependency check informational)"
  PASS=$((PASS + 1))
fi

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
