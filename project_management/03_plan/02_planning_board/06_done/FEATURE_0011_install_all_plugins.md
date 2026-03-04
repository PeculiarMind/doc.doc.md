# Install All Plugins Command

- **ID:** FEATURE_0011
- **Priority:** Medium
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

Implement the `doc.doc.sh install plugins --all` command that iterates over all discovered plugins, checks whether each one is already installed (via the plugin's `installed.sh` script), and runs the plugin's `install.sh` script only for those that are not yet installed.

**Command signature:**
```
doc.doc.sh install plugins --all
```

**Current state:** No bulk install command exists. Users must manually invoke each plugin's `install.sh` individually, with no automated check to skip already-installed plugins.

**Business Value:**
- Enables a single-command setup experience — ideal for fresh environments and CI/CD pipelines
- Prevents redundant re-installations by checking `installed.sh` before invoking `install.sh`
- Reduces user friction when onboarding to a new machine or container
- Consistent with the project goal of a self-managing, user-friendly CLI tool

**What this delivers:**
- `doc.doc.sh install plugins --all` — iterates all plugins in `PLUGIN_DIR` and installs any that are not yet installed
- For each plugin: run `installed.sh`; if exit code is non-zero (not installed), run `install.sh`
- Per-plugin status output (e.g. `stat: already installed`, `ocrmypdf: installing...`, `ocrmypdf: installed`)
- Failed installations are reported with a clear error message; the command continues with remaining plugins
- Updated `usage()` help text covering the new sub-command

## Acceptance Criteria

### Happy Path

- [ ] `doc.doc.sh install plugins --all` exits with code 0 when all plugins are already installed
- [ ] `doc.doc.sh install plugins --all` exits with code 0 when all plugins are successfully installed
- [ ] For each plugin, `installed.sh` is executed before `install.sh`
- [ ] If `installed.sh` exits with code 0, `install.sh` is **not** invoked for that plugin
- [ ] If `installed.sh` exits with a non-zero code, `install.sh` is invoked for that plugin
- [ ] Output clearly indicates per-plugin status: already installed or newly installed

### Partial Failure

- [ ] If `install.sh` fails for one plugin, the command continues processing remaining plugins
- [ ] Failed plugin installations are reported to stderr with the plugin name and error detail
- [ ] Final exit code is non-zero if at least one plugin installation failed

### Discovery

- [ ] All plugins found in `PLUGIN_DIR` with a valid `descriptor.json` are considered
- [ ] Plugins without an `install.sh` are skipped with an informational message
- [ ] Plugins without an `installed.sh` are treated as not installed (always attempt install)

### Help / Usage

- [ ] `doc.doc.sh --help` output includes `install plugins --all`
- [ ] `doc.doc.sh install --help` output includes `plugins --all` with a description

## Scope

**In scope:**
- Bulk plugin installation via `install plugins --all`
- Per-plugin install-check using `installed.sh`
- Per-plugin install execution using `install.sh`
- Console output per plugin (status lines + errors)
- Help/usage text updates

**Out of scope:**
- Installing a single named plugin (`doc.doc.sh install --plugin <name>`) — covered by REQ_0026 as a separate feature
- Plugin activation/deactivation after installation

## Dependencies

- REQ_0026 (Install Plugin) — defines `install.sh` contract
- REQ_0027 (Check Plugin Installation) — defines `installed.sh` contract
- REQ_0003 (Plugin-Based Architecture) — plugin discovery mechanism

## Related Links

- Requirements: [REQ_0026](../../../02_project_vision/02_requirements/03_accepted/REQ_0026_install-plugin.md)
- Requirements: [REQ_0027](../../../02_project_vision/02_requirements/03_accepted/REQ_0027_check-plugin-installed.md)
- Project Goals: [project_goals.md](../../../02_project_vision/01_project_goals/project_goals.md)
