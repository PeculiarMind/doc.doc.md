# ADR-0002: Guide Users with "Try --help" on Errors

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation  
**Feature Reference**: [Feature 0001: Basic Script Structure](../../../01_vision/02_features/feature_0001.md)

## Decision

All error messages related to invalid arguments include guidance: `Try 'doc.doc.sh --help' for more information.`

## Context

When users encounter argument errors, they need to know how to correct them. Options:
1. Show full help immediately
2. Show error only
3. Show error + guidance to help

## Rationale

**User Experience**:
- Provides actionable next step for users
- Avoids cluttering terminal with full help on every error
- Balances information density with discoverability

**Industry Standard**:
- Used by git, gcc, cargo, and other modern CLI tools
- Users expect this pattern

**Error Message Example**:
```
Error: Unknown option: -x
Try 'doc.doc.sh --help' for more information.
```

## Alternatives Considered

1. **Show full help on error**: Rejected - Too verbose, clutters output
2. **Error only**: Rejected - Leaves user without next steps
3. **Generic "See --help"**: Rejected - Less specific and actionable

## Implementation

**Pattern Applied to**:
- Unknown options (`-x`)
- Invalid arguments (`-d` without directory)
- Unexpected arguments
- Conflicting options (future)

**Exception**: Help explicitly requested (`-h`, `--help`) shows help without error

## Impact

- Consistent error messaging across script
- Improved user experience for error recovery
- Sets pattern for future error messages
