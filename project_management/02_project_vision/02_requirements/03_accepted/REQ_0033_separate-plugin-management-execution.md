# Requirement: Separate Plugin Management from Plugin Execution

- **ID:** REQ_0033
- **State:** Accepted
- **Type:** Non-Functional
- **Priority:** Unset
- **Created at:** 2026-03-06
- **Last Updated:** 2026-03-06

## Overview
Plugin management responsibilities and plugin execution responsibilities currently mixed in `components/plugins.sh` shall be separated into two distinct modules.

## Description
`components/plugins.sh` currently serves as a single file that conflates two architecturally distinct concerns:

- **Plugin Management**: discovering plugins, loading descriptors, reading/writing activation state
- **Plugin Execution**: invoking plugin commands, handling stdin/stdout, classifying exit codes, validating output

The architecture vision defines these as separate Level-1 building blocks (**Plugin Management** and **Plugin Execution**). The refactoring shall split `components/plugins.sh` into (at minimum) two files, one per building block.

Neither file shall contain responsibilities that belong to the other: the management module must not invoke plugin commands, and the execution module must not read or write activation state.

## Motivation
Derived from the architecture vision:
[project_management/02_project_vision/03_architecture_vision/05_building_block_view/05_building_block_view.md](../../../03_architecture_vision/05_building_block_view/05_building_block_view.md) — Plugin Management and Plugin Execution building blocks (Level 1).

Separation enables independent testing, future sandboxing of execution without touching management logic, and clearer ownership of each concern.

## Acceptance Criteria
- [ ] `components/plugins.sh` is replaced by (at minimum) two separate files
- [ ] One file contains only plugin management logic (discovery, descriptor loading, activation state)
- [ ] One file contains only plugin execution logic (invocation, I/O, exit-code handling, output validation)
- [ ] No management-layer function calls a plugin command
- [ ] No execution-layer function reads or writes the activation state store
- [ ] Existing integration tests pass without modification after the split

## Related Requirements
- [REQ_0002 Modular Architecture](../03_accepted/REQ_0002_modular-architecture.md)
- [REQ_0003 Plugin System](../03_accepted/REQ_0003_plugin-system.md)
- [REQ_0034 Cohesive Plugin Execution Module](REQ_0034_cohesive-plugin-execution-module.md)
- [REQ_0035 Cohesive Plugin Management Module](REQ_0035_cohesive-plugin-management-module.md)
- [REQ_0037 Module Interface Contract](REQ_0037_module-interface-contract.md)
