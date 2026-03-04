# Installed Plugin Check Command

- **ID:** FEATURE_0015
- **Priority:** Low
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

Implement the `doc.doc.sh installed --plugin <plugin_name>` command that reports whether a specified plugin is currently installed by delegating to the plugin's own `installed.sh` script.

**Command signature:**
```
doc.doc.sh installed --plugin <plugin_name>
doc.doc.sh installed -p <plugin_name>
```

**Current state:** No top-level `installed` command exists. The `installed.sh` check is used internally by `install --plugin` and `install plugins --all` but is not directly accessible from the CLI.

**Business Value:**
- Enables users and scripts to query plugin installation state without triggering installation
- Useful in CI/CD pipelines and setup scripts to conditionally branch on plugin availability
- Completes the plugin management surface: list → check installed → install → activate/deactivate

**What this delivers:**
- `doc.doc.sh installed --plugin <name>` — runs the plugin's `installed.sh` and reports the result
- Human-readable output: `plugin '<name>' is installed` / `plugin '<name>' is not installed`
- Exit code reflects installation state: 0 = installed, 1 = not installed
- Updated `usage()` help text

## Acceptance Criteria

### Happy Path

- [ ] `doc.doc.sh installed --plugin <name>` exits with code 0 when the plugin is installed
- [ ] Exit code is non-zero (1) when the plugin is not installed
- [ ] Output clearly states whether the plugin is installed or not
- [ ] Short form `-p` is accepted as equivalent to `--plugin`

### Edge Cases

- [ ] If the plugin has no `installed.sh`, the command exits with code 1 (treat as not installed) and prints an informational message
- [ ] Assessment is purely based on the `installed.sh` exit code — it does not modify any state

### Error Handling

- [ ] If the named plugin does not exist in `PLUGIN_DIR`, an error is printed to stderr and exit code is non-zero (distinct from "not installed")
- [ ] Missing `--plugin` / `-p` argument prints usage error to stderr and exits with non-zero code

### Help / Usage

- [ ] `doc.doc.sh --help` output includes `installed --plugin <plugin_name>`
- [ ] `doc.doc.sh installed --help` describes the command, its parameter, and the exit code semantics

## Scope

**In scope:**
- Single named plugin installation check via `installed --plugin <name>`
- Delegation to the plugin's `installed.sh`
- Exit code contract (0 = installed, 1 = not installed, other = error)
- Help/usage text updates

**Out of scope:**
- Bulk installation checks — use `install plugins --all` (FEATURE_0011) which checks all automatically

## Dependencies

- REQ_0027 (Check Plugin Installation) — defines command contract and `installed.sh` interface
- REQ_0026 (Install Plugin) — related install command uses the same `installed.sh` contract
- FEATURE_0014 (Install Single Plugin) — uses same `installed.sh` internally; implement together

## Related Links

- Requirements: [REQ_0027](../../../02_project_vision/02_requirements/03_accepted/REQ_0027_check-plugin-installed.md)
- Requirements: [REQ_0026](../../../02_project_vision/02_requirements/03_accepted/REQ_0026_install-plugin.md)
- Related Feature: [FEATURE_0014](FEATURE_0014_install_single_plugin.md)
- Project Goals: [project_goals.md](../../../02_project_vision/01_project_goals/project_goals.md)
