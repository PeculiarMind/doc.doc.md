# Architecture Decisions - Feature 0001: Basic Script Structure

**Implementation Date**: 2026-02-06  
**Feature ID**: feature_0001  
**Status**: Implemented  
**Vision Reference**: [Architecture Decisions](../../../01_vision/03_architecture/09_architecture_decisions/09_architecture_decisions.md)

## Overview

This document records architectural decisions made during the implementation of the basic script structure (feature_0001). These decisions establish patterns and conventions that subsequent features will follow.

---

## AD-0001: Use "Usage" Instead of "USAGE" in Help Text

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation

### Decision

Use "Usage:" (sentence case) instead of "USAGE:" (all caps) in the help text header.

### Context

Help text headers can follow different conventions:
- All caps: `USAGE:`, `OPTIONS:`, `EXAMPLES:` (traditional Unix man pages)
- Sentence case: `Usage:`, `Options:`, `Examples:` (modern CLI tools)

### Rationale

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

### Alternatives Considered

1. **All caps** (`USAGE:`, `OPTIONS:`): Rejected - Too aggressive, dated feel
2. **Mixed** (some caps, some sentence case): Rejected - Inconsistent

### Impact

- **Alignment**: Minor deviation from traditional Unix convention
- **Risk**: Low - No functional impact, purely stylistic
- **Compatibility**: No impact on scripting or automation

### Related Decisions

- Applies to all help text sections: Usage, Description, Options, Exit Codes, Examples

---

## AD-0002: Guide Users with "Try --help" on Errors

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation

### Decision

All error messages related to invalid arguments include guidance: `Try 'doc.doc.sh --help' for more information.`

### Context

When users encounter argument errors, they need to know how to correct them. Options:
1. Show full help immediately
2. Show error only
3. Show error + guidance to help

### Rationale

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

### Alternatives Considered

1. **Show full help on error**: Rejected - Too verbose, clutters output
2. **Error only**: Rejected - Leaves user without next steps
3. **Generic "See --help"**: Rejected - Less specific and actionable

### Implementation

**Pattern Applied to**:
- Unknown options (`-x`)
- Invalid arguments (`-d` without directory)
- Unexpected arguments
- Conflicting options (future)

**Exception**: Help explicitly requested (`-h`, `--help`) shows help without error

### Impact

- Consistent error messaging across script
- Improved user experience for error recovery
- Sets pattern for future error messages

---

## AD-0003: Platform Detection Fallback Strategy

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation

### Decision

Implement three-tier platform detection: `/etc/os-release` → `uname -s` → "generic"

### Context

Platform detection must work across diverse environments:
- Modern Linux (has `/etc/os-release`)
- macOS (no `/etc/os-release`)
- Minimal containers (may lack `/etc/os-release`)
- BSDs, legacy systems

### Rationale

**Tier 1: `/etc/os-release`** (Primary):
- Standard on systemd-based Linux distributions
- Provides detailed information (ID, VERSION_ID, etc.)
- Most reliable for Linux platform-specific features

**Tier 2: `uname -s`** (Fallback):
- Universal availability on POSIX systems
- Provides basic OS identification
- Sufficient for high-level branching (Linux vs. Darwin)

**Tier 3: "generic"** (Default):
- Ensures script always has a platform value
- Enables graceful degradation of platform-specific features
- Prevents unset variable errors

### Implementation

```bash
detect_platform() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    PLATFORM="${ID:-generic}"  # Extract ID, fallback to generic
  else
    case "$(uname -s)" in
      Linux*)   PLATFORM="linux" ;;
      Darwin*)  PLATFORM="darwin" ;;
      CYGWIN*)  PLATFORM="cygwin" ;;
      MINGW*)   PLATFORM="mingw" ;;
      *)        PLATFORM="generic" ;;
    esac
  fi
  
  log "INFO" "Detected platform: ${PLATFORM}"
}
```

### Example Platform Values

| Environment | Detection | PLATFORM Value |
|-------------|-----------|----------------|
| Ubuntu | os-release | `ubuntu` |
| Debian | os-release | `debian` |
| Fedora | os-release | `fedora` |
| macOS | uname | `darwin` |
| Alpine (minimal) | os-release or uname | `alpine` or `linux` |
| Git Bash (Windows) | uname | `mingw` |
| Unknown | fallback | `generic` |

### Alternatives Considered

1. **Only uname**: Rejected - Less specific on Linux
2. **Only os-release**: Rejected - Breaks on macOS, older systems
3. **Complex detection (lsb_release, etc.)**: Rejected - Over-engineered, additional dependencies

### Impact

- **Portability**: Script runs on any POSIX system
- **Granularity**: Linux distributions identified specifically
- **Future Features**: Plugin discovery can check platform-specific directories (`plugins/ubuntu/`, `plugins/darwin/`)
- **Robustness**: Never fails platform detection (always has value)

---

## AD-0004: Log Level Design (INFO, WARN, ERROR, DEBUG)

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation

### Decision

Implement four log levels with conditional display: DEBUG, INFO (verbose only), WARN, ERROR (always shown).

### Context

Logging must serve two audiences:
1. **Regular users**: Want to see errors/warnings only
2. **Debugging users**: Want detailed execution trace

### Rationale

**Level Definitions**:
- **DEBUG**: Detailed diagnostic information (e.g., "Executing plugin: stat")
- **INFO**: Informational messages (e.g., "Detected platform: ubuntu")
- **WARN**: Warning messages (e.g., "Plugin tool not available")
- **ERROR**: Error messages (e.g., "Cannot read directory")

**Display Logic**:
```
Show message IF:
  (VERBOSE flag is true) OR
  (level is WARN) OR
  (level is ERROR)
```

**Output Stream**: All logs → stderr (separates diagnostics from data output)

### Design Principles

1. **Quiet by Default**: Users see errors/warnings only (clean output)
2. **Verbose for Debugging**: `-v` enables INFO and DEBUG messages
3. **Errors Always Shown**: Users always know when something fails
4. **Warnings Always Shown**: Users alerted to degraded functionality

### Implementation

```bash
log() {
  local level="$1"
  local message="$2"
  
  if [[ "${VERBOSE}" == true ]] || [[ "${level}" == "ERROR" ]] || [[ "${level}" == "WARN" ]]; then
    echo "[${level}] ${message}" >&2
  fi
}
```

### Example Outputs

**Normal mode** (quiet):
```bash
$ ./doc.doc.sh -x
[ERROR] Unknown option: -x
```

**Verbose mode**:
```bash
$ ./doc.doc.sh -v
[INFO] Verbose mode enabled
[INFO] Detected platform: ubuntu
[INFO] Script initialization complete
```

### Alternatives Considered

1. **Five levels** (TRACE, DEBUG, INFO, WARN, ERROR): Rejected - Over-engineered for Bash script
2. **Numeric levels**: Rejected - Less readable than named levels
3. **Separate verbose and debug flags**: Rejected - Complexity not justified

### Impact

- Clear separation between user messages and debug output
- Enables troubleshooting without code modification
- Follows industry conventions (similar to syslog levels)

---

## AD-0005: No Arguments Shows Help (Not Error)

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation

### Decision

When called without arguments, display help and exit 0 (instead of showing error).

### Context

Script behavior when executed without arguments:
1. Show error ("required arguments missing")
2. Show help automatically
3. Do nothing and exit

### Rationale

**Discoverability**:
- New users can run `./doc.doc.sh` and immediately see available options
- Reduces barrier to entry (no need to know to add `-h`)

**User-Friendliness**:
- Assumes user exploring the tool, not making a mistake
- Help is more useful than error in this scenario

**Exit Code**:
- Exit 0 (not an error condition - no action requested)

### Implementation

```bash
parse_arguments() {
  if [[ $# -eq 0 ]]; then
    show_help
    exit "${EXIT_SUCCESS}"
  fi
  # ... rest of parsing
}
```

### Alternatives Considered

1. **Show error** (missing required args): Rejected - Less welcoming, assumes hostile user intent
2. **Do nothing**: Rejected - Confusing, no feedback to user

### Trade-offs

**Pros**:
- Improved discoverability
- Friendly to new users
- Common pattern in modern CLI tools

**Cons**:
- Future features will require arguments (`-d`, `-m`, etc.)
- May need to revisit when core functionality implemented

**Future Consideration**: When `-d`/`-m`/`-t`/`-w` are implemented and required, this behavior may change to require at least one operational argument. Current behavior is appropriate for framework-only implementation.

### Impact

- Positive user experience for exploration
- May need refinement in future features
- No breaking change (help already available via `-h`)

---

## AD-0006: Bash Strict Mode (set -euo pipefail)

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation

### Decision

Enable Bash strict mode at script initialization: `set -euo pipefail`

### Context

Bash by default is permissive with errors and undefined variables. Options:
- Default behavior (permissive)
- Strict mode (fail-fast)
- Selective strictness

### Rationale

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

### Implementation

```bash
#!/usr/bin/env bash

# Exit on error, undefined variables, pipe failures
set -euo pipefail
```

**Placement**: Immediately after shebang (before any other code)

### Handling Exceptions

When intentional non-zero exits needed:
```bash
# Allow command to fail
if ! some_command; then
  handle_failure
fi

# Or
some_command || handle_failure
```

### Alternatives Considered

1. **No strict mode**: Rejected - Too many potential silent failures
2. **Only -e**: Rejected - Unset variables still dangerous
3. **Selective strict mode**: Rejected - Complexity not justified

### Impact

- **Safety**: Prevents common Bash scripting errors
- **Debugging**: Failures immediately visible
- **Maintenance**: Forces explicit error handling (good for long-term maintenance)

**Vision Alignment**: Consistent with quality requirements and error handling strategy

---

## AD-0007: Modular Function Architecture

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation

### Decision

Organize script into focused, single-responsibility functions rather than monolithic code.

### Context

Bash scripts can be structured as:
1. Linear script (top to bottom)
2. Function-based with main entry point
3. Hybrid approach

### Rationale

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

### Implemented Functions

| Function | Responsibility | Lines |
|----------|---------------|-------|
| `show_help()` | Display usage information | ~30 |
| `show_version()` | Display version info | ~10 |
| `detect_platform()` | Detect OS/distribution | ~15 |
| `log()` | Structured logging | ~7 |
| `error_exit()` | Error handling | ~5 |
| `parse_arguments()` | Argument parsing | ~80 |
| `main()` | Orchestration | ~10 |

### Design Principles

1. **Single Responsibility**: Each function does one thing
2. **Clear Naming**: Function name describes action (`show_help`, `detect_platform`)
3. **Documentation**: Each function has header comment
4. **No Globals Modification** (where practical): Functions operate on parameters or explicit globals

### Script Organization

```bash
# 1. Metadata and constants
# 2. Utility functions (logging, error handling)
# 3. Feature functions (help, version, platform)
# 4. Core logic (argument parsing)
# 5. Main orchestration
# 6. Entry point guard
```

### Alternatives Considered

1. **Monolithic script**: Rejected - Hard to maintain and test
2. **Separate files**: Rejected - Over-engineered for current scope, complicates deployment
3. **Object-oriented approach**: Rejected - Not idiomatic for Bash

### Impact

- Clear code structure for future contributors
- Easy to extend with new functions
- Testable components (when sourced)
- Aligns with vision's component architecture

---

## AD-0008: Exit Code System (0-5)

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation

### Decision

Define six exit codes (0-5) as named constants, each representing a specific failure category.

### Context

Script needs to communicate success/failure to calling processes. Options:
1. Simple (0=success, 1=failure)
2. Categorized (0=success, different codes for different failures)
3. Detailed (many exit codes for specific scenarios)

### Rationale

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

### Exit Code Definitions

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

### Usage in Code

```bash
# Success
exit "${EXIT_SUCCESS}"

# Argument error
exit "${EXIT_INVALID_ARGS}"

# Future: File error
error_exit "Cannot read directory" "${EXIT_FILE_ERROR}"
```

### Documentation

Exit codes documented in:
1. Help text (visible to users)
2. Code comments (visible to developers)
3. Architecture documentation (this document)

### Alternatives Considered

1. **Single error code** (0 and 1 only): Rejected - Insufficient granularity
2. **Many exit codes** (10+ codes): Rejected - Over-engineered for current scope
3. **Signal-based codes** (128+): Rejected - Not applicable (no signal handling yet)

### Impact

- Scripts can handle specific error types
- Clear communication of failure reason
- Prepared for future error scenarios (codes 2-5 currently unused but ready)

---

## AD-0009: Entry Point Guard for Sourcing

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation

### Decision

Use entry point guard to prevent `main()` execution when script is sourced for testing.

### Context

Bash scripts can be:
1. Executed directly: `./doc.doc.sh`
2. Sourced: `source doc.doc.sh` (for testing functions)

### Rationale

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

### Example Usage

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

### Alternatives Considered

1. **Always run main**: Rejected - Can't test functions in isolation
2. **Separate library file**: Rejected - Over-engineered for single script
3. **Explicit test mode flag**: Rejected - Entry point guard is simpler

### Impact

- Enables unit testing of individual functions
- No impact on normal execution
- Standard Bash testing pattern

---

## Summary of Architectural Decisions

| ID | Decision | Impact | Status |
|----|----------|--------|--------|
| AD-0001 | Use "Usage" (sentence case) | User-friendliness | ✅ Approved |
| AD-0002 | "Try --help" error guidance | User experience | ✅ Approved |
| AD-0003 | Three-tier platform detection | Portability | ✅ Approved |
| AD-0004 | Four log levels (DEBUG/INFO/WARN/ERROR) | Debugging capability | ✅ Approved |
| AD-0005 | No args shows help | Discoverability | ✅ Approved |
| AD-0006 | Bash strict mode | Safety, quality | ✅ Approved |
| AD-0007 | Modular function architecture | Maintainability | ✅ Approved |
| AD-0008 | Exit code system (0-5) | Scriptability | ✅ Approved |
| AD-0009 | Entry point guard | Testability | ✅ Approved |

---

## Alignment with Vision

All decisions align with vision principles:
- **Unix Philosophy**: Clean interface, composability (AD-0002, AD-0008)
- **Lightweight**: Minimal dependencies (AD-0003)
- **Quality**: Error handling, strictness (AD-0004, AD-0006)
- **Extensibility**: Modular architecture (AD-0007)
- **User-Focused**: Discoverability, guidance (AD-0001, AD-0005)

No decisions conflict with architecture vision. All establish patterns consistent with future feature development.
