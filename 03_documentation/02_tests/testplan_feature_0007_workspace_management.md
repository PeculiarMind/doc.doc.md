# Test Plan: Workspace Management System

**Feature ID**: 0007  
**Feature**: Workspace Management System  
**Test Plan Created**: 2026-02-11  
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

Validate that the workspace management system correctly handles workspace initialization, JSON file operations, lock management, metadata storage, timestamp tracking, integrity verification, error handling, and security permissions.

### Key Validation Goals
1. **Function Existence**: Verify all required workspace functions are defined and available
2. **Workspace Initialization**: Ensure workspaces are created with correct structure and permissions
3. **Data Integrity**: Confirm JSON read/write operations, atomic writes, and corruption handling
4. **Concurrency Safety**: Validate lock acquisition, release, timeout, and stale lock cleanup
5. **Security Compliance**: Verify restrictive directory (0700) and file (0600) permissions

---

## Test Scope

### In Scope
- Unit tests for workspace initialization and directory structure
- File hash generation and consistency validation
- JSON file operations (save, load, pretty-print, validation)
- Lock management (acquire, release, timeout, stale cleanup)
- Metadata storage and plugin data merging
- Timestamp tracking for scan operations
- Integrity verification and corruption recovery
- Error handling for write failures and data preservation
- Security permissions for directories and files

### Out of Scope
- Performance benchmarking (deferred)
- Load testing with concurrent processes (deferred)
- Cross-platform workspace compatibility (deferred)

---

## Test Cases

### TC-01: Function Existence
**Objective**: Verify all 10 required workspace functions are defined  
**Test Files**: `test_workspace.sh`  
**Expected**: init_workspace, generate_file_hash, load_workspace, save_workspace, acquire_lock, release_lock, get_last_scan_time, update_scan_timestamp, remove_corrupted_workspace_file, validate_workspace_schema all exist

### TC-02: Workspace Initialization - Creates Directory
**Objective**: Verify init_workspace creates the workspace directory  
**Test Files**: `test_workspace.sh`  
**Expected**: Directory created, exit code 0

### TC-03: Workspace Initialization - Creates Subdirectories
**Objective**: Verify init_workspace creates standard subdirectories  
**Test Files**: `test_workspace.sh`  
**Expected**: files/ and plugins/ subdirectories created

### TC-04: Workspace Initialization - Validates Writable
**Objective**: Verify workspace directory is writable after initialization  
**Test Files**: `test_workspace.sh`  
**Expected**: Directory has write permission

### TC-05: Workspace Initialization - Handles Existing Gracefully
**Objective**: Verify re-initialization preserves existing workspace data  
**Test Files**: `test_workspace.sh`  
**Expected**: Existing files preserved, exit code 0

### TC-06: Workspace Initialization - Rejects Empty Argument
**Objective**: Verify init_workspace rejects empty directory argument  
**Test Files**: `test_workspace.sh`  
**Expected**: Exit code 1

### TC-07: Workspace Initialization - Rejects Path Traversal
**Objective**: Verify init_workspace rejects path traversal attempts  
**Test Files**: `test_workspace.sh`  
**Expected**: Exit code 1

### TC-08: File Hash Generation - Produces SHA-256 Hash
**Objective**: Verify generate_file_hash produces a valid 64-character SHA-256 hash  
**Test Files**: `test_workspace.sh`  
**Expected**: Non-empty 64-character hex string

### TC-09: File Hash Generation - Consistent Hashing
**Objective**: Verify same file produces same hash on repeated calls  
**Test Files**: `test_workspace.sh`  
**Expected**: Identical hashes for identical content

### TC-10: File Hash Generation - Different Content Different Hashes
**Objective**: Verify different file content produces different hashes  
**Test Files**: `test_workspace.sh`  
**Expected**: Distinct hashes for distinct content

### TC-11: File Hash Generation - Fails for Missing File
**Objective**: Verify generate_file_hash fails for nonexistent file  
**Test Files**: `test_workspace.sh`  
**Expected**: Exit code 1

### TC-12: File Hash Generation - Fails for Empty Argument
**Objective**: Verify generate_file_hash fails for empty argument  
**Test Files**: `test_workspace.sh`  
**Expected**: Exit code 1

### TC-13: JSON File Operations - Writes JSON
**Objective**: Verify save_workspace creates a JSON file in the workspace  
**Test Files**: `test_workspace.sh`  
**Expected**: JSON file created at expected path, exit code 0

### TC-14: JSON File Operations - Writes Valid JSON
**Objective**: Verify saved file contains valid JSON (parseable by jq)  
**Test Files**: `test_workspace.sh`  
**Expected**: jq validates file as valid JSON

### TC-15: JSON File Operations - Pretty-Prints JSON
**Objective**: Verify saved JSON is pretty-printed (multi-line) for readability  
**Test Files**: `test_workspace.sh`  
**Expected**: Output file has more than 1 line

### TC-16: JSON File Operations - Rejects Invalid JSON
**Objective**: Verify save_workspace rejects invalid JSON input  
**Test Files**: `test_workspace.sh`  
**Expected**: Exit code 1

### TC-17: JSON File Operations - Atomic Write
**Objective**: Verify save_workspace performs atomic updates  
**Test Files**: `test_workspace.sh`  
**Expected**: Updated version reflected after overwrite

### TC-18: JSON File Operations - Reads JSON
**Objective**: Verify load_workspace reads and returns correct JSON data  
**Test Files**: `test_workspace.sh`  
**Expected**: Loaded data matches saved data

### TC-19: JSON File Operations - Handles Missing File
**Objective**: Verify load_workspace returns empty JSON object for missing file  
**Test Files**: `test_workspace.sh`  
**Expected**: Returns {}, exit code 0

### TC-20: JSON File Operations - Handles Corrupted JSON
**Objective**: Verify load_workspace handles corrupted JSON files gracefully  
**Test Files**: `test_workspace.sh`  
**Expected**: Returns {}, corrupted file removed

### TC-21: Lock Management - Creates Lock File
**Objective**: Verify acquire_lock creates a lock file  
**Test Files**: `test_workspace.sh`  
**Expected**: .lock file created, exit code 0

### TC-22: Lock Management - Removes Lock After Release
**Objective**: Verify release_lock removes the lock file  
**Test Files**: `test_workspace.sh`  
**Expected**: .lock file removed after release

### TC-23: Lock Management - Timeout When Held
**Objective**: Verify acquire_lock times out when lock is held by another  
**Test Files**: `test_workspace.sh`  
**Expected**: Exit code 1 after timeout

### TC-24: Lock Management - Cleans Stale Locks
**Objective**: Verify acquire_lock cleans stale lock files and acquires lock  
**Test Files**: `test_workspace.sh`  
**Expected**: Stale lock cleaned, new lock acquired, exit code 0

### TC-25: Lock Management - Releases Lock After Save
**Objective**: Verify save_workspace releases lock after writing  
**Test Files**: `test_workspace.sh`  
**Expected**: No .lock file present after save completes

### TC-26: Metadata Storage - Stores File Metadata Fields
**Objective**: Verify workspace stores all required file metadata fields  
**Test Files**: `test_workspace.sh`  
**Expected**: file_path, file_type, file_size correctly stored and retrievable

### TC-27: Metadata Storage - Merge Plugin Data
**Objective**: Verify merge_plugin_data merges plugin results into workspace data  
**Test Files**: `test_workspace.sh`  
**Expected**: Plugin data merged, plugin execution tracked in plugins_executed

### TC-28: Metadata Storage - Plugins Executed Tracks History
**Objective**: Verify plugins_executed array tracks all plugin executions  
**Test Files**: `test_workspace.sh`  
**Expected**: Array length matches number of executed plugins

### TC-29: Timestamp Tracking - Update Scan Timestamp
**Objective**: Verify update_scan_timestamp updates the last_scanned field  
**Test Files**: `test_workspace.sh`  
**Expected**: last_scanned field matches provided timestamp

### TC-30: Timestamp Tracking - Update Full Scan Timestamp
**Objective**: Verify update_full_scan_timestamp stores and retrieves timestamp  
**Test Files**: `test_workspace.sh`  
**Expected**: get_last_scan_time returns the stored timestamp

### TC-31: Timestamp Tracking - Empty Workspace
**Objective**: Verify get_last_scan_time returns empty for workspace without timestamp  
**Test Files**: `test_workspace.sh`  
**Expected**: Returns empty string

### TC-32: Timestamp Tracking - Nonexistent Workspace
**Objective**: Verify get_last_scan_time returns empty for nonexistent workspace  
**Test Files**: `test_workspace.sh`  
**Expected**: Returns empty string

### TC-33: Integrity and Recovery - Remove Corrupted Workspace File
**Objective**: Verify remove_corrupted_workspace_file removes file and associated lock  
**Test Files**: `test_workspace.sh`  
**Expected**: Both .json and .json.lock files removed

### TC-34: Integrity and Recovery - Validate Workspace Schema Valid
**Objective**: Verify validate_workspace_schema passes for valid workspace  
**Test Files**: `test_workspace.sh`  
**Expected**: Exit code 0

### TC-35: Integrity and Recovery - Missing Subdirectories
**Objective**: Verify validate_workspace_schema fails when subdirectories missing  
**Test Files**: `test_workspace.sh`  
**Expected**: Exit code 1

### TC-36: Integrity and Recovery - Removes Corrupted Files
**Objective**: Verify validate_workspace_schema removes corrupted files, preserves valid  
**Test Files**: `test_workspace.sh`  
**Expected**: Corrupted files removed, valid files preserved

### TC-37: Integrity and Recovery - Nonexistent Workspace
**Objective**: Verify validate_workspace_schema fails for nonexistent path  
**Test Files**: `test_workspace.sh`  
**Expected**: Exit code 1

### TC-38: Integrity and Recovery - Empty Argument
**Objective**: Verify validate_workspace_schema fails for empty argument  
**Test Files**: `test_workspace.sh`  
**Expected**: Exit code 1

### TC-39: Error Handling - Handles Write Failure
**Objective**: Verify save_workspace fails gracefully on write error  
**Test Files**: `test_workspace.sh`  
**Expected**: Exit code 1, no crash

### TC-40: Error Handling - Preserves Old Data on Failure
**Objective**: Verify original data preserved when write fails  
**Test Files**: `test_workspace.sh`  
**Expected**: Original version data still present after failed write

### TC-41: Security - Directory Permissions
**Objective**: Verify workspace directory has restrictive permissions  
**Test Files**: `test_workspace.sh`  
**Expected**: Directory permissions are 0700

### TC-42: Security - File Permissions
**Objective**: Verify workspace files have restrictive permissions  
**Test Files**: `test_workspace.sh`  
**Expected**: File permissions are 0600

---

## Test Execution History

| Execution Date | Execution Status | Test Report | Total Tests | Passed | Failed | Notes |
|---------------|------------------|-------------|-------------|--------|--------|-------|
| 2026-02-11 | ✅ Passed | [Report 1](testreport_feature_0007_workspace_management_20260211.01.md) | 60 | 60 | 0 | Initial test execution |

---

## Test Coverage Summary

| Component | Test File | Coverage |
|-----------|-----------|----------|
| orchestration/workspace.sh | test_workspace.sh | ✅ Complete |

---

## Success Criteria

- [x] All 60 tests execute successfully
- [x] Workspace initialization creates correct directory structure
- [x] File hash generation produces consistent SHA-256 hashes
- [x] JSON read/write operations handle valid and invalid data
- [x] Lock management prevents concurrent access
- [x] Metadata storage and plugin data merging verified
- [x] Timestamp tracking for scan operations validated
- [x] Integrity verification and corruption recovery working
- [x] Error handling preserves data on failure
- [x] Security permissions enforced (0700 directories, 0600 files)

---

## References

- **Feature**: [feature_0007_workspace_management.md](../../02_agile_board/06_done/feature_0007_workspace_management.md)
- **Requirement**: [req_0059_workspace_recovery_and_rescan.md](../../01_vision/02_requirements/03_accepted/req_0059_workspace_recovery_and_rescan.md)
- **Requirement**: [req_0025_incremental_analysis.md](../../01_vision/02_requirements/03_accepted/req_0025_incremental_analysis.md)
- **Requirement**: [req_0050_workspace_integrity_verification.md](../../01_vision/02_requirements/03_accepted/req_0050_workspace_integrity_verification.md)
- **Requirement**: [req_0023_data_driven_execution_flow.md](../../01_vision/02_requirements/03_accepted/req_0023_data_driven_execution_flow.md)

---

**Test Plan Version**: 1.0  
**Last Updated**: 2026-02-11  
**Next Review**: After next feature implementation requiring workspace changes
