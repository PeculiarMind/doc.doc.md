# TC-0003: User-Space Execution (No Root/Sudo)

**ID**: TC-0003  
**Status**: Active  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08

## Constraint

The system must operate entirely in user-space without requiring root privileges or sudo access.

## Source

Target deployment environments (shared servers, restricted user accounts, corporate workstations). Many users do not have administrative privileges.

## Rationale

Users may not have administrative privileges on target systems. Requiring sudo would prevent usage in many enterprise and shared hosting environments where sudo access is explicitly prohibited for security and system stability.

## Impact

- Cannot install system-wide packages or modify system directories
- Cannot access privileged system information or APIs
- Must use user-writable directories for workspace and output
- Tool installation prompts must guide users to userspace methods

## Implementation Status

**Compliance**: ✅ COMPLIANT

**Evidence**:
- No sudo/root requirements
- Uses user-writable directories only
- No system directory modifications
- File permissions respect user context

**Implementation Details**:
- Script executes with user permissions
- Workspace/target directories in user space
- No privileged operations required
- Future: Tool installation prompts will guide to user-space methods

## Implementation Approach

- Workspace in user directories (`~/.doc.doc/` recommended)
- No system-wide installation required
- Tool installation via package managers (user-space when possible)

## Compliance Verification

**Verification Method**:
```bash
# Run as non-root user
whoami  # Should NOT be root
./scripts/doc.doc.sh --help
./scripts/doc.doc.sh -p list

# Verify no sudo calls
grep -r "sudo\|su " scripts/
```

**Expected Result**: Runs successfully without root privileges

## Related Constraints

- [TC-0001: Bash/POSIX Shell Runtime Environment](TC_0001_bash_posix_shell_runtime.md)
- [TC-0004: Headless/SSH Environment Compatibility](TC_0004_headless_ssh_compatibility.md)
