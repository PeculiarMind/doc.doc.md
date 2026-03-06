# Extract UI Module

- **ID:** FEATURE_0020
- **Priority:** HIGH
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

Extract all user-interaction concerns — argument parsing, help output, and logging/progress output — from `doc.doc.sh` into a cohesive `components/ui.sh` module. After this change `doc.doc.sh` delegates every user-facing interaction to `ui.sh` and contains no help or log formatting code itself.

**Business Value:**
- Aligns the codebase with the architecture vision's UI building block, making responsibilities explicit and testable.
- Reduces cognitive load when reading `doc.doc.sh`: it will contain only routing, not presentation.
- Provides a single point of change for CLI help text, progress messages, and log formatting.

**What this delivers:**
- `components/ui.sh` encapsulating all argument parsing, `--help` output, and logging/progress functions currently inline in `doc.doc.sh` (and any existing `components/help.sh`, `components/logging.sh`).
- `doc.doc.sh` sources `ui.sh` and calls its public functions — no inline help or log code remains.
- Public interface of `ui.sh` documented in-file (function signatures + purpose comments).
- All existing CLI commands, options, and output formats preserved verbatim.

## Acceptance Criteria

- [x] `components/ui.sh` exists and is sourced by `doc.doc.sh`.
- [x] All `--help` / `-h` output is produced exclusively via `ui.sh`.
- [x] All progress and log messages (info, warning, error) are emitted exclusively via functions in `ui.sh`.
- [x] `doc.doc.sh` contains no inline help text or log-formatting code.
- [x] `ui.sh` declares a documented public interface (header comment listing exported functions and their signatures).
- [x] `doc.doc.sh --help` output is byte-for-byte identical to the output before this change.
- [x] All existing unit and integration tests pass without modification (`tests/test_doc_doc.sh`, `tests/test_docs_integration.sh`, and all feature/bug test scripts).
- [x] No regressions in any CLI command or option.

## Assessments

### Tester Assessment (tester.agent)
**Result:** PASS — 29/29 feature tests pass, 47/47 core tests pass, all subcommand help preserved.

### Architect Assessment (architect.agent)
**Result:** PASS — Aligns with Building Block View (UI block), REQ_0032, REQ_0036, REQ_0037. No critical architectural debt.

### Security Assessment (security.agent)
**Result:** PASS — No security vulnerabilities introduced. Pure presentation layer with proper shell quoting. Compliant with REQ_SEC_001 and REQ_SEC_005.

### License Assessment (license.agent)
**Result:** PASS — Pure internal refactoring, no new dependencies or third-party code. AGPL-3.0 compliant.

### Documentation Assessment (documentation.agent)
**Result:** PASS — README.md updated (components directory description). All documentation current.

## Dependencies

None — this work item is independent and can be implemented in parallel with FEATURE_0021 and FEATURE_0022.

## Related Links

- Architecture Vision (Building Block View): `project_management/02_project_vision/03_architecture_vision/05_building_block_view/05_building_block_view.md`
- Requirements:
  - [REQ_0032 — separate-ui-module](../../02_project_vision/02_requirements/03_accepted/REQ_0032_separate-ui-module.md)
  - [REQ_0036 — orchestration-isolation](../../02_project_vision/02_requirements/03_accepted/REQ_0036_orchestration-isolation.md)
  - [REQ_0037 — module-interface-contract](../../02_project_vision/02_requirements/03_accepted/REQ_0037_module-interface-contract.md)
- Blocked by: —
- Blocks: [FEATURE_0023 — Orchestration cleanup](FEATURE_0023_orchestration-cleanup.md)
