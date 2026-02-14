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

# Unit Tests: Bug #0005 - Interactive Progress Display Integration
# Tests that progress display functions are properly called during file processing
# Bug: Progress functions exist but are never called, so interactive mode shows logs instead of progress bars

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPONENTS_DIR="$PROJECT_ROOT/scripts/components"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"

# ==============================================================================
# Test Setup
# ==============================================================================

TEST_FIXTURE_DIR="/tmp/bug_0005_test_$$"
TEST_SOURCE_DIR="${TEST_FIXTURE_DIR}/source"
TEST_WORKSPACE_DIR="${TEST_FIXTURE_DIR}/workspace"
TEST_TARGET_DIR="${TEST_FIXTURE_DIR}/target"
TEST_TEMPLATE_FILE="${TEST_FIXTURE_DIR}/template.md"
TEST_PLUGINS_DIR="${TEST_FIXTURE_DIR}/plugins"

setup_test() {
  # Create test directories
  mkdir -p "${TEST_SOURCE_DIR}"
  mkdir -p "${TEST_PLUGINS_DIR}"
  
  # Create test files to process
  echo "test file 1" > "${TEST_SOURCE_DIR}/file1.txt"
  echo "test file 2" > "${TEST_SOURCE_DIR}/file2.txt"
  echo "test file 3" > "${TEST_SOURCE_DIR}/file3.txt"
  
  # Create basic template
  cat > "${TEST_TEMPLATE_FILE}" << 'EOF'
# Test Report
Total files: {{total_files}}
EOF

  # Create a minimal test plugin
  mkdir -p "${TEST_PLUGINS_DIR}/test_plugin"
  cat > "${TEST_PLUGINS_DIR}/test_plugin/descriptor.json" << 'EOF'
{
  "name": "test_plugin",
  "version": "1.0.0",
  "enabled": true,
  "priority": 100,
  "file_types": ["*.txt"],
  "requirements": [],
  "description": "Test plugin"
}
EOF
  
  cat > "${TEST_PLUGINS_DIR}/test_plugin/plugin.sh" << 'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "${TEST_PLUGINS_DIR}/test_plugin/plugin.sh"
}

teardown_test() {
  if [[ -d "${TEST_FIXTURE_DIR}" ]]; then
    rm -rf "${TEST_FIXTURE_DIR}"
  fi
}

# Load required components
load_components() {
  source "$COMPONENTS_DIR/core/constants.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/core/logging.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/core/mode_detection.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/core/error_handling.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/ui/progress_display.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/workspace.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/workspace_security.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/scanner.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/template_engine.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/report_generator.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/plugin/plugin_parser.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/plugin/plugin_validator.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/plugin/plugin_tool_checker.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/plugin/plugin_executor.sh" 2>/dev/null || true
  source "$COMPONENTS_DIR/orchestration/main_orchestrator.sh" 2>/dev/null || true
}

# ==============================================================================
# Test 1: Verify progress functions are called in interactive mode
# ==============================================================================

test_progress_functions_called_in_interactive_mode() {
  setup_test
  load_components
  
  # Track progress function calls using temp files (survives subshell)
  local track_dir="${TEST_FIXTURE_DIR}/progress_tracking"
  mkdir -p "$track_dir"
  
  # Override progress functions to track calls via files
  show_progress() {
    echo "1" >> "$track_dir/show_progress_calls"
    return 0
  }
  
  clear_progress() {
    echo "1" >> "$track_dir/clear_progress_calls"
    return 0
  }
  
  # Set interactive mode
  export IS_INTERACTIVE=true
  
  # Run orchestration (wrapped to capture errors)
  local result
  result=$(orchestrate_directory_analysis \
    "$TEST_SOURCE_DIR" \
    "$TEST_WORKSPACE_DIR" \
    "$TEST_TARGET_DIR" \
    "$TEST_TEMPLATE_FILE" \
    "$TEST_PLUGINS_DIR" 2>&1) || true
  
  # Read tracking data from files
  local show_progress_called=0
  local clear_progress_called=0
  local update_count=0
  
  if [[ -f "$track_dir/show_progress_calls" ]]; then
    show_progress_called=1
    update_count=$(wc -l < "$track_dir/show_progress_calls")
  fi
  if [[ -f "$track_dir/clear_progress_calls" ]]; then
    clear_progress_called=1
  fi
  
  teardown_test
  
  # Verify show_progress was called
  if [[ $show_progress_called -eq 1 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: show_progress() called during file processing"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: show_progress() was not called in interactive mode"
  fi
  
  # Verify clear_progress was called
  if [[ $clear_progress_called -eq 1 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: clear_progress() called after processing"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: clear_progress() was not called"
  fi
  
  # Verify multiple updates occurred (one per file)
  if [[ $update_count -ge 3 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Progress updated multiple times ($update_count updates)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Progress should update for each file (got $update_count updates, expected >= 3)"
  fi
}

# ==============================================================================
# Test 2: Verify progress NOT called in non-interactive mode
# ==============================================================================

test_progress_not_called_in_noninteractive_mode() {
  setup_test
  load_components
  
  # Track progress function calls using temp files
  local track_dir="${TEST_FIXTURE_DIR}/progress_tracking_nointeractive"
  mkdir -p "$track_dir"
  
  # Override progress functions to track calls via files
  show_progress() {
    echo "1" >> "$track_dir/show_progress_calls"
    return 0
  }
  
  clear_progress() {
    echo "1" >> "$track_dir/clear_progress_calls"
    return 0
  }
  
  # Set non-interactive mode
  export IS_INTERACTIVE=false
  
  # Run orchestration
  local result
  result=$(orchestrate_directory_analysis \
    "$TEST_SOURCE_DIR" \
    "$TEST_WORKSPACE_DIR" \
    "$TEST_TARGET_DIR" \
    "$TEST_TEMPLATE_FILE" \
    "$TEST_PLUGINS_DIR" 2>&1) || true
  
  # Read tracking data
  local show_progress_called=0
  local clear_progress_called=0
  
  if [[ -f "$track_dir/show_progress_calls" ]]; then
    show_progress_called=1
  fi
  if [[ -f "$track_dir/clear_progress_calls" ]]; then
    clear_progress_called=1
  fi
  
  teardown_test
  
  # Verify show_progress was NOT called in non-interactive mode
  if [[ $show_progress_called -eq 0 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: show_progress() not called in non-interactive mode"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: show_progress() should not be called in non-interactive mode"
  fi
  
  # Verify clear_progress was NOT called
  if [[ $clear_progress_called -eq 0 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: clear_progress() not called in non-interactive mode"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: clear_progress() should not be called in non-interactive mode"
  fi
}

# ==============================================================================
# Test 3: Verify progress shows correct file counts and percentages
# ==============================================================================

test_progress_shows_correct_counts_and_percentages() {
  setup_test
  load_components
  
  # Track progress parameters using temp files
  local track_dir="${TEST_FIXTURE_DIR}/progress_tracking_counts"
  mkdir -p "$track_dir"
  
  # Override show_progress to capture parameters via files
  show_progress() {
    local percent="$1"
    local processed="$2"
    local total="$3"
    
    echo "$percent" >> "$track_dir/percentages"
    echo "$processed" >> "$track_dir/processed"
    echo "$total" >> "$track_dir/totals"
    
    return 0
  }
  
  clear_progress() {
    return 0
  }
  
  # Set interactive mode
  export IS_INTERACTIVE=true
  
  # Run orchestration
  local result
  result=$(orchestrate_directory_analysis \
    "$TEST_SOURCE_DIR" \
    "$TEST_WORKSPACE_DIR" \
    "$TEST_TARGET_DIR" \
    "$TEST_TEMPLATE_FILE" \
    "$TEST_PLUGINS_DIR" 2>&1) || true
  
  # Read tracking data
  local update_count=0
  if [[ -f "$track_dir/percentages" ]]; then
    update_count=$(wc -l < "$track_dir/percentages")
  fi
  
  # Read file data before teardown
  local last_total="" first_processed="" last_processed="" first_percent="" last_percent=""
  if [[ -f "$track_dir/totals" ]]; then
    last_total=$(tail -1 "$track_dir/totals")
  fi
  if [[ -f "$track_dir/processed" ]]; then
    first_processed=$(head -1 "$track_dir/processed")
    last_processed=$(tail -1 "$track_dir/processed")
  fi
  if [[ -f "$track_dir/percentages" ]]; then
    first_percent=$(head -1 "$track_dir/percentages")
    last_percent=$(tail -1 "$track_dir/percentages")
  fi
  
  teardown_test
  
  # Verify we got progress updates
  if [[ $update_count -ge 3 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Received progress updates ($update_count updates)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Expected at least 3 progress updates, got $update_count"
    return
  fi
  
  # Verify total is consistent (should be at least 3 files)
  if [[ -n "$last_total" ]] && [[ "$last_total" -ge 3 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Progress shows correct total file count (>= 3, got $last_total)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Expected total >= 3, got total=$last_total"
  fi
  
  # Verify processed count increases
  if [[ -n "$last_processed" ]] && [[ -n "$first_processed" ]] && [[ $last_processed -gt $first_processed ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Processed count increases ($first_processed -> $last_processed)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Processed count should increase"
  fi
  
  # Verify percentage increases
  if [[ -n "$last_percent" ]] && [[ -n "$first_percent" ]] && [[ $last_percent -ge $first_percent ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Progress percentage increases ($first_percent% -> $last_percent%)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Progress percentage should increase"
  fi
}

# ==============================================================================
# Test 4: Verify progress displays current file being processed
# ==============================================================================

test_progress_shows_current_file() {
  setup_test
  load_components
  
  # Track captured file paths using temp files
  local track_dir="${TEST_FIXTURE_DIR}/progress_tracking_files"
  mkdir -p "$track_dir"
  
  # Override show_progress to capture file parameter via files
  show_progress() {
    local percent="$1"
    local processed="$2"
    local total="$3"
    local skipped="$4"
    local current_file="$5"
    
    if [[ -n "$current_file" ]]; then
      echo "$current_file" >> "$track_dir/captured_files"
    fi
    
    return 0
  }
  
  clear_progress() {
    return 0
  }
  
  # Set interactive mode
  export IS_INTERACTIVE=true
  
  # Run orchestration
  local result
  result=$(orchestrate_directory_analysis \
    "$TEST_SOURCE_DIR" \
    "$TEST_WORKSPACE_DIR" \
    "$TEST_TARGET_DIR" \
    "$TEST_TEMPLATE_FILE" \
    "$TEST_PLUGINS_DIR" 2>&1) || true
  
  # Read tracking data before teardown
  local file_count=0
  local captured_files_content=""
  if [[ -f "$track_dir/captured_files" ]]; then
    file_count=$(wc -l < "$track_dir/captured_files")
    captured_files_content=$(cat "$track_dir/captured_files")
  fi
  
  teardown_test
  
  # Verify current file was captured
  if [[ $file_count -ge 3 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Progress displays current file ($file_count files captured)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Expected at least 3 file paths, got $file_count"
    return
  fi
  
  # Verify file paths are not empty
  local all_valid=1
  while IFS= read -r file; do
    if [[ -z "$file" ]]; then
      all_valid=0
      break
    fi
  done <<< "$captured_files_content"
  
  if [[ $all_valid -eq 1 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: All captured file paths are non-empty"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Some file paths were empty"
  fi
  
  # Verify at least one file path contains our test files
  local found_test_file=0
  if echo "$captured_files_content" | grep -q "file.*\.txt" 2>/dev/null; then
    found_test_file=1
  fi
  
  if [[ $found_test_file -eq 1 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Progress shows actual test file paths"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Could not find test file paths in progress"
  fi
}

# ==============================================================================
# Test 5: Verify progress initialized before loop starts
# ==============================================================================

test_progress_initialized_before_loop() {
  setup_test
  load_components
  
  # Track first call parameters using temp files
  local track_dir="${TEST_FIXTURE_DIR}/progress_tracking_init"
  mkdir -p "$track_dir"
  
  # Override show_progress to capture first call via file
  show_progress() {
    if [[ ! -f "$track_dir/first_call" ]]; then
      echo "$1|$2" > "$track_dir/first_call"
    fi
    return 0
  }
  
  clear_progress() {
    return 0
  }
  
  # Set interactive mode
  export IS_INTERACTIVE=true
  
  # Run orchestration
  local result
  result=$(orchestrate_directory_analysis \
    "$TEST_SOURCE_DIR" \
    "$TEST_WORKSPACE_DIR" \
    "$TEST_TARGET_DIR" \
    "$TEST_TEMPLATE_FILE" \
    "$TEST_PLUGINS_DIR" 2>&1) || true
  
  teardown_test
  
  # Read first call data
  local first_call_percent=""
  local first_call_processed=""
  if [[ -f "$track_dir/first_call" ]]; then
    first_call_percent=$(cut -d'|' -f1 < "$track_dir/first_call")
    first_call_processed=$(cut -d'|' -f2 < "$track_dir/first_call")
  fi
  
  # Verify first call shows initial state (0% or 0 processed)
  if [[ "$first_call_percent" -eq 0 ]] || [[ "$first_call_processed" -eq 0 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Progress initialized at start (percent=$first_call_percent%, processed=$first_call_processed)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: First progress call should show 0% or 0 processed (got percent=$first_call_percent%, processed=$first_call_processed)"
  fi
}

# ==============================================================================
# Test 6: Source code verification - check calls exist in main_orchestrator.sh
# ==============================================================================

test_source_contains_progress_calls() {
  local orchestrator_file="$COMPONENTS_DIR/orchestration/main_orchestrator.sh"
  
  if [[ ! -f "$orchestrator_file" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: main_orchestrator.sh not found"
    return
  fi
  
  # Check for show_progress call in file processing section
  if grep -q "show_progress" "$orchestrator_file"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: show_progress() call exists in main_orchestrator.sh"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: show_progress() call not found in main_orchestrator.sh"
  fi
  
  # Check for clear_progress call
  if grep -q "clear_progress" "$orchestrator_file"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: clear_progress() call exists in main_orchestrator.sh"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: clear_progress() call not found in main_orchestrator.sh"
  fi
  
  # Check that progress calls are in the file processing loop area (around lines 167-184)
  local loop_section
  loop_section=$(sed -n '150,200p' "$orchestrator_file")
  
  if echo "$loop_section" | grep -q "show_progress\|update_progress"; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Progress call found in file processing loop section"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Progress call not found in file processing loop section (lines 150-200)"
  fi
}

# ==============================================================================
# Test 7: Verify IS_INTERACTIVE flag controls progress display
# ==============================================================================

test_is_interactive_flag_controls_progress() {
  setup_test
  load_components
  
  # Track calls using temp files
  local track_dir="${TEST_FIXTURE_DIR}/progress_tracking_flag"
  mkdir -p "$track_dir"
  
  # Test with IS_INTERACTIVE=true
  show_progress() {
    echo "1" >> "$track_dir/interactive_calls"
    return 0
  }
  clear_progress() {
    return 0
  }
  
  export IS_INTERACTIVE=true
  local result
  result=$(orchestrate_directory_analysis \
    "$TEST_SOURCE_DIR" \
    "$TEST_WORKSPACE_DIR" \
    "$TEST_TARGET_DIR" \
    "$TEST_TEMPLATE_FILE" \
    "$TEST_PLUGINS_DIR" 2>&1) || true
  
  # Test with IS_INTERACTIVE=false
  show_progress() {
    echo "1" >> "$track_dir/noninteractive_calls"
    return 0
  }
  
  export IS_INTERACTIVE=false
  result=$(orchestrate_directory_analysis \
    "$TEST_SOURCE_DIR" \
    "$TEST_WORKSPACE_DIR" \
    "$TEST_TARGET_DIR" \
    "$TEST_TEMPLATE_FILE" \
    "$TEST_PLUGINS_DIR" 2>&1) || true
  
  # Read tracking data
  local interactive_calls=0
  local noninteractive_calls=0
  if [[ -f "$track_dir/interactive_calls" ]]; then
    interactive_calls=$(wc -l < "$track_dir/interactive_calls")
  fi
  if [[ -f "$track_dir/noninteractive_calls" ]]; then
    noninteractive_calls=$(wc -l < "$track_dir/noninteractive_calls")
  fi
  
  teardown_test
  
  # Verify interactive mode triggered progress
  if [[ $interactive_calls -gt 0 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Progress called when IS_INTERACTIVE=true ($interactive_calls calls)"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Progress not called when IS_INTERACTIVE=true"
  fi
  
  # Verify non-interactive mode did NOT trigger progress
  if [[ $noninteractive_calls -eq 0 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Progress not called when IS_INTERACTIVE=false"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Progress should not be called when IS_INTERACTIVE=false (got $noninteractive_calls calls)"
  fi
}

# ==============================================================================
# Run Tests
# ==============================================================================

start_test_suite "Bug #0005 - Interactive Progress Display Integration"

test_progress_functions_called_in_interactive_mode
test_progress_not_called_in_noninteractive_mode
test_progress_shows_correct_counts_and_percentages
test_progress_shows_current_file
test_progress_initialized_before_loop
test_source_contains_progress_calls
test_is_interactive_flag_controls_progress

finish_test_suite "Bug #0005 - Interactive Progress Display Integration"
