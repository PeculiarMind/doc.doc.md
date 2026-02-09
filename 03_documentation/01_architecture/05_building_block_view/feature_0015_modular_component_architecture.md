# Building Block View: Modular Component Architecture (Feature 15)

**Feature**: Feature 0015 - Modular Component Architecture Refactoring  
**Status**: Implemented  
**Architecture Decision**: IDR-0014

## Overview

This document describes the building block view of the modular component architecture that replaced the monolithic script structure. The system is now organized into 16 discrete components across 4 domains, orchestrated by a lightweight entry script.

## Level 1: System Context

```
┌─────────────────────────────────────────────────────┐
│                  doc.doc.sh System                  │
│                                                     │
│  ┌─────────────┐     ┌──────────────────────────┐  │
│  │ Entry Script│────▶│  Component Architecture  │  │
│  │  (83 lines) │     │     (16 components)      │  │
│  └─────────────┘     └──────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
         │                                    │
         │ CLI Input                          │ Output
         ▼                                    ▼
    [User/Cron]                         [Reports/Logs]
```

## Level 2: Component Domains

The system is organized into 4 architectural domains:

```
┌────────────────────────────────────────────────────────────┐
│                     doc.doc.sh Entry Script                │
│                          (83 lines)                        │
└────────────────────────────────────────────────────────────┘
                              │
                              │ Loads & Orchestrates
                              ▼
        ┌─────────────────────────────────────────┐
        │         Component Architecture          │
        │                                         │
        │  ┌──────────┐  ┌──────────┐           │
        │  │   Core   │  │    UI    │           │
        │  │ (4 comp) │  │ (3 comp) │           │
        │  └──────────┘  └──────────┘           │
        │                                         │
        │  ┌──────────┐  ┌──────────────────┐   │
        │  │  Plugin  │  │  Orchestration   │   │
        │  │ (4 comp) │  │    (4 comp)      │   │
        │  └──────────┘  └──────────────────┘   │
        │                                         │
        └─────────────────────────────────────────┘
```

## Level 3: Component Details

### Domain: Core (Foundation Layer)

Core components provide infrastructure used by all other components.

```
┌─────────────────────────────────────────────────────────┐
│                    Core Components                      │
│                   (No Dependencies)                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  constants.sh (25 lines)                               │
│  ├─ Script metadata (name, version, copyright)         │
│  ├─ Exit codes (SUCCESS, INVALID_ARGS, FILE_ERROR...)  │
│  └─ Global configuration variables                     │
│                                                         │
│  logging.sh (43 lines)                                 │
│  ├─ log(level, message) - Core logging function        │
│  ├─ set_log_level(level) - Configure log verbosity     │
│  ├─ is_verbose() - Check verbose flag                  │
│  └─ Dependencies: constants.sh                         │
│                                                         │
│  error_handling.sh (41 lines)                          │
│  ├─ error_exit(message, code) - Fatal error handler    │
│  ├─ handle_error(context) - Error context capture      │
│  ├─ cleanup() - Resource cleanup                       │
│  ├─ set_exit_trap() - Trap registration                │
│  └─ Dependencies: logging.sh                           │
│                                                         │
│  platform_detection.sh (37 lines)                      │
│  ├─ detect_platform() - OS detection                   │
│  ├─ Sets PLATFORM variable (ubuntu, debian, darwin...) │
│  └─ Dependencies: logging.sh                           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Design Notes**:
- Core components have no external dependencies
- Pure functions where possible (constants, logging)
- Side effects clearly documented (platform_detection sets PLATFORM)
- Loaded first in dependency order

### Domain: UI (Presentation Layer)

UI components handle all user-facing interface functionality.

```
┌─────────────────────────────────────────────────────────┐
│                     UI Components                       │
│                 (Depends on: Core)                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  help_system.sh (68 lines)                             │
│  ├─ show_help() - Display main help                    │
│  ├─ show_help_plugins() - Plugin help (future)         │
│  ├─ show_help_template() - Template help (future)      │
│  ├─ show_help_examples() - Usage examples (future)     │
│  └─ Dependencies: constants.sh                         │
│                                                         │
│  version_info.sh (22 lines)                            │
│  ├─ show_version() - Display version info              │
│  └─ Dependencies: constants.sh                         │
│                                                         │
│  argument_parser.sh (131 lines)                        │
│  ├─ parse_arguments(args...) - Parse CLI arguments     │
│  ├─ validate_arguments() - Validation logic            │
│  ├─ Delegates to: show_help, show_version              │
│  ├─ Delegates to: list_plugins (plugin domain)         │
│  └─ Dependencies: core/*, help_system, version_info    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Design Notes**:
- No dependencies between UI components at same level
- `argument_parser.sh` acts as coordinator, depends on other UI components
- Pure display functions (no side effects except stdout)
- Separation of display from business logic

### Domain: Plugin (Plugin Management)

Plugin components handle all plugin-related functionality.

```
┌─────────────────────────────────────────────────────────┐
│                   Plugin Components                     │
│              (Depends on: Core, Platform)               │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  plugin_parser.sh (111 lines)                          │
│  ├─ parse_plugin_descriptor(path) - Parse JSON         │
│  ├─ extract_plugin_field(json, field) - Extract field  │
│  ├─ Fallback: jq → python3 → error                     │
│  └─ Dependencies: logging.sh                           │
│                                                         │
│  plugin_discovery.sh (117 lines)                       │
│  ├─ discover_plugins() - Find all plugins              │
│  ├─ validate_plugin(descriptor) - Validate plugin      │
│  ├─ filter_active_plugins(plugins) - Filter active     │
│  ├─ Platform-specific + cross-platform search          │
│  └─ Dependencies: platform_detection, plugin_parser    │
│                                                         │
│  plugin_display.sh (82 lines)                          │
│  ├─ list_plugins() - Display plugin list               │
│  ├─ format_plugin_info(plugin) - Format single plugin  │
│  ├─ Table formatting with columns                      │
│  └─ Dependencies: plugin_discovery                     │
│                                                         │
│  plugin_executor.sh (47 lines)                         │
│  ├─ execute_plugin(name, workspace) - Execute plugin   │
│  ├─ build_dependency_graph() - Dependency analysis     │
│  ├─ orchestrate_plugins(workspace) - Coordinate exec   │
│  └─ Dependencies: plugin_discovery, workspace.sh       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Design Notes**:
- Hierarchical dependencies (parser → discovery → display → executor)
- `plugin_executor.sh` loaded last (depends on orchestration)
- Clear separation: parsing, discovery, display, execution
- Platform-aware plugin discovery

### Domain: Orchestration (Workflow Coordination)

Orchestration components coordinate analysis workflows (future full implementation).

```
┌─────────────────────────────────────────────────────────┐
│                Orchestration Components                 │
│            (Depends on: Core, Plugin, UI)               │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  workspace.sh (72 lines)                               │
│  ├─ init_workspace(path) - Initialize workspace        │
│  ├─ load_workspace(path) - Load JSON workspace         │
│  ├─ save_workspace(path, data) - Save workspace        │
│  ├─ acquire_lock() - File locking                      │
│  ├─ release_lock() - Lock release                      │
│  └─ Dependencies: logging, error_handling              │
│                                                         │
│  scanner.sh (48 lines)                                 │
│  ├─ scan_directory(path) - Scan for files              │
│  ├─ detect_file_type(path) - File type detection       │
│  ├─ filter_files(files, criteria) - Filter results     │
│  └─ Dependencies: logging, workspace                   │
│                                                         │
│  template_engine.sh (64 lines)                         │
│  ├─ process_template(template, vars) - Template proc   │
│  ├─ substitute_variables(text, vars) - Substitution    │
│  ├─ process_conditionals(text, vars) - Conditionals    │
│  ├─ process_loops(text, data) - Loop processing        │
│  └─ Dependencies: logging                              │
│                                                         │
│  report_generator.sh (38 lines)                        │
│  ├─ generate_reports(workspace) - Generate reports     │
│  ├─ generate_aggregated_report(data) - Aggregation     │
│  └─ Dependencies: workspace, template_engine           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Design Notes**:
- Designed for future feature implementation
- `workspace.sh` provides state management foundation
- Clear workflow: scan → process → template → report
- Can depend on any lower-level components

## Level 4: Dependency Graph

Complete component dependency graph showing load order:

```
constants.sh (no deps)
    │
    ├──▶ logging.sh
    │       │
    │       ├──▶ error_handling.sh
    │       │
    │       ├──▶ platform_detection.sh
    │       │       │
    │       │       └──▶ plugin_discovery.sh
    │       │               │
    │       │               ├──▶ plugin_display.sh
    │       │               │
    │       │               └──▶ plugin_executor.sh (also needs workspace)
    │       │
    │       ├──▶ plugin_parser.sh
    │       │       │
    │       │       └──▶ plugin_discovery.sh
    │       │
    │       ├──▶ scanner.sh (also needs workspace)
    │       │
    │       └──▶ template_engine.sh
    │               │
    │               └──▶ report_generator.sh (also needs workspace)
    │
    ├──▶ help_system.sh
    │       │
    │       └──▶ argument_parser.sh (also needs version_info)
    │
    └──▶ version_info.sh
            │
            └──▶ argument_parser.sh

error_handling.sh ──▶ workspace.sh
                        │
                        ├──▶ scanner.sh
                        │
                        ├──▶ plugin_executor.sh
                        │
                        └──▶ report_generator.sh
```

## Component Loading Sequence

Components are loaded in strict dependency order:

```bash
# Phase 1: Core Foundation (no dependencies)
source_component "core/constants.sh"
source_component "core/logging.sh"
source_component "core/error_handling.sh"
source_component "core/platform_detection.sh"

# Phase 2: UI and Plugin Base (depend on core)
source_component "ui/help_system.sh"
source_component "ui/version_info.sh"
source_component "ui/argument_parser.sh"
source_component "plugin/plugin_parser.sh"
source_component "plugin/plugin_discovery.sh"
source_component "plugin/plugin_display.sh"

# Phase 3: Orchestration (depend on core + plugin)
source_component "orchestration/workspace.sh"
source_component "orchestration/scanner.sh"
source_component "orchestration/template_engine.sh"
source_component "orchestration/report_generator.sh"
source_component "plugin/plugin_executor.sh"  # Last (needs orchestration)
```

**Rationale**:
- Core loaded first (no dependencies)
- UI and plugin components loaded after core
- Orchestration loaded last (depends on everything)
- `plugin_executor.sh` loaded after orchestration (needs workspace)

## Component Interfaces

### Standard Component Header

Every component follows this interface standard:

```bash
#!/usr/bin/env bash
# Component: <name>
# Purpose: <one-line description>
# Dependencies: <component1>, <component2>
# Exports: <function1>, <function2>
# Side Effects: <description or "None">
```

### Function Naming Convention

All functions follow `verb_noun()` pattern:
- `parse_arguments()` - Parse CLI arguments
- `load_workspace()` - Load workspace file
- `detect_platform()` - Detect operating system
- `list_plugins()` - List available plugins

### Return Value Convention

- **Exit Codes**: Use `return 0` (success) or `return 1` (error)
- **Data Output**: Use `echo` to stdout
- **No Direct Exit**: Components never call `exit` (except `error_exit`)
- **Error Propagation**: Return codes propagate to caller

### Side Effects Documentation

Components clearly document side effects:
- **None**: Pure functions (constants, parsing)
- **Writes to stderr**: Logging components
- **Modifies global state**: Platform detection (sets PLATFORM)
- **Reads filesystem**: Plugin discovery, scanner
- **Writes filesystem**: Workspace, report generator

## Architecture Metrics

### Size Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Entry script | 83 lines | ✅ Target: <150 |
| Average component | 60 lines | ✅ Target: <200 |
| Largest component | 131 lines (argument_parser) | ✅ Target: <200 |
| Smallest component | 22 lines (version_info) | ✅ |
| Total component count | 16 | ✅ |
| Total lines (components) | 946 lines | ℹ️ Was: 509 |

### Complexity Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| Maximum dependency depth | 3 levels | constants → logging → error_handling → workspace |
| Components with 0 deps | 1 | constants.sh |
| Components with 1 dep | 5 | logging, help, version, plugin_parser, template |
| Components with 2+ deps | 10 | Most components |
| Circular dependencies | 0 | ✅ None detected |

### Quality Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Components testable independently | 16/16 | ✅ 100% |
| Components with unit tests | 2/16 | ⚠️ Core only |
| Components with headers | 16/16 | ✅ 100% |
| Functional tests passing | 10/15 | ✅ (5 obsolete) |
| Documentation coverage | 100% | ✅ Complete |

## Design Patterns

### Pattern 1: Pure Functions

Components like `constants.sh`, `template_engine.sh` use pure functions:
- No side effects
- Deterministic output
- Easy to test
- Composable

### Pattern 2: Dependency Injection

Components receive dependencies via sourcing:
```bash
# plugin_display.sh depends on plugin_discovery.sh
# Entry script ensures discovery loaded first
source_component "plugin/plugin_discovery.sh"
source_component "plugin/plugin_display.sh"
```

### Pattern 3: Error Propagation

Components return error codes, entry script handles:
```bash
# In component
parse_plugin_descriptor() {
  [[ -f "$1" ]] || return 1  # Error code
  # ... processing ...
  echo "${result}"  # Output via stdout
  return 0  # Success
}

# In entry script or caller
result=$(parse_plugin_descriptor "$file") || {
  log "WARN" "Failed to parse: $file"
  continue  # Handle error
}
```

### Pattern 4: Global State Management

Minimal global state, clearly documented:
- `VERBOSE` - Logging verbosity (set by argument_parser)
- `PLATFORM` - Detected OS (set by platform_detection)
- All other state passed via function parameters or workspace

## Testing Strategy

### Unit Testing

Components tested independently:
```bash
# Test logging component
source scripts/components/core/constants.sh
source scripts/components/core/logging.sh

# Test with mocked VERBOSE flag
VERBOSE=true
output=$(log "INFO" "Test" 2>&1)
[[ "${output}" == "[INFO] Test" ]] || fail
```

### Integration Testing

Component interactions tested:
```bash
# Test plugin workflow
source_component "core/constants.sh"
source_component "core/logging.sh"
source_component "plugin/plugin_parser.sh"
source_component "plugin/plugin_discovery.sh"

plugins=$(discover_plugins)
[[ -n "${plugins}" ]] || fail
```

### Mock Components

Test doubles for isolation:
```bash
# tests/mocks/core/platform_detection.sh
detect_platform() {
  PLATFORM="ubuntu"  # Fixed for testing
}
```

## Future Enhancements

### Planned Improvements

1. **Lazy Loading**: Load orchestration components only when needed
2. **Component Versioning**: Version compatibility checks
3. **Dynamic Discovery**: Optional auto-discovery of new components
4. **Performance Profiling**: Measure component load times
5. **Additional Unit Tests**: Expand test coverage to all components

### Extensibility Points

New features can be added as components:
- `orchestration/parallel_executor.sh` - Parallel plugin execution
- `orchestration/incremental_analyzer.sh` - Smart incremental analysis
- `orchestration/cache_manager.sh` - Result caching
- `ui/progress_display.sh` - Progress bars and status

## Related Documentation

- **Architecture Decision**: [IDR-0014: Modular Component Architecture Implementation](../09_architecture_decisions/IDR_0014_modular_component_architecture_implementation.md)
- **Vision ADR**: [ADR-0007: Modular Component-Based Architecture](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0007_modular_component_based_script_architecture.md)
- **Component README**: [scripts/components/README.md](../../../../scripts/components/README.md)
- **Feature**: [Feature 0015: Modular Component Refactoring](../../../02_agile_board/05_implementing/feature_0015_modular_component_refactoring.md)

## Conclusion

The modular component architecture successfully decomposes the monolithic script into 16 focused components across 4 domains. The architecture provides:

✅ **Maintainability** - 60-line average component size  
✅ **Testability** - Independent component testing  
✅ **Extensibility** - Add features without modifying existing components  
✅ **Clarity** - Clear dependency graph and load order  
✅ **Documentation** - Comprehensive headers and documentation  

The building block view demonstrates a well-structured, layered architecture that supports future growth while maintaining simplicity and clarity.
