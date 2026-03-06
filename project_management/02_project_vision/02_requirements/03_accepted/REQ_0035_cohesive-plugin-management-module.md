# Requirement: Cohesive Plugin Management Module

- **ID:** REQ_0035
- **State:** Accepted
- **Type:** Non-Functional
- **Priority:** Unset
- **Created at:** 2026-03-06
- **Last Updated:** 2026-03-06

## Overview
The plugin management module shall own exactly: plugin discovery, descriptor loading, and activation/deactivation state; it shall not invoke plugin commands or handle process I/O.

## Description
A dedicated plugin management module (e.g., `components/plugin_mgmt.sh`) shall be the single authoritative source for all lifecycle management of plugins:

1. **Plugin discovery** — locating plugin directories under `doc.doc.md/plugins/`
2. **Descriptor loading** — parsing `descriptor.json` for each plugin and exposing its metadata
3. **Activation state** — reading and writing the activation/deactivation state of each plugin (currently fulfilled by REQ_0029)

The module shall expose functions used by high-level commands such as `list`, `activate`, `deactivate`, `install`, and `plugins` (tree view).

It must not contain any logic for running plugin commands, reading plugin stdout, or classifying exit codes. Those responsibilities belong exclusively to the plugin execution module (REQ_0034).

## Motivation
Derived from the architecture vision:
[project_management/02_project_vision/03_architecture_vision/05_building_block_view/05_building_block_view.md](../../../03_architecture_vision/05_building_block_view/05_building_block_view.md) — Plugin Management building block (Level 1).

## Acceptance Criteria
- [ ] A dedicated plugin management module file exists under `components/`
- [ ] Plugin discovery logic is contained within this module
- [ ] Descriptor loading logic is contained within this module
- [ ] Activation/deactivation state read/write is contained within this module
- [ ] The module contains no command-invocation or exit-code logic
- [ ] `list`, `activate`, `deactivate`, `tree` commands source only the management module (not the execution module) to fulfil their operations

## Related Requirements
- [REQ_0029 Plugin State Storage](../03_accepted/REQ_0029_plugin-state-storage.md)
- [REQ_0033 Separate Plugin Management from Plugin Execution](REQ_0033_separate-plugin-management-execution.md)
- [REQ_0034 Cohesive Plugin Execution Module](REQ_0034_cohesive-plugin-execution-module.md)
- [REQ_0037 Module Interface Contract](REQ_0037_module-interface-contract.md)
- [REQ_SEC_003 Plugin Descriptor Validation](../03_accepted/REQ_SEC_003_plugin_descriptor_validation.md)
