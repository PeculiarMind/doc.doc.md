# Split plugins.sh: Extract Plugin Execution Module

- **ID:** FEATURE_0022
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

Extract plugin command invocation, stdin/stdout JSON I/O wiring, exit-code classification (0 = success, 1 = plugin error, 2 = fatal), and output validation from `components/plugins.sh` into a dedicated `components/plugin_execution.sh` module. The resulting module contains no plugin discovery or activation state logic.

**Business Value:**
- Aligns the codebase with the architecture vision's Plugin Execution building block.
- Isolates the runtime execution contract (JSON in/out, exit codes) so it can be reasoned about, tested, and modified independently of plugin lifecycle management.
- Provides a clear boundary for future extension (e.g., parallel execution, timeout handling).

**What this delivers:**
- `components/plugin_execution.sh` owning: plugin command invocation, stdin JSON construction, stdout JSON parsing, exit-code classification (0/1/2), and output schema validation.
- No plugin discovery, descriptor loading, or activation state logic in `plugin_execution.sh`.
- Public interface documented in-file (header comment listing exported functions and signatures).
- `doc.doc.sh` (or the future orchestration layer) sources `plugin_execution.sh` for the `process` command pipeline.
- The full plugin chain processes files correctly and produces identical output to before this change.

## Acceptance Criteria

- [x] `components/plugin_execution.sh` exists and is sourced appropriately.
- [x] `plugin_execution.sh` contains plugin invocation, JSON I/O pipeline, and exit-code classification (0/1/2).
- [x] `plugin_execution.sh` contains **no** plugin discovery, descriptor loading, or activation state management logic.
- [x] `plugin_execution.sh` declares a documented public interface (header comment listing exported functions and signatures).
- [x] Exit codes 0, 1, and 2 are handled with the same semantics as before this change.
- [x] The `process` command processes a document collection correctly end-to-end.
- [x] `tests/test_doc_doc.sh` and `tests/test_docs_integration.sh` pass without modification.
- [x] Plugin filter/MIME gate tests pass (`tests/test_filter_mime.sh`, `tests/test_feature_0007.sh`).
- [x] All other existing tests continue to pass.

## Assessments

### Tester Assessment (tester.agent)
**Result:** PASS — 10/10 feature tests pass, all 22 non-ocrmypdf test suites pass (0 regressions).

### Architect Assessment (architect.agent)
**Result:** PASS — Clean separation of execution from management, aligns with Building Block View and REQ_0033/REQ_0034.

### Security Assessment (security.agent)
**Result:** PASS — No security vulnerabilities introduced. run_plugin() maintains same security properties. Proper shell quoting preserved.

### License Assessment (license.agent)
**Result:** PASS — Pure internal refactoring, no new dependencies or third-party code.

### Documentation Assessment (documentation.agent)
**Result:** PASS — plugins.sh now deprecated (code moved to dedicated modules). No README changes needed.

## Dependencies

None — this work item is independent and can be implemented in parallel with FEATURE_0020 and FEATURE_0021.

## Related Links

- Architecture Vision (Building Block View): `project_management/02_project_vision/03_architecture_vision/05_building_block_view/05_building_block_view.md`
- Requirements:
  - [REQ_0033 — separate-plugin-management-execution](../../02_project_vision/02_requirements/03_accepted/REQ_0033_separate-plugin-management-execution.md)
  - [REQ_0034 — cohesive-plugin-execution-module](../../02_project_vision/02_requirements/03_accepted/REQ_0034_cohesive-plugin-execution-module.md)
  - [REQ_0037 — module-interface-contract](../../02_project_vision/02_requirements/03_accepted/REQ_0037_module-interface-contract.md)
- Blocked by: —
- Blocks: [FEATURE_0023 — Orchestration cleanup](FEATURE_0023_orchestration-cleanup.md)
