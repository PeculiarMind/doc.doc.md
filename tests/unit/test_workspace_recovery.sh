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

# Test: Workspace Recovery and Rescan (feature_0046)
# Tests workspace directory creation, subdirectory recreation, JSON parse error handling,
# corrupted file removal, source re-scanning, and corruption logging

# Determine repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load test helpers
source "${REPO_ROOT}/tests/helpers/test_helpers.sh"

# ==============================================================================
# Test Setup and Teardown
# ==============================================================================

# Test fixture directory (in /tmp for safe cleanup)
TEST_WORKSPACE_DIR="/tmp/workspace_recovery_test_$$"
TEST_SOURCE_DIR="/tmp/source_test_$$"

setup_test() {
  # Source dependencies
  source "${REPO_ROOT}/scripts/components/core/constants.sh"
  source "${REPO_ROOT}/scripts/components/core/logging.sh"
  source "${REPO_ROOT}/scripts/components/core/error_handling.sh"

  # Source the component under test
  source "${REPO_ROOT}/scripts/components/orchestration/workspace.sh"

  # Create test fixture directories
  mkdir -p "${TEST_WORKSPACE_DIR}"
  mkdir -p "${TEST_SOURCE_DIR}"
}

teardown_test() {
  # Clean up test fixtures
  if [[ -d "${TEST_WORKSPACE_DIR}" ]]; then
    rm -rf "${TEST_WORKSPACE_DIR}"
  fi
  if [[ -d "${TEST_SOURCE_DIR}" ]]; then
    rm -rf "${TEST_SOURCE_DIR}"
  fi
}

# ==============================================================================
# Tests: Workspace Directory Creation with -w Flag
# ==============================================================================

test_workspace_directory_created_when_missing_with_w_flag() {
  local ws_dir="${TEST_WORKSPACE_DIR}/auto_create"
  
  # Ensure directory doesn't exist
  [[ ! -d "$ws_dir" ]]
  
  local output exit_code
  run_command output exit_code init_workspace "$ws_dir"
  
  assert_exit_code 0 "$exit_code" "Workspace initialization should succeed"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -d "$ws_dir" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Missing workspace directory created with -w flag"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Workspace directory should be created when missing"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_workspace_directory_creation_logs_event() {
  local ws_dir="${TEST_WORKSPACE_DIR}/auto_create_log"
  
  local output
  output=$(init_workspace "$ws_dir" 2>&1)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$output" =~ "Creating workspace directory" ]] || [[ "$output" =~ "Initializing workspace" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Workspace directory creation is logged"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should log workspace directory creation"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_workspace_initialization_creates_all_required_subdirectories() {
  local ws_dir="${TEST_WORKSPACE_DIR}/full_structure"
  
  init_workspace "$ws_dir" 2>/dev/null
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -d "$ws_dir/files" ]] && [[ -d "$ws_dir/plugins" ]]; then
    echo -e "${GREEN}✓${NC} PASS: All required subdirectories created"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should create files/ and plugins/ subdirectories"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ==============================================================================
# Tests: Subdirectory Recreation with Warning
# ==============================================================================

test_missing_subdirectories_recreated_automatically() {
  local ws_dir="${TEST_WORKSPACE_DIR}/missing_subdir"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Remove subdirectories to simulate corruption
  rm -rf "$ws_dir/files"
  rm -rf "$ws_dir/plugins"
  
  # Validate workspace (should recreate subdirectories)
  validate_workspace_schema "$ws_dir" 2>/dev/null
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -d "$ws_dir/files" ]] && [[ -d "$ws_dir/plugins" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Missing subdirectories recreated automatically"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Missing subdirectories should be recreated"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_subdirectory_recreation_logs_warning() {
  local ws_dir="${TEST_WORKSPACE_DIR}/subdir_warning"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Remove subdirectory
  rm -rf "$ws_dir/files"
  
  local output
  output=$(validate_workspace_schema "$ws_dir" 2>&1)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$output" =~ "warning" ]] || [[ "$output" =~ "recreating" ]] || [[ "$output" =~ "missing" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Subdirectory recreation logs warning"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should log warning when recreating subdirectories"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_workspace_validation_succeeds_after_subdirectory_recreation() {
  local ws_dir="${TEST_WORKSPACE_DIR}/validation_after_recreation"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Remove and recreate through validation
  rm -rf "$ws_dir/files"
  
  local output exit_code
  run_command output exit_code validate_workspace_schema "$ws_dir"
  
  assert_exit_code 0 "$exit_code" "Validation should succeed after subdirectory recreation"
}

# ==============================================================================
# Tests: JSON Parse Error Handling
# ==============================================================================

test_json_parse_failure_detected() {
  local ws_dir="${TEST_WORKSPACE_DIR}/parse_error"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create corrupted JSON file
  echo "invalid json {{{ not parseable" > "$ws_dir/files/corrupted.json"
  
  local loaded
  loaded=$(load_workspace "$ws_dir" "corrupted" 2>&1)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$loaded" =~ "parse" ]] || [[ "$loaded" == "{}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: JSON parse failure detected"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should detect JSON parse failure"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_malformed_json_handled_gracefully() {
  local ws_dir="${TEST_WORKSPACE_DIR}/malformed"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create various malformed JSON files
  echo "{missing: quotes}" > "$ws_dir/files/bad1.json"
  echo "{'single': 'quotes'}" > "$ws_dir/files/bad2.json"
  echo "{trailing: comma,}" > "$ws_dir/files/bad3.json"
  
  local result1 result2 result3
  result1=$(load_workspace "$ws_dir" "bad1" 2>/dev/null)
  result2=$(load_workspace "$ws_dir" "bad2" 2>/dev/null)
  result3=$(load_workspace "$ws_dir" "bad3" 2>/dev/null)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$result1" == "{}" ]] && [[ "$result2" == "{}" ]] && [[ "$result3" == "{}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Malformed JSON handled gracefully"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: All malformed JSON should return empty object"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_incomplete_json_structure_detected() {
  local ws_dir="${TEST_WORKSPACE_DIR}/incomplete"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create incomplete JSON
  echo '{"file_path": "/test.txt", "incomplete' > "$ws_dir/files/incomplete.json"
  
  local loaded
  loaded=$(load_workspace "$ws_dir" "incomplete" 2>/dev/null)
  
  assert_contains "$loaded" "{}" "Incomplete JSON should return empty object"
}

# ==============================================================================
# Tests: Corrupted Workspace File Removal
# ==============================================================================

test_corrupted_file_removed_on_parse_failure() {
  local ws_dir="${TEST_WORKSPACE_DIR}/remove_corrupt"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create corrupted file
  echo "not json" > "$ws_dir/files/remove_test.json"
  
  # Attempt to load (should remove corrupted file)
  load_workspace "$ws_dir" "remove_test" 2>/dev/null
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -f "$ws_dir/files/remove_test.json" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Corrupted file removed on parse failure"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Corrupted file should be removed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_corrupted_file_removal_preserves_valid_files() {
  local ws_dir="${TEST_WORKSPACE_DIR}/selective_remove"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create both corrupted and valid files
  echo "corrupt" > "$ws_dir/files/bad.json"
  echo '{"valid": true}' > "$ws_dir/files/good.json"
  
  # Load corrupted file (should remove it)
  load_workspace "$ws_dir" "bad" 2>/dev/null
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -f "$ws_dir/files/bad.json" ]] && [[ -f "$ws_dir/files/good.json" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Only corrupted file removed, valid files preserved"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should remove only corrupted files"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_corrupted_file_lock_removed_with_file() {
  local ws_dir="${TEST_WORKSPACE_DIR}/remove_lock"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create corrupted file with lock
  echo "corrupt" > "$ws_dir/files/locked_bad.json"
  echo "lock" > "$ws_dir/files/locked_bad.json.lock"
  
  # Use remove_corrupted_workspace_file directly
  remove_corrupted_workspace_file "$ws_dir" "locked_bad" 2>/dev/null
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -f "$ws_dir/files/locked_bad.json" ]] && [[ ! -f "$ws_dir/files/locked_bad.json.lock" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Corrupted file and lock removed together"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Lock file should be removed with corrupted file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ==============================================================================
# Tests: Source File Re-scanning After Removal
# ==============================================================================

test_removed_file_treated_as_unscanned() {
  local ws_dir="${TEST_WORKSPACE_DIR}/rescan_test"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create and then corrupt a workspace file
  save_workspace "$ws_dir" "rescan1" '{"scanned": true}' 2>/dev/null
  echo "corrupt" > "$ws_dir/files/rescan1.json"
  
  # Load should remove corrupt file and return empty
  local result
  result=$(load_workspace "$ws_dir" "rescan1" 2>/dev/null)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$result" == "{}" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Removed file treated as unscanned (returns empty object)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should return empty object for removed file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_rescan_after_corruption_creates_fresh_state() {
  local ws_dir="${TEST_WORKSPACE_DIR}/fresh_state"
  local source_file="${TEST_SOURCE_DIR}/doc.txt"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create source file
  echo "test content" > "$source_file"
  
  # Create workspace entry
  local hash
  hash=$(generate_file_hash "$source_file" 2>/dev/null)
  save_workspace "$ws_dir" "$hash" '{"file_path":"'"$source_file"'","scanned":true}' 2>/dev/null
  
  # Corrupt the workspace file
  echo "corrupt" > "$ws_dir/files/${hash}.json"
  
  # Load (removes corrupt file)
  load_workspace "$ws_dir" "$hash" 2>/dev/null
  
  # Rescan and save fresh data
  save_workspace "$ws_dir" "$hash" '{"file_path":"'"$source_file"'","scanned":true,"rescanned":true}' 2>/dev/null
  
  local fresh_data
  fresh_data=$(load_workspace "$ws_dir" "$hash" 2>/dev/null)
  
  local rescanned
  rescanned=$(echo "$fresh_data" | jq -r '.rescanned' 2>/dev/null)
  
  assert_equals "true" "$rescanned" "Fresh state created after corruption removal"
}

test_multiple_corrupted_files_handled_independently() {
  local ws_dir="${TEST_WORKSPACE_DIR}/multi_corrupt"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create multiple corrupted files
  echo "corrupt1" > "$ws_dir/files/file1.json"
  echo "corrupt2" > "$ws_dir/files/file2.json"
  echo '{"valid": true}' > "$ws_dir/files/file3.json"
  
  # Load each (corrupted ones should be removed)
  load_workspace "$ws_dir" "file1" 2>/dev/null
  load_workspace "$ws_dir" "file2" 2>/dev/null
  local valid_result
  valid_result=$(load_workspace "$ws_dir" "file3" 2>/dev/null)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -f "$ws_dir/files/file1.json" ]] && 
     [[ ! -f "$ws_dir/files/file2.json" ]] && 
     [[ -f "$ws_dir/files/file3.json" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Multiple corrupted files handled independently"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Each corrupted file should be handled independently"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ==============================================================================
# Tests: Corruption Event Logging
# ==============================================================================

test_corruption_event_logged_with_file_path() {
  local ws_dir="${TEST_WORKSPACE_DIR}/log_path"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create corrupted file
  echo "corrupt" > "$ws_dir/files/log_test.json"
  
  local output
  output=$(load_workspace "$ws_dir" "log_test" 2>&1)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$output" =~ "log_test" ]] || [[ "$output" =~ "corrupt" ]] || [[ "$output" =~ "remov" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Corruption event logged with file path"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should log corruption event with file path"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_corruption_event_logged_with_reason() {
  local ws_dir="${TEST_WORKSPACE_DIR}/log_reason"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create corrupted file
  echo "{invalid json" > "$ws_dir/files/reason_test.json"
  
  local output
  output=$(load_workspace "$ws_dir" "reason_test" 2>&1)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$output" =~ "parse" ]] || [[ "$output" =~ "invalid" ]] || [[ "$output" =~ "corrupt" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Corruption event logged with reason"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should log corruption reason"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_remove_corrupted_logs_file_path_and_reason() {
  local ws_dir="${TEST_WORKSPACE_DIR}/explicit_log"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create corrupted file
  echo "bad data" > "$ws_dir/files/explicit.json"
  
  local output
  output=$(remove_corrupted_workspace_file "$ws_dir" "explicit" 2>&1)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$output" =~ "explicit" ]] && ([[ "$output" =~ "remov" ]] || [[ "$output" =~ "corrupt" ]]); then
    echo -e "${GREEN}✓${NC} PASS: remove_corrupted_workspace_file logs path and reason"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should log file path and removal reason"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_validation_logs_all_corrupted_files() {
  local ws_dir="${TEST_WORKSPACE_DIR}/validation_log"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create multiple corrupted files
  echo "bad1" > "$ws_dir/files/corrupt1.json"
  echo "bad2" > "$ws_dir/files/corrupt2.json"
  
  local output
  output=$(validate_workspace_schema "$ws_dir" 2>&1)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$output" =~ "corrupt1" ]] || [[ "$output" =~ "corrupt2" ]] || [[ "$output" =~ "corrupt" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Validation logs all corrupted files"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should log all corrupted files during validation"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ==============================================================================
# Tests: Validation Without Migrations
# ==============================================================================

test_validation_succeeds_without_migration() {
  local ws_dir="${TEST_WORKSPACE_DIR}/no_migration"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Add valid workspace files without any version/migration metadata
  echo '{"file_path":"/test1.txt"}' > "$ws_dir/files/file1.json"
  echo '{"file_path":"/test2.txt"}' > "$ws_dir/files/file2.json"
  
  local output exit_code
  run_command output exit_code validate_workspace_schema "$ws_dir"
  
  assert_exit_code 0 "$exit_code" "Validation should succeed without requiring migrations"
}

test_validation_does_not_require_schema_version() {
  local ws_dir="${TEST_WORKSPACE_DIR}/no_version"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create files without schema version
  echo '{"data": "test"}' > "$ws_dir/files/versionless.json"
  
  local output exit_code
  run_command output exit_code validate_workspace_schema "$ws_dir"
  
  assert_exit_code 0 "$exit_code" "Should not require schema version field"
}

test_validation_accepts_any_valid_json_structure() {
  local ws_dir="${TEST_WORKSPACE_DIR}/any_structure"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create files with various valid JSON structures
  echo '{"simple": true}' > "$ws_dir/files/simple.json"
  echo '{"nested": {"deeply": {"value": 123}}}' > "$ws_dir/files/nested.json"
  echo '["array", "format"]' > "$ws_dir/files/array.json"
  
  local output exit_code
  run_command output exit_code validate_workspace_schema "$ws_dir"
  
  assert_exit_code 0 "$exit_code" "Should accept any valid JSON structure"
}

test_old_workspace_data_compatible_with_new_code() {
  local ws_dir="${TEST_WORKSPACE_DIR}/backward_compat"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Simulate old workspace data (minimal fields)
  echo '{"file_path":"/old/file.txt"}' > "$ws_dir/files/old_format.json"
  
  local loaded
  loaded=$(load_workspace "$ws_dir" "old_format" 2>/dev/null)
  
  local file_path
  file_path=$(echo "$loaded" | jq -r '.file_path' 2>/dev/null)
  
  assert_equals "/old/file.txt" "$file_path" "Old workspace data should be readable"
}

# ==============================================================================
# Tests: System Continues After Recovery
# ==============================================================================

test_system_continues_analysis_after_corruption_removal() {
  local ws_dir="${TEST_WORKSPACE_DIR}/continue_analysis"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create mix of corrupted and valid files
  echo "corrupt" > "$ws_dir/files/bad.json"
  echo '{"valid": 1}' > "$ws_dir/files/good1.json"
  echo '{"valid": 2}' > "$ws_dir/files/good2.json"
  
  # Validate (should remove corrupted but keep valid)
  local output exit_code
  run_command output exit_code validate_workspace_schema "$ws_dir"
  
  assert_exit_code 0 "$exit_code" "System should continue after corruption removal"
  
  # Verify valid files are intact
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -f "$ws_dir/files/good1.json" ]] && [[ -f "$ws_dir/files/good2.json" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Analysis continues with valid files after corruption removed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Valid files should remain for continued analysis"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_recovery_allows_subsequent_operations() {
  local ws_dir="${TEST_WORKSPACE_DIR}/subsequent_ops"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Corrupt and recover
  echo "corrupt" > "$ws_dir/files/recover_test.json"
  load_workspace "$ws_dir" "recover_test" 2>/dev/null
  
  # Subsequent operations should work
  local output exit_code
  run_command output exit_code save_workspace "$ws_dir" "new_file" '{"after_recovery": true}'
  
  assert_exit_code 0 "$exit_code" "Should allow new operations after recovery"
  assert_file_exists "$ws_dir/files/new_file.json" "New files can be created after recovery"
}

test_multiple_recovery_cycles_work() {
  local ws_dir="${TEST_WORKSPACE_DIR}/multi_recovery"
  init_workspace "$ws_dir" 2>/dev/null
  
  # First cycle: corrupt and recover
  echo "corrupt1" > "$ws_dir/files/cycle1.json"
  load_workspace "$ws_dir" "cycle1" 2>/dev/null
  save_workspace "$ws_dir" "cycle1" '{"recovered": 1}' 2>/dev/null
  
  # Second cycle: corrupt and recover again
  echo "corrupt2" > "$ws_dir/files/cycle1.json"
  load_workspace "$ws_dir" "cycle1" 2>/dev/null
  save_workspace "$ws_dir" "cycle1" '{"recovered": 2}' 2>/dev/null
  
  local loaded
  loaded=$(load_workspace "$ws_dir" "cycle1" 2>/dev/null)
  
  local recovered
  recovered=$(echo "$loaded" | jq -r '.recovered' 2>/dev/null)
  
  assert_equals "2" "$recovered" "Multiple recovery cycles should work"
}

# ==============================================================================
# Tests: Edge Cases and Robustness
# ==============================================================================

test_empty_json_file_handled() {
  local ws_dir="${TEST_WORKSPACE_DIR}/empty_json"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create empty file
  touch "$ws_dir/files/empty.json"
  
  local loaded
  loaded=$(load_workspace "$ws_dir" "empty" 2>/dev/null)
  
  assert_contains "$loaded" "{}" "Empty JSON file should be handled gracefully"
}

test_very_large_corrupted_file_removed() {
  local ws_dir="${TEST_WORKSPACE_DIR}/large_corrupt"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create large corrupted file (1MB of garbage)
  dd if=/dev/urandom of="$ws_dir/files/large_bad.json" bs=1M count=1 2>/dev/null
  
  load_workspace "$ws_dir" "large_bad" 2>/dev/null
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -f "$ws_dir/files/large_bad.json" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Large corrupted file removed successfully"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should remove large corrupted files"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_special_characters_in_corrupted_data() {
  local ws_dir="${TEST_WORKSPACE_DIR}/special_chars"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create file with special characters
  echo '{"bad": "value\x00\xFF"}' > "$ws_dir/files/special.json"
  
  local loaded
  loaded=$(load_workspace "$ws_dir" "special" 2>/dev/null)
  
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -n "$loaded" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Special characters in data handled"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should handle special characters without crashing"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_concurrent_corruption_detection() {
  local ws_dir="${TEST_WORKSPACE_DIR}/concurrent"
  init_workspace "$ws_dir" 2>/dev/null
  
  # Create multiple corrupted files
  for i in {1..5}; do
    echo "corrupt$i" > "$ws_dir/files/concurrent$i.json"
  done
  
  # Load all concurrently (in background)
  for i in {1..5}; do
    load_workspace "$ws_dir" "concurrent$i" 2>/dev/null &
  done
  wait
  
  # Count remaining files
  local remaining
  remaining=$(find "$ws_dir/files" -name "concurrent*.json" 2>/dev/null | wc -l)
  
  assert_equals "0" "$remaining" "All corrupted files should be removed"
}

test_workspace_recovery_with_nested_paths() {
  local ws_dir="${TEST_WORKSPACE_DIR}/nested/deep/path"
  
  # Should create all nested directories
  local output exit_code
  run_command output exit_code init_workspace "$ws_dir"
  
  assert_exit_code 0 "$exit_code" "Should handle nested workspace paths"
  assert_directory_exists "$ws_dir/files" "Nested subdirectories should be created"
}

# ==============================================================================
# Test Execution
# ==============================================================================

main() {
  start_test_suite "Workspace Recovery and Rescan (feature_0046)"
  
  setup_test
  
  # Workspace directory creation tests
  test_workspace_directory_created_when_missing_with_w_flag
  test_workspace_directory_creation_logs_event
  test_workspace_initialization_creates_all_required_subdirectories
  
  # Subdirectory recreation tests
  test_missing_subdirectories_recreated_automatically
  test_subdirectory_recreation_logs_warning
  test_workspace_validation_succeeds_after_subdirectory_recreation
  
  # JSON parse error handling tests
  test_json_parse_failure_detected
  test_malformed_json_handled_gracefully
  test_incomplete_json_structure_detected
  
  # Corrupted file removal tests
  test_corrupted_file_removed_on_parse_failure
  test_corrupted_file_removal_preserves_valid_files
  test_corrupted_file_lock_removed_with_file
  
  # Source file re-scanning tests
  test_removed_file_treated_as_unscanned
  test_rescan_after_corruption_creates_fresh_state
  test_multiple_corrupted_files_handled_independently
  
  # Corruption event logging tests
  test_corruption_event_logged_with_file_path
  test_corruption_event_logged_with_reason
  test_remove_corrupted_logs_file_path_and_reason
  test_validation_logs_all_corrupted_files
  
  # Validation without migrations tests
  test_validation_succeeds_without_migration
  test_validation_does_not_require_schema_version
  test_validation_accepts_any_valid_json_structure
  test_old_workspace_data_compatible_with_new_code
  
  # System continuation tests
  test_system_continues_analysis_after_corruption_removal
  test_recovery_allows_subsequent_operations
  test_multiple_recovery_cycles_work
  
  # Edge cases and robustness tests
  test_empty_json_file_handled
  test_very_large_corrupted_file_removed
  test_special_characters_in_corrupted_data
  test_concurrent_corruption_detection
  test_workspace_recovery_with_nested_paths
  
  teardown_test
  
  finish_test_suite "Workspace Recovery and Rescan (feature_0046)"
}

# Run tests
main

exit $?
