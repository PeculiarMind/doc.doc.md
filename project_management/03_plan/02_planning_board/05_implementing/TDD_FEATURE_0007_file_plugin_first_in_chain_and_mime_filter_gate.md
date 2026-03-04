# TDD Task: File Plugin as Processing Chain Gate with MIME Type Filter

- **ID:** TDD_FEATURE_0007
- **Priority:** HIGH
- **Type:** TDD Task
- **Created at:** 2026-03-04
- **Created by:** developer.agent
- **Status:** Done
- **Assigned to:** tester.agent
- **Related Feature:** FEATURE_0007

## Overview

Implement failing tests for FEATURE_0007 following TDD workflow.
Tests must fail before implementation and cover all acceptance criteria.

## Acceptance Criteria to Cover

### Processing Chain — file Plugin Executes First
- file plugin is always placed at position 0 in execution order
- If file plugin is not active/installed, process aborts with clear error
- mimeType from file plugin output is available to filter logic before other plugins

### Filter Gate — MIME Type Evaluation
- After file plugin executes, doc.doc evaluates mimeType against --include/--exclude criteria
- MIME-excluded files are silently skipped (no output, no error)
- MIME type filter criteria recognized by presence of `/` character
- Glob-style MIME patterns supported (e.g., `image/*`)

### Skipped File Behavior
- No markdown output for skipped files
- No mirror directory entry for skipped files
- doc.doc continues to next file silently

### Backward Compatibility
- Files without MIME filter criteria unaffected
- Extension-based and glob-based filter criteria continue to work

## Test File Location

Tests should be added to: `tests/test_feature_0007.sh`

## Completion

- **Test file created:** `tests/test_feature_0007.sh`
- **Total tests:** 63
- **Currently passing:** 49 (filter.py matching logic + backward compat + no-MIME-filter scenarios)
- **Currently failing:** 14 (all integration tests for file-first enforcement and MIME filter gate)
