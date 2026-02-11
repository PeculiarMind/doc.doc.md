# Requirement: Workspace Recovery and Rescan

**ID**: req_0059

## Status
State: Accepted  
Created: 2026-02-11  
Last Updated: 2026-02-11

## Overview
The system shall keep workspace state recoverable without migrations by rebuilding or re-scanning when data is invalid.

## Description
Workspace state is derived from source files and can be rebuilt by scanning again. If a workspace JSON file cannot be parsed, the system removes that file and treats the source file as unscanned so it will be processed again on the next run. Workspace recovery must favor forward progress and avoid blocking analysis on corrupted or stale state.

## Category
- Type: Functional
- Priority: High

## Acceptance Criteria

### Initialization and Validation
- [ ] Workspace directory is created when missing and `-w` is specified
- [ ] Missing subdirectories are recreated automatically with a warning
- [ ] Workspace validation does not require migrations

### Corruption Handling
- [ ] On JSON parse failure, the corresponding workspace file is removed
- [ ] Removed workspace files are treated as unscanned in the next analysis run
- [ ] Corruption events are logged with file path and reason

### Recovery and Rebuild
- [ ] If workspace state is incompatible or unreadable, the system can rebuild by re-scanning
- [ ] Recovery never blocks analysis if the workspace can be safely rebuilt

### Atomic Operations
- [ ] JSON writes use atomic temp-file + rename
- [ ] Locking prevents concurrent writes to the same workspace file
- [ ] Interrupted operations leave no partial JSON files

### Error Handling
- [ ] Permission and disk errors are reported with actionable messages
- [ ] Read-only workspace locations fail cleanly without crashing

## Related Requirements
- req_0001 (Single Command Directory Analysis)
- req_0003 (Metadata Extraction)
- req_0018 (Per-File Reports)
- req_0025 (Incremental Analysis)
- req_0023 (Data-driven Execution Flow)

## Transition History
- [2026-02-11] Created in accepted by user request  
-- Comment: Replaces migration-based workspace handling with rescan-based recovery
