# Test Plan: Workspace Recovery and Rescan

**Feature ID**: 0046  
**Feature**: Workspace Recovery and Rescan  
**Test Plan Created**: 2026-02-14  
**Test Plan Owner**: Tester Agent  
**Status**: Active

---

## Table of Contents
- [Objective](#objective)
- [Test Scope](#test-scope)
- [Test Cases](#test-cases)
- [Test Execution History](#test-execution-history)

---

## Objective

Validate the workspace recovery and rescan system that ensures workspace state remains recoverable without migrations by rebuilding or re-scanning when data is invalid, ensuring forward progress and avoiding blocking on corrupted state.

### Key Validation Goals
1. **Workspace Directory Creation**: Verify workspace directory is created when missing with `-w` flag
2. **Subdirectory Recreation**: Confirm missing subdirectories are automatically recreated with warnings
3. **JSON Parse Error Handling**: Validate corrupted JSON files are detected and removed
4. **Source File Re-scanning**: Verify removed workspace files are treated as unscanned
5. **Corruption Logging**: Confirm corruption events are logged with file path and reason
6. **Validation Without Migrations**: Verify workspace validation succeeds without requiring migrations
7. **System Continuation**: Confirm analysis continues after workspace recovery

---

## Test Scope

### In Scope
- Unit tests for workspace directory creation with `-w` flag
- Unit tests for subdirectory recreation when missing
- Unit tests for JSON parse failure detection
- Unit tests for corrupted workspace file removal
- Unit tests for source file re-scanning after corruption
- Unit tests for corruption event logging
- Unit tests for validation without migrations
- Unit tests for system continuation after recovery
- Edge cases: empty JSON, large corrupted files, special characters, concurrent corruption

### Out of Scope
- Integration tests with full orchestration flow (deferred)
- Performance benchmarking of workspace recovery (deferred)
- Migration system testing (explicitly not required by design)
- Multi-process concurrent write conflict handling (deferred)

---

## Test Cases

### Workspace Directory Creation with -w Flag

#### TC-01: Workspace Directory Created When Missing
**Objective**: Verify workspace directory is created when it doesn't exist and `-w` flag is used  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Workspace directory is created when missing and `-w` is specified]  
**Expected**: init_workspace creates directory, exit code 0

#### TC-02: Workspace Directory Creation Logs Event
**Objective**: Verify workspace directory creation is logged  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Workspace directory is created when missing and `-w` is specified]  
**Expected**: Output contains "Creating workspace directory" or similar message

#### TC-03: Workspace Initialization Creates All Required Subdirectories
**Objective**: Verify all required subdirectories (files/, plugins/) are created  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Workspace directory is created when missing and `-w` is specified]  
**Expected**: files/ and plugins/ subdirectories exist after init_workspace

### Subdirectory Recreation with Warning

#### TC-04: Missing Subdirectories Recreated Automatically
**Objective**: Verify missing subdirectories are recreated during validation  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Missing subdirectories are recreated automatically with a warning]  
**Expected**: validate_workspace_schema recreates missing subdirectories

#### TC-05: Subdirectory Recreation Logs Warning
**Objective**: Verify subdirectory recreation produces a warning message  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Missing subdirectories are recreated automatically with a warning]  
**Expected**: Output contains "warning", "recreating", or "missing" message

#### TC-06: Workspace Validation Succeeds After Subdirectory Recreation
**Objective**: Verify validation completes successfully after recreating subdirectories  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Missing subdirectories are recreated automatically with a warning]  
**Expected**: validate_workspace_schema returns exit code 0

### JSON Parse Error Handling

#### TC-07: JSON Parse Failure Detected
**Objective**: Verify corrupted JSON is detected during load_workspace  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [On JSON parse failure, the corresponding workspace file is removed]  
**Expected**: load_workspace detects parse failure, returns empty object

#### TC-08: Malformed JSON Handled Gracefully
**Objective**: Verify various malformed JSON formats are handled without crashes  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [On JSON parse failure, the corresponding workspace file is removed]  
**Expected**: All malformed JSON returns empty object "{}"

#### TC-09: Incomplete JSON Structure Detected
**Objective**: Verify incomplete JSON (truncated files) is detected  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [On JSON parse failure, the corresponding workspace file is removed]  
**Expected**: Incomplete JSON returns empty object

### Corrupted Workspace File Removal

#### TC-10: Corrupted File Removed on Parse Failure
**Objective**: Verify corrupted workspace files are removed from disk  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [On JSON parse failure, the corresponding workspace file is removed]  
**Expected**: Corrupted JSON file no longer exists after load_workspace

#### TC-11: Corrupted File Removal Preserves Valid Files
**Objective**: Verify only corrupted files are removed, valid files remain  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [On JSON parse failure, the corresponding workspace file is removed]  
**Expected**: Corrupted file removed, valid files preserved

#### TC-12: Corrupted File Lock Removed with File
**Objective**: Verify lock files are removed along with corrupted workspace files  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [On JSON parse failure, the corresponding workspace file is removed]  
**Expected**: Both .json and .json.lock files removed

### Source File Re-scanning After Removal

#### TC-13: Removed File Treated as Unscanned
**Objective**: Verify removed workspace files are treated as if never scanned  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Removed workspace files are treated as unscanned in the next analysis run]  
**Expected**: load_workspace returns empty object for removed file

#### TC-14: Rescan After Corruption Creates Fresh State
**Objective**: Verify fresh workspace data can be saved after corruption removal  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Removed workspace files are treated as unscanned in the next analysis run]  
**Expected**: New workspace data saved and loaded successfully

#### TC-15: Multiple Corrupted Files Handled Independently
**Objective**: Verify each corrupted file is handled independently  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Removed workspace files are treated as unscanned in the next analysis run]  
**Expected**: Multiple corrupted files removed, valid files preserved

### Corruption Event Logging

#### TC-16: Corruption Event Logged with File Path
**Objective**: Verify corruption events include the file path  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Corruption events are logged with file path and reason]  
**Expected**: Log output contains file path identifier

#### TC-17: Corruption Event Logged with Reason
**Objective**: Verify corruption events include the reason  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Corruption events are logged with file path and reason]  
**Expected**: Log output contains "parse", "invalid", or "corrupt" reason

#### TC-18: remove_corrupted_workspace_file Logs Path and Reason
**Objective**: Verify explicit removal function logs complete information  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Corruption events are logged with file path and reason]  
**Expected**: Output contains both file path and removal reason

#### TC-19: Validation Logs All Corrupted Files
**Objective**: Verify workspace validation logs all detected corrupted files  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Corruption events are logged with file path and reason]  
**Expected**: Multiple corrupted files appear in validation output

### Validation Without Migrations

#### TC-20: Validation Succeeds Without Migration
**Objective**: Verify workspace validation does not require migration system  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Workspace validation does not require migrations]  
**Expected**: validate_workspace_schema succeeds without migration metadata

#### TC-21: Validation Does Not Require Schema Version
**Objective**: Verify workspace files do not require schema version field  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Workspace validation does not require migrations]  
**Expected**: Validation succeeds without schema_version field

#### TC-22: Validation Accepts Any Valid JSON Structure
**Objective**: Verify validation accepts any valid JSON structure  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Workspace validation does not require migrations]  
**Expected**: Simple, nested, and array JSON all accepted

#### TC-23: Old Workspace Data Compatible with New Code
**Objective**: Verify backward compatibility with old workspace formats  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Workspace validation does not require migrations]  
**Expected**: Old format workspace data loads successfully

### System Continues After Recovery

#### TC-24: System Continues Analysis After Corruption Removal
**Objective**: Verify system continues with valid files after removing corrupted ones  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [System continues analysis after workspace recovery]  
**Expected**: validate_workspace_schema succeeds, valid files remain

#### TC-25: Recovery Allows Subsequent Operations
**Objective**: Verify new workspace operations work after recovery  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [System continues analysis after workspace recovery]  
**Expected**: save_workspace succeeds after corruption removal

#### TC-26: Multiple Recovery Cycles Work
**Objective**: Verify recovery can be performed multiple times on same file  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [System continues analysis after workspace recovery]  
**Expected**: Multiple corrupt-recover cycles succeed

### Edge Cases and Robustness

#### TC-27: Empty JSON File Handled
**Objective**: Verify empty JSON files are handled gracefully  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [On JSON parse failure, the corresponding workspace file is removed]  
**Expected**: Empty file returns empty object

#### TC-28: Very Large Corrupted File Removed
**Objective**: Verify large corrupted files (1MB+) are removed successfully  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [On JSON parse failure, the corresponding workspace file is removed]  
**Expected**: Large corrupted file removed without errors

#### TC-29: Special Characters in Corrupted Data
**Objective**: Verify special characters in corrupted data don't cause crashes  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [On JSON parse failure, the corresponding workspace file is removed]  
**Expected**: Special characters handled, no crashes

#### TC-30: Concurrent Corruption Detection
**Objective**: Verify multiple corrupted files can be detected concurrently  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [On JSON parse failure, the corresponding workspace file is removed]  
**Expected**: All corrupted files removed, no race conditions

#### TC-31: Workspace Recovery with Nested Paths
**Objective**: Verify workspace creation works with deeply nested paths  
**Test File**: `tests/unit/test_workspace_recovery.sh`  
**Acceptance Criteria**: [Workspace directory is created when missing and `-w` is specified]  
**Expected**: Nested directories created successfully

---

## Test Execution History

| Execution Date | Execution Status | Test Report | Total Tests | Passed | Failed | Notes |
|---------------|------------------|-------------|-------------|--------|--------|-------|
| 2026-02-14 | ✅ Passed | [Report 1](testreport_feature_0046_workspace_recovery_20260214.01.md) | 35 | 35 | 0 | Initial test execution - all acceptance criteria validated |

---

## Test Coverage Summary

| Component | Test File | Tests | Coverage |
|-----------|-----------|-------|----------|
| Workspace Recovery | test_workspace_recovery.sh | 35 | Directory creation, subdirectory recreation, JSON parse error handling, file removal, re-scanning, corruption logging, validation without migrations, system continuation, edge cases |

---

## Coverage Gaps

| Gap | Reason | Priority |
|-----|--------|----------|
| Integration tests with full orchestration | Requires workspace component integration | High |
| Performance benchmarking of recovery operations | Deferred to performance testing | Low |
| Multi-process concurrent write conflict handling | Requires complex process synchronization | Medium |

---

## References

- **Feature 0046**: [feature_0046_workspace_recovery.md](../../02_agile_board/05_implementing/feature_0046_workspace_recovery.md)
- **Requirement**: [req_0059_workspace_recovery_and_rescan.md](../../01_vision/02_requirements/03_accepted/req_0059_workspace_recovery_and_rescan.md)
- **Related Requirement**: [req_0007_tool_availability_verification.md](../../01_vision/02_requirements/03_accepted/req_0007_tool_availability_verification.md) - Workspace Management
- **Related Requirement**: [req_0025_incremental_analysis.md](../../01_vision/02_requirements/03_accepted/req_0025_incremental_analysis.md) - Incremental Analysis
- **Related Requirement**: [req_0064_comprehensive_error_handling_recovery.md](../../01_vision/02_requirements/03_accepted/req_0064_comprehensive_error_handling_recovery.md) - Error Handling

---

**Test Plan Version**: 1.0  
**Last Updated**: 2026-02-14  
**Next Review**: After integration tests are implemented
