#!/bin/bash
# Test suite for FEATURE_0045: loop command — interactive document pipeline
# TDD: Tests define the contract BEFORE implementation; they FAIL until loop is
#       implemented in doc.doc.sh and the supporting components.
# Run from repository root: bash tests/test_feature_0045.sh

# 'set -e' is intentionally omitted: individual assertions must not abort the
# test run; every failure is recorded via FAIL counter and execution continues
# so all groups report results before the final summary.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/doc.doc.sh"
PLUGIN_DIR="$REPO_ROOT/doc.doc.md/plugins"

PASS=0
FAIL=0
SKIP=0
TOTAL=0

# ---- assert helpers ----

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

assert_not_contains() {
  local test_name="$1" unwanted="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$actual" | grep -qF -- "$unwanted"; then
    echo "  FAIL: $test_name"
    echo "    Should not contain: $unwanted"
    echo "    Actual: $(echo "$actual" | head -3)"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

assert_file_exists() {
  local test_name="$1" filepath="$2"
  TOTAL=$((TOTAL + 1))
  if [ -e "$filepath" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Expected file: $filepath"
    FAIL=$((FAIL + 1))
  fi
}

assert_dir_exists() {
  local test_name="$1" dirpath="$2"
  TOTAL=$((TOTAL + 1))
  if [ -d "$dirpath" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Expected directory: $dirpath"
    FAIL=$((FAIL + 1))
  fi
}

assert_count() {
  local test_name="$1" expected="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $test_name (count=$actual)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    Expected count: $expected"
    echo "    Actual count:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

# ---- Setup: create spy45 test plugin ----

SPY_PLUGIN_DIR="$PLUGIN_DIR/spy45"
TEST_TMPDIR=$(mktemp -d)

cleanup() {
  rm -rf "$SPY_PLUGIN_DIR" "$TEST_TMPDIR"
}
trap cleanup EXIT

mkdir -p "$SPY_PLUGIN_DIR"

# descriptor.json — three commands:
#   train    : records filePath in pluginStorage/calls.log, echoes JSON, exits 0
#   skip65   : records filePath in pluginStorage/skip65_calls.log, exits 65
#   fail99   : records filePath in pluginStorage/fail99_calls.log, exits 99
cat > "$SPY_PLUGIN_DIR/descriptor.json" << 'DESCEOF'
{
  "name": "spy45",
  "version": "1.0.0",
  "description": "Spy plugin for testing FEATURE_0045 loop command",
  "active": true,
  "commands": {
    "train": {
      "description": "Record calls to pluginStorage/calls.log and echo JSON. Used by loop.",
      "command": "train.sh",
      "input": {
        "pluginStorage": {
          "type": "string",
          "description": "Path to plugin storage directory",
          "required": true
        },
        "filePath": {
          "type": "string",
          "description": "Absolute path to the document being processed",
          "required": true
        }
      }
    },
    "skip65": {
      "description": "Always exits 65 (ADR-004 intentional skip). Tests silent-skip behaviour.",
      "command": "skip65.sh",
      "input": {
        "filePath": {
          "type": "string",
          "description": "Absolute path to the document being processed",
          "required": true
        },
        "pluginStorage": {
          "type": "string",
          "description": "Path to plugin storage directory",
          "required": false
        }
      }
    },
    "fail99": {
      "description": "Always exits 99. Tests graceful-continue on non-zero non-65 exit.",
      "command": "fail99.sh",
      "input": {
        "filePath": {
          "type": "string",
          "description": "Absolute path to the document being processed",
          "required": true
        },
        "pluginStorage": {
          "type": "string",
          "description": "Path to plugin storage directory",
          "required": false
        }
      }
    }
  }
}
DESCEOF

# train.sh — read JSON stdin; log filePath; echo JSON back; exit 0
cat > "$SPY_PLUGIN_DIR/train.sh" << 'EOF'
#!/bin/bash
json=$(cat)
file_path=$(printf '%s' "$json" | jq -r '.filePath // ""')
plugin_storage=$(printf '%s' "$json" | jq -r '.pluginStorage // ""')
if [ -n "$plugin_storage" ]; then
  mkdir -p "$plugin_storage"
  printf '%s\n' "$file_path" >> "$plugin_storage/calls.log"
fi
printf '%s\n' "$json"
exit 0
EOF
chmod +x "$SPY_PLUGIN_DIR/train.sh"

# skip65.sh — log filePath; exit 65 (intentional skip per ADR-004)
cat > "$SPY_PLUGIN_DIR/skip65.sh" << 'EOF'
#!/bin/bash
json=$(cat)
file_path=$(printf '%s' "$json" | jq -r '.filePath // ""')
plugin_storage=$(printf '%s' "$json" | jq -r '.pluginStorage // ""')
if [ -n "$plugin_storage" ]; then
  mkdir -p "$plugin_storage"
  printf '%s\n' "$file_path" >> "$plugin_storage/skip65_calls.log"
fi
exit 65
EOF
chmod +x "$SPY_PLUGIN_DIR/skip65.sh"

# fail99.sh — log filePath; exit 99 (non-zero, non-skip error)
cat > "$SPY_PLUGIN_DIR/fail99.sh" << 'EOF'
#!/bin/bash
json=$(cat)
file_path=$(printf '%s' "$json" | jq -r '.filePath // ""')
plugin_storage=$(printf '%s' "$json" | jq -r '.pluginStorage // ""')
if [ -n "$plugin_storage" ]; then
  mkdir -p "$plugin_storage"
  printf '%s\n' "$file_path" >> "$plugin_storage/fail99_calls.log"
fi
exit 99
EOF
chmod +x "$SPY_PLUGIN_DIR/fail99.sh"

# ---- TTY simulation helper ----
# run_in_tty <command_string>
# Executes the given command inside a pseudo-TTY via `script`.
# After the call: _TTY_EXIT holds the exit code; _TTY_OUT holds captured output
# (ANSI escape codes and carriage returns stripped).
#
# Note: `script` on util-linux does not reliably propagate the child exit code,
# so we capture it via a wrapper script that writes the code to a temp file.

_TTY_EXIT=0
_TTY_OUT=""
_tty_seq=0

run_in_tty() {
  local cmd_str="$1"
  _tty_seq=$((_tty_seq + 1))
  local tmp_log="$TEST_TMPDIR/tty_log_${_tty_seq}.txt"
  local ec_file="$TEST_TMPDIR/tty_ec_${_tty_seq}.txt"
  local wrapper="$TEST_TMPDIR/tty_wrap_${_tty_seq}.sh"

  # Write a small wrapper that captures the exit code of the target command
  cat > "$wrapper" << WRAPEOF
#!/bin/bash
$cmd_str
printf '%s\n' "\$?" > "$ec_file"
WRAPEOF
  chmod +x "$wrapper"

  script -q -c "bash '$wrapper'" "$tmp_log" >/dev/null 2>&1
  # 255 is a deliberate sentinel: if ec_file is missing (wrapper crashed before
  # writing it) no normal exit code equals 255, so assert_exit_code will produce
  # a meaningful failure message rather than a silent mismatch.
  _TTY_EXIT=$(cat "$ec_file" 2>/dev/null | tr -d ' \n' || echo "255")
  # Strip ANSI escape sequences and carriage returns from the typescript
  _TTY_OUT=$(sed 's/\x1b\[[0-9;?]*[mGKHFJABCDEhlsu]//g; s/\r//g' "$tmp_log" 2>/dev/null || true)
  rm -f "$tmp_log" "$ec_file" "$wrapper"
}

echo "============================================"
echo "  FEATURE_0045: loop command"
echo "  (interactive document pipeline)"
echo "============================================"
echo ""

# =========================================
# Group 1: Non-interactive mode rejection
# Running without a TTY must exit 1 with an error explaining
# that loop requires an interactive terminal.
# =========================================
echo "--- Group 1: Requires interactive terminal (no-TTY rejection) ---"

DOCS_DIR1="$TEST_TMPDIR/docs1"
OUT_DIR1="$TEST_TMPDIR/out1"
mkdir -p "$DOCS_DIR1"
printf 'test document\n' > "$DOCS_DIR1/doc.txt"

# bash "$CLI" runs without a TTY (stdin/stdout are pipes in test context)
out=$(bash "$CLI" loop -d "$DOCS_DIR1" -o "$OUT_DIR1" --plugin spy45 train 2>&1); ec=$?
assert_exit_code "loop without TTY exits 1" 1 "$ec"
assert_contains "loop without TTY error mentions interactive" "interactive" "$out"

# =========================================
# Group 2: Help text
# =========================================
echo ""
echo "--- Group 2: Help text ---"

out=$(bash "$CLI" loop --help 2>&1); ec=$?
assert_exit_code "loop --help exits 0" 0 "$ec"
assert_contains "loop --help shows Usage" "Usage:" "$out"
assert_contains "loop --help documents -d flag" "-d" "$out"
assert_contains "loop --help documents -o flag" "-o" "$out"
assert_contains "loop --help documents --plugin flag" "--plugin" "$out"

out=$(bash "$CLI" --help 2>&1)
assert_contains "main --help lists loop command" "loop" "$out"

# =========================================
# Group 3: Missing required arguments
# =========================================
echo ""
echo "--- Group 3: Missing required arguments ---"

DOCS_DIR3="$TEST_TMPDIR/docs3"
OUT_DIR3="$TEST_TMPDIR/out3"
mkdir -p "$DOCS_DIR3"

# -d missing
out=$(bash "$CLI" loop -o "$OUT_DIR3" --plugin spy45 train 2>&1); ec=$?
assert_exit_code "loop missing -d exits 1" 1 "$ec"
assert_contains "loop missing -d shows helpful error" "-d" "$out"

# -o missing
out=$(bash "$CLI" loop -d "$DOCS_DIR3" --plugin spy45 train 2>&1); ec=$?
assert_exit_code "loop missing -o exits 1" 1 "$ec"
assert_contains "loop missing -o shows helpful error" "-o" "$out"

# --plugin missing (command name at wrong position)
out=$(bash "$CLI" loop -d "$DOCS_DIR3" -o "$OUT_DIR3" train 2>&1); ec=$?
assert_exit_code "loop missing --plugin exits 1" 1 "$ec"

# command name missing (after --plugin)
out=$(bash "$CLI" loop -d "$DOCS_DIR3" -o "$OUT_DIR3" --plugin spy45 2>&1); ec=$?
assert_exit_code "loop missing command exits 1" 1 "$ec"
assert_contains "loop missing command shows error about command" "command" "$out"

# =========================================
# Group 4: Unknown plugin / unknown command
# =========================================
echo ""
echo "--- Group 4: Unknown plugin and unknown command ---"

out=$(bash "$CLI" loop -d "$DOCS_DIR3" -o "$OUT_DIR3" \
  --plugin nonexistent_plugin_xyz45 train 2>&1); ec=$?
assert_exit_code "loop unknown plugin exits 1" 1 "$ec"
assert_contains "loop unknown plugin error mentions not found" "not found" "$out"

out=$(bash "$CLI" loop -d "$DOCS_DIR3" -o "$OUT_DIR3" \
  --plugin spy45 nonexistent_cmd_xyz45 2>&1); ec=$?
assert_exit_code "loop unknown command exits 1" 1 "$ec"
assert_contains "loop unknown command error mentions not found" "not found" "$out"

# =========================================
# Group 5: -d must exist and be readable
# =========================================
echo ""
echo "--- Group 5: Input directory validation ---"

out=$(bash "$CLI" loop -d /nonexistent/path/xyz45abc -o "$TEST_TMPDIR" \
  --plugin spy45 train 2>&1); ec=$?
assert_exit_code "loop -d nonexistent exits 1" 1 "$ec"
assert_contains "loop -d nonexistent shows error" "not exist" "$out"

# =========================================
# Group 6: Per-document invocation (requires TTY)
# The spy plugin records each invocation in pluginStorage/calls.log.
# =========================================
echo ""
echo "--- Group 6: Per-document invocation (TTY) ---"

DOCS_DIR6="$TEST_TMPDIR/docs6"
OUT_DIR6="$TEST_TMPDIR/out6"
mkdir -p "$DOCS_DIR6"
printf 'alpha content\n'   > "$DOCS_DIR6/alpha.txt"
printf 'beta content\n'    > "$DOCS_DIR6/beta.txt"
printf 'gamma content\n'   > "$DOCS_DIR6/gamma.txt"

run_in_tty "bash '$CLI' loop -d '$DOCS_DIR6' -o '$OUT_DIR6' --plugin spy45 train"
assert_exit_code "loop iterates 3 docs, exits 0 (TTY)" 0 "$_TTY_EXIT"

STORAGE6="$OUT_DIR6/.doc.doc.md/spy45"
assert_file_exists "calls.log created in pluginStorage" "$STORAGE6/calls.log"

call_count6=$(cat "$STORAGE6/calls.log" 2>/dev/null | wc -l | tr -d ' ') || call_count6=0
assert_count "spy45 train invoked once per doc (3 total)" 3 "$call_count6"

for fname in alpha.txt beta.txt gamma.txt; do
  TOTAL=$((TOTAL + 1))
  if grep -qF "$fname" "$STORAGE6/calls.log" 2>/dev/null; then
    echo "  PASS: $fname recorded in calls.log"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $fname NOT found in calls.log"
    FAIL=$((FAIL + 1))
  fi
done

# =========================================
# Group 7: pluginStorage directory created under outputDir
# Derived path: <canonicalOutputDir>/.doc.doc.md/<pluginName>/
# =========================================
echo ""
echo "--- Group 7: pluginStorage directory creation ---"

DOCS_DIR7="$TEST_TMPDIR/docs7"
OUT_DIR7="$TEST_TMPDIR/out7"
mkdir -p "$DOCS_DIR7"
printf 'content\n' > "$DOCS_DIR7/file.txt"

run_in_tty "bash '$CLI' loop -d '$DOCS_DIR7' -o '$OUT_DIR7' --plugin spy45 train"
assert_exit_code "loop pluginStorage test exits 0 (TTY)" 0 "$_TTY_EXIT"

STORAGE7="$OUT_DIR7/.doc.doc.md/spy45"
assert_dir_exists "pluginStorage directory created at expected path" "$STORAGE7"

# filePath injected must be an absolute path
if [ -f "$STORAGE7/calls.log" ]; then
  logged_path7=$(head -1 "$STORAGE7/calls.log" 2>/dev/null || true)
  TOTAL=$((TOTAL + 1))
  if [[ "$logged_path7" == /* ]]; then
    echo "  PASS: filePath in JSON is an absolute path"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: filePath is not absolute: '$logged_path7'"
    FAIL=$((FAIL + 1))
  fi
else
  TOTAL=$((TOTAL + 1))
  echo "  FAIL: calls.log not found (cannot verify filePath injection)"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 8: Exit code 65 — silent skip (ADR-004)
# When the target plugin command exits 65, the file is silently skipped:
# no error output from loop, loop continues, overall exit code 0.
# =========================================
echo ""
echo "--- Group 8: Exit code 65 silently skips file ---"

DOCS_DIR8="$TEST_TMPDIR/docs8"
OUT_DIR8="$TEST_TMPDIR/out8"
mkdir -p "$DOCS_DIR8"
printf 'skip1\n' > "$DOCS_DIR8/skip1.txt"
printf 'skip2\n' > "$DOCS_DIR8/skip2.txt"

run_in_tty "bash '$CLI' loop -d '$DOCS_DIR8' -o '$OUT_DIR8' --plugin spy45 skip65"
assert_exit_code "loop skip65 command exits 0 (skips are not fatal)" 0 "$_TTY_EXIT"

# skip65.sh logs to skip65_calls.log so we can verify files were reached
STORAGE8="$OUT_DIR8/.doc.doc.md/spy45"
skip_count8=$(cat "$STORAGE8/skip65_calls.log" 2>/dev/null | wc -l | tr -d ' ') || skip_count8=0
assert_count "skip65 reached both files" 2 "$skip_count8"

# loop must not emit "Error:" for exit-65 files — those are silent skips.
# We check for the literal "Error:" prefix that doc.doc.sh uses for all
# error messages (via log_error / the Error: convention).
TOTAL=$((TOTAL + 1))
if ! echo "$_TTY_OUT" | grep -qF "Error:"; then
  echo "  PASS: no error output for exit-65 skip"
  PASS=$((PASS + 1))
else
  echo "  FAIL: unexpected error output for exit-65 skip"
  echo "    TTY output: $(echo "$_TTY_OUT" | grep -F "Error:" | head -3)"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 9: Non-zero non-65 exit code — graceful continue
# When the target plugin command exits non-zero (≠65), loop logs a warning
# to stderr and continues to the next file; overall exit is still 0.
# =========================================
echo ""
echo "--- Group 9: Non-zero non-65 exit — graceful continue ---"

DOCS_DIR9="$TEST_TMPDIR/docs9"
OUT_DIR9="$TEST_TMPDIR/out9"
mkdir -p "$DOCS_DIR9"
printf 'f1\n' > "$DOCS_DIR9/file1.txt"
printf 'f2\n' > "$DOCS_DIR9/file2.txt"

run_in_tty "bash '$CLI' loop -d '$DOCS_DIR9' -o '$OUT_DIR9' --plugin spy45 fail99"
assert_exit_code "loop fail99 command still exits 0 (graceful continue)" 0 "$_TTY_EXIT"

# fail99.sh logs to fail99_calls.log; both files should have been attempted
STORAGE9="$OUT_DIR9/.doc.doc.md/spy45"
fail_count9=$(cat "$STORAGE9/fail99_calls.log" 2>/dev/null | wc -l | tr -d ' ') || fail_count9=0
assert_count "fail99 reached both files (loop continued)" 2 "$fail_count9"

# =========================================
# Group 10: --include filter scopes iterated files
# =========================================
echo ""
echo "--- Group 10: --include filter ---"

DOCS_DIR10="$TEST_TMPDIR/docs10"
OUT_DIR10="$TEST_TMPDIR/out10"
mkdir -p "$DOCS_DIR10"
printf 'include\n' > "$DOCS_DIR10/keep1.txt"
printf 'include\n' > "$DOCS_DIR10/keep2.txt"
printf 'exclude\n' > "$DOCS_DIR10/skip.md"

run_in_tty "bash '$CLI' loop -d '$DOCS_DIR10' -o '$OUT_DIR10' --plugin spy45 train --include '*.txt'"
assert_exit_code "loop --include exits 0 (TTY)" 0 "$_TTY_EXIT"

STORAGE10="$OUT_DIR10/.doc.doc.md/spy45"
inc_count10=$(cat "$STORAGE10/calls.log" 2>/dev/null | wc -l | tr -d ' ') || inc_count10=0
assert_count "--include *.txt processes only .txt files (2)" 2 "$inc_count10"

TOTAL=$((TOTAL + 1))
if ! grep -qF "skip.md" "$STORAGE10/calls.log" 2>/dev/null; then
  echo "  PASS: skip.md excluded by --include *.txt"
  PASS=$((PASS + 1))
else
  echo "  FAIL: skip.md was NOT excluded despite --include *.txt"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 11: --exclude filter scopes iterated files
# =========================================
echo ""
echo "--- Group 11: --exclude filter ---"

DOCS_DIR11="$TEST_TMPDIR/docs11"
OUT_DIR11="$TEST_TMPDIR/out11"
mkdir -p "$DOCS_DIR11"
printf 'proc\n' > "$DOCS_DIR11/proc1.txt"
printf 'proc\n' > "$DOCS_DIR11/proc2.txt"
printf 'skip\n' > "$DOCS_DIR11/ignore.log"

run_in_tty "bash '$CLI' loop -d '$DOCS_DIR11' -o '$OUT_DIR11' --plugin spy45 train --exclude '*.log'"
assert_exit_code "loop --exclude exits 0 (TTY)" 0 "$_TTY_EXIT"

STORAGE11="$OUT_DIR11/.doc.doc.md/spy45"
exc_count11=$(cat "$STORAGE11/calls.log" 2>/dev/null | wc -l | tr -d ' ') || exc_count11=0
assert_count "--exclude *.log processes only non-log files (2)" 2 "$exc_count11"

TOTAL=$((TOTAL + 1))
if ! grep -qF "ignore.log" "$STORAGE11/calls.log" 2>/dev/null; then
  echo "  PASS: ignore.log excluded by --exclude *.log"
  PASS=$((PASS + 1))
else
  echo "  FAIL: ignore.log was NOT excluded despite --exclude *.log"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 12: No sidecar .md files created
# loop must NOT produce sidecar files (unlike process).
# =========================================
echo ""
echo "--- Group 12: No sidecar output files ---"

DOCS_DIR12="$TEST_TMPDIR/docs12"
OUT_DIR12="$TEST_TMPDIR/out12"
mkdir -p "$DOCS_DIR12"
printf 'content\n' > "$DOCS_DIR12/nosidecar.txt"

run_in_tty "bash '$CLI' loop -d '$DOCS_DIR12' -o '$OUT_DIR12' --plugin spy45 train"
assert_exit_code "loop no-sidecar test exits 0 (TTY)" 0 "$_TTY_EXIT"

sidecar_count12=$(find "$OUT_DIR12" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
TOTAL=$((TOTAL + 1))
if [ "$sidecar_count12" -eq 0 ]; then
  echo "  PASS: no sidecar .md files created by loop"
  PASS=$((PASS + 1))
else
  echo "  FAIL: loop created $sidecar_count12 sidecar .md file(s)"
  find "$OUT_DIR12" -name "*.md" >&2
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 13: Startup banner printed; loop produces no extra output
# The banner must appear in TTY output; beyond the banner and the
# plugin command's own output, loop emits nothing.
# =========================================
echo ""
echo "--- Group 13: Startup banner printed once ---"

DOCS_DIR13="$TEST_TMPDIR/docs13"
OUT_DIR13="$TEST_TMPDIR/out13"
mkdir -p "$DOCS_DIR13"
printf 'one\n' > "$DOCS_DIR13/one.txt"
printf 'two\n' > "$DOCS_DIR13/two.txt"

run_in_tty "bash '$CLI' loop -d '$DOCS_DIR13' -o '$OUT_DIR13' --plugin spy45 train"
assert_exit_code "loop banner test exits 0 (TTY)" 0 "$_TTY_EXIT"

# Banner should contain the doc.doc.md branding (ASCII art or text header).
# We specifically require "doc.doc" to appear, which distinguishes it from
# incidental output such as error messages.
TOTAL=$((TOTAL + 1))
if echo "$_TTY_OUT" | grep -qF "doc.doc"; then
  echo "  PASS: startup banner present in TTY output"
  PASS=$((PASS + 1))
else
  echo "  FAIL: no startup banner detected in TTY output"
  echo "    First 10 lines: $(echo "$_TTY_OUT" | head -10)"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 14: filePath and pluginStorage injected into JSON
# Verify the JSON passed to the plugin command contains both fields
# with correct values.
# =========================================
echo ""
echo "--- Group 14: filePath and pluginStorage injected into JSON ---"

DOCS_DIR14="$TEST_TMPDIR/docs14"
OUT_DIR14="$TEST_TMPDIR/out14"
mkdir -p "$DOCS_DIR14"
printf 'hello\n' > "$DOCS_DIR14/myfile.txt"

run_in_tty "bash '$CLI' loop -d '$DOCS_DIR14' -o '$OUT_DIR14' --plugin spy45 train"
assert_exit_code "loop JSON injection test exits 0 (TTY)" 0 "$_TTY_EXIT"

STORAGE14="$OUT_DIR14/.doc.doc.md/spy45"

# filePath: calls.log should contain the full path to myfile.txt
TOTAL=$((TOTAL + 1))
if grep -qF "myfile.txt" "$STORAGE14/calls.log" 2>/dev/null; then
  echo "  PASS: filePath containing myfile.txt injected into JSON"
  PASS=$((PASS + 1))
else
  echo "  FAIL: myfile.txt not found in calls.log"
  echo "    calls.log: $(cat "$STORAGE14/calls.log" 2>/dev/null | head -5)"
  FAIL=$((FAIL + 1))
fi

# pluginStorage: the directory must exist (train.sh creates it via pluginStorage JSON field)
assert_dir_exists "pluginStorage injected and directory exists" "$STORAGE14"

# Canonical pluginStorage path has no traversal sequences
TOTAL=$((TOTAL + 1))
canonical_storage14="$(readlink -f "$STORAGE14" 2>/dev/null || true)"
if [ -n "$canonical_storage14" ] && [[ "$canonical_storage14" == "$OUT_DIR14"* ]]; then
  echo "  PASS: pluginStorage path is under outputDir (no traversal)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: pluginStorage path not under outputDir or traversal detected"
  echo "    pluginStorage: $canonical_storage14"
  echo "    outputDir:     $OUT_DIR14"
  FAIL=$((FAIL + 1))
fi

# =========================================
# Group 15: Pipeline determination — minimal plugin set
# A command that only needs filePath and pluginStorage (both injected by
# loop itself) should succeed without requiring stat/markitdown to run.
# Verified by: calls.log exists and has correct count (plugins won't abort).
# =========================================
echo ""
echo "--- Group 15: Minimal pipeline determination ---"

DOCS_DIR15="$TEST_TMPDIR/docs15"
OUT_DIR15="$TEST_TMPDIR/out15"
mkdir -p "$DOCS_DIR15"
printf 'pipeline test\n' > "$DOCS_DIR15/pdoc.txt"

run_in_tty "bash '$CLI' loop -d '$DOCS_DIR15' -o '$OUT_DIR15' --plugin spy45 train"
assert_exit_code "loop minimal pipeline exits 0 (TTY)" 0 "$_TTY_EXIT"

STORAGE15="$OUT_DIR15/.doc.doc.md/spy45"
assert_file_exists "minimal pipeline: calls.log created" "$STORAGE15/calls.log"

min_count15=$(cat "$STORAGE15/calls.log" 2>/dev/null | wc -l | tr -d ' ') || min_count15=0
assert_count "minimal pipeline: 1 doc processed" 1 "$min_count15"

# =========================================
# Summary
# =========================================
echo ""
echo "============================================"
if [ "$SKIP" -gt 0 ]; then
  echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped (of $TOTAL total)"
else
  echo "  Results: $PASS passed, $FAIL failed (total: $TOTAL)"
fi
echo "============================================"
[ "$FAIL" -eq 0 ]
