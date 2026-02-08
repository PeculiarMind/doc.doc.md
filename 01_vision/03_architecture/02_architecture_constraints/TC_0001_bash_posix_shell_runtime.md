# TC-0001: Bash/POSIX Shell Runtime Environment

**ID**: TC-0001  
**Status**: Active  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08  
**Type**: Technical Constraint

## Constraint

The system must execute in Bash 3.x+ or POSIX-compliant shell environments commonly available on Linux, macOS, and WSL.

## Source

Target deployment platforms (standard UNIX-like systems)

## Rationale

Target users operate on standard Linux/macOS systems where Bash is the ubiquitous scripting environment. Cannot assume other runtime environments (Python, Node.js, Ruby, etc.) without increasing installation burden.

## Impact

**Architectural Impact**:
- Implementation language limited to shell scripting
- Cannot use language features or libraries requiring compilation or runtime installation beyond standard shell utilities
- Must maintain compatibility across Bash versions and POSIX variants

**Design Constraints**:
- Core logic must be implemented in pure Bash
- No dependencies on external runtime environments
- Modular function architecture for maintainability
- Must account for portability across shell implementations

## Non-Negotiable Because

Target platforms only guarantee Bash/POSIX shell availability without additional installations. Users cannot be expected to install additional runtimes.

## Related Constraints

- [TC-0002: No Network Access During Runtime](TC_0002_no_network_access_runtime.md)
- [TC-0003: User-Space Execution](TC_0003_user_space_execution.md)
