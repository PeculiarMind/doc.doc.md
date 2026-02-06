# Test Suite for doc.doc.sh - Feature 0001: Basic Script Structure

## Overview
This directory contains comprehensive tests for the doc.doc.sh script following Test-Driven Development (TDD) principles.

## Test Structure

```
tests/
├── run_all_tests.sh              # Master test runner
├── helpers/
│   └── test_helpers.sh           # Shared test utilities and assertions
├── unit/                         # Unit tests (individual components)
│   ├── test_script_structure.sh
│   ├── test_help_system.sh
│   ├── test_version.sh
│   ├── test_argument_parsing.sh
│   ├── test_exit_codes.sh
│   ├── test_verbose_logging.sh
│   ├── test_platform_detection.sh
│   └── test_error_handling.sh
├── integration/                  # Integration tests (components together)
│   └── test_complete_workflow.sh
├── system/                       # System tests (end-to-end scenarios)
│   └── test_user_scenarios.sh
└── fixtures/                     # Test data (currently empty)
```

## Running Tests

### Run All Tests
```bash
./tests/run_all_tests.sh
```

### Run Individual Test Suites
```bash
# Unit tests
./tests/unit/test_script_structure.sh
./tests/unit/test_help_system.sh
./tests/unit/test_version.sh
./tests/unit/test_argument_parsing.sh
./tests/unit/test_exit_codes.sh
./tests/unit/test_verbose_logging.sh
./tests/unit/test_platform_detection.sh
./tests/unit/test_error_handling.sh

# Integration tests
./tests/integration/test_complete_workflow.sh

# System tests
./tests/system/test_user_scenarios.sh
```

## Test Coverage

### Unit Tests (8 suites)
1. **Script Structure** - Tests shebang, constants, strict mode, modular functions
2. **Help System** - Tests -h/--help flags, help content, formatting
3. **Version Information** - Tests --version flag, semantic versioning, copyright
4. **Argument Parsing** - Tests flag recognition, invalid arguments, error handling
5. **Exit Codes** - Tests all 6 exit codes (0-5) are properly defined and used
6. **Verbose Logging** - Tests -v flag, log function, log levels, stderr routing
7. **Platform Detection** - Tests detect_platform function, fallback logic
8. **Error Handling** - Tests bash strict mode, error messages, exit codes

### Integration Tests (1 suite)
9. **Complete Workflow** - Tests multiple components working together

### System Tests (1 suite)
10. **User Scenarios** - Tests complete end-to-end user interactions

## Test Requirements Coverage

### Acceptance Criteria Covered

#### Script Structure (9 criteria)
- ✅ Proper shebang line
- ✅ Usage/help function
- ✅ Argument parsing logic
- ✅ Version information
- ✅ Error handling patterns
- ✅ Bash best practices (strict mode)
- ✅ Script is executable
- ✅ Clear comments
- ✅ Modular functions

#### Argument Parsing Framework (8 criteria)
- ✅ -h/--help displays usage and exits with code 0
- ✅ -v/--verbose flag recognized
- ✅ Invalid arguments show error and exit with code 1
- ✅ Unknown options show error message
- ✅ Both short and long option formats
- ✅ Error messages for invalid input

#### Help System (6 criteria)
- ✅ Shows script name and description
- ✅ Shows usage syntax
- ✅ Lists available options with descriptions
- ✅ Includes usage examples
- ✅ Formatted for readability
- ✅ Output to stdout when requested

#### Version Information (3 criteria)
- ✅ --version displays version number
- ✅ Includes copyright and license
- ✅ Follows semantic versioning

#### Exit Codes (7 criteria)
- ✅ EXIT_SUCCESS=0
- ✅ EXIT_INVALID_ARGS=1
- ✅ EXIT_FILE_ERROR=2
- ✅ EXIT_PLUGIN_ERROR=3
- ✅ EXIT_REPORT_ERROR=4
- ✅ EXIT_WORKSPACE_ERROR=5
- ✅ Exit codes documented

#### Platform Detection (5 criteria)
- ✅ Detects platform using /etc/os-release or uname
- ✅ Platform stored in variable
- ✅ Handles missing /etc/os-release
- ✅ Defaults to "generic" on failure
- ✅ Platform detection logged in verbose mode

#### Verbose Mode Infrastructure (6 criteria)
- ✅ Verbose flag sets VERBOSE variable
- ✅ Log function created
- ✅ Log function checks VERBOSE flag
- ✅ Verbose output to stderr
- ✅ Consistent prefix format
- ✅ Log levels supported (INFO, WARN, ERROR, DEBUG)

#### Error Handling (5 criteria)
- ✅ Global error handling
- ✅ Errors output to stderr
- ✅ Error messages include context
- ✅ Appropriate exit codes
- ✅ Graceful error handling

#### Code Quality (6 criteria)
- ✅ Functions are small and focused
- ✅ Meaningful variable names
- ✅ Constants defined at top
- ✅ Consistent indentation
- ✅ No hardcoded paths
- ✅ Script location determined dynamically

**Total Coverage: 55 acceptance criteria tested**

## TDD Workflow

### Current Phase: RED 🔴
All tests are expected to **FAIL** at this stage because the `doc.doc.sh` script has not been implemented yet.

This is the correct and expected behavior in Test-Driven Development:
1. **RED Phase** (Current) - Write tests that define expected behavior → Tests FAIL
2. **GREEN Phase** (Next) - Implement minimal code to make tests pass → Tests PASS
3. **REFACTOR Phase** (Final) - Improve code quality while keeping tests passing

### Expected Test Results (RED Phase)
```
❌ All test suites should FAIL
❌ Individual assertions will fail
✅ Test infrastructure itself works correctly
```

### Next Steps (GREEN Phase)
The Developer Agent will now implement the `doc.doc.sh` script to satisfy all these tests. Tests will guide the implementation.

## Test Framework

These tests use a custom bash testing framework (test_helpers.sh) with the following assertions:
- `assert_equals` - Compare two values
- `assert_contains` - Check if string contains substring
- `assert_not_contains` - Check if string doesn't contain substring
- `assert_exit_code` - Verify exit code
- `assert_file_exists` - Check file existence
- `assert_file_executable` - Check file is executable

## Exit Codes

Test scripts use these exit codes:
- `0` - All tests in suite passed
- `1` - One or more tests failed

The master runner (`run_all_tests.sh`) returns:
- `0` - All tests failed (RED phase) OR all tests passed (GREEN phase)
- `1` - Mixed results (partial implementation)

## Notes for Developers

1. **Run tests frequently** during implementation
2. **Implement incrementally** - make one test pass at a time
3. **Don't modify tests** unless requirements change
4. **Tests define the contract** - implementation must satisfy them
5. **All tests must pass** before feature is considered complete

## Maintenance

When updating tests:
1. Update this README to reflect changes
2. Ensure test coverage percentage remains high
3. Keep tests independent and isolated
4. Document any new test utilities added
