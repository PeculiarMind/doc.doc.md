# Agile Board

## Overview

This agile board manages the lifecycle of features from initial idea through implementation to completion. It follows a Kanban-style workflow where each column is represented by a numbered directory, and features are tracked as Markdown files that move between columns as they progress.

## Board Columns

The board consists of eight columns, each representing a stage in the feature lifecycle:

| Column | Directory | Purpose |
|--------|-----------|---------|
| **Funnel** | `01_funnel/` | Capture point for raw ideas and feature requests — unrefined, unanalyzed |
| **Analyze** | `02_analyze/` | Features under investigation — requirements linkage, scope definition, acceptance criteria drafted |
| **Ready** | `03_ready/` | Fully specified features approved for implementation — all acceptance criteria defined, dependencies identified |
| **Backlog** | `04_backlog/` | Prioritized queue of ready features awaiting implementation — ordered by priority and dependency |
| **Implementing** | `05_implementing/` | Features actively being worked on — branch created, tests written, code in progress |
| **Done** | `06_done/` | Completed features — all acceptance criteria met, quality gates passed, PR merged |
| **Obsoleted** | `07_obsoleted/` | Features that are no longer relevant due to changed requirements or project direction |
| **Rejected** | `08_rejected/` | Features explicitly rejected after analysis — includes rationale for rejection |

## Feature File Format

Each feature is a Markdown file named `feature_<ID>_<short_name>.md` (e.g., `feature_0009_plugin_execution_engine.md`).

### Required Metadata Header

```markdown
# Feature: <Title>

**ID**: <4-digit zero-padded number>
**Type**: Feature Implementation
**Status**: <Current column name>
**Created**: <YYYY-MM-DD>
**Updated**: <YYYY-MM-DD> (<reason for update>)
**Priority**: Critical | High | Medium | Low
```

### Required Sections

| Section | Description |
|---------|-------------|
| **Overview** | One-paragraph summary of the feature |
| **Description** | Detailed explanation including scope, approach, and context |
| **Business Value** | Bullet list of why this feature matters |
| **Related Requirements** | Links to requirement files in `01_vision/02_requirements/03_accepted/` |
| **Acceptance Criteria** | Grouped checklists (`- [ ]`) defining what "done" means |

### Optional Sections

| Section | Description |
|---------|-------------|
| **Dependencies** | Features or components that must exist before implementation |
| **Technical Notes** | Implementation guidance, patterns, or constraints |
| **Testing** | Specific testing strategies or edge cases |

## Workflow

### Forward Flow (Happy Path)

```
Funnel → Analyze → Ready → Backlog → Implementing → Done
```

1. **Funnel → Analyze**: An idea is deemed worth investigating. Initial description and business value are drafted.
2. **Analyze → Ready**: Requirements are linked, acceptance criteria are fully defined, and the feature is considered well-specified.
3. **Ready → Backlog**: The feature is approved and prioritized for implementation.
4. **Backlog → Implementing**: A developer picks up the feature. A feature branch is created (`feature/<ID>_<title_in_snake_case>`), the feature file is moved to `05_implementing/`, and the `Status` and `Updated` metadata fields are updated.
5. **Implementing → Done**: All acceptance criteria are met, tests pass, quality gates are satisfied, and the PR is merged. The feature file is moved to `06_done/`.

### Terminal States

- **Obsoleted**: A feature at any stage can be moved to `07_obsoleted/` if it becomes irrelevant. The `Updated` field should record the reason.
- **Rejected**: A feature in `02_analyze/` can be moved to `08_rejected/` if analysis determines it should not be built. The file should include a rejection rationale.

### Moving a Feature Between Columns

1. Move the file to the target directory (e.g., `git mv 04_backlog/feature_0009_*.md 05_implementing/`)
2. Update the `**Status**` field to match the new column name
3. Update the `**Updated**` field with the current date and transition reason
4. Commit the change with a message like: `board: move feature_0009 to implementing`

## Prioritization

Features in **Backlog** are ordered by:

1. **Priority level**: Critical > High > Medium > Low
2. **Dependency satisfaction**: Features whose dependencies are already in `06_done/` take precedence
3. **Business value**: Higher-value features are preferred when priority and dependencies are equal

The **Ready** column (`03_ready/`) always takes precedence over **Backlog** (`04_backlog/`) — if a feature is in Ready, it should be moved to Backlog (or directly picked up) before less-refined items.

## Implementation Workflow

When a feature moves to **Implementing**, the following process is executed (typically by the Developer Agent):

1. **Preflight**: Run the full test suite to confirm a green baseline
2. **Branch**: Create `feature/<ID>_<title_in_snake_case>` from `main`
3. **Test-first**: Hand off to the Tester Agent to write tests based on acceptance criteria
4. **Implement**: Write code to pass the tests
5. **Validate**: Run the full test suite and fix any failures
6. **Quality gates** (in order):
   - Architect Agent — architecture compliance and documentation
   - License Governance Agent — license compatibility
   - Security Review Agent — vulnerability assessment
   - README Maintainer Agent — documentation updates
7. **Close-out**: Move the feature file to `06_done/`, open a PR with all gate confirmations

## Conventions

- **One feature per file**: Each feature gets its own Markdown file
- **Sequential IDs**: Feature IDs are assigned sequentially and never reused (even for rejected/obsoleted features)
- **WIP limit**: Only one feature should be in `05_implementing/` at a time to maintain focus
- **Atomic moves**: A feature file should exist in exactly one column at any given time
- **Traceability**: Every feature links to at least one accepted requirement in `01_vision/02_requirements/03_accepted/`
- **Acceptance-driven**: A feature cannot leave `02_analyze/` until acceptance criteria are fully defined
- **Update trail**: The `Updated` metadata field serves as a lightweight audit log of transitions

## Relationship to Requirements

Features are the implementation vehicles for requirements:

```
01_vision/02_requirements/03_accepted/req_XXXX_*.md  ←  linked by  →  02_agile_board/*/feature_YYYY_*.md
```

- A single requirement may be fulfilled by multiple features
- A single feature may address multiple requirements
- Features reference requirements via relative links in the **Related Requirements** section
- Requirements do not reference features — the linkage is one-directional (feature → requirement)
