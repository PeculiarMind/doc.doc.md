# Test Plan: Plugin Execution System

**Feature IDs**: 0009, 0011, 0012  
**Features**: Plugin Execution Engine, Tool Availability Verification, Plugin Security Validation  
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

Validate the plugin execution system comprising the execution engine (dependency graph construction, topological sort, file filtering, variable substitution, plugin execution), tool availability verification (detection, status reporting, install guidance), and plugin security validation (descriptor schema, injection prevention, sandbox compatibility, data type validation).

### Key Validation Goals
1. **Dependency Graph**: Verify topological sort produces correct execution order based on consumes/provides
2. **Circular Detection**: Confirm circular dependencies are detected and rejected
3. **File Filtering**: Verify plugins execute only for matching file types (MIME/extension)
4. **Variable Substitution Security**: Validate secure variable replacement preventing injection
5. **Plugin Execution**: Confirm plugins execute with correct environment and results are captured
6. **Tool Verification**: Verify available/missing tool detection and platform-specific guidance
7. **Descriptor Validation**: Confirm schema validation, injection pattern detection, and sandbox checks

---

## Test Scope

### In Scope
- Unit tests for dependency graph ordering (topological sort)
- Unit tests for circular dependency detection
- Unit tests for file type filtering (MIME type and extension matching)
- Unit tests for secure variable substitution
- Unit tests for plugin execution flow
- Unit tests for tool availability checking (`command -v` pattern)
- Unit tests for missing tool detection and status reporting
- Unit tests for install guidance generation
- Unit tests for descriptor schema validation (required fields, field types)
- Unit tests for command injection pattern detection
- Unit tests for path traversal prevention
- Unit tests for sandbox compatibility validation
- Unit tests for data type validation in consumes/provides

### Out of Scope
- Integration tests for full end-to-end orchestration with workspace (deferred)
- Interactive installation prompt tests (TTY dependency)
- Performance benchmarking of execution engine (deferred)
- Cross-platform installation guidance testing (deferred)
- Circular dependency detection with multiple plugin chains (deferred)

---

## Test Cases

### Feature 0009: Plugin Execution Engine

#### TC-01: Dependency Graph - Topological Sort Order
**Objective**: Verify plugins are ordered so dependencies execute before consumers  
**Test File**: `tests/unit/test_plugin_executor.sh`  
**Acceptance Criteria**: [Dependency Graph Construction], [Topological Sort]  
**Expected**: Provider plugins appear before consumer plugins in execution order

#### TC-02: Dependency Graph - Independent Plugins
**Objective**: Verify plugins with no dependencies can execute in any order  
**Test File**: `tests/unit/test_plugin_executor.sh`  
**Acceptance Criteria**: [Dependency Graph Construction]  
**Expected**: Independent plugins included in execution order, exit code 0

#### TC-03: Dependency Graph - Multiple Dependencies
**Objective**: Verify plugins with multiple dependencies wait for all providers  
**Test File**: `tests/unit/test_plugin_executor.sh`  
**Acceptance Criteria**: [Dependency Graph Construction]  
**Expected**: Consumer executes only after all providing plugins

#### TC-04: Circular Dependency Detection
**Objective**: Verify circular dependencies in consumes/provides chains are detected  
**Test File**: `tests/unit/test_plugin_executor.sh`  
**Acceptance Criteria**: [Dependency Graph Construction]  
**Expected**: Non-zero exit code, error message identifies cycle

#### TC-05: File Type Filtering - MIME Type Match
**Objective**: Verify plugins execute only for files matching declared MIME types  
**Test File**: `tests/unit/test_plugin_executor.sh`  
**Acceptance Criteria**: [Plugin Filtering]  
**Expected**: Plugin skipped for non-matching MIME types

#### TC-06: File Type Filtering - Extension Match
**Objective**: Verify plugins match files by extension from `processes.file_extensions`  
**Test File**: `tests/unit/test_plugin_executor.sh`  
**Acceptance Criteria**: [Plugin Filtering]  
**Expected**: Plugin executes for matching extension, skips for non-matching

#### TC-07: File Type Filtering - Universal Plugin
**Objective**: Verify plugins with empty `processes` field execute for all files  
**Test File**: `tests/unit/test_plugin_executor.sh`  
**Acceptance Criteria**: [Plugin Filtering]  
**Expected**: Plugin executes regardless of file type

#### TC-08: Variable Substitution - Safe Replacement
**Objective**: Verify `${variable_name}` patterns are replaced with workspace values  
**Test File**: `tests/unit/test_plugin_executor.sh`  
**Acceptance Criteria**: [Execution Environment Setup]  
**Expected**: Variables replaced correctly, no shell expansion

#### TC-09: Variable Substitution - Injection Prevention
**Objective**: Verify variable values containing shell metacharacters are safely handled  
**Test File**: `tests/unit/test_plugin_executor.sh`  
**Acceptance Criteria**: [Security Requirements]  
**Expected**: Metacharacters escaped/quoted, no command injection

#### TC-10: Variable Substitution - Undeclared Variable Rejection
**Objective**: Verify undeclared variables in templates are not substituted  
**Test File**: `tests/unit/test_plugin_executor.sh`  
**Acceptance Criteria**: [Strict Input Validation]  
**Expected**: Undeclared variables remain literal or cause error

#### TC-11 through TC-18: Plugin Execution Flow
**Objective**: Verify plugin execution, result capture, error handling, timeout enforcement  
**Test File**: `tests/unit/test_plugin_executor.sh`  
**Acceptance Criteria**: [Plugin Execution], [Result Capture], [Error Handling]  
**Expected**: Plugins execute, output captured, failures handled gracefully

### Feature 0011: Tool Availability Verification

#### TC-19: Available Tool Detection
**Objective**: Verify system detects tools available on the system  
**Test File**: `tests/unit/test_tool_verification.sh`  
**Acceptance Criteria**: [Tool Availability Check]  
**Expected**: Available tools reported with "available" status

#### TC-20: Missing Tool Detection
**Objective**: Verify system detects tools not installed on the system  
**Test File**: `tests/unit/test_tool_verification.sh`  
**Acceptance Criteria**: [Tool Availability Check]  
**Expected**: Missing tools reported with "missing" status

#### TC-21: Tool Status Report
**Objective**: Verify status report summarizes available and missing tools  
**Test File**: `tests/unit/test_tool_verification.sh`  
**Acceptance Criteria**: [Missing Tool Reporting]  
**Expected**: Report lists each tool with status and requiring plugin

#### TC-22: Install Guidance Generation
**Objective**: Verify platform-specific installation commands are provided  
**Test File**: `tests/unit/test_tool_verification.sh`  
**Acceptance Criteria**: [Platform-Specific Installation Guidance]  
**Expected**: Correct package manager command for detected platform

#### TC-23: verify_plugin_tools Integration
**Objective**: Verify verify_plugin_tools function processes plugin descriptors  
**Test File**: `tests/unit/test_tool_verification.sh`  
**Acceptance Criteria**: [Plugin Integration]  
**Expected**: Plugin tools checked, status aggregated correctly

#### TC-24 through TC-26: Additional Tool Verification
**Objective**: Verify edge cases: empty descriptors, multiple tools, check command failures  
**Test File**: `tests/unit/test_tool_verification.sh`  
**Acceptance Criteria**: [Error Handling], [Tool Discovery]  
**Expected**: Graceful handling of all edge cases

### Feature 0012: Plugin Security Validation

#### TC-27: Valid Descriptor Acceptance
**Objective**: Verify a correctly formed descriptor passes validation  
**Test File**: `tests/unit/test_plugin_validation.sh`  
**Acceptance Criteria**: [Schema Validation]  
**Expected**: Exit code 0, descriptor accepted

#### TC-28: Missing Required Fields
**Objective**: Verify descriptors missing required fields are rejected  
**Test File**: `tests/unit/test_plugin_validation.sh`  
**Acceptance Criteria**: [Schema Validation]  
**Expected**: Exit code 1, error identifies missing field

#### TC-29: Invalid Plugin Name
**Objective**: Verify names violating `^[a-zA-Z0-9_-]{3,50}$` pattern are rejected  
**Test File**: `tests/unit/test_plugin_validation.sh`  
**Acceptance Criteria**: [Schema Validation]  
**Expected**: Exit code 1, error identifies invalid name

#### TC-30: Command Injection Detection
**Objective**: Verify command templates with injection patterns (`;`, `&&`, `$()`, backticks) are rejected  
**Test File**: `tests/unit/test_plugin_validation.sh`  
**Acceptance Criteria**: [Command Template Security]  
**Expected**: Exit code 1, error identifies unsafe pattern

#### TC-31: Path Traversal Detection
**Objective**: Verify descriptors with `..` path traversal attempts are rejected  
**Test File**: `tests/unit/test_plugin_validation.sh`  
**Acceptance Criteria**: [Path Validation]  
**Expected**: Exit code 1, path traversal blocked

#### TC-32: Sandbox Incompatibility Detection
**Objective**: Verify commands requiring network, /proc, sudo are flagged  
**Test File**: `tests/unit/test_plugin_validation.sh`  
**Acceptance Criteria**: [Sandbox Compliance Validation]  
**Expected**: Exit code 1, sandbox violation reported

#### TC-33: Invalid Data Types
**Objective**: Verify invalid type declarations in consumes/provides are rejected  
**Test File**: `tests/unit/test_plugin_validation.sh`  
**Acceptance Criteria**: [Data Type Validation]  
**Expected**: Exit code 1, invalid type identified

#### TC-34: Install Command Validation
**Objective**: Verify install commands using non-package-manager patterns are rejected  
**Test File**: `tests/unit/test_plugin_validation.sh`  
**Acceptance Criteria**: [Command Template Security]  
**Expected**: Exit code 1 for non-package-manager install commands

---

## Test Execution History

| Execution Date | Execution Status | Test Report | Total Tests | Passed | Failed | Notes |
|---------------|------------------|-------------|-------------|--------|--------|-------|
| 2026-02-11 | ✅ Passed | [Report 1](testreport_feature_0009_0011_0012_0020_20260211.01.md) | 34 | 34 | 0 | Initial test execution - unit tests only |

---

## Test Coverage Summary

| Component | Test File | Tests | Coverage |
|-----------|-----------|-------|----------|
| Plugin Executor | test_plugin_executor.sh | 18 | Dependency graph, filtering, substitution, execution |
| Tool Verification | test_tool_verification.sh | 8 | Availability checking, status reporting, guidance |
| Plugin Validation | test_plugin_validation.sh | 8 | Schema, injection, traversal, sandbox, data types |

---

## Coverage Gaps

| Gap | Reason | Priority |
|-----|--------|----------|
| Integration tests for full orchestration with workspace | Requires workspace component integration | High |
| Interactive installation prompt tests | TTY dependency in CI | Medium |
| Circular dependency detection with multi-plugin chains | Deferred to integration testing | Medium |
| End-to-end sandbox execution tests | Requires Bubblewrap availability | High |

---

## References

- **Feature 0009**: [feature_0009_plugin_execution_engine.md](../../02_agile_board/05_implementing/feature_0009_plugin_execution_engine.md)
- **Feature 0011**: [feature_0011_tool_verification.md](../../02_agile_board/05_implementing/feature_0011_tool_verification.md)
- **Feature 0012**: [feature_0012_plugin_security_validation.md](../../02_agile_board/05_implementing/feature_0012_plugin_security_validation.md)
- **Requirement**: [req_0023_data_driven_execution_flow.md](../../01_vision/02_requirements/03_accepted/req_0023_data_driven_execution_flow.md)
- **Requirement**: [req_0024_plugin_dependency_graph_construction.md](../../01_vision/02_requirements/03_accepted/req_0024_plugin_dependency_graph_construction.md)
- **Requirement**: [req_0007_tool_availability_verification.md](../../01_vision/02_requirements/03_accepted/req_0007_tool_availability_verification.md)
- **Requirement**: [req_0047_plugin_descriptor_validation.md](../../01_vision/02_requirements/03_accepted/req_0047_plugin_descriptor_validation.md)
- **Requirement**: [req_0049_template_injection_prevention.md](../../01_vision/02_requirements/03_accepted/req_0049_template_injection_prevention.md)

---

**Test Plan Version**: 1.0  
**Last Updated**: 2026-02-11  
**Next Review**: After integration tests are implemented
