# Test Report: BUG_0014 — run command-level --help fix

- **Report ID:** TESTREP_019
- **Work Item:** BUG_0014
- **Date:** 2026-03-14
- **Agent:** tester.agent
- **Status:** PASS

## Scope

Verification that `./doc.doc.sh run <plugin> <command> --help` displays per-command help text (description, input fields, output fields) and exits 0, without producing the self-referential error message observed pre-fix.

## Test Suite

**File:** `tests/test_bug_0014.sh`

## Results

| Group | Tests | Passed | Failed |
|-------|-------|--------|--------|
| 1 — command-level --help exits 0 | 3 | 3 | 0 |
| 2 — description displayed | 2 | 2 | 0 |
| 3 — input fields displayed | 6 | 6 | 0 |
| 4 — output fields displayed | 2 | 2 | 0 |
| 5 — command with no declared fields | 2 | 2 | 0 |
| 6 — no self-referential error | 3 | 3 | 0 |
| 7 — existing help levels unaffected | 4 | 4 | 0 |
| **Total** | **22** | **22** | **0** |

## Regression

All 50 pre-existing tests in `tests/test_feature_0043.sh` continue to pass.

## Findings

- All acceptance criteria covered.
- Three-level help hierarchy (`run --help`, `run <plugin> --help`, `run <plugin> <command> --help`) now works consistently.
- Commands with no declared input or output fields display description only — graceful degradation.

## Verdict

**PASS** — BUG_0014 is fixed and verified.
