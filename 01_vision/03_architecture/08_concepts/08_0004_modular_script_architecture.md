## 0004 Modular Script Architecture

## Table of Contents

- [Rationale](#rationale)
- [Current Monolithic Structure](#current-monolithic-structure)
- [Target Modular Architecture](#target-modular-architecture)
- [Component Identification](#component-identification)
- [Component Interface Contracts](#component-interface-contracts)
- [Directory Structure](#directory-structure)
- [Orchestration Pattern](#orchestration-pattern)
- [Component Loading Strategy](#component-loading-strategy)
- [Error Handling and Propagation](#error-handling-and-propagation)
- [Testing Strategy](#testing-strategy)
- [Migration Path](#migration-path)
- [Related Requirements](#related-requirements)

The system shall transition from a monolithic script architecture to a modular component-based architecture where functionality is separated into distinct, reusable components orchestrated by a lightweight entry script.

## Rationale

**Maintainability**:
- Single Responsibility: Each component owns one logical function area
- Reduced Cognitive Load: Developers work on smaller, focused code units
- Easier Debugging: Isolate issues to specific components
- Clearer Code Organization: Explicit boundaries between functionalities

**Testability**:
- Unit Testing: Test components independently
- Mock Dependencies: Replace components with test doubles
- Faster Test Execution: Test only changed components
- Higher Code Coverage: Easier to cover all code paths

**Reusability**:
- Component Sharing: Use components across multiple tools
- Library Building: Components become building blocks
- Reduced Duplication: Common logic centralized

**Separation of Concerns**:
- Clear Boundaries: Each component has well-defined responsibilities
- Loose Coupling: Components depend on interfaces, not implementations
- High Cohesion: Related functionality grouped together

**Extensibility**:
- Add Features: New components without modifying existing ones
- Replace Components: Swap implementations without affecting others
- Plugin Support: External components follow same pattern

## Current Monolithic Structure

The current `doc.doc.sh` script (510 lines) contains all functionality in a single file:

```bash
#!/usr/bin/env bash
# Sections:
# - Script Metadata (lines 1-14)
# - Exit Codes (lines 16-21)
# - Global Flags (lines 23-26)
# - Logging Functions (lines 28-45)
# - Help System (lines 47-92)
# - Version Information (lines 94-104)
# - Platform Detection (lines 106-124)
# - Error Handling (lines 126-137)
# - Plugin Management (lines 139-382)
# - Argument Parsing (lines 384-490)
# - Main Entry Point (lines 492-510)
```

**Problems with Current Structure**:
- Single point of change: Modifications to any feature touch the same file
- Testing challenges: Cannot test components independently
- Merge conflicts: Multiple developers working on different features conflict
- Difficult refactoring: Changes risk breaking unrelated functionality
- Code navigation: Finding specific logic requires scrolling through entire file
- Reuse limitations: Cannot use logging or error handling in other scripts

## Target Modular Architecture

Transform into component-based architecture with clear separation:

```
scripts/
├── doc.doc.sh                    # Entry point (100-150 lines)
├── template.doc.doc.md           # Report template (unchanged)
├── components/                   # Component library
│   ├── core/                     # Core infrastructure
│   │   ├── constants.sh          # Script metadata, exit codes
│   │   ├── logging.sh            # Logging functions
│   │   ├── error_handling.sh    # Error management
│   │   └── platform_detection.sh # OS/platform detection
│   ├── ui/                       # User interface
│   │   ├── help_system.sh        # Help display
│   │   ├── version_info.sh       # Version information
│   │   └── argument_parser.sh    # CLI argument parsing
│   ├── plugin/                   # Plugin management
│   │   ├── plugin_discovery.sh   # Find and validate plugins
│   │   ├── plugin_parser.sh      # Parse descriptor.json
│   │   └── plugin_display.sh     # Format plugin lists
│   └── orchestration/            # Future components
│       ├── file_scanner.sh       # Directory scanning (future)
│       ├── analysis_engine.sh    # Coordinate analysis (future)
│       └── report_generator.sh   # Generate reports (future)
└── plugins/                      # Plugins (unchanged)
    ├── all/
    └── ubuntu/
```

**Architecture Principles**:
- **Entry Script Responsibility**: Load components, initialize, delegate to components
- **Component Responsibility**: Single focused task, well-defined interface
- **No Cross-Dependencies**: Components depend only on core, not each other
- **Interface-Based**: Components expose functions, not implementation details

## Component Identification

### Current Script Analysis

| Lines     | Section              | Component Target                | LOC  |
| --------- | -------------------- | ------------------------------- | ---- |
| 1-14      | Metadata             | `core/constants.sh`             | ~20  |
| 16-21     | Exit Codes           | `core/constants.sh`             | ~10  |
| 23-26     | Global Flags         | `core/constants.sh`             | ~10  |
| 28-45     | Logging              | `core/logging.sh`               | ~30  |
| 47-92     | Help System          | `ui/help_system.sh`             | ~50  |
| 94-104    | Version Info         | `ui/version_info.sh`            | ~15  |
| 106-124   | Platform Detection   | `core/platform_detection.sh`    | ~25  |
| 126-137   | Error Handling       | `core/error_handling.sh`        | ~20  |
| 139-382   | Plugin Management    | `plugin/*.sh` (3 files)         | ~250 |
| 384-490   | Argument Parsing     | `ui/argument_parser.sh`         | ~120 |
| 492-510   | Main Entry           | `doc.doc.sh` (entry)            | ~25  |
| **Total** | **~510 lines**       | **~575 lines** (with docs/test) |      |

**Component Breakdown Details**:

1. **core/constants.sh** (~40 lines)
   - `SCRIPT_NAME`, `SCRIPT_VERSION`, `SCRIPT_DIR`
   - `SCRIPT_COPYRIGHT`, `SCRIPT_LICENSE`
   - All `EXIT_*` codes
   - Global flags: `VERBOSE`, `PLATFORM`

2. **core/logging.sh** (~30 lines)
   - `log()` function
   - Future: log levels, log file output

3. **core/error_handling.sh** (~20 lines)
   - `error_exit()` function
   - Future: error recovery, cleanup handlers

4. **core/platform_detection.sh** (~25 lines)
   - `detect_platform()` function
   - Sets global `PLATFORM`

5. **ui/help_system.sh** (~50 lines)
   - `show_help()` function
   - Help text content

6. **ui/version_info.sh** (~15 lines)
   - `show_version()` function
   - Version display formatting

7. **ui/argument_parser.sh** (~120 lines)
   - `parse_arguments()` function
   - All argument handling logic

8. **plugin/plugin_parser.sh** (~80 lines)
   - `parse_plugin_descriptor()` function
   - JSON parsing logic (jq/python fallback)

9. **plugin/plugin_discovery.sh** (~120 lines)
   - `discover_plugins()` function
   - Platform-specific and cross-platform search
   - Deduplication logic

10. **plugin/plugin_display.sh** (~50 lines)
    - `display_plugin_list()` function
    - `list_plugins()` function
    - Formatting logic

## Component Interface Contracts

### Core Components

#### core/constants.sh
```bash
# Provides: Global constants and exit codes
# Dependencies: None
# Exports:
#   - SCRIPT_NAME (readonly)
#   - SCRIPT_VERSION (readonly)
#   - SCRIPT_DIR (readonly)
#   - SCRIPT_COPYRIGHT (readonly)
#   - SCRIPT_LICENSE (readonly)
#   - EXIT_SUCCESS, EXIT_INVALID_ARGS, etc. (readonly)
#   - VERBOSE (mutable)
#   - PLATFORM (mutable)
# Exit Codes: None (constant definitions only)
# Side Effects: None
```

#### core/logging.sh
```bash
# Provides: Logging functionality
# Dependencies: core/constants.sh (VERBOSE flag)
# Exports:
#   - log(level, message)
# Parameters:
#   - level: INFO|WARN|ERROR|DEBUG
#   - message: string
# Exit Codes: None
# Side Effects: Writes to stderr
# Global State: Reads VERBOSE flag
```

#### core/error_handling.sh
```bash
# Provides: Error handling and exit
# Dependencies: core/logging.sh, core/constants.sh
# Exports:
#   - error_exit(message, [exit_code])
# Parameters:
#   - message: string (required)
#   - exit_code: integer (optional, defaults to EXIT_FILE_ERROR)
# Exit Codes: Terminates with specified exit code
# Side Effects: Logs error, terminates script
```

#### core/platform_detection.sh
```bash
# Provides: Platform/OS detection
# Dependencies: core/logging.sh, core/constants.sh
# Exports:
#   - detect_platform()
# Parameters: None
# Returns: Sets global PLATFORM variable
# Exit Codes: None
# Side Effects: Reads /etc/os-release, modifies PLATFORM
# Global State: Modifies PLATFORM
```

### UI Components

#### ui/help_system.sh
```bash
# Provides: Help information display
# Dependencies: core/constants.sh (metadata)
# Exports:
#   - show_help()
# Parameters: None
# Exit Codes: None (caller decides exit)
# Side Effects: Writes to stdout
```

#### ui/version_info.sh
```bash
# Provides: Version information display
# Dependencies: core/constants.sh (version metadata)
# Exports:
#   - show_version()
# Parameters: None
# Exit Codes: None (caller decides exit)
# Side Effects: Writes to stdout
```

#### ui/argument_parser.sh
```bash
# Provides: Command-line argument parsing
# Dependencies: 
#   - core/constants.sh (exit codes, VERBOSE)
#   - core/logging.sh (log function)
#   - core/error_handling.sh (error_exit)
#   - ui/help_system.sh (show_help)
#   - ui/version_info.sh (show_version)
#   - plugin/plugin_display.sh (list_plugins)
# Exports:
#   - parse_arguments(args...)
# Parameters: "$@" from main script
# Exit Codes: May exit with EXIT_SUCCESS or EXIT_INVALID_ARGS
# Side Effects: Modifies VERBOSE, may call subcommands, may exit
# Global State: Modifies VERBOSE
```

### Plugin Components

#### plugin/plugin_parser.sh
```bash
# Provides: Plugin descriptor parsing
# Dependencies: core/logging.sh, core/error_handling.sh, core/constants.sh
# Exports:
#   - parse_plugin_descriptor(descriptor_path)
# Parameters:
#   - descriptor_path: absolute path to descriptor.json
# Returns: Echoes "name|description|active" or returns 1
# Exit Codes: 
#   - 0: Success
#   - 1: Parse failure
#   - EXIT_PLUGIN_ERROR: No JSON parser available (error_exit)
# Side Effects: None (pure function except error_exit on missing tools)
# External Tools: jq (preferred), python3 (fallback)
```

#### plugin/plugin_discovery.sh
```bash
# Provides: Plugin discovery in filesystem
# Dependencies: 
#   - core/constants.sh (SCRIPT_DIR, PLATFORM, exit codes)
#   - core/logging.sh (log)
#   - core/error_handling.sh (error_exit)
#   - plugin/plugin_parser.sh (parse_plugin_descriptor)
# Exports:
#   - discover_plugins()
# Parameters: None
# Returns: Echoes newline-separated "name|description|active" strings
# Exit Codes:
#   - 0: Success (even if no plugins found)
#   - EXIT_FILE_ERROR: Plugin directory missing (error_exit)
# Side Effects: Reads filesystem
# Global State: Reads SCRIPT_DIR, PLATFORM
```

#### plugin/plugin_display.sh
```bash
# Provides: Plugin list formatting and display
# Dependencies: plugin/plugin_discovery.sh, core/logging.sh
# Exports:
#   - display_plugin_list(plugin_data_array...)
#   - list_plugins()
# Parameters:
#   - display_plugin_list: array of "name|description|active" strings
#   - list_plugins: none
# Exit Codes: None
# Side Effects: Writes to stdout
```

## Directory Structure

```
scripts/
├── doc.doc.sh                               # Entry point orchestrator
├── template.doc.doc.md                      # Existing template
├── components/                              # Component library
│   ├── README.md                            # Component documentation
│   ├── core/                                # Core infrastructure
│   │   ├── constants.sh                     # Metadata, exit codes, globals
│   │   ├── logging.sh                       # Logging system
│   │   ├── error_handling.sh                # Error management
│   │   └── platform_detection.sh            # Platform detection
│   ├── ui/                                  # User interface components
│   │   ├── help_system.sh                   # Help display
│   │   ├── version_info.sh                  # Version info
│   │   └── argument_parser.sh               # Argument parsing
│   ├── plugin/                              # Plugin management
│   │   ├── plugin_parser.sh                 # Descriptor parsing
│   │   ├── plugin_discovery.sh              # Plugin discovery
│   │   └── plugin_display.sh                # Display formatting
│   └── orchestration/                       # Future: Analysis components
│       ├── file_scanner.sh                  # (Future)
│       ├── analysis_engine.sh               # (Future)
│       └── report_generator.sh              # (Future)
└── plugins/                                 # Existing plugin directory
    ├── all/                                 # Cross-platform plugins
    └── ubuntu/                              # Platform-specific plugins
```

**Component Organization Rules**:
- **Core**: Infrastructure used by multiple components
- **UI**: User-facing interface components
- **Plugin**: Plugin system components
- **Orchestration**: Analysis workflow components (future)

**Naming Conventions**:
- Lowercase with underscores: `error_handling.sh`
- Descriptive names reflecting single responsibility
- `.sh` extension for all component files

## Orchestration Pattern

### Entry Script Responsibilities

The entry script (`doc.doc.sh`) becomes a lightweight orchestrator:

```bash
#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Component Loading
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Define component loading function
source_component() {
  local component_path="$1"
  local full_path="${SCRIPT_DIR}/components/${component_path}"
  
  if [[ ! -f "${full_path}" ]]; then
    echo "ERROR: Required component not found: ${component_path}" >&2
    exit 2
  fi
  
  # shellcheck source=/dev/null
  source "${full_path}"
}

# ==============================================================================
# Load Components in Dependency Order
# ==============================================================================

# Core components (no dependencies)
source_component "core/constants.sh"
source_component "core/logging.sh"
source_component "core/error_handling.sh"
source_component "core/platform_detection.sh"

# UI components (depend on core)
source_component "ui/help_system.sh"
source_component "ui/version_info.sh"

# Plugin components (depend on core)
source_component "plugin/plugin_parser.sh"
source_component "plugin/plugin_discovery.sh"
source_component "plugin/plugin_display.sh"

# Argument parser (depends on core, ui, plugin)
source_component "ui/argument_parser.sh"

# ==============================================================================
# Main Entry Point
# ==============================================================================

main() {
  # Initialize platform detection
  detect_platform
  
  # Parse command-line arguments
  parse_arguments "$@"
  
  # If we get here, no action was taken
  log "INFO" "Script initialization complete"
  
  exit "${EXIT_SUCCESS}"
}

# Execute main
main "$@"
```

**Orchestration Design Principles**:
1. **Explicit Loading**: Source components explicitly, not dynamically
2. **Dependency Order**: Load in order that respects dependencies
3. **Fail Fast**: Exit immediately if component missing
4. **Minimal Logic**: Entry script contains no business logic
5. **Clear Flow**: main() delegates to loaded components

## Component Loading Strategy

### Static Sourcing (Chosen Approach)

**Method**: Explicit `source` statements in dependency order

**Advantages**:
- **Explicit Dependencies**: Clear what components are needed
- **Fast Loading**: No directory scanning at runtime
- **ShellCheck Compatible**: Static analysis works correctly
- **Predictable Order**: Load order under full control
- **Simple Debugging**: No dynamic loading magic

**Disadvantages**:
- **Manual Maintenance**: Must update when adding components
- **Verbose**: More lines in entry script

### Alternative: Dynamic Component Discovery (Rejected)

**Method**: Loop through `components/` and auto-load

```bash
# NOT RECOMMENDED
for component in "${SCRIPT_DIR}"/components/**/*.sh; do
  source "${component}"
done
```

**Rejected Because**:
- ❌ Unpredictable load order (dependency conflicts)
- ❌ Slower (unnecessary globbing)
- ❌ ShellCheck cannot analyze
- ❌ Harder to debug (implicit dependencies)

### source_component() Function Design

```bash
source_component() {
  local component_path="$1"
  local full_path="${SCRIPT_DIR}/components/${component_path}"
  
  # Validate component exists
  if [[ ! -f "${full_path}" ]]; then
    echo "ERROR: Required component not found: ${component_path}" >&2
    exit 2
  fi
  
  # Validate component is readable
  if [[ ! -r "${full_path}" ]]; then
    echo "ERROR: Cannot read component: ${component_path}" >&2
    exit 2
  fi
  
  # shellcheck source=/dev/null
  source "${full_path}"
}
```

**Function Responsibilities**:
- Resolve relative component path to absolute
- Validate component file exists and is readable
- Source component into current shell context
- Use direct exit (not error_exit, as logging may not be loaded yet)
- Suppress ShellCheck source warnings (components loaded dynamically)

## Error Handling and Propagation

### Component-Level Error Handling

**Principle**: Components handle their own errors, propagate via exit codes

```bash
# In plugin/plugin_parser.sh
parse_plugin_descriptor() {
  local descriptor_path="$1"
  
  # Validation
  if [[ ! -f "${descriptor_path}" ]]; then
    log "WARN" "Descriptor file not found: ${descriptor_path}"
    return 1  # Non-fatal, continue processing
  fi
  
  if [[ ! -r "${descriptor_path}" ]]; then
    log "WARN" "Cannot read descriptor: ${descriptor_path}"
    return 1  # Non-fatal, continue processing
  fi
  
  # Critical error: no JSON parser
  if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    error_exit "No JSON parser available" "${EXIT_PLUGIN_ERROR}"
  fi
  
  # ... parsing logic ...
  
  echo "${result}"
  return 0
}
```

**Error Handling Patterns**:
- **return 1**: Non-fatal errors (skip item, continue processing)
- **error_exit()**: Fatal errors (cannot continue)
- **log WARN**: Recoverable issues
- **log ERROR**: Before error_exit

### Entry Script Error Handling

**Responsibility**: Minimal, rely on `set -euo pipefail`

```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Component loading errors: direct exit (no logging available yet)
source_component "core/constants.sh" || exit 2

# After components loaded: use error_handling.sh
main() {
  detect_platform || error_exit "Platform detection failed" "${EXIT_FILE_ERROR}"
  
  parse_arguments "$@"  # May exit internally with various codes
  
  exit "${EXIT_SUCCESS}"
}
```

### Error Code Strategy

Use exit codes from `core/constants.sh`:
- `EXIT_SUCCESS=0`: Normal completion
- `EXIT_INVALID_ARGS=1`: Bad command-line arguments
- `EXIT_FILE_ERROR=2`: File access issues, missing components
- `EXIT_PLUGIN_ERROR=3`: Plugin system failures
- `EXIT_REPORT_ERROR=4`: Report generation failures
- `EXIT_WORKSPACE_ERROR=5`: Workspace corruption

## Testing Strategy

### Unit Testing Components

Each component testable independently:

```bash
# tests/unit/test_logging.sh
#!/usr/bin/env bash

# Setup: Load only required components
source "$(dirname "$0")/../../scripts/components/core/constants.sh"
source "$(dirname "$0")/../../scripts/components/core/logging.sh"

# Test: Logging with verbose off
test_logging_verbose_off() {
  VERBOSE=false
  output=$(log "INFO" "Test message" 2>&1)
  [[ -z "${output}" ]] || return 1
}

# Test: Logging with verbose on
test_logging_verbose_on() {
  VERBOSE=true
  output=$(log "INFO" "Test message" 2>&1)
  [[ "${output}" == "[INFO] Test message" ]] || return 1
}

# Test: Error level always shows
test_logging_error_always_shows() {
  VERBOSE=false
  output=$(log "ERROR" "Error message" 2>&1)
  [[ "${output}" == "[ERROR] Error message" ]] || return 1
}

# Execute tests
test_logging_verbose_off && echo "✓ test_logging_verbose_off"
test_logging_verbose_on && echo "✓ test_logging_verbose_on"
test_logging_error_always_shows && echo "✓ test_logging_error_always_shows"
```

**Unit Test Structure**:
- **Isolated**: Test single component
- **Fast**: No external dependencies
- **Repeatable**: Same result every time
- **Clear Assertions**: Pass/fail obvious

### Integration Testing

Test component combinations:

```bash
# tests/integration/test_plugin_system.sh
#!/usr/bin/env bash

# Load component chain
source_component "core/constants.sh"
source_component "core/logging.sh"
source_component "core/error_handling.sh"
source_component "plugin/plugin_parser.sh"
source_component "plugin/plugin_discovery.sh"

# Test: Full plugin discovery workflow
test_plugin_discovery_workflow() {
  VERBOSE=true
  PLATFORM="ubuntu"
  
  plugins=$(discover_plugins)
  
  # Verify plugins found
  [[ -n "${plugins}" ]] || return 1
  
  # Verify format
  echo "${plugins}" | grep -q "|" || return 1
}
```

### Mock Components for Testing

Create test doubles:

```bash
# tests/mocks/core/platform_detection.sh
# Mock that always returns "ubuntu"
detect_platform() {
  PLATFORM="ubuntu"
  log "INFO" "Detected platform: ${PLATFORM} (MOCKED)"
}
```

Use in tests:

```bash
# Load mock instead of real component
source "tests/mocks/core/platform_detection.sh"

# Now test behavior with controlled platform
```

## Migration Path

### Phase 1: Extract Core Components

**Goal**: Extract reusable infrastructure without changing behavior

**Steps**:
1. Create `scripts/components/core/` directory
2. Extract `constants.sh` (metadata, exit codes, globals)
3. Extract `logging.sh`
4. Extract `error_handling.sh`
5. Extract `platform_detection.sh`
6. Update entry script to source components
7. Run all existing tests (should pass)

**Risk**: Low (pure extraction, no logic changes)

### Phase 2: Extract UI Components

**Goal**: Separate user interface from logic

**Steps**:
1. Create `scripts/components/ui/` directory
2. Extract `help_system.sh`
3. Extract `version_info.sh`
4. Update entry script
5. Run tests

**Risk**: Low (no dependencies between UI components)

### Phase 3: Extract Plugin Components

**Goal**: Modularize complex plugin management logic

**Steps**:
1. Create `scripts/components/plugin/` directory
2. Extract `plugin_parser.sh` (most complex)
3. Extract `plugin_discovery.sh`
4. Extract `plugin_display.sh`
5. Extract `argument_parser.sh` (depends on plugins)
6. Update entry script
7. Run comprehensive plugin tests

**Risk**: Medium (complex logic, many dependencies)

### Phase 4: Refine and Document

**Goal**: Polish and establish patterns

**Steps**:
1. Create `scripts/components/README.md`
2. Document component contracts
3. Add ShellCheck directives
4. Improve error messages
5. Add integration tests

**Risk**: Low (documentation and polish)

### Phase 5: Future Extensibility

**Goal**: Enable new feature development with modular pattern

**Steps**:
1. Create `scripts/components/orchestration/` directory
2. Implement new features as components:
   - `file_scanner.sh`
   - `analysis_engine.sh`
   - `report_generator.sh`
3. Follow established patterns

**Risk**: Low (greenfield, established patterns)

### Rollback Strategy

If issues arise during migration:

1. **Git Safety**: Each phase is separate commit(s)
2. **Feature Flag**: Keep monolithic version as fallback:
   ```bash
   if [[ "${USE_MODULAR_ARCHITECTURE}" == "true" ]]; then
     source_components
   else
     # Monolithic code path
   fi
   ```
3. **Incremental Rollout**: Test each phase before proceeding

## Related Requirements

- [REQ-0001: Single Command Directory Analysis](../../02_requirements/03_accepted/req_0001_single_command_directory_analysis.md)
- [REQ-0006: Verbose Logging Mode](../../02_requirements/03_accepted/req_0006_verbose_logging_mode.md)

**Future Requirements Enabled by Modularization**:
- Parallel plugin execution (component independence)
- Plugin hot-reloading (isolated plugin components)
- Distributed analysis (reusable components across nodes)
- Alternative entry points (CLI vs. daemon vs. library)
