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
| 2026-03-01 | GitHub Copilot | Updated canonical schema to include `active` field and `commands` object for plugin-specific commands |
| 2026-03-01 | GitHub Copilot | Revised schema: moved all commands to `commands` object; removed `entry_point`, `install_command`, `check_installed`; defined standard required commands (process, install, installed) |
| 2026-03-01 | GitHub Copilot | Revised schema: input/output parameters now defined per command (not globally); removed global `input_types` and `output_variables`; each parameter requires type and description; install/installed commands have no input params |
| 2026-03-01 | GitHub Copilot | Added naming convention: all input/output parameter names must follow lowerCamelCase (e.g., `filePath`, `mimeType`, `fileSize`) |
| 2026-03-01 | GitHub Copilot | Removed `system_requirements` field - install and installed commands are responsible for managing and verifying dependencies |
| 2026-03-01 | GitHub Copilot | Removed `dependencies` field - dependencies discovered automatically by analyzing input/output parameters between plugins |
| 2026-03-01 | Architect Agent | Changed plugin parameter passing from environment variables to JSON stdin/stdout communication for improved type preservation, security, and consistency |

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
├── main.sh           # Main processing script (required - referenced in commands.process)
├── install.sh        # Installation script (required - referenced in commands.install)
└── installed.sh      # Installation check script (required - referenced in commands.installed)
```

## Descriptor Format (descriptor.json)

**Canonical Plugin Descriptor Schema** (Updated 2026-03-01):

```json
{
  "name": "stat",
  "version": "1.0.0",
  "description": "Provides file metadata using stat command",
  "author": "doc.doc.md team",
  "active": true,
  "commands": {
    "process": {
      "description": "Process a file and output metadata",
      "command": "main.sh",
      "input": {
        "filePath": {
          "type": "string",
          "description": "Absolute path to the file being processed",
          "required": true
        }
      },
      "output": {
        "fileSize": {
          "type": "number",
          "description": "File size in bytes"
        },
        "fileSizeHuman": {
          "type": "string",
          "description": "Human-readable file size (e.g., '1.5 MB')"
        },
        "modifiedDate": {
          "type": "string",
          "description": "Last modified date in ISO format"
        },
        "permissions": {
          "type": "string",
          "description": "File permissions (e.g., 'rw-r--r--')"
        }
      }
    },
    "install": {
      "description": "Install plugin dependencies",
      "command": "install.sh",
      "output": {
        "success": {
          "type": "boolean",
          "description": "Whether installation succeeded"
        }
      }
    },
    "installed": {
      "description": "Check if plugin is installed",
      "command": "installed.sh",
      "output": {
        "installed": {
          "type": "boolean",
          "description": "Whether plugin is installed and ready"
        }
      }
    },
    "validate": {
      "description": "Validate stat command is available",
      "command": "command -v stat",
      "output": {
        "available": {
          "type": "boolean",
          "description": "Whether stat command is available"
        }
      }
    }
  }
}
```

**Required Fields**:
- `name`: String matching `[a-zA-Z0-9_-]+`, max 64 characters - unique plugin identifier
- `version`: Semantic version string (e.g., "1.0.0")
- `description`: String, max 500 characters - human-readable description
- `commands`: Object - plugin command definitions (REQUIRED)
  - **Standard Required Commands** (must be implemented by all plugins):
    - `process`: Main file processing command
      - **Input**: Must define `filePath` parameter (type: string, required: true)
      - **Output**: Plugin-specific output variables (each with type and description)
      - **Parameter Naming**: All input/output parameter names must follow lowerCamelCase convention (e.g., `filePath`, `mimeType`, `fileSize`)
    - `install`: Installation script - NO input parameters required
      - **Output**: Installation result (typically success/failure boolean)
    - `installed`: Installation check - NO input parameters required
      - **Output**: Installation status (typically installed boolean)
  - **Optional Custom Commands**: Plugins may define additional commands for specific operations
  - Each command structure:
    - `description`: String - what the command does
    - `command`: String - shell command/script to execute (relative to plugin directory)
    - `input`: Object (optional) - input parameter definitions
      - Each parameter has: `type` (string/number/boolean/object/array), `description` (string), `required` (boolean, default: false)
      - **Parameter names must follow lowerCamelCase convention** (pattern: `^[a-z][a-zA-Z0-9]*$`)
    - `output`: Object (optional) - output variable definitions
      - Each variable has: `type` (string/number/boolean/object/array), `description` (string)
      - **Variable names must follow lowerCamelCase convention** (pattern: `^[a-z][a-zA-Z0-9]*$`)

**Optional Fields**:
- `author`: String - plugin author/maintainer information
- `active`: Boolean (default: true) - plugin activation status (for future use in plugin management)

## Plugin Invocation Interface

**Standard Commands**:

All plugins must implement three standard commands in the `commands` object:

1. **process**: Main file processing command
   - **Input** (via stdin, JSON format):
     ```json
     {
       "filePath": "/input/docs/report.pdf",
       "outputDir": "/output/docs",
       "pluginDataDir": "/tmp/plugin_data"
     }
     ```
     **Note**: Input parameter names match the lowerCamelCase names defined in the descriptor's input schema.
   - **Output** (via stdout, JSON format):
     ```json
     {
       "fileSize": 1048576,
       "fileSizeHuman": "1.0 MB",
       "modifiedDate": "2024-02-25",
       "permissions": "rw-r--r--"
     }
     ```
     **Note**: Output variable names must match the lowerCamelCase names defined in the descriptor.
   - **Exit codes**:
     - 0: Success
     - 1: Temporary failure (skip file, continue processing)
     - 2: Fatal error (stop processing)

2. **install**: Install plugin dependencies
   - **Input** (via stdin): Empty JSON object `{}` or no input
   - Executes installation of required system tools or dependencies
   - **Exit codes**: 0 = success, non-zero = failure

3. **installed**: Check if plugin is installed
   - **Input** (via stdin): Empty JSON object `{}` or no input
   - Verifies all dependencies and requirements are met
   - **Exit codes**: 0 = installed and ready, non-zero = not installed or missing requirements

**Custom Commands**:
- Plugins may define additional commands for specific operations (e.g., `validate`, `configure`, `test`)
- Custom commands follow the same invocation pattern (shell execution, exit codes)

## Principles

1. **Language Agnostic**: Plugin commands can be any executable (shell script, Python script, compiled binary)
2. **Standard Interface**: All plugins implement standard commands (process, install, installed) with same contracts
3. **Process Isolation**: Each plugin invocation is separate process; no shared state
4. **Structured Metadata**: JSON descriptors easily parsed by Bash (via Python/jq) and other tools
5. **Self-Contained**: Each plugin directory contains everything needed for that plugin
6. **Command-Based Invocation**: All plugin functionality accessed through commands object, enabling standardization and extensibility
8. **Optional Installation**: Plugins without dependencies work immediately; others provide install script
9. **JSON stdin/stdout Communication**: Parameters passed as JSON via stdin, output returned as JSON via stdout for type preservation and consistency

# Consequences

## Positive

1. **Language Freedom**: Developers can write plugins in any language they choose
2. **Simple Discovery**: List directory, read JSON files - no complex plugin registry
3. **Easy Parsing**: JSON parsable in Bash (via jq or Python), Python, and virtually all languages
4. **Process Isolation**: Plugin crashes don't affect core system or other plugins
5. **No Tight Coupling**: Core system never imports plugin code; clean separation
6. **Testability**: Plugins easily tested independently; mock via JSON stdin input
7. **Universal Tools**: JSON validators, schema tools widely available
8. **Version Control Friendly**: Text files (JSON, shell scripts) work well in Git
9. **Documentation**: descriptor.json serves as self-documentation
10. **Type Preservation**: JSON stdin/stdout maintains type information (numbers, booleans, arrays, objects) vs. string-only environment variables
11. **No Size Limits**: JSON stdin avoids environment variable size limitations for large parameter values
12. **Security**: Eliminates environment variable injection attack vectors
13. **Consistency**: Same communication format (JSON) for both input and output

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
