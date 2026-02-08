# ADR-0007: Modular Function Architecture

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation  
**Feature Reference**: [Feature 0001: Basic Script Structure](../../../01_vision/02_features/feature_0001.md)

## Decision

Organize script into focused, single-responsibility functions rather than monolithic code.

## Context

Bash scripts can be structured as:
1. Linear script (top to bottom)
2. Function-based with main entry point
3. Hybrid approach

## Rationale

**Testability**:
- Functions can be tested independently (when sourced)
- Clear inputs and outputs

**Maintainability**:
- Single Responsibility Principle
- Easy to locate and modify specific behavior

**Reusability**:
- Functions can be called from multiple locations
- Facilitates future refactoring

**Readability**:
- Function names document intent
- Clear separation of concerns

## Implemented Functions

| Function | Responsibility | Lines |
|----------|---------------|-------|
| `show_help()` | Display usage information | ~30 |
| `show_version()` | Display version info | ~10 |
| `detect_platform()` | Detect OS/distribution | ~15 |
| `log()` | Structured logging | ~7 |
| `error_exit()` | Error handling | ~5 |
| `parse_arguments()` | Argument parsing | ~80 |
| `main()` | Orchestration | ~10 |

## Design Principles

1. **Single Responsibility**: Each function does one thing
2. **Clear Naming**: Function name describes action (`show_help`, `detect_platform`)
3. **Documentation**: Each function has header comment
4. **No Globals Modification** (where practical): Functions operate on parameters or explicit globals

## Script Organization

```bash
# 1. Metadata and constants
# 2. Utility functions (logging, error handling)
# 3. Feature functions (help, version, platform)
# 4. Core logic (argument parsing)
# 5. Main orchestration
# 6. Entry point guard
```

## Alternatives Considered

1. **Monolithic script**: Rejected - Hard to maintain and test
2. **Separate files**: Rejected - Over-engineered for current scope, complicates deployment
3. **Object-oriented approach**: Rejected - Not idiomatic for Bash

## Impact

- Clear code structure for future contributors
- Easy to extend with new functions
- Testable components (when sourced)
- Aligns with vision's component architecture

## Implementation Location

**Code Reference**: `scripts/doc.doc.sh` (entire script structure)

**Function Locations**:
- `log()`: Lines 32-49
- `show_help()`: Lines 52-92
- `show_version()`: Lines 98-107
- `detect_platform()`: Lines 113-130
- `error_exit()`: Lines 136-144
- `parse_arguments()`: Lines 152-241
- `main()`: Lines 247-268

**Organization Pattern**:
```bash
# Section 1: Constants (lines 6-23)
# Section 2: Utility functions (lines 32-144)
# Section 3: Core logic (lines 152-241)
# Section 4: Main orchestration (lines 247-268)
```

**Implementation Date**: 2026-02-06  
**Feature**: feature_0001  
**Status**: ✅ Implemented across entire script
