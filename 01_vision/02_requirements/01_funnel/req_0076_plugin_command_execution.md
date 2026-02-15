# Requirement: Plugin Command Execution Interface
ID: req_0076

## Status
State: Funnel
Created: 2026-02-14
Last Updated: 2026-02-14

## Overview
The system shall provide a command-line interface to execute plugin-specific commands, enabling plugins to expose custom operations beyond standard analysis workflows.

## Description
Plugins may require specialized operations that go beyond processing files during the analysis workflow. For example:
- **Training classifiers**: Bogofilter plugins need to train categories with positive/negative examples
- **Configuration management**: Plugins may need initialization, configuration updates, or state management
- **Database operations**: Plugins with persistent state may need maintenance operations (rebuild, optimize, clear)
- **Diagnostics**: Plugins may provide health checks, validation, or troubleshooting commands
- **Data import/export**: Plugins may support importing training data or exporting learned models

The system should provide a standardized interface to invoke these plugin-specific commands through the main CLI entry point (`doc.doc.sh`), maintaining a consistent user experience and avoiding the need for users to directly interact with plugin implementation details.

**Proposed Interface**:
```bash
./doc.doc.sh -p exec <PLUGIN_NAME> <COMMAND> [PARAMS...]
```

This allows plugins to declare supported commands in their descriptors, and the system routes the command invocation to the appropriate plugin handler.

## Motivation
Links to vision sections:
- [Vision: Plugin-based extensibility](../../01_project_vision/01_vision.md) - "Enable users to customize and extend the analysis workflow by adding or substituting CLI tools as needed"
- [Vision: Script entry point](../../01_project_vision/01_vision.md) - "The primary entry point is a single script" - extending this to plugin operations maintains simplicity
- [Vision: Usability](../../01_project_vision/01_vision.md) - "Provide scripts that verify required tools are installed and, if not, prompt the user to install them"

This requirement enables plugins to be fully self-contained with their own operations accessible through a unified interface, improving usability and plugin capabilities without requiring users to understand plugin internals.

## Category
- Type: Functional
- Priority: Medium

## Acceptance Criteria
- [ ] System accepts `-p exec <PLUGIN_NAME> <COMMAND> [PARAMS...]` syntax
- [ ] Plugins declare supported commands in their descriptors
- [ ] System routes command execution to the appropriate plugin handler script
- [ ] Command parameters are passed through to the plugin handler
- [ ] Plugin command output is displayed to user
- [ ] Plugin command exit codes are propagated to doc.doc.sh exit code
- [ ] Error handling for unknown plugins, unknown commands, and execution failures
- [ ] `-p exec <PLUGIN_NAME> help` displays plugin-specific command help
- [ ] `-p exec --help` displays generic help about plugin command execution
- [ ] Plugin commands can access common utilities (logging, configuration, workspace paths)
- [ ] Security: Plugin commands execute with same sandboxing as plugin analysis (if req_0048 implemented)
- [ ] Documentation explains how to add commands to plugin descriptors

## Related Requirements
- [req_0022](../03_accepted/req_0022_plugin_based_extensibility.md) - Plugin-based Extensibility (foundation)
- [req_0024](../03_accepted/req_0024_plugin_listing.md) - Plugin Listing (similar -p interface pattern)
- [req_0047](../03_accepted/req_0047_plugin_descriptor_validation.md) - Plugin Descriptor Validation (validates command declarations)
- [req_0048](../03_accepted/req_0048_plugin_execution_sandboxing.md) - Plugin Execution Sandboxing (may apply to commands)
- [req_0017](../03_accepted/req_0017_script_entry_point.md) - Script Entry Point (extends primary interface)
- [req_0075](./req_0075_bogofilter_spam_analysis_plugin.md) - Bogofilter Plugin (motivating use case: training commands)

## Use Cases

### Use Case 1: Train Bogofilter Category
```bash
# Train "technical" category with positive examples
./doc.doc.sh -p exec bogofilter train technical --positive technical_docs/

# Train with negative examples
./doc.doc.sh -p exec bogofilter train technical --negative general_docs/

# Check training status
./doc.doc.sh -p exec bogofilter status technical
```

### Use Case 2: Plugin Diagnostics
```bash
# Check plugin health
./doc.doc.sh -p exec ocrmypdf check

# Validate plugin configuration
./doc.doc.sh -p exec stat validate
```

### Use Case 3: Plugin Help
```bash
# Get plugin-specific command help
./doc.doc.sh -p exec bogofilter help

# List available commands for a plugin
./doc.doc.sh -p exec bogofilter
```

## Notes
- Plugin descriptor should include `commands` section declaring supported operations
- Each command should specify: name, description, parameters, handler script/function
- Consider command namespacing to avoid conflicts
- Plugin commands should follow same conventions as main CLI (verbose mode, logging, error handling)
- Future enhancement: Tab completion for plugin names and commands
- Consider whether plugin commands need workspace context (may need -w parameter)
