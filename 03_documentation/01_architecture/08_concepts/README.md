# 8. Concepts (Implementation)

**Status**: Active  
**Last Updated**: 2026-02-08  
**Vision Reference**: [Concepts](../../../01_vision/03_architecture/08_concepts/)

## Overview

This directory documents the key cross-cutting concepts implemented in the doc.doc toolkit. Each concept is detailed in its own document.

## Table of Contents

- [Implemented Concepts](#implemented-concepts)
  - [Concept 0001: Plugin Architecture](#concept-0001-plugin-architecture)
  - [Concept 0002: Workspace Management](#concept-0002-workspace-management)
  - [Concept 0003: CLI Interface](#concept-0003-cli-interface)
- [Concept Status Summary](#concept-status-summary)
- [Cross-Cutting Concerns](#cross-cutting-concerns)
  - [Error Handling ✅ IMPLEMENTED](#error-handling--implemented)
  - [Logging ✅ IMPLEMENTED](#logging--implemented)
  - [Platform Detection ✅ IMPLEMENTED](#platform-detection--implemented)
  - [JSON Processing ✅ IMPLEMENTED](#json-processing--implemented)
  - [Data Serialization ✅ PARTIALLY IMPLEMENTED](#data-serialization--partially-implemented)
- [Design Principles Applied](#design-principles-applied)
  - [Unix Philosophy ✅ HONORED](#unix-philosophy--honored)
  - [Modularity ✅ IMPLEMENTED](#modularity--implemented)
  - [Defensive Programming ✅ IMPLEMENTED](#defensive-programming--implemented)
- [Future Concepts (Planned)](#future-concepts-planned)
  - [Template System ⏳ PLANNED](#template-system--planned)
  - [Dependency Resolution ⏳ PLANNED](#dependency-resolution--planned)
  - [Incremental Analysis ⏳ PLANNED](#incremental-analysis--planned)
  - [Concurrency Control ⏳ PLANNED](#concurrency-control--planned)
- [Concept Documentation Standards](#concept-documentation-standards)
- [Summary](#summary)

## Implemented Concepts

### [Concept 0001: Plugin Architecture](./08_0001_plugin_concept.md) ✅ PARTIALLY IMPLEMENTED

**Status**: Discovery and validation implemented, execution pending

The plugin system allows extending functionality through JSON descriptors that define CLI tool integration.

**Implemented**:
- ✅ Plugin discovery (platform-aware scanning)
- ✅ Descriptor parsing and validation
- ✅ Tool availability checking
- ✅ Platform-specific precedence
- ✅ Plugin listing command

**Pending**:
- ⏳ Plugin execution orchestration
- ⏳ Data dependency resolution
- ⏳ Plugin output processing

**Key Files**:
- `scripts/plugins/all/*/descriptor.json` - Cross-platform plugins
- `scripts/plugins/{platform}/*/descriptor.json` - Platform-specific plugins

**Related ADRs**:
- ADR-0010: Pipe-Delimited Plugin Data
- ADR-0011: Dual JSON Parser Strategy
- ADR-0012: Platform-Specific Plugin Precedence
- ADR-0014: Continue on Malformed Descriptors
- ADR-0015: Alphabetical Plugin Sorting

---

### [Concept 0002: Workspace Management](./08_0002_workspace_concept.md) ⏳ PLANNED

**Status**: Not yet implemented, design complete

The workspace provides persistent storage for analysis state, enabling incremental processing and external tool integration.

**Design Complete**:
- 📋 JSON-based file-per-document storage
- 📋 Atomic write pattern with lock files
- 📋 Incremental analysis logic
- 📋 External tool integration interfaces

**Implementation Pending**:
- ⏳ Workspace initialization
- ⏳ File metadata persistence
- ⏳ JSON read/write operations
- ⏳ Lock file management

**Planned Structure**:
```
workspace/
├── <hash>.json       # Per-file analysis data
├── <hash>.json.lock  # Concurrent access lock
└── metadata.json     # Workspace-level info
```

---

### [Concept 0003: CLI Interface](./08_0003_cli_interface_concept.md) ✅ IMPLEMENTED

**Status**: Core interface complete, analysis operations pending

The command-line interface follows POSIX conventions and Unix philosophy for composability.

**Implemented**:
- ✅ Argument parsing (POSIX-style)
- ✅ Help text with examples
- ✅ Version information
- ✅ Verbose logging mode
- ✅ Plugin listing command
- ✅ Exit code system (0-5)
- ✅ Error messages with guidance

**Pending**:
- ⏳ Full analysis command execution
- ⏳ Progress reporting during analysis
- ⏳ Workspace/report path handling

**Related ADRs**:
- ADR-0004: Log Level Design
- ADR-0005: No Args Shows Help
- ADR-0008: Exit Code System

---

## Concept Status Summary

| Concept | Status | Completion | Priority |
|---------|--------|------------|----------|
| Plugin Architecture | 🟡 Partial | ~60% | High |
| Workspace Management | ⏳ Planned | 0% | High |
| CLI Interface | ✅ Done | ~90% | High |

## Cross-Cutting Concerns

### Error Handling ✅ IMPLEMENTED

**Approach**: Defensive programming with clear error messages

**Implementation**:
- Bash strict mode (`set -euo pipefail`)
- Named exit code constants
- `error_exit()` function for consistent errors
- Detailed error messages with user guidance

**Coverage**:
- ✅ Argument validation
- ✅ Plugin descriptor validation
- ✅ Platform detection failures
- ⏳ File access errors (planned)
- ⏳ Workspace errors (planned)

**Related ADRs**: ADR-0006 (Bash Strict Mode), ADR-0008 (Exit Codes)

---

### Logging ✅ IMPLEMENTED

**Approach**: Structured logging with level-based filtering

**Implementation**:
```bash
log() {
  local level="$1"
  local message="$2"
  
  # Log levels: DEBUG, INFO, WARN, ERROR
  # DEBUG/INFO only shown in verbose mode
  # WARN/ERROR always shown
  # All logs to stderr (keeps stdout clean for data)
}
```

**Features**:
- ✅ Four log levels (DEBUG, INFO, WARN, ERROR)
- ✅ Verbose mode toggle (`-v` flag)
- ✅ Stderr routing (stdout clean for data)
- ⏳ Timestamp addition (future enhancement)

**Related ADRs**: ADR-0004 (Log Level Design)

---

### Platform Detection ✅ IMPLEMENTED

**Approach**: Three-tier fallback detection

**Implementation**:
1. Parse `/etc/os-release` for `ID` field (modern Linux)
2. Fallback to `uname -s` (macOS, BSD)
3. Default to "generic" if both fail

**Supported Platforms**:
- ✅ Ubuntu (primary)
- ✅ Debian
- ✅ Generic Linux
- ⏳ macOS (untested)
- ⏳ Alpine (untested)

**Usage**: Determines which plugin directories to scan

**Related ADRs**: ADR-0003 (Platform Detection Fallback)

---

### JSON Processing ✅ IMPLEMENTED

**Approach**: Dual parser strategy for maximum compatibility

**Implementation**:
- Primary: `jq` (fast, efficient, standard tool)
- Fallback: `python3 -c 'import json, sys; ...'`
- Graceful degradation if both unavailable (future: basic bash parsing)

**Use Cases**:
- ✅ Plugin descriptor parsing
- ⏳ Workspace JSON read/write (planned)
- ⏳ Metadata processing (planned)

**Related ADRs**: ADR-0011 (Dual JSON Parser Strategy)

---

### Data Serialization ✅ PARTIALLY IMPLEMENTED

**Approach**: Pipe-delimited strings for inter-function communication

**Implementation**:
- Plugin data: `"name|description|active|available"`
- Simple, bash-native format
- No external dependencies for parsing
- Efficient for function returns

**Use Cases**:
- ✅ Plugin discovery internal representation
- ⏳ Future: File list representation

**Related ADRs**: ADR-0010 (Pipe-Delimited Plugin Data)

---

## Design Principles Applied

### Unix Philosophy ✅ HONORED

**Principles**:
1. Do one thing well → Single-purpose script
2. Work together → Composable via exit codes and pipes
3. Text streams → Stdout/stderr, Markdown reports

**Evidence**:
- ✅ Exit codes for scripting
- ✅ Stderr for logs (stdout clean)
- ✅ Text-based output
- ✅ No interactive prompts in scripts

---

### Modularity ✅ IMPLEMENTED

**Approach**: Function-based modular architecture

**Implementation**:
- Each function has single responsibility
- Clear interfaces (parameters and return codes)
- Entry point guard for testing
- Independent testable units

**Related ADRs**: ADR-0007 (Modular Function Architecture), ADR-0009 (Entry Point Guard)

---

### Defensive Programming ✅ IMPLEMENTED

**Approach**: Validate inputs, handle errors gracefully

**Implementation**:
- Bash strict mode (exit on errors)
- Input validation in parsers
- Existence checks before operations
- Clear error messages

**Related ADRs**: ADR-0006 (Bash Strict Mode)

---

## Future Concepts (Planned)

### Template System ⏳ PLANNED

Variable substitution in Markdown templates for report generation.

### Dependency Resolution ⏳ PLANNED

Automatic plugin execution ordering based on data dependencies (consumes/provides).

### Incremental Analysis ⏳ PLANNED

Change detection using workspace timestamps to skip unchanged files.

### Concurrency Control ⏳ PLANNED

Lock file mechanism for safe concurrent access to workspace files.

---

## Concept Documentation Standards

Each concept document follows this structure:
1. **Purpose**: What problem it solves
2. **Rationale**: Why this approach
3. **Implementation**: How it works (code/design)
4. **Status**: What's done, what's pending
5. **Related**: Links to ADRs, code, tests

---

## Summary

The implemented concepts establish a solid foundation:
- ✅ **Plugin Architecture**: Discovery working, execution pending
- ⏳ **Workspace Management**: Design complete, implementation pending
- ✅ **CLI Interface**: Core complete, analysis commands pending

**Cross-cutting concerns** (error handling, logging, platform detection) are well-implemented and support the core concepts effectively.

**Next Steps**: Implement workspace management and plugin execution to complete the conceptual framework.
