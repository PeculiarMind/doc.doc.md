# Bug: markitdown Plugin Discards Underlying Error on Failure

- **ID:** BUG_0012
- **Priority:** Medium
- **Type:** Bug
- **Created at:** 2026-03-08
- **Created by:** Tester
- **Status:** DONE

## TOC
1. [Overview](#overview)
2. [Symptoms](#symptoms)
3. [Root Cause](#root-cause)
4. [Expected Behaviour](#expected-behaviour)
5. [Steps to Reproduce](#steps-to-reproduce)
6. [Acceptance Criteria](#acceptance-criteria)
7. [Dependencies](#dependencies)
8. [Related Links](#related-links)

## Overview

When the `markitdown` CLI binary crashes or fails during document processing, `markitdown/main.sh` captures its stderr into a temporary file but then **deletes that file without forwarding its content**. The user receives only a generic `Error: markitdown conversion failed` with no indication of the underlying cause.

> **Note:** Under the project goals, the `process` command's **Validation Phase** (step 1 / 1.1) is responsible for detecting missing plugin binaries *before* execution begins — offering the user the choice to skip, abort, or install the plugin. This bug therefore focuses on runtime failures that occur **after** validation passes: e.g. the binary is found but crashes, returns a non-zero exit code, or produces an error for a specific input.

## Symptoms

Running the plugin directly against a file that causes the binary to fail:
```
echo '{"filePath":"./tests/docs/README-MSWORD.docx","mimeType":"application/vnd.openxmlformats-officedocument.wordprocessingml.document"}' \
  | bash doc.doc.md/plugins/markitdown/main.sh
```
Produces:
```
Error: markitdown conversion failed
```
…with no indication of the actual failure reason (conversion error, corrupt file, unsupported format, etc.).

Likewise, when invoked via `doc.doc.sh process` and the binary fails on a specific document:
```
Error: Plugin 'markitdown' failed for file: README-MSWORD.docx
```
…again without any diagnostic detail.

## Root Cause

In `doc.doc.md/plugins/markitdown/main.sh`, stderr from the `markitdown` invocation is redirected to a temp file:

```bash
_mkd_err_file="$(mktemp)"
if ! document_text="$(markitdown "$canonical_path" 2>"$_mkd_err_file")"; then
  echo "Error: markitdown conversion failed" >&2
  rm -f "$_mkd_err_file"        # ← temp file deleted without being read
  exit 1
fi
rm -f "$_mkd_err_file"
```

The failure branch prints a static error string and immediately deletes the temp file — the actual cause is never surfaced to the user or to the framework.

## Expected Behaviour

When `markitdown` exits non-zero during document processing, `main.sh` should forward the captured stderr content to its own stderr before exiting, so the user can diagnose the failure. For example:

```
Error: markitdown conversion failed: <content of captured stderr>
```

At minimum, the contents of the captured stderr file must be relayed before the file is deleted. If the captured stderr is empty, a fallback message indicating the exit code should be printed.

The fix must not interfere with the Validation Phase: detection of a missing binary remains the responsibility of `installed.sh` and the `process` validation flow (which directs the user to `sudo ./doc.doc.sh install --plugin markitdown` when the binary is absent).

## Steps to Reproduce

1. Ensure `markitdown` **is** installed but invoke it against an input that causes it to fail (e.g. a corrupt or unsupported file, or a temporary wrapper script that exits non-zero).
2. Run the plugin directly or via `./doc.doc.sh process -d ./tests/docs/ -o ./tests/out`.
3. Observe: the error message gives no hint of the underlying failure reason.

## Acceptance Criteria

- [ ] When `markitdown` exits non-zero, `main.sh` forwards the captured stderr content to its own stderr before exiting
- [ ] If captured stderr is empty, the error message includes the exit code (e.g. `Error: markitdown conversion failed (exit code: 2)`)
- [ ] The error message clearly indicates the underlying failure
- [ ] The temp file is always cleaned up (no leaks on the success or failure path)
- [ ] Existing tests pass without modification
- [ ] A test validates that when `markitdown` fails on a document, the plugin exits 1 and the error output contains a meaningful diagnostic message

## Dependencies

None.

## Related Links

- `doc.doc.md/plugins/markitdown/main.sh`
- ADR-004 exit code contract: `project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md`
- Related: `BUG_0006_markitdown_plugin_missing_stdin_size_limit.md`
- Related: `FEATURE_0033_markitdown-plugin-adr004-exit-code-compliance.md`
