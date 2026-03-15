# Architecture Review: BUG_0015 — Interactive plugin command support

- **Report ID:** ARCHREV_023
- **Work Item:** BUG_0015
- **Date:** 2026-03-14
- **Agent:** architect.agent
- **Status:** Compliant

## Scope

Review of changes to `plugin_management.sh` and `crm114/descriptor.json` that add interactive command detection and positional argument passing to `cmd_run()`.

## Changes Reviewed

| File | Change |
|------|--------|
| `doc.doc.md/components/plugin_management.sh` | Added interactive mode detection via `jq` query on `descriptor.json`; conditional execution path passes positional args instead of JSON stdin |
| `doc.doc.md/plugins/crm114/descriptor.json` | Added `"interactive": true` to `train` command; renamed `input_dir` → `inputDirectory`; updated field descriptions |
| `tests/test_bug_0015.sh` | New test suite with spy plugin verifying interactive/non-interactive command dispatch |

## Compliance Assessment

| Criterion | Status | Notes |
|-----------|--------|-------|
| ADR-001: Bash implementation | ✅ | Pure Bash + jq, no new language dependencies |
| ADR-002: Tool reuse | ✅ | Uses existing `jq` for descriptor.json `interactive` field lookup |
| ADR-003: JSON plugin descriptors | ✅ | Extends descriptor schema with `"interactive": true` — backward compatible (missing field defaults to `false`) |
| Module placement | ✅ | Change is contained within `cmd_run()` in `plugin_management.sh`, same function that handles all run logic |
| REQ_SEC_005: Path traversal prevention | ✅ | Script canonicalization and plugin directory containment checks remain unchanged and apply before the interactive/non-interactive branch |
| FEATURE_0041 consistency | ✅ | `pluginStorage` derivation from `-o` still applies before the interactive branch — derived path is passed as positional arg 1 |
| FEATURE_0044 consistency | ✅ | `-d` and `-o` flag parsing unaffected; derived values used in positional args for interactive mode |
| Field naming convention | ✅ | `input_dir` renamed to `inputDirectory` (camelCase) consistent with all other descriptor fields |
| Backward compatibility | ✅ | Commands without `"interactive"` field default to `false`, preserving existing JSON-stdin behavior |

## Deviations

None.

## Recommendations

None — change is minimal, well-scoped, and backward compatible.

## Verdict

**Compliant** — The fix extends the descriptor schema with an optional `"interactive"` flag and adds a conditional execution path that is fully consistent with existing architecture patterns.
