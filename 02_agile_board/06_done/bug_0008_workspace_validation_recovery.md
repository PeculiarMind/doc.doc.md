# Bug: Workspace Validation Missing Recovery and Plugin Discovery Crash

**ID**: bug_0008_workspace_validation_recovery  
**Status**: Done  
**Created**: 2026-02-14  
**Last Updated**: 2026-02-14  
**Completed**: 2026-02-14

## Overview
Two related issues with error handling: `validate_workspace_schema` didn't recover missing subdirectories, and `discover_plugins` crashed when the plugins directory didn't exist.

## Description

### Issue 1: validate_workspace_schema Missing Recovery
The `validate_workspace_schema()` function only reported missing subdirectories as errors and returned failure. The workspace recovery feature (feature_0046) expects the function to recreate missing subdirectories automatically during validation, similar to how `init_workspace()` handles existing workspaces with missing subdirectories.

### Issue 2: discover_plugins Hard Crash
The `discover_plugins()` function called `error_exit()` when the plugins directory didn't exist, which terminated the entire process. This prevented graceful handling of scenarios like:
- Using `--activate-plugin` with `-p list` when no plugins directory exists
- Plugin directories being temporarily unavailable

### Issue 3: Missing assert_directory_exists Helper
The test helper `test_helpers.sh` was missing an `assert_directory_exists` function used by the workspace recovery tests.

## Resolution
**Fixed**:
1. `validate_workspace_schema` now recreates missing `files/` and `plugins/` subdirectories with appropriate permissions and WARN-level logging
2. `discover_plugins` now logs a WARN message and returns empty list instead of calling `error_exit` when the plugins directory doesn't exist
3. Added `assert_directory_exists` to `tests/helpers/test_helpers.sh`

## Category
- Type: Bug
- Priority: High

## Tests
- All 35 tests in `tests/unit/test_workspace_recovery.sh` pass
- All 60 tests in `tests/unit/test_workspace.sh` pass
- All 36 tests in `tests/unit/test_plugin_active_state.sh` pass (except 1 missing feature)
