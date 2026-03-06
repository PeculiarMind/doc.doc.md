# Requirement: Module Interface Contract

- **ID:** REQ_0037
- **State:** Accepted
- **Type:** Non-Functional
- **Priority:** Unset
- **Created at:** 2026-03-06
- **Last Updated:** 2026-03-06

## Overview
Each building-block module shall expose a documented, stable interface; callers shall depend only on that interface, not on internal implementation details.

## Description
For each module introduced by the codebase decomposition (UI, Plugin Management, Plugin Execution, Template Management, Python Filter Engine), an interface contract shall be defined and documented. A "module interface" for a Bash component consists of:

1. **Public function list** — the set of functions external callers are permitted to invoke, explicitly listed in the module file header
2. **Function signatures** — parameter names, expected types/formats, and return values (exit code and stdout contract)
3. **Side-effect declaration** — any global variables read or written, files touched, or environment assumptions

Functions not listed as part of the public interface are considered internal and may be changed without notice. Callers must not invoke internal functions.

This contract enables individual modules to be replaced, refactored, or extended without requiring changes to callers, and provides the foundation for unit testing in isolation.

## Motivation
Derived from the architecture vision:
[project_management/02_project_vision/03_architecture_vision/05_building_block_view/05_building_block_view.md](../../../03_architecture_vision/05_building_block_view/05_building_block_view.md) — all Level-1 building blocks define explicit Interfaces sections.

## Acceptance Criteria
- [ ] Each module file contains a header comment block listing its public interface functions
- [ ] Each public function has an inline comment documenting its parameters and return contract
- [ ] At least one automated test exists that exercises each module exclusively through its public interface
- [ ] Internal (non-public) functions are prefixed or otherwise marked to distinguish them from public ones
- [ ] The developer guide references the interface contract convention

## Related Requirements
- [REQ_0032 Separate UI Module](REQ_0032_separate-ui-module.md)
- [REQ_0033 Separate Plugin Management from Plugin Execution](REQ_0033_separate-plugin-management-execution.md)
- [REQ_0034 Cohesive Plugin Execution Module](REQ_0034_cohesive-plugin-execution-module.md)
- [REQ_0035 Cohesive Plugin Management Module](REQ_0035_cohesive-plugin-management-module.md)
- [REQ_0036 Orchestration Isolation](REQ_0036_orchestration-isolation.md)
- [REQ_0002 Modular Architecture](../03_accepted/REQ_0002_modular-architecture.md)
