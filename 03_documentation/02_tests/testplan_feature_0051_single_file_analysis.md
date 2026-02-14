# Test Plan: Single-File Analysis Mode

**Feature ID**: 0051  
**Feature**: Single-File Analysis Mode  
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

Validate the single-file analysis mode feature that enables users to analyze individual files through the CLI using the `-f` flag, with full integration into the workspace system, plugin execution framework, and report generation pipeline.

### Key Validation Goals
1. **CLI Flag Support**: Verify `-f` flag acceptance and file path argument handling
2. **File Validation**: Confirm file existence checks, error handling, and path resolution
3. **MIME Type Detection**: Validate MIME type detection for various file formats
4. **Plugin Execution**: Verify plugins execute correctly on single files with proper filtering
5. **Result Generation**: Confirm workspace integration and report generation
6. **Plugin Flag Integration**: Validate `--activate-plugin` and `--deactivate-plugin` work with single-file mode
7. **Edge Cases**: Verify robustness with empty files, large files, special characters, symlinks, and read-only files
8. **Workspace Integration**: Confirm proper workspace structure creation and multi-file support

---

## Test Scope

### In Scope
- Unit tests for `-f` flag parsing and acceptance
- Unit tests for file existence validation and error messages
- Unit tests for directory vs. file detection
- Unit tests for relative and absolute path resolution
- Unit tests for MIME type detection (text, markdown, JSON, shell scripts)
- Unit tests for plugin execution on single files (active/inactive filtering)
- Unit tests for plugin file type filtering (MIME types and extensions)
- Unit tests for workspace result generation
- Unit tests for report generation after single-file analysis
- Unit tests for `--activate-plugin` and `--deactivate-plugin` flag integration
- Unit tests for edge cases (empty files, large files, special characters, symlinks, read-only files)
- Unit tests for workspace structure creation and reuse
- Unit tests for multiple files analyzed to same workspace

### Out of Scope
- Integration tests for full end-to-end single-file analysis with real plugins (deferred)
- Performance benchmarking of single-file analysis vs. directory analysis (deferred)
- Plugin MIME type filtering implementation (requires feature_0044_plugin_file_type_filtering)
- Cross-platform path resolution testing (deferred)
- Binary file analysis (deferred)

---

## Test Cases

### Category: CLI Single-File Flag Support

#### TC-01: Single File Flag Accepted
**Objective**: Verify `-f` flag is recognized and accepted by the CLI parser  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: CLI accepts `-f` flag without "unrecognized option" or "invalid option" errors  
**Expected**: Flag accepted, no option parsing errors

#### TC-02: Single File Flag Accepts Path Argument
**Objective**: Verify `-f` flag accepts a file path as its argument  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Flag accepts file path without "requires an argument" or "missing argument" errors  
**Expected**: File path argument accepted

#### TC-03: Single-File Mode Works with Workspace Directory
**Objective**: Verify single-file mode integrates with workspace directory (`-w` flag)  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Workspace directory is created/used for single-file analysis  
**Expected**: Workspace directory exists after analysis

#### TC-04: Single-File Mode Recognized
**Objective**: Verify script recognizes single-file mode vs. directory scan mode  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Script does not perform directory scan when `-f` is specified  
**Expected**: No "Scanning directory" message or single-file indicator present

### Category: File Existence and Error Handling

#### TC-05: Non-Existent File Error
**Objective**: Verify non-existent file produces clear error message  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Error message indicates file not found or does not exist  
**Expected**: Non-zero exit code or "not found"/"does not exist" error message

#### TC-06: Error Message Includes File Path
**Objective**: Verify error message includes the requested file path  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Error message contains the file path user requested  
**Expected**: File path appears in error output

#### TC-07: Directory Path Produces Error
**Objective**: Verify directory path to `-f` flag produces error  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Non-zero exit code or error message indicating directory not accepted  
**Expected**: Error when directory given instead of file

#### TC-08: Relative File Path Resolved
**Objective**: Verify relative file paths are resolved correctly  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Relative paths (e.g., `./test.txt`) are resolved and accepted  
**Expected**: Relative path resolves without "not found" error

### Category: MIME Type Detection

#### TC-09: MIME Type Detection - Text File
**Objective**: Verify MIME type detected for plain text files  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Text file MIME type detected (e.g., text/plain)  
**Expected**: Analysis completes successfully

#### TC-10: MIME Type Detection - Markdown File
**Objective**: Verify MIME type detected for markdown files  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Markdown MIME type detected (e.g., text/markdown)  
**Expected**: Analysis completes successfully

#### TC-11: MIME Type Detection - JSON File
**Objective**: Verify MIME type detected for JSON files  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: JSON MIME type detected (e.g., application/json)  
**Expected**: Analysis completes successfully

#### TC-12: MIME Type Detection - Shell Script
**Objective**: Verify MIME type detected for executable shell scripts  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Script MIME type detected (e.g., text/x-shellscript)  
**Expected**: Analysis completes successfully

### Category: Plugin Execution

#### TC-13: Active Plugins Executed on Single File
**Objective**: Verify active plugins execute on single file  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Active plugin appears in output or executes successfully  
**Expected**: Active plugin executed

#### TC-14: Inactive Plugins Not Executed on Single File
**Objective**: Verify inactive plugins are skipped on single file  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Inactive plugin does not appear in output or is skipped  
**Expected**: Inactive plugin not executed

#### TC-15: Plugin Execution Respects File Type Filters
**Objective**: Verify plugins filter by MIME types and file extensions  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Plugin with `mime_types: ["text/markdown"]` executes on `.md` but not `.txt`  
**Expected**: Plugin executes only for matching file types  
**Dependencies**: Requires feature_0044_plugin_file_type_filtering  
**Status**: ⚠️ Expected failure until feature_0044 implemented

### Category: Result Generation

#### TC-16: Results Generated in Workspace
**Objective**: Verify results are generated in workspace directory  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Workspace contains result files after analysis  
**Expected**: Workspace directory contains JSON or result files

#### TC-17: Workspace File Created for Analyzed File
**Objective**: Verify workspace entry created for analyzed file  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Workspace contains file entry for analyzed file  
**Expected**: At least one JSON file in workspace

#### TC-18: Report Generated After Analysis
**Objective**: Verify report generated or analysis completion confirmed  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Output mentions "report" or "complete" or "Analysis"  
**Expected**: Report generation or completion confirmed

### Category: Plugin Flag Integration

#### TC-19: Activate Plugin Flag with Single-File Mode
**Objective**: Verify `--activate-plugin` flag works with single-file mode  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Previously inactive plugin executes when activated  
**Expected**: Plugin appears in output or executes

#### TC-20: Deactivate Plugin Flag with Single-File Mode
**Objective**: Verify `--deactivate-plugin` flag works with single-file mode  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Previously active plugin does not execute when deactivated  
**Expected**: Plugin does not appear in output

#### TC-21: Multiple Plugin Flags with Single-File Mode
**Objective**: Verify multiple plugin activation/deactivation flags work together  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Both activation and deactivation flags honored  
**Expected**: Correct plugins execute based on flags

### Category: Edge Cases and Robustness

#### TC-22: Empty File Handled
**Objective**: Verify empty file is handled gracefully  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Empty file does not cause error  
**Expected**: Exit code 0, no error messages

#### TC-23: Large File Handled
**Objective**: Verify large file (1MB+) is handled  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Large file analyzed without error  
**Expected**: Exit code 0, no error messages

#### TC-24: File with Special Characters in Name
**Objective**: Verify file with spaces in name is handled  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: File with spaces or special characters analyzed  
**Expected**: Exit code 0, no "not found" error

#### TC-25: Symlink to File Followed
**Objective**: Verify symlink to file is followed and analyzed  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Symlink resolved and target file analyzed  
**Expected**: Exit code 0, no "not found" error

#### TC-26: Read-Only File Analyzed
**Objective**: Verify read-only file (permissions 444) is analyzed  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Read-only file analyzed without permission error  
**Expected**: Exit code 0

#### TC-27: Single-File Mode No Sibling Scan
**Objective**: Verify single-file mode does not scan sibling files  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Only specified file analyzed, not siblings in same directory  
**Expected**: One workspace entry (or minimal entries)

### Category: Workspace Integration

#### TC-28: Workspace Structure Created
**Objective**: Verify single-file analysis creates workspace structure  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Workspace subdirectories (e.g., `files/`) created  
**Expected**: Workspace directory structure exists

#### TC-29: Single-File Re-Analysis Uses Cache
**Objective**: Verify re-analyzing same file uses cached workspace  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Second analysis completes (cache behavior may vary)  
**Expected**: Exit code 0

#### TC-30: Different Files Same Workspace
**Objective**: Verify multiple files can be analyzed to same workspace  
**Test File**: `tests/unit/test_single_file_analysis.sh`  
**Acceptance Criteria**: Workspace contains entries for both files  
**Expected**: At least 2 JSON files in workspace

---

## Test Execution History

| Execution Date | Execution Status | Test Report | Total Tests | Passed | Failed | Notes |
|---------------|------------------|-------------|-------------|--------|--------|-------|
| 2026-02-14 | ⚠️ Partial Pass | [Report 1](testreport_feature_0051_single_file_analysis_20260214.01.md) | 30 | 29 | 1 | TC-15 expected failure (feature_0044 dependency) |

---

## Test Coverage Summary

| Component | Test File | Tests | Coverage |
|-----------|-----------|-------|----------|
| CLI Flag Support | test_single_file_analysis.sh | 4 | Flag parsing, workspace integration, mode recognition |
| File Validation | test_single_file_analysis.sh | 4 | Existence checks, error handling, path resolution |
| MIME Detection | test_single_file_analysis.sh | 4 | Text, markdown, JSON, shell script detection |
| Plugin Execution | test_single_file_analysis.sh | 3 | Active/inactive filtering, file type filtering |
| Result Generation | test_single_file_analysis.sh | 3 | Workspace results, file entries, report generation |
| Plugin Flags | test_single_file_analysis.sh | 3 | Activate, deactivate, multiple flags |
| Edge Cases | test_single_file_analysis.sh | 6 | Empty, large, special chars, symlinks, read-only, isolation |
| Workspace Integration | test_single_file_analysis.sh | 3 | Structure creation, caching, multi-file support |

---

## Coverage Gaps

| Gap | Reason | Priority |
|-----|--------|----------|
| Plugin file type filtering (TC-15) | Requires feature_0044_plugin_file_type_filtering implementation | High |
| Integration tests with real plugins | Deferred to end-to-end testing | High |
| Performance comparison single-file vs. directory | Deferred to performance testing | Low |
| Binary file analysis | Out of current scope | Medium |
| Cross-platform path resolution | Deferred to platform testing | Medium |

---

## References

- **Feature 0051**: [feature_0051_single_file_analysis_mode.md](../../02_agile_board/06_done/feature_0051_single_file_analysis_mode.md)
- **Requirement**: [req_0078_single_file_analysis_mode.md](../../01_vision/02_requirements/03_accepted/req_0078_single_file_analysis_mode.md)
- **Related Feature**: [feature_0044_plugin_file_type_filtering.md](../../02_agile_board/04_backlog/feature_0044_plugin_file_type_filtering.md) (dependency for TC-15)

---

**Test Plan Version**: 1.0  
**Last Updated**: 2026-02-14  
**Next Review**: After feature_0044 implementation
