#!/bin/bash
# run_all_tests.sh - Run all test suites with a per-test timeout.
# Usage: bash tests/run_all_tests.sh [timeout_seconds]
# Default timeout: 10 seconds per test file.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMEOUT="${1:-10}"

total=0
passed=0
failed=0
timed_out=0

for test_file in "$SCRIPT_DIR"/test_*.sh; do
  [ -f "$test_file" ] || continue
  test_name="$(basename "$test_file")"
  total=$((total + 1))

  # Run with timeout; capture exit code
  timeout "$TIMEOUT" bash "$test_file" >/dev/null 2>&1
  ec=$?

  if [ "$ec" -eq 0 ]; then
    printf "  PASS  %s\n" "$test_name"
    passed=$((passed + 1))
  elif [ "$ec" -eq 124 ] || [ "$ec" -eq 137 ] || [ "$ec" -eq 143 ]; then
    printf "  TIMEOUT  %s  (killed after %ss)\n" "$test_name" "$TIMEOUT"
    timed_out=$((timed_out + 1))
  else
    printf "  FAIL  %s  (exit %d)\n" "$test_name" "$ec"
    failed=$((failed + 1))
  fi
done

echo ""
echo "============================================"
echo "  Total: $total  Passed: $passed  Failed: $failed  Timed out: $timed_out"
echo "============================================"

if [ "$failed" -gt 0 ] || [ "$timed_out" -gt 0 ]; then
  exit 1
fi
exit 0
