
# Plugin Descriptor Must Not Declare Explicit `dependencies` Attribute

- **ID:** BUG_0005
- **Priority:** Medium
- **Type:** Bug
- **Created at:** 2026-03-04
- **Created by:** product_owner
- **Status:** DONE

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

## Workflow Assessment Log

### Step 5: Tester Assessment
- **Date:** 2026-03-05
- **Agent:** tester.agent
- **Result:** PASS
- **Report:** [TESTREP_003](../../../04_reporting/02_tests_reports/TESTREP_003_BUG_0005_plugin_descriptor_dependencies.md)
- **Summary:** All 10 tests pass. `dependencies` attribute removed from all plugin descriptors; `tree` command correctly derives `ocrmypdf → file` dependency via I/O parameter name matching. All existing regression test suites (47+63+52+28 tests) continue to pass.

### Step 6: Architect Assessment
- **Date:** 2026-03-05
- **Agent:** architect.agent
- **Result:** PASS
- **Report:** [ARCHREV_005](../../../04_reporting/01_architecture_reviews/ARCHREV_005_BUG_0005_remove_dependencies_attribute.md)
- **Summary:** Implementation fully compliant with ADR-003 and ARC-0003. `dependencies` key removed; dependency graph now derived exclusively from `input`/`output` parameter name matching. `ocrmypdf → file` chain preserved. Single source of truth enforced.

### Step 7: Security Assessment
- **Date:** 2026-03-05
- **Agent:** security.agent
- **Result:** PASS
- **Report:** [SECREV_005](../../../04_reporting/03_security_reviews/SECREV_005_BUG_0005_remove_dependencies_attribute.md)
- **Summary:** No security issues found. Removal of the `dependencies` attribute eliminates a potential phantom-dependency injection vector; no new attack surface introduced.

### Step 8: License Assessment
- **Date:** 2026-03-05
- **Agent:** license.agent
- **Result:** PASS
- **Summary:** No new code files, no new dependencies, and no third-party content introduced. Change is purely a deletion of a JSON attribute and internal logic refactoring. No CREDITS.md update required. Full compatibility with project AGPL-3.0 license maintained.

### Step 9: Documentation Assessment
- **Date:** 2026-03-05
- **Agent:** documentation.agent
- **Result:** PASS
- **Summary:** README.md already documents type-based dependency derivation ("Execution order is derived automatically by matching output parameter names of one plugin to input parameter names of another — no explicit dependency declarations in descriptors"). No documentation changes required for this item.
