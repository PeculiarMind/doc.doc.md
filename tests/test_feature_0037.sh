#!/bin/bash
# Test suite for FEATURE_0037: Plugin Install Validation and Error Guidance
# Run from repository root: bash tests/test_feature_0037.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"
PLUGIN_MGMT="$REPO_ROOT/doc.doc.md/components/plugin_management.sh"

PASS=0
FAIL=0
TOTAL=0

INPUT_DIR=""
OUTPUT_DIR=""
BACKUP_DIR=""

cleanup() {
  [ -n "$INPUT_DIR" ] && [ -d "$INPUT_DIR" ] && rm -rf "$INPUT_DIR"
  [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ] && rm -rf "$OUTPUT_DIR"
  # Restore any modified descriptors
  if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    for bak in "$BACKUP_DIR"/*.json; do
      [ -f "$bak" ] || continue
      local pname
      pname=$(basename "$bak" .json)
      cp "$bak" "$PLUGIN_DIR/$pname/descriptor.json" 2>/dev/null || true
    done
    rm -rf "$BACKUP_DIR"
  fi
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
  local test_name="$1" unwanted="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$unwanted"; then
    echo "  FAIL: $test_name"
    echo "    Should not contain: $unwanted"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

echo "============================================"
echo "  FEATURE_0037: Plugin Install Validation"
echo "  and Error Guidance"
echo "============================================"
echo ""

INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
BACKUP_DIR=$(mktemp -d)

# Create test input files
echo "Hello World" > "$INPUT_DIR/test.txt"

# Backup descriptors for plugins we'll modify
for p in "$PLUGIN_DIR"/*/; do
  [ -d "$p" ] || continue
  pname=$(basename "$p")
  [ -f "$p/descriptor.json" ] && cp "$p/descriptor.json" "$BACKUP_DIR/$pname.json"
done

# =========================================
# Group 1: install --plugin with unknown plugin name
# =========================================
echo "--- Group 1: install --plugin unknown plugin name ---"

output=""
exit_code=0
output=$(bash "$CLI" install --plugin nonexistent_plugin_xyz 2>&1) || exit_code=$?

assert_exit_code "install unknown plugin exits non-zero" "1" "$exit_code"
assert_contains "install unknown plugin lists available plugins" "Available plugins" "$output"

# =========================================
# Group 2: install --plugin already installed
# =========================================
echo ""
echo "--- Group 2: install --plugin already installed ---"

# stat plugin should be installed (it's a built-in shell plugin)
output=""
exit_code=0
output=$(bash "$CLI" install --plugin stat 2>&1) || exit_code=$?

assert_exit_code "install already installed exits 0" "0" "$exit_code"
assert_contains "install already installed shows message" "already installed" "$output"

# =========================================
# Group 3: install --plugin failure advice
# =========================================
echo ""
echo "--- Group 3: install --plugin failure advice ---"

# Create a temporary test plugin that fails to install
TEST_PLUGIN_DIR="$PLUGIN_DIR/_test_fail_install"
mkdir -p "$TEST_PLUGIN_DIR"
cat > "$TEST_PLUGIN_DIR/descriptor.json" <<'JSON'
{
  "name": "_test_fail_install",
  "version": "0.0.1",
  "description": "Test plugin for install failure",
  "active": false,
  "commands": {
    "process": { "command": "main.sh" }
  }
}
JSON
cat > "$TEST_PLUGIN_DIR/installed.sh" <<'SCRIPT'
#!/bin/bash
echo '{"installed": false}'
SCRIPT
chmod +x "$TEST_PLUGIN_DIR/installed.sh"
cat > "$TEST_PLUGIN_DIR/install.sh" <<'SCRIPT'
#!/bin/bash
echo "Installation dependency not found" >&2
exit 1
SCRIPT
chmod +x "$TEST_PLUGIN_DIR/install.sh"

output=""
exit_code=0
output=$(bash "$CLI" install --plugin _test_fail_install 2>&1) || exit_code=$?

assert_exit_code "install failure exits non-zero" "1" "$exit_code"
assert_contains "install failure shows sudo tip" "sudo" "$output"

# Clean up test plugin
rm -rf "$TEST_PLUGIN_DIR"

# =========================================
# Group 4: process non-interactive with uninstalled plugin
# =========================================
echo ""
echo "--- Group 4: process non-interactive with uninstalled plugin ---"

# Create test plugin that reports as not installed
TEST_PLUGIN_DIR2="$PLUGIN_DIR/_test_not_installed"
mkdir -p "$TEST_PLUGIN_DIR2"
cat > "$TEST_PLUGIN_DIR2/descriptor.json" <<'JSON'
{
  "name": "_test_not_installed",
  "version": "0.0.1",
  "description": "Test plugin not installed",
  "active": true,
  "commands": {
    "process": { "command": "main.sh" }
  }
}
JSON
cat > "$TEST_PLUGIN_DIR2/installed.sh" <<'SCRIPT'
#!/bin/bash
echo '{"installed": false}'
SCRIPT
chmod +x "$TEST_PLUGIN_DIR2/installed.sh"
cat > "$TEST_PLUGIN_DIR2/main.sh" <<'SCRIPT'
#!/bin/bash
head -c 1048576 > /dev/null
echo '{"test": true}'
SCRIPT
chmod +x "$TEST_PLUGIN_DIR2/main.sh"

output=""
exit_code=0
# Non-interactive: pipe stdin from /dev/null to ensure non-TTY
output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" --no-progress 2>&1 </dev/null) || exit_code=$?

assert_exit_code "process exits non-zero with uninstalled plugin (non-interactive)" "1" "$exit_code"
assert_contains "process error mentions uninstalled plugin" "_test_not_installed" "$output"

# Clean up test plugin
rm -rf "$TEST_PLUGIN_DIR2"

# =========================================
# Group 5: process succeeds when all plugins installed
# =========================================
echo ""
echo "--- Group 5: process succeeds when all plugins installed ---"

output=""
exit_code=0
output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" --no-progress 2>&1) || exit_code=$?

assert_exit_code "process exits 0 when all plugins installed" "0" "$exit_code"

# =========================================
# Group 6: setup exits non-zero with advice on install failure
# =========================================
echo ""
echo "--- Group 6: setup with install failure advice ---"

# Create a test plugin that fails to install
TEST_PLUGIN_DIR3="$PLUGIN_DIR/_test_setup_fail"
mkdir -p "$TEST_PLUGIN_DIR3"
cat > "$TEST_PLUGIN_DIR3/descriptor.json" <<'JSON'
{
  "name": "_test_setup_fail",
  "version": "0.0.1",
  "description": "Test plugin for setup failure",
  "active": true,
  "commands": {
    "process": { "command": "main.sh" }
  }
}
JSON
cat > "$TEST_PLUGIN_DIR3/installed.sh" <<'SCRIPT'
#!/bin/bash
echo '{"installed": false}'
SCRIPT
chmod +x "$TEST_PLUGIN_DIR3/installed.sh"
cat > "$TEST_PLUGIN_DIR3/install.sh" <<'SCRIPT'
#!/bin/bash
echo "Cannot find dependency XYZ" >&2
exit 1
SCRIPT
chmod +x "$TEST_PLUGIN_DIR3/install.sh"

output=""
exit_code=0
output=$(bash "$CLI" setup --yes 2>&1) || exit_code=$?

# Setup with --yes should attempt to install and report failure
assert_contains "setup failure mentions recovery advice" "sudo" "$output"

# Clean up test plugin
rm -rf "$TEST_PLUGIN_DIR3"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed (total: $TOTAL)"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
