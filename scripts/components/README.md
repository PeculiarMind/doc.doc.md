# Component Architecture

## Overview

This directory contains the modular component architecture for doc.doc.sh. The monolithic script has been refactored into discrete, reusable components organized by domain and responsibility.

## Table of Contents

- [Architecture Principles](#architecture-principles)
- [Component Directory Structure](#component-directory-structure)
- [Component Dependency Graph](#component-dependency-graph)
- [Loading Order](#loading-order)
- [Component Guidelines](#component-guidelines)
- [Adding New Components](#adding-new-components)

## Architecture Principles

- **Single Responsibility**: Each component has one clear purpose
- **Explicit Dependencies**: Components declare their dependencies in headers
- **Independent Testability**: Components can be sourced and tested in isolation
- **Clear Interfaces**: Functions follow consistent naming and parameter conventions
- **Minimal Side Effects**: Side effects are documented and minimized

## Component Directory Structure

```
scripts/
├── doc.doc.sh              # Entry script (83 lines)
└── components/
    ├── README.md           # This file
    ├── core/               # Core utilities (foundation layer)
    │   ├── constants.sh    # Global constants and configuration
    │   ├── logging.sh      # Logging infrastructure
    │   ├── error_handling.sh  # Error handling and cleanup
    │   └── platform_detection.sh  # Platform detection
    ├── ui/                 # User interface (presentation layer)
    │   ├── help_system.sh  # Help text and documentation
    │   ├── version_info.sh # Version information display
    │   └── argument_parser.sh  # CLI argument parsing
    ├── plugin/             # Plugin management (domain layer)
    │   ├── plugin_parser.sh    # JSON descriptor parsing
    │   ├── plugin_discovery.sh # Plugin discovery and validation
    │   ├── plugin_display.sh   # Plugin listing and formatting
    │   └── plugin_executor.sh  # Plugin execution orchestration
    └── orchestration/      # Workflow orchestration (domain layer)
        ├── scanner.sh          # Directory and file scanning
        ├── workspace.sh        # Workspace management
        ├── template_engine.sh  # Template processing
        └── report_generator.sh # Report generation
```

## Component Dependency Graph

```
constants.sh (no dependencies)
    ├── logging.sh
    │   ├── error_handling.sh
    │   ├── platform_detection.sh
    │   ├── help_system.sh
    │   ├── version_info.sh
    │   ├── argument_parser.sh (also uses help_system.sh, version_info.sh)
    │   ├── plugin_parser.sh
    │   ├── scanner.sh (also uses workspace.sh)
    │   └── template_engine.sh
    ├── help_system.sh
    └── version_info.sh

platform_detection.sh (uses logging.sh)
    └── plugin_discovery.sh (also uses plugin_parser.sh)

plugin_parser.sh (uses logging.sh)
    ├── plugin_discovery.sh (also uses platform_detection.sh)
    └── plugin_display.sh (also uses plugin_discovery.sh)

plugin_discovery.sh
    ├── plugin_display.sh
    └── plugin_executor.sh (also uses workspace.sh)

workspace.sh (uses logging.sh, error_handling.sh)
    ├── scanner.sh (also uses logging.sh)
    ├── plugin_executor.sh (also uses plugin_discovery.sh)
    └── report_generator.sh (also uses template_engine.sh)

template_engine.sh (uses logging.sh)
    └── report_generator.sh (also uses workspace.sh)
```

## Loading Order

Components must be loaded in dependency order. The entry script (`doc.doc.sh`) loads them as follows:

```bash
# Core (foundation - no dependencies)
source_component "core/constants.sh"
source_component "core/logging.sh"
source_component "core/error_handling.sh"
source_component "core/platform_detection.sh"

# UI (depends on core)
source_component "ui/help_system.sh"
source_component "ui/version_info.sh"
source_component "ui/argument_parser.sh"

# Plugin (depends on core)
source_component "plugin/plugin_parser.sh"
source_component "plugin/plugin_discovery.sh"
source_component "plugin/plugin_display.sh"

# Orchestration (depends on core and plugin)
source_component "orchestration/workspace.sh"
source_component "orchestration/scanner.sh"
source_component "orchestration/template_engine.sh"
source_component "orchestration/report_generator.sh"
source_component "plugin/plugin_executor.sh"  # Last (depends on orchestration)
```

**Rationale**:
- Core components first (no dependencies)
- UI and plugin components next (depend only on core)
- Orchestration components last (depend on core and plugin)

## Component Guidelines

### Component Header Format

Every component must include a header comment:

```bash
#!/usr/bin/env bash
# Component: <name>
# Purpose: <one-line description>
# Dependencies: <component1>, <component2>
# Exports: <function1>, <function2>
# Side Effects: <description or "None">
```

### Function Naming Convention

Functions follow `verb_noun()` pattern:
- `parse_arguments` (not `argumentParser`)
- `load_workspace` (not `loadWorkspace`)
- `detect_platform` (not `getPlatform`)

### Local Variables

All local variables must use `local` keyword:

```bash
my_function() {
  local param="$1"
  local result=""
  # ...
}
```

### Return Values

- Exit codes via `return`: `return 0` for success, `return 1` for failure
- Data output via `echo`: `echo "result"`
- Never use `exit` inside components (except error_exit in error_handling.sh)

### No Cross-Dependencies

Components at the same level should not depend on each other:
- ✅ `ui/help_system.sh` can depend on `core/logging.sh`
- ❌ `ui/help_system.sh` should NOT depend on `ui/version_info.sh`
- ✅ `plugin/plugin_display.sh` can depend on `plugin/plugin_discovery.sh` (different levels)

## Adding New Components

### 1. Create Component File

Choose appropriate directory based on domain:
- `core/` - Foundation utilities used by everyone
- `ui/` - User interface and presentation
- `plugin/` - Plugin-related functionality
- `orchestration/` - Workflow and process orchestration

### 2. Add Component Header

Include required documentation header with:
- Component name
- Purpose (one line)
- Dependencies (other components)
- Exports (function names)
- Side effects (or "None")

### 3. Implement Functions

Follow naming conventions and coding standards:
- Use `verb_noun()` naming
- Use `local` for all local variables
- Return via `return` (codes) or `echo` (data)
- Document complex logic with comments

### 4. Update Entry Script

Add `source_component` call in correct dependency order in `doc.doc.sh`.

### 5. Create Unit Tests

Add test file in `tests/unit/test_<component>.sh`:

```bash
#!/usr/bin/env bash
# Test: <component>

# Load test helpers
source "$(dirname "$0")/../helpers/test_helpers.sh"

# Load component dependencies
source "${REPO_ROOT}/scripts/components/core/constants.sh"
source "${REPO_ROOT}/scripts/components/core/logging.sh"

# Load component under test
source "${REPO_ROOT}/scripts/components/<path>/<component>.sh"

# Test functions
test_my_function() {
  # Test logic here
}

# Run tests
run_tests
```

### 6. Update This README

Add component to:
- Directory structure diagram
- Dependency graph
- Loading order (if needed)

## Testing Components

### Unit Testing

Test individual components in isolation:

```bash
# Source component dependencies
source scripts/components/core/constants.sh
source scripts/components/core/logging.sh

# Source component to test
source scripts/components/ui/help_system.sh

# Test functions
show_help > /tmp/help_output.txt
```

### Integration Testing

Test component interactions:

```bash
# Source all required components
source scripts/components/core/constants.sh
source scripts/components/core/logging.sh
source scripts/components/plugin/plugin_parser.sh
source scripts/components/plugin/plugin_discovery.sh

# Test interactions
plugins=$(discover_plugins)
echo "${plugins}"
```

### Full Script Testing

Test complete functionality:

```bash
./scripts/doc.doc.sh --help
./scripts/doc.doc.sh --version
./scripts/doc.doc.sh -p list
./scripts/doc.doc.sh -v -p list
```

## Benefits of Component Architecture

### Maintainability
- Easier to locate and understand specific functionality
- Smaller files reduce cognitive load
- Clear separation of concerns

### Testability
- Components can be tested independently
- Mock dependencies for isolated testing
- Faster test execution

### Scalability
- Multiple developers can work on different components
- Minimal merge conflicts
- Easier code review

### Reusability
- Components can be shared across tools
- Extract as libraries if needed
- Consistent patterns across codebase

### Extensibility
- Add features by creating new components
- Modify components without touching others
- Plugin architecture naturally supported

## Metrics

- **Entry Script**: 83 lines (target: <150 lines) ✅
- **Average Component Size**: ~50 lines (target: <200 lines) ✅
- **Total Components**: 16 components
- **Original Monolith**: 509 lines
- **Total Modular Code**: ~800 lines (including headers and documentation)

## Design Decisions

### Why pipe-delimited strings instead of JSON?
Plugin data uses pipe-delimited strings (`name|description|active`) for:
- Simplicity and performance (no JSON parsing overhead)
- Ease of manipulation in Bash
- Compatibility with older systems

### Why separate display from discovery?
Separating `plugin_display.sh` from `plugin_discovery.sh`:
- Discovery is data retrieval (domain logic)
- Display is presentation (UI logic)
- Enables different output formats (future)
- Testability (mock discovery in display tests)

### Why component headers?
Standardized headers provide:
- Quick understanding of component purpose
- Dependency tracking
- API documentation (exports)
- Side effect awareness

## Future Enhancements

- Component versioning for compatibility
- Lazy loading for improved startup time
- Component registry for dynamic loading
- Plugin components loaded on demand
- Parallel component testing
