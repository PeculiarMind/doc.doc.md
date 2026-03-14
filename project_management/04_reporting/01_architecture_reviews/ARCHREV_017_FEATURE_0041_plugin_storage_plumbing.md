# Architecture Review: FEATURE_0041 Plugin Storage Plumbing

- **ID:** ARCHREV_017
- **Created at:** 2026-03-14
- **Created by:** architect.agent
- **Work Item:** [FEATURE_0041: Plugin Storage Plumbing](../../03_plan/02_planning_board/05_implementing/FEATURE_0041_plugin-storage-plumbing.md)
- **Status:** Compliant

## Table of Contents
1. [Reviewed Scope](#reviewed-scope)
2. [Architecture Vision Reference](#architecture-vision-reference)
3. [Compliance Assessment](#compliance-assessment)
4. [Deviations Found](#deviations-found)
5. [Recommendations](#recommendations)
6. [Conclusion](#conclusion)

## Reviewed Scope

| File | Change Purpose |
|------|---------------|
| `doc.doc.md/components/plugin_execution.sh` | `run_plugin` signature extended with `output_dir` parameter; `pluginStorage` injection via `jq`; `mkdir -p` for storage directory creation |
| `doc.doc.md/components/plugin_execution.sh` | `process_file` accepts and propagates `output_dir` to `run_plugin` for each plugin in the chain |
| `doc.doc.sh` | Passes `_PROC_CANONICAL_OUT` to `process_file`; `--echo` mode omits output directory |
| `tests/test_feature_0041.sh` | 14 tests covering directory creation, JSON injection, echo-mode bypass, path canonicalization, and security containment |

## Architecture Vision Reference

- **ADR-001:** [Mixed Bash/Python Implementation](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_001_mixed_bash_python_implementation.md) — orchestration and plugin execution remain in Bash
- **ADR-003:** [JSON Plugin Descriptors](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md) — JSON I/O extended with `pluginStorage` field
- **ADR-004:** [Plugin Exit Code Strategy](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md) — exit code contract unchanged
- **REQ_0029:** [Plugin State Storage](../../02_project_vision/02_requirements/03_accepted/REQ_0029_plugin-state-storage.md) — the requirement this feature implements
- **REQ_SEC_005:** [Path Traversal Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md) — path canonicalization and containment validation

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| ADR-001: Mixed Bash/Python Implementation | ✅ Compliant | All changes are in Bash (`plugin_execution.sh`, `doc.doc.sh`); no new Python code introduced |
| ADR-003: JSON Plugin Descriptors / I/O | ✅ Compliant | `pluginStorage` field injected into JSON stdin via `jq`; JSON output pipeline unchanged; existing plugins that do not consume the field are unaffected |
| ADR-004: Plugin Exit Code Strategy | ✅ Compliant | Exit code contract (0/65/1) unchanged; `run_plugin` propagates plugin exit codes as before |
| REQ_0029: Plugin State Storage | ✅ Compliant | Storage path `<output_dir>/.doc.doc.md/<pluginname>/` resolved and created; absolute canonical path injected as `pluginStorage`; `--echo` mode omits storage |
| REQ_SEC_005: Path Traversal Prevention | ✅ Compliant | `readlink -f` canonicalization applied; storage path validated to remain under canonical output directory; no `..` segments possible in resolved path |
| Storage Path Pattern | ✅ Compliant | Hidden directory (`.doc.doc.md/`) follows existing convention; per-plugin subdirectory provides namespace isolation |
| Signature Compatibility | ✅ Compliant | `run_plugin` extended with positional `output_dir` parameter; `process_file` propagates it; call sites in `doc.doc.sh` updated; no breaking changes to other callers |
| Idempotent Directory Creation | ✅ Compliant | `mkdir -p` is idempotent — no error on existing directories, no race conditions |

## Deviations Found

None.

All changes follow established architecture patterns. The `run_plugin` signature extension is backward-compatible — the new `output_dir` parameter is positional and all call sites have been updated. The `pluginStorage` JSON injection is additive and does not alter the existing JSON structure consumed by plugins.

## Recommendations

- As more stateful plugins are introduced (e.g., FEATURE_0003 CRM114), consider documenting the `pluginStorage` contract in a shared plugin development guide so that plugin authors have a single reference for the expected JSON schema.
- Monitor the `.doc.doc.md/` directory size over time — no cleanup or lifecycle management is in scope for this feature, but it may be needed in the future.

## Conclusion

FEATURE_0041 is **architecturally compliant**. The plugin storage plumbing implements REQ_0029 by extending the existing `run_plugin` / `process_file` pipeline with storage directory creation and `pluginStorage` JSON injection. ADR-001, ADR-003, and ADR-004 are fully met. Path security follows REQ_SEC_005 via `readlink -f` canonicalization and containment validation. No deviations or concerns were identified.
