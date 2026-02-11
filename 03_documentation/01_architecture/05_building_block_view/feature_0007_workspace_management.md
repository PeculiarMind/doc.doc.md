# Building Block View: Workspace Management System (Feature 7)

**Feature**: Feature 0007 - Workspace Management System  
**Status**: Implemented  
**Architecture Decision**: IDR-0015

## Overview

This document describes the building block view of the workspace management system implemented in `workspace.sh`. The workspace component provides the persistent data layer for the doc.doc.sh system, managing directory structures, JSON file read/write with atomic operations, file locking, timestamp tracking, integrity verification, and corruption recovery. It resides in the orchestration domain and serves as the state management foundation upon which scanner, plugin executor, and report generator depend.

## Level 1: System Context

```
┌─────────────────────────────────────────────────────────┐
│                  doc.doc.sh System                      │
│                                                         │
│  ┌──────────────┐     ┌─────────────────────────────┐  │
│  │ Entry Script  │────▶│  Orchestration Domain       │  │
│  │              │     │                             │  │
│  │              │     │  ┌───────────────────────┐  │  │
│  │              │     │  │   workspace.sh        │  │  │
│  │              │     │  │   (635 lines)         │  │  │
│  │              │     │  │   State Management    │  │  │
│  │              │     │  └───────────────────────┘  │  │
│  └──────────────┘     └─────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
         │                                    │
         │ CLI Input                          │ JSON Data
         ▼                                    ▼
    [User/Cron]                     [Workspace Directory]
```

## Level 2: Component Relationships

The workspace component sits at the foundation of the orchestration domain. Other orchestration and plugin components depend on it for persistent state management.

```
┌─────────────────────────────────────────────────────────────┐
│                   Orchestration Domain                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │  scanner.sh   │  │ template_    │  │ report_        │  │
│  │               │  │ engine.sh    │  │ generator.sh   │  │
│  └───────┬───────┘  └──────────────┘  └───────┬────────┘  │
│          │                                     │           │
│          │ get_last_scan_time()                │           │
│          │ load_workspace()                    │           │
│          ▼                                     ▼           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │                   workspace.sh                      │  │
│  │                                                     │  │
│  │  init_workspace()      acquire_lock()               │  │
│  │  generate_file_hash()  release_lock()               │  │
│  │  load_workspace()      get_last_scan_time()         │  │
│  │  save_workspace()      update_scan_timestamp()      │  │
│  │  merge_plugin_data()   update_full_scan_timestamp() │  │
│  │  validate_workspace_schema()                        │  │
│  │  remove_corrupted_workspace_file()                  │  │
│  └─────────────────────────────────────────────────────┘  │
│                            ▲                               │
│                            │ save_workspace()              │
│                            │ load_workspace()              │
│                            │ merge_plugin_data()           │
│  ┌─────────────────────────┴───────┐                      │
│  │       plugin_executor.sh        │                      │
│  │       (Plugin Domain)           │                      │
│  └─────────────────────────────────┘                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Level 3: Internal Structure

### Workspace Directory Layout

The workspace component manages the following directory structure on disk:

```
workspace/                          # Root workspace directory (0700)
├── workspace.json                  # Workspace-level metadata
│                                   #   - last_full_scan timestamp
├── files/                          # Per-file analysis results (0700)
│   ├── <sha256_hash_1>.json       # File analysis data (0600)
│   ├── <sha256_hash_1>.json.lock  # Lock file during write (0600)
│   ├── <sha256_hash_2>.json       # Another file's data
│   └── ...
└── plugins/                        # Plugin-specific persistent data (0700)
    ├── metadata-extractor/
    └── content-analyzer/
```

### Functional Groups

The component is organized into 5 functional groups:

```
┌─────────────────────────────────────────────────────────────┐
│                     workspace.sh                            │
│                     (635 lines)                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 1. Configuration Constants                          │   │
│  │    WORKSPACE_LOCK_TIMEOUT (default: 30s)            │   │
│  │    WORKSPACE_STALE_LOCK_AGE (default: 300s)         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 2. Workspace Initialization                         │   │
│  │    init_workspace(workspace_dir)                    │   │
│  │    ├─ Validates arguments                           │   │
│  │    ├─ Prevents path traversal (CWE-22)              │   │
│  │    ├─ Creates workspace/, files/, plugins/ dirs     │   │
│  │    └─ Sets restrictive permissions (0700)            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 3. File Hash Generation                             │   │
│  │    generate_file_hash(filepath)                     │   │
│  │    ├─ Content-based SHA-256 via sha256sum            │   │
│  │    └─ Returns hash string on stdout                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 4. Lock Management                                  │   │
│  │    acquire_lock(workspace_dir, file_hash, timeout)  │   │
│  │    ├─ Stale lock detection and cleanup              │   │
│  │    ├─ Atomic creation via noclobber (set -C)         │   │
│  │    └─ Configurable timeout with retry loop           │   │
│  │    release_lock(workspace_dir, file_hash)            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 5. Workspace Data Operations                        │   │
│  │    load_workspace(workspace_dir, file_hash)         │   │
│  │    ├─ Reads JSON, validates syntax via jq            │   │
│  │    ├─ Handles missing files (returns {})             │   │
│  │    └─ Removes corrupted files (recovery by rescan)   │   │
│  │    save_workspace(workspace_dir, file_hash, data)   │   │
│  │    ├─ Validates JSON before writing                  │   │
│  │    ├─ Acquires lock                                  │   │
│  │    ├─ Writes temp file with pretty-print (jq)        │   │
│  │    ├─ Validates temp file                            │   │
│  │    ├─ Atomic rename (mv temp → target)               │   │
│  │    ├─ Sets 0600 permissions                          │   │
│  │    └─ Releases lock                                  │   │
│  │    merge_plugin_data(existing, plugin, result, st)  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 6. Timestamp Tracking                               │   │
│  │    get_last_scan_time(workspace_dir)                │   │
│  │    ├─ Reads workspace.json → .last_full_scan        │   │
│  │    └─ Returns ISO 8601 timestamp or empty string     │   │
│  │    update_scan_timestamp(ws_dir, hash, timestamp)   │   │
│  │    update_full_scan_timestamp(ws_dir, timestamp)    │   │
│  │    └─ Atomic write to workspace.json                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 7. Integrity and Recovery                           │   │
│  │    remove_corrupted_workspace_file(ws, hash, file)  │   │
│  │    ├─ Removes corrupted JSON + associated lock       │   │
│  │    └─ Logs for rescan on next run                    │   │
│  │    validate_workspace_schema(workspace_dir)         │   │
│  │    ├─ Checks directory structure                     │   │
│  │    ├─ Validates all JSON files in files/             │   │
│  │    ├─ Removes corrupted files automatically          │   │
│  │    └─ Validates workspace.json if present            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Level 4: Dependency Graph

```
constants.sh (no deps)
    │
    ├──▶ logging.sh
    │       │
    │       ├──▶ error_handling.sh
    │       │       │
    │       │       └──▶ workspace.sh ◄── core dependencies
    │       │               │
    │       │               ├──▶ scanner.sh
    │       │               │     └─ calls: get_last_scan_time()
    │       │               │
    │       │               ├──▶ plugin_executor.sh
    │       │               │     └─ calls: save_workspace(), load_workspace()
    │       │               │              merge_plugin_data()
    │       │               │
    │       │               └──▶ report_generator.sh
    │       │                     └─ calls: load_workspace()
    │       │
    │       └──▶ ... (other components)
    │
    └──▶ ... (other components)

External Dependencies:
    workspace.sh ──▶ jq (JSON processing)
    workspace.sh ──▶ sha256sum (hash generation)
    workspace.sh ──▶ stat (lock age detection)
    workspace.sh ──▶ date (timestamp generation)
```

## Component Interfaces

### Exported Functions

| Function | Arguments | Returns | Side Effects |
|----------|-----------|---------|-------------|
| `init_workspace` | `workspace_dir` | 0=success, 1=failure | Creates directories, sets permissions |
| `generate_file_hash` | `filepath` | Hash string on stdout | Reads file content |
| `load_workspace` | `workspace_dir, file_hash` | JSON on stdout | Reads filesystem, may remove corrupted files |
| `save_workspace` | `workspace_dir, file_hash, json_data` | 0=success, 1=failure | Writes JSON, creates/removes lock files |
| `acquire_lock` | `workspace_dir, file_hash [, timeout]` | 0=acquired, 1=timeout | Creates lock file, may remove stale locks |
| `release_lock` | `workspace_dir, file_hash` | 0=success | Removes lock file |
| `get_last_scan_time` | `workspace_dir` | ISO 8601 timestamp or "" | Reads workspace.json |
| `update_scan_timestamp` | `workspace_dir, file_hash [, timestamp]` | 0=success, 1=failure | Updates per-file JSON |
| `update_full_scan_timestamp` | `workspace_dir [, timestamp]` | 0=success, 1=failure | Writes workspace.json atomically |
| `merge_plugin_data` | `existing_data, plugin_name, result, status` | Merged JSON on stdout | None (pure data merge) |
| `remove_corrupted_workspace_file` | `workspace_dir, file_hash [, json_file]` | 0=success | Removes JSON + lock files |
| `validate_workspace_schema` | `workspace_dir` | 0=valid, 1=invalid | May remove corrupted files |

### Configuration Constants

| Constant | Default | Environment Override | Purpose |
|----------|---------|---------------------|---------|
| `WORKSPACE_LOCK_TIMEOUT` | 30 seconds | `WORKSPACE_LOCK_TIMEOUT` | Maximum wait time for lock acquisition |
| `WORKSPACE_STALE_LOCK_AGE` | 300 seconds | `WORKSPACE_STALE_LOCK_AGE` | Age threshold for stale lock cleanup |

### Data Flow

```
                        ┌──────────────┐
                        │  scanner.sh  │
                        │              │
                        │ Needs:       │
                        │ - last scan  │
                        │   timestamp  │
                        └──────┬───────┘
                               │ get_last_scan_time()
                               ▼
┌──────────────┐      ┌──────────────────┐      ┌──────────────────┐
│    plugin_   │      │                  │      │   report_        │
│  executor.sh │─────▶│  workspace.sh    │◀─────│ generator.sh     │
│              │      │                  │      │                  │
│ Calls:       │      │ Manages:         │      │ Calls:           │
│ - save       │      │ - workspace.json │      │ - load_workspace │
│ - load       │      │ - files/*.json   │      │                  │
│ - merge      │      │ - files/*.lock   │      │                  │
└──────────────┘      └────────┬─────────┘      └──────────────────┘
                               │
                               ▼
                      ┌──────────────────┐
                      │  Filesystem      │
                      │                  │
                      │  workspace/      │
                      │  ├ workspace.json│
                      │  ├ files/        │
                      │  └ plugins/      │
                      └──────────────────┘
```

### Atomic Write Sequence

```
save_workspace(workspace_dir, file_hash, json_data)
    │
    ├─ 1. Validate JSON (jq empty)
    │     └─ FAIL → return 1 (no write)
    │
    ├─ 2. acquire_lock(workspace_dir, file_hash)
    │     ├─ Check for stale lock (age > 300s) → remove
    │     ├─ Try atomic create: (set -C; echo $$ > lockfile)
    │     ├─ SUCCESS → continue
    │     └─ TIMEOUT → return 1
    │
    ├─ 3. Write temp file: json_data | jq '.' > file.tmp.$$
    │     └─ FAIL → cleanup temp, release lock, return 1
    │
    ├─ 4. Validate temp file (jq empty)
    │     └─ FAIL → cleanup temp, release lock, return 1
    │
    ├─ 5. Set permissions: chmod 0600 temp_file
    │
    ├─ 6. Atomic rename: mv temp_file → target_file
    │     └─ FAIL → cleanup temp, release lock, return 1
    │
    └─ 7. release_lock(workspace_dir, file_hash)
```

## Design Patterns

### Pattern 1: Atomic Write (Temp File + Rename)

All write operations follow the temp-file-then-rename pattern to prevent partial writes:

```bash
# Write to temporary file (unique per PID)
echo "$data" | jq '.' > "$file.tmp.$$"
# Validate written data
jq empty "$file.tmp.$$"
# Atomic rename (POSIX guarantees atomicity on same filesystem)
mv "$file.tmp.$$" "$file"
```

### Pattern 2: Custom Lock Files with Noclobber

Concurrency control uses shell noclobber instead of flock for portability:

```bash
# Atomic lock creation (fails if file exists)
(set -C; echo "$$" > "$lock_file") 2>/dev/null
```

### Pattern 3: Corruption Recovery by Removal + Rescan

Corrupted JSON files are removed rather than repaired. The file is treated as unscanned and rebuilt on the next analysis run:

```bash
# Detect corruption
if ! echo "$json_data" | jq empty 2>/dev/null; then
    remove_corrupted_workspace_file "$workspace_dir" "$file_hash"
    echo "{}"  # Return empty, will be rescanned
fi
```

### Pattern 4: Defensive Input Validation

All public functions validate arguments before proceeding and check for path traversal:

```bash
case "$workspace_dir" in
    *..*)
        log "ERROR" "WORKSPACE" "Path traversal detected"
        return 1 ;;
esac
```

## Architecture Metrics

### Size Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Component size | 635 lines | ⚠️ Exceeds 200-line guideline |
| Exported functions | 12 | ℹ️ Cohesive workspace API |
| Configuration constants | 2 | ✅ |
| Functional groups | 7 | ✅ Well-organized |
| External dependencies | 4 (jq, sha256sum, stat, date) | ✅ |

### Complexity Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| Dependency depth | 3 levels | constants → logging → error_handling → workspace |
| Components depending on workspace | 3 | scanner, plugin_executor, report_generator |
| Core dependencies | 3 | constants.sh, logging.sh, error_handling.sh |
| Circular dependencies | 0 | ✅ None |

### Quality Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Functions with input validation | 12/12 | ✅ 100% |
| Functions with error handling | 12/12 | ✅ 100% |
| Security checks (path traversal) | Yes | ✅ CWE-22 mitigated |
| JSON validation on load | Yes | ✅ |
| JSON validation on save | Yes (pre-write + post-write) | ✅ |
| Atomic write operations | Yes | ✅ |
| Lock-based concurrency | Yes | ✅ |

## Testing Strategy

### Unit Testing

```bash
# Test workspace initialization
source scripts/components/core/constants.sh
source scripts/components/core/logging.sh
source scripts/components/core/error_handling.sh
source scripts/components/orchestration/workspace.sh

workspace_dir=$(mktemp -d)
init_workspace "$workspace_dir"
[[ -d "$workspace_dir/files" ]] || fail "files/ not created"
[[ -d "$workspace_dir/plugins" ]] || fail "plugins/ not created"
```

### Integration Testing

```bash
# Test save/load cycle with locking
init_workspace "$workspace_dir"
hash=$(generate_file_hash "/path/to/file")
save_workspace "$workspace_dir" "$hash" '{"test": "data"}'
result=$(load_workspace "$workspace_dir" "$hash")
[[ $(echo "$result" | jq -r '.test') == "data" ]] || fail
```

### Corruption Recovery Testing

```bash
# Test corrupted file detection and removal
echo "not json" > "$workspace_dir/files/${hash}.json"
result=$(load_workspace "$workspace_dir" "$hash")
[[ "$result" == "{}" ]] || fail "Should return empty JSON"
[[ ! -f "$workspace_dir/files/${hash}.json" ]] || fail "Corrupted file should be removed"
```

## Future Enhancements

### Planned Improvements

1. **Workspace Cleanup**: Remove orphaned entries for deleted source files
2. **Workspace Statistics**: Report disk usage and file counts
3. **Compression**: Compress old/inactive workspace files
4. **Index File**: Faster lookups for large workspaces
5. **Workspace Reset**: Full reset with confirmation safeguard

### Extensibility Points

- `plugins/` directory supports per-plugin persistent storage
- `workspace.json` can be extended with additional workspace-level metadata
- JSON schema allows `additionalProperties` for backward compatibility

## Related Documentation

- **Architecture Decision**: [IDR-0015: Workspace Management Implementation](../09_architecture_decisions/IDR_0015_workspace_management_implementation.md)
- **Vision ADR**: [ADR-0002: JSON Workspace for State Persistence](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0002_json_workspace_for_state_persistence.md)
- **Vision Concept**: [08_0002: Workspace Concept](../../../01_vision/03_architecture/08_concepts/08_0002_workspace_concept.md)
- **Feature**: [Feature 0007: Workspace Management System](../../../02_agile_board/06_done/feature_0007_workspace_management.md)
- **Building Block View**: [05_building_block_view (Vision)](../../../01_vision/03_architecture/05_building_block_view/05_building_block_view.md) - Section 5.8 Workspace Manager

## Conclusion

The workspace management system successfully implements the persistent data layer envisioned in ADR-0002 and the workspace concept (08_0002). The component provides:

✅ **Atomic Operations** - Temp file + rename pattern prevents corruption  
✅ **Concurrency Safety** - Custom lock files with stale detection  
✅ **Data Integrity** - JSON validation on both load and save  
✅ **Security** - Path traversal prevention, restrictive permissions (0700/0600)  
✅ **Recovery** - Corruption detection with automatic removal and rescan  
✅ **Extensibility** - Plugin data merge, workspace-level metadata, additionalProperties  

The building block view demonstrates a well-structured component that serves as the reliable state management foundation for the entire orchestration workflow.
