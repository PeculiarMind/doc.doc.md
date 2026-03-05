# TDD for BUG_0009: render_template_json Multiline Injection

- **ID:** TDD_BUG_0009
- **Priority:** Medium
- **Type:** Task
- **Created at:** 2026-03-05
- **Created by:** developer.agent
- **Status:** DONE
- **Assigned to:** tester.agent

## Overview
TDD task for BUG_0009. Tests written in `tests/test_bug_0009.sh` covering:
- Source uses safe jq 'keys[]' pattern (not to_entries[])
- Multiline value injection prevention
- Single-line placeholder regression
- Unmatched placeholders preserved

## Acceptance Criteria
- [x] Tests for template injection prevention written (12 assertions)
- [x] Tests pass after fix

## Related Links
- Bug: [BUG_0009](BUG_0009_render_template_json_multiline_injection.md)
- Technical Debt: [DEBTR_003](DEBTR_003_render_template_json_multiline_values.md)
