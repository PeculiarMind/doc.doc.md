# Deactivate Plugin Command

- **ID:** FEATURE_0013
- **Priority:** High
- **Type:** Feature
- **Created at:** 2026-03-04
- **Created by:** Product Owner
- **Status:** BACKLOG
- **Assigned to:** developer.agent

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Dependencies](#dependencies)
5. [Related Links](#related-links)

## Overview

Implement the `doc.doc.sh deactivate --plugin <plugin_name>` command that marks a specified plugin as inactive in its `descriptor.json`, removing it from document processing without uninstalling it.

**Command signature:**
```
doc.doc.sh deactivate --plugin <plugin_name>
doc.doc.sh deactivate -p <plugin_name>
```

**Current state:** No `deactivate` command exists. Plugins can only be disabled by manually editing `descriptor.json`.

**Business Value:**
- Allows users to disable plugins they do not need without losing the installation, enabling quick re-activation later
- Enables scripted environment configuration (e.g., disable heavy plugins for lightweight runs)
- Symmetric and consistent with the `activate` command (FEATURE_0012)

**What this delivers:**
- `doc.doc.sh deactivate --plugin <name>` — sets `"active": false` in the plugin's `descriptor.json`
- Clear confirmation output on success (e.g., `plugin 'stat' deactivated`)
- Graceful handling if the plugin is already inactive (informational message, exit 0)
- Clear error if the plugin does not exist (exit non-zero)
- Updated `usage()` help text

## Acceptance Criteria

### Happy Path

- [ ] `doc.doc.sh deactivate --plugin <name>` exits with code 0 when the plugin exists and was active
- [ ] The `active` field in the plugin's `descriptor.json` is set to `false` after the command runs
- [ ] A confirmation message is printed, e.g. `plugin '<name>' deactivated`
- [ ] Short form `-p` is accepted as equivalent to `--plugin`

### Already Inactive

- [ ] If the plugin is already inactive, the command exits with code 0
- [ ] An informational message is printed indicating the plugin was already inactive (no error)

### Error Handling

- [ ] If the named plugin does not exist in `PLUGIN_DIR`, an error is printed to stderr and exit code is non-zero
- [ ] If `descriptor.json` cannot be written (permissions), an error is printed to stderr and exit code is non-zero
- [ ] Missing `--plugin` / `-p` argument prints usage error to stderr and exits with non-zero code

### Help / Usage

- [ ] `doc.doc.sh --help` output includes `deactivate --plugin <plugin_name>`
- [ ] `doc.doc.sh deactivate --help` output describes the command and its parameter

## Scope

**In scope:**
- Setting `"active": false` in `descriptor.json`
- Idempotent handling (already inactive → success)
- Error handling for unknown plugins and write failures
- Help/usage text updates

**Out of scope:**
- Uninstalling the plugin — deactivation only disables execution, does not remove installed dependencies
- Bulk deactivation of all plugins at once
- Cascading deactivation of dependent plugins

## Dependencies

- REQ_0025 (Deactivate Plugin) — defines command contract
- REQ_0003 (Plugin-Based Architecture) — plugin discovery and `descriptor.json` structure
- FEATURE_0012 (Activate Plugin) — symmetric command; implement together

## Related Links

- Requirements: [REQ_0025](../../../02_project_vision/02_requirements/03_accepted/REQ_0025_deactivate-plugin.md)
- Requirements: [REQ_0024](../../../02_project_vision/02_requirements/03_accepted/REQ_0024_activate-plugin.md)
- Project Goals: [project_goals.md](../../../02_project_vision/01_project_goals/project_goals.md)
