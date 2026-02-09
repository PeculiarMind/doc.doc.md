# Requirement: Workspace Directory Management

**ID**: req_0032

## Status
State: Accepted  
Created: 2026-02-09  
Last Updated: 2026-02-09

## Overview
The system shall provide workspace directory management including initialization, structure creation, validation, corruption recovery, and cleanup operations.

## Description
While workspace functionality is referenced in multiple requirements (req_0001, req_0003, req_0018, req_0025), there is no explicit requirement defining workspace directory lifecycle and management operations. The workspace serves as a persistent data layer storing JSON metadata, timestamps, and analysis state. The system must initialize workspace directories when they don't exist, validate structure on startup, detect and recover from corruption, and provide cleanup mechanisms for obsolete data. Workspace operations must be atomic and safe, preventing corruption during concurrent access or interruption.

## Motivation
From the vision: "Stores document metadata and scan state in the workspace directory (`-w`) as JSON files for later processing. Records timestamps and metadata (last scan time, document information) for incremental analysis and tool integration."

From ADR-0002: "Use JSON files in a workspace directory to persist analysis results and metadata. Each analyzed file gets its own JSON file identified by content hash."

Multiple requirements reference workspace functionality, but none define the foundational workspace management operations that make those features possible. Without proper workspace management, incremental analysis (req_0025), state persistence (req_0018), and plugin data exchange (req_0023) cannot function reliably.

## Category
- Type: Functional
- Priority: High

## Acceptance Criteria

### Initialization
- [ ] The system creates workspace directory structure if it doesn't exist when `-w` is specified
- [ ] Workspace initialization is atomic (completes fully or fails cleanly)
- [ ] Workspace directory permissions are set appropriately (user read/write only)
- [ ] Workspace metadata file (workspace.json) is created with version information

### Structure Validation
- [ ] The system validates workspace structure on startup before analysis begins
- [ ] Missing subdirectories are recreated automatically with warning logged
- [ ] Workspace version is checked for compatibility with current tool version
- [ ] Invalid workspace structure results in clear error message with recovery options

### Corruption Detection and Recovery
- [ ] The system detects corrupted JSON files in workspace (invalid syntax, truncated files)
- [ ] Corrupted files are quarantined (moved to corruption/ subdirectory) not deleted
- [ ] Analysis continues with healthy workspace files after corruption detected
- [ ] Recovery log clearly documents which files were corrupted and recovery actions taken
- [ ] User can optionally force full workspace rebuild via command-line flag

### Atomic Operations
- [ ] JSON file writes use atomic operations (write to temp, then rename)
- [ ] File locking prevents concurrent writes to same JSON file
- [ ] Interrupted operations leave workspace in consistent state (no partial writes)
- [ ] Lock files are cleaned up on normal exit and detected/handled on abnormal termination

### Cleanup and Maintenance
- [ ] The system provides command-line option to remove workspace files for deleted source files
- [ ] Workspace size can be queried via command-line option
- [ ] Obsolete workspace format versions can be migrated to current format
- [ ] Complete workspace reset option available (preserves structure, removes data)

### Error Handling
- [ ] Workspace directory creation failures result in clear error messages with specific cause
- [ ] Insufficient disk space during workspace operations detected and reported
- [ ] Permission errors accessing workspace directory reported with actionable guidance
- [ ] Workspace on read-only filesystem results in appropriate error, not crash

## Related Requirements
- req_0001 (Single Command Directory Analysis) - requires `-w` workspace parameter
- req_0003 (Metadata Extraction) - stores metadata in workspace as JSON
- req_0018 (Per-File Reports) - stores file metadata in workspace JSON files
- req_0025 (Incremental Analysis) - depends on workspace timestamp tracking
- req_0023 (Data-driven Execution Flow) - plugins read/write workspace data

## Technical Considerations

### Workspace Structure
```
workspace/
├── workspace.json              # Workspace metadata and version
├── files/                      # File-specific metadata
│   ├── abc123def456.json      # Content hash as filename
│   ├── abc123def456.json.lock # Lock file during write
│   └── fed654cba321.json
├── plugins/                    # Plugin-specific data
│   ├── metadata-extractor/
│   └── content-analyzer/
├── corruption/                 # Quarantined corrupted files
│   └── abc123def456.json.corrupted.2026-02-09
└── .workspace-version          # Format version marker
```

### Recovery Operations
- Detect corrupted JSON: Try parsing, catch errors
- Quarantine: Move to corruption/ with timestamp suffix
- Continue: Process with remaining valid files
- Log: Document corruption detection and recovery actions
- User guidance: Suggest `-f fullscan` to regenerate corrupted data

## Transition History
- [2026-02-09] Created and placed in Funnel by Requirements Engineer Agent  
-- Comment: Gap identified - workspace extensively referenced but management operations not formalized
- [2026-02-09] Moved to Accepted by user  
-- Comment: Accepted as operational requirement for workspace lifecycle management
