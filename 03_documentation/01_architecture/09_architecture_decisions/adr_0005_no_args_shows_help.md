# ADR-0005: No Arguments Shows Help (Not Error)

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation  
**Feature Reference**: [Feature 0001: Basic Script Structure](../../../01_vision/02_features/feature_0001.md)

## Decision

When called without arguments, display help and exit 0 (instead of showing error).

## Context

Script behavior when executed without arguments:
1. Show error ("required arguments missing")
2. Show help automatically
3. Do nothing and exit

## Rationale

**Discoverability**:
- New users can run `./doc.doc.sh` and immediately see available options
- Reduces barrier to entry (no need to know to add `-h`)

**User-Friendliness**:
- Assumes user exploring the tool, not making a mistake
- Help is more useful than error in this scenario

**Exit Code**:
- Exit 0 (not an error condition - no action requested)

## Implementation

```bash
parse_arguments() {
  if [[ $# -eq 0 ]]; then
    show_help
    exit "${EXIT_SUCCESS}"
  fi
  # ... rest of parsing
}
```

## Alternatives Considered

1. **Show error** (missing required args): Rejected - Less welcoming, assumes hostile user intent
2. **Do nothing**: Rejected - Confusing, no feedback to user

## Trade-offs

**Pros**:
- Improved discoverability
- Friendly to new users
- Common pattern in modern CLI tools

**Cons**:
- Future features will require arguments (`-d`, `-m`, etc.)
- May need to revisit when core functionality implemented

**Future Consideration**: When `-d`/`-m`/`-t`/`-w` are implemented and required, this behavior may change to require at least one operational argument. Current behavior is appropriate for framework-only implementation.

## Impact

- Positive user experience for exploration
- May need refinement in future features
- No breaking change (help already available via `-h`)
