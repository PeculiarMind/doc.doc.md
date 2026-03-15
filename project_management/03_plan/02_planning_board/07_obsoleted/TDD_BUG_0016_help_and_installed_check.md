# TDD Task: BUG_0016 — Help text CLI flags & installed check

- **ID:** TDD_BUG_0016
- **Priority:** Medium
- **Type:** Task
- **Created at:** 2026-03-15
- **Created by:** developer.agent
- **Assigned to:** tester.agent
- **Status:** OBSOLETED
- **Obsolescence reason:** Parent bug BUG_0016 obsoleted; CRM114 plugin requires massive rework.

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)

## Overview

Create tests for BUG_0016 before implementation (TDD red phase). Tests should cover:

1. **Problem 1 — Help text**: `_run_command_help()` should show CLI flags (`-d`, `-o`) for interactive commands instead of raw JSON field names
2. **Problem 2 — Installed check**: `installed.sh` should accurately reflect plugin usability; `train.sh`/`learn.sh`/`unlearn.sh` should use `crm -e` instead of `csslearn`/`cssunlearn`

## Acceptance Criteria
- [ ] Test file `tests/test_bug_0016.sh` created
- [ ] Tests verify help output shows CLI flags, not JSON field names
- [ ] Tests verify `installed.sh` returns correct status
- [ ] Tests verify `learn.sh`/`unlearn.sh`/`train.sh` use `crm -e` instead of `csslearn`/`cssunlearn`
- [ ] All tests fail in red phase (before implementation)
