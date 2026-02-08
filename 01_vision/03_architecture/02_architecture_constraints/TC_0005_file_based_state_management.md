# TC-0005: File-Based State Management

**ID**: TC-0005  
**Status**: Active  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08  
**Type**: Technical Constraint

## Constraint

State persistence must use file-based storage only; database servers or daemon processes are not available.

## Source

Lightweight implementation requirement and deployment environment limitations

## Rationale

Target environments do not run database servers. Solution must be self-contained without assuming availability of PostgreSQL, MySQL, Redis, or similar services.

## Impact

**Architectural Impact**:
- State, metadata, and workspace data stored as JSON files
- No ACID guarantees beyond filesystem atomicity
- Concurrency handled through file locking mechanisms
- Query performance limited by filesystem and text processing tools

**Design Constraints**:
- JSON-based workspace storage
- File locking for concurrent access
- Atomic write operations (temp + rename pattern)
- Simple query mechanisms using text tools (jq, grep)

## Non-Negotiable Because

Cannot require users to install and maintain database servers for a lightweight analysis toolkit. Solution must be portable and self-contained.

## Related Constraints

- [TC-0001: Bash/POSIX Shell Runtime Environment](TC_0001_bash_posix_shell_runtime.md)
- [TC-0004: Headless/SSH Environment Compatibility](TC_0004_headless_ssh_compatibility.md)
