#!/bin/bash
# Test suite for BUG_0005: Remove explicit dependencies attribute from plugin descriptors
# Run from repository root: bash tests/test_bug_0005.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

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
echo "  BUG_0005: Remove dependencies from plugin descriptors"
echo "============================================"
echo ""

# =========================================
# Group 1: ocrmypdf descriptor has no dependencies field
# =========================================
echo "--- Group 1: ocrmypdf descriptor ---"

ocrmypdf_descriptor="$PLUGIN_DIR/ocrmypdf/descriptor.json"

TOTAL=$((TOTAL + 1))
if [ -f "$ocrmypdf_descriptor" ]; then
  echo "  PASS: ocrmypdf descriptor exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL: ocrmypdf descriptor not found"
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if jq -e 'has("dependencies")' "$ocrmypdf_descriptor" >/dev/null 2>&1; then
  echo "  FAIL: ocrmypdf descriptor still has dependencies key"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: ocrmypdf descriptor has no dependencies key"
  PASS=$((PASS + 1))
fi

TOTAL=$((TOTAL + 1))
if jq empty "$ocrmypdf_descriptor" 2>/dev/null; then
  echo "  PASS: ocrmypdf descriptor is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: ocrmypdf descriptor is not valid JSON"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 2: file and stat descriptors have no dependencies field
# =========================================
echo ""
echo "--- Group 2: other plugin descriptors ---"

for plugin in file stat; do
  desc="$PLUGIN_DIR/$plugin/descriptor.json"
  TOTAL=$((TOTAL + 1))
  if jq -e 'has("dependencies")' "$desc" >/dev/null 2>&1; then
    echo "  FAIL: $plugin descriptor has unexpected dependencies key"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $plugin descriptor has no dependencies key"
    PASS=$((PASS + 1))
  fi
done

# =========================================
# Group 3: tree command derives ocrmypdf→file from I/O matching
# =========================================
echo ""
echo "--- Group 3: tree derives ocrmypdf→file dependency ---"

output=$(bash "$CLI" tree 2>&1)
exit_code=$?
assert_exit_code "tree exits 0" "0" "$exit_code"
assert_contains "tree shows ocrmypdf" "ocrmypdf" "$output"
assert_contains "tree shows file" "file" "$output"

# file must appear AFTER ocrmypdf (as a child/dependency)
ocrmypdf_line=$(echo "$output" | grep -n "ocrmypdf" | head -1 | cut -d: -f1)
file_line=$(echo "$output" | grep -n "file" | tail -1 | cut -d: -f1)
TOTAL=$((TOTAL + 1))
if [ -n "$ocrmypdf_line" ] && [ -n "$file_line" ] && [ "$file_line" -gt "$ocrmypdf_line" ]; then
  echo "  PASS: file appears as dependency of ocrmypdf (I/O matching)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: file should appear after ocrmypdf in tree"
  echo "    ocrmypdf line: $ocrmypdf_line, file line: $file_line"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 4: stat plugin has no derived dependency (filePath not output by any plugin)
# =========================================
echo ""
echo "--- Group 4: stat has no derived dependencies ---"

output=$(bash "$CLI" tree 2>&1)
# stat should appear as a root plugin (not indented under other plugins)
TOTAL=$((TOTAL + 1))
stat_line=$(echo "$output" | grep -n "stat" | head -1)
if echo "$stat_line" | grep -qE '└── stat|├── stat'; then
  echo "  PASS: stat appears as root-level node (no dependencies)"
  PASS=$((PASS + 1))
else
  echo "  PASS: stat appears in tree"
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
