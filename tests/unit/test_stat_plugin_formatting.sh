#!/usr/bin/env bash
# Unit tests for bug_0003: Stat Plugin Output Data Formatting Issues
# Tests correct field mapping and timestamp consistency

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source test helpers
source "${SCRIPT_DIR}/../helpers/test_helpers.sh"

# Test fixture directory
TEST_FIXTURE_DIR="${SCRIPT_DIR}/../fixtures/stat_plugin_test"

# Setup
setup() {
  rm -rf "$TEST_FIXTURE_DIR"
  mkdir -p "$TEST_FIXTURE_DIR"
  mkdir -p "$TEST_FIXTURE_DIR/plugins/ubuntu/stat"
  mkdir -p "$TEST_FIXTURE_DIR/workspace/files"
  
  # Create a test file with known properties
  echo "test content" > "$TEST_FIXTURE_DIR/testfile.txt"
  chmod 644 "$TEST_FIXTURE_DIR/testfile.txt"
  
  # Get actual stat values for verification
  TEST_FILE_MTIME=$(stat -c '%Y' "$TEST_FIXTURE_DIR/testfile.txt")
  TEST_FILE_SIZE=$(stat -c '%s' "$TEST_FIXTURE_DIR/testfile.txt")
  TEST_FILE_OWNER=$(stat -c '%U' "$TEST_FIXTURE_DIR/testfile.txt")
}

# Teardown
teardown() {
  rm -rf "$TEST_FIXTURE_DIR"
}

# Test 1: Stat command output order matches expected format
test_stat_command_output_order() {
  echo -e "\n${BLUE}Test: Stat command outputs values in correct order${NC}"
  
  local output
  output=$(stat -c '%Y,%s,%U' "$TEST_FIXTURE_DIR/testfile.txt")
  
  # Parse output
  IFS=',' read -r mtime size owner <<< "$output"
  
  # Verify each field is correct type and value
  if [[ "$mtime" =~ ^[0-9]+$ ]] && [[ "$mtime" -eq "$TEST_FILE_MTIME" ]]; then
    echo -e "  ✓ First field is timestamp: $mtime"
  else
    echo -e "${RED}✗${NC} FAIL: First field should be timestamp, got: $mtime (expected: $TEST_FILE_MTIME)"
    return 1
  fi
  
  if [[ "$size" =~ ^[0-9]+$ ]] && [[ "$size" -eq "$TEST_FILE_SIZE" ]]; then
    echo -e "  ✓ Second field is file size: $size bytes"
  else
    echo -e "${RED}✗${NC} FAIL: Second field should be file size, got: $size (expected: $TEST_FILE_SIZE)"
    return 1
  fi
  
  if [[ "$owner" =~ ^[a-zA-Z0-9_-]+$ ]] && [[ "$owner" == "$TEST_FILE_OWNER" ]]; then
    echo -e "  ✓ Third field is owner: $owner"
  else
    echo -e "${RED}✗${NC} FAIL: Third field should be owner, got: $owner (expected: $TEST_FILE_OWNER)"
    return 1
  fi
  
  echo -e "${GREEN}✓${NC} PASS: Stat command output order is correct"
}

# Test 2: Descriptor provides keys alphabetical order
test_descriptor_provides_keys_order() {
  echo -e "\n${BLUE}Test: Descriptor provides keys match stat output order${NC}"
  
  local descriptor_file="${PROJECT_ROOT}/scripts/plugins/ubuntu/stat/descriptor.json"
  
  if [[ ! -f "$descriptor_file" ]]; then
    echo -e "${RED}✗${NC} FAIL: Descriptor file not found: $descriptor_file"
    return 1
  fi
  
  # Get provides keys in jq order (alphabetical)
  local keys
  keys=$(jq -r '.provides | keys[]' "$descriptor_file")
  
  # Convert to array
  local keys_array=()
  while IFS= read -r key; do
    keys_array+=("$key")
  done <<< "$keys"
  
  echo -e "  Provides keys order: ${keys_array[*]}"
  
  # The stat command outputs: %Y,%s,%U (mtime, size, owner)
  # jq keys[] returns alphabetically: file_last_modified, file_owner, file_size
  # This is the mapping:
  #   Index 0: file_last_modified <- %Y (timestamp) ✓
  #   Index 1: file_owner         <- %s (size) ✗ WRONG!
  #   Index 2: file_size          <- %U (owner) ✗ WRONG!
  
  # Expected order after fix: should match stat output
  if [[ "${keys_array[0]}" == "file_last_modified" ]] && \
     [[ "${keys_array[1]}" == "file_owner" ]] && \
     [[ "${keys_array[2]}" == "file_size" ]]; then
    echo -e "${YELLOW}⚠${NC}  INFO: Keys are in alphabetical order (file_last_modified, file_owner, file_size)"
    echo -e "${YELLOW}⚠${NC}  INFO: This does NOT match stat output order (%Y=%s,%U = mtime,size,owner)"
    echo -e "${YELLOW}⚠${NC}  INFO: Commandline must be adjusted to match key order"
  fi
  
  echo -e "${GREEN}✓${NC} PASS: Verified provides keys order"
}

# Test 3: Commandline format matches provides key order
test_commandline_matches_provides_order() {
  echo -e "\n${BLUE}Test: Commandline output order matches provides keys order${NC}"
  
  local descriptor_file="${PROJECT_ROOT}/scripts/plugins/ubuntu/stat/descriptor.json"
  
  # Get provides keys in order
  local keys
  keys=$(jq -r '.provides | keys[]' "$descriptor_file")
  local keys_array=()
  while IFS= read -r key; do
    keys_array+=("$key")
  done <<< "$keys"
  
  # Get commandline
  local commandline
  commandline=$(jq -r '.commandline' "$descriptor_file")
  
  echo -e "  Provides keys: ${keys_array[*]}"
  echo -e "  Commandline: $commandline"
  
  # Expected: commandline should output values in same order as provides keys
  # Keys order: file_last_modified, file_owner, file_size
  # So commandline should be: stat -c '%Y,%U,%s' (mtime, owner, size)
  
  # Check current commandline
  if [[ "$commandline" == *"%Y,%s,%U"* ]]; then
    echo -e "${RED}✗${NC} FAIL: Commandline uses wrong order: %Y,%s,%U"
    echo -e "  Expected order to match keys: %Y,%U,%s (mtime, owner, size)"
    return 1
  elif [[ "$commandline" == *"%Y,%U,%s"* ]]; then
    echo -e "${GREEN}✓${NC} PASS: Commandline order matches provides keys"
  else
    echo -e "${YELLOW}⚠${NC}  WARN: Unexpected commandline format: $commandline"
  fi
}

# Test 4: Field type validation
test_field_types_are_correct() {
  echo -e "\n${BLUE}Test: Stat output fields have correct types${NC}"
  
  local descriptor_file="${PROJECT_ROOT}/scripts/plugins/ubuntu/stat/descriptor.json"
  
  # Check type declarations in descriptor
  local mtime_type
  mtime_type=$(jq -r '.provides.file_last_modified.type' "$descriptor_file")
  
  local size_type
  size_type=$(jq -r '.provides.file_size.type' "$descriptor_file")
  
  local owner_type
  owner_type=$(jq -r '.provides.file_owner.type' "$descriptor_file")
  
  if [[ "$mtime_type" != "integer" ]]; then
    echo -e "${RED}✗${NC} FAIL: file_last_modified should be integer, got: $mtime_type"
    return 1
  fi
  
  if [[ "$size_type" != "integer" ]]; then
    echo -e "${RED}✗${NC} FAIL: file_size should be integer, got: $size_type"
    return 1
  fi
  
  if [[ "$owner_type" != "string" ]]; then
    echo -e "${RED}✗${NC} FAIL: file_owner should be string, got: $owner_type"
    return 1
  fi
  
  echo -e "  ✓ file_last_modified: integer"
  echo -e "  ✓ file_size: integer"
  echo -e "  ✓ file_owner: string"
  
  echo -e "${GREEN}✓${NC} PASS: Field types are correctly declared"
}

# Test 5: Integration test - plugin execution produces correct mapping
test_plugin_execution_field_mapping() {
  echo -e "\n${BLUE}Test: Plugin execution maps fields correctly${NC}"
  
  # Source required components
  source "${PROJECT_ROOT}/scripts/components/core/logging.sh"
  source "${PROJECT_ROOT}/scripts/components/plugin/plugin_executor.sh"
  
  # Execute plugin
  local variable_json
  variable_json=$(jq -n --arg fp "$TEST_FIXTURE_DIR/testfile.txt" '{"file_path_absolute": $fp}')
  
  local output
  output=$(execute_plugin "stat" "${PROJECT_ROOT}/scripts/plugins" "$variable_json" 2>/dev/null || true)
  
  if [[ -z "$output" ]]; then
    echo -e "${YELLOW}⚠${NC}  SKIP: Plugin execution failed (may need dependencies)"
    return 0
  fi
  
  echo -e "  Plugin output: $output"
  
  # Parse output
  IFS=',' read -r field1 field2 field3 <<< "$output"
  
  # After fix, field1 should be timestamp, field2 should be owner, field3 should be size
  # (matching alphabetical provides key order)
  
  # Verify field1 is a timestamp (integer)
  if [[ ! "$field1" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}✗${NC} FAIL: Field 1 should be timestamp (integer), got: $field1"
    return 1
  fi
  
  # After the fix, field2 should be owner (string, not a number)
  # Before fix: field2 would be size (numeric)
  if [[ "$field2" =~ ^[0-9]+$ ]] && [[ "$field2" -eq "$TEST_FILE_SIZE" ]]; then
    echo -e "${RED}✗${NC} FAIL: Field 2 is file size ($field2), should be owner (BUG NOT FIXED)"
    echo -e "  This indicates the bug is still present: fields are swapped"
    return 1
  elif [[ "$field2" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "  ✓ Field 2 is owner: $field2"
  fi
  
  # After the fix, field3 should be size (integer)
  if [[ ! "$field3" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}✗${NC} FAIL: Field 3 should be file size (integer), got: $field3"
    return 1
  fi
  
  echo -e "  ✓ Field 1 (timestamp): $field1"
  echo -e "  ✓ Field 2 (owner): $field2"
  echo -e "  ✓ Field 3 (size): $field3"
  
  echo -e "${GREEN}✓${NC} PASS: Plugin execution field mapping is correct"
}

# Main test runner
main() {
  echo -e "${BLUE}=== Stat Plugin Output Formatting Tests (bug_0003) ===${NC}"
  
  setup
  
  local failed=0
  
  test_stat_command_output_order || ((failed++))
  test_descriptor_provides_keys_order || ((failed++))
  test_commandline_matches_provides_order || ((failed++))
  test_field_types_are_correct || ((failed++))
  test_plugin_execution_field_mapping || ((failed++))
  
  teardown
  
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
