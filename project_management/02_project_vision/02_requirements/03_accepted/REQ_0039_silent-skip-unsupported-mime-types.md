# Requirement: Silent Skip for Unsupported MIME Types

- **ID:** REQ_0039
- **State:** Accepted
- **Type:** Functional
- **Priority:** High
- **Created at:** 2026-03-07
- **Last Updated:** 2026-03-07

## Overview
When a plugin cannot handle a file's MIME type, the framework shall silently skip that file rather than printing an error message.

## Description
During the Document Processing Phase of `doc.doc.sh process`, each active plugin is invoked for every discovered file. Plugins are designed to handle specific MIME types and are expected to decline files outside their supported types. Currently the framework reports this expected decline as an error, e.g.:

```
Error: Plugin 'markitdown' failed for file: README-Screenshot-PNG.png
```

This behaviour is misleading because no actual failure has occurred — the plugin simply does not support that MIME type.

The framework shall distinguish between three distinct plugin exit outcomes, following the exit code contract defined in ADR-004 (aligned with BSD `sysexits.h`):

| Exit Code | Meaning | Framework Action |
|-----------|---------|------------------|
| **0** | Successful execution | Merge JSON output into combined result |
| **65** (`EX_DATAERR`) | Input not supported — intentional skip | Silently discard; no message printed |
| **1** (or other non-zero ≠ 65) | Unexpected failure | Print error message to stderr |

1. **Intentional skip (exit 65):** When a plugin decides it will not handle a particular document (e.g., unsupported MIME type), it MUST exit with code **65** and SHOULD print `{}` or `{"message": "<reason>"}` to stdout. The framework shall silently discard this and continue without printing any message to stdout or stderr.

2. **Actual plugin error (exit 1 or other non-zero ≠ 65):** The plugin encountered an unexpected error while attempting to process the input. The framework shall print a clear error message to stderr.

3. **Success (exit 0):** The plugin produced valid JSON output. The framework merges it into the combined result.

The skip decision is entirely the **plugin's own responsibility**. The framework does not pre-screen files; it simply acts on the exit code.

## Motivation
Derived from:
[project_management/02_project_vision/01_project_goals/project_goals.md](../../01_project_goals/project_goals.md) — TODO 1: "the framework should recognize that the plugin is not designed to handle that file type and simply skip it without printing an error message. The framework should only print error messages for actual errors that occur during plugin execution."

## Acceptance Criteria
- [ ] Running `doc.doc.sh process` against a directory containing files with MIME types unsupported by an active plugin produces no error messages for those files
- [ ] An actual plugin failure (exit 1 or other non-zero ≠ 65) still produces an error message on stderr
- [ ] A plugin that chooses to skip a file exits with code **65** and optionally outputs `{}` or `{"message": "<reason>"}`
- [ ] The framework silently discards an exit-65 result without printing anything to stdout or stderr
- [ ] Existing test suite passes without modification after the fix is applied
- [ ] No regression in processing files whose MIME types are supported by the active plugin
- [ ] The developer guide plugin development section documents the three-state exit code contract (exit 0, exit 65, exit 1), including the `EX_DATAERR`/exit-65 skip convention, so that plugin authors have a normative reference when implementing new plugins

## Related Architecture Decisions
- [ADR-004 Plugin Exit Code and Failure Handling Strategy](../../03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md)

## Related Requirements
- [REQ_0009 Process Command](REQ_0009_process-command.md)
- [REQ_0006 User-Friendly Interface](REQ_0006_user-friendly-interface.md)
- [REQ_0003 Plugin System](REQ_0003_plugin-system.md)
- [REQ_0042 Plugin Process Command Exit Code Interface Contract](REQ_0042_plugin-process-exit-code-contract.md)
