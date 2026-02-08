# IDR-0002: Exit Code System (0-5)

**ID**: IDR-0002  
**Status**: Accepted  
**Created**: 2026-02-06  
**Last Updated**: 2026-02-08  
**Related ADRs**: [ADR-0001: Bash as Primary Language](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0001_bash_as_primary_implementation_language.md)

## Decision

Define six exit codes (0-5) as named constants, each representing a specific failure category.

## Context

Script needs to communicate success/failure to calling processes. Options:
1. Simple (0=success, 1=failure)
2. Categorized (0=success, different codes for different failures)
3. Detailed (many exit codes for specific scenarios)

## Rationale

**Scriptability**:
- Calling scripts can distinguish error types
- Enables conditional retry logic or error handling

**Debugging**:
- Exit code immediately indicates failure category
- Reduces investigation time

**Convention**:
- Follows Unix convention (0=success, non-zero=failure)
- Exit code 1 for generic errors (argument errors)
- Codes 2-5 for specific failure domains

## Reason

Exit code categorization was necessary to enable calling scripts to distinguish between different failure types and implement appropriate error handling logic. Vision ADRs did not specify exit code strategy, so this implementation decision fills that detail.

## Deviation from Vision

No deviation - this decision fills implementation details not specified in vision. The exit code system complements ADR-0001 (Bash as Primary Language) by providing robust error communication that integrates naturally with shell scripting conventions and enables scriptable error handling.

## Associated Risks

No associated risks - decision aligns with vision principles and Unix conventions. Exit code system follows industry best practices and enhances scriptability without introducing technical debt or architectural concerns.

## Exit Code Definitions

```bash
EXIT_SUCCESS=0          # Successful completion
EXIT_INVALID_ARGS=1     # Invalid command-line arguments
EXIT_FILE_ERROR=2       # File or directory access error
EXIT_PLUGIN_ERROR=3     # Plugin execution failed
EXIT_REPORT_ERROR=4     # Report generation failed
EXIT_WORKSPACE_ERROR=5  # Workspace corruption or access error
```

**Range Rationale**:
- 0: Standard success
- 1: Standard error (arguments, generic)
- 2-5: Domain-specific errors (file, plugin, report, workspace)
- Avoids high exit codes (reserved by shell for signals)

## Usage in Code

```bash
# Success
exit "${EXIT_SUCCESS}"

# Argument error
exit "${EXIT_INVALID_ARGS}"

# Future: File error
error_exit "Cannot read directory" "${EXIT_FILE_ERROR}"
```

## Documentation

Exit codes documented in:
1. Help text (visible to users)
2. Code comments (visible to developers)
3. Architecture documentation (this document)

## Alternatives Considered

1. **Single error code** (0 and 1 only): Rejected - Insufficient granularity
2. **Many exit codes** (10+ codes): Rejected - Over-engineered for current scope
3. **Signal-based codes** (128+): Rejected - Not applicable (no signal handling yet)

## Impact

- Scripts can handle specific error types
- Clear communication of failure reason
- Prepared for future error scenarios (codes 2-5 currently unused but ready)

## Implementation Location

**Code Reference**: `scripts/doc.doc.sh:17-23`

```bash
EXIT_SUCCESS=0          # Successful completion
EXIT_INVALID_ARGS=1     # Invalid command-line arguments
EXIT_FILE_ERROR=2       # File or directory access error
EXIT_PLUGIN_ERROR=3     # Plugin execution failed
EXIT_REPORT_ERROR=4     # Report generation failed
EXIT_WORKSPACE_ERROR=5  # Workspace corruption or access error
```

**Usage Locations**:
- `show_help()`: Line 92 (EXIT_SUCCESS)
- `show_version()`: Line 107 (EXIT_SUCCESS)
- `parse_arguments()`: Lines 157, 178, 188, 198, 208, 218, 231, 236 (EXIT_INVALID_ARGS)
- `main()`: Line 268 (EXIT_SUCCESS)

**Implementation Date**: 2026-02-06  
**Feature**: feature_0001  
**Status**: ✅ Implemented (codes 2-5 defined, not yet used)
