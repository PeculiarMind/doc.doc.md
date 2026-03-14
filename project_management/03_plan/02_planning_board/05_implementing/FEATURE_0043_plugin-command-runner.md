# Plugin Command Runner (run command)

- **ID:** FEATURE_0043
- **Priority:** MEDIUM
- **Type:** Feature
- **Created at:** 2026-03-14
- **Created by:** Product Owner
- **Status:** IMPLEMENTING

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

Currently, plugin-specific commands (e.g. `train`, `learn`, `unlearn`, `listCategories`) can only be invoked by calling the plugin script directly. There is no first-class CLI entry point in `doc.doc.sh` for running arbitrary plugin commands.

This feature adds a `run` top-level command that lets users invoke any command declared in a plugin's `descriptor.json` directly from the CLI:

```
./doc.doc.sh run <pluginName> <commandName> [--plugin-storage <dir>] [--file <path>] [--category <name>] [-- key=value...]
./doc.doc.sh run --help
./doc.doc.sh run <pluginName> --help
```

The `run` command constructs the required JSON input from the provided flags and pipes it to the plugin's command script, streaming the JSON output back to stdout.

**Business Value:**
- Makes plugin-specific commands (train, learn, unlearn, listCategories, etc.) accessible without knowing internal script paths
- Enables scripted/batch workflows using plugin commands from shell scripts or CI pipelines
- Unblocks interactive use of FEATURE_0042 (crm114 model management) once implemented
- Provides a consistent, discoverable interface for all plugin commands

## Acceptance Criteria

### Invocation syntax
- [ ] `./doc.doc.sh run <pluginName> <commandName> [options]` invokes the script declared in `descriptor.json` under `commands.<commandName>.command`
- [ ] `<pluginName>` and `<commandName>` are positional arguments (not flags)
- [ ] If no arguments are given, or `--help` is passed, the `run` command prints top-level usage listing all plugins and exits 0
- [ ] `./doc.doc.sh run <pluginName> --help` prints the list of commands available for that plugin (names + descriptions from `descriptor.json`) and exits 0
- [ ] If `<pluginName>` is missing (and `--help` was not passed), an error is shown and exit code 1 is returned
- [ ] If `<commandName>` is missing (and `--help` was not passed), an error is shown and exit code 1 is returned
- [ ] If the plugin does not exist, an error is shown and exit code 1 is returned
- [ ] If the command is not declared in `descriptor.json`, an error is shown and exit code 1 is returned

### JSON input construction
- [ ] `--file <path>` maps to the `filePath` field in the JSON input
- [ ] `--plugin-storage <dir>` maps to the `pluginStorage` field in the JSON input
- [ ] `--category <name>` maps to the `category` field in the JSON input
- [ ] Additional `key=value` pairs after `--` are merged into the JSON input object
- [ ] If no input fields are provided, an empty JSON object `{}` is piped to the plugin script

### Output
- [ ] The plugin script's stdout is streamed directly to stdout
- [ ] The plugin script's stderr is streamed directly to stderr
- [ ] The exit code of `doc.doc.sh run` matches the exit code of the plugin script

### Security
- [ ] `<pluginName>` is validated against known plugin directories (no path traversal)
- [ ] `<commandName>` is validated against the plugin's `descriptor.json` (no arbitrary script execution)
- [ ] `--file` path is passed as-is in JSON; individual plugin scripts are responsible for their own path validation (REQ_SEC_005)
- [ ] `key=value` pairs after `--` are JSON-encoded safely via `jq` (no shell injection)

### Help and discoverability
- [ ] `./doc.doc.sh run --help` lists all plugins with their descriptions
- [ ] `./doc.doc.sh run <pluginName> --help` lists all commands of that plugin with descriptions from `descriptor.json`
- [ ] The main `./doc.doc.sh --help` lists `run` as an available command

### Tests
- [ ] `tests/test_feature_0043.sh` verifies basic invocation, plugin-level help, error cases, and JSON construction
- [ ] All existing tests continue to pass

## Scope

### In Scope
- New `run` top-level command in `doc.doc.sh`
- `ui_usage_run` help text in `ui.sh`
- Command parsing and JSON construction logic in `doc.doc.sh` or a new component
- TDD test suite `tests/test_feature_0043.sh`

### Out of Scope
- Changes to individual plugin scripts
- Interactive prompting (the `run` command is non-interactive; interactive commands like `train` handle their own interaction)
- Streaming large binary inputs

## Technical Requirements

- Validate plugin name against directory listing of `$PLUGIN_DIR`
- Validate command name against `jq` query on `descriptor.json`
- Resolve plugin script path from `descriptor.json`: `commands.<commandName>.command`
- `run --help`: iterate all plugin directories, read `name` and `description` from each `descriptor.json`, print as a table
- `run <pluginName> --help`: read `commands` from plugin's `descriptor.json`, print command names and descriptions
- Build JSON input via `jq -n` with provided flags
- Pipe JSON to plugin script, inherit stdin for interactive commands
- Use `log_error` for all error output (colored output consistency)

## Dependencies

### Blocking Items
None — `run` command can be implemented independently of FEATURE_0042

### Enables These Features
- **FEATURE_0042** (CRM114 model management) — `run` provides the CLI entry point for `train`, `learn`, `unlearn`, `listCategories`

### Related Requirements
- **REQ_0003**: Plugin-Based Architecture
- **REQ_SEC_001**: Input Validation and Sanitization
- **REQ_SEC_005**: Path Traversal Prevention

## Related Links

### Requirements
- [REQ_0003: Plugin-Based Architecture](../../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-system.md)
- [REQ_SEC_001: Input Validation and Sanitization](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_001_input_validation_sanitization.md)
- [REQ_SEC_005: Path Traversal Prevention](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md)

### Related Work Items
- [FEATURE_0042: CRM114 Model Management Commands](FEATURE_0042_crm114-model-management-commands.md)
