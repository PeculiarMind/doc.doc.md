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

# Test: orchestration/workspace.sh component
# Tests workspace initialization, JSON read/write, locking, timestamps, integrity

# Determine repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load test helpers
source "${REPO_ROOT}/tests/helpers/test_helpers.sh"

# ==============================================================================
# Test Setup and Teardown
# ==============================================================================

# Test fixture directory (in /tmp for safe cleanup)
TEST_WORKSPACE_DIR="/tmp/workspace_test_$$"

setup_test() {
  # Source dependencies
  source "${REPO_ROOT}/scripts/components/core/constants.sh"
  source "${REPO_ROOT}/scripts/components/core/logging.sh"
  source "${REPO_ROOT}/scripts/components/core/error_handling.sh"

  # Source the component under test
  source "${REPO_ROOT}/scripts/components/orchestration/workspace.sh"

  # Create test fixture directory
  mkdir -p "${TEST_WORKSPACE_DIR}"
}

teardown_test() {
  # Clean up test fixtures
  if [[ -d "${TEST_WORKSPACE_DIR}" ]]; then
    rm -rf "${TEST_WORKSPACE_DIR}"
  fi
}

# ==============================================================================
# Tests: Function Existence
# ==============================================================================

test_init_workspace_function_exists() {
  if declare -f init_workspace >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: init_workspace function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: init_workspace function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_generate_file_hash_function_exists() {
  if declare -f generate_file_hash >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: generate_file_hash function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: generate_file_hash function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_load_workspace_function_exists() {
  if declare -f load_workspace >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: load_workspace function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: load_workspace function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_save_workspace_function_exists() {
  if declare -f save_workspace >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: save_workspace function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: save_workspace function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_acquire_lock_function_exists() {
  if declare -f acquire_lock >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: acquire_lock function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: acquire_lock function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_release_lock_function_exists() {
  if declare -f release_lock >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: release_lock function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: release_lock function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_get_last_scan_time_function_exists() {
  if declare -f get_last_scan_time >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: get_last_scan_time function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: get_last_scan_time function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_update_scan_timestamp_function_exists() {
  if declare -f update_scan_timestamp >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: update_scan_timestamp function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: update_scan_timestamp function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_remove_corrupted_workspace_file_function_exists() {
  if declare -f remove_corrupted_workspace_file >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: remove_corrupted_workspace_file function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: remove_corrupted_workspace_file function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_validate_workspace_schema_function_exists() {
  if declare -f validate_workspace_schema >/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: validate_workspace_schema function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: validate_workspace_schema function should exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

# ==============================================================================
# Tests: Workspace Initialization
# ==============================================================================

test_init_workspace_creates_directory() {
  local ws_dir="${TEST_WORKSPACE_DIR}/new_workspace"
  local output exit_code
  run_command output exit_code init_workspace "$ws_dir"

  assert_exit_code 0 "$exit_code" "init_workspace should succeed"

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -d "$ws_dir" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Workspace directory was created"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Workspace directory should be created"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_init_workspace_creates_subdirectories() {
  local ws_dir="${TEST_WORKSPACE_DIR}/subdir_workspace"
  init_workspace "$ws_dir" 2>/dev/null

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -d "$ws_dir/files" ]] && [[ -d "$ws_dir/plugins" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Standard subdirectories (files/, plugins/) created"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should create files/ and plugins/ subdirectories"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_init_workspace_validates_writable() {
  local ws_dir="${TEST_WORKSPACE_DIR}/writable_test"
  init_workspace "$ws_dir" 2>/dev/null

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -w "$ws_dir" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Workspace directory is writable"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Workspace directory should be writable"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_init_workspace_handles_existing_gracefully() {
  local ws_dir="${TEST_WORKSPACE_DIR}/existing_workspace"
  init_workspace "$ws_dir" 2>/dev/null
  # Create a marker file to verify workspace isn't wiped
  echo "marker" > "$ws_dir/files/marker.txt"

  local output exit_code
  run_command output exit_code init_workspace "$ws_dir"

  assert_exit_code 0 "$exit_code" "Should handle existing workspace gracefully"

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -f "$ws_dir/files/marker.txt" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Existing workspace data preserved"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should not reinitialize valid workspace"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_init_workspace_rejects_empty_argument() {
  local output exit_code
  run_command output exit_code init_workspace ""

  assert_exit_code 1 "$exit_code" "Should reject empty workspace directory argument"
}

test_init_workspace_rejects_path_traversal() {
  local output exit_code
  run_command output exit_code init_workspace "${TEST_WORKSPACE_DIR}/../../../etc/hack"

  assert_exit_code 1 "$exit_code" "Should reject path traversal attempts"
}

# ==============================================================================
# Tests: File Hash Generation
# ==============================================================================

test_generate_file_hash_produces_hash() {
  echo "test content" > "${TEST_WORKSPACE_DIR}/hashtest.txt"

  local hash
  hash=$(generate_file_hash "${TEST_WORKSPACE_DIR}/hashtest.txt" 2>/dev/null)

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -n "$hash" ]] && [[ ${#hash} -eq 64 ]]; then
    echo -e "${GREEN}✓${NC} PASS: Generated valid SHA-256 hash (64 chars)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should generate 64-character SHA-256 hash, got: '$hash'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_generate_file_hash_consistent() {
  echo "consistent content" > "${TEST_WORKSPACE_DIR}/consistent.txt"

  local hash1 hash2
  hash1=$(generate_file_hash "${TEST_WORKSPACE_DIR}/consistent.txt" 2>/dev/null)
  hash2=$(generate_file_hash "${TEST_WORKSPACE_DIR}/consistent.txt" 2>/dev/null)

  assert_equals "$hash1" "$hash2" "Same file should produce same hash"
}

test_generate_file_hash_different_content() {
  echo "content A" > "${TEST_WORKSPACE_DIR}/fileA.txt"
  echo "content B" > "${TEST_WORKSPACE_DIR}/fileB.txt"

  local hashA hashB
  hashA=$(generate_file_hash "${TEST_WORKSPACE_DIR}/fileA.txt" 2>/dev/null)
  hashB=$(generate_file_hash "${TEST_WORKSPACE_DIR}/fileB.txt" 2>/dev/null)

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$hashA" != "$hashB" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Different content produces different hashes"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Different content should produce different hashes"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_generate_file_hash_fails_for_missing_file() {
  local output exit_code
  run_command output exit_code generate_file_hash "/nonexistent/file.txt"

  assert_exit_code 1 "$exit_code" "Should fail for missing file"
}

test_generate_file_hash_fails_for_empty_argument() {
  local output exit_code
  run_command output exit_code generate_file_hash ""

  assert_exit_code 1 "$exit_code" "Should fail for empty argument"
}

# ==============================================================================
# Tests: JSON File Operations (Load/Save)
# ==============================================================================

test_save_workspace_writes_json() {
  local ws_dir="${TEST_WORKSPACE_DIR}/save_test"
  init_workspace "$ws_dir" 2>/dev/null

  local json_data='{"file_path":"/test/file.txt","file_size":100}'
  local output exit_code
  run_command output exit_code save_workspace "$ws_dir" "abc123" "$json_data"

  assert_exit_code 0 "$exit_code" "save_workspace should succeed"
  assert_file_exists "$ws_dir/files/abc123.json" "JSON file should be created"
}

test_save_workspace_writes_valid_json() {
  local ws_dir="${TEST_WORKSPACE_DIR}/valid_json_test"
  init_workspace "$ws_dir" 2>/dev/null

  local json_data='{"file_path":"/test/file.txt","file_size":100}'
  save_workspace "$ws_dir" "def456" "$json_data" 2>/dev/null

  TESTS_RUN=$((TESTS_RUN + 1))
  if jq empty "$ws_dir/files/def456.json" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} PASS: Written file contains valid JSON"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Written file should contain valid JSON"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_save_workspace_pretty_prints_json() {
  local ws_dir="${TEST_WORKSPACE_DIR}/pretty_test"
  init_workspace "$ws_dir" 2>/dev/null

  local json_data='{"a":"1","b":"2"}'
  save_workspace "$ws_dir" "pretty1" "$json_data" 2>/dev/null

  local line_count
  line_count=$(wc -l < "$ws_dir/files/pretty1.json")

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$line_count" -gt 1 ]]; then
    echo -e "${GREEN}✓${NC} PASS: JSON is pretty-printed (multi-line)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: JSON should be pretty-printed for readability"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_save_workspace_rejects_invalid_json() {
  local ws_dir="${TEST_WORKSPACE_DIR}/invalid_json_test"
  init_workspace "$ws_dir" 2>/dev/null

  local output exit_code
  run_command output exit_code save_workspace "$ws_dir" "bad1" "not valid json"

  assert_exit_code 1 "$exit_code" "Should reject invalid JSON data"
}

test_save_workspace_atomic_write() {
  local ws_dir="${TEST_WORKSPACE_DIR}/atomic_test"
  init_workspace "$ws_dir" 2>/dev/null

  # Write initial data
  save_workspace "$ws_dir" "atomic1" '{"version":1}' 2>/dev/null

  # Write updated data
  save_workspace "$ws_dir" "atomic1" '{"version":2}' 2>/dev/null

  local version
  version=$(jq -r '.version' "$ws_dir/files/atomic1.json" 2>/dev/null)

  assert_equals "2" "$version" "Atomic write should update to latest version"
}

test_load_workspace_reads_json() {
  local ws_dir="${TEST_WORKSPACE_DIR}/load_test"
  init_workspace "$ws_dir" 2>/dev/null

  local json_data='{"file_path":"/test/file.txt","file_size":200}'
  save_workspace "$ws_dir" "load1" "$json_data" 2>/dev/null

  local loaded
  loaded=$(load_workspace "$ws_dir" "load1" 2>/dev/null)

  local file_path
  file_path=$(echo "$loaded" | jq -r '.file_path' 2>/dev/null)

  assert_equals "/test/file.txt" "$file_path" "Should load correct file_path from workspace"
}

test_load_workspace_handles_missing_file() {
  local ws_dir="${TEST_WORKSPACE_DIR}/missing_load_test"
  init_workspace "$ws_dir" 2>/dev/null

  local loaded exit_code
  run_command loaded exit_code load_workspace "$ws_dir" "nonexistent"

  assert_exit_code 0 "$exit_code" "Should handle missing file gracefully"
  assert_contains "$loaded" "{}" "Should return empty JSON object for missing file"
}

test_load_workspace_handles_corrupted_json() {
  local ws_dir="${TEST_WORKSPACE_DIR}/corrupt_load_test"
  init_workspace "$ws_dir" 2>/dev/null

  # Write corrupted data directly (bypassing save_workspace)
  echo "this is not json {{{" > "$ws_dir/files/corrupt1.json"

  local loaded
  loaded=$(load_workspace "$ws_dir" "corrupt1" 2>/dev/null)

  assert_contains "$loaded" "{}" "Should return empty JSON for corrupted file"

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -f "$ws_dir/files/corrupt1.json" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Corrupted file was removed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Corrupted file should be removed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ==============================================================================
# Tests: Lock Management
# ==============================================================================

test_acquire_lock_creates_lock_file() {
  local ws_dir="${TEST_WORKSPACE_DIR}/lock_test"
  init_workspace "$ws_dir" 2>/dev/null

  local output exit_code
  run_command output exit_code acquire_lock "$ws_dir" "locktest1" 5

  assert_exit_code 0 "$exit_code" "Lock acquisition should succeed"

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -f "$ws_dir/files/locktest1.json.lock" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Lock file was created"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Lock file should be created"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Clean up
  release_lock "$ws_dir" "locktest1" 2>/dev/null
}

test_release_lock_removes_lock_file() {
  local ws_dir="${TEST_WORKSPACE_DIR}/release_test"
  init_workspace "$ws_dir" 2>/dev/null

  acquire_lock "$ws_dir" "releasetest1" 5 2>/dev/null
  release_lock "$ws_dir" "releasetest1" 2>/dev/null

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -f "$ws_dir/files/releasetest1.json.lock" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Lock file was removed after release"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Lock file should be removed after release"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_acquire_lock_timeout() {
  local ws_dir="${TEST_WORKSPACE_DIR}/timeout_test"
  init_workspace "$ws_dir" 2>/dev/null

  # Create a lock file manually to simulate held lock
  echo "fake_pid" > "$ws_dir/files/timeout1.json.lock"
  # Set lock file to recent timestamp (not stale)
  touch "$ws_dir/files/timeout1.json.lock"

  local output exit_code
  run_command output exit_code acquire_lock "$ws_dir" "timeout1" 1

  assert_exit_code 1 "$exit_code" "Lock should timeout when held by another"

  # Clean up
  rm -f "$ws_dir/files/timeout1.json.lock"
}

test_acquire_lock_cleans_stale_locks() {
  local ws_dir="${TEST_WORKSPACE_DIR}/stale_test"
  init_workspace "$ws_dir" 2>/dev/null

  # Create a stale lock file (very old)
  echo "stale_pid" > "$ws_dir/files/stale1.json.lock"
  touch -t 202001011200.00 "$ws_dir/files/stale1.json.lock"

  local output exit_code
  run_command output exit_code acquire_lock "$ws_dir" "stale1" 5

  assert_exit_code 0 "$exit_code" "Should acquire lock after cleaning stale lock"

  # Clean up
  release_lock "$ws_dir" "stale1" 2>/dev/null
}

test_save_workspace_releases_lock_after_write() {
  local ws_dir="${TEST_WORKSPACE_DIR}/lock_release_test"
  init_workspace "$ws_dir" 2>/dev/null

  save_workspace "$ws_dir" "lockrel1" '{"data":"test"}' 2>/dev/null

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -f "$ws_dir/files/lockrel1.json.lock" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Lock released after save"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Lock should be released after save"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ==============================================================================
# Tests: Metadata Storage
# ==============================================================================

test_save_workspace_stores_file_metadata() {
  local ws_dir="${TEST_WORKSPACE_DIR}/metadata_test"
  init_workspace "$ws_dir" 2>/dev/null

  local json_data
  json_data=$(jq -n '{
    "file_path": "/absolute/path/to/file.pdf",
    "file_path_relative": "documents/file.pdf",
    "file_type": "application/pdf",
    "file_size": 1048576,
    "file_last_modified": 1707177600,
    "last_scanned": "2026-02-09T14:30:00Z"
  }')

  save_workspace "$ws_dir" "meta1" "$json_data" 2>/dev/null

  local loaded
  loaded=$(load_workspace "$ws_dir" "meta1" 2>/dev/null)

  local file_path file_type file_size
  file_path=$(echo "$loaded" | jq -r '.file_path')
  file_type=$(echo "$loaded" | jq -r '.file_type')
  file_size=$(echo "$loaded" | jq -r '.file_size')

  assert_equals "/absolute/path/to/file.pdf" "$file_path" "Should store file_path"
  assert_equals "application/pdf" "$file_type" "Should store file_type"
  assert_equals "1048576" "$file_size" "Should store file_size"
}

test_merge_plugin_data() {
  local existing='{"file_path":"/test.txt","file_size":100}'
  local plugin_result='{"word_count":500}'

  local merged
  merged=$(merge_plugin_data "$existing" "word-counter" "$plugin_result" "success" 2>/dev/null)

  local word_count plugin_name
  word_count=$(echo "$merged" | jq -r '.["word-counter"].word_count')
  plugin_name=$(echo "$merged" | jq -r '.plugins_executed[0].name')

  assert_equals "500" "$word_count" "Should merge plugin result data"
  assert_equals "word-counter" "$plugin_name" "Should track plugin execution"
}

test_plugins_executed_tracks_history() {
  local ws_dir="${TEST_WORKSPACE_DIR}/plugin_history_test"
  init_workspace "$ws_dir" 2>/dev/null

  local data='{"file_path":"/test.txt"}'
  data=$(merge_plugin_data "$data" "plugin-a" '{"result":"a"}' "success" 2>/dev/null)
  data=$(merge_plugin_data "$data" "plugin-b" '{"result":"b"}' "success" 2>/dev/null)

  local count
  count=$(echo "$data" | jq '.plugins_executed | length')

  assert_equals "2" "$count" "Should track all plugin executions"
}

# ==============================================================================
# Tests: Timestamp Tracking
# ==============================================================================

test_update_scan_timestamp() {
  local ws_dir="${TEST_WORKSPACE_DIR}/timestamp_test"
  init_workspace "$ws_dir" 2>/dev/null

  # Create initial file data
  save_workspace "$ws_dir" "ts1" '{"file_path":"/test.txt"}' 2>/dev/null

  # Update timestamp
  update_scan_timestamp "$ws_dir" "ts1" "2026-02-09T14:30:00Z" 2>/dev/null

  local loaded
  loaded=$(load_workspace "$ws_dir" "ts1" 2>/dev/null)

  local last_scanned
  last_scanned=$(echo "$loaded" | jq -r '.last_scanned')

  assert_equals "2026-02-09T14:30:00Z" "$last_scanned" "Should update last_scanned timestamp"
}

test_update_full_scan_timestamp() {
  local ws_dir="${TEST_WORKSPACE_DIR}/full_scan_ts_test"
  init_workspace "$ws_dir" 2>/dev/null

  update_full_scan_timestamp "$ws_dir" "2026-02-10T10:00:00Z" 2>/dev/null

  local ts
  ts=$(get_last_scan_time "$ws_dir" 2>/dev/null)

  assert_equals "2026-02-10T10:00:00Z" "$ts" "Should store and retrieve full scan timestamp"
}

test_get_last_scan_time_empty_workspace() {
  local ws_dir="${TEST_WORKSPACE_DIR}/empty_ts_test"
  init_workspace "$ws_dir" 2>/dev/null

  local ts
  ts=$(get_last_scan_time "$ws_dir" 2>/dev/null)

  assert_equals "" "$ts" "Should return empty for workspace without scan timestamp"
}

test_get_last_scan_time_nonexistent_workspace() {
  local ts
  ts=$(get_last_scan_time "/nonexistent/workspace" 2>/dev/null)

  assert_equals "" "$ts" "Should return empty for nonexistent workspace"
}

# ==============================================================================
# Tests: Integrity and Recovery
# ==============================================================================

test_remove_corrupted_workspace_file() {
  local ws_dir="${TEST_WORKSPACE_DIR}/corrupt_remove_test"
  init_workspace "$ws_dir" 2>/dev/null

  # Create a corrupted file
  echo "corrupt data" > "$ws_dir/files/bad1.json"
  echo "lock" > "$ws_dir/files/bad1.json.lock"

  remove_corrupted_workspace_file "$ws_dir" "bad1" 2>/dev/null

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -f "$ws_dir/files/bad1.json" ]] && [[ ! -f "$ws_dir/files/bad1.json.lock" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Corrupted file and lock file removed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should remove corrupted file and associated lock"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_validate_workspace_schema_valid() {
  local ws_dir="${TEST_WORKSPACE_DIR}/schema_valid_test"
  init_workspace "$ws_dir" 2>/dev/null

  # Add a valid JSON file
  echo '{"file_path":"/test.txt"}' > "$ws_dir/files/valid1.json"

  local output exit_code
  run_command output exit_code validate_workspace_schema "$ws_dir"

  assert_exit_code 0 "$exit_code" "Valid workspace should pass schema validation"
}

test_validate_workspace_schema_missing_subdirs() {
  local ws_dir="${TEST_WORKSPACE_DIR}/schema_missing_test"
  mkdir -p "$ws_dir"
  # Don't create files/ and plugins/ subdirectories

  local output exit_code
  run_command output exit_code validate_workspace_schema "$ws_dir"

  assert_exit_code 1 "$exit_code" "Should fail validation with missing subdirectories"
}

test_validate_workspace_schema_removes_corrupted() {
  local ws_dir="${TEST_WORKSPACE_DIR}/schema_corrupt_test"
  init_workspace "$ws_dir" 2>/dev/null

  # Add a corrupted JSON file
  echo "not json" > "$ws_dir/files/corrupt_schema.json"
  # Add a valid JSON file
  echo '{"valid":true}' > "$ws_dir/files/valid_schema.json"

  validate_workspace_schema "$ws_dir" 2>/dev/null

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -f "$ws_dir/files/corrupt_schema.json" ]] && [[ -f "$ws_dir/files/valid_schema.json" ]]; then
    echo -e "${GREEN}✓${NC} PASS: Corrupted files removed, valid files preserved"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} FAIL: Should remove corrupted files and preserve valid ones"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_validate_workspace_schema_nonexistent() {
  local output exit_code
  run_command output exit_code validate_workspace_schema "/nonexistent/path"

  assert_exit_code 1 "$exit_code" "Should fail for nonexistent workspace"
}

test_validate_workspace_schema_empty_argument() {
  local output exit_code
  run_command output exit_code validate_workspace_schema ""

  assert_exit_code 1 "$exit_code" "Should fail for empty argument"
}

# ==============================================================================
# Tests: Error Handling
# ==============================================================================

test_save_workspace_handles_write_failure() {
  local ws_dir="${TEST_WORKSPACE_DIR}/write_fail_test"
  init_workspace "$ws_dir" 2>/dev/null

  # Make files directory read-only to simulate write failure
  chmod 0500 "$ws_dir/files"

  local output exit_code
  run_command output exit_code save_workspace "$ws_dir" "fail1" '{"data":"test"}'

  assert_exit_code 1 "$exit_code" "Should fail gracefully on write error"

  # Restore permissions for cleanup
  chmod 0700 "$ws_dir/files"
}

test_save_workspace_preserves_old_data_on_failure() {
  local ws_dir="${TEST_WORKSPACE_DIR}/preserve_test"
  init_workspace "$ws_dir" 2>/dev/null

  # Write initial data
  save_workspace "$ws_dir" "preserve1" '{"version":1}' 2>/dev/null

  # Attempt to write invalid data (should fail)
  save_workspace "$ws_dir" "preserve1" "not json" 2>/dev/null || true

  local version
  version=$(jq -r '.version' "$ws_dir/files/preserve1.json" 2>/dev/null)

  assert_equals "1" "$version" "Original data should be preserved on write failure"
}

# ==============================================================================
# Tests: Security
# ==============================================================================

test_workspace_directory_permissions() {
  local ws_dir="${TEST_WORKSPACE_DIR}/perms_test"
  init_workspace "$ws_dir" 2>/dev/null

  local dir_perms
  dir_perms=$(stat -c '%a' "$ws_dir" 2>/dev/null)

  assert_equals "700" "$dir_perms" "Workspace directory should have restrictive permissions (0700)"
}

test_workspace_file_permissions() {
  local ws_dir="${TEST_WORKSPACE_DIR}/file_perms_test"
  init_workspace "$ws_dir" 2>/dev/null

  save_workspace "$ws_dir" "perm1" '{"data":"test"}' 2>/dev/null

  local file_perms
  file_perms=$(stat -c '%a' "$ws_dir/files/perm1.json" 2>/dev/null)

  assert_equals "600" "$file_perms" "Workspace files should have restrictive permissions (0600)"
}

# ==============================================================================
# Test Execution
# ==============================================================================

main() {
  start_test_suite "orchestration/workspace.sh"

  setup_test

  # Function existence tests
  test_init_workspace_function_exists
  test_generate_file_hash_function_exists
  test_load_workspace_function_exists
  test_save_workspace_function_exists
  test_acquire_lock_function_exists
  test_release_lock_function_exists
  test_get_last_scan_time_function_exists
  test_update_scan_timestamp_function_exists
  test_remove_corrupted_workspace_file_function_exists
  test_validate_workspace_schema_function_exists

  # Workspace initialization tests
  test_init_workspace_creates_directory
  test_init_workspace_creates_subdirectories
  test_init_workspace_validates_writable
  test_init_workspace_handles_existing_gracefully
  test_init_workspace_rejects_empty_argument
  test_init_workspace_rejects_path_traversal

  # File hash generation tests
  test_generate_file_hash_produces_hash
  test_generate_file_hash_consistent
  test_generate_file_hash_different_content
  test_generate_file_hash_fails_for_missing_file
  test_generate_file_hash_fails_for_empty_argument

  # JSON file operations tests
  test_save_workspace_writes_json
  test_save_workspace_writes_valid_json
  test_save_workspace_pretty_prints_json
  test_save_workspace_rejects_invalid_json
  test_save_workspace_atomic_write
  test_load_workspace_reads_json
  test_load_workspace_handles_missing_file
  test_load_workspace_handles_corrupted_json

  # Lock management tests
  test_acquire_lock_creates_lock_file
  test_release_lock_removes_lock_file
  test_acquire_lock_timeout
  test_acquire_lock_cleans_stale_locks
  test_save_workspace_releases_lock_after_write

  # Metadata storage tests
  test_save_workspace_stores_file_metadata
  test_merge_plugin_data
  test_plugins_executed_tracks_history

  # Timestamp tracking tests
  test_update_scan_timestamp
  test_update_full_scan_timestamp
  test_get_last_scan_time_empty_workspace
  test_get_last_scan_time_nonexistent_workspace

  # Integrity and recovery tests
  test_remove_corrupted_workspace_file
  test_validate_workspace_schema_valid
  test_validate_workspace_schema_missing_subdirs
  test_validate_workspace_schema_removes_corrupted
  test_validate_workspace_schema_nonexistent
  test_validate_workspace_schema_empty_argument

  # Error handling tests
  test_save_workspace_handles_write_failure
  test_save_workspace_preserves_old_data_on_failure

  # Security tests
  test_workspace_directory_permissions
  test_workspace_file_permissions

  teardown_test

  finish_test_suite "orchestration/workspace.sh"
}

# Run tests
main

exit $?
