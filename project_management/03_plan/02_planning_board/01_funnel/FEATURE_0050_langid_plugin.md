# Language Identification Plugin (langid)

- **ID:** FEATURE_0050
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

Implement a `langid` plugin that detects the natural language of a document's text content using [langid.py](https://github.com/saffsd/langid.py) — a self-contained, off-the-shelf language identification library for Python. It classifies text into one of 97 languages and returns an ISO 639-1 language code together with a log-probability confidence score.

The plugin operates as a standard stateless pipeline plugin: it receives pre-extracted text from an upstream plugin (e.g. `markitdown` or `ocrmypdf`) via the accumulated pipeline JSON context, feeds it to the `langid` Python CLI/API, and returns two new fields — `languageCode` and `languageConfidence` — without performing any text extraction or file I/O of its own.

**Business Value:**
- Adds automatic language detection to every sidecar `.md` file, enabling downstream filtering by language (e.g. process only English documents)
- `languageCode` can be used by other pipeline plugins (e.g. `crm114`, `ots`) to select language-appropriate models or skip unsupported languages
- Purely stateless — no storage, no side effects; fits cleanly into the existing plugin pipeline
- `langid.py` is a pure-Python wheel with no system-level dependencies beyond `pip`

**What this delivers:**
- `langid` plugin under `doc.doc.md/plugins/langid/` following the standard plugin structure (`descriptor.json`, `main.sh`, `install.sh`, `installed.sh`)
- `main.sh` receives accumulated pipeline JSON on stdin, extracts available text (`documentText`, `ocrText`, or `textContent` — in that priority order), pipes it through a small Python inline script that calls `langid.classify()`, and returns `languageCode` (ISO 639-1 string, e.g. `"en"`) and `languageConfidence` (float, log-probability) in the JSON output
- If no text field is present or all candidate fields are empty in the pipeline context, the plugin exits with code 65 (skip — ADR-004)
- `install.sh` installs `langid` via `pip install langid`
- `installed.sh` checks that the `langid` Python package is importable (`python3 -c "import langid"`)

**Typical output contribution to sidecar `.md`:**
```
{{languageCode}}
{{languageConfidence}}
```

## Acceptance Criteria

### Plugin Structure
- [ ] Plugin directory `doc.doc.md/plugins/langid/` contains `descriptor.json`, `main.sh`, `install.sh`, and `installed.sh`
- [ ] All scripts are executable (`chmod +x`)
- [ ] `descriptor.json` declares `name`, `version`, `description`, `active` flag, `dependencies`, and a `process` command with `input`/`output` JSON schemas
- [ ] `descriptor.json` passes the existing plugin descriptor validation (REQ_SEC_003)

### process Command (`main.sh`)
- [ ] Reads accumulated pipeline JSON from stdin
- [ ] Extracts available text using the following priority order: `documentText`, `ocrText`, `textContent`; uses the first non-empty field found
- [ ] If no non-empty text field is available, exits with code 65 (skip — ADR-004)
- [ ] Passes the extracted text to `langid.classify()` via an inline `python3` call
- [ ] Returns valid JSON to stdout:
```json
{
  "languageCode": "<ISO 639-1 two-letter code, e.g. \"en\">",
  "languageConfidence": <float, log-probability score, e.g. -12.345>
}
```
- [ ] Logs errors to stderr; stdout contains only valid JSON or nothing
- [ ] Never reads from or writes to the filesystem (text is passed via shell variable / pipe only)
- [ ] Input text is passed to `langid` as data, never interpolated into a shell command string (no command injection)

### install Command (`install.sh`)
- [ ] Runs `pip install langid` (or `pip3 install langid`)
- [ ] Exits 0 on success

### installed Command (`installed.sh`)
- [ ] Checks that the `langid` Python package is importable: `python3 -c "import langid"`
- [ ] Exits 0 if importable, non-zero otherwise

### Dependency Declaration
- [ ] `descriptor.json` declares at least one of `markitdown` or `ocrmypdf` as an optional upstream dependency (provides `documentText` / `ocrText`)

### Security
- [ ] Text content is never interpolated into a shell command string; it is passed to the Python script via stdin or a shell variable read by Python's `sys.stdin` (REQ_SEC_005)
- [ ] All JSON input is validated before processing (REQ_SEC_009)
- [ ] No file paths or external URLs are constructed from pipeline data

### Tests
- [ ] `tests/test_feature_0050.sh` covers:
  - `languageCode` is a two-letter ISO 639-1 string for a known English input
  - `languageCode` is correct for a non-English input (e.g. German or French)
  - `languageConfidence` is a negative float (log-probability)
  - Skip (exit 65) when no text fields are present in the pipeline JSON
  - Skip (exit 65) when all candidate text fields are empty strings
  - `documentText` is preferred over `ocrText` when both are present
  - `installed.sh` exits 0 when `langid` is installed, non-zero when absent
- [ ] All existing tests continue to pass

## Scope

### In Scope
- `doc.doc.md/plugins/langid/descriptor.json`
- `doc.doc.md/plugins/langid/main.sh`
- `doc.doc.md/plugins/langid/install.sh`
- `doc.doc.md/plugins/langid/installed.sh`
- Default template update: add `{{languageCode}}` and `{{languageConfidence}}` placeholders to `doc.doc.md/templates/default.md`
- TDD test suite `tests/test_feature_0050.sh`

### Out of Scope
- Text extraction from source files (delegated to `markitdown` / `ocrmypdf` plugins)
- Training or fine-tuning a custom language model
- Support for language detection beyond `langid.py`'s built-in 97 languages
- Returning a ranked list of candidate languages (single best-guess result only)

## Technical Requirements

- Language detection: `python3 -c "import sys, json, langid; text=sys.stdin.read(); code,conf=langid.classify(text); print(json.dumps({'languageCode':code,'languageConfidence':conf}))"` or equivalent inline script
- Text extracted from pipeline JSON via `jq`; passed to Python via process substitution or heredoc — never via shell interpolation
- JSON output assembled via the Python script above (already valid JSON)
- Exit code 65 (ADR-004) for all intentional skips

## Dependencies

- **markitdown plugin** (optional upstream): provides `documentText`
- **ocrmypdf plugin** (optional upstream): provides `ocrText`
- **langid Python package** (`pip install langid`): runtime dependency
- **ADR-004** (exit code 65 skip contract)

## Related Links
- Architecture Vision: `project_documentation/01_architecture/`
- Requirements: `project_management/02_project_vision/02_requirements/`
- [langid.py on GitHub](https://github.com/saffsd/langid.py)
