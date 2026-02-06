# ADR-0009: Entry Point Guard for Sourcing

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation  
**Feature Reference**: [Feature 0001: Basic Script Structure](../../../01_vision/02_features/feature_0001.md)

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
