# Activate Plugin Command

- **ID:** FEATURE_0012
- **Priority:** High
- **Type:** Feature
- **Created at:** 2026-03-04
- **Created by:** Product Owner
- **Status:** Done
- **Assigned to:** developer.agent

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Dependencies](#dependencies)
5. [Related Links](#related-links)

## Overview

Implement the `doc.doc.sh activate --plugin <plugin_name>` command that marks a specified plugin as active in its `descriptor.json`, making it available for use in document processing.

**Command signature:**
```
doc.doc.sh activate --plugin <plugin_name>
doc.doc.sh activate -p <plugin_name>
```

**Current state:** No `activate` command exists. Plugins can only be enabled by manually editing `descriptor.json`.

**Business Value:**
- Gives users a safe, CLI-driven way to enable plugins without editing JSON files manually
- Enables scripted setup workflows (e.g., activate a specific plugin for a given use case)
- Consistent with the project's goal of an intuitive, self-managing CLI

**What this delivers:**
- `doc.doc.sh activate --plugin <name>` — sets `"active": true` in the plugin's `descriptor.json`
- Clear confirmation output on success (e.g., `plugin 'stat' activated`)
- Graceful handling if the plugin is already active (informational message, exit 0)
- Clear error if the plugin does not exist (exit non-zero)
- Updated `usage()` help text

## Acceptance Criteria

### Happy Path

- [ ] `doc.doc.sh activate --plugin <name>` exits with code 0 when the plugin exists and was inactive
- [ ] The `active` field in the plugin's `descriptor.json` is set to `true` after the command runs
- [ ] A confirmation message is printed, e.g. `plugin '<name>' activated`
- [ ] Short form `-p` is accepted as equivalent to `--plugin`

### Already Active

- [ ] If the plugin is already active, the command exits with code 0
- [ ] An informational message is printed indicating the plugin was already active (no error)

### Error Handling

- [ ] If the named plugin does not exist in `PLUGIN_DIR`, an error is printed to stderr and exit code is non-zero
- [ ] If `descriptor.json` cannot be written (permissions), an error is printed to stderr and exit code is non-zero
- [ ] Missing `--plugin` / `-p` argument prints usage error to stderr and exits with non-zero code

### Help / Usage

- [ ] `doc.doc.sh --help` output includes `activate --plugin <plugin_name>`
- [ ] `doc.doc.sh activate --help` output describes the command and its parameter

## Scope

**In scope:**
- Setting `"active": true` in `descriptor.json`
- Idempotent handling (already active → success)
- Error handling for unknown plugins and write failures
- Help/usage text updates

**Out of scope:**
- Installing the plugin before activation — use `install --plugin` first
- Bulk activation of all plugins at once
- Dependency resolution during activation

## Dependencies

- REQ_0024 (Activate Plugin) — defines command contract
- REQ_0003 (Plugin-Based Architecture) — plugin discovery and `descriptor.json` structure
- REQ_0025 (Deactivate Plugin) — symmetric command; implement together

## Related Links

- Requirements: [REQ_0024](../../../02_project_vision/02_requirements/03_accepted/REQ_0024_activate-plugin.md)
- Requirements: [REQ_0025](../../../02_project_vision/02_requirements/03_accepted/REQ_0025_deactivate-plugin.md)
- Project Goals: [project_goals.md](../../../02_project_vision/01_project_goals/project_goals.md)
