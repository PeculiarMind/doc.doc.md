# Feature: Plugin Results Aggregation and Workspace Integration

**ID**: feature_0048_plugin_results_aggregation  
**Status**: Done  
**Created**: 2026-02-13  
**Last Updated**: 2026-02-15
**Completed**: 2026-02-15

## Overview
Capture plugin outputs via Bash variables (using the `read -r` command pattern) and write them to document-specific JSON files in the workspace, where each analyzed document has a corresponding JSON file that accumulates results from all plugins that process that document.

## Description
The system implements a results aggregation layer where the doc.doc toolkit captures plugin outputs via Bash variables and writes them to the document-specific JSON file in the workspace. Plugins use the `read -r` command pattern to capture tool outputs and set Bash variables according to their `provides` declaration. The toolkit executes the plugin command, captures the Bash variables that were set during execution, validates the data, and writes it to the appropriate workspace JSON file. Each analyzed file has a corresponding JSON file in the workspace directory that accumulates results from all plugins that process that file.

**Plugin Output Mechanism**:
- Plugins declare output variables in the `provides` field of their descriptor
- Plugin `execute_commandline` uses `read -r variable_list < <(command)` pattern to capture tool output
- Example: `read -r file_size file_owner < <(stat -c '%s,%U' "${file_path_absolute}")`
- The plugin execution sets Bash variables (e.g., `file_size=2048`, `file_owner=user`)
- The toolkit captures these Bash variables after plugin execution completes
- The toolkit does NOT rely on plugins writing to files or stdout directly

**Toolkit Aggregation Process**:
- Toolkit executes plugin command in plugin's directory (optionally sandboxed with Bubblewrap)
- Toolkit captures Bash variables set by the plugin's `read -r` command
- Toolkit validates captured values against the plugin's `provides` schema
- Toolkit writes validated data to the document's corresponding JSON file in workspace
- Multiple plugins' outputs are merged into the same JSON file per document
- Each plugin's contribution is identifiable and can be updated independently

**Workspace JSON File Structure**:
- Each analyzed document has one corresponding JSON file in the workspace directory
- JSON filename typically based on document hash or path
- Structure: `{ "file_path": "...", "plugins_executed": [...], "field1": value1, ... }`
- Plugin-provided fields are merged at the root level or in structured sections
- Metadata tracks which plugins have executed and when

## Traceability
- **Primary**: [req_0062](../../01_vision/02_requirements/03_accepted/req_0062_plugin_results_aggregation.md) - Plugin Results Aggregation and Workspace Integration
- **Primary**: [req_0022](../../01_vision/02_requirements/03_accepted/req_0022_plugin_based_extensibility.md) - Plugin-based Extensibility (Bash variable interface)
- **Related**: [req_0025](../../01_vision/02_requirements/03_accepted/req_0025_incremental_analysis.md) - Incremental Analysis
- **Related**: [req_0059](../../01_vision/02_requirements/03_accepted/req_0059_workspace_recovery_and_rescan.md) - Workspace Recovery
- **Related**: [req_0064](../../01_vision/02_requirements/03_accepted/req_0064_comprehensive_error_handling_recovery.md) - Error Handling
- **Architecture**: [ADR-0010](../../01_vision/03_architecture/09_architecture_decisions/ADR_0010_plugin_toolkit_interface_architecture.md) - Plugin-Toolkit Interface Architecture
- **Architecture**: [Concept 08_0001](../../01_vision/03_architecture/08_concepts/08_0001_plugin_concept.md) - Plugin Concept
- **Architecture**: [Concept 08_0017](../../01_vision/03_architecture/08_concepts/08_0017_plugin_results_aggregation_system.md) - Plugin Results Aggregation System
- **Architecture**: [Runtime View](../../01_vision/03_architecture/06_runtime_view/06_runtime_view.md) - Plugin Execution Scenario

## Implementation Notes

### Pre-existing Implementation
This feature was already implemented in the plugin execution engine:
- `orchestrate_plugins()` in `plugin_executor.sh` - orchestrates plugin execution per file
- `execute_plugin()` in `plugin_executor.sh` - executes individual plugins
- `merge_plugin_data()` in `workspace.sh` - merges plugin results into workspace JSON
- `save_workspace()` in `workspace.sh` - atomically saves workspace data

### MVP Enhancement (2026-02-15)
Enhanced `orchestrate_plugins()` to also store file path metadata:
- `file_path` - absolute path
- `filepath_relative` - relative to source directory
- `source_directory` - root scan directory
- `filename` - base filename

This enables sidecar file naming in the report generator.

## Acceptance Criteria
- [x] Each analyzed document has one corresponding JSON file in the workspace directory
- [x] Plugins use `read -r` command pattern to capture tool outputs into Bash variables
- [x] Plugins declare output variables in their `provides` field
- [x] Toolkit executes plugin command and captures Bash variables set during execution
- [x] Toolkit validates captured variables against plugin's `provides` schema
- [x] Toolkit writes validated plugin outputs to the document's corresponding JSON file in workspace
- [x] Plugins do not write directly to JSON files; toolkit handles all JSON writes
- [x] Each plugin's contribution is identifiable within the JSON file
- [x] Toolkit accumulates results from multiple plugins in the same JSON file
- [x] System maintains consistent data formats across all workspace JSON files
- [x] System handles plugin output conflicts using defined rules
- [x] System enables incremental updates (only changed data processed)
- [x] System maintains workspace validity during partial failures
- [ ] Documentation explains Bash variable capture mechanism, aggregation logic, JSON file structure, and conflict resolution

## Dependencies
- Plugin execution engine (feature_0009) ✓
- Workspace management (feature_0007) ✓
- Error handling framework (req_0064) ✓

## Notes
- Created by Requirements Engineer Agent from accepted requirement req_0062
- Priority: High
- Type: Core Feature
- **Key Pattern**: Plugins use `read -r var1 var2 ... < <(command)` to capture outputs into Bash variables; toolkit captures these variables and writes to workspace JSON
- **Example**: `read -r file_size file_owner < <(stat -c '%s,%U' "${file_path_absolute}")` sets `file_size` and `file_owner` variables that toolkit captures
- **Separation of Concerns**: Plugins focus on tool invocation and output parsing; toolkit handles all workspace JSON file operations
- Aligns with ADR-0010 Sandboxed Command Template Architecture
- Implements the variable-based interface pattern from req_0022
- Already implemented, verified and enhanced during MVP implementation 2026-02-15
