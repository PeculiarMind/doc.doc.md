#!/bin/bash
# Test suite for BUG_0009: render_template_json Multiline Value Injection
# Run from repository root: bash tests/test_bug_0009.sh
#
# render_template_json() used jq 'to_entries[] | "\(.key)=\(.value)"' to
# iterate JSON fields.  When a value contains newlines the read loop treats
# each line as a separate key=value pair.  This:
#   1. Truncates multiline values at the first newline  (DEBTR_003)
#   2. Allows document content to override template variables (injection)
#
# The fix iterates over keys with jq 'keys[]' and extracts each value
# individually with jq --arg k "$key" '.[$k] // empty'.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
TEMPLATES_SH="$REPO_ROOT/doc.doc.md/components/templates.sh"

PASS=0
FAIL=0
TOTAL=0

INPUT_DIR=""
OUTPUT_DIR=""
TEMPLATE_FILE=""

cleanup() {
  [ -n "${INPUT_DIR:-}" ]    && [ -d "$INPUT_DIR" ]    && rm -rf "$INPUT_DIR"
  [ -n "${OUTPUT_DIR:-}" ]   && [ -d "$OUTPUT_DIR" ]   && rm -rf "$OUTPUT_DIR"
  [ -n "${TEMPLATE_FILE:-}" ] && [ -f "$TEMPLATE_FILE" ] && rm -f "$TEMPLATE_FILE"
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
echo "  BUG_0009: render_template_json Multiline"
echo "           Value Injection"
echo "============================================"
echo ""

# =========================================
# Group 1: Source code uses the safe jq pattern
# The fixed code must iterate keys with  jq -r 'keys[]'
# and must NOT use the flawed  jq -r 'to_entries[]' pattern
# inside render_template_json.
# =========================================
echo "--- Group 1: Source code uses safe jq pattern ---"

source_code=$(cat "$CLI")

# Extract only the render_template_json function body for targeted checks
# (function may be in doc.doc.sh or in components/templates.sh)
func_body=""
if grep -q '^render_template_json()' "$CLI" 2>/dev/null; then
  func_body=$(sed -n '/^render_template_json()/,/^}/p' "$CLI")
elif [ -f "$TEMPLATES_SH" ]; then
  func_body=$(sed -n '/^render_template_json()/,/^}/p' "$TEMPLATES_SH")
fi

assert_contains \
  "render_template_json uses jq 'keys[]' for iteration" \
  "jq -r 'keys[]'" \
  "$func_body"

assert_not_contains \
  "render_template_json does NOT use jq 'to_entries[]'" \
  "to_entries[]" \
  "$func_body"

assert_contains \
  "render_template_json extracts values individually with jq --arg" \
  'jq -r --arg k "$key"' \
  "$func_body"

# =========================================
# Group 2: Security — document content cannot override template variables
# A file whose first line is "filePath=/evil" must not cause
# {{filePath}} to be substituted with "/evil".
# =========================================
echo ""
echo "--- Group 2: Security — multiline value cannot inject template vars ---"

INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)

# Create a file whose content starts with a line that looks like a key=value pair.
# Under the old bug this line would be parsed as  key=filePath  val=/evil
# and would overwrite {{filePath}} in the sidecar output.
printf 'filePath=/evil\nNormal line two\n' > "$INPUT_DIR/innocent.txt"

# Create a custom template that includes {{filePath}} and {{fileName}}
TEMPLATE_FILE=$(mktemp --suffix=.md)
cat > "$TEMPLATE_FILE" <<'EOF'
# {{fileName}}
path: {{filePath}}
mime: {{mimeType}}
EOF

output=$(bash "$CLI" process -d "$INPUT_DIR" -o "$OUTPUT_DIR" -t "$TEMPLATE_FILE" 2>/dev/null)
exit_code=$?

assert_exit_code "process exits 0" "0" "$exit_code"

sidecar="$OUTPUT_DIR/innocent.txt.md"
assert_file_exists "sidecar created for innocent.txt" "$sidecar"

sidecar_content=$(cat "$sidecar")

# filePath must point to the actual file, not /evil
assert_not_contains \
  "sidecar does not contain injected /evil path" \
  "/evil" \
  "$sidecar_content"

assert_contains \
  "sidecar contains real file name innocent.txt" \
  "innocent.txt" \
  "$sidecar_content"

# =========================================
# Group 3: DEBTR_003 — multiline content is preserved via process
# We verify via the process command that {{documentText}} (if present
# in a template) would receive the full content.  Since the default
# plugins may not emit documentText, we test indirectly: confirm the
# sidecar contains the correct filePath substitution, and that
# the source code fix is in place (Group 1 already validates the
# safe iteration pattern).
# =========================================
echo ""
echo "--- Group 3: Regression — single-line placeholder substitution ---"

# Re-use sidecar from Group 2
assert_contains \
  "sidecar contains 'path:' heading from template" \
  "path:" \
  "$sidecar_content"

assert_contains \
  "sidecar contains 'mime:' heading from template" \
  "mime:" \
  "$sidecar_content"

# =========================================
# Group 4: Template variables with no matching JSON key stay unchanged
# =========================================
echo ""
echo "--- Group 4: Unmatched placeholders remain in output ---"

REGR_INPUT=$(mktemp -d)
REGR_OUTPUT=$(mktemp -d)
REGR_TEMPLATE=$(mktemp --suffix=.md)

echo "some data" > "$REGR_INPUT/data.txt"
cat > "$REGR_TEMPLATE" <<'EOF'
# {{fileName}}
custom: {{noSuchKey}}
EOF

bash "$CLI" process -d "$REGR_INPUT" -o "$REGR_OUTPUT" -t "$REGR_TEMPLATE" 2>/dev/null
regr_sidecar="$REGR_OUTPUT/data.txt.md"

assert_file_exists "sidecar created for data.txt" "$regr_sidecar"

regr_content=$(cat "$regr_sidecar")

assert_contains \
  "unmatched placeholder {{noSuchKey}} left unchanged" \
  "{{noSuchKey}}" \
  "$regr_content"

assert_contains \
  "matched placeholder {{fileName}} was substituted" \
  "data.txt" \
  "$regr_content"

rm -rf "$REGR_INPUT" "$REGR_OUTPUT" "$REGR_TEMPLATE"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
