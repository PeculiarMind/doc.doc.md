# Building Block View: Plugin Execution Engine (Features 0009, 0011, 0012, 0020)

**Features**: Feature 0009 (Plugin Execution Engine), Feature 0011 (Tool Verification), Feature 0012 (Plugin Security Validation), Feature 0020 (Stat Plugin)  
**Status**: Implemented  
**Architecture Decision**: IDR-0016

## Overview

This document describes the building block view of the plugin execution subsystem added to the plugin domain. Three new components extend the existing plugin architecture, and one reference plugin (stat) demonstrates the complete pipeline.

## Level 1: Plugin Execution Context

```
┌───────────────────────────────────────────────────────┐
│                  doc.doc.sh System                    │
│                                                       │
│  ┌──────────────┐     ┌────────────────────────────┐ │
│  │  Existing     │     │   New Plugin Execution     │ │
│  │  Components   │────▶│   Subsystem (3 components) │ │
│  │  (16 total)   │     └────────────────────────────┘ │
│  └──────────────┘                  │                  │
│                                    ▼                  │
│                          ┌─────────────────┐          │
│                          │  Plugin Store   │          │
│                          │  (stat plugin)  │          │
│                          └─────────────────┘          │
└───────────────────────────────────────────────────────┘
```

## Level 2: New Components in Plugin Domain

```
┌─────────────────────────────────────────────────────────────┐
│                   Plugin Domain (Extended)                   │
│                                                             │
│  Existing Components          New Components                │
│  ┌────────────────────┐       ┌──────────────────────────┐ │
│  │ plugin_parser.sh   │       │ plugin_validator.sh      │ │
│  │ plugin_discovery.sh│──────▶│ (Feature 0012, 491 lines)│ │
│  │ plugin_display.sh  │       └──────────────────────────┘ │
│  └────────────────────┘       ┌──────────────────────────┐ │
│                               │ plugin_tool_checker.sh   │ │
│                          ────▶│ (Feature 0011, 223 lines)│ │
│                               └──────────────────────────┘ │
│                               ┌──────────────────────────┐ │
│                          ────▶│ plugin_executor.sh       │ │
│                               │ (Feature 0009, 615 lines)│ │
│                               └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Level 3: Component Details

### Component: plugin_validator.sh (Feature 0012)

Plugin descriptor validation and security gate.

```
┌─────────────────────────────────────────────────────────┐
│              plugin_validator.sh (491 lines)             │
│         Dependencies: logging.sh, plugin_parser.sh      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  validate_plugin_descriptor(descriptor_file)            │
│  ├─ JSON syntax validation                             │
│  ├─ Required fields: name, description, active,        │
│  │   commandline, check/install_commandline             │
│  ├─ Name format: ^[a-zA-Z0-9_-]{3,50}$                │
│  └─ Path traversal detection (..)                      │
│                                                         │
│  validate_command_template_safety(command, field_name)  │
│  ├─ Injection pattern detection: ; | & $() ` eval      │
│  ├─ Shell invocation blocking: bash -c, sh -c          │
│  ├─ Environment variable leak detection                │
│  └─ Install command: package manager enforcement       │
│                                                         │
│  validate_variable_substitution(command, descriptor)    │
│  ├─ Extracts ${variable} references from templates     │
│  └─ Verifies all variables declared in consumes        │
│                                                         │
│  validate_data_objects(descriptor, field_type)          │
│  ├─ Validates consumes/provides field names             │
│  └─ Validates type declarations (string/integer/bool)  │
│                                                         │
│  validate_sandbox_compatibility(command)                │
│  ├─ Rejects /proc/, /sys/, mount, chroot, sudo         │
│  └─ Warns on network tools (curl, wget, etc.)          │
│                                                         │
│  validate_processes_field(descriptor)                   │
│  ├─ MIME type format validation                        │
│  └─ File extension format validation (dot prefix)      │
│                                                         │
│  detect_circular_dependencies(plugins_dir)             │
│  ├─ Builds provides→plugin mapping                     │
│  ├─ Constructs dependency graph from consumes          │
│  └─ Kahn's algorithm for cycle detection               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Design Notes**:
- Fail-fast: rejects invalid plugins before execution
- Aggregates all validation errors (does not stop on first)
- Shared circular dependency detection with executor

### Component: plugin_tool_checker.sh (Feature 0011)

Tool availability verification and installation guidance.

```
┌─────────────────────────────────────────────────────────┐
│            plugin_tool_checker.sh (223 lines)           │
│     Dependencies: logging.sh, platform_detection.sh     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  verify_plugin_tools(plugins_dir, interactive)          │
│  ├─ Iterates discovered plugin descriptors              │
│  ├─ Extracts check_commandline from each               │
│  ├─ Returns count of missing tools                     │
│  └─ Optionally prompts for installation                │
│                                                         │
│  check_tool_availability(check_command)                 │
│  ├─ Executes via bash -c subshell                      │
│  └─ Returns 0 (available) or 1 (missing)               │
│                                                         │
│  get_install_guidance(tool_name, platform)              │
│  ├─ ubuntu/debian: apt-get install                     │
│  ├─ darwin: brew install                               │
│  ├─ alpine: apk add                                    │
│  └─ generic: manual install guidance                   │
│                                                         │
│  prompt_tool_install(tool_name, install_cmd)            │
│  ├─ TTY detection for interactive mode                 │
│  ├─ User confirmation prompt (y/N)                     │
│  └─ Executes install_commandline on approval           │
│                                                         │
│  get_plugin_tool_status(descriptor)                     │
│  └─ Returns "available" or "missing"                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Design Notes**:
- Platform detection reused from existing core component
- Interactive mode gated on TTY detection (non-interactive safe)
- Tool status used by executor to skip plugins with missing deps

### Component: plugin_executor.sh (Feature 0009)

Plugin execution orchestration engine.

```
┌─────────────────────────────────────────────────────────┐
│             plugin_executor.sh (615 lines)               │
│   Dependencies: plugin_discovery.sh, plugin_validator.sh │
│                 plugin_tool_checker.sh, workspace.sh     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  orchestrate_plugins(workspace, plugins_dir, file)      │
│  ├─ Discovers and validates plugins                    │
│  ├─ Builds dependency graph                            │
│  ├─ Topological sort (Kahn's algorithm)                │
│  ├─ File type filtering per plugin                     │
│  ├─ Sequential execution in dependency order           │
│  └─ Merges results into workspace                      │
│                                                         │
│  build_dependency_graph(plugins)                        │
│  ├─ Maps provides fields to source plugins             │
│  ├─ Computes in-degree from consumes references        │
│  ├─ Detects circular dependencies                      │
│  └─ Returns ordered execution list                     │
│                                                         │
│  execute_plugin_sandboxed(plugin_dir, command, file)    │
│  ├─ Primary: bwrap sandbox execution                   │
│  │   ├─ ro-bind: /usr, /bin, /lib, /lib64, source file │
│  │   ├─ bind: plugin dir, temp dir                     │
│  │   └─ --unshare-net, --unshare-pid, --die-with-parent│
│  └─ Fallback: timeout-wrapped direct execution         │
│                                                         │
│  substitute_variables_secure(template, vars)            │
│  ├─ Validates variable names: ^[a-zA-Z0-9_]+$         │
│  ├─ Blocks injection chars: ; | & ` $() control chars │
│  └─ sed substitution with pipe delimiter               │
│                                                         │
│  should_execute_plugin(descriptor, file)                │
│  ├─ Wildcard check (*/* MIME, * extension)             │
│  ├─ Extension matching (fast path)                     │
│  └─ MIME type matching via file command (slow path)    │
│                                                         │
│  execute_plugin(plugin_name, file, workspace)           │
│  ├─ Variable substitution into command template        │
│  ├─ Sandboxed execution                               │
│  ├─ Comma-separated output parsing                    │
│  └─ Result mapping to provides fields                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Design Notes**:
- Largest component at 615 lines (orchestration complexity)
- DoS protection: 100 plugin maximum
- Continue-on-failure: logs warning but processes remaining plugins
- Plugin name validation: alphanumeric, hyphen, underscore only

### Plugin: stat (Feature 0020)

Reference plugin implementation demonstrating the full pipeline.

```
┌─────────────────────────────────────────────────────────┐
│          scripts/plugins/ubuntu/stat/                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  descriptor.json (32 lines)                            │
│  ├─ name: "stat"                                       │
│  ├─ active: true                                       │
│  ├─ processes: */* (universal - all file types)        │
│  ├─ consumes: file_path_absolute (string)              │
│  ├─ provides: file_last_modified, file_size, file_owner│
│  ├─ commandline: stat -c '%Y,%s,%U' '${file_path...}' │
│  ├─ check_commandline: which stat availability check   │
│  └─ install_commandline: apt install -y coreutils      │
│                                                         │
│  install.sh (24 lines)                                 │
│  ├─ Idempotent installation script                     │
│  ├─ Checks if stat already available                   │
│  └─ Installs coreutils via apt-get if missing          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Design Notes**:
- Universal plugin (no file type filtering)
- Zero external dependencies beyond coreutils
- Comma-separated output format aligns with executor parsing
- Serves as template for future plugin development

## Level 4: Execution Flow

Plugin execution pipeline from discovery to result capture:

```
  discover_plugins()
        │
        ▼
  validate_plugin_descriptor()     ← plugin_validator.sh
        │
        ▼
  verify_plugin_tools()            ← plugin_tool_checker.sh
        │
        ▼
  build_dependency_graph()         ← Kahn's algorithm
        │
        ▼
  topological_sort()
        │
        ▼
  ┌─── for each plugin (in order) ───┐
  │                                   │
  │  should_execute_plugin()          │
  │       │                           │
  │       ▼                           │
  │  substitute_variables_secure()    │
  │       │                           │
  │       ▼                           │
  │  execute_plugin_sandboxed()       │
  │       │                           │
  │       ▼                           │
  │  parse comma-separated output     │
  │       │                           │
  │       ▼                           │
  │  merge into workspace             │
  │                                   │
  └───────────────────────────────────┘
```

## Component Dependency Graph

```
core/logging.sh
    │
    ├──▶ plugin_parser.sh (existing)
    │       │
    │       └──▶ plugin_discovery.sh (existing)
    │               │
    │               ├──▶ plugin_validator.sh (new)
    │               │
    │               └──▶ plugin_executor.sh (new)
    │                       │
    │                       ├── uses plugin_validator.sh
    │                       ├── uses plugin_tool_checker.sh
    │                       └── uses workspace.sh
    │
    ├──▶ platform_detection.sh (existing)
    │       │
    │       └──▶ plugin_tool_checker.sh (new)
    │
    └──▶ workspace.sh (existing)
```

## Architecture Metrics

### Size Metrics

| Component | Lines | Target (<200) | Status |
|-----------|-------|---------------|--------|
| plugin_validator.sh | 491 | Exceeds | ⚠️ Justified by validation breadth |
| plugin_tool_checker.sh | 223 | Slightly over | ✅ Acceptable |
| plugin_executor.sh | 615 | Exceeds | ⚠️ Justified by orchestration complexity |
| stat/descriptor.json | 32 | N/A | ✅ |
| stat/install.sh | 24 | N/A | ✅ |

### Security Metrics

| Security Control | Status |
|-----------------|--------|
| Command injection prevention | ✅ Pattern blocking + sandbox |
| Path traversal prevention | ✅ Validator rejects `..` paths |
| Variable substitution security | ✅ Allowlist character validation |
| Sandbox isolation (when bwrap available) | ✅ Network, PID, filesystem isolation |
| Plugin count DoS protection | ✅ 100 plugin limit |
| Circular dependency detection | ✅ Kahn's algorithm |

## Related Documentation

- **Architecture Decision**: [IDR-0016: Plugin Execution Engine Implementation](../09_architecture_decisions/IDR_0016_plugin_execution_engine_implementation.md)
- **Vision ADRs**: [ADR-0009](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0009_plugin_security_sandboxing_bubblewrap.md), [ADR-0010](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0010_plugin_toolkit_interface_architecture.md)
- **Prior Building Block**: [Feature 0015: Modular Component Architecture](feature_0015_modular_component_architecture.md)
- **Component README**: [scripts/components/README.md](../../../../scripts/components/README.md)
