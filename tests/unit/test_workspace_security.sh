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

# Unit Tests: Workspace Security
# Tests workspace integrity, validation, and security features

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../helpers/test_helpers.sh"
source "$PROJECT_ROOT/scripts/components/core/logging.sh"
source "$PROJECT_ROOT/scripts/components/orchestration/workspace_security.sh"

start_test_suite "Workspace Security"

# Setup: Create test workspace
TEST_WORKSPACE=""
setup_test_workspace() {
  TEST_WORKSPACE=$(mktemp -d)
  mkdir -p "$TEST_WORKSPACE/files"
  mkdir -p "$TEST_WORKSPACE/plugins"
}

cleanup_test_workspace() {
  if [[ -n "$TEST_WORKSPACE" ]] && [[ -d "$TEST_WORKSPACE" ]]; then
    rm -rf "$TEST_WORKSPACE"
  fi
}

# ==============================================================================
# Workspace Structure Validation Tests
# ==============================================================================

test_validate_workspace_structure_success() {
  setup_test_workspace
  
  local result
  if validate_workspace_structure "$TEST_WORKSPACE"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 0 $result "Valid workspace structure should pass"
  
  cleanup_test_workspace
}

test_validate_workspace_structure_missing_files_dir() {
  setup_test_workspace
  rmdir "$TEST_WORKSPACE/files"
  
  local result
  if validate_workspace_structure "$TEST_WORKSPACE"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 1 $result "Missing files directory should fail"
  
  cleanup_test_workspace
}

test_validate_workspace_structure_missing_plugins_dir() {
  setup_test_workspace
  rmdir "$TEST_WORKSPACE/plugins"
  
  local result
  if validate_workspace_structure "$TEST_WORKSPACE"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 1 $result "Missing plugins directory should fail"
  
  cleanup_test_workspace
}

test_validate_workspace_structure_path_traversal() {
  local result
  if validate_workspace_structure "/tmp/../etc"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 1 $result "Path traversal should be rejected"
}

# ==============================================================================
# Permission Validation Tests
# ==============================================================================

test_validate_workspace_permissions_correct() {
  setup_test_workspace
  chmod 700 "$TEST_WORKSPACE"
  chmod 700 "$TEST_WORKSPACE/files"
  chmod 700 "$TEST_WORKSPACE/plugins"
  
  local result
  if validate_workspace_permissions "$TEST_WORKSPACE"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 0 $result "Correct permissions should pass"
  
  cleanup_test_workspace
}

test_validate_workspace_permissions_too_permissive() {
  setup_test_workspace
  chmod 755 "$TEST_WORKSPACE"
  
  local result
  if validate_workspace_permissions "$TEST_WORKSPACE"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 1 $result "Permissive permissions should fail"
  
  cleanup_test_workspace
}

test_validate_workspace_permissions_files_too_permissive() {
  setup_test_workspace
  chmod 700 "$TEST_WORKSPACE"
  echo '{"file_path": "/test", "file_type": "bash", "last_scanned": "2026-01-01"}' > "$TEST_WORKSPACE/files/test.json"
  chmod 644 "$TEST_WORKSPACE/files/test.json"
  
  local result
  if validate_workspace_permissions "$TEST_WORKSPACE"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 1 $result "Permissive file permissions should fail"
  
  cleanup_test_workspace
}

# ==============================================================================
# Permission Hardening Tests
# ==============================================================================

test_harden_workspace_permissions_directory() {
  setup_test_workspace
  chmod 755 "$TEST_WORKSPACE"
  
  harden_workspace_permissions "$TEST_WORKSPACE"
  
  local perms
  perms=$(stat -c '%a' "$TEST_WORKSPACE")
  
  assert_equals "700" "$perms" "Workspace directory should be hardened to 700"
  
  cleanup_test_workspace
}

test_harden_workspace_permissions_files() {
  setup_test_workspace
  echo '{"test": "data"}' > "$TEST_WORKSPACE/files/test.json"
  chmod 644 "$TEST_WORKSPACE/files/test.json"
  
  harden_workspace_permissions "$TEST_WORKSPACE"
  
  local perms
  perms=$(stat -c '%a' "$TEST_WORKSPACE/files/test.json")
  
  assert_equals "600" "$perms" "JSON files should be hardened to 600"
  
  cleanup_test_workspace
}

# ==============================================================================
# JSON Validation Tests
# ==============================================================================

test_validate_workspace_json_valid() {
  setup_test_workspace
  local json_file="$TEST_WORKSPACE/files/valid.json"
  echo '{"file_path": "/test.sh", "file_type": "bash", "last_scanned": "2026-01-01T00:00:00Z"}' > "$json_file"
  
  local result
  if validate_workspace_json "$json_file"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 0 $result "Valid JSON with required fields should pass"
  
  cleanup_test_workspace
}

test_validate_workspace_json_invalid_syntax() {
  setup_test_workspace
  local json_file="$TEST_WORKSPACE/files/invalid.json"
  echo '{"file_path": "/test.sh", invalid json' > "$json_file"
  
  local result
  if validate_workspace_json "$json_file"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 1 $result "Invalid JSON syntax should fail"
  
  cleanup_test_workspace
}

test_validate_workspace_json_missing_file_path() {
  setup_test_workspace
  local json_file="$TEST_WORKSPACE/files/missing_field.json"
  echo '{"file_type": "bash", "last_scanned": "2026-01-01"}' > "$json_file"
  
  local result
  if validate_workspace_json "$json_file"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 1 $result "Missing file_path field should fail"
  
  cleanup_test_workspace
}

test_validate_workspace_json_missing_file_type() {
  setup_test_workspace
  local json_file="$TEST_WORKSPACE/files/missing_field.json"
  echo '{"file_path": "/test.sh", "last_scanned": "2026-01-01"}' > "$json_file"
  
  local result
  if validate_workspace_json "$json_file"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 1 $result "Missing file_type field should fail"
  
  cleanup_test_workspace
}

test_validate_workspace_json_missing_last_scanned() {
  setup_test_workspace
  local json_file="$TEST_WORKSPACE/files/missing_field.json"
  echo '{"file_path": "/test.sh", "file_type": "bash"}' > "$json_file"
  
  local result
  if validate_workspace_json "$json_file"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 1 $result "Missing last_scanned field should fail"
  
  cleanup_test_workspace
}

# ==============================================================================
# Corrupted File Removal Tests
# ==============================================================================

test_remove_corrupted_file_success() {
  setup_test_workspace
  local corrupted_file="$TEST_WORKSPACE/files/corrupted.json"
  echo 'corrupted data' > "$corrupted_file"
  
  remove_corrupted_file "$TEST_WORKSPACE" "$corrupted_file"
  
  if [[ ! -f "$corrupted_file" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Corrupted file should be removed"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Corrupted file should be removed"
  fi
  
  cleanup_test_workspace
}

# ==============================================================================
# File Type Validation Tests
# ==============================================================================

test_validate_file_type_regular_file() {
  setup_test_workspace
  local test_file="$TEST_WORKSPACE/test.sh"
  echo '#!/bin/bash' > "$test_file"
  
  local result
  # Set MAX_FILE_SIZE for test
  MAX_FILE_SIZE=104857600
  SOURCE_DIR="$TEST_WORKSPACE"
  
  if validate_file_type "$test_file"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 0 $result "Regular file should pass validation"
  
  cleanup_test_workspace
}

test_validate_file_type_exceeds_size_limit() {
  setup_test_workspace
  local test_file="$TEST_WORKSPACE/large.sh"
  # Create file larger than limit
  dd if=/dev/zero of="$test_file" bs=1M count=1 2>/dev/null
  
  local result
  # Set small limit for test
  MAX_FILE_SIZE=100
  SOURCE_DIR="$TEST_WORKSPACE"
  
  if validate_file_type "$test_file"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 1 $result "File exceeding size limit should fail"
  
  cleanup_test_workspace
}

test_validate_file_type_symlink_within_bounds() {
  setup_test_workspace
  local target_file="$TEST_WORKSPACE/target.sh"
  local link_file="$TEST_WORKSPACE/link.sh"
  echo '#!/bin/bash' > "$target_file"
  ln -s "$target_file" "$link_file"
  
  local result
  MAX_FILE_SIZE=104857600
  SOURCE_DIR="$TEST_WORKSPACE"
  
  if validate_file_type "$link_file"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 0 $result "Symlink within bounds should pass"
  
  cleanup_test_workspace
}

test_validate_file_type_symlink_outside_bounds() {
  setup_test_workspace
  local target_file="/tmp/external_target.sh"
  local link_file="$TEST_WORKSPACE/link.sh"
  echo '#!/bin/bash' > "$target_file"
  ln -s "$target_file" "$link_file"
  
  local result
  MAX_FILE_SIZE=104857600
  SOURCE_DIR="$TEST_WORKSPACE"
  
  if validate_file_type "$link_file"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 1 $result "Symlink outside bounds should fail"
  
  rm -f "$target_file"
  cleanup_test_workspace
}

# ==============================================================================
# Lock File Cleaning Tests
# ==============================================================================

test_clean_stale_locks_removes_old() {
  setup_test_workspace
  local lock_file="$TEST_WORKSPACE/files/test.lock"
  touch "$lock_file"
  # Make lock file old (366+ seconds old by backdating)
  touch -d "10 minutes ago" "$lock_file"
  
  clean_stale_locks "$TEST_WORKSPACE"
  
  if [[ ! -f "$lock_file" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Stale lock file should be removed"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Stale lock file should be removed"
  fi
  
  cleanup_test_workspace
}

test_clean_stale_locks_keeps_recent() {
  setup_test_workspace
  chmod 700 "$TEST_WORKSPACE/files"
  local lock_file="$TEST_WORKSPACE/files/test.lock"
  touch "$lock_file"
  
  clean_stale_locks "$TEST_WORKSPACE"
  
  if [[ -f "$lock_file" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Recent lock file should be kept"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Recent lock file should be kept"
  fi
  
  cleanup_test_workspace
}

# ==============================================================================
# Integration Tests: verify_workspace_integrity
# ==============================================================================

test_verify_workspace_integrity_success() {
  setup_test_workspace
  chmod 700 "$TEST_WORKSPACE"
  chmod 700 "$TEST_WORKSPACE/files"
  chmod 700 "$TEST_WORKSPACE/plugins"
  
  local result
  if verify_workspace_integrity "$TEST_WORKSPACE"; then
    result=0
  else
    result=$?
  fi
  
  assert_exit_code 0 $result "Valid workspace should pass integrity check"
  
  cleanup_test_workspace
}

test_verify_workspace_integrity_fixes_permissions() {
  setup_test_workspace
  chmod 755 "$TEST_WORKSPACE"
  
  verify_workspace_integrity "$TEST_WORKSPACE"
  
  local perms
  perms=$(stat -c '%a' "$TEST_WORKSPACE")
  
  assert_equals "700" "$perms" "Integrity check should fix permissions"
  
  cleanup_test_workspace
}

test_verify_workspace_integrity_removes_corrupted() {
  setup_test_workspace
  chmod 700 "$TEST_WORKSPACE"
  chmod 700 "$TEST_WORKSPACE/files"
  chmod 700 "$TEST_WORKSPACE/plugins"
  
  local corrupted_file="$TEST_WORKSPACE/files/corrupted.json"
  echo 'invalid json {' > "$corrupted_file"
  chmod 600 "$corrupted_file"
  
  verify_workspace_integrity "$TEST_WORKSPACE"
  
  if [[ ! -f "$corrupted_file" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Integrity check should remove corrupted files"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Integrity check should remove corrupted files"
  fi
  
  cleanup_test_workspace
}

test_verify_workspace_integrity_keeps_valid_json() {
  setup_test_workspace
  chmod 700 "$TEST_WORKSPACE"
  chmod 700 "$TEST_WORKSPACE/files"
  chmod 700 "$TEST_WORKSPACE/plugins"
  
  local valid_file="$TEST_WORKSPACE/files/valid.json"
  echo '{"file_path": "/test.sh", "file_type": "bash", "last_scanned": "2026-01-01"}' > "$valid_file"
  chmod 600 "$valid_file"
  
  verify_workspace_integrity "$TEST_WORKSPACE"
  
  if [[ -f "$valid_file" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Integrity check should keep valid files"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Integrity check should keep valid files"
  fi
  
  cleanup_test_workspace
}

test_verify_workspace_integrity_cleans_stale_locks() {
  setup_test_workspace
  chmod 700 "$TEST_WORKSPACE"
  chmod 700 "$TEST_WORKSPACE/files"
  chmod 700 "$TEST_WORKSPACE/plugins"
  
  local lock_file="$TEST_WORKSPACE/files/stale.lock"
  touch "$lock_file"
  touch -d "10 minutes ago" "$lock_file"
  
  verify_workspace_integrity "$TEST_WORKSPACE"
  
  if [[ ! -f "$lock_file" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: Integrity check should clean stale locks"
  else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: Integrity check should clean stale locks"
  fi
  
  cleanup_test_workspace
}

# ==============================================================================
# Run all tests
# ==============================================================================

# Structure validation
test_validate_workspace_structure_success
test_validate_workspace_structure_missing_files_dir
test_validate_workspace_structure_missing_plugins_dir
test_validate_workspace_structure_path_traversal

# Permission validation
test_validate_workspace_permissions_correct
test_validate_workspace_permissions_too_permissive
test_validate_workspace_permissions_files_too_permissive

# Permission hardening
test_harden_workspace_permissions_directory
test_harden_workspace_permissions_files

# JSON validation
test_validate_workspace_json_valid
test_validate_workspace_json_invalid_syntax
test_validate_workspace_json_missing_file_path
test_validate_workspace_json_missing_file_type
test_validate_workspace_json_missing_last_scanned

# Corrupted file removal
test_remove_corrupted_file_success

# File type validation
test_validate_file_type_regular_file
test_validate_file_type_exceeds_size_limit
test_validate_file_type_symlink_within_bounds
test_validate_file_type_symlink_outside_bounds

# Lock file cleaning
test_clean_stale_locks_removes_old
test_clean_stale_locks_keeps_recent

# Integration tests
test_verify_workspace_integrity_success
test_verify_workspace_integrity_fixes_permissions
test_verify_workspace_integrity_removes_corrupted
test_verify_workspace_integrity_keeps_valid_json
test_verify_workspace_integrity_cleans_stale_locks

finish_test_suite "Workspace Security"
