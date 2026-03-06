# Requirement: Backward-Compatible CLI After Refactoring

- **ID:** REQ_0038
- **State:** Accepted
- **Type:** Non-Functional
- **Priority:** Unset
- **Created at:** 2026-03-06
- **Last Updated:** 2026-03-06

## Overview
The structural refactoring to decompose the codebase into building-block modules shall not change any existing CLI commands, options, flags, or user-visible output formats.

## Description
The refactoring described by REQ_0032–REQ_0036 is an internal restructuring exercise. From the perspective of any user or external script that invokes `doc.doc.sh`, the tool's behaviour must remain identical before and after the refactoring:

- All existing commands (`process`, `list`, `activate`, `deactivate`, `install`, `plugins`, etc.) must continue to work with the same option names and semantics.
- All existing output formats (text output to stdout, exit codes) must be preserved.
- No new mandatory arguments may be introduced.
- No existing optional arguments may be removed or renamed.
- The `--help` output may be reformatted but must cover at minimum the same commands and options as before.

This requirement acts as a non-regression constraint on all refactoring work.

## Motivation
Derived from the architecture vision:
[project_management/02_project_vision/03_architecture_vision/05_building_block_view/05_building_block_view.md](../../../03_architecture_vision/05_building_block_view/05_building_block_view.md) — the Core System is the stable CLI contract surface.

Also derived from:
[project_management/02_project_vision/01_project_goals/project_goals.md](../../01_project_goals/project_goals.md) — the tool shall be reliable and backward-compatible for existing users.

## Acceptance Criteria
- [ ] All existing test suite files in `tests/` pass without modification after the refactoring
- [ ] `doc.doc.sh --help` lists all commands documented before the refactoring
- [ ] `doc.doc.sh process`, `list`, `activate`, `deactivate`, `install`, and `plugins` commands produce output structurally identical to pre-refactoring output
- [ ] No shell script that previously invoked `doc.doc.sh` requires modification after the refactoring
- [ ] Exit codes for all commands are unchanged

## Related Requirements
- [REQ_0001 Command-Line Tool](../03_accepted/REQ_0001_command-line-tool.md)
- [REQ_0032 Separate UI Module](REQ_0032_separate-ui-module.md)
- [REQ_0036 Orchestration Isolation](REQ_0036_orchestration-isolation.md)
- [REQ_0009 Process Command](../03_accepted/REQ_0009_process-command.md)
- [REQ_0021 List Plugins](../03_accepted/REQ_0021_list-plugins.md)
- [REQ_0024 Activate Plugin](../03_accepted/REQ_0024_activate-plugin.md)
- [REQ_0025 Deactivate Plugin](../03_accepted/REQ_0025_deactivate-plugin.md)
