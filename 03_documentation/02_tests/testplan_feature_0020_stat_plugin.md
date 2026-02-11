# Test Plan: File Statistics Plugin (stat)

**Feature ID**: 0020  
**Feature**: File Statistics Plugin  
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

Validate the stat plugin implementation including descriptor compliance with unified plugin schema (ADR-0010), tool availability checking, installation script correctness, and file statistics extraction functionality.

### Key Validation Goals
1. **Descriptor Compliance**: Verify descriptor follows unified plugin schema with correct consumes/provides
2. **Tool Check**: Verify `check_commandline` correctly detects stat availability
3. **Install Script**: Verify `install.sh` handles pre-installed and missing stat scenarios
4. **File Statistics**: Verify extraction of last modified time, file size, and owner
5. **Plugin Visibility**: Verify stat plugin appears in plugin listing

---

## Test Scope

### In Scope
- Descriptor validation (required fields, data types, schema compliance)
- Tool check command execution (stat availability)
- Install script idempotency
- Plugin visibility in plugin listing output
- Consumes/provides field correctness
- Command template variable substitution pattern

### Out of Scope
- Full stat execution with sandbox (requires end-to-end integration)
- Platform-specific stat syntax variations (macOS/BSD)
- Performance testing with large file sets
- Dedicated stat output parsing tests (deferred to integration)

---

## Test Cases

### TC-01: Plugin Visibility in Listing
**Objective**: Verify stat plugin appears in `doc.doc.md --list-plugins` output  
**Test File**: `tests/unit/test_plugin_listing.sh`  
**Acceptance Criteria**: [Plugin Structure]  
**Expected**: stat plugin listed with name and description

### TC-02: Descriptor Required Fields
**Objective**: Verify descriptor contains all required fields per ADR-0010  
**Test File**: `tests/unit/test_plugin_validation.sh` (validates schema patterns)  
**Acceptance Criteria**: [Descriptor Requirements]  
**Expected**: name, description, active, commandline, check_commandline, install_commandline, consumes, provides all present

### TC-03: Descriptor Name Field
**Objective**: Verify descriptor name is "stat" (matches directory name)  
**Test File**: `tests/unit/test_plugin_validation.sh`  
**Acceptance Criteria**: [Descriptor Requirements]  
**Expected**: Name field is "stat", matches `^[a-zA-Z0-9_-]{3,50}$`

### TC-04: Consumes Field Correctness
**Objective**: Verify consumes declares `file_path_absolute` with type and description  
**Test File**: `tests/unit/test_plugin_validation.sh`  
**Acceptance Criteria**: [Descriptor Requirements]  
**Expected**: consumes.file_path_absolute has type "string" and description

### TC-05: Provides Field Correctness
**Objective**: Verify provides declares file_last_modified, file_size, file_owner  
**Test File**: `tests/unit/test_plugin_validation.sh`  
**Acceptance Criteria**: [Descriptor Requirements]  
**Expected**: Three provides fields with correct types (integer, integer, string)

### TC-06: Tool Check Command
**Objective**: Verify check_commandline detects stat availability  
**Test File**: `tests/unit/test_tool_verification.sh`  
**Acceptance Criteria**: [Descriptor Requirements]  
**Expected**: check_commandline returns success on system with stat installed

### TC-07: Install Script Idempotency
**Objective**: Verify install.sh succeeds when stat is already installed  
**Test File**: (Manual verification / deferred)  
**Acceptance Criteria**: [Plugin Structure]  
**Expected**: install.sh exits 0 without unnecessary reinstallation

### TC-08: Universal File Processing
**Objective**: Verify processes field allows execution for all file types  
**Test File**: `tests/unit/test_plugin_executor.sh` (file filtering tests)  
**Acceptance Criteria**: [File Type Filtering]  
**Expected**: Empty/universal processes field matches all files

---

## Test Execution History

| Execution Date | Execution Status | Test Report | Total Tests | Passed | Failed | Notes |
|---------------|------------------|-------------|-------------|--------|--------|-------|
| 2026-02-11 | ✅ Passed | [Report 1](testreport_feature_0009_0011_0012_0020_20260211.01.md) | 8 | 8 | 0 | Plugin listing tests verify stat visibility |

---

## Test Coverage Summary

| Component | Test File | Tests | Coverage |
|-----------|-----------|-------|----------|
| Plugin Listing (stat visibility) | test_plugin_listing.sh | 8 | Plugin discovery and listing |

---

## Coverage Gaps

| Gap | Reason | Priority |
|-----|--------|----------|
| Dedicated stat execution tests | Requires executor integration testing | High |
| Output parsing validation | Requires end-to-end plugin execution | High |
| Error handling (missing files, permission denied) | Requires sandbox integration | Medium |
| Files with special characters in paths | Requires executor variable substitution | Medium |

---

## References

- **Feature**: [feature_0020_stat_plugin.md](../../02_agile_board/05_implementing/feature_0020_stat_plugin.md)
- **Requirement**: [req_0022_plugin_based_extensibility.md](../../01_vision/02_requirements/03_accepted/req_0022_plugin_based_extensibility.md)
- **Requirement**: [req_0023_data_driven_execution_flow.md](../../01_vision/02_requirements/03_accepted/req_0023_data_driven_execution_flow.md)
- **Requirement**: [req_0025_incremental_analysis.md](../../01_vision/02_requirements/03_accepted/req_0025_incremental_analysis.md)

---

**Test Plan Version**: 1.0  
**Last Updated**: 2026-02-11  
**Next Review**: After dedicated stat execution tests are implemented
