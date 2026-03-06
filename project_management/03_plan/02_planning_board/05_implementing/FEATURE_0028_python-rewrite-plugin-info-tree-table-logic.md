# Python Rewrite: New plugin_info.py Component for Tree and Table Logic

- **ID:** FEATURE_0028
- **Priority:** Medium
- **Type:** Feature
- **Created at:** 2026-03-06
- **Created by:** product_owner
- **Status:** IMPLEMENTING

## TOC

## Overview
Rewrite the complex logic of `cmd_tree` (~200 Bash lines: DFS dependency graph, cycle detection, ASCII tree rendering) and the parameter/command table formatting currently in `cmd_list` (~80 Bash lines: jq `@tsv` pipelines and `column -t`) as a new Python component `doc.doc.md/components/plugin_info.py`. The Bash `cmd_tree` and `cmd_list` table-formatting paths become thin wrapper calls to `python3 plugin_info.py`. This eliminates the `bsdextrautils` (`column`) system dependency and makes graph and table logic unit-testable as pure Python, advancing the modular-architecture goal of REQ_0002 and the orchestration-isolation goal of REQ_0036.

**Prerequisite:** FEATURE_0027 must be completed and merged before starting this item.

## Acceptance Criteria
- [x] A new file `doc.doc.md/components/plugin_info.py` exists and implements at minimum two callable modes: `tree <plugins_dir>` (DFS graph traversal with cycle detection and ASCII rendering) and `table <json_input>` (column-aligned table formatting for plugin command/parameter lists)
- [x] `bsdextrautils` (i.e. the `column` command) is no longer required at runtime; the `column -t` invocation is removed from `plugin_management.sh` in favour of a call to `plugin_info.py`
- [x] The Bash `cmd_tree` function (moved to `plugin_management.sh` by FEATURE_0027) is refactored into a thin wrapper that invokes `python3 .../plugin_info.py tree`; all DFS, cycle-detection, and rendering logic lives exclusively in Python
- [x] The `plugin_info.py` tree and table functions are covered by at least five Python unit tests (using `unittest` or `pytest`) that do not require a shell environment
- [x] All existing automated tests in `tests/` (shell-level integration tests) continue to pass without modification after the rewrite, confirming backward-compatible CLI output (REQ_0038)
- [x] `plugin_info.py` carries a header comment defining its public CLI interface (argument syntax, exit codes, stdout contract) consistent with REQ_0037
- [x] A graceful error is produced (non-zero exit, human-readable message to stderr) when `plugin_info.py` is invoked with an invalid or missing plugins directory, or malformed JSON input

## Dependencies
- **Blocked by FEATURE_0027**: `cmd_tree` and `cmd_list` must reside in `plugin_management.sh` before this item can refactor them into thin wrappers. Do not begin implementation until FEATURE_0027 is in state DONE.

## Related Links
- Requirements: [REQ_0036 Orchestration Isolation](../../../02_project_vision/02_requirements/03_accepted/REQ_0036_orchestration-isolation.md)
- Requirements: [REQ_0037 Module Interface Contract](../../../02_project_vision/02_requirements/03_accepted/REQ_0037_module-interface-contract.md)
- Requirements: [REQ_0002 Modular and Extensible Architecture](../../../02_project_vision/02_requirements/03_accepted/REQ_0002_modular-architecture.md)
- Requirements: [REQ_0035 Cohesive Plugin Management Module](../../../02_project_vision/02_requirements/03_accepted/REQ_0035_cohesive-plugin-management-module.md)
- Requirements: [REQ_0028 Plugin Tree View](../../../02_project_vision/02_requirements/03_accepted/REQ_0028_plugin-tree-view.md)
- Requirements: [REQ_0038 Backward-Compatible CLI](../../../02_project_vision/02_requirements/03_accepted/REQ_0038_backward-compatible-cli.md)
- Predecessor: FEATURE_0027 (Bash restructuring — move cmd_* to components)
