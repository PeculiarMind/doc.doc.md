# Requirement: Plugin-based Extensibility

**ID**: req_0022  
**Title**: Plugin-based Extensibility  
**Status**: Accepted  
**Created**: 2026-02-04  
**Category**: Functional

## Overview
The toolkit shall support extension through plugins, allowing users to integrate custom CLI tools and analysis capabilities without modifying the core system. Each plugin shall declare its data consumption and production capabilities through a descriptor.

## Description
The system must provide a plugin architecture that enables users to extend analysis capabilities by adding custom CLI tool integrations. Plugins operate as self-contained modules that declare their input requirements (what information they consume) and output capabilities (what information they provide) through structured descriptors. This allows the core system to remain unchanged while new analysis capabilities are added. 

Plugins return processing results via bash variables using the `read` command. Input variables are consumed by referencing them in the plugin's commandline using bash variable expansion (`${variable_name}`), and output variables are assigned by the plugin's commandline using bash `read -r variable1 variable2 ...` syntax. This variable-based interface enables the core system to orchestrate data flow between plugins without requiring intermediate files or complex parsing.

## Motivation
From the vision: "The toolkit is designed to be extended through plugins, allowing users to integrate custom CLI tools and analysis capabilities without modifying the core system. Each plugin declares what information it consumes and what information it provides through its descriptor."

This requirement enables the "Toolkit extensibility" goal, allowing users to customize and extend the analysis workflow by adding or substituting CLI tools as needed without forking or modifying the core codebase.

## Acceptance Criteria
1. The system provides a defined plugin interface that specifies how plugins integrate with the core system
2. Each plugin includes a descriptor file (e.g., `descriptor.json`) that declares:
   - Plugin metadata (name, version, description)
   - Data inputs: what information the plugin requires to execute
   - Data outputs: what information the plugin produces
   - CLI tool dependencies required by the plugin
3. Plugins can be added to the system by placing them in a designated plugin directory without modifying core system code
4. The system discovers and loads plugins automatically from the plugin directory
5. Plugins execute using the CLI tools they declare in their descriptors
6. Plugin descriptors are validated on load to ensure required fields are present
7. Plugins that fail validation produce clear error messages indicating what is missing or incorrect
8. Multiple plugins can coexist and operate independently without conflicts
9. Plugins return processing results via bash variables:
   - The plugin descriptor's `provides` section declares output variable names and types
   - The plugin's `commandline` uses bash `read -r` to assign values to declared output variables
   - The plugin descriptor's `consumes` section declares input variable names and types
   - The plugin's `commandline` references input variables using bash variable expansion (`${variable_name}`)
   - Variable names follow bash naming conventions (lowercase with underscores)
10. The plugin architecture supports both system-provided plugins and user-created custom plugins

## Example
The `stat` plugin demonstrates the variable-based interface:

**Descriptor (`descriptor.json`):**
```json
{
    "name": "stat",
    "consumes": {
        "file_path_absolute": {
            "type": "string",
            "description": "Path to the file to be analyzed."
        }
    },
    "provides": {
        "file_last_modified": {
            "type": "integer",
            "description": "Last modified time as Unix timestamp."
        },
        "file_size": {
            "type": "integer",
            "description": "Size of the file in bytes."
        },
        "file_owner": {
            "type": "string",
            "description": "Owner of the file."
        }
    },
    "commandline": "read -r file_created file_last_modified file_owner file_size < <(stat -c %W,%Y,%U,%B ${file_path_absolute})"
}
```

**How it works:**
1. The core system provides the input variable `file_path_absolute` (declared in `consumes`)
2. The commandline references it using `${file_path_absolute}` bash expansion
3. The commandline executes `stat` and uses `read -r` to assign output values to variables
4. The output variables `file_last_modified`, `file_size`, `file_owner` (declared in `provides`) are now available for other plugins or the core system

## Notes
This requirement focuses on the plugin interface and descriptor mechanism, providing the technical implementation details for the extensibility concept defined in req_0021. The orchestration of plugin execution order is addressed in req_0023 (Data-driven Execution Flow). Together, req_0022 and req_0023 implement the complete plugin architecture vision defined in req_0021.
