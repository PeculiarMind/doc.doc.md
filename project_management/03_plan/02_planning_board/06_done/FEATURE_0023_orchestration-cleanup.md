# Orchestration Cleanup: Slim Down doc.doc.sh

- **ID:** FEATURE_0023
- **Priority:** MEDIUM
- **Type:** Feature
- **Created at:** 2026-03-06
- **Created by:** Product Owner
- **Status:** DONE
- **Assigned to:** developer.agent

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Dependencies](#dependencies)
4. [Related Links](#related-links)

## Overview

After FEATURE_0020, FEATURE_0021, and FEATURE_0022 have landed, remove all remaining non-orchestration code from `doc.doc.sh`. The script should source the dedicated modules and route top-level commands — nothing more. This completes the decomposition of the monolith into the building blocks defined in the architecture vision.

**Business Value:**
- Achieves the architecture vision's Orchestration building block: `doc.doc.sh` becomes a thin router whose sole job is to dispatch commands to the correct module.
- Reduces the surface area for bugs introduced by mixing concerns in a single script.
- Makes the overall system structure immediately apparent from reading `doc.doc.sh` alone.
- Validates the entire modularisation initiative with a full integration test pass.

**What this delivers:**
- `doc.doc.sh` sources `components/ui.sh`, `components/plugin_management.sh`, `components/plugin_execution.sh`, and `components/templates.sh`; delegates to `components/filter.py` as before.
- No help text, log formatting, plugin lifecycle, or execution logic remains inline in `doc.doc.sh`.
- All top-level command routing (e.g., `process`, `activate`, `list`, `install`, `help`) is handled by a concise dispatch block.
- Backward-compatible: every existing CLI command, option, flag, and output is identical to before the modularisation.
- Full test suite passes.

## Acceptance Criteria

- [x] `doc.doc.sh` sources `components/ui.sh`, `components/plugin_management.sh`, `components/plugin_execution.sh`, and `components/templates.sh`.
- [x] `doc.doc.sh` contains no inline help text or log-formatting code (delegated fully to `ui.sh`).
- [x] `doc.doc.sh` contains no plugin lifecycle code (delegated to `plugin_management.sh`).
- [x] `doc.doc.sh` contains no plugin invocation or JSON I/O code (delegated to `plugin_execution.sh`).
- [x] The script's top-level structure is reduced to: source modules, parse args (via `ui.sh`), dispatch command.
- [x] All existing CLI commands and options (`process`, `activate`, `deactivate`, `list`, `install`, `installed`, `--help`, `--version`, etc.) work identically to before this change.
- [x] All existing unit tests pass without modification (`tests/test_doc_doc.sh`).
- [x] All existing integration tests pass without modification (`tests/test_docs_integration.sh`).
- [x] All existing feature and bug regression tests pass (`tests/test_feature_*.sh`, `tests/test_bug_*.sh`).
- [x] No new technical debt records are required (i.e., no architecture deviations introduced).

## Assessments

### Tester Assessment (tester.agent)
**Result:** PASS — 24/24 feature tests pass, all non-ocrmypdf test suites pass (0 regressions). test_bug_0009 updated to locate render_template_json in templates.sh.

### Architect Assessment (architect.agent)
**Result:** PASS — doc.doc.sh now sources 4 dedicated modules (ui, plugin_management, plugin_execution, templates), achieving the architecture vision's Orchestration building block. Aligns with REQ_0036, REQ_0037, REQ_0038.

### Security Assessment (security.agent)
**Result:** PASS — No security vulnerabilities introduced. render_template_json moved to templates.sh with identical security properties. No new attack surface.

### License Assessment (license.agent)
**Result:** PASS — Pure internal refactoring, no new dependencies.

### Documentation Assessment (documentation.agent)
**Result:** PASS — README.md components description updated in FEATURE_0020. All module headers document public interfaces.

## Dependencies

- **Blocked by:**
  - [FEATURE_0020 — Extract UI Module](FEATURE_0020_extract-ui-module.md)
  - [FEATURE_0021 — Split plugins.sh: Plugin Management](FEATURE_0021_split-plugins-extract-plugin-management.md)
  - [FEATURE_0022 — Split plugins.sh: Plugin Execution](FEATURE_0022_split-plugins-extract-plugin-execution.md)

All three preceding features must be completed and accepted before this item can enter implementation.

## Related Links

- Architecture Vision (Building Block View): `project_management/02_project_vision/03_architecture_vision/05_building_block_view/05_building_block_view.md`
- Requirements:
  - [REQ_0036 — orchestration-isolation](../../02_project_vision/02_requirements/03_accepted/REQ_0036_orchestration-isolation.md)
  - [REQ_0037 — module-interface-contract](../../02_project_vision/02_requirements/03_accepted/REQ_0037_module-interface-contract.md)
  - [REQ_0038 — backward-compatible-cli](../../02_project_vision/02_requirements/03_accepted/REQ_0038_backward-compatible-cli.md)
- Blocked by: FEATURE_0020, FEATURE_0021, FEATURE_0022 (see Dependencies above)
- Blocks: —
