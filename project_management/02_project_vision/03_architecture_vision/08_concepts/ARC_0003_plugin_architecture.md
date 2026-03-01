## Plugin Architecture

**Author:** Architect Agent  
**Created on:** 2026-03-01  
**Last Updated:** 2026-03-01  
**Status:** Proposed


**Version History**  
| Date       | Author       | Description                |
|------------|--------------|----------------------------|
| 2026-03-01 | Architect Agent | Initial concept creation from legacy documentation |

**Table of Contents:**  
- [Problem Statement](#problem-statement)
- [Scope](#scope)
- [Proposed Solution](#proposed-solution)
- [Benefits](#benefits)
- [Challenges and Risks](#challenges-and-risks)
- [Implementation Plan](#implementation-plan)
- [Conclusion](#conclusion)
- [References](#references)


### Problem Statement
Different file types require different tools and methods to extract meaningful information for documentation. A monolithic application cannot efficiently support the wide variety of file types users may need to document. An extensible plugin architecture is needed to allow the system to handle diverse file types and enable community contributions of new capabilities.

### Scope
This concept defines the plugin architecture for doc.doc.md, including plugin structure, interface contracts, discovery mechanism, dependency resolution, and execution flow.

### In Scope
- Plugin directory structure and required files
- Plugin descriptor format and metadata
- Plugin interface (input/output contracts)
- Plugin discovery and validation mechanism
- Plugin dependency resolution and execution order
- Plugin lifecycle (installation, execution, error handling)
- Environment variable-based plugin communication
- JSON-based plugin output format

### Out of Scope
- Plugin distribution and marketplace
- Plugin versioning and updates
- Plugin sandboxing and security isolation
- Plugin configuration UI
- Plugin hot-reloading
- Cross-plugin communication beyond dependencies
- Plugin resource monitoring and limits

### Proposed Solution

#### Plugin Structure

Each plugin is a directory containing:

```
plugin_name/
├── descriptor.json       # Plugin metadata and configuration
├── main.sh              # Main processing script (referenced in commands.process)
├── install.sh           # Installation script (referenced in commands.install)
└── installed.sh         # Installation check script (referenced in commands.installed)
```

#### Descriptor Format

The `descriptor.json` file defines plugin metadata (see [ADR-003](../09_architecture_decisions/ADR_003_json_plugin_descriptors.md) for canonical schema):

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
          "description": "Human-readable file size"
        },
        "modifiedDate": {
          "type": "string",
          "description": "Last modified date"
        },
        "createdDate": {
          "type": "string",
          "description": "File creation date"
        },
        "permissions": {
          "type": "string",
          "description": "File permissions"
        },
        "owner": {
          "type": "string",
          "description": "File owner"
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
    }
  }
}
```

**Note**: The canonical plugin descriptor schema is defined in [ADR-003](../09_architecture_decisions/ADR_003_json_plugin_descriptors.md). All plugins must implement three standard commands:
- `process`: Main file processing command - requires `filePath` input parameter, defines plugin-specific output parameters
- `install`: Plugin installation/setup command - no input parameters, returns installation result
- `installed`: Check if plugin is properly installed - no input parameters, returns installation status

Each command defines its own input/output parameters with type declarations and descriptions. **All parameter names must follow lowerCamelCase naming convention** (e.g., `filePath`, `mimeType`, `fileSize`). Additional custom commands may be defined for plugin-specific operations.

#### Plugin Interface

**Input** (via environment variables):
- `FILE_PATH`: Absolute path to the file being processed
- `OUTPUT_DIR`: Directory for output generation
- `PLUGIN_DATA_DIR`: Directory for plugin-specific temporary data

**Output** (via stdout, JSON format):
```json
{
  "fileSize": 1048576,
  "fileSizeHuman": "1.0 MB",
  "modifiedDate": "2024-02-25 14:30:00",
  "permissions": "rw-r--r--"
}
```

**Note**: Output variable names must match the lowerCamelCase names defined in the descriptor's `output` object.

#### Plugin Execution Flow

1. **Discovery**: System scans plugin directory, loads descriptors
2. **Validation**: Check dependencies and system requirements
3. **Selection**: Determine applicable plugins for each file type
4. **Execution**: Run plugins in dependency order
5. **Aggregation**: Merge outputs from all plugins
6. **Template Application**: Substitute variables with aggregated data

#### Plugin Dependency Resolution

Example dependency chain:
```
Plugin A (no dependencies)
Plugin B (depends on Plugin A)
Plugin C (depends on Plugin B)

Execution order: A → B → C
```

**Algorithm:**
1. Build dependency graph from descriptors
2. Perform topological sort
3. Detect circular dependencies (error if found)
4. Execute in sorted order
5. Pass previous plugin outputs to dependent plugins

#### Plugin Discovery

The system searches for plugins in:
1. User plugins: `~/.config/doc.doc.md/plugins/`
2. System plugins: `/usr/local/share/doc.doc.md/plugins/`
3. Project plugins: `./doc.doc.md/plugins/` (if present)

#### Plugin Installation

Plugins can include `install.sh` and `installed.sh` scripts:
- `install.sh`: Installs plugin dependencies
- `installed.sh`: Checks if plugin is ready to use (exit code 0 = installed)

The system runs `installed.sh` before executing a plugin and automatically runs `install.sh` if needed.

### Benefits
- **Extensibility**: New file types can be supported by adding plugins
- **Modularity**: Each plugin is isolated and self-contained
- **Community contributions**: Users can create and share plugins
- **Flexibility**: Plugins can use any tool or language internally
- **Maintainability**: Core system remains simple, complexity is in plugins
- **Reusability**: Plugins can be shared across different installations
- **Simple interface**: Environment variables and JSON are universal

### Challenges and Risks
- **Plugin quality**: User-created plugins may be unreliable or insecure
- **Performance**: Many plugins or slow plugins can impact processing speed
- **Compatibility**: Plugins may depend on external tools not available on all systems
- **Error handling**: Plugin failures need graceful degradation
- **Security**: Plugins have full system access, no sandboxing in initial version
- **Dependency complexity**: Complex dependency chains may be hard to debug
- **Version conflicts**: Different plugins may require different versions of tools

### Implementation Plan
1. **Phase 1**: Define plugin descriptor format and interface
2. **Phase 2**: Implement plugin discovery mechanism
3. **Phase 3**: Implement plugin validation (check system requirements)
4. **Phase 4**: Implement basic plugin execution (no dependencies)
5. **Phase 5**: Implement dependency resolution and topological sort
6. **Phase 6**: Implement plugin installation mechanism
7. **Phase 7**: Create built-in plugins (stat, file)
8. **Phase 8**: Add error handling and graceful degradation
9. **Phase 9**: Document plugin development guidelines
10. **Phase 10**: Create plugin template and examples

### Conclusion
The plugin architecture provides a flexible and extensible foundation for doc.doc.md. By defining a simple interface based on environment variables and JSON output, plugins can be written in any language and use any tools. The dependency resolution system allows complex plugin interactions while maintaining simplicity for basic use cases. This architecture enables the system to grow and adapt to new file types and use cases without requiring changes to the core system.

### References
- Original concepts documentation: [08_concepts_old.md](08_concepts_old.md)
- Template processing concept: [ARC_0002_template_processing.md](ARC_0002_template_processing.md)
- Error handling concept: [ARC_0004_error_handling.md](ARC_0004_error_handling.md)
- JSON output format specifications
- Topological sort algorithms
