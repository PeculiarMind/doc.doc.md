# Requirement: Plugin State Storage

- **ID:** REQ_0029
- **State:** Accepted
- **Type:** Functional
- **Priority:** Medium
- **Created at:** 2026-03-02
- **Last Updated:** 2026-03-02

## Overview
Plugins shall be allowed to persist state in a dedicated hidden directory, with doc.doc.md providing the exact storage path to each plugin via a `pluginStorage` attribute.

## Description
Plugins may need to maintain state across invocations (e.g., caches, indexes, incremental processing data). The system shall create and manage a hidden directory `.doc.doc.md/<pluginname>/` below the output folder for this purpose. The exact path to this directory is passed to each plugin as the `pluginStorage` attribute at invocation time.

Plugins must not construct or assume any path themselves — they must exclusively use the `pluginStorage` value provided by doc.doc.md. This decouples the plugin implementation from the physical storage location and allows the system to change the storage strategy in the future (e.g., different base path, per-run isolation, or central registry) without requiring any changes to existing plugins.

## Motivation
Derived from [project_management/02_project_vision/01_project_goals/project_goals.md](../../01_project_goals/project_goals.md):
- The plugin architecture is designed to be modular and extensible without coupling plugins to internal implementation details.
- Providing an abstracted storage path via a well-defined attribute follows the same principle as other plugin interface attributes.

## Acceptance Criteria
- [ ] doc.doc.md creates `.doc.doc.md/<pluginname>/` directory under the output folder before invoking the plugin
- [ ] The resolved absolute path is passed to the plugin as a `pluginStorage` attribute
- [ ] Plugins receive and use only the `pluginStorage` attribute for state persistence (no hardcoded paths)
- [ ] The storage directory is hidden (prefixed with `.`)
- [ ] Changing the base storage location in doc.doc.md does not require changes to any plugin implementation
- [ ] If the storage directory does not yet exist, it is created automatically by doc.doc.md before plugin invocation

## Related Requirements
- REQ_0003 (Plugin-Based Architecture)
- REQ_0009 (Process Command)
- REQ_0013 (Directory Structure Mirroring)
