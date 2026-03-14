# Architecture Review: FEATURE_0044 — run command -d / -o flag support

- **Report ID:** ARCHREV_022
- **Work Item:** FEATURE_0044
- **Date:** 2026-03-14
- **Agent:** architect.agent
- **Status:** Compliant

## Scope

Review of changes that add `-d` and `-o` flag support to the `run` command, enabling automatic `pluginStorage` derivation consistent with `process` command behavior (FEATURE_0041).

## Changes Reviewed

| File | Change |
|------|--------|
| `doc.doc.md/components/plugin_management.sh` | Added `-d`, `-o` to flag parser; pluginStorage derivation logic; input dir validation |
| `doc.doc.md/components/ui.sh` | Updated `ui_usage_run()` and `ui_usage()` to document `-d`, `-o` options |
| `tests/test_feature_0044.sh` | New test suite with 28 tests |

## Compliance Assessment

| Criterion | Status | Notes |
|-----------|--------|-------|
| ADR-001: Bash implementation | ✅ | Pure Bash + jq, no new language dependencies |
| ADR-002: Tool reuse | ✅ | Reuses `readlink -f` for canonicalization (consistent with `plugin_execution.sh`), `jq --arg` for safe JSON construction |
| ADR-003: JSON plugin descriptors | ✅ | `pluginStorage` field follows existing convention |
| FEATURE_0041 consistency | ✅ | Path convention `<output_dir>/.doc.doc.md/<pluginname>/` identical to `run_plugin()` in `plugin_execution.sh` |
| REQ_SEC_005: Path traversal prevention | ✅ | `readlink -f` canonicalization + prefix check; derived path validated under canonical output dir |
| Help pattern | ✅ | `ui_usage_run()` updated with new options; main `ui_usage()` example updated |
| Module boundary | ✅ | Logic stays within `cmd_run()` in `plugin_management.sh` |

## Deviations

None.

## Recommendations

1. Consider extracting the `pluginStorage` derivation logic (canonicalize, validate, mkdir) into a shared helper to avoid duplication with `plugin_execution.sh` in the future. Not blocking — current duplication is minimal and both code paths are well-tested.

## Verdict

**Compliant** — Implementation follows established patterns and is consistent with the existing `process` command's storage derivation.
