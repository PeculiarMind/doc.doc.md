# WC Word Count Plugin

- **ID:** FEATURE_0048
- **Priority:** LOW
- **Type:** Feature
- **Created at:** 2026-03-15
- **Created by:** Product Owner
- **Status:** FUNNEL

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

Implement a `wc` plugin that wraps the standard Unix `wc` tool to count lines, words, and characters in a document's **pre-extracted text content**. The plugin operates as a standard stateless pipeline plugin: it reads the text already produced by an upstream plugin (e.g. `markitdown`, `ocrmypdf`) from the accumulated pipeline JSON and counts its lines, words, and characters — without performing any file I/O of its own.

**Business Value:**
- Enriches sidecar `.md` files with basic content metrics (word count, line count, character count) of the document's extracted text, without any additional file access
- Useful for filtering, sorting, and at-a-glance sizing of document content in the output collection
- Trivially installable — `wc` is part of GNU coreutils and available on all target platforms with no `install` step

**What this delivers:**
- `wc` plugin under `doc.doc.md/plugins/wc/` following the standard plugin structure (`descriptor.json`, `main.sh`, `install.sh`, `installed.sh`)
- `main.sh` receives accumulated pipeline JSON on stdin, selects available text (`textContent` → `ocrText` → `documentText`, first non-empty), pipes it to `wc`, and returns `lineCount`, `wordCount`, and `charCount` in the JSON output
- If no text field is available in the pipeline context, the plugin exits with code 65 (skip — ADR-004)
- `installed.sh` verifies `wc` is available on PATH (always true on Unix; included for protocol compliance)

## Acceptance Criteria

### Plugin Structure
- [ ] Plugin directory `doc.doc.md/plugins/wc/` contains `descriptor.json`, `main.sh`, `install.sh`, and `installed.sh`
- [ ] All scripts are executable (`chmod +x`)
- [ ] `descriptor.json` declares `name`, `version`, `description`, `active` flag, `dependencies`, and a `process` command with `input`/`output` JSON schemas
- [ ] `descriptor.json` passes the existing plugin descriptor validation (REQ_SEC_003)

### process Command (`main.sh`)
- [ ] Reads accumulated pipeline JSON from stdin
- [ ] Selects text input using the following priority order: `textContent` → `ocrText` → `documentText`; uses the first non-empty field found
- [ ] If none of those fields are present or all are empty, exits with code 65 (skip — ADR-004)
- [ ] Pipes the selected text to `wc -l -w -m` via stdin to obtain line count, word count, and character count
- [ ] Returns valid JSON to stdout:
```json
{
  "lineCount": <integer>,
  "wordCount": <integer>,
  "charCount": <integer>
}
```
- [ ] Logs errors to stderr; stdout contains only valid JSON or nothing
- [ ] Never reads from or writes to the filesystem

### install Command (`install.sh`)
- [ ] Prints a message that `wc` is part of GNU coreutils and requires no installation
- [ ] Exits 0

### installed Command (`installed.sh`)
- [ ] Exits 0 if `wc` is available on PATH
- [ ] Exits non-zero otherwise

### Dependency Declaration
- [ ] `descriptor.json` declares `markitdown` and/or `ocrmypdf` as optional upstream dependencies (to signal that one of them should be active to provide text input)
- [ ] The plugin activates and runs regardless of which upstream text-extraction plugin is present; it skips gracefully (exit 65) if no text is found in the pipeline context

### Security
- [ ] Text is passed to `wc` via stdin only; no file paths are passed to `wc`, no shell interpolation of document content (REQ_SEC_005)
- [ ] All JSON input is validated before processing (REQ_SEC_009)

### Tests
- [ ] `tests/test_feature_0048.sh` covers:
  - Correct `lineCount`, `wordCount`, `charCount` values returned for a known text input via `textContent`, `ocrText`, and `documentText` fields (priority order)
  - Skip (exit 65) when no text field is present in the pipeline JSON
  - `installed.sh` exits 0 (`wc` always present)
- [ ] All existing tests continue to pass

## Scope

### In Scope
- `doc.doc.md/plugins/wc/descriptor.json`
- `doc.doc.md/plugins/wc/main.sh`
- `doc.doc.md/plugins/wc/install.sh`
- `doc.doc.md/plugins/wc/installed.sh`
- Default template update: add `{{wordCount}}`, `{{lineCount}}`, `{{charCount}}` placeholders to `doc.doc.md/templates/default.md`
- TDD test suite `tests/test_feature_0048.sh`

### Out of Scope
- Counting words directly from the source file (plugin works on pre-extracted text only)
- Byte count (`wc -c`) — the plugin counts characters (`wc -m`) from the extracted text, not raw file bytes

## Technical Requirements

- Text piped to `wc -l -w -m` via stdin: `printf '%s' "$text" | wc -l -w -m`
- No file paths passed to `wc`; no filesystem access after JSON input is read
- Output parsed with standard shell builtins or `awk`; no `eval`
- JSON output assembled via `jq`
- Exit code 65 (ADR-004) for all intentional skips

## Dependencies

- **ADR-004** (exit code 65 skip contract)
- `markitdown` or `ocrmypdf` plugin upstream in the pipeline (optional; plugin skips gracefully without them)

## Related Links
- Architecture Vision: `project_documentation/01_architecture/`
- Requirements: `project_management/02_project_vision/02_requirements/`
