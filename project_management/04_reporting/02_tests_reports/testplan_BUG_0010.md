# Test Plan: BUG_0010 — JSON stdout pollution in interactive process run

- **ID:** testplan_BUG_0010
- **Created at:** 2026-03-06
- **Created by:** Tester
- **Work Item:** [BUG_0010](../../03_plan/02_planning_board/04_backlog/BUG_0010_process_json_stdout_pollutes_interactive_terminal.md)
- **Status:** Active

## Scope

**In scope:**
- Verifying that `./doc.doc.sh process -d <input> -o <output>` does NOT print raw JSON to stdout when stdout is an interactive TTY.
- Verifying that in non-TTY (piped) mode the JSON array still streams to stdout correctly (backward compatibility / Unix pipeline use).
- Verifying clean stream separation: `Processed:` / error messages on stderr only; nothing leaking between streams in non-TTY mode.

**Out of scope:**
- Correctness of the JSON content itself (covered by FEATURE_0019 tests).
- Progress bar rendering (covered by FEATURE_0026 tests).
- Plugin error recovery logic.

## Test Strategy

**Integration tests** executed against the real `doc.doc.sh` entry point with a temporary input/output directory. No mocking.

TTY detection is exercised via the `script` utility (`util-linux`), which allocates a pseudo-TTY (PTY) and routes the child process's stdout/stderr through it, making `[ -t 1 ]` and `[ -t 2 ]` return true inside the subprocess. The typescript output is captured to a temp file for assertions.

## Entry Criteria
- [x] `doc.doc.sh`, `doc.doc.md/components/ui.sh`, and `doc.doc.md/components/plugin_execution.sh` present and executable
- [x] `jq` available on PATH
- [x] `script` (util-linux ≥ 2.39) available on PATH
- [x] `file` and `stat` plugins active and installed (default dev-container state)

## Exit Criteria
- [ ] All scenarios in `tests/test_bug_0010.sh` pass
- [ ] Existing `tests/test_feature_0019.sh` (process output directory) still passes
- [ ] `tests/test_doc_doc.sh` still passes (regression gate)

## Test Scenarios

| ID | Scenario | Type | Expected Result |
|----|----------|------|-----------------|
| TS_001 | Run `process -d <input> -o <output>` with stdout piped — exit code | Integration | Exit 0 |
| TS_002 | Run `process -d <input> -o <output>` with stdout piped — stdout is valid JSON | Integration | `jq empty` passes on stdout |
| TS_003 | Non-TTY stdout contains plugin data field `filePath` | Integration | `filePath` present in stdout JSON |
| TS_004 | Non-TTY stderr contains `Processed:` summary line | Integration | `Processed:` found in stderr |
| TS_005 | Non-TTY stderr does NOT contain raw JSON (`filePath` key) | Integration | No `"filePath"` in stderr |
| TS_006 | Non-TTY stdout does NOT contain `Processed:` lines | Integration | No `Processed:` in stdout |
| TS_007 | Non-TTY stdout does NOT contain `Error:` lines | Integration | No `Error:` in stdout |
| TS_008 | **[RED]** TTY mode (via `script` PTY) — stdout does NOT contain JSON array opener `[` | Integration | No `[` in PTY-captured output (FAILS before fix) |
| TS_009 | **[RED]** TTY mode (via `script` PTY) — stdout does NOT contain `"filePath"` | Integration | No `"filePath"` in PTY-captured output (FAILS before fix) |
| TS_010 | TTY mode — `Processed:` summary line still visible in PTY output | Integration | `Processed:` present in PTY-captured output |

## Implementation Reference

Test file: `tests/test_bug_0010.sh`

| Scenario | Group in test file |
|---|---|
| TS_001 – TS_003 | Group 1: Non-TTY pipe mode (backward compat) |
| TS_004 – TS_005 | Group 2: Non-TTY stderr is human-readable |
| TS_006 – TS_007 | Group 3: Non-TTY stdout is JSON only |
| TS_008 – TS_009 | Group 4: TTY mode — no JSON on stdout (RED before fix) |
| TS_010 | Group 5: TTY mode — summary still visible |

## Dependencies
- `script` (util-linux): TS_008 – TS_010 are skipped when `script` is unavailable
- Active `file` and `stat` plugins: required to produce a non-empty result set

## Execution History

| Date | Report | Result |
|------|--------|--------|
| 2026-03-06 | — | Red phase: TS_008 and TS_009 FAIL (bug confirmed); TS_001–TS_007, TS_010 PASS |
