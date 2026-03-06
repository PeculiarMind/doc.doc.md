# Bug: JSON Data Stream Pollutes stdout During Interactive Process Run

- **ID:** BUG_0010
- **Priority:** High
- **Type:** Bug
- **Created at:** 2026-03-06
- **Created by:** Tester
- **Status:** IMPLEMENTING
- **Assigned to:** developer

## Overview
When `./doc.doc.sh process -d <input> -o <output>` is executed in an interactive terminal, a raw JSON array of all plugin results is printed to **stdout** while progress/log messages are printed to **stderr**. A terminal displays both streams simultaneously, so the user sees a confusing interleaving of JSON data fragments and human-readable progress lines.

## Symptoms
Running:
```
./doc.doc.sh process -d ./tests/docs/ -o ./tests/out
```
Produces output similar to:
```
Error: Plugin 'markitdown' failed for file: README-MSWORD.docx
[
{
  "filePath": "...",
  "mimeType": "...",
  ...
}
Processed: ./tests/docs/README-MSWORD.docx -> .../tests/out/...
,
{
  "filePath": "...",
  ...
}
Processed: ./tests/docs/README-PDF.pdf -> .../tests/out/...
...
]
Processed 5 documents.
```

The `[`, JSON objects, `,` separators, and `]` (stdout) mix with `Error:`/`Processed:` lines (stderr), creating unreadable noise for the user.

## Root Cause
`doc.doc.sh` always emits the full JSON result array to **stdout** unconditionally:
```bash
echo "["
echo "$result"         # each file's merged plugin JSON
echo ","
echo "]"
```
There is no TTY check on stdout — the command already guards progress display with `[ -t 2 ]` (stderr is a TTY), but never suppresses JSON when `[ -t 1 ]` (stdout is a TTY).

When the user specifies `-o <dir>`, the markdown files written to disk are the intended output; the JSON stream is only useful when stdout is piped to another tool (Unix pipeline use). Printing it to a terminal is unintended noise.

## Expected Behaviour
- When stdout is **not** a TTY (piped / redirected): JSON array continues to stream to stdout as today (backward-compatible Unix pipeline behaviour).
- When stdout **is** a TTY (interactive terminal) AND `-o <dir>` is given: JSON is **not** printed to stdout; only the human-readable summary (`Processed N documents.`) is shown on stderr.
- A `--json` flag (or similar) can be added in future to force JSON to stdout even in a TTY.

## Steps to Reproduce
1. `./doc.doc.sh process -d ./tests/docs/ -o ./tests/out` in any interactive terminal.
2. Observe stdout — JSON fragments appear interleaved with stderr log messages.

## Acceptance Criteria
- [ ] Running `process -d <input> -o <output>` in a **non-TTY** context (stdout piped to `cat`) still produces a valid JSON array on stdout (pipeline compatibility preserved).
- [ ] Running `process -d <input> -o <output>` in a **TTY** context produces **no** JSON on stdout; only the summary line appears on stderr.
- [ ] All existing `process` tests pass (REQ_0038 backward compatibility).
- [ ] A new test verifies the TTY-suppression behaviour using a pseudo-TTY or non-TTY pipe.

## Dependencies
- REQ_0009 (Process Command)
- REQ_0038 (Backward-Compatible CLI)
- FEATURE_0026 (Interactive Progress Display — related stdout/stderr separation)

## Related Links
- Source: `doc.doc.sh` (process command JSON printing block ~line 1095–1165)
- Component: `doc.doc.md/components/ui.sh` (`log_processed`)
- Test reference: `tests/test_feature_0019.sh` (process output directory)

## License Assessment

- **Status:** PASS
- **Date:** 2026-03-06
- **Finding:** No new dependencies, third-party code, or assets introduced. Pure bash implementation using standard POSIX/bash built-ins (`[ -t 1 ]` TTY check and conditional `echo` statements). No changes to `CREDITS.md` or `LICENSE.md` required. All modifications remain within the existing AGPL-3.0 project scope.
