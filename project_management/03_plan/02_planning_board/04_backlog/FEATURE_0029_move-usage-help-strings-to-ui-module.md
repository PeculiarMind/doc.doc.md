# Move Usage/Help Strings to `ui.sh` Module

- **ID:** FEATURE_0029
- **Priority:** Medium
- **Type:** Feature
- **Created at:** 2026-03-06
- **Created by:** product_owner
- **Status:** BACKLOG

## TOC

## Overview
All usage/help text functions (`usage()`, `usage_activate()`, `usage_process()`, etc.) currently live in `doc.doc.sh`. These functions are pure presentation — they print human-readable text to the terminal and contain zero orchestration logic. The `ui.sh` component already owns all other user-facing output: progress display, log helpers, and colour constants. Moving the usage/help functions into `ui.sh` completes the separation of concerns demanded by REQ_0032 (separate UI module) and REQ_0036 (orchestration isolation): `doc.doc.sh` becomes a pure CLI router with no presentation logic of any kind.

FEATURE_0027 reorganises the `cmd_*` command functions and deliberately defers this follow-up. This item must therefore begin only after FEATURE_0027 is DONE, so that the final shape of the moved functions is stable before the usage strings are also relocated.

**Prerequisite:** FEATURE_0027 must be completed and merged before starting this item.

## Acceptance Criteria
- [ ] All usage/help text functions (including but not limited to `usage()`, `usage_activate()`, `usage_process()`, and any per-command usage helpers) are removed from `doc.doc.sh` and implemented inside `doc.doc.md/components/ui.sh`
- [ ] `doc.doc.sh` contains no `echo`/`printf` statements that produce user-facing help or usage output after this change; it only sources `ui.sh` and delegates to the relocated functions
- [ ] All existing automated tests in `tests/` continue to pass without modification, confirming that the visible CLI usage output is byte-for-byte identical before and after the move (REQ_0038 backward compatibility)
- [ ] `ui.sh` exports the relocated functions under the `ui_` naming convention (e.g. `ui_usage`, `ui_usage_activate`, `ui_usage_process`) or an equivalent documented convention consistent with REQ_0037 module interface contracts
- [ ] `doc.doc.sh` line count is measurably reduced (target: ≤ 450 lines, consistent with the cap introduced in FEATURE_0027), with the reduction attributable entirely to the moved usage/help functions
- [ ] Each relocated function carries a brief inline comment identifying its origin and purpose, consistent with the module documentation convention in REQ_0037

## Dependencies
- **Blocked by FEATURE_0027**: The `cmd_*` reorganisation must be complete and merged before relocating usage strings, so that the final function structure in `doc.doc.sh` is stable. Do not begin implementation until FEATURE_0027 is in state DONE.

## Related Links
- Requirements: [REQ_0032 Separate UI Module](../../../02_project_vision/02_requirements/03_accepted/REQ_0032_separate-ui-module.md)
- Requirements: [REQ_0036 Orchestration Isolation](../../../02_project_vision/02_requirements/03_accepted/REQ_0036_orchestration-isolation.md)
- Requirements: [REQ_0037 Module Interface Contract](../../../02_project_vision/02_requirements/03_accepted/REQ_0037_module-interface-contract.md)
- Predecessor: FEATURE_0027 (Move cmd_* functions to component modules)
- Successor context: FEATURE_0028 (Python rewrite of plugin_info logic — benefits from a leaner doc.doc.sh)
