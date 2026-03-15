# Test Report: BUG_0015 — Interactive plugin command support

- **Report ID:** TESTREP_021
- **Work Item:** BUG_0015
- **Date:** 2026-03-14
- **Agent:** tester.agent
- **Status:** PASS

## Scope

Verification that `cmd_run` correctly detects `"interactive": true` in a command's `descriptor.json` entry and invokes the script with positional arguments (`pluginStorage`, `inputDirectory`) instead of piping JSON to stdin, while non-interactive commands continue to work unchanged.

## Test Suite

**File:** `tests/test_bug_0015.sh`

## Results

| Group | Tests | Passed | Failed |
|-------|-------|--------|--------|
| 1 — Interactive command receives positional args | 6 | 6 | 0 |
| 2 — Non-interactive command still receives JSON via stdin | 3 | 3 | 0 |
| 3 — Interactive command does NOT receive JSON on stdin | 2 | 2 | 0 |
| 4 — crm114 train descriptor has interactive field | 5 | 5 | 0 |
| 5 — Backward compatibility | 4 | 4 | 0 |
| 6 — Help text reflects interactive mode | 2 | 2 | 0 |
| **Total** | **22** | **22** | **0** |

## Regression

| Suite | Result |
|-------|--------|
| `tests/test_feature_0043.sh` (Plugin Command Runner) | 50/50 pass |
| `tests/test_feature_0044.sh` (run -d/-o flags) | 28/28 pass |
| `tests/test_bug_0014.sh` (command-level help) | 22/22 pass |
| `tests/test_feature_0042.sh` (CRM114 Model Management) | 56/56 pass (6 skipped) |
| `tests/test_list_commands.sh` | 28/28 pass |
| `tests/test_plugins.sh` | 52/52 pass |
| `tests/test_feature_0038.sh` (help system) | 44/44 pass |

## Findings

- All acceptance criteria covered.
- Interactive mode correctly passes `pluginStorage` and `inputDirectory` as positional arguments.
- Non-interactive commands (learn, unlearn, listCategories, process) continue to receive JSON via stdin — no behavioral change.
- The crm114 `train` descriptor has been updated: `"interactive": true` added, `input_dir` renamed to `inputDirectory`, positional argument references removed from descriptions.
- No regressions in any related test suite.

## Verdict

**PASS** — BUG_0015 is fixed and verified.
