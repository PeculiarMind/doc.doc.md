# Requirement: Orchestration Isolation in doc.doc.sh

- **ID:** REQ_0036
- **State:** Accepted
- **Type:** Non-Functional
- **Priority:** Unset
- **Created at:** 2026-03-06
- **Last Updated:** 2026-03-06

## Overview
`doc.doc.sh` shall contain only high-level workflow coordination and shall delegate all UI, plugin management, plugin execution, template management, and filter operations to their respective modules.

## Description
Currently `doc.doc.sh` is a monolithic script that directly implements argument parsing, help text, logging, plugin loading, plugin dispatch, template rendering, and filtering. After the refactoring it shall serve solely as:

- The command-line entry point
- The top-level command router (dispatching `process`, `list`, `activate`, `deactivate`, `install`, `plugins`, etc.)
- The workflow coordinator (ordering calls to the specialised modules)

All implementation detail shall live in the dedicated modules:

| Concern | Delegated to |
|---------|-------------|
| Argument parsing, help, logging, progress | UI module (REQ_0032) |
| Plugin discovery, descriptor, state | Plugin Management module (REQ_0035) |
| Plugin command invocation, I/O, exit codes | Plugin Execution module (REQ_0034) |
| Template resolution and substitution | Template Management component |
| Include/exclude filtering | Python Filter Engine (`components/filter.py`) |

`doc.doc.sh` shall source or invoke these modules; it shall contain no inline implementation of their respective concerns.

## Motivation
Derived from the architecture vision:
[project_management/02_project_vision/03_architecture_vision/05_building_block_view/05_building_block_view.md](../../../03_architecture_vision/05_building_block_view/05_building_block_view.md) — Main Entry Point / Core System (doc.doc.sh) Level-2 responsibilities.

## Acceptance Criteria
- [ ] `doc.doc.sh` sources (or delegates to) at least four distinct module files at runtime
- [ ] `doc.doc.sh` contains no inline help text, logging format strings, or plugin-invocation logic
- [ ] Removing any single module source line causes only that module's functionality to break, not unrelated functionality
- [ ] A code review confirms no cross-cutting implementation in `doc.doc.sh` beyond routing and sequencing

## Related Requirements
- [REQ_0032 Separate UI Module](REQ_0032_separate-ui-module.md)
- [REQ_0033 Separate Plugin Management from Plugin Execution](REQ_0033_separate-plugin-management-execution.md)
- [REQ_0034 Cohesive Plugin Execution Module](REQ_0034_cohesive-plugin-execution-module.md)
- [REQ_0035 Cohesive Plugin Management Module](REQ_0035_cohesive-plugin-management-module.md)
- [REQ_0037 Module Interface Contract](REQ_0037_module-interface-contract.md)
- [REQ_0002 Modular Architecture](../03_accepted/REQ_0002_modular-architecture.md)
