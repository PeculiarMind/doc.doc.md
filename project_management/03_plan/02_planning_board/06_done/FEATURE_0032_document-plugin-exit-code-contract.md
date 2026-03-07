# Feature: Document Plugin Exit Code Contract in Developer Guide

- **ID:** FEATURE_0032
- **Priority:** High
- **Type:** Feature
- **Created at:** 2026-03-07
- **Created by:** Product Owner
- **Status:** BACKLOG

## Overview
Document the three-state plugin exit code contract (ADR-004 / REQ_0042) in the developer guide so that plugin authors have a normative, self-contained reference for how the `process` command must behave. This is a precondition for any new plugin to be correctly implemented and accepted.

## Background
ADR-004 defined a structured exit code contract for the plugin–framework interface, and REQ_0042 formalised this as a testable requirement. Currently the developer guide (`project_documentation/04_dev_guide/dev_guide.md`) does not document exit code expectations for the `process` command. A plugin author following the existing guide would implement exit 1 for all failures, producing the very spurious error messages that BUG_0011 aims to fix.

## Acceptance Criteria
- [ ] The developer guide plugin development section documents the three-state exit code contract:
  - Exit **0** — successful execution; stdout contains output JSON as declared in `descriptor.json`
  - Exit **65** (`EX_DATAERR`) — intentional skip / input not supported; stdout contains `{}` or `{"message":"<reason>"}`
  - Exit **1** (or any non-zero ≠ 65) — unexpected failure during processing
- [ ] The guide explicitly states that exit 65 must only be used when the plugin decided not to handle the input, not for processing errors
- [ ] The guide explicitly states that the skip message (`{"message":"..."}`) must go to **stdout** as JSON, not to stderr as plain text
- [ ] The guide includes a short code example illustrating the three exit paths in a plugin's `main.sh`
- [ ] ADR-004 is cross-referenced from the developer guide plugin section
- [ ] REQ_0042 acceptance criterion for dev guide documentation is satisfied

## Dependencies
- ADR-004 (Plugin Exit Code and Failure Handling Strategy)
- REQ_0042 (Plugin Process Command Exit Code Interface Contract)
- BUG_0011 (depends on this being documented before or alongside the implementation)

## Related Links
- Architecture Decision: `project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md`
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0042_plugin-process-exit-code-contract.md`
- Dev guide: `project_documentation/04_dev_guide/dev_guide.md`
