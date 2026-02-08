# ADR-0006: Bash Strict Mode (set -euo pipefail)

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation  
**Feature Reference**: [Feature 0001: Basic Script Structure](../../../01_vision/02_features/feature_0001.md)

## Decision

Enable Bash strict mode at script initialization: `set -euo pipefail`

## Context

Bash by default is permissive with errors and undefined variables. Options:
- Default behavior (permissive)
- Strict mode (fail-fast)
- Selective strictness

## Rationale

**Error Prevention**:
- `-e`: Exit immediately if any command fails (prevents cascading errors)
- `-u`: Treat unset variables as errors (catches typos, missing initialization)
- `-o pipefail`: Return exit code of first failed command in pipeline

**Quality Assurance**:
- Forces explicit error handling
- Reveals bugs during development
- Industry best practice for Bash scripts

**Example Impact**:
```bash
# Without strict mode
cd "$NONEXISTENT_DIR"  # Fails silently, continues in wrong directory
rm -rf *               # Potentially catastrophic

# With strict mode
cd "$NONEXISTENT_DIR"  # Script exits immediately, rm never executes
```

## Implementation

```bash
#!/usr/bin/env bash

# Exit on error, undefined variables, pipe failures
set -euo pipefail
```

**Placement**: Immediately after shebang (before any other code)

## Handling Exceptions

When intentional non-zero exits needed:
```bash
# Allow command to fail
if ! some_command; then
  handle_failure
fi

# Or
some_command || handle_failure
```

## Alternatives Considered

1. **No strict mode**: Rejected - Too many potential silent failures
2. **Only -e**: Rejected - Unset variables still dangerous
3. **Selective strict mode**: Rejected - Complexity not justified

## Impact

- **Safety**: Prevents common Bash scripting errors
- **Debugging**: Failures immediately visible
- **Maintenance**: Forces explicit error handling (good for long-term maintenance)

**Vision Alignment**: Consistent with quality requirements and error handling strategy

## Implementation Location

**Code Reference**: `scripts/doc.doc.sh:4`

```bash
#!/usr/bin/env bash

# Exit on error, undefined variables, pipe failures
set -euo pipefail
```

**Implementation Date**: 2026-02-06  
**Feature**: feature_0001  
**Status**: ✅ Implemented
