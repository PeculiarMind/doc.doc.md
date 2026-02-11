# IDR-0015: Workspace Management Implementation

**ID**: IDR-0015  
**Status**: Implemented  
**Created**: 2026-02-11  
**Feature**: Feature 0007 - Workspace Management System

## Context

Feature 0007 implemented the workspace management system envisioned in ADR-0002 (JSON Workspace for State Persistence) and the workspace concept (08_0002). The workspace component provides persistent state management for the doc.doc.sh system, enabling incremental analysis, plugin data exchange, and corruption recovery. This Implementation Decision Record documents the actual implementation decisions made during development of `scripts/components/orchestration/workspace.sh`.

## Implementation Decisions

### 1. Content-Based SHA-256 Hashing for File Identification

**Decision**: Use SHA-256 hash of file content (via `sha256sum`) as the unique identifier for workspace JSON files, stored as `files/<hash>.json`.

**Rationale**:
- Content-based hashing ensures identical files produce identical identifiers regardless of path
- SHA-256 provides sufficient collision resistance for file identification
- Deterministic naming enables efficient lookup without maintaining an index
- Handles special characters and long paths that would be problematic as filenames

**Alternatives Considered**:
- Path-based hashing (hash of file path) → Rejected: file moves would create duplicates, same content at different paths treated differently
- Sequential numbering → Rejected: requires index file, non-deterministic
- MD5 hashing → Rejected: weaker collision resistance, SHA-256 preferred for security

**Consequences**:
- ✅ Unique, deterministic filenames for any input file
- ✅ Handles edge cases (special characters, long paths)
- ⚠️ Requires `sha256sum` external tool (widely available on Linux)
- ⚠️ File content changes produce new hash, old workspace entry becomes orphaned

### 2. Atomic Write Pattern (Temp File + Rename)

**Decision**: All write operations use a temp file + atomic rename pattern:
1. Write data to `<target>.tmp.$$` (PID-unique temp file)
2. Validate the written data
3. `mv` temp file to target (atomic on POSIX same-filesystem)

**Rationale**:
- POSIX guarantees `mv` (rename) is atomic on the same filesystem
- Process crash during write leaves only a temp file, never a partial target
- PID suffix (`$$`) prevents temp file collisions between concurrent processes
- Aligns with ADR-0002 vision which specifies atomic write pattern

**Alternatives Considered**:
- Direct write to target → Rejected: process kill during write corrupts file
- Write + fsync → Rejected: more complex, still vulnerable to partial writes
- Copy-on-write with backup → Rejected: over-engineering for this use case

**Consequences**:
- ✅ Zero risk of partial writes corrupting workspace files
- ✅ Simple and well-understood pattern
- ✅ Self-cleaning (orphaned temp files don't affect operation)
- ⚠️ Requires temp file and target on same filesystem (always true for workspace)

### 3. Custom Lock Files with Noclobber (set -C) for Concurrency Control

**Decision**: Implement file locking using shell noclobber (`set -C`) for atomic lock file creation:

```bash
(set -C; echo "$$" > "$lock_file") 2>/dev/null
```

**Rationale**:
- `set -C` (noclobber) causes `>` redirection to fail if file exists — atomic test-and-create
- More portable than `flock` (not available on all platforms, especially macOS default)
- Lock file contains PID for ownership identification
- Subshell `()` isolates the noclobber setting from the main script
- Aligns with ADR-0001 (Bash as Primary Language) portability goals

**Alternatives Considered**:
- `flock` utility → Rejected: not available on macOS by default, requires `brew install flock`
- `mkdir` as lock (atomic on POSIX) → Considered but noclobber provides PID storage in single operation
- Advisory file locks via `fcntl` → Rejected: not accessible from bash
- No locking → Rejected: concurrent access would corrupt workspace data

**Consequences**:
- ✅ Portable across Linux and macOS
- ✅ Atomic creation prevents race conditions
- ✅ PID stored in lock file enables stale lock detection
- ⚠️ Not as robust as kernel-level `flock` (lock survives process crash as stale file)
- ⚠️ Requires stale lock cleanup mechanism (see Decision 4)

### 4. Stale Lock Detection and Cleanup (Configurable Timeout)

**Decision**: Detect and remove stale lock files based on file age, with configurable thresholds:
- `WORKSPACE_LOCK_TIMEOUT`: Maximum wait time for lock acquisition (default: 30 seconds)
- `WORKSPACE_STALE_LOCK_AGE`: Age threshold for stale lock removal (default: 300 seconds / 5 minutes)

**Rationale**:
- Processes that crash while holding a lock leave orphaned lock files
- Age-based detection is simple and reliable — a lock held for 5+ minutes is almost certainly stale
- Configurable via environment variables for different deployment scenarios
- `stat -c '%Y'` provides lock file modification time for age calculation

**Alternatives Considered**:
- PID-based detection (check if PID still running) → Rejected: PID reuse risk, cross-machine issues
- No stale detection (manual cleanup) → Rejected: poor operational experience
- Fixed timeout with no configuration → Rejected: different environments need different thresholds

**Consequences**:
- ✅ Automatic recovery from crashed processes
- ✅ Configurable for different deployment needs
- ✅ Conservative default (5 minutes) avoids premature cleanup
- ⚠️ Relies on filesystem timestamps (must be accurate)
- ⚠️ Uses `stat -c` (GNU stat syntax, may differ on macOS)

### 5. JSON Validation on Both Load and Save

**Decision**: Validate JSON syntax using `jq empty` at every data boundary:
- **On load**: Validate data read from disk before returning to caller
- **On save (pre-write)**: Validate caller-provided data before writing
- **On save (post-write)**: Validate temp file contents before atomic rename

**Rationale**:
- Defense in depth: catch corruption at every stage
- Prevents invalid data from propagating through the system
- `jq empty` is efficient — only parses, produces no output
- Corrupted files detected on load are removed and treated as unscanned (see Decision 8)

**Alternatives Considered**:
- Validate only on save → Rejected: doesn't catch disk corruption or external edits
- Validate only on load → Rejected: allows bad data to be written
- Schema validation (full JSON Schema) → Rejected: over-engineering, `jq empty` sufficient for syntax
- No validation → Rejected: silent corruption would produce wrong results

**Consequences**:
- ✅ Corrupted data never passes through the system silently
- ✅ Three validation checkpoints per save operation
- ✅ Corruption detected early with clear error messages
- ⚠️ Requires `jq` as mandatory dependency
- ⚠️ Small performance overhead for triple validation (negligible for typical workspaces)

### 6. Pretty-Printed JSON for Human Readability

**Decision**: Save all JSON data with `jq '.'` pretty-printing rather than compact single-line format.

**Rationale**:
- Aligns with ADR-0002 rationale: "Human-Readability over Compactness: Prefer debuggability"
- Workspace files are a debugging and integration surface
- External tools (downstream scripts, manual inspection) benefit from readable format
- `jq '.'` normalizes formatting consistently across all writes
- Performance impact negligible for expected workspace sizes

**Alternatives Considered**:
- Compact JSON (`jq -c`) → Rejected: harder to debug, minimal space savings
- Configurable formatting → Rejected: unnecessary complexity
- Raw echo without jq formatting → Rejected: inconsistent formatting

**Consequences**:
- ✅ Easy debugging with `cat` or any text editor
- ✅ Consistent formatting across all workspace files
- ✅ Normalized output (sorted keys, proper indentation)
- ⚠️ Slightly larger file sizes (~30-50% vs compact)

### 7. Restrictive Permissions (0700 Directories, 0600 Files)

**Decision**: Set permissions to owner-only access:
- Directories: `chmod 0700` (rwx------)
- JSON files: `chmod 0600` (rw-------)
- Lock files: `chmod 0600` (rw-------)

**Rationale**:
- Workspace may contain sensitive file metadata (paths, content summaries)
- Principle of least privilege — only the running user needs access
- Aligns with feature_0007 security considerations
- `chmod` failures are non-fatal (logged but `|| true`) for compatibility

**Alternatives Considered**:
- Default permissions (umask-based) → Rejected: may be too permissive on shared systems
- Group-readable (0750/0640) → Rejected: no use case for group access currently
- ACL-based permissions → Rejected: over-engineering, not portable

**Consequences**:
- ✅ Workspace data protected from other users
- ✅ Defense in depth for sensitive metadata
- ⚠️ May need adjustment for shared workspace deployments (future feature)

### 8. Corruption Recovery by Removal + Rescan Approach

**Decision**: When corrupted JSON is detected (empty file or invalid JSON syntax), remove the file and treat it as unscanned. The file will be automatically re-analyzed on the next scan.

**Rationale**:
- Simple and reliable — no complex repair logic
- Worst case is re-analysis of one file (acceptable cost)
- Avoids attempting to parse or repair partially corrupted data
- Aligns with workspace concept (08_0002) corruption handling specification
- `remove_corrupted_workspace_file()` also cleans up associated lock files

**Alternatives Considered**:
- Repair corrupted JSON (partial parsing) → Rejected: unreliable, complex
- Move to quarantine directory → Rejected: adds complexity without benefit
- Ignore corruption (return partial data) → Rejected: could produce wrong analysis results
- Keep backup copies for recovery → Rejected: doubles storage, adds complexity

**Consequences**:
- ✅ Simple, predictable recovery behavior
- ✅ No partial or incorrect data returned
- ✅ Clear logging of corruption events
- ⚠️ Re-analysis cost for corrupted files (acceptable trade-off)

### 9. workspace.json for Workspace-Level Metadata vs Per-File Metadata in files/

**Decision**: Use two-tier metadata storage:
- `workspace.json`: Workspace-level metadata (e.g., `last_full_scan` timestamp)
- `files/<hash>.json`: Per-file analysis data and metadata

**Rationale**:
- Separates workspace-wide state from per-file state
- `get_last_scan_time()` reads from `workspace.json` — single file read, not scanning all file entries
- Per-file data scales independently (thousands of JSON files)
- Aligns with vision concept 08_0002 which specifies `metadata.json` (implemented as `workspace.json`)
- `update_full_scan_timestamp()` uses its own atomic write pattern for workspace.json

**Alternatives Considered**:
- Single large JSON file for all data → Rejected: doesn't scale, locking blocks all access
- Per-file metadata only (no workspace.json) → Rejected: workspace-wide queries require scanning all files
- Database (SQLite) → Rejected per ADR-0002: overkill for file-to-metadata mapping

**Consequences**:
- ✅ Efficient workspace-level queries (single file read)
- ✅ Per-file data scales to thousands of files
- ✅ Independent locking granularity
- ⚠️ Two different file types to manage (minimal complexity)

### 10. get_last_scan_time Moved from scanner.sh to workspace.sh

**Decision**: Place `get_last_scan_time()` in `workspace.sh` rather than `scanner.sh`, even though the scanner is the primary consumer.

**Rationale**:
- The function reads `workspace.json` — a workspace management concern, not a scanning concern
- Prevents scanner.sh from needing to know workspace internal file structure
- Eliminates code duplication (other components may also need scan timestamps)
- Clean dependency direction: scanner depends on workspace, not workspace on scanner
- Consistent with the principle that data access belongs with the data owner

**Alternatives Considered**:
- Place in scanner.sh (caller owns function) → Rejected: scanner shouldn't know workspace internals
- Duplicate in both components → Rejected: DRY violation
- Create separate timestamp utility → Rejected: over-engineering for one function

**Consequences**:
- ✅ Clean separation of concerns
- ✅ No circular dependencies
- ✅ Single source of truth for workspace data access
- ✅ scanner.sh calls `get_last_scan_time()` without knowing about workspace.json

## Consequences

### Positive Outcomes

✅ **Data Integrity**: Triple JSON validation + atomic writes prevent corruption  
✅ **Concurrency Safety**: Noclobber lock files + stale detection enable multi-process operation  
✅ **Recovery**: Automatic corruption detection and removal with rescan behavior  
✅ **Security**: Path traversal prevention, restrictive permissions, input validation  
✅ **Debuggability**: Pretty-printed JSON, human-readable workspace files  
✅ **Portability**: Custom locking works across Linux and macOS (no flock dependency)  
✅ **Extensibility**: Two-tier metadata, additionalProperties in JSON schema  
✅ **Clean Architecture**: Data access functions co-located with data management  

### Trade-offs Accepted

📊 **Component Size**: 635 lines exceeds 200-line guideline — accepted due to cohesive workspace management API  
📊 **jq Dependency**: Required for JSON operations — acceptable per ADR-0002  
📊 **File-Based Locking**: Less robust than kernel locks — mitigated by stale lock cleanup  
📊 **Pretty-Print Overhead**: Larger files than compact JSON — accepted for debuggability  

## Compliance Verification

### Against ADR-0002 (JSON Workspace for State Persistence)

| ADR-0002 Specification | Implementation Status | Notes |
|------------------------|----------------------|-------|
| JSON files in workspace directory | ✅ Implemented | `files/<hash>.json` per analyzed file |
| Content hash as filename | ✅ Implemented | SHA-256 via `sha256sum` |
| Atomic write pattern | ✅ Implemented | Temp file + rename with validation |
| File locking with .lock files | ✅ Implemented | Noclobber-based with stale detection |
| Human-readable JSON | ✅ Implemented | Pretty-printed via `jq '.'` |
| One JSON file per analyzed file | ✅ Implemented | Scalable, distributed I/O |
| Incremental analysis support | ✅ Implemented | Timestamp tracking in workspace.json |

### Against Vision Concept 08_0002 (Workspace Concept)

| Concept Specification | Implementation Status | Notes |
|----------------------|----------------------|-------|
| Workspace directory structure | ✅ Implemented | workspace/, files/, plugins/ subdirectories |
| SHA-256 hash naming | ✅ Implemented | Content-based hashing |
| Atomic write pattern | ✅ Implemented | Enhanced with triple validation |
| Lock file protocol | ✅ Implemented | Noclobber + stale detection (improved over vision) |
| Initialization with permissions | ✅ Implemented | 0700 directories, 0600 files |
| Corruption detection and recovery | ✅ Implemented | Remove + rescan approach |
| Workspace validation | ✅ Implemented | `validate_workspace_schema()` |
| workspace.json metadata | ✅ Implemented | `last_full_scan` timestamp stored |

### Against Feature 0007 Acceptance Criteria

| Acceptance Criterion | Implementation Status | Evidence |
|---------------------|----------------------|----------|
| Workspace directory creation | ✅ Implemented | `init_workspace()` with mkdir -p |
| Standard subdirectories (files/, plugins/) | ✅ Implemented | Created in `init_workspace()` |
| Writable workspace validation | ✅ Implemented | `-w` check in init and validate |
| Content-based hash generation | ✅ Implemented | `generate_file_hash()` with SHA-256 |
| Atomic JSON writes | ✅ Implemented | Temp file + rename in `save_workspace()` |
| Lock files for concurrency | ✅ Implemented | `acquire_lock()` / `release_lock()` |
| Lock timeout | ✅ Implemented | Configurable `WORKSPACE_LOCK_TIMEOUT` |
| JSON validation on write | ✅ Implemented | Pre-write + post-write validation |
| Pretty-printed JSON | ✅ Implemented | `jq '.'` formatting |
| Timestamp tracking | ✅ Implemented | Per-file and workspace-level |
| Corrupted file removal | ✅ Implemented | `remove_corrupted_workspace_file()` |
| Stale lock cleanup | ✅ Implemented | Age-based detection in `acquire_lock()` |
| Path traversal prevention | ✅ Implemented | CWE-22 check in `init_workspace()` |
| Restrictive permissions | ✅ Implemented | 0700 dirs, 0600 files |

## Success Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| All acceptance criteria | Met | All 14 criteria satisfied | ✅ Achieved |
| Atomic write safety | Zero partial writes | Temp + rename pattern | ✅ Achieved |
| Concurrency support | Lock-based | Noclobber + stale detection | ✅ Achieved |
| JSON validation | On load and save | Triple validation (load + pre-write + post-write) | ✅ Exceeded |
| Corruption recovery | Detect and remove | Automatic removal with rescan | ✅ Achieved |
| Security | Path traversal prevention | CWE-22 check implemented | ✅ Achieved |

## Related Items

- **Vision ADR**: [ADR-0002: JSON Workspace for State Persistence](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0002_json_workspace_for_state_persistence.md)
- **Vision Concept**: [08_0002: Workspace Concept](../../../01_vision/03_architecture/08_concepts/08_0002_workspace_concept.md)
- **Building Block View**: [Feature 0007 Building Block View](../05_building_block_view/feature_0007_workspace_management.md)
- **Feature**: [Feature 0007: Workspace Management System](../../../02_agile_board/06_done/feature_0007_workspace_management.md)
- **Architecture Overview (Vision)**: [05_building_block_view Section 5.8](../../../01_vision/03_architecture/05_building_block_view/05_building_block_view.md) - Workspace Manager

## Reason

This implementation decision was made during Feature 0007 implementation to specify workspace management strategies when working with persistent analysis state. The vision (ADR-0002, concept 08_0002) establishes the need for JSON workspace persistence but leaves implementation details such as locking mechanism, validation strategy, and corruption recovery approach to the implementation phase.

## Deviation from Vision

No significant deviation — implementation follows and enhances vision specifications. Minor enhancements over vision:
- Triple JSON validation (vision specified single validation)
- Noclobber locking instead of simple while-loop + write (more atomic)
- Configurable lock timeout and stale age thresholds (vision used fixed values)
- Two-tier metadata (`workspace.json` + `files/*.json`) vs flat structure in vision concept

All enhancements are additive and compatible with the vision architecture.

## Associated Risks

No significant risks — decision aligns with vision principles. The primary operational risk is reliance on file-based locking which is less robust than kernel-level locks, mitigated by stale lock detection and configurable timeouts. The `jq` dependency is required but widely available and already an accepted dependency per ADR-0002.

## Conclusion

The workspace management implementation successfully delivers the persistent data layer envisioned in ADR-0002 and concept 08_0002. All 10 implementation decisions are justified, documented, and aligned with the architecture vision. The component provides atomic operations, concurrency safety, corruption recovery, and security hardening as a reliable foundation for the orchestration workflow.

**Architecture Compliance Status**: ✅ **COMPLIANT** - implementation follows architecture vision from 01_vision/03_architecture.
