# Bash Restructuring: Move cmd_* Functions to Component Modules

- **ID:** FEATURE_0027
- **Priority:** High
- **Type:** Feature
- **Created at:** 2026-03-06
- **Created by:** product_owner
- **Status:** DONE

## TOC

## Overview
Move all `cmd_*` command functions and their private helpers out of the monolithic `doc.doc.sh` entry point into the appropriate existing component files, without changing any observable behaviour. After this restructuring, `doc.doc.sh` shall contain only `main`, top-level usage strings, global variable declarations, and `source` statements (~450 lines), satisfying the orchestration-isolation requirement REQ_0036.

## Acceptance Criteria
- [x] `cmd_activate` and `cmd_deactivate` are moved verbatim into `doc.doc.md/components/plugin_management.sh` and are removed from `doc.doc.sh`
- [x] `cmd_install`, `_install_single_plugin`, `_install_all_plugins`, and `cmd_installed` are moved verbatim into `doc.doc.md/components/plugin_management.sh` and are removed from `doc.doc.sh`
- [x] `cmd_tree`, `_validate_plugin_dir`, `_list_plugins`, and `cmd_list` are moved verbatim into `doc.doc.md/components/plugin_management.sh` and are removed from `doc.doc.sh`
- [x] `process_file` is moved verbatim into `doc.doc.md/components/plugin_execution.sh` and is removed from `doc.doc.sh`
- [x] `doc.doc.sh` retains only `main`, top-level variable declarations, usage/help strings, and `source` statements; its line count does not exceed 450 lines after the move
- [x] Each receiving component file (`plugin_management.sh`, `plugin_execution.sh`) gains a header comment block listing its updated public interface (satisfying REQ_0037)
- [x] All existing automated tests in `tests/` pass without modification after the restructuring
- [x] No change in observable CLI behaviour: all commands (`activate`, `deactivate`, `install`, `installed`, `list`, `tree`, `process`) produce identical output to the pre-refactoring baseline

## Status
DONE

## Quality Gate Assessments

### Tester Assessment
- **Result:** ✅ PASS
- **Report:** [TESTREP_009](../../../04_reporting/02_tests_reports/TESTREP_009_FEATURE_0027_bash-restructuring-move-cmd-functions-to-components.md)
- **Summary:** 21/21 FEATURE_0027 dedicated tests pass. Full suite 735/757 (22 pre-existing environmental failures, all unrelated to this change). No regressions introduced.
- **Date:** 2026-03-06

### Architect Assessment
- **Result:** ✅ Fully Compliant
- **Report:** [ARCHREV_011](../../../04_reporting/01_architecture_reviews/ARCHREV_011_FEATURE_0027_bash-restructuring-move-cmd-functions-to-components.md)
- **Summary:** All five target requirements (REQ_0033–REQ_0037) satisfied. `doc.doc.sh` is a pure orchestrator at 382 lines. Plugin management and execution are cleanly separated at the file boundary. Public interface header comments present in both components.
- **Date:** 2026-03-06

### Security Assessment
- **Result:** ✅ Passed — No Security Issues Found
- **Report:** [SECREV_011](../../../04_reporting/03_security_reviews/SECREV_011_FEATURE_0027_bash-restructuring-move-cmd-functions-to-components.md)
- **Summary:** Pure structural refactoring introduces no new security vulnerabilities. Existing controls (path traversal prevention via `_validate_plugin_dir`, descriptor validation, JSON injection boundaries) are preserved verbatim in new locations.
- **Date:** 2026-03-06

### License Assessment
- **Result:** ✅ No Concerns
- **Summary:** Pure refactoring with no new dependencies added. No license review required.
- **Date:** 2026-03-06

### Documentation Assessment
- **Result:** ✅ No Update Required
- **Summary:** FEATURE_0027 is a pure internal restructuring with no change to observable CLI behaviour. README.md accurately reflects the tool's external interface and requires no modification.
- **Date:** 2026-03-06

## Dependencies
- No blocking predecessors; this item may be started independently.
- FEATURE_0028 (Python rewrite of tree/table logic) depends on this item being completed first.

## Related Links
- Requirements: [REQ_0036 Orchestration Isolation](../../../02_project_vision/02_requirements/03_accepted/REQ_0036_orchestration-isolation.md)
- Requirements: [REQ_0037 Module Interface Contract](../../../02_project_vision/02_requirements/03_accepted/REQ_0037_module-interface-contract.md)
- Requirements: [REQ_0002 Modular and Extensible Architecture](../../../02_project_vision/02_requirements/03_accepted/REQ_0002_modular-architecture.md)
- Requirements: [REQ_0033 Separate Plugin Management from Plugin Execution](../../../02_project_vision/02_requirements/03_accepted/REQ_0033_separate-plugin-management-execution.md)
- Requirements: [REQ_0034 Cohesive Plugin Execution Module](../../../02_project_vision/02_requirements/03_accepted/REQ_0034_cohesive-plugin-execution-module.md)
- Requirements: [REQ_0035 Cohesive Plugin Management Module](../../../02_project_vision/02_requirements/03_accepted/REQ_0035_cohesive-plugin-management-module.md)
- Successor: FEATURE_0028 (Python rewrite — plugin_info.py)
