# IDR-0013: Entry Point Guard for Sourcing

**ID**: IDR-0013  
**Status**: Accepted  
**Created**: 2026-02-06  
**Last Updated**: 2026-02-08  
**Related ADRs**: [ADR-0001: Bash as Primary Language](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0001_bash_as_primary_implementation_language.md)

## Decision

Use entry point guard to prevent `main()` execution when script is sourced for testing.

## Context

Bash scripts can be:
1. Executed directly: `./doc.doc.sh`
2. Sourced: `source doc.doc.sh` (for testing functions)

## Rationale

**Testability**:
- Allows test scripts to source and call individual functions
- Prevents automatic execution during testing

**Pattern**:
```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

**Explanation**:
- `BASH_SOURCE[0]`: Path to script file
- `${0}`: Name of executed script
- If equal: Script executed directly → run main
- If different: Script sourced → skip main

## Example Usage

**Direct execution**:
```bash
$ ./doc.doc.sh -h
# main() executes, help shown
```

**Sourced for testing**:
```bash
$ source doc.doc.sh
$ show_help  # Call function directly
# main() not executed
```

## Alternatives Considered

1. **Always run main**: Rejected - Can't test functions in isolation
2. **Separate library file**: Rejected - Over-engineered for single script
3. **Explicit test mode flag**: Rejected - Entry point guard is simpler

## Impact

- Enables unit testing of individual functions
- No impact on normal execution
- Standard Bash testing pattern

## Implementation Location

**Code Reference**: `scripts/doc.doc.sh:265-267`

```bash
# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

**Usage in Tests**: Test scripts can source `doc.doc.sh` without triggering execution:
```bash
# In test script
source ../doc.doc.sh

# Now test individual functions
VERBOSE=true
log "INFO" "Test message"  # Call function directly
```

**Implementation Date**: 2026-02-06  
**Feature**: feature_0001  
**Status**: ✅ Implemented
