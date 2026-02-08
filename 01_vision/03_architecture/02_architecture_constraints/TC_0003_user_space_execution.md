# TC-0003: User-Space Execution (No Root/Sudo)

**ID**: TC-0003  
**Status**: Active  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08  
**Type**: Technical Constraint

## Constraint

The system must operate entirely in user-space without requiring root privileges or sudo access.

## Source

Target deployment environments (shared servers, restricted user accounts, corporate workstations)

## Rationale

Users may not have administrative privileges on target systems. Requiring sudo would prevent usage in many enterprise and shared hosting environments.

## Impact

**Architectural Impact**:
- Cannot install system-wide packages or modify system directories
- Cannot access privileged system information or APIs
- Must use user-writable directories for workspace and output
- Tool installation prompts must guide users to userspace methods (package managers like Homebrew, apt without sudo, manual installation)

**Design Constraints**:
- All operations in user-writable directories
- No system modifications permitted
- Tool dependencies must be installable in user-space
- Clear guidance for non-privileged tool installation

## Non-Negotiable Because

Many target environments explicitly prohibit sudo access for security and system stability. Enterprise users often lack administrative privileges.

## Related Constraints

- [TC-0001: Bash/POSIX Shell Runtime Environment](TC_0001_bash_posix_shell_runtime.md)
- [TC-0004: Headless/SSH Environment Compatibility](TC_0004_headless_ssh_compatibility.md)
