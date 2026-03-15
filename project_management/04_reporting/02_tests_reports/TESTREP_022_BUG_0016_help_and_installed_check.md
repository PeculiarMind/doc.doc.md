# Test Report: BUG_0016 — Help text CLI flags & installed check

- **Report ID:** TESTREP_022
- **Work Item:** BUG_0016
- **Date:** 2026-03-15
- **Agent:** tester.agent
- **Status:** PASS

## Scope

Verification that:
1. `_run_command_help()` shows CLI flags from a `usage` block for interactive commands instead of raw JSON field names
2. Non-interactive commands continue to show input/output fields as before
3. `learn.sh`, `unlearn.sh`, and `train.sh` use `crm -e 'learn/unlearn ...'` instead of standalone `csslearn`/`cssunlearn`
4. `installed.sh` checks only for the `crm` binary
5. Backward compatibility with existing run command behavior

## Test Suite

**File:** `tests/test_bug_0016.sh`

## Results

| Group | Tests | Passed | Failed |
|-------|-------|--------|--------|
| 1 — Interactive command help shows CLI flags | 5 | 5 | 0 |
| 2 — Interactive command help hides JSON field names as input fields | 2 | 2 | 0 |
| 3 — Non-interactive command help shows input fields | 4 | 4 | 0 |
| 4 — crm114 train --help shows CLI flags | 5 | 5 | 0 |
| 5 — crm114 non-interactive commands unchanged | 5 | 5 | 0 |
| 6 — crm114 descriptor has usage block | 3 | 3 | 0 |
| 7 — learn.sh and unlearn.sh use crm -e | 4 | 4 | 0 |
| 8 — train.sh uses crm -e | 3 | 3 | 0 |
| 9 — installed.sh checks crm binary | 3 | 3 | 0 |
| 10 — Backward compatibility | 3 | 3 | 0 |
| **Total** | **37** | **37** | **0** |

## Regression

| Suite | Result |
|-------|--------|
| `tests/test_bug_0014.sh` (command-level help) | 22/22 pass |
| `tests/test_bug_0015.sh` (interactive plugin commands) | 22/22 pass |
| `tests/test_feature_0042.sh` (CRM114 Model Management) | 56/56 pass (6 skipped) |
| `tests/test_feature_0043.sh` (Plugin Command Runner) | 50/50 pass |
| `tests/test_feature_0044.sh` (run -d/-o flags) | 28/28 pass |
| `tests/test_feature_0038.sh` (help system) | 44/44 pass |
| `tests/test_list_commands.sh` | 28/28 pass |
| `tests/test_plugins.sh` | 52/52 pass |

## Findings

- All acceptance criteria covered.
- Interactive commands with a `usage` block now show CLI flags (`-o`, `-d`) instead of raw JSON field names.
- Non-interactive commands (learn, unlearn, listCategories, process) continue to show `Input fields:` / `Output fields:` sections — no behavioral change.
- `learn.sh`, `unlearn.sh`, and `train.sh` replaced all `csslearn`/`cssunlearn` invocations with `crm -e 'learn/unlearn <osb unique microgroom> (...)'`.
- `installed.sh` now checks only for the `crm` binary, accurately reflecting the plugin's actual runtime dependencies.
- No regressions in any related test suite.

## Verdict

**PASS** — BUG_0016 is fixed and verified.
