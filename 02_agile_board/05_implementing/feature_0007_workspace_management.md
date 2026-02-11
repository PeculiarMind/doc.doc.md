# Feature: Workspace Management System

**ID**: 0007  
**Type**: Feature Implementation  
**Status**: Implementing  
**Created**: 2026-02-09  
**Updated**: 2026-02-11 (Moved to implementing)  
**Priority**: Critical

## Overview
Implement the workspace directory management system that creates, maintains, and validates workspace structures for storing analysis metadata, scan timestamps, and plugin results as JSON files.

## Description
Create the workspace management subsystem that handles all operations related to the workspace directory: initialization, directory structure creation, JSON file read/write with atomic operations and locking, timestamp tracking, integrity verification, and corruption recovery via rescan. The workspace serves as the persistent data layer enabling incremental analysis, plugin data exchange, and downstream tool integration.

This feature implements the foundation for stateful operation, allowing the toolkit to track what has been analyzed, store incremental results, and provide a consumable data format for external tools.

## Business Value
- Enables incremental analysis, dramatically reducing processing time for subsequent runs
- Provides persistent storage for analysis results accessible by external tools
- Enables plugin data exchange through structured JSON format
- Supports debugging and auditing through historical data
- Critical dependency for core workflow functionality

## Related Requirements
- [req_0059](../../01_vision/02_requirements/03_accepted/req_0059_workspace_recovery_and_rescan.md) - Workspace Recovery and Rescan (PRIMARY)
- [req_0025](../../01_vision/02_requirements/03_accepted/req_0025_incremental_analysis.md) - Incremental Analysis Support
- [req_0050](../../01_vision/02_requirements/03_accepted/req_0050_workspace_integrity_verification.md) - Workspace Integrity Verification
- [req_0023](../../01_vision/02_requirements/03_accepted/req_0023_data_driven_execution_flow.md) - Data-driven Execution (uses workspace)

## Acceptance Criteria

### Workspace Initialization
- [ ] System creates workspace directory if it doesn't exist
- [ ] System creates standard subdirectory structure: `files/` and `plugins/`
- [ ] System validates workspace directory is writable
- [ ] System handles existing workspace gracefully (no reinitialize if valid)

### JSON File Operations
- [ ] System generates content-based hash for file identification (SHA-256 or similar)
- [ ] System stores per-file metadata as `files/<hash>.json`
- [ ] System writes JSON atomically using temp file + rename pattern
- [ ] System uses lock files (`<hash>.json.lock`) to prevent concurrent access
- [ ] System implements timeout for lock acquisition (fail if lock held too long)
- [ ] System validates JSON syntax before writing
- [ ] System pretty-prints JSON for readability (if not performance-critical)

### Metadata Storage
- [ ] System stores required file metadata fields:
  - `file_path` (absolute path)
  - `file_path_relative` (relative to source directory)
  - `file_type` (MIME type)
  - `file_size` (bytes)
  - `file_last_modified` (timestamp)
  - `last_scanned` (timestamp)
- [ ] System stores plugin execution results dynamically
- [ ] System merges new plugin data with existing workspace data
- [ ] System maintains `plugins_executed` array tracking execution history

### Timestamp Tracking
- [ ] System records last scan timestamp for each file
- [ ] System records last full scan timestamp for workspace
- [ ] System provides query function to get last scan time for incremental analysis
- [ ] System updates timestamps on successful analysis completion

### Read Operations
- [ ] System loads workspace JSON for specified file hash
- [ ] System validates JSON syntax when loading
- [ ] System returns structured data (associative array in bash or equivalent)
- [ ] System handles missing workspace files gracefully (empty data)
- [ ] System handles corrupted JSON by removing the file and treating it as unscanned

### Write Operations
- [ ] System writes complete workspace JSON atomically
- [ ] System acquires lock before writing
- [ ] System validates data structure before writing
- [ ] System releases lock after successful write
- [ ] System handles write failures gracefully (log error, preserve old data)

### Integrity Verification
- [ ] System detects corrupted JSON files (parsing errors)
- [ ] System removes corrupted files and logs the removal
- [ ] System logs corruption detection events
- [ ] System continues operation with remaining valid files
- [ ] System provides recovery guidance in logs (rescan behavior)

### Error Handling
- [ ] System validates workspace directory exists and is writable
- [ ] System handles filesystem errors gracefully (disk full, permissions)
- [ ] System provides clear error messages for workspace failures
- [ ] System handles concurrent access conflicts (lock timeout, retry logic)
- [ ] System cleans up stale lock files (lock age exceeds timeout)

## Technical Considerations

### Workspace Structure
```
workspace/
├── workspace.json              # Optional: workspace-level metadata
├── files/                      # Per-file analysis results
│   ├── abc123def456.json      # Content hash as filename
│   ├── abc123def456.json.lock # Lock file during write
│   └── fed654cba321.json
├── plugins/                    # Plugin-specific persistent data
│   ├── metadata-extractor/
│   └── content-analyzer/
```

### JSON Schema
```json
{
  "file_path": "/absolute/path/to/file.pdf",
  "file_path_relative": "documents/file.pdf",
  "file_type": "application/pdf",
  "file_size": 1048576,
  "file_last_modified": 1707177600,
  "last_scanned": "2026-02-09T14:30:00Z",
  
  "content": {
    "text": "Extracted text...",
    "word_count": 5432,
    "summary": "Document summary..."
  },
  
  "plugins_executed": [
    {
      "name": "stat",
      "timestamp": "2026-02-09T14:30:01Z",
      "status": "success"
    }
  ]
}
```

### Implementation Functions
```bash
# Initialize workspace
init_workspace(workspace_dir)

# Generate file hash
generate_file_hash(filepath) -> hash_string

# Load workspace data
load_workspace(workspace_dir, file_hash) -> json_data

# Save workspace data
save_workspace(workspace_dir, file_hash, json_data)

# Acquire lock
acquire_lock(workspace_dir, file_hash, timeout) -> success/failure

# Release lock
release_lock(workspace_dir, file_hash)

# Get last scan time
get_last_scan_time(workspace_dir) -> timestamp

# Update scan timestamp
update_scan_timestamp(workspace_dir, file_hash, timestamp)

# Remove corrupted file and mark unscanned
remove_corrupted_workspace_file(workspace_dir, file_hash, json_file)

# Validate workspace schema
validate_workspace_schema(workspace_dir) -> valid/invalid
```

### Atomic Write Pattern
```bash
save_workspace() {
  local workspace_dir="$1"
  local file_hash="$2"
  local json_data="$3"
  
  local json_file="$workspace_dir/files/${file_hash}.json"
  local temp_file="$json_file.tmp.$$"
  local lock_file="$json_file.lock"
  
  # Acquire lock
  if ! acquire_lock "$workspace_dir" "$file_hash" 30; then
    log "ERROR" "WORKSPACE" "Failed to acquire lock for $file_hash"
    return 1
  fi
  
  # Write to temp file
  echo "$json_data" | jq '.' > "$temp_file" 2>/dev/null
  
  # Validate JSON
  if ! jq empty "$temp_file" 2>/dev/null; then
    log "ERROR" "WORKSPACE" "Invalid JSON, not saving"
    rm -f "$temp_file"
    release_lock "$workspace_dir" "$file_hash"
    return 1
  fi
  
  # Atomic rename
  mv "$temp_file" "$json_file"
  
  # Release lock
  release_lock "$workspace_dir" "$file_hash"
}
```

### Integration Points
- **Directory Scanner**: Reads timestamps for incremental analysis
- **Plugin Execution**: Reads/writes plugin results
- **Report Generator**: Reads final analysis data
- **Incremental Analysis**: Queries timestamps

 ### Dependencies
- `jq` or Python for JSON parsing/generation
- `sha256sum` or equivalent for hash generation
- File locking mechanism (flock or custom)
- Logging infrastructure

### Performance Considerations
- Use content hashing to avoid duplicate processing
- Implement efficient lock acquisition (timeouts, stale lock cleanup)
- Consider JSON parsing performance for large workspaces
- Cache frequently accessed data in memory

### Security Considerations
- Validate workspace directory within expected boundaries
- Set restrictive permissions on workspace (0700 for directories, 0600 for files)
- Prevent path traversal in workspace operations
- Handle concurrent access safely with locking
- Remove corrupted data and rescan

## Dependencies
- Requires: Basic script structure (feature_0001) ✅
- Blocks: Directory scanner (feature_0006) - needs timestamp queries
- Blocks: Plugin execution (feature_0009) - needs data storage
- Blocks: Incremental analysis - depends on timestamp tracking

## Testing Strategy
- Unit tests: Workspace initialization
- Unit tests: JSON read/write operations
- Unit tests: Atomic write with locking
- Unit tests: Corruption detection and removal with rescan behavior
- Unit tests: Timestamp tracking
- Integration tests: Concurrent access handling
- Integration tests: Filesystem error handling (disk full, permissions)
- Integration tests: Large workspace (thousands of files)
- Performance tests: JSON read/write performance

## Definition of Done
- [ ] All acceptance criteria met
- [ ] Unit tests passing with >80% coverage
- [ ] Integration tests passing
- [ ] Code reviewed and approved
- [ ] Documentation updated (workspace concept, architecture)
- [ ] Security review completed
- [ ] Performance benchmarks meet targets
