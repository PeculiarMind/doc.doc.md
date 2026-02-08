# ADR-0007: Modular Component-Based Script Architecture

**ID**: ADR-0007  
**Status**: Accepted  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08

## Context

Current monolithic script (510 lines) becoming difficult to maintain, test, and extend as features grow. Need architecture that supports parallel development, isolated testing, code reuse, and future extensibility.

## Decision

Transition from monolithic `doc.doc.sh` script to modular component-based architecture with functionality separated into discrete, reusable components organized in `scripts/components/` directory, orchestrated by a lightweight entry script.

## Rationale

**Strengths**:
- **Maintainability**: Single Responsibility Principle - each component owns one logical area, reducing cognitive load and simplifying debugging
- **Testability**: Components testable in isolation, enabling unit tests, mocking, and faster test cycles
- **Reusability**: Components become building blocks usable across multiple tools and contexts
- **Separation of Concerns**: Clear boundaries between logging, error handling, plugin management, UI, etc.
- **Extensibility**: Add features without modifying existing components, reducing regression risk
- **Collaboration**: Multiple developers work on different components without merge conflicts
- **Code Navigation**: Find specific logic quickly in focused files vs. scrolling through 500+ line monolith

**Weaknesses**:
- **Initial Overhead**: Requires upfront refactoring effort (~40-60 hours)
- **Loading Complexity**: Must explicitly source components in dependency order
- **Indirection**: Following logic requires navigating multiple files
- **Disk I/O**: Multiple file reads at script startup (minimal impact ~10ms)

## Alternatives Considered

### Keep Monolithic Structure
- ✅ No refactoring needed, works today
- ✅ All logic in one place
- ❌ Maintenance difficulty grows with each feature
- ❌ Testing requires full script execution
- ❌ Cannot reuse components elsewhere
- ❌ Merge conflicts increase with team size
- **Decision**: Technical debt accumulates, becomes harder to change later

### Multiple Standalone Scripts (No Shared Components)
- ✅ Simple, independent executables
- ❌ Code duplication (logging, error handling repeated)
- ❌ Inconsistent behavior across scripts
- ❌ Changes require updating multiple files
- **Decision**: Violates DRY principle, maintenance nightmare

### External Library (Separate Repository)
- ✅ Stronger encapsulation, versioning
- ❌ Complex dependency management
- ❌ Overkill for single-project use
- ❌ Deployment complexity
- **Decision**: Premature abstraction, YAGNI

### Dynamic Plugin-Style Component Loading
```bash
for component in components/**/*.sh; do
  source "${component}"
done
```
- ✅ Auto-discovery, less boilerplate
- ❌ Unpredictable load order (dependency conflicts)
- ❌ ShellCheck cannot analyze
- ❌ Slower (unnecessary globbing)
- ❌ Harder to debug
- **Decision**: Explicit beats implicit, clarity over cleverness

## Consequences

### Positive
- ✅ **Unit Testing**: Test logging without loading plugin system
- ✅ **Mock Components**: Replace platform detection with test double
- ✅ **Parallel Development**: Team works on different components simultaneously
- ✅ **Code Reuse**: Use logging in other scripts: `source components/core/logging.sh`
- ✅ **Easier Debugging**: Isolate issue to specific component (~50 lines vs. 500)
- ✅ **ShellCheck Integration**: Analyze components independently
- ✅ **Documentation**: Component contracts serve as API documentation
- ✅ **Future-Proof**: New features (file scanning, report generation) follow same pattern

### Negative
- ❌ **Migration Effort**: ~40-60 hours to extract and test components
- ❌ **Learning Curve**: New developers must understand component structure
- ❌ **More Files**: Navigate 10+ files vs. 1 (IDE mitigates this)
- ❌ **Startup Overhead**: ~10ms additional load time (negligible)
- ❌ **Maintenance**: Keep entry script load order correct (documented in component READMEs)

### Risks
- Incorrect dependency ordering causes load failures
- Components may develop hidden dependencies
- Over-modularization could fragment logic

## Implementation Notes

### Component Structure Design

**Directory Organization**:
```
scripts/components/
├── core/              # Infrastructure (logging, errors, platform, constants)
├── ui/                # User interface (help, version, argument parsing)
├── plugin/            # Plugin system (discovery, parsing, display)
└── orchestration/     # Future: analysis workflow components
```

**Component Interface Contract**:
Each component declares:
- **Provides**: Functions/variables exported
- **Dependencies**: Required components (load before this)
- **Parameters**: Function signatures
- **Exit Codes**: Return codes and meanings
- **Side Effects**: I/O, global state modifications
- **External Tools**: Required commands (jq, python3, etc.)

**Component Loading Pattern**:
```bash
# Entry script (doc.doc.sh)
source_component() {
  local component_path="$1"
  local full_path="${SCRIPT_DIR}/components/${component_path}"
  
  [[ -f "${full_path}" ]] || { echo "ERROR: Component not found" >&2; exit 2; }
  source "${full_path}"
}

# Load in dependency order
source_component "core/constants.sh"        # No deps
source_component "core/logging.sh"          # Depends: constants
source_component "core/error_handling.sh"   # Depends: logging, constants
source_component "core/platform_detection.sh" # Depends: logging, constants
source_component "ui/help_system.sh"        # Depends: constants
source_component "ui/version_info.sh"       # Depends: constants
source_component "plugin/plugin_parser.sh"  # Depends: core/*
source_component "plugin/plugin_discovery.sh" # Depends: core/*, plugin_parser
source_component "plugin/plugin_display.sh" # Depends: plugin_discovery
source_component "ui/argument_parser.sh"    # Depends: ui/*, plugin/*
```

**Component Breakdown**:

| Component | LOC | Responsibility | Dependencies |
|-----------|-----|----------------|-------------|
| `core/constants.sh` | ~40 | Script metadata, exit codes, globals | None |
| `core/logging.sh` | ~30 | Logging with levels | constants |
| `core/error_handling.sh` | ~20 | Error exit with context | logging, constants |
| `core/platform_detection.sh` | ~25 | OS detection | logging, constants |
| `ui/help_system.sh` | ~50 | Help display | constants |
| `ui/version_info.sh` | ~15 | Version info | constants |
| `ui/argument_parser.sh` | ~120 | CLI parsing | all ui/*, plugin/* |
| `plugin/plugin_parser.sh` | ~80 | JSON descriptor parsing | core/* |
| `plugin/plugin_discovery.sh` | ~120 | Filesystem plugin search | core/*, plugin_parser |
| `plugin/plugin_display.sh` | ~50 | Format plugin lists | plugin_discovery |
| **Entry Script** | ~100 | Orchestration only | all components |
| **Total** | ~650 | (includes component docs) | |

### Migration Strategy

**Phase 1: Core Components** (Low Risk)
1. Extract `core/constants.sh`, `core/logging.sh`, `core/error_handling.sh`, `core/platform_detection.sh`
2. Update entry script to source components
3. Validate all existing tests pass

**Phase 2: UI Components** (Low Risk)
1. Extract `ui/help_system.sh`, `ui/version_info.sh`
2. Update entry script
3. Test help and version commands

**Phase 3: Plugin Components** (Medium Risk)
1. Extract `plugin/plugin_parser.sh`, `plugin/plugin_discovery.sh`, `plugin/plugin_display.sh`
2. Extract `ui/argument_parser.sh`
3. Comprehensive plugin system testing

**Phase 4: Polish** (Low Risk)
1. Component documentation
2. Integration tests
3. Performance validation

**Rollback**: Each phase is separate commit, revert if issues arise

### Testing Strategy

**Unit Tests**:
```bash
# tests/unit/test_logging.sh
source components/core/constants.sh
source components/core/logging.sh

test_logging_verbose() {
  VERBOSE=true
  output=$(log "INFO" "test" 2>&1)
  [[ "${output}" == "[INFO] test" ]] || return 1
}
```

**Integration Tests**:
```bash
# tests/integration/test_plugin_workflow.sh
# Load full component chain
for component in core/* ui/* plugin/*; do
  source_component "${component}"
done

test_plugin_list_workflow() {
  output=$(list_plugins)
  echo "${output}" | grep -q "Available Plugins" || return 1
}
```

**Mock Components**:
```bash
# tests/mocks/core/platform_detection.sh
detect_platform() {
  PLATFORM="ubuntu"  # Fixed for testing
}
```

### Success Criteria

**Modularization succeeds when**:
- ✅ All existing tests pass after each migration phase
- ✅ Component can be tested independently with <50 LOC test
- ✅ New feature implementation requires modifying only 1-2 components
- ✅ Entry script remains <150 lines
- ✅ Component contracts documented and enforced
- ✅ No performance regression (startup time <100ms)

## Related Items

- [ADR-0001](ADR_0001_bash_as_primary_implementation_language.md) - Components remain in Bash, maintains zero-dependency goal
- [ADR-0003](ADR_0003_data_driven_plugin_orchestration.md) - Plugin components demonstrate separation of concerns
- Feature-0001: Basic Script Structure (implemented with initial monolith)
- Feature Future: Analysis engine, report generator will follow component pattern

**Trade-offs Accepted**:
- **Upfront Effort over Ongoing Pain**: Accept migration cost for long-term maintainability
- **Explicit Loading over Dynamic Discovery**: Clarity and predictability over cleverness
- **Multiple Files over Single File**: Modularity over convenience
- **Structure over Simplicity**: Accept complexity for scalability
