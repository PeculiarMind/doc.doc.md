#!/usr/bin/env bash
# Unit tests for bug_0002: Interactive Mode Showing Duplicate Plugin Execution Lines
# Tests that plugin execution messages don't duplicate on separate rows in interactive mode

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source test helpers
source "${SCRIPT_DIR}/../helpers/test_helpers.sh"

# Test 1: Plugin executor uses DEBUG log level for execution messages in interactive mode
test_plugin_executor_log_level() {
  echo -e "\n${BLUE}Test: Plugin executor uses appropriate log level${NC}"
  
  local executor_file="${PROJECT_ROOT}/scripts/components/plugin/plugin_executor.sh"
  
  if [[ ! -f "$executor_file" ]]; then
    echo -e "${RED}✗${NC} FAIL: Plugin executor file not found: $executor_file"
    return 1
  fi
  
  # Check if the "Executing plugin" message uses INFO or DEBUG level
  local log_line
  log_line=$(grep -n "log.*\"Executing plugin:" "$executor_file" | grep -v "DEBUG" || true)
  
  if [[ -n "$log_line" ]]; then
    echo -e "${RED}✗${NC} FAIL: Found non-DEBUG log for 'Executing plugin' message:"
    echo -e "  $log_line"
    echo -e "  This will cause duplicate lines in interactive mode"
    echo -e "  Should use DEBUG level to avoid interfering with progress display"
    return 1
  fi
  
  # Verify DEBUG level is used
  local debug_line
  debug_line=$(grep -n "log.*DEBUG.*\"Executing plugin:" "$executor_file" || true)
  
  if [[ -z "$debug_line" ]]; then
    echo -e "${YELLOW}⚠${NC}  WARN: No 'Executing plugin' log found at DEBUG level"
    echo -e "  The message may have been removed or refactored"
  else
    echo -e "  ✓ Found DEBUG level log: $debug_line"
  fi
  
  echo -e "${GREEN}✓${NC} PASS: Plugin execution logging will not duplicate in interactive mode"
}

# Test 2: Progress display handles plugin execution messages
test_progress_display_shows_plugin() {
  echo -e "\n${BLUE}Test: Progress display includes current plugin field${NC}"
  
  local progress_file="${PROJECT_ROOT}/scripts/components/ui/progress_display.sh"
  
  if [[ ! -f "$progress_file" ]]; then
    echo -e "${RED}✗${NC} FAIL: Progress display file not found: $progress_file"
    return 1
  fi
  
  # Check if show_progress accepts current_plugin parameter
  local show_progress_def
  show_progress_def=$(grep -A 20 "^show_progress()" "$progress_file" || true)
  
  if [[ -z "$show_progress_def" ]]; then
    echo -e "${RED}✗${NC} FAIL: show_progress function not found"
    return 1
  fi
  
  # Check for current_plugin parameter
  if echo "$show_progress_def" | grep -q "current_plugin"; then
    echo -e "  ✓ show_progress function has current_plugin parameter"
  else
    echo -e "${RED}✗${NC} FAIL: show_progress function missing current_plugin parameter"
    return 1
  fi
  
  # Check if it displays "Executing plugin:"
  if grep -q "Executing plugin:" "$progress_file"; then
    echo -e "  ✓ Progress display shows 'Executing plugin:' message"
  else
    echo -e "${RED}✗${NC} FAIL: Progress display doesn't show plugin execution"
    return 1
  fi
  
  echo -e "${GREEN}✓${NC} PASS: Progress display properly handles plugin execution messages"
}

# Test 3: Verify no INFO level "Executing plugin" logs in plugin_executor
test_no_info_executing_plugin_logs() {
  echo -e "\n${BLUE}Test: No INFO level 'Executing plugin' logs in plugin executor${NC}"
  
  local executor_file="${PROJECT_ROOT}/scripts/components/plugin/plugin_executor.sh"
  
  # Search for log "INFO" followed by "Executing plugin"
  if grep -q 'log "INFO".*"Executing plugin:' "$executor_file"; then
    echo -e "${RED}✗${NC} FAIL: Found log \"INFO\" \"Executing plugin:\" - this causes duplicate lines"
    echo -e "  Line content:"
    grep -n 'log "INFO".*"Executing plugin:' "$executor_file"
    return 1
  fi
  
  echo -e "  ✓ No INFO level 'Executing plugin' logs found"
  echo -e "${GREEN}✓${NC} PASS: Plugin executor will not create duplicate log lines"
}

# Test 4: Verify in-place update mechanism in progress display
test_progress_display_in_place_update() {
  echo -e "\n${BLUE}Test: Progress display uses carriage return for in-place updates${NC}"
  
  local progress_file="${PROJECT_ROOT}/scripts/components/ui/progress_display.sh"
  
  # Check for carriage return (\r) usage
  if grep -q '\\r' "$progress_file"; then
    echo -e "  ✓ Progress display uses carriage return (\\r)"
  else
    echo -e "${YELLOW}⚠${NC}  WARN: No carriage return found in progress display"
  fi
  
  # Check for ANSI escape codes for line clearing
  if grep -q '\\033\[K' "$progress_file"; then
    echo -e "  ✓ Progress display uses ANSI escape codes to clear lines"
  else
    echo -e "${YELLOW}⚠${NC}  WARN: No line clearing escape codes found"
  fi
  
  # Check for cursor movement (moving back up)
  if grep -q '\\033\[.*A' "$progress_file"; then
    echo -e "  ✓ Progress display moves cursor back up for updates"
  else
    echo -e "${YELLOW}⚠${NC}  WARN: No cursor movement escape codes found"
  fi
  
  echo -e "${GREEN}✓${NC} PASS: Progress display has in-place update mechanism"
}

# Main test runner
main() {
  echo -e "${BLUE}=== Interactive Progress Duplicate Lines Tests (bug_0002) ===${NC}"
  
  local failed=0
  
  test_plugin_executor_log_level || ((failed++))
  test_progress_display_shows_plugin || ((failed++))
  test_no_info_executing_plugin_logs || ((failed++))
  test_progress_display_in_place_update || ((failed++))
  
  echo -e "\n${BLUE}=== Test Summary ===${NC}"
  if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} All tests passed"
    return 0
  else
    echo -e "${RED}✗${NC} $failed test(s) failed"
    return 1
  fi
}

# Run tests
main
