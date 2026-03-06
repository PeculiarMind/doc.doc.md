# Requirement: Separate UI Module

- **ID:** REQ_0032
- **State:** Accepted
- **Type:** Non-Functional
- **Priority:** Unset
- **Created at:** 2026-03-06
- **Last Updated:** 2026-03-06

## Overview
The UI concerns (CLI argument parsing, help display, progress indication, and logging) shall be isolated from orchestration logic in a dedicated UI module.

## Description
Currently, UI responsibilities are scattered across `doc.doc.sh` and loose component files (`components/help.sh`, `components/logging.sh`). These responsibilities correspond to the **UI building block** defined in the architecture vision and shall be grouped into a cohesive module (e.g., `components/ui.sh` or a formal `components/ui/` directory).

The module must cover all four Level-2 sub-blocks of the UI building block:
1. **CLI** — argument parsing and option validation presentation
2. **Help** — usage text, examples, and context-sensitive help output
3. **Progress** — progress indication during processing
4. **Logging** — status, warning, and error message output

Orchestration code in `doc.doc.sh` shall call into this module via its interface rather than implementing any of these concerns inline.

## Motivation
Derived from the architecture vision:
[project_management/02_project_vision/03_architecture_vision/05_building_block_view/05_building_block_view.md](../../../03_architecture_vision/05_building_block_view/05_building_block_view.md) — UI building block (Level 1 and Level 2 decomposition).

The goal is to improve testability of UI logic in isolation and to enable future replacement of individual UI sub-blocks without touching orchestration or processing logic.

## Acceptance Criteria
- [ ] A dedicated UI module file or directory exists under `components/`
- [ ] All help output logic is sourced exclusively from the UI module
- [ ] All logging/status output functions are sourced exclusively from the UI module
- [ ] Progress indication is sourced exclusively from the UI module
- [ ] `doc.doc.sh` contains no inline help-text strings or logging-format logic
- [ ] The UI module can be sourced independently without loading plugin or template modules

## Related Requirements
- [REQ_0002 Modular Architecture](../03_accepted/REQ_0002_modular-architecture.md)
- [REQ_0036 Orchestration Isolation](REQ_0036_orchestration-isolation.md)
- [REQ_0037 Module Interface Contract](REQ_0037_module-interface-contract.md)
- [REQ_0038 Backward-Compatible CLI](REQ_0038_backward-compatible-cli.md)
