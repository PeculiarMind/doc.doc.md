# Feature: Modular Component Architecture Refactoring

**ID**: 0015  
**Type**: Refactoring  
**Status**: Backlog  
**Created**: 2026-02-09  
**Priority**: Highest

## Overview
Refactor the monolithic `doc.doc.sh` script into a component-based architecture with clearly separated concerns, explicit dependencies, and independent testability.

## Description
Transform the current monolithic script structure (currently 510+ lines in a single file) into a modular component architecture where functionality is organized into discrete, reusable components with well-defined interfaces. Components are organized by domain (core, UI, plugin, orchestration) and loaded dynamically by a lightweight entry script. This architectural refactoring improves maintainability through Single Responsibility Principle, enables independent unit testing of components, reduces cognitive load for developers, allows parallel development without merge conflicts, and facilitates code reuse across tools.

The refactoring maintains backward compatibility for users (same CLI interface) while dramatically improving developer experience and code quality.

## Business Value
- **Maintainability**: Easier to understand, modify, and debug individual components
- **Testability**: Unit test components independently with mocked dependencies
- **Scalability**: Multiple developers can work on different components simultaneously
- **Reusability**: Components can be shared across tools or extracted as libraries
- **Extensibility**: Add new features by creating new components without touching existing code
- **Quality**: Reduced complexity enables better code review and quality assurance
- **Onboarding**: New contributors can understand and contribute to specific components

## Project Stage Considerations
This is an early-stage refactoring where:
- Breaking changes are acceptable (no users yet)
- Performance optimization is deferred (focus on correctness first)
- Architecture quality takes priority over compatibility
- Timeline is flexible based on implementation learnings

## Related Requirements
- [req_0041](../../01_vision/02_requirements/03_accepted/req_0041_modular_component_architecture.md) - Modular Component Architecture (PRIMARY)
- [req_0009](../../01_vision/02_requirements/03_accepted/req_0009_lightweight_implementation.md) - Lightweight Implementation
- [req_0010](../../01_vision/02_requirements/03_accepted/req_0010_unix_tool_composability.md) - Unix Tool Composability

## Acceptance Criteria

### Component Directory Structure
- [ ] Create `scripts/components/` directory structure:
  ```
  scripts/
  ├── doc.doc.sh              # Entry script (< 150 lines)
  └── components/
      ├── README.md           # Component documentation
      ├── core/               # Core utilities
      │   ├── constants.sh
      │   ├── logging.sh
      │   ├── error_handling.sh
      │   └── platform_detection.sh
      ├── ui/                 # User interface
      │   ├── help_system.sh
      │   ├── version_info.sh
      │   └── argument_parser.sh
      ├── plugin/             # Plugin management
      │   ├── plugin_parser.sh
      │   ├── plugin_discovery.sh
      │   ├── plugin_display.sh
      │   └── plugin_executor.sh
      └── orchestration/      # Workflow orchestration
          ├── scanner.sh
          ├── workspace.sh
          ├── template_engine.sh
          └── report_generator.sh
  ```

### Core Components
- [ ] **constants.sh**: Global constants, configuration defaults, version info
  - Exports: VERSION, DEFAULT_*, EXIT_CODE_*
  - Dependencies: None
  - No side effects, pure data
  
- [ ] **logging.sh**: Logging infrastructure with levels and formatting
  - Exports: `log()`, `set_log_level()`, `is_verbose()`
  - Dependencies: constants.sh
  - Side effects: Writes to stderr
  
- [ ] **error_handling.sh**: Error handling, exit code management, cleanup
  - Exports: `handle_error()`, `cleanup()`, `set_exit_trap()`
  - Dependencies: logging.sh
  - Side effects: Sets traps, modifies exit behavior
  
- [ ] **platform_detection.sh**: Platform detection (ubuntu, debian, darwin, etc.)
  - Exports: `detect_platform()`, `PLATFORM` variable
  - Dependencies: logging.sh
  - Side effects: Sets global PLATFORM variable

### UI Components
- [ ] **help_system.sh**: All help text and display functions
  - Exports: `show_help()`, `show_help_plugins()`, `show_help_template()`, `show_help_examples()`
  - Dependencies: core/constants.sh, core/logging.sh
  - No side effects, pure display
  
- [ ] **version_info.sh**: Version display
  - Exports: `show_version()`
  - Dependencies: core/constants.sh
  - No side effects, pure display
  
- [ ] **argument_parser.sh**: CLI argument parsing and validation
  - Exports: `parse_arguments()`, `validate_arguments()`
  - Dependencies: core/logging.sh, core/error_handling.sh
  - Side effects: Sets global config variables

### Plugin Components
- [ ] **plugin_parser.sh**: Plugin descriptor JSON parsing
  - Exports: `parse_plugin_descriptor()`, `extract_plugin_field()`
  - Dependencies: core/logging.sh
  - No side effects, pure parsing
  
- [ ] **plugin_discovery.sh**: Plugin discovery and validation
  - Exports: `discover_plugins()`, `validate_plugin()`, `filter_active_plugins()`
  - Dependencies: core/platform_detection.sh, plugin/plugin_parser.sh
  - Side effects: Reads filesystem
  
- [ ] **plugin_display.sh**: Plugin listing and formatting
  - Exports: `list_plugins()`, `format_plugin_info()`
  - Dependencies: plugin/plugin_discovery.sh, plugin/plugin_parser.sh
  - No side effects, pure formatting
  
- [ ] **plugin_executor.sh**: Plugin execution orchestration
  - Exports: `execute_plugin()`, `build_dependency_graph()`, `orchestrate_plugins()`
  - Dependencies: plugin/plugin_discovery.sh, orchestration/workspace.sh
  - Side effects: Executes external commands, modifies workspace

### Orchestration Components
- [ ] **scanner.sh**: Directory scanning and file discovery
  - Exports: `scan_directory()`, `detect_file_type()`, `filter_files()`
  - Dependencies: core/logging.sh, orchestration/workspace.sh
  - Side effects: Reads filesystem
  
- [ ] **workspace.sh**: Workspace management (JSON read/write)
  - Exports: `init_workspace()`, `load_workspace()`, `save_workspace()`, `acquire_lock()`, `release_lock()`
  - Dependencies: core/logging.sh, core/error_handling.sh
  - Side effects: Reads/writes filesystem
  
- [ ] **template_engine.sh**: Template processing
  - Exports: `process_template()`, `substitute_variables()`, `process_conditionals()`, `process_loops()`
  - Dependencies: core/logging.sh
  - No side effects (pure processing), output via stdout
  
- [ ] **report_generator.sh**: Report generation
  - Exports: `generate_reports()`, `generate_aggregated_report()`
  - Dependencies: orchestration/workspace.sh, orchestration/template_engine.sh
  - Side effects: Writes report files

### Entry Script Refactoring
- [ ] Entry script (`doc.doc.sh`) reduced to < 150 lines
- [ ] Entry script contains only:
  - Shebang and header comment
  - Component loading function: `source_component()`
  - Component loading sequence (in dependency order)
  - Main workflow orchestration function: `main()`
  - Argument parsing delegation
  - Error trap setup
  - Main execution call
- [ ] Entry script loads components with error handling:
  ```bash
  source_component() {
    local component="$1"
    if [[ -f "$COMPONENTS_DIR/$component" ]]; then
      source "$COMPONENTS_DIR/$component" || {
        echo "ERROR: Failed to load component: $component" >&2
        exit 1
      }
    else
      echo "ERROR: Component not found: $component" >&2
      exit 1
    fi
  }
  ```

### Component Interface Standards
- [ ] Each component includes header comment documenting:
  - Purpose and responsibility
  - Exported functions
  - Required dependencies
  - Global state modifications
  - Side effects
  - Example usage
- [ ] Component header format:
  ```bash
  #!/usr/bin/env bash
  # Component: <name>
  # Purpose: <one-line description>
  # Dependencies: <component1>, <component2>
  # Exports: <function1>, <function2>
  # Side Effects: <description or "None">
  # shellcheck disable=SC2034  # (if needed)
  ```
- [ ] Functions follow naming convention: `verb_noun()` (e.g., `parse_arguments`, `load_workspace`)
- [ ] Functions use `local` for all local variables
- [ ] Functions return via `return` (exit codes) or `echo` (data output)
- [ ] No cross-dependencies between same-level components (only depend on core)

### Testing Infrastructure
- [ ] Each component has corresponding test file: `tests/unit/test_<component>.sh`
- [ ] Components can be sourced independently for testing
- [ ] Mock functions available for dependency injection in tests
- [ ] Test coverage target: > 80% for each component
- [ ] Integration tests verify component interactions

### Documentation
- [ ] Component `README.md` documents:
  - Component architecture overview
  - Component dependency graph diagram
  - Loading order and rationale
  - How to add new components
  - Component design guidelines
- [ ] Each component has inline documentation for all functions
- [ ] Architecture documentation updated with component design

## Technical Considerations

### Refactoring Strategy

**Phase 1: Extract Core Components**
1. Extract constants to `core/constants.sh`
2. Extract logging to `core/logging.sh`
3. Extract error handling to `core/error_handling.sh`
4. Extract platform detection to `core/platform_detection.sh`
5. Update entry script to load core components
6. Test: Core functionality works

**Phase 2: Extract UI Components**
1. Extract help system to `ui/help_system.sh`
2. Extract version info to `ui/version_info.sh`
3. Extract argument parsing to `ui/argument_parser.sh`
4. Update entry script to load UI components
5. Test: Help, version, argument parsing work

**Phase 3: Extract Plugin Components**
1. Extract plugin parsing to `plugin/plugin_parser.sh`
2. Extract plugin discovery to `plugin/plugin_discovery.sh`
3. Extract plugin display to `plugin/plugin_display.sh`
4. Extract plugin execution to `plugin/plugin_executor.sh`
5. Update entry script to load plugin components
6. Test: Plugin listing and discovery work

**Phase 4: Extract Orchestration Components**
1. Extract scanner to `orchestration/scanner.sh`
2. Extract workspace to `orchestration/workspace.sh`
3. Extract template engine to `orchestration/template_engine.sh`
4. Extract report generator to `orchestration/report_generator.sh`
5. Update entry script to load orchestration components
6. Test: Full workflow executes correctly

**Phase 5: Finalize**
1. Refactor entry script to pure orchestration (< 150 lines)
2. Add component documentation
3. Create component dependency diagram
4. Validate loading order
5. Final testing and documentation

### Component Loading Order
```bash
# Core (no dependencies)
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

# Orchestration (depends on core, plugin)
source_component "orchestration/workspace.sh"
source_component "orchestration/scanner.sh"
source_component "orchestration/template_engine.sh"
source_component "orchestration/report_generator.sh"
source_component "plugin/plugin_executor.sh"  # Last, depends on orchestration
```

### Component Dependency Graph
```
constants.sh
    ├── logging.sh
    │   ├── error_handling.sh
    │   ├── platform_detection.sh
    │   ├── help_system.sh
    │   ├── version_info.sh
    │   ├── argument_parser.sh
    │   ├── plugin_parser.sh
    │   ├── scanner.sh
    │   └── template_engine.sh
    ├── help_system.sh
    └── version_info.sh

platform_detection.sh
    └── plugin_discovery.sh

plugin_parser.sh
    ├── plugin_discovery.sh
    └── plugin_display.sh

plugin_discovery.sh
    ├── plugin_display.sh
    └── plugin_executor.sh

workspace.sh
    ├── scanner.sh
    ├── plugin_executor.sh
    └── report_generator.sh

template_engine.sh
    └── report_generator.sh
```

### Implementation Approach
- **Incremental**: Extract components one at a time, test after each
- **Git history**: Use `git mv` where appropriate to preserve history
- **Atomic commits**: Each phase is a separate commit
- **Clean breaks**: No need for compatibility layers or feature flags in early stage

### Testing Strategy
```bash
# Test individual component
source tests/helpers/test_helpers.sh
source scripts/components/core/logging.sh
test_log_function

# Test component integration
source scripts/components/core/constants.sh
source scripts/components/core/logging.sh
test_logging_uses_constants

# Test full script
./doc.doc.sh --help
./doc.doc.sh -p list
./tests/run_all_tests.sh
```

## Dependencies
- Requires: Basic script structure (feature_0001) ✅
- Blocks: None (improves development of all future features)
- Enables: Easier implementation of features 0006-0014

## Risk Assessment

### Risks
- **Scope creep**: Temptation to refactor beyond modularization
  - **Mitigation**: Strict scope definition, only structural changes
  
- **Implementation complexity**: Getting component boundaries right requires iteration
  - **Mitigation**: Start with obvious separations, refine based on learnings
  
- **Merge conflicts**: Changes affect entire codebase
  - **Mitigation**: Complete refactoring in dedicated branch, coordinate with team

### Benefits
- **Improved development velocity**: Easier to understand, modify, and test individual components
- **Better code quality**: Single Responsibility Principle, clear interfaces, independent testing
- **Easier collaboration**: Multiple developers can work on different components
- **Foundation for scale**: Proper architecture before significant feature growth

## Testing Strategy
- Pre-refactoring: Run existing tests to establish baseline
- Per-phase: Test each component as it's extracted
- Post-refactoring: Full test suite passes, component tests written
- Component tests: Unit test each component independently
- Integration tests: Test component interactions
- Focus: Correctness and testability, performance optimization deferred

## Definition of Done
- [ ] All acceptance criteria met
- [ ] All components extracted and documented
- [ ] Entry script < 150 lines
- [ ] Tests validate component functionality
- [ ] Component tests written (target >80% coverage)
- [ ] Code reviewed and approved
- [ ] Documentation updated (architecture, component README)
- [ ] Component dependency diagram created

## Success Metrics
- **Lines per file**: Average < 200 lines per component (was 510+ in monolith)
- **Cyclomatic complexity**: < 10 per function (measurable improvement)
- **Test coverage**: Target > 80% per component
- **Component isolation**: Each component can be sourced and tested independently
- **Documentation quality**: Clear interfaces and dependencies for each component
