# IDR-0001: Modular Function Architecture

**ID**: IDR-0001  
**Status**: Accepted  
**Created**: 2026-02-06  
**Last Updated**: 2026-02-08  
**Related ADRs**: [ADR-0007: Modular Component-Based Script Architecture](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0007_modular_component_based_script_architecture.md)

## Context

Feature 0001 (Basic Script Structure) required implementation of modular code organization. Bash scripts can be structured as:
1. Linear script (top to bottom)
2. Function-based with main entry point
3. Hybrid approach
4. Multiple source files (component-based architecture)

## Decision

Organize script into focused, single-responsibility functions within a single `doc.doc.sh` file, using function-based architecture with main entry point.

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

**Reason for Single-File Approach**:
- Simplifies deployment (single file to distribute)
- Reduces loader complexity (no explicit sourcing needed)
- Current scope manageable within single file (~500 lines)
- Easier for users to inspect and understand

## Deviation from Vision

**Vision ADR-0007 proposes component-based architecture** with separate files in `scripts/components/` directory organized by functional area (core/logging, platform/detection, plugin/discovery, etc.).

**This implementation deviates** by keeping all functions in a single `doc.doc.sh` file rather than splitting into separate component files.

**Reasoning**:
- **Deployment Simplicity**: Single file easier to distribute and install
- **Current Scope**: 510 lines manageable in single file for initial implementation  
- **Reduced Complexity**: No sourcing logic needed, simpler startup
- **Incremental Path**: Can refactor to component-based later if file grows beyond maintainability threshold

**Trade-off**: Accepts technical debt of monolithic file in exchange for deployment simplicity and implementation speed for initial release.

## Associated Risks

**Deviation from vision incurs technical debt documented in**: [debt_0001_monolithic_script_architecture.md](../11_risks_and_technical_debt/debt_0001_monolithic_script_architecture.md)

**Risk Summary**:
- **ID**: debt-0001
- **Status**: Accepted
- **Severity**: Medium
- **Impact**: As features grow, single-file approach will become harder to maintain, test, and extend. Will require refactoring to component-based architecture per ADR-0007.
- **Mitigation**: Monitor file size; refactor to component-based architecture when script exceeds 1000 lines or when parallel development conflicts increase.

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

1. **Monolithic script** (no functions): Rejected - Hard to maintain and test
2. **Component-based architecture** (separate files per ADR-0007): Deferred - Will implement when script exceeds 1000 lines or team size increases
3. **Object-oriented approach**: Rejected - Not idiomatic for Bash

## Consequences

### Positive
- ✅ Clear code structure for future contributors
- ✅ Easy to extend with new functions
- ✅ Testable components (when sourced)
- ✅ Single file simplifies deployment
- ✅ No source loading complexity

### Negative
- ❌ Does not follow ADR-0007 component-based architecture
- ❌ All code in single file limits parallel development
- ❌ Will require refactoring as script grows
- ❌ Testing requires sourcing entire file (cannot isolate single component)

## Implementation Notes

**Implemented Functions**:

| Function | Responsibility | Lines |
|----------|---------------|-------|
| `show_help()` | Display usage information | ~30 |
| `show_version()` | Display version info | ~10 |
| `detect_platform()` | Detect OS/distribution | ~15 |
| `log()` | Structured logging | ~7 |
| `error_exit()` | Error handling | ~5 |
| `parse_arguments()` | Argument parsing | ~80 |
| `main()` | Orchestration | ~10 |

**Design Principles**:
1. Single Responsibility: Each function does one thing
2. Clear Naming: Function name describes action
3. Documentation: Each function has header comment
4. Minimal global state: Functions operate on parameters where practical

**Script Organization**:
```bash
# 1. Metadata and constants
# 2. Utility functions (logging, error handling)
# 3. Feature functions (help, version, platform)
# 4. Core logic (argument parsing)
# 5. Main orchestration
# 6. Entry point guard
```

**Code Reference**: `scripts/doc.doc.sh` (entire script structure)

**Function Locations**:
- `log()`: Lines 32-49
- `show_help()`: Lines 52-92
- `show_version()`: Lines 98-107
- `detect_platform()`: Lines 113-130
- `error_exit()`: Lines 136-144
- `parse_arguments()`: Lines 152-241
- `main()`: Lines 247-268

## Related Items

- [ADR-0001: Bash as Primary Language](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0001_bash_as_primary_implementation_language.md) - Language choice enabling function-based architecture
- [ADR-0007: Modular Component-Based Architecture](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0007_modular_component_based_script_architecture.md) - Vision for component separation (not yet implemented)
- [IDR-0013: Entry Point Guard](IDR_0013_entry_point_guard.md) - Enables function testing
- [debt_0001: Monolithic Script Architecture](../11_risks_and_technical_debt/debt_0001_monolithic_script_architecture.md) - Technical debt from deviation
