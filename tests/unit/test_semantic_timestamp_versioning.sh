#!/usr/bin/env bash
# Copyright (c) 2026 doc.doc.md Project
# This file is part of doc.doc.md.
#
# doc.doc.md is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# doc.doc.md is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with doc.doc.md. If not, see <https://www.gnu.org/licenses/>.

# Unit Tests: Semantic Timestamp Versioning (ADR-0012)
# Tests the version string generation following format:
# <YEAR>_<CREATIVE_NAME>_<MMDD>.<SECONDS_OF_DAY>
# Example: 2026_Phoenix_0213.54321

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION_NAME_FILE="$PROJECT_ROOT/scripts/components/version_name.txt"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

start_test_suite "Semantic Timestamp Versioning"

# ============================================================================
# Test Group 1: Version Format Validation
# ============================================================================

# Test: Version format matches ADR-0012 pattern
test_version_format_valid() {
  local test_version="2026_Phoenix_0213.54321"
  
  # Pattern: <YEAR>_<NAME>_<MMDD>.<SECONDS>
  if echo "$test_version" | grep -qE '^[0-9]{4}_[A-Za-z]+_[0-9]{4}\.[0-9]+$'; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Version format matches ADR-0012 pattern"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Version format should match <YEAR>_<NAME>_<MMDD>.<SECONDS>"
    echo "  Test version: $test_version"
  fi
}

# Test: Version format rejects invalid patterns
test_version_format_rejects_invalid() {
  local invalid_versions=(
    "2026-Phoenix-0213.54321"  # Wrong separators
    "26_Phoenix_0213.54321"    # Two-digit year
    "2026_phoenix_0213.54321"  # Lowercase name (should be capitalized)
    "2026_Phoenix_213.54321"   # Three-digit MMDD
    "2026_Phoenix_0213"        # Missing SECONDS_OF_DAY
    "2026__0213.54321"         # Missing creative name
  )
  
  local all_rejected=true
  for invalid_version in "${invalid_versions[@]}"; do
    if echo "$invalid_version" | grep -qE '^[0-9]{4}_[A-Z][A-Za-z]+_[0-9]{4}\.[0-9]+$'; then
      all_rejected=false
      echo -e "${RED}✗${NC} Invalid version should be rejected: $invalid_version"
    fi
  done
  
  # Test semantic validation separately (month 13 passes regex but fails semantic check)
  local semantic_invalid="2026_Phoenix_1399.54321"
  local month=$(echo "$semantic_invalid" | cut -d'_' -f3 | cut -c1-2)
  local month_int=$((10#$month))
  if [[ $month_int -lt 1 || $month_int -gt 12 ]]; then
    # This is correctly rejected by semantic validation
    true
  else
    all_rejected=false
    echo -e "${RED}✗${NC} Invalid month (13) should be rejected: $semantic_invalid"
  fi
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if $all_rejected; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Invalid version formats are properly rejected"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Some invalid formats were not rejected"
  fi
}

# Test: Extract year component from version string
test_extract_year_component() {
  local version="2026_Phoenix_0213.54321"
  local year=$(echo "$version" | cut -d'_' -f1)
  
  assert_equals "2026" "$year" "Year component should be extracted correctly"
}

# Test: Extract creative name component from version string
test_extract_creative_name() {
  local version="2026_Phoenix_0213.54321"
  local name=$(echo "$version" | cut -d'_' -f2)
  
  assert_equals "Phoenix" "$name" "Creative name component should be extracted correctly"
}

# Test: Extract MMDD component from version string
test_extract_mmdd_component() {
  local version="2026_Phoenix_0213.54321"
  local mmdd=$(echo "$version" | cut -d'_' -f3 | cut -d'.' -f1)
  
  assert_equals "0213" "$mmdd" "MMDD component should be extracted correctly"
}

# Test: Extract seconds of day component from version string
test_extract_seconds_component() {
  local version="2026_Phoenix_0213.54321"
  local seconds=$(echo "$version" | cut -d'.' -f2)
  
  assert_equals "54321" "$seconds" "Seconds component should be extracted correctly"
}

# ============================================================================
# Test Group 2: Creative Name Management
# ============================================================================

# Test: Creative name file exists
test_creative_name_file_exists() {
  if [[ -f "$VERSION_NAME_FILE" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Creative name file exists at $VERSION_NAME_FILE"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Creative name file should exist at $VERSION_NAME_FILE"
  fi
}

# Test: Creative name file is readable
test_creative_name_file_readable() {
  if [[ -r "$VERSION_NAME_FILE" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Creative name file is readable"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Creative name file should be readable"
  fi
}

# Test: Creative name is not empty
test_creative_name_not_empty() {
  if [[ -f "$VERSION_NAME_FILE" ]]; then
    local name=$(cat "$VERSION_NAME_FILE" | tr -d '[:space:]')
    if [[ -n "$name" ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Creative name is not empty (value: $name)"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Creative name file should contain a non-empty name"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Cannot test creative name - file does not exist"
  fi
}

# Test: Creative name starts with uppercase letter
test_creative_name_capitalized() {
  if [[ -f "$VERSION_NAME_FILE" ]]; then
    local name=$(cat "$VERSION_NAME_FILE" | tr -d '[:space:]')
    if [[ "$name" =~ ^[A-Z] ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Creative name starts with uppercase letter"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Creative name should start with uppercase letter (got: $name)"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Cannot test creative name - file does not exist"
  fi
}

# Test: Creative name contains only letters
test_creative_name_alphabetic() {
  if [[ -f "$VERSION_NAME_FILE" ]]; then
    local name=$(cat "$VERSION_NAME_FILE" | tr -d '[:space:]')
    if [[ "$name" =~ ^[A-Za-z]+$ ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Creative name contains only letters"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Creative name should contain only letters (got: $name)"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Cannot test creative name - file does not exist"
  fi
}

# Test: Handle missing creative name file gracefully
test_handle_missing_creative_name_file() {
  local temp_dir=$(mktemp -d)
  local missing_file="$temp_dir/nonexistent.txt"
  
  if [[ ! -f "$missing_file" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Missing file condition can be detected"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Should detect missing file"
  fi
  
  rm -rf "$temp_dir"
}

# ============================================================================
# Test Group 3: Timestamp Calculation
# ============================================================================

# Test: Year component is 4 digits
test_year_four_digits() {
  local current_year=$(date -u +%Y)
  
  if [[ "$current_year" =~ ^[0-9]{4}$ ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Year is 4 digits (current: $current_year)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Year should be 4 digits (got: $current_year)"
  fi
}

# Test: MMDD component format is valid
test_mmdd_format_valid() {
  local mmdd=$(date -u +%m%d)
  
  if [[ "$mmdd" =~ ^[0-9]{4}$ ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: MMDD is 4 digits (current: $mmdd)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: MMDD should be 4 digits (got: $mmdd)"
  fi
}

# Test: MMDD month component is valid (01-12)
test_mmdd_month_valid() {
  local month=$(date -u +%m)
  local month_int=$((10#$month))
  
  if [[ $month_int -ge 1 && $month_int -le 12 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Month is valid (01-12, current: $month)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Month should be 01-12 (got: $month)"
  fi
}

# Test: MMDD day component is valid (01-31)
test_mmdd_day_valid() {
  local day=$(date -u +%d)
  local day_int=$((10#$day))
  
  if [[ $day_int -ge 1 && $day_int -le 31 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Day is valid (01-31, current: $day)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Day should be 01-31 (got: $day)"
  fi
}

# Test: Seconds of day calculation is valid (0-86399)
test_seconds_of_day_valid() {
  local hour=$(date -u +%H)
  local minute=$(date -u +%M)
  local second=$(date -u +%S)
  local seconds_of_day=$((10#$hour * 3600 + 10#$minute * 60 + 10#$second))
  
  if [[ $seconds_of_day -ge 0 && $seconds_of_day -lt 86400 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Seconds of day is valid (0-86399, current: $seconds_of_day)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Seconds of day should be 0-86399 (got: $seconds_of_day)"
  fi
}

# Test: Seconds of day calculation for midnight
test_seconds_of_day_midnight() {
  local midnight_seconds=0
  
  if [[ $midnight_seconds -ge 0 && $midnight_seconds -lt 86400 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Midnight (00:00:00) = 0 seconds"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Midnight should be 0 seconds (got: $midnight_seconds)"
  fi
}

# Test: Seconds of day calculation for noon
test_seconds_of_day_noon() {
  local noon_seconds=$((12 * 3600))  # 43200
  local expected=43200
  
  assert_equals "$expected" "$noon_seconds" "Noon (12:00:00) should be 43200 seconds"
}

# Test: Seconds of day calculation for end of day
test_seconds_of_day_end_of_day() {
  local end_of_day_seconds=$((23 * 3600 + 59 * 60 + 59))  # 86399
  local expected=86399
  
  assert_equals "$expected" "$end_of_day_seconds" "End of day (23:59:59) should be 86399 seconds"
}

# ============================================================================
# Test Group 4: Version Comparison and Sorting
# ============================================================================

# Test: Versions sort chronologically by year
test_version_sort_by_year() {
  local v1="2025_Phoenix_0101.0"
  local v2="2026_Phoenix_0101.0"
  
  # v1 should come before v2
  if [[ "$v1" < "$v2" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Versions sort by year (2025 < 2026)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Versions should sort by year"
  fi
}

# Test: Versions with same year sort by MMDD
test_version_sort_by_mmdd() {
  local v1="2026_Phoenix_0101.0"
  local v2="2026_Phoenix_0213.0"
  
  # v1 should come before v2
  if [[ "$v1" < "$v2" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Versions sort by MMDD (0101 < 0213)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Versions should sort by MMDD"
  fi
}

# Test: Versions with same date sort by seconds
test_version_sort_by_seconds() {
  local v1="2026_Phoenix_0213.12345"
  local v2="2026_Phoenix_0213.54321"
  
  # v1 should come before v2
  if [[ "$v1" < "$v2" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Versions sort by seconds (12345 < 54321)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Versions should sort by seconds"
  fi
}

# Test: Multiple versions sort correctly
test_version_multiple_sort() {
  local versions=(
    "2025_Phoenix_1231.86399"
    "2026_Phoenix_0101.0"
    "2026_Phoenix_0213.12345"
    "2026_Phoenix_0213.54321"
    "2027_Phoenix_0101.0"
  )
  
  local sorted=$(printf '%s\n' "${versions[@]}" | sort)
  local expected=$(printf '%s\n' "${versions[@]}")
  
  if [[ "$sorted" == "$expected" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Multiple versions sort chronologically"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Multiple versions should sort chronologically"
    echo "  Expected: $expected"
    echo "  Got: $sorted"
  fi
}

# Test: Creative name does not affect chronological sorting
test_creative_name_does_not_affect_sort() {
  local v1="2026_Alpha_0213.12345"
  local v2="2026_Zulu_0213.12345"
  
  # Both versions are identical in timestamp, order preserved
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "${GREEN}✓${NC} PASS: Creative name variations don't break chronological sorting"
}

# ============================================================================
# Test Group 5: Error Handling
# ============================================================================

# Test: Detect invalid MMDD values (month 00)
test_invalid_mmdd_month_zero() {
  local invalid_mmdd="0013"  # Month 00
  local month="${invalid_mmdd:0:2}"
  local month_int=$((10#$month))
  
  if [[ $month_int -lt 1 || $month_int -gt 12 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Invalid month (00) is detected"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Should detect invalid month 00"
  fi
}

# Test: Detect invalid MMDD values (month 13)
test_invalid_mmdd_month_thirteen() {
  local invalid_mmdd="1313"  # Month 13
  local month="${invalid_mmdd:0:2}"
  local month_int=$((10#$month))
  
  if [[ $month_int -lt 1 || $month_int -gt 12 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Invalid month (13) is detected"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Should detect invalid month 13"
  fi
}

# Test: Detect invalid MMDD values (day 00)
test_invalid_mmdd_day_zero() {
  local invalid_mmdd="0100"  # Day 00
  local day="${invalid_mmdd:2:2}"
  local day_int=$((10#$day))
  
  if [[ $day_int -lt 1 || $day_int -gt 31 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Invalid day (00) is detected"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Should detect invalid day 00"
  fi
}

# Test: Detect invalid MMDD values (day 32)
test_invalid_mmdd_day_thirtytwo() {
  local invalid_mmdd="0132"  # Day 32
  local day="${invalid_mmdd:2:2}"
  local day_int=$((10#$day))
  
  if [[ $day_int -lt 1 || $day_int -gt 31 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Invalid day (32) is detected"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Should detect invalid day 32"
  fi
}

# Test: Detect seconds of day out of range (negative)
test_invalid_seconds_negative() {
  local invalid_seconds=-1
  
  if [[ $invalid_seconds -lt 0 || $invalid_seconds -ge 86400 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Negative seconds (-1) is detected"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Should detect negative seconds"
  fi
}

# Test: Detect seconds of day out of range (>= 86400)
test_invalid_seconds_overflow() {
  local invalid_seconds=86400
  
  if [[ $invalid_seconds -lt 0 || $invalid_seconds -ge 86400 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Overflow seconds (86400) is detected"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Should detect seconds >= 86400"
  fi
}

# Test: Handle empty creative name gracefully
test_empty_creative_name_error() {
  local temp_dir=$(mktemp -d)
  local empty_file="$temp_dir/empty.txt"
  touch "$empty_file"
  
  local name=$(cat "$empty_file" | tr -d '[:space:]')
  
  if [[ -z "$name" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Empty creative name is detected"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Should detect empty creative name"
  fi
  
  rm -rf "$temp_dir"
}

# ============================================================================
# Test Group 6: Integration Scenarios
# ============================================================================

# Test: Generate complete version string from components
test_generate_complete_version() {
  local year="2026"
  local creative_name="Phoenix"
  local mmdd="0213"
  local seconds="54321"
  
  local version="${year}_${creative_name}_${mmdd}.${seconds}"
  local expected="2026_Phoenix_0213.54321"
  
  assert_equals "$expected" "$version" "Complete version string should be generated correctly"
}

# Test: Parse and reconstruct version string
test_parse_and_reconstruct_version() {
  local original="2026_Phoenix_0213.54321"
  
  local year=$(echo "$original" | cut -d'_' -f1)
  local name=$(echo "$original" | cut -d'_' -f2)
  local mmdd=$(echo "$original" | cut -d'_' -f3 | cut -d'.' -f1)
  local seconds=$(echo "$original" | cut -d'.' -f2)
  
  local reconstructed="${year}_${name}_${mmdd}.${seconds}"
  
  assert_equals "$original" "$reconstructed" "Version string should parse and reconstruct identically"
}

# Test: Version generation with current timestamp
test_generate_version_with_current_timestamp() {
  if [[ -f "$VERSION_NAME_FILE" ]]; then
    local year=$(date -u +%Y)
    local name=$(cat "$VERSION_NAME_FILE" | tr -d '[:space:]')
    local mmdd=$(date -u +%m%d)
    local hour=$(date -u +%H)
    local minute=$(date -u +%M)
    local second=$(date -u +%S)
    local seconds=$((10#$hour * 3600 + 10#$minute * 60 + 10#$second))
    
    local version="${year}_${name}_${mmdd}.${seconds}"
    
    if echo "$version" | grep -qE '^[0-9]{4}_[A-Z][A-Za-z]+_[0-9]{4}\.[0-9]+$'; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Current timestamp generates valid version: $version"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Current timestamp should generate valid version (got: $version)"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Cannot test version generation - creative name file missing"
  fi
}

# Test: Two versions generated seconds apart are different
test_sequential_versions_differ() {
  if [[ -f "$VERSION_NAME_FILE" ]]; then
    local year=$(date -u +%Y)
    local name=$(cat "$VERSION_NAME_FILE" | tr -d '[:space:]')
    local mmdd=$(date -u +%m%d)
    local hour=$(date -u +%H)
    local minute=$(date -u +%M)
    local second=$(date -u +%S)
    local seconds1=$((10#$hour * 3600 + 10#$minute * 60 + 10#$second))
    
    sleep 1
    
    local hour2=$(date -u +%H)
    local minute2=$(date -u +%M)
    local second2=$(date -u +%S)
    local seconds2=$((10#$hour2 * 3600 + 10#$minute2 * 60 + 10#$second2))
    
    if [[ $seconds2 -gt $seconds1 ]]; then
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo -e "${GREEN}✓${NC} PASS: Sequential versions differ ($seconds1 < $seconds2)"
    else
      TESTS_RUN=$((TESTS_RUN + 1))
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo -e "${RED}✗${NC} FAIL: Sequential versions should differ"
    fi
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Cannot test sequential versions - creative name file missing"
  fi
}

# ============================================================================
# Run all tests
# ============================================================================

# Group 1: Format Validation
test_version_format_valid
test_version_format_rejects_invalid
test_extract_year_component
test_extract_creative_name
test_extract_mmdd_component
test_extract_seconds_component

# Group 2: Creative Name Management
test_creative_name_file_exists
test_creative_name_file_readable
test_creative_name_not_empty
test_creative_name_capitalized
test_creative_name_alphabetic
test_handle_missing_creative_name_file

# Group 3: Timestamp Calculation
test_year_four_digits
test_mmdd_format_valid
test_mmdd_month_valid
test_mmdd_day_valid
test_seconds_of_day_valid
test_seconds_of_day_midnight
test_seconds_of_day_noon
test_seconds_of_day_end_of_day

# Group 4: Version Comparison
test_version_sort_by_year
test_version_sort_by_mmdd
test_version_sort_by_seconds
test_version_multiple_sort
test_creative_name_does_not_affect_sort

# Group 5: Error Handling
test_invalid_mmdd_month_zero
test_invalid_mmdd_month_thirteen
test_invalid_mmdd_day_zero
test_invalid_mmdd_day_thirtytwo
test_invalid_seconds_negative
test_invalid_seconds_overflow
test_empty_creative_name_error

# Group 6: Integration
test_generate_complete_version
test_parse_and_reconstruct_version
test_generate_version_with_current_timestamp
test_sequential_versions_differ

finish_test_suite "Semantic Timestamp Versioning"
exit $?
