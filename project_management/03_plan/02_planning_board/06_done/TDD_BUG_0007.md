# TDD for BUG_0007: List Command Path Traversal

- **ID:** TDD_BUG_0007
- **Priority:** Medium
- **Type:** Task
- **Created at:** 2026-03-05
- **Created by:** developer.agent
- **Status:** DONE
- **Assigned to:** tester.agent

## Overview
TDD task for BUG_0007. Tests written in `tests/test_bug_0007.sh` covering:
- Path traversal via --parameters rejected (33 assertions)
- Path traversal via --commands rejected
- Various traversal patterns tested
- Legitimate plugins still work (regression)
- Bare '..' rejected

## Acceptance Criteria
- [x] Tests for path traversal prevention written
- [x] Tests pass after fix

## Related Links
- Bug: [BUG_0007](BUG_0007_list_plugin_path_traversal.md)
