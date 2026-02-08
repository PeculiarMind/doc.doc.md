# TC-0001: Bash/POSIX Shell Runtime Environment

**ID**: TC-0001  
**Status**: Active  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08

## Constraint

The system must execute in Bash 4.0+ or POSIX-compliant shell environments.

## Source

Target deployment platforms (standard UNIX-like systems) only guarantee Bash/POSIX shell availability.

## Rationale

Target users operate on standard Linux/macOS systems where Bash is the ubiquitous scripting environment. Cannot assume other runtime environments (Python, Node.js, Ruby, etc.) without increasing installation burden.

## Impact

- Implementation language limited to shell scripting
- Cannot use language features or libraries requiring compilation or runtime installation beyond standard shell utilities
- Core logic must be pure Bash
- No external runtime dependencies

## Implementation Status

**Compliance**: ✅ COMPLIANT

**Evidence**:
- Script uses `#!/usr/bin/env bash` shebang
- Bash 4.0+ features used appropriately
- Core logic implemented in pure Bash
- No external runtime dependencies (Python, Node.js, etc.)

**Implementation Location**: `scripts/doc.doc.sh:1`

**Platform Testing**:
- ✅ Ubuntu/Debian (primary target)
- ⏳ macOS (planned testing)
- ⏳ WSL (planned testing)
- ⏳ Alpine Linux (planned testing)

## Compliance Verification

**Verification Method**:
```bash
# Check shebang
head -n1 scripts/doc.doc.sh

# Verify no external runtime calls
grep -r "python\|node\|ruby\|perl" scripts/doc.doc.sh
```

**Expected Result**: No external runtime dependencies found

## Related Constraints

- [TC-0002: No Network Access During Runtime](TC_0002_no_network_access_runtime.md)
- [TC-0003: User-Space Execution](TC_0003_user_space_execution.md)
