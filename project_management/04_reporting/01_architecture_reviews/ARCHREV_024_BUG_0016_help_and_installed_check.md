# Architecture Review: BUG_0016 — Help text CLI flags & installed check

- **Report ID:** ARCHREV_024
- **Work Item:** BUG_0016
- **Date:** 2026-03-15
- **Agent:** architect.agent
- **Status:** Compliant

## Scope

Review of changes to `plugin_management.sh`, `crm114/descriptor.json`, `crm114/learn.sh`, `crm114/unlearn.sh`, `crm114/train.sh`, and `crm114/installed.sh` that:
1. Add a `usage` block to the descriptor schema for interactive command help rendering
2. Replace `csslearn`/`cssunlearn` invocations with `crm -e 'learn/unlearn ...'`
3. Simplify the installed check to only require the `crm` binary

## Changes Reviewed

| File | Change |
|------|--------|
| `doc.doc.md/components/plugin_management.sh` | `_run_command_help()` checks for `usage` array in descriptor; renders CLI flags for interactive commands instead of raw JSON fields |
| `doc.doc.md/plugins/crm114/descriptor.json` | Added `usage` array to `train` command with `-o` and `-d` flag entries; updated description |
| `doc.doc.md/plugins/crm114/learn.sh` | Replaced `csslearn` with `crm -e 'learn <osb unique microgroom> (...)'` |
| `doc.doc.md/plugins/crm114/unlearn.sh` | Replaced `cssunlearn` with `crm -e 'unlearn <osb unique microgroom> (...)'` |
| `doc.doc.md/plugins/crm114/train.sh` | Replaced `csslearn`/`cssunlearn` with `crm -e` equivalents; simplified availability check |
| `doc.doc.md/plugins/crm114/installed.sh` | Changed from `crm || cssutil` to `crm` only check |
| `tests/test_bug_0016.sh` | New test suite with spy plugin verifying help rendering and source code changes |

## Compliance Assessment

| Criterion | Status | Notes |
|-----------|--------|-------|
| ADR-001: Bash implementation | ✅ | Pure Bash + jq, no new language dependencies |
| ADR-002: Tool reuse | ✅ | Uses existing `jq` for descriptor.json `usage` array lookup |
| ADR-003: JSON plugin descriptors | ✅ | Extends descriptor schema with optional `"usage"` array — backward compatible (commands without it show input/output fields as before) |
| Module placement | ✅ | Change is contained within `_run_command_help()` in `plugin_management.sh` |
| REQ_SEC_005: Path traversal prevention | ✅ | CSS file path construction and validation unchanged in learn.sh/unlearn.sh |
| FEATURE_0041 consistency | ✅ | `pluginStorage` derivation unchanged |
| FEATURE_0043 consistency | ✅ | `cmd_run()` flow unaffected; only help rendering changes |
| FEATURE_0044 consistency | ✅ | `-d` and `-o` flag parsing unaffected |
| Field naming convention | ✅ | `usage` array uses `flag` and `description` keys consistent with help system patterns |
| Backward compatibility | ✅ | Commands without `"usage"` array render input/output fields as before |
| Dependency reduction | ✅ | Replacing `csslearn`/`cssunlearn` with `crm -e` reduces external binary requirements from 3+ to 1 (`crm` only) |

## Deviations

None.

## Recommendations

None — changes are minimal, well-scoped, and backward compatible.

## Verdict

**Compliant** — The fix extends the descriptor schema with an optional `"usage"` array and adds a conditional rendering path that is fully consistent with existing architecture patterns. The CRM114 dependency simplification is a net positive.
