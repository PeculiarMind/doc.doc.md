
# Plugin Descriptor Must Not Declare Explicit `dependencies` Attribute

- **ID:** BUG_0005
- **Priority:** Medium
- **Type:** Bug
- **Created at:** 2026-03-04
- **Created by:** product_owner
- **Status:** BACKLOG

## TOC

## Overview

The `ocrmypdf` plugin descriptor (`descriptor.json`) contains an explicit `"dependencies"` attribute listing other plugins (e.g. `"file"`). This attribute must not exist in plugin descriptors. The dependency graph between plugins must be derived exclusively from the declared `input` and `output` parameters of each plugin command — if the output type of one plugin matches the input type of another, a dependency edge is inferred automatically.

Allowing hand-written `dependencies` fields creates a second, inconsistent source of truth, can introduce cycles or phantom dependencies, and bypasses the type-based chaining logic that `doc.doc.md` is designed around.

Affected file: `doc.doc.md/plugins/ocrmypdf/descriptor.json`

## Acceptance Criteria

- [ ] The `"dependencies"` attribute is removed from all plugin descriptor files (starting with `ocrmypdf/descriptor.json`).
- [ ] `doc.doc.md` does not read or evaluate any `"dependencies"` key in plugin descriptors.
- [ ] The dependency/execution order between plugins is determined solely by matching `output` parameter types to `input` parameter types across plugin commands.
- [ ] Existing behaviour of the `ocrmypdf` → `file` chain is preserved after the removal of the explicit attribute.
- [ ] All existing tests pass after the change.
- [ ] Descriptor schema documentation (if any) is updated to explicitly state that `dependencies` is a forbidden key.

## Dependencies

None

## Related Links

- Architecture Vision: `project_management/02_project_vision/03_architecture_vision/`
- Requirements: `project_management/02_project_vision/02_requirements/`
- Security Concept: —
- Test Plan: —
