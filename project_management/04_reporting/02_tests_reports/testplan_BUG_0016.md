# Test Plan: BUG_0016 — Help text CLI flags & installed check

- **ID:** testplan_BUG_0016
- **Created at:** 2026-03-15
- **Created by:** tester.agent
- **Work Item:** [BUG_0016](../../03_plan/02_planning_board/05_implementing/BUG_0016_help_does_not_show_proper_examples_and_dependencies_are_not_installed.md)
- **Status:** Active

## Scope

Testing that:
1. `_run_command_help()` shows CLI flags from a `usage` block for interactive commands instead of raw JSON field names
2. Non-interactive commands continue to show input/output fields as before
3. `learn.sh`, `unlearn.sh`, and `train.sh` use `crm -e 'learn/unlearn ...'` instead of standalone `csslearn`/`cssunlearn`
4. `installed.sh` checks only for the `crm` binary (no longer references `csslearn`/`cssunlearn`)
5. Backward compatibility with existing run command behavior

## Test Strategy

Integration tests via `tests/test_bug_0016.sh` using a spy16 test plugin and crm114 source inspection.

## Entry Criteria
- [x] BUG_0016 work item in implementing state
- [x] TDD task created and assigned

## Exit Criteria
- [ ] All tests in `tests/test_bug_0016.sh` pass
- [ ] No regressions in related test suites

## Test Scenarios

| ID | Scenario | Type | Expected Result |
|----|----------|------|-----------------|
| TS_001 | Interactive command --help shows CLI flags from usage block | Integration | Help output contains `-o <output-dir>` and `-d <input-dir>` |
| TS_002 | Interactive command --help does NOT show raw JSON field names | Integration | Help output does not contain `pluginStorage`, `inputDirectory`, or `Input fields:` |
| TS_003 | Non-interactive command --help still shows input/output fields | Integration | Help output contains `Input fields:`, `pluginStorage`, `filePath` |
| TS_004 | crm114 train --help shows CLI flags | Integration | Help shows `-o`, `-d`, not `--inputDirectory` |
| TS_005 | crm114 learn/unlearn --help unchanged | Integration | Help still shows `Input fields:` and `category` |
| TS_006 | crm114 descriptor.json train command has usage array | Unit | `usage` array exists with `-o` and `-d` entries |
| TS_007 | learn.sh uses `crm -e` not `csslearn` | Unit | Source does not contain `csslearn`, contains `crm` |
| TS_008 | unlearn.sh uses `crm -e` not `cssunlearn` | Unit | Source does not contain `cssunlearn`, contains `crm` |
| TS_009 | train.sh uses `crm -e` not `csslearn`/`cssunlearn` | Unit | Source does not contain `csslearn` or `cssunlearn` |
| TS_010 | installed.sh checks crm, not csslearn/cssunlearn | Unit | Source contains `crm`, not `csslearn` or `cssunlearn` |
| TS_011 | Backward compatibility | Integration | crm114 --help and listCategories --help still work |

## Dependencies

- jq installed for descriptor.json parsing
- spy16 test plugin created at test runtime

## Execution History

| Date | Report | Result |
|------|--------|--------|
