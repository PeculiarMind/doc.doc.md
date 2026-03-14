# Test Report: FEATURE_0044 — run command -d / -o flag support

- **Report ID:** TESTREP_020
- **Work Item:** FEATURE_0044
- **Date:** 2026-03-14
- **Agent:** tester.agent
- **Status:** PASS

## Scope

Verification that `./doc.doc.sh run <plugin> <command> -o <dir>` derives `pluginStorage` automatically, `-d <dir>` passes `inputDirectory`, path validation and security checks work correctly, and backward compatibility is maintained.

## Test Suite

**File:** `tests/test_feature_0044.sh`

## Results

| Group | Tests | Passed | Failed |
|-------|-------|--------|--------|
| 1 — -o derives pluginStorage | 3 | 3 | 0 |
| 2 — -d sets inputDirectory | 3 | 3 | 0 |
| 3 — --plugin-storage still works | 2 | 2 | 0 |
| 4 — -o takes precedence | 3 | 3 | 0 |
| 5 — -d validation | 2 | 2 | 0 |
| 6 — Security: canonicalization | 2 | 2 | 0 |
| 7 — Help text -d/-o | 3 | 3 | 0 |
| 8 — Command --help | 1 | 1 | 0 |
| 9 — Combined flags | 5 | 5 | 0 |
| 10 — Backward compatibility | 4 | 4 | 0 |
| **Total** | **28** | **28** | **0** |

## Regression

- `tests/test_feature_0043.sh`: 50/50 pass
- `tests/test_bug_0014.sh`: 22/22 pass

## Findings

- All acceptance criteria covered by at least one test.
- `pluginStorage` directory is created under output dir with correct `.doc.doc.md/<pluginname>/` convention.
- `readlink -f` canonicalization produces absolute paths with no `..` components.
- Warning emitted to stderr when both `-o` and `--plugin-storage` provided (does not pollute JSON stdout).

## Verdict

**PASS** — FEATURE_0044 is implemented and verified.
