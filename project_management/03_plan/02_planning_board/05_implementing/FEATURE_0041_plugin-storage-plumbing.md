# Plugin Storage Plumbing (pluginStorage attribute)

- **ID:** FEATURE_0041
- **Priority:** HIGH
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

Implement the `pluginStorage` attribute plumbing required by REQ_0029. Before invoking a plugin's `process` command, `doc.doc.md` must:

1. Resolve the per-plugin storage path: `.doc.doc.md/<pluginname>/` under the output directory
2. Create the directory if it does not already exist
3. Inject the resolved absolute path as a `pluginStorage` field in the JSON passed to the plugin on stdin

This is a core infrastructure change in `plugin_execution.sh` (`run_plugin` / `process_file`) and `doc.doc.sh` (output-dir propagation). Once in place it unblocks **FEATURE_0003** (CRM114 classification plugin) and any future stateful plugin that relies on `pluginStorage`.

**Business Value:**
- Unblocks FEATURE_0003 (CRM114 plugin) and any future stateful plugin
- Completes the accepted requirement REQ_0029
- Provides a standardised, decoupled storage abstraction for all plugins

## Acceptance Criteria

### Directory Creation
- [ ] For each plugin invocation, `doc.doc.md` resolves the storage path as `<output_dir>/.doc.doc.md/<pluginname>/`
- [ ] The storage directory is created (`mkdir -p`) before the plugin is invoked if it does not already exist
- [ ] The directory name starts with `.` (hidden)

### JSON Injection
- [ ] The resolved absolute path is added as `pluginStorage` to the JSON input object before it is piped to the plugin
- [ ] The path is an absolute, canonical path (resolved via `readlink -f` or equivalent)
- [ ] If `--echo` mode is active (no output directory), `pluginStorage` is omitted from the JSON input (no state directory created)

### Signature Compatibility
- [ ] `run_plugin` in `plugin_execution.sh` accepts the output directory path as an additional argument and injects `pluginStorage` into the JSON
- [ ] `process_file` passes the output directory through to `run_plugin` for each plugin in the chain
- [ ] The call sites in `doc.doc.sh` pass `_PROC_CANONICAL_OUT` to `process_file`
- [ ] Existing plugins that do not use `pluginStorage` are unaffected (field is present but ignored)

### Security
- [ ] The `pluginStorage` path is validated to be under the canonical output directory (no path traversal via `..`)
- [ ] No world-writable permissions are set on created directories (inherits umask)

### Tests
- [ ] `tests/test_feature_0041.sh` verifies that the `.doc.doc.md/<pluginname>/` directory is created during `process`
- [ ] Test verifies that a plugin receives `pluginStorage` in its JSON input
- [ ] Test verifies that `--echo` mode does not create a storage directory
- [ ] All existing tests continue to pass

## Scope

### In Scope
- Creating `.doc.doc.md/<pluginname>/` under the output directory before plugin invocation
- Injecting `pluginStorage` (absolute canonical path) into plugin JSON input
- Updating `run_plugin`, `process_file` in `plugin_execution.sh`
- Updating call sites in `doc.doc.sh` to pass the output directory
- Omitting `pluginStorage` in `--echo` mode

### Out of Scope
- Cleanup or lifecycle management of storage directories (no purge/reset command)
- Per-run isolation of storage directories
- Central registry of storage paths
- Any plugin-level use of `pluginStorage` (that is each plugin's own responsibility)

## Technical Requirements

- Storage path pattern: `<canonical_output_dir>/.doc.doc.md/<pluginname>/`
- Path resolved with `readlink -f` before injection to ensure absoluteness
- `mkdir -p` used for creation (idempotent, no error if already exists)
- `run_plugin` signature extended: `run_plugin <name> <file_path> <plugin_base_dir> <output_dir> [context_json]`
- `pluginStorage` injected via `jq` into the accumulated JSON before piping to the plugin script
- Must pass `shellcheck` and existing test suite

## Dependencies

### Blocking Items
- None — REQ_0029 is already accepted; implementation can proceed immediately

### Unblocks
- **FEATURE_0003**: CRM114 Text Classification Plugin (depends on `pluginStorage` being passed to plugins)

### Related Requirements
- **REQ_0029**: Plugin State Storage — the requirement this feature implements
- **REQ_0003**: Plugin-Based Architecture
- **REQ_0009**: Process Command
- **REQ_SEC_005**: Path Traversal Prevention

## Related Links

### Requirements
- [REQ_0029: Plugin State Storage](../../../02_project_vision/02_requirements/03_accepted/REQ_0029_plugin-state-storage.md)
- [REQ_0003: Plugin-Based Architecture](../../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-system.md)
- [REQ_SEC_005: Path Traversal Prevention](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md)

### Source Files to Modify
- [plugin_execution.sh](../../../../doc.doc.md/components/plugin_execution.sh)
- [doc.doc.sh](../../../../doc.doc.sh)

### Blocked Feature
- [FEATURE_0003: CRM114 Text Classification Plugin](FEATURE_0003_crm114_text_classification_plugin.md)
