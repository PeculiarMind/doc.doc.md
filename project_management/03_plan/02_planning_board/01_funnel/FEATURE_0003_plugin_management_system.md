# Plugin Management System

- **ID:** FEATURE_0003
- **Priority:** High
- **Type:** Feature
- **Created at:** 2026-02-27
- **Created by:** Requirements Engineer
- **Status:** FUNNEL

## Overview

As a **user**, I want to **manage and extend doc.doc.md functionality through plugins** so that I can **customize document processing to my specific needs**.

This feature implements the complete plugin lifecycle, including discovery, installation, activation/deactivation, listing, and visual tree display. It establishes the plugin architecture foundation using JSON descriptors and shell command invocation.

## User Value

- Extend document processing without modifying core code
- Install new plugins easily
- Control which plugins are active
- See plugin dependencies and status clearly
- Use language-agnostic plugins (bash, python, any executable)

## Scope

### In Scope
- Plugin descriptor format (JSON-based per ADR-003)
- Plugin discovery and loading mechanism
- Plugin lifecycle commands:
  - `list plugins` (all, active, inactive)
  - `activate --plugin <name>`
  - `deactivate --plugin <name>`
  - `install --plugin <name>`
  - `installed --plugin <name>`
  - `tree` (visual plugin tree with dependencies)
- Plugin metadata handling (name, version, description, dependencies)
- Plugin state persistence (active/inactive)
- Plugin dependency resolution
- Plugin execution interface
- Two reference plugins: `file` and `stat`

### Out of Scope
- Plugin sandboxing (planned for v0.3.0)
- Plugin signing/verification (planned for v0.5.0)
- Plugin repository/marketplace
- Complex dependency versioning

## Acceptance Criteria

- [ ] Plugin descriptors use JSON format with required fields (name, version, command)
- [ ] Plugins discovered from `doc.doc.md/plugins/` directory
- [ ] `doc.doc.sh list plugins` shows all plugins with activation status
- [ ] `doc.doc.sh list plugins active` shows only active plugins
- [ ] `doc.doc.sh list plugins inactive` shows only inactive plugins
- [ ] `doc.doc.sh activate --plugin <name>` activates a plugin
- [ ] `doc.doc.sh deactivate --plugin <name>` deactivates a plugin
- [ ] `doc.doc.sh install --plugin <name>` runs plugin install script
- [ ] `doc.doc.sh installed --plugin <name>` checks installation status
- [ ] `doc.doc.sh tree` displays plugin tree with dependencies
- [ ] Tree view shows active plugins in green, inactive in red
- [ ] Plugin activation status persists across invocations
- [ ] Attempting to activate non-existent plugin shows clear error
- [ ] Attempting to activate already-active plugin handled gracefully
- [ ] Plugin dependencies declared in descriptor
- [ ] Reference plugins (`file`, `stat`) functional and documented
- [ ] Plugin interface clearly documented for developers

## Technical Details

### Architecture Alignment
- **Building Block**: Plugin System (plugins.sh), Plugin Interface
- **ADR References**: ADR-003 (JSON-Based Plugin Descriptors)
- **Quality Goals**: Flexibility (QS-F03, QS-F04), Maintainability (QS-M03)
- **Crosscutting Concepts**: Plugin Architecture

### Plugin Descriptor Format (JSON)
```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "Plugin description",
  "command": "./main.sh",
  "dependencies": ["other-plugin"],
  "author": "Author Name",
  "license": "MIT"
}
```

### Plugin Directory Structure
```
plugins/
├── file/
│   ├── descriptor.json
│   ├── install.sh
│   ├── installed.sh
│   └── main.sh
└── stat/
    ├── descriptor.json
    ├── install.sh
    ├── installed.sh
    └── main.sh
```

### Implementation Approach
- JSON descriptor parsing using `jq` command
- Plugin state stored in `~/.config/doc.doc.md/plugins.state` or `.doc.doc.md/plugins.state`
- Plugin loading at runtime from active list
- Tree visualization using ANSI colors and box-drawing characters
- Dependency resolution using topological sort

### Complexity
**Large (L)**: JSON parsing, state management, dependency resolution, multiple commands

## Dependencies

### Blocked By
- FEATURE_0001 (Core CLI Framework) - requires CLI infrastructure

### Blocks
None (optional enhancement to document processing)

### Integrates With
- FEATURE_0002 (Document Processing Engine) - plugins can extend processing

## Related Requirements

### Functional Requirements
- REQ_0021: List Plugins Command
  - All list variations (all, active, inactive)
  
- REQ_0024: Activate Plugin Command
  - Activation with validation
  
- REQ_0025: Deactivate Plugin Command
  - Deactivation with validation
  
- REQ_0026: Install Plugin Command
  - Installation workflow
  
- REQ_0027: Check Plugin Installation Command
  - Installation status checking
  
- REQ_0028: Plugin Tree View Command
  - Visual tree with colors and dependencies

### Security Requirements
- REQ_SEC_003: Plugin Descriptor Validation
  - JSON schema validation
  - Path validation for command field
  
- REQ_SEC_007: Plugin Security Documentation
  - User warnings for third-party plugins
  - Developer security guidelines
  
- REQ_SEC_008: Environment Variable Sanitization
  - Clean environment for plugin execution

## Related Links

- Architecture Vision: [05_building_block_view](../../../02_project_vision/03_architecture_vision/05_building_block_view/05_building_block_view.md)
- Architecture Vision: [06_runtime_view](../../../02_project_vision/03_architecture_vision/06_runtime_view/06_runtime_view.md)
- Architecture Vision: [08_concepts](../../../02_project_vision/03_architecture_vision/08_concepts/08_concepts.md)
- ADR: [ADR-003](../../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md)
- Requirements: [REQ_0021](../../../02_project_vision/02_requirements/01_funnel/REQ_0021_list-plugins.md)
- Requirements: [REQ_0024](../../../02_project_vision/02_requirements/01_funnel/REQ_0024_activate-plugin.md)
- Requirements: [REQ_0025](../../../02_project_vision/02_requirements/01_funnel/REQ_0025_deactivate-plugin.md)
- Requirements: [REQ_0026](../../../02_project_vision/02_requirements/01_funnel/REQ_0026_install-plugin.md)
- Requirements: [REQ_0027](../../../02_project_vision/02_requirements/01_funnel/REQ_0027_check-plugin-installed.md)
- Requirements: [REQ_0028](../../../02_project_vision/02_requirements/01_funnel/REQ_0028_plugin-tree-view.md)
- Requirements: [REQ_SEC_003](../../../02_project_vision/02_requirements/01_funnel/REQ_SEC_003_plugin_descriptor_validation.md)
- Requirements: [REQ_SEC_007](../../../02_project_vision/02_requirements/01_funnel/REQ_SEC_007_plugin_security_documentation.md)
- Requirements: [REQ_SEC_008](../../../02_project_vision/02_requirements/01_funnel/REQ_SEC_008_environment_variable_sanitization.md)
- Security Concept: [01_security_concept](../../../02_project_vision/04_security_concept/01_security_concept.md)

## Implementation Notes

### Component Structure
```
doc.doc.md/
├── components/
│   └── plugins.sh          # Plugin management
└── plugins/
    ├── file/               # Reference plugin 1
    └── stat/               # Reference plugin 2
```

### Plugin Interface Contract
Each plugin must provide:
- `descriptor.json`: Plugin metadata
- `install.sh`: Installation script (optional)
- `installed.sh`: Check if dependencies installed
- Command executable specified in descriptor

### Plugin Lifecycle States
1. **Discovered**: Plugin in plugins/ directory with valid descriptor
2. **Installed**: Plugin dependencies installed (install.sh succeeded)
3. **Active**: Plugin enabled in configuration
4. **Inactive**: Plugin disabled but still installed

### Quality Checklist
- [ ] JSON descriptors validate against schema
- [ ] Invalid descriptors rejected with clear errors
- [ ] Plugin state persists correctly
- [ ] Dependency resolution handles cycles gracefully
- [ ] Tree view renders correctly with colors
- [ ] Both reference plugins (`file`, `stat`) work
- [ ] Plugin execution isolated with clean environment
- [ ] Security validation per REQ_SEC_003 and REQ_SEC_008
- [ ] User documentation warns about untrusted plugins
- [ ] Developer guide shows how to create secure plugins
