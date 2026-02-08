# TC-0005: File-Based State Management

**ID**: TC-0005  
**Status**: Active  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08

## Constraint

State persistence must use file-based storage only; database servers or daemon processes are not available.

## Source

Lightweight implementation requirement and deployment environment limitations. Target environments do not run database servers.

## Rationale

Solution must be self-contained without assuming availability of PostgreSQL, MySQL, Redis, or similar services. Cannot require users to install and maintain database servers for a lightweight analysis toolkit.

## Impact

- State, metadata, and workspace data stored as JSON files
- No ACID guarantees beyond filesystem atomicity
- Concurrency handled through file locking mechanisms
- Query performance limited by filesystem and text processing tools

## Implementation Status

**Compliance**: ✅ COMPLIANT

**Evidence**:
- No database dependencies
- JSON workspace planned (file-based)
- No daemon processes required
- ⏳ Workspace implementation pending

## Planned Implementation

- JSON files in workspace directory
- One file per analyzed document
- Atomic write operations (temp + rename)
- File locking for concurrency control

**Compliance Notes**:
- SQLite considered but rejected (matches constraint)
- Design uses jq for JSON processing (available on most systems)
- Fallback to Python JSON parser if jq unavailable

## Compliance Verification

**Verification Method**:
```bash
# Check for database dependencies
grep -r "postgres\|mysql\|redis\|mongodb" scripts/

# Verify no daemon processes
ps aux | grep doc.doc
```

**Expected Result**: No database connections, no daemon processes

## Related Constraints

- [TC-0001: Bash/POSIX Shell Runtime Environment](TC_0001_bash_posix_shell_runtime.md)
- [TC-0004: Headless/SSH Environment Compatibility](TC_0004_headless_ssh_compatibility.md)
