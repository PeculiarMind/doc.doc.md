# JSON-Based Plugin Descriptors with Shell Command Invocation

- **ID:** ADR-003
- **Status:** DECIDED
- **Created at:** 2026-02-25
- **Created by:** Architect Agent
- **Decided at:** 2026-02-25
- **Decided by:** Architecture Review
- **Obsoleted by:** N/A

# Change History
| Date | Author | Description |
|------|--------|-------------|
| 2026-02-25 | Architect Agent | Initial decision document created |

# TOC

1. [Context](#context)
2. [Decision](#decision)
3. [Consequences](#consequences)
4. [Alternatives Considered](#alternatives-considered)
5. [Evaluation Matrix](#evaluation-matrix)
6. [References](#references)

# Context

The doc.doc.md project requires a plugin system to extend document processing capabilities. This architectural decision addresses how plugins are described, discovered, and invoked by the system.

## Requirements

From the accepted requirements:

- **REQ_0003 (Plugin-Based Architecture)**: System must support plugins that can be installed, activated, and deactivated independently
- **REQ_0002 (Modular Architecture)**: Core functionality separated from extensions; clear extension points
- **REQ_0021-0028**: Plugin management commands (list, activate, deactivate, install, check installation, tree view)

## Design Challenges

1. **Language Agnosticism**: Plugins should be implementable in any language (Bash, Python, Perl, compiled binaries, etc.)
2. **Metadata Management**: System needs to know plugin capabilities, dependencies, entry points, and outputs
3. **Discovery**: System must automatically discover available plugins
4. **Dependency Resolution**: Need to execute plugins in correct order when dependencies exist
5. **Interface Consistency**: All plugins must provide consistent interface despite implementation language differences
6. **Parsing Complexity**: System (Bash) must easily parse plugin metadata

## Alternative Approaches Considered

### 1. Language-Specific Plugin Systems

**Python-only plugins with setuptools entry points**:
- Plugins define entry points in setup.py
- System imports plugins dynamically
- Benefits: Rich Python ecosystem, pip installation
- Drawbacks: Limited to Python; requires Python imports (tight coupling); complex for simple scripts

**Bash-only plugins with source'd files**:
- Plugins are Bash scripts with standard functions
- System sources plugin files
- Benefits: Simple, native to shell environment
- Drawbacks: Limited to Bash; namespace collisions; no isolation

### 2. Metadata Format Options

**Embedded metadata in plugin files**:
```bash
#!/bin/bash
# PLUGIN_NAME: stat
# PLUGIN_VERSION: 1.0.0
# PLUGIN_DEPENDENCIES: 
# PLUGIN_OUTPUT: file_size,modified_date
```
- Benefits: Single file, simple
- Drawbacks: Harder to parse; language-dependent comment syntax; limited structure

**YAML descriptors**:
```yaml
name: stat
version: 1.0.0
dependencies: []
output_variables:
  - file_size
  - modified_date
```
- Benefits: Human-readable, structured
- Drawbacks: Requires YAML parser (dependency); less universal than JSON

**JSON descriptors**:
```json
{
  "name": "stat",
  "version": "1.0.0",
  "dependencies": [],
  "output_variables": ["file_size", "modified_date"]
}
```
- Benefits: Universal parser support; structured; easy to validate
- Drawbacks: Slightly less human-friendly than YAML (but still readable)

### 3. Plugin Invocation Approaches

**Direct language imports** (Python example):
```python
import plugins.stat as stat_plugin
result = stat_plugin.process(file_path)
```
- Benefits: Fast, type-safe, IDE support
- Drawbacks: Language-specific; tight coupling; no isolation

**Shell command invocation**:
```bash
plugin_output=$(plugins/stat/main.sh "$file_path")
```
- Benefits: Language-agnostic; process isolation; simple interface
- Drawbacks: Slight overhead; no type safety

**RPC/Message Queue**:
- Complex plugin server/client architecture
- Benefits: Ultimate isolation, sophisticated communication
- Drawbacks: Massive overkill for file processing; deployment complexity

# Decision

**We will use JSON-based descriptor files with shell command invocation for the plugin system.**

## Plugin Structure

Each plugin consists of a directory containing:

```
plugins/<plugin_name>/
├── descriptor.json    # Plugin metadata (required)
├── main.sh           # Main entry point (required)
├── install.sh        # Installation script (optional)
└── installed.sh      # Installation check script (optional)
```

## Descriptor Format (descriptor.json)

```json
{
  "name": "stat",
  "version": "1.0.0",
  "description": "Provides file metadata using stat command",
  "author": "doc.doc.md team",
  "entry_point": "main.sh",
  "dependencies": [],
  "system_requirements": ["stat"],
  "input_types": ["*"],
  "output_variables": [
    "file_size",
    "file_size_human",
    "modified_date",
    "permissions"
  ],
  "install_command": "install.sh",
  "check_installed": "installed.sh"
}
```

## Plugin Invocation Interface

**Input** (via environment variables):
```bash
export FILE_PATH="/input/docs/report.pdf"
export OUTPUT_DIR="/output/docs"
export PLUGIN_DATA_DIR="/tmp/plugin_data"
```

**Output** (via stdout, JSON format):
```json
{
  "file_size": 1048576,
  "file_size_human": "1.0 MB",
  "modified_date": "2024-02-25",
  "permissions": "rw-r--r--"
}
```

**Exit codes**:
- 0: Success
- 1: Temporary failure (skip file, continue processing)
- 2: Fatal error (stop processing)

## Principles

1. **Language Agnostic**: Plugin entry point can be any executable (shell script, Python script, compiled binary)
2. **Standard Interface**: All plugins follow same input (env vars) and output (JSON to stdout) contract
3. **Process Isolation**: Each plugin invocation is separate process; no shared state
4. **Structured Metadata**: JSON descriptors easily parsed by Bash (via Python/jq) and other tools
5. **Self-Contained**: Each plugin directory contains everything needed for that plugin
6. **Optional Installation**: Plugins without dependencies work immediately; others provide install script

# Consequences

## Positive

1. **Language Freedom**: Developers can write plugins in any language they choose
2. **Simple Discovery**: List directory, read JSON files - no complex plugin registry
3. **Easy Parsing**: JSON parsable in Bash (via jq or Python), Python, and virtually all languages
4. **Process Isolation**: Plugin crashes don't affect core system or other plugins
5. **No Tight Coupling**: Core system never imports plugin code; clean separation
6. **Testability**: Plugins easily tested independently; mock via environment variables
7. **Universal Tools**: JSON validators, schema tools widely available
8. **Version Control Friendly**: Text files (JSON, shell scripts) work well in Git
9. **Documentation**: descriptor.json serves as self-documentation

## Negative

1. **Process Overhead**: Shell invocation has ~10-50ms overhead per file per plugin (acceptable for I/O-bound workload)
2. **No Type Safety**: Interface contract unenforced at compile time (mitigated by validation and testing)
3. **JSON Parsing in Bash**: Requires jq or Python helper (acceptable; follows ADR-002 tool reuse)
4. **Slightly Verbose**: Separate descriptor file vs embedded metadata (acceptable; clearer separation)

## Risks and Mitigation

| Risk | Mitigation |
|------|-----------|
| **Performance overhead** | Workload is I/O-bound; process overhead negligible compared to file operations |
| **JSON parsing complexity** | Use jq (standard tool) or Python JSON module; isolate parsing in single function |
| **Interface violations** | Validate plugin output; provide clear error messages; offer plugin validation tool |
| **Descriptor format drift** | Define JSON schema; validate all descriptors on load; version descriptor format |

# Alternatives Considered

## Alternative 1: Python-Only Plugin System with Entry Points

**Approach**: Use Python setuptools entry points for plugin discovery.

**Evaluation**:
- ✅ Rich Python ecosystem
- ✅ Standard plugin pattern
- ❌ Limited to Python (violates language agnostic goal)
- ❌ Requires Python imports (tight coupling)
- ❌ More complex for simple Bash-based plugins

**Conclusion**: Rejected due to language limitation.

## Alternative 2: Embedded Metadata in Plugin Files

**Approach**: Comments at top of main.sh with structured metadata.

**Evaluation**:
- ✅ Single file simplicity
- ❌ Language-specific comment syntax
- ❌ Harder to parse reliably
- ❌ Limited structure (no nested objects)
- ❌ No validation tools

**Conclusion**: Rejected due to parsing complexity and limited structure.

## Alternative 3: YAML Descriptors

**Approach**: Use YAML instead of JSON for descriptors.

**Evaluation**:
- ✅ More human-readable
- ✅ Supports comments
- ❌ Requires YAML parser (PyYAML, yq)
- ❌ Less universal than JSON
- ❌ More complex parsing in Bash

**Conclusion**: Rejected; JSON advantage in universality outweighs YAML readability.

# Evaluation Matrix

| Criterion | JSON + Shell | Python Entry Points | Embedded Metadata | YAML + Shell |
|-----------|--------------|---------------------|-------------------|--------------|
| Language Agnostic | ✅ Excellent | ❌ Python Only | ⚠️ Limited | ✅ Excellent |
| Parsing Simplicity | ✅ Simple (jq) | ✅ Native | ❌ Complex | ⚠️ Moderate |
| Structured Data | ✅ Full | ✅ Full | ❌ Limited | ✅ Full |
| Process Isolation | ✅ Full | ❌ None | ⚠️ Depends | ✅ Full |
| Performance | ✅ Good | ✅ Excellent | ✅ Excellent | ✅ Good |
| Tool Support | ✅ Universal | ⚠️ Python | ❌ Limited | ⚠️ Moderate |
| Complexity | ✅ Low | ⚠️ Moderate | ✅ Low | ⚠️ Moderate |
| Validation | ✅ JSON Schema | ✅ Type hints | ❌ Manual | ⚠️ YAML Schema |

**Winner**: JSON + Shell best balances language agnosticism, simplicity, and tooling.

# References

- [REQ_0002: Modular Architecture](../../../02_requirements/03_accepted/REQ_0002_modular-architecture.md)
- [REQ_0003: Plugin-Based Architecture](../../../02_requirements/03_accepted/REQ_0003_plugin-system.md)
- [ADR-001: Mixed Bash/Python Implementation](ADR_001_mixed_bash_python_implementation.md)
- [ADR-002: Prioritize Tool Reuse](ADR_002_prioritize_tool_reuse.md)
- [Building Block View - Plugin Architecture](../05_building_block_view/05_building_block_view.md#level-4-plugin-architecture)
