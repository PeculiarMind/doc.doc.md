# Split plugins.sh: Extract Plugin Management Module

- **ID:** FEATURE_0021
- **Priority:** HIGH
- **Type:** Feature
- **Created at:** 2026-03-06
- **Created by:** Product Owner
- **Status:** FUNNEL

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Dependencies](#dependencies)
4. [Related Links](#related-links)

## Overview

Extract plugin discovery, `descriptor.json` parsing, installation-state checking, and activation/deactivation state management from `components/plugins.sh` into a dedicated `components/plugin_management.sh` module. The resulting module contains no plugin invocation or I/O logic.

**Business Value:**
- Aligns the codebase with the architecture vision's Plugin Management building block.
- Makes plugin lifecycle concerns (discovery, metadata, activation) independently understandable and testable.
- Reduces merge conflicts by separating management changes from execution changes.

**What this delivers:**
- `components/plugin_management.sh` owning: plugin discovery, `descriptor.json` loading, install-state checking (`installed.sh` delegation), and activate/deactivate/list state management.
- No plugin command invocation, stdin/stdout JSON I/O, or exit-code classification logic in `plugin_management.sh`.
- Public interface documented in-file (header comment listing exported functions and signatures).
- `doc.doc.sh` (or the future orchestration layer) sources `plugin_management.sh` for management commands.
- All management-oriented CLI commands (`activate`, `deactivate`, `list`, `install`, `installed`) continue to work correctly.

## Acceptance Criteria

- [ ] `components/plugin_management.sh` exists and is sourced appropriately.
- [ ] `plugin_management.sh` contains plugin discovery, descriptor loading, activation state management, and installation checks.
- [ ] `plugin_management.sh` contains **no** plugin invocation, JSON I/O pipeline, or exit-code classification logic.
- [ ] `plugin_management.sh` declares a documented public interface (header comment listing exported functions and signatures).
- [ ] `activate`, `deactivate`, `list`, `install`, and `installed` commands produce identical output to before this change.
- [ ] All existing plugin-management tests pass without modification (e.g., `tests/test_feature_0012.sh`, `tests/test_feature_0013.sh`, `tests/test_feature_0014.sh`, `tests/test_feature_0015.sh`).
- [ ] No regressions in plugin listing (`tests/test_list_commands.sh`, `tests/test_plugins.sh`).
- [ ] All other existing tests continue to pass.

## Dependencies

None — this work item is independent and can be implemented in parallel with FEATURE_0020 and FEATURE_0022.

## Related Links

- Architecture Vision (Building Block View): `project_management/02_project_vision/03_architecture_vision/05_building_block_view/05_building_block_view.md`
- Requirements:
  - [REQ_0033 — separate-plugin-management-execution](../../02_project_vision/02_requirements/03_accepted/REQ_0033_separate-plugin-management-execution.md)
  - [REQ_0035 — cohesive-plugin-management-module](../../02_project_vision/02_requirements/03_accepted/REQ_0035_cohesive-plugin-management-module.md)
  - [REQ_0037 — module-interface-contract](../../02_project_vision/02_requirements/03_accepted/REQ_0037_module-interface-contract.md)
- Blocked by: —
- Blocks: [FEATURE_0023 — Orchestration cleanup](FEATURE_0023_orchestration-cleanup.md)
