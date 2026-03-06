# Technical Debt: `ui.sh` Internal Cleanup — Globals Struct and Bar-Render Loop

- **ID:** DEBTR_004
- **Priority:** Low
- **Type:** Task
- **Created at:** 2026-03-06
- **Created by:** product_owner
- **Status:** BACKLOG

## TOC

## Overview
Two internal quality issues exist inside `doc.doc.md/components/ui.sh` (~310 lines). Neither affects external CLI behaviour, but both impede maintainability and carry a measurable performance cost on every `process` invocation.

**Issue 1 — Scattered progress globals:** The module declares 10 `_UI_PROGRESS_*` global variables scattered across the top of the file with no grouping or explanatory comment. Readers and future contributors (e.g. anyone extending progress state for FEATURE_0025 interactive setup) must hunt through the file to find all state variables. These should be collected under a single clearly-labelled "progress state struct" comment block, and any reset/init assignments consolidated into `ui_progress_init` so there is one canonical place to zero-out all progress state.

**Issue 2 — Character-by-character bar rendering loop:** `_ui_progress_render` builds the progress bar with a `for (( i=0; i<filled; i++ ))` loop (up to 50 iterations per render call). This function is called tens of times per `process` run (once per file processed). Replacing the loop with `printf '%.0s█' $(seq 1 $filled)` (or equivalent single-expression string repetition) reduces line count, eliminates the loop variable, and is measurably faster on typical `process` workloads.

Both changes are purely internal refactors: no public function signatures, no CLI output format, and no exit codes change.

## Acceptance Criteria
- [ ] All 10 `_UI_PROGRESS_*` global variables are grouped together under a single clearly-labelled comment block (e.g. `# --- Progress state struct ---`) at the top of `ui.sh`; no `_UI_PROGRESS_*` declarations appear outside that block
- [ ] All zero-out / reset assignments for `_UI_PROGRESS_*` variables are consolidated inside `ui_progress_init`; no other function re-initialises progress state from scratch
- [ ] The character-by-character `for` loop in `_ui_progress_render` is replaced with a single-expression string-repetition construct (e.g. `printf`/`seq` or parameter expansion); the rendered progress bar output is visually identical to the previous implementation
- [ ] All existing automated tests in `tests/` continue to pass without modification after both changes, confirming no regression in progress display or any other `ui.sh`-dependent behaviour
- [ ] The line count of `ui.sh` does not increase as a result of these changes (the loop replacement and consolidation should reduce or maintain total line count)

## Dependencies
None. This item has no blocking prerequisites and can be scheduled independently.

## Related Links
- Requirements: [REQ_0032 Separate UI Module](../../../02_project_vision/02_requirements/03_accepted/REQ_0032_separate-ui-module.md)
- Requirements: [REQ_0006 User-Friendly Interface](../../../02_project_vision/02_requirements/03_accepted/REQ_0006_user-friendly-interface.md)
