# Bug: Workspace Initialization Logging Invisible in Legacy Mode

**ID**: bug_0007_workspace_init_logging  
**Status**: Done  
**Created**: 2026-02-14  
**Last Updated**: 2026-02-14  
**Completed**: 2026-02-14

## Overview
The workspace creation log message was invisible when IS_INTERACTIVE was not set (legacy mode), because it was logged at INFO level which is only shown in verbose mode.

## Description
When `init_workspace()` creates a new workspace directory, it logged the event at INFO level:
```
log "INFO" "WORKSPACE" "Initializing workspace: $workspace_dir"
```

In legacy mode (IS_INTERACTIVE not set, VERBOSE not true), INFO messages are suppressed by the `_log_legacy()` function. This meant workspace creation — a significant operational event — was not visible to users.

## Resolution
**Fixed**: Changed the log level for workspace creation from INFO to WARN, making it visible in all logging modes. The message was also updated to "Creating workspace directory" for clarity.

## Category
- Type: Bug
- Priority: Low

## Tests
- All 35 tests in `tests/unit/test_workspace_recovery.sh` pass
- All 60 tests in `tests/unit/test_workspace.sh` pass
