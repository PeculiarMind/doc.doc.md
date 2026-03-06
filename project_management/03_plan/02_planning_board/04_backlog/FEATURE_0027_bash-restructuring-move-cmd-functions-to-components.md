# Bash Restructuring: Move cmd_* Functions to Component Modules

- **ID:** FEATURE_0027
- **Priority:** High
- **Type:** Feature
- **Created at:** 2026-03-06
- **Created by:** product_owner
- **Status:** BACKLOG

## TOC

## Overview
Move all `cmd_*` command functions and their private helpers out of the monolithic `doc.doc.sh` entry point into the appropriate existing component files, without changing any observable behaviour. After this restructuring, `doc.doc.sh` shall contain only `main`, top-level usage strings, global variable declarations, and `source` statements (~450 lines), satisfying the orchestration-isolation requirement REQ_0036.

## Acceptance Criteria
- [ ] `cmd_activate` and `cmd_deactivate` are moved verbatim into `doc.doc.md/components/plugin_management.sh` and are removed from `doc.doc.sh`
- [ ] `cmd_install`, `_install_single_plugin`, `_install_all_plugins`, and `cmd_installed` are moved verbatim into `doc.doc.md/components/plugin_management.sh` and are removed from `doc.doc.sh`
- [ ] `cmd_tree`, `_validate_plugin_dir`, `_list_plugins`, and `cmd_list` are moved verbatim into `doc.doc.md/components/plugin_management.sh` and are removed from `doc.doc.sh`
- [ ] `process_file` is moved verbatim into `doc.doc.md/components/plugin_execution.sh` and is removed from `doc.doc.sh`
- [ ] `doc.doc.sh` retains only `main`, top-level variable declarations, usage/help strings, and `source` statements; its line count does not exceed 450 lines after the move
- [ ] Each receiving component file (`plugin_management.sh`, `plugin_execution.sh`) gains a header comment block listing its updated public interface (satisfying REQ_0037)
- [ ] All existing automated tests in `tests/` pass without modification after the restructuring
- [ ] No change in observable CLI behaviour: all commands (`activate`, `deactivate`, `install`, `installed`, `list`, `tree`, `process`) produce identical output to the pre-refactoring baseline

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
