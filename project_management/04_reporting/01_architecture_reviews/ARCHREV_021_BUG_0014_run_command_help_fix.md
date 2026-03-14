# Architecture Review: BUG_0014 — run command-level --help fix

- **Report ID:** ARCHREV_021
- **Work Item:** BUG_0014
- **Date:** 2026-03-14
- **Agent:** architect.agent
- **Status:** Compliant

## Scope

Review of changes to `plugin_management.sh` that add per-command `--help` handling to the `cmd_run()` function.

## Changes Reviewed

| File | Change |
|------|--------|
| `doc.doc.md/components/plugin_management.sh` | Added `_run_command_help()` function; added `--help` check after command name validation |
| `tests/test_bug_0014.sh` | New test suite verifying command-level help |

## Compliance Assessment

| Criterion | Status | Notes |
|-----------|--------|-------|
| ADR-001: Bash implementation | ✅ | Pure Bash + jq, no new language dependencies |
| ADR-002: Tool reuse | ✅ | Uses existing `jq` for descriptor.json parsing |
| ADR-003: JSON plugin descriptors | ✅ | Reads `commands[$cmd].input` and `commands[$cmd].output` from descriptor.json |
| Help pattern (`_run_*_help`) | ✅ | Follows existing `_run_global_help`, `_run_plugin_help` naming convention |
| Module placement | ✅ | Helper added in `plugin_management.sh` alongside existing help functions |
| REQ_SEC_001 / REQ_SEC_005 | ✅ | No new user input handling; command name already validated before --help check |

## Deviations

None.

## Recommendations

None — change is minimal and well-scoped.

## Verdict

**Compliant** — The fix follows existing patterns and introduces no architectural concerns.
