# ADR-0001: Use "Usage" Instead of "USAGE" in Help Text

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation  
**Feature Reference**: [Feature 0001: Basic Script Structure](../../../01_vision/02_features/feature_0001.md)

## Decision

Use "Usage:" (sentence case) instead of "USAGE:" (all caps) in the help text header.

## Context

Help text headers can follow different conventions:
- All caps: `USAGE:`, `OPTIONS:`, `EXAMPLES:` (traditional Unix man pages)
- Sentence case: `Usage:`, `Options:`, `Examples:` (modern CLI tools)

## Rationale

**User-Friendliness**:
- Sentence case is less aggressive and more approachable
- Modern CLI tools (git, npm, cargo) use sentence case
- Maintains professionalism while being welcoming

**Consistency**:
- All help text headers use sentence case: "Usage:", "Description:", "Options:", "Exit Codes:", "Examples:"
- Maintains visual consistency throughout help output

**Tradition vs. Modernity**:
- While traditional Unix tools use all caps, this is not a hard requirement
- Tool targets modern system administrators familiar with contemporary CLI conventions

## Alternatives Considered

1. **All caps** (`USAGE:`, `OPTIONS:`): Rejected - Too aggressive, dated feel
2. **Mixed** (some caps, some sentence case): Rejected - Inconsistent

## Impact

- **Alignment**: Minor deviation from traditional Unix convention
- **Risk**: Low - No functional impact, purely stylistic
- **Compatibility**: No impact on scripting or automation

## Related Decisions

- Applies to all help text sections: Usage, Description, Options, Exit Codes, Examples
