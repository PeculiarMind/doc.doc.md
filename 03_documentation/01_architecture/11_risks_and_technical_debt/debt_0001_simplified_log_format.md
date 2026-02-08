# DEBT-0001: Simplified Log Format

**ID**: debt-0001  
**Status**: Accepted  
**Priority**: Low  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08

## Description

Logging format simplified from vision specification. Current implementation uses `[LEVEL] Message` instead of `[TIMESTAMP] [LEVEL] [COMPONENT] Message`.

## Impact

**Severity**: LOW

Logs are functional and useful for current needs, but lack timestamp and component context that would be beneficial for:
- Debugging timing-sensitive issues
- Identifying which component generated a message
- Correlation of events across multiple tool executions

## Root Cause

**Decision**: Simplified for initial release (v1.0)

**Rationale**:
- Simpler implementation for MVP
- Timestamp adds noise for short-running script
- Component unnecessary with single-script architecture
- Adequate for current functionality

## Current Implementation

**Vision Specification**:
```bash
[2026-02-08 10:30:45] [INFO] [Plugin] Analyzing file.pdf
[2026-02-08 10:30:46] [ERROR] [Workspace] Failed to write metadata
```

**Current Implementation** (`doc.doc.sh:32-49`):
```bash
[INFO] Analyzing file.pdf
[ERROR] Failed to write metadata
```

## Mitigation Strategy

**Short-term**: Acceptable as-is for v1.x releases

**Long-term**: Add timestamps and component tags in future release (v2.0 candidate)

**Implementation Approach**:
- Add `--timestamps` flag for optional timestamp display
- Reserved `COMPONENT` parameter in `log()` function
- Maintain backward compatibility with current format

## Acceptance Criteria

**When is this debt resolved?**
- Log format matches vision specification: `[TIMESTAMP] [LEVEL] [COMPONENT] Message`
- Implementation maintains performance (negligible overhead)
- Backward compatibility maintained (old logs still readable)

## Related Items

- **Architecture Decision**: [09_architecture_decisions/ADR-000X_logging_strategy.md] (pending)
- **Deviation**: DEV-001 (documented deviation from vision)
- **Technical Debt**: TD-1 (same item)
- **Requirements**: req_0006 (verbose logging mode)
