# Requirement: Plugin Process Command Exit Code Interface Contract

- **ID:** REQ_0042
- **State:** Accepted
- **Type:** Non-Functional
- **Priority:** High
- **Created at:** 2026-03-07
- **Last Updated:** 2026-03-07

## Overview
Every plugin that implements a `process` command shall conform to the three-state exit code contract defined in ADR-004, making the plugin interface formally testable and enforceable.

## Description
ADR-004 defines a structured exit code contract for the plugin-framework interface. REQ_0039 captures the framework-side behaviour in response to that contract. This requirement captures the **plugin-side obligation**: any plugin — built-in or third-party — that implements a `process` command must implement exactly the three exit states below and no others.

| Exit Code | Constant (`sysexits.h`) | Meaning | Required stdout |
|-----------|-------------------------|---------|-----------------|
| **0** | `EX_OK` | Successful execution; the plugin produced output | A valid JSON object containing at least the output fields declared in `descriptor.json` |
| **65** | `EX_DATAERR` | Input not supported — intentional skip | `{}` or `{"message": "<human-readable reason>"}` |
| **1** (or any non-zero ≠ 65) | — | Unexpected failure during processing | Any (the framework will not parse it) |

### Rules for Plugin Authors

1. A plugin **MUST** exit 0 when it successfully processes the input and produces output JSON.
2. A plugin **MUST** exit 65 when it determines that the input cannot or will not be handled (e.g., unsupported MIME type, unsupported file structure). It **SHOULD** print `{"message": "<human-readable reason>"}` to stdout to aid debugging.
3. A plugin **MUST** exit with a non-zero code other than 65 (typically 1) when an unexpected error occurs during processing of a supported input.
4. A plugin **MUST NOT** exit 65 for errors that occur while attempting to process a file it agrees to handle — a processing error is a failure (exit 1), not a skip.
5. A plugin **MUST NOT** exit 0 when it performed no processing; a no-op result must be signalled by exit 65.

These rules are the plugin interface contract. Conformance is required for correct framework behaviour and is a precondition for any plugin to be accepted into the plugin collection.

### Rationale for a Formal Requirement
ADR-004 is an architecture decision that captures the *reasoning* behind the exit code design. This requirement makes the exit code contract an observable, traceable, and testable constraint that:
- Can be verified by automated conformance tests;
- Provides a normative basis for code review of new plugins;
- Links traceably from test results back to a requirement ID.

## Motivation
Derived from:
- [ADR-004 Plugin Exit Code and Failure Handling Strategy](../../03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md) — technical decision being formalised as a testable requirement
- [REQ_0039 Silent Skip for Unsupported MIME Types](REQ_0039_silent-skip-unsupported-mime-types.md) — framework-side behaviour that depends on this contract
- [project_management/02_project_vision/01_project_goals/project_goals.md](../../01_project_goals/project_goals.md) — "the framework should recognize that the plugin is not designed to handle that file type and simply skip it"

## Acceptance Criteria
- [ ] The `markitdown` plugin `process` command exits **65** with `{"message": "..."}` when invoked with an unsupported MIME type, and exits **0** with valid JSON when invoked with a supported MIME type
- [ ] The `ocrmypdf` plugin `process` command exits **65** with `{"message": "..."}` when invoked with an unsupported MIME type, and exits **0** with valid JSON when invoked with a supported MIME type
- [ ] The `file` plugin `process` command exits **0** for every regular file it is given (it supports all files) and exits **1** only on a genuine processing error
- [ ] The `stat` plugin `process` command exits **0** for every regular file it is given and exits **1** only on a genuine processing error
- [ ] Any new plugin submitted for inclusion has its exit code behaviour verified against this three-state contract in its feature test (`tests/test_feature_<N>.sh`)
- [ ] The developer guide plugin development section documents this three-state exit code contract as a normative requirement for plugin authors (cross-reference: REQ_0039 AC)

## Related Architecture Decisions
- [ADR-004 Plugin Exit Code and Failure Handling Strategy](../../03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md)

## Related Requirements
- [REQ_0003 Plugin-Based Architecture](REQ_0003_plugin-system.md)
- [REQ_0039 Silent Skip for Unsupported MIME Types](REQ_0039_silent-skip-unsupported-mime-types.md)
- [REQ_0034 Cohesive Plugin Execution Module](REQ_0034_cohesive-plugin-execution-module.md)
