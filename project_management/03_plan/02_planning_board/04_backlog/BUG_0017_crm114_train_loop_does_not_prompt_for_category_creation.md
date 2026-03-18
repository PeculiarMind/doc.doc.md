# CRM114 `loop train` Does Not Prompt for Category Creation

- **ID:** BUG_0017
- **Priority:** Medium
- **Type:** Bug
- **Created at:** 2026-03-18
- **Created by:** Product Owner
- **Status:** BACKLOG

## Overview

When running `./doc.doc.sh loop -d <docsDir> -o <outputDir> --plugin crm114 train` with no categories
configured, `train.sh` exits immediately with code 65 and prints a static message directing the user
to run `manageCategories` separately first. The expected behaviour is that the `loop … train` flow
is fully self-contained and interactive: if no categories exist yet, the user should be prompted to
create them inline — matching the same interactive UX provided by `manageCategories` — before the
per-document labeling begins.

## Background — FEATURE_0046 Design

FEATURE_0046 defined the following **typical interactive training workflow**:

```
# Step 1 — set up categories once
./doc.doc.sh run crm114 manageCategories -o <outputDir>

# Step 2 — label documents interactively
./doc.doc.sh loop -d <docsDir> -o <outputDir> --plugin crm114 train
```

The feature acceptance criteria for the `train` command state:

> *"If no categories exist in `pluginStorage`, prints a message instructing the user to run
> `manageCategories` first and exits with code 65 (skip — ADR-004)"*

This was implemented as specified in FEATURE_0046. However the two-step workflow creates unnecessary
friction: a new user running only the `loop … train` command receives a cryptic skip with no
interactive recovery path. The intended UX is a single command that handles first-run setup
automatically, consistent with how `manageCategories` itself prompts for initial categories when
none exist yet.

## Steps to Reproduce

1. Start with a clean/empty output directory (no `.css` model files in `pluginStorage`).
2. Run:
   ```
   ./doc.doc.sh loop -d ./tests/docs/ -o ./tests/out --plugin crm114 train
   ```
3. Observe: loop skips every document silently; no category creation prompt is shown.

## Expected Behaviour

When no categories exist in `pluginStorage`, `train.sh` detects this before the first document is
processed and interactively prompts the user to create at least one category (reusing the same
inline flow implemented in `manageCategories.sh`) before beginning the per-document `t/u/s` labeling.

## Actual Behaviour

`train.sh` exits with code 65 and prints:
```
No categories exist. Run 'doc.doc.sh run crm114 manageCategories -o <outputDir>' first.
```
`doc.doc.sh loop` receives the skip exit code on every document and the session ends with zero
training performed and no interactive prompt.

## Root Cause

`doc.doc.md/plugins/crm114/train.sh` (guard block around lines 43–49): when `pluginStorage`
contains no `.css` files it calls `exit 65` immediately rather than delegating to the inline
category-creation sub-flow from `manageCategories.sh`.

## Acceptance Criteria

- [ ] Running `loop … --plugin crm114 train` with no categories in `pluginStorage` triggers an
      interactive prompt to create at least one category before the first document is processed.
- [ ] The inline category-creation flow uses the same validation rules as `manageCategories`:
      names are alphanumeric, dash, underscore, or dot only; corresponding `.css` files are
      initialized in `pluginStorage`.
- [ ] If the user provides no categories (empty input / Ctrl-D), the command exits gracefully with
      a clear message and exit code 65 (ADR-004 skip contract preserved).
- [ ] If at least one category is created inline, processing continues immediately with the
      per-document `t/u/s` labeling prompts for all documents in the loop.
- [ ] If categories already exist in `pluginStorage`, behaviour is unchanged.
- [ ] `doc.doc.sh run crm114 manageCategories -o <outputDir>` continues to work independently.
- [ ] All security constraints from FEATURE_0046 are maintained: `pluginStorage` path traversal
      check, category name sanitization (REQ_SEC_005), `.css` files written exclusively to
      `pluginStorage`.
- [ ] A regression test (`tests/test_bug_0017.sh`) covers the new behaviour.

## Dependencies

- **FEATURE_0046** (CRM114 plugin) — DONE; provides `train.sh` and `manageCategories.sh`
- **FEATURE_0045** (`loop` command) — DONE; drives per-document invocation of `train.sh`
- **FEATURE_0041** (plugin storage plumbing) — DONE; derives and injects `pluginStorage`
- **ADR-004** — exit code 65 skip contract must remain intact

## Related Links

- Feature: [FEATURE_0046](../06_done/FEATURE_0046_crm114_text_classification_plugin.md)
- FEATURE_0045: `project_management/03_plan/02_planning_board/06_done/FEATURE_0045_loop-command-interactive-document-pipeline.md`
- FEATURE_0041: `project_management/03_plan/02_planning_board/06_done/FEATURE_0041_plugin-storage-plumbing.md`
- train command: `doc.doc.md/plugins/crm114/train.sh`
- manageCategories command: `doc.doc.md/plugins/crm114/manageCategories.sh`
