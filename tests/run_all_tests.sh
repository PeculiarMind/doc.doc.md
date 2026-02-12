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

# Master Test Runner for doc.doc.sh
# Runs all test suites and provides comprehensive test report

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           doc.doc.sh Test Suite Runner                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

run_test_suite() {
  local test_file="$1"
  local test_name
  test_name=$(basename "$test_file" .sh)
  
  echo -e "${YELLOW}▶ Running: $test_name${NC}"
  
  TOTAL_SUITES=$((TOTAL_SUITES + 1))
  
  if bash "$test_file"; then
    PASSED_SUITES=$((PASSED_SUITES + 1))
    echo -e "${GREEN}✓ PASSED: $test_name${NC}"
  else
    FAILED_SUITES=$((FAILED_SUITES + 1))
    echo -e "${RED}✗ FAILED: $test_name${NC}"
  fi
  
  echo ""
}

# Unit Tests
echo -e "${BLUE}═══ UNIT TESTS ═══${NC}"
echo ""

for test_file in "$SCRIPT_DIR"/unit/test_*.sh; do
  if [[ -f "$test_file" ]]; then
    run_test_suite "$test_file"
  fi
done

# Integration Tests
echo -e "${BLUE}═══ INTEGRATION TESTS ═══${NC}"
echo ""

for test_file in "$SCRIPT_DIR"/integration/test_*.sh; do
  if [[ -f "$test_file" ]]; then
    run_test_suite "$test_file"
  fi
done

# System Tests
echo -e "${BLUE}═══ SYSTEM TESTS ═══${NC}"
echo ""

for test_file in "$SCRIPT_DIR"/system/test_*.sh; do
  if [[ -f "$test_file" ]]; then
    run_test_suite "$test_file"
  fi
done

# Final Report
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   FINAL TEST REPORT                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Total Test Suites: $TOTAL_SUITES"
echo -e "Passed: ${GREEN}$PASSED_SUITES${NC}"
echo -e "Failed: ${RED}$FAILED_SUITES${NC}"
echo ""

if [[ $FAILED_SUITES -eq $TOTAL_SUITES ]]; then
  echo -e "${RED}✗ All tests failed${NC}"
  exit 1
elif [[ $FAILED_SUITES -eq 0 ]]; then
  echo -e "${GREEN}✓ All tests passed! Implementation complete.${NC}"
  exit 0
else
  echo -e "${YELLOW}⚠ Mixed results: Some tests passed, some failed${NC}"
  echo -e "${YELLOW}Implementation may be partially complete${NC}"
  exit 1
fi
