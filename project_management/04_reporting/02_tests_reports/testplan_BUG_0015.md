# Test Plan: BUG_0015 — run command incompatible with interactive plugins

- **ID:** testplan_BUG_0015
- **Created at:** 2026-03-14
- **Created by:** Tester
- **Work Item:** [BUG_0015](../../03_plan/02_planning_board/05_implementing/BUG_0015_run-command-incompatible-with-interactive-plugins.md)
- **Status:** Active

## Scope

**In scope:**
- Verifying that `cmd_run` detects `"interactive": true` in `descriptor.json` and invokes the command script with positional arguments instead of piping JSON to stdin
- Verifying that non-interactive commands continue to receive JSON via stdin unchanged
- Verifying that the crm114 `train` command descriptor has been updated with `"interactive": true`, renamed `inputDirectory` field, and cleaned descriptions
- Backward compatibility with all existing `run` command behavior

**Out of scope:**
- Actual interactive CRM114 training session (requires TTY + crm114 tools installed)
- Changes to the `process` command pipeline
- Individual plugin script modifications beyond descriptor changes

## Test Strategy

**Integration tests** using a spy plugin (`spy15`) that records how it was invoked (positional args vs. stdin JSON). Tests run against the real `doc.doc.sh` entry point.

## Entry Criteria
- [x] `doc.doc.sh` and `doc.doc.md/components/plugin_management.sh` present and executable
- [x] `jq` available on PATH
- [x] FEATURE_0043 (Plugin Command Runner) implemented and passing
- [x] FEATURE_0044 (run command -d/-o flags) implemented and passing

## Exit Criteria
- [x] All scenarios in `tests/test_bug_0015.sh` pass
- [x] `tests/test_feature_0043.sh` still passes (50/50)
- [x] `tests/test_feature_0044.sh` still passes (28/28)
- [x] `tests/test_bug_0014.sh` still passes (22/22)

## Test Scenarios

| ID | Scenario | Type | Expected Result |
|----|----------|------|-----------------|
| TS_001 | Interactive command exits 0 | Integration | Exit 0 |
| TS_002 | Interactive command receives pluginStorage as positional arg 1 | Integration | ARG1 contains derived pluginStorage path |
| TS_003 | Interactive command receives inputDirectory as positional arg 2 | Integration | ARG2 is the input directory |
| TS_004 | Interactive command receives exactly 2 positional args | Integration | ARGC=2 |
| TS_005 | Non-interactive command receives JSON via stdin | Integration | stdout contains JSON with pluginStorage and filePath |
| TS_006 | Interactive command does NOT receive JSON on stdin | Integration | No `{` or `"pluginStorage"` in stdout |
| TS_007 | crm114 train descriptor has `"interactive": true` | Descriptor | jq query returns `true` |
| TS_008 | crm114 train descriptor no longer has `input_dir` field | Descriptor | jq query returns empty |
| TS_009 | crm114 train descriptor has `inputDirectory` field | Descriptor | jq query returns non-empty |
| TS_010 | pluginStorage description no longer mentions "positional" | Descriptor | No "positional" substring |
| TS_011 | inputDirectory description no longer mentions "positional" | Descriptor | No "positional" substring |
| TS_012 | crm114 learn --help still works | Regression | Exit 0 |
| TS_013 | crm114 listCategories --help still works | Regression | Exit 0 |
| TS_014 | Non-interactive --plugin-storage still works | Regression | Exit 0, JSON with pluginStorage |
| TS_015 | Interactive command --help exits 0 | Help | Exit 0 |
| TS_016 | Interactive command --help shows description | Help | Contains "Interactive command" |

## Implementation Reference

Test file: `tests/test_bug_0015.sh`

| Scenario | Group in test file |
|---|---|
| TS_001 – TS_004 | Group 1: Interactive command receives positional args |
| TS_005 | Group 2: Non-interactive command still receives JSON via stdin |
| TS_006 | Group 3: Interactive command does NOT receive JSON on stdin |
| TS_007 – TS_011 | Group 4: crm114 train descriptor has interactive field |
| TS_012 – TS_014 | Group 5: Backward compatibility |
| TS_015 – TS_016 | Group 6: Help text reflects interactive mode |

## Dependencies
- spy15 test plugin: created/destroyed by test file (cleanup trap)
- crm114 plugin descriptor: read-only checks against live descriptor

## Execution History

| Date | Report | Result |
|------|--------|--------|
| 2026-03-14 | — | Red phase: 7 failures (TS_001–TS_004 partial, TS_007–TS_011 fail) |
| 2026-03-14 | [TESTREP_021](./TESTREP_021_BUG_0015_interactive_plugin_commands.md) | Green phase: 22/22 pass; regression suites pass |
