# Feature: file Plugin — ADR-004 Exit Code Compliance Verification

- **ID:** FEATURE_0035
- **Priority:** Medium
- **Type:** Feature
- **Created at:** 2026-03-07
- **Created by:** Product Owner
- **Status:** BACKLOG

## Overview
Verify that the `file` plugin's `process` command is formally compliant with the three-state exit code contract defined in ADR-004, update its code documentation to reference the contract, and add a dedicated conformance test. The `file` plugin handles every regular file regardless of MIME type, so exit 65 (intentional skip) is explicitly not applicable — but exits 0 and 1 must be formally verified and annotated.

## Motivation
ADR-004 is the authoritative exit code contract. REQ_0042 requires every built-in plugin to have its exit code behaviour verified against that contract. The `file` plugin is currently behaviorally compliant (exits 0 on success, 1 on error) but this compliance is implicit and untested against the formal contract. Code comments reference only `"0 on success, 1 on error"` without naming ADR-004, and no dedicated conformance test exists.

## Implementation Notes (from architecture review)

The `file` plugin processes **all** MIME types. It uses the `file --mime-type` command to determine MIME type and outputs `{"mimeType":"..."}`. It has no unsupported-MIME path, so exit 65 is structurally impossible and must remain so.

**Change — `file/main.sh`: update header comment**
```bash
# Exit codes: 0 success (EX_OK), 1 failure — exit 65 not applicable (all file types handled)
# Exit code contract: ADR-004 (project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md)
```

No logic changes are expected. Before the feature is closed, the developer must confirm by reading `file/main.sh` end-to-end that no code path returns exit 65 or any exit code other than 0 and 1.

**Test structure (`tests/test_feature_0035.sh`):**

| Scenario | Input | Expected exit | Expected stdout |
|---|---|---|---|
| Readable regular file (any MIME type) | valid `filePath` | 0 | `{"mimeType":"..."}` (non-empty) |
| Missing file | non-existent `filePath` | 1 | any (stderr contains error) |
| Restricted path | `/proc/1/mem` | 1 | any (stderr contains error) |

## Acceptance Criteria
- [ ] `file/main.sh` process command exits **0** for every readable regular file, regardless of MIME type; stdout is a valid JSON object containing `mimeType`
- [ ] `file/main.sh` process command exits **1** for unreadable, missing, or restricted-path inputs; an error message is written to stderr
- [ ] Exit **65** is never returned by this plugin's process command (all file types are handled — no skip case)
- [ ] The header comment in `file/main.sh` references ADR-004, states exit 65 is not applicable, and explains why
- [ ] `tests/test_feature_0035.sh` verifies exit 0 (success), exit 1 (error), and explicitly asserts exit 65 is never produced for any test input
- [ ] Existing tests pass without modification

## Dependencies
- REQ_0042 (Plugin Process Command Exit Code Interface Contract)

## Related Links
- Architecture Decision: `project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md`
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0042_plugin-process-exit-code-contract.md`
