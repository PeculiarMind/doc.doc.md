# Bug: Spurious Error Messages for Unsupported MIME Types During Processing

- **ID:** BUG_0011
- **Priority:** High
- **Type:** Bug
- **Created at:** 2026-03-07
- **Created by:** Product Owner
- **Status:** BACKLOG

## Overview
When `doc.doc.sh process` runs in interactive process mode, plugins that do not support the MIME type of a given file emit error messages such as:

```
Error: Plugin 'markitdown' failed for file: README-Screenshot-PNG.png
```

This is misleading. The plugin did not fail — it was asked to process a file type it is simply not designed to handle. The framework should silently skip unsupported MIME types and reserve error output for genuine plugin failures.

## Symptoms
Running:
```
./doc.doc.sh process -d ./tests/docs/ -o ./tests/out
```
Produces noise like:
```
Error: Plugin 'markitdown' failed for file: README-Screenshot-PNG.png
Error: Plugin 'ocrmypdf' failed for file: README-MSWORD.docx
```
...even though skipping those file types is correct, expected behavior.

## Root Cause
There are two interacting issues confirmed by code review:

**Issue 1 — `run_plugin` swallows exit codes.** `run_plugin` in `plugin_execution.sh` is called with `||` error absorption, meaning any non-zero exit — including a future exit 65 — never reaches `process_file`. `run_plugin` itself must be refactored to propagate exit codes before `process_file` can branch on them.

**Issue 2 — Plugins emit messages to stderr instead of stdout.** Both `markitdown` and `ocrmypdf` currently print their unsupported-MIME message to **stderr** and exit 1. ADR-004 requires the skip payload (`{}` or `{"message":"..."}`) to be on **stdout** as JSON, and the exit code to be **65**.

## Required Changes (three files)

### 1. `plugin_execution.sh` — Refactor `run_plugin` to propagate exit codes
`run_plugin` must capture and return the plugin's exit code rather than absorbing it. `process_file` then branches as follows:

| Returned exit | Action |
|---------------|--------|
| 0 | Merge stdout JSON into combined result |
| 65 | Silently discard — no message, no merge |
| Any other non-zero | `ui_error "Plugin '...' failed for file: ..."` |

> ⚠️ The `file` plugin fast-path in `process_file` (fail-closed on MIME filter) uses non-zero to abort the whole file early. This special case must remain intact — the `file` plugin never exits 65.

### 2. `markitdown/main.sh` — Switch from exit 1 + stderr to exit 65 + stdout JSON
```bash
# Before:
echo "Unsupported MIME type: $file_mime" >&2; exit 1

# After:
echo '{"message":"skipped due to unsupported mime type"}'; exit 65
```

### 3. `ocrmypdf/main.sh` — Same change as markitdown

## Expected Behaviour (ADR-004 exit code contract)
| Exit Code | Meaning | Framework action |
|-----------|---------|------------------|
| 0 | Success | Merge JSON into combined result |
| 65 (`EX_DATAERR`) | Intentional skip / unsupported input | Silently discard; no error printed |
| 1 (or other non-zero ≠ 65) | Unexpected failure | Print error message to stderr |

## Acceptance Criteria
- [ ] Running `process` against a mixed document collection produces no error output for MIME-type mismatches
- [ ] A genuine plugin failure (exit 1) still produces an error message on stderr
- [ ] `run_plugin` in `plugin_execution.sh` propagates the plugin's exit code without absorbing it
- [ ] `process_file` branches on exit 65 as a silent skip (no merge, no error output)
- [ ] The `file` plugin fast-path (fail-closed on MIME) in `process_file` is unaffected by this change
- [ ] `markitdown/main.sh` exits **65** and prints `{"message":"skipped due to unsupported mime type"}` to **stdout** for unsupported MIME types
- [ ] `ocrmypdf/main.sh` exits **65** and prints `{"message":"skipped due to unsupported mime type"}` to **stdout** for unsupported MIME types
- [ ] Existing tests pass without modification
- [ ] At least one new test validates the silent-skip behavior for exit 65

## Dependencies
- REQ_0039 (Silent Skip for Unsupported MIME Types)
- REQ_0042 (Plugin Process Command Exit Code Interface Contract)

## Related Architecture Decisions
- [ADR-004 Plugin Exit Code Strategy](../../../../project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md)

## Related Links
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0039_silent-skip-unsupported-mime-types.md`
- Architecture Concept: `project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_0007_plugin_mime_type_skip.md`
