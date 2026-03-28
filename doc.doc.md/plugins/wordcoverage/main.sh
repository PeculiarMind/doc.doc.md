#!/bin/bash
# wordcoverage plugin - process command
# Reads accumulated pipeline JSON from stdin, extracts wordCount (required)
# and maxWords (optional, default 100), calculates coverage percentage.
# Exit codes: 0 success, 65 skip (wordCount absent/zero — ADR-004), 1 failure

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../components/plugin_input.sh"

plugin_read_input

# Extract wordCount (required, positive integer)
WORD_COUNT_RAW=$(plugin_get_field "wordCount")

# Skip if wordCount is absent, empty, or not a positive integer (ADR-004: exit 65)
if [ -z "$WORD_COUNT_RAW" ]; then
  echo "wordCount is absent from pipeline context" >&2
  exit 65
fi

# Validate wordCount is a positive integer
if ! [[ "$WORD_COUNT_RAW" =~ ^[0-9]+$ ]] || [ "$WORD_COUNT_RAW" -eq 0 ]; then
  echo "wordCount is not a positive integer: $WORD_COUNT_RAW" >&2
  exit 65
fi

WORD_COUNT="$WORD_COUNT_RAW"

# Extract maxWords (optional, positive integer, default 100)
MAX_WORDS_RAW=$(plugin_get_field "maxWords")
MAX_WORDS=100
if [ -n "$MAX_WORDS_RAW" ] && [[ "$MAX_WORDS_RAW" =~ ^[0-9]+$ ]] && [ "$MAX_WORDS_RAW" -gt 0 ]; then
  MAX_WORDS="$MAX_WORDS_RAW"
fi

# Calculate coverage percentage
if [ "$WORD_COUNT" -le "$MAX_WORDS" ]; then
  COVERAGE="100.0"
else
  COVERAGE=$(awk "BEGIN { printf \"%.2f\", ($MAX_WORDS / $WORD_COUNT) * 100 }")
fi

# Output JSON via jq
jq -n \
  --argjson summaryMaxWords "$MAX_WORDS" \
  --argjson summaryCoveragePercent "$COVERAGE" \
  '{
    summaryMaxWords: $summaryMaxWords,
    summaryCoveragePercent: $summaryCoveragePercent
  }'
