# Install Single Plugin Command

- **ID:** FEATURE_0014
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

Implement the `doc.doc.sh install --plugin <plugin_name>` command that installs a specified plugin by invoking its `install.sh` script, first checking via `installed.sh` whether installation is actually needed.

**Command signature:**
```
doc.doc.sh install --plugin <plugin_name>
doc.doc.sh install -p <plugin_name>
```

**Current state:** No `install --plugin` command exists. Plugin installation requires users to locate and manually run each plugin's `install.sh` script.

**Business Value:**
- Provides a unified, CLI-driven way to install individual plugins on demand
- Prevents unnecessary re-installation by checking `installed.sh` before running `install.sh`
- Required prerequisite for the `activate` workflow: install → activate → use

**What this delivers:**
- `doc.doc.sh install --plugin <name>` — runs the plugin's `install.sh` if `installed.sh` reports not installed
- Output indicates whether the plugin was already installed or was freshly installed
- Clear error on failure (installation script exits non-zero)
- Updated `usage()` help text

## Acceptance Criteria

### Happy Path

- [ ] `doc.doc.sh install --plugin <name>` exits with code 0 when the plugin is not yet installed and `install.sh` succeeds
- [ ] `installed.sh` is invoked first; if it exits 0 (already installed), `install.sh` is **not** run
- [ ] If the plugin is already installed, command exits with code 0 and prints an informational message
- [ ] Installation success is confirmed with a message (e.g., `plugin '<name>' installed`)
- [ ] Short form `-p` is accepted as equivalent to `--plugin`

### Error Handling

- [ ] If the named plugin does not exist in `PLUGIN_DIR`, an error is printed to stderr and exit code is non-zero
- [ ] If `install.sh` exits with a non-zero code, the error is reported to stderr and exit code is non-zero
- [ ] If the plugin has no `install.sh`, an informational message is printed and exit code is 0 (nothing to install)
- [ ] Missing `--plugin` / `-p` argument prints usage error to stderr and exits with non-zero code

### Help / Usage

- [ ] `doc.doc.sh --help` output includes `install --plugin <plugin_name>`
- [ ] `doc.doc.sh install --help` documents both `--plugin <name>` and `plugins --all` variants

## Scope

**In scope:**
- Single named plugin installation via `install --plugin <name>`
- Pre-check via `installed.sh` to avoid redundant re-installs
- Clear per-plugin status output
- Help/usage text updates (consolidating with FEATURE_0011 `install plugins --all`)

**Out of scope:**
- Bulk installation — covered by FEATURE_0011 (`install plugins --all`)
- Plugin activation after installation

## Dependencies

- REQ_0026 (Install Plugin) — defines command contract and `install.sh` interface
- REQ_0027 (Check Plugin Installation) — defines `installed.sh` interface
- FEATURE_0011 (Install All Plugins) — related bulk variant; help text must be consistent

## Related Links

- Requirements: [REQ_0026](../../../02_project_vision/02_requirements/03_accepted/REQ_0026_install-plugin.md)
- Requirements: [REQ_0027](../../../02_project_vision/02_requirements/03_accepted/REQ_0027_check-plugin-installed.md)
- Related Feature: [FEATURE_0011](FEATURE_0011_install_all_plugins.md)
- Project Goals: [project_goals.md](../../../02_project_vision/01_project_goals/project_goals.md)
