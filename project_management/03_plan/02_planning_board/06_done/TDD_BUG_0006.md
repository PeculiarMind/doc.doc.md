# TDD for BUG_0006: Markitdown Plugin Stdin Size Limit

- **ID:** TDD_BUG_0006
- **Priority:** Medium
- **Type:** Task
- **Created at:** 2026-03-05
- **Created by:** developer.agent
- **Status:** DONE
- **Assigned to:** tester.agent

## Overview

TDD task for BUG_0006. Tests written in `tests/test_bug_0006.sh` covering:
- Script uses `head -c 1048576` instead of bare `cat`
- Valid small payloads work (regression)
- Oversized payloads (>1MB) are truncated

## Acceptance Criteria

- [x] Tests for stdin size limit written
- [x] Tests initially fail (TDD red phase)
- [x] Tests pass after fix (TDD green phase)

## Related Links

- Bug: [BUG_0006](BUG_0006_markitdown_plugin_missing_stdin_size_limit.md)
