# Integration Tests Using Real Document Files

- **ID:** FEATURE_0009
- **Priority:** HIGH
- **Type:** Feature
- **Created at:** 2026-03-04
- **Created by:** Product Owner
- **Status:** BACKLOG

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

Create an integration test suite (`tests/test_docs_integration.sh`) that exercises the full `doc.doc.sh process` pipeline against the real document files in `tests/docs/`. These tests verify that the `stat` and `file` plugins produce correct, semantically meaningful output for each real file type — going beyond the synthetic test files used in `test_doc_doc.sh`.

**The `tests/docs/` fixture set (committed to the repository):**

| File | MIME Type | Size (approx) |
|------|-----------|---------------|
| `README-PDF.pdf` | `application/pdf` | ~349 KB |
| `README-Screenshot-GIF.gif` | `image/gif` | ~35 KB |
| `README-Screenshot-JPG.jpg` | `image/jpeg` | ~109 KB |
| `README-Screenshot-PNG.png` | `image/png` | ~94 KB |

**Current state when running `./doc.doc.sh process -d ./tests/docs`:**
- `stat` and `file` plugins run successfully and produce correct JSON for all 4 files
- `ocrmypdf` plugin is active but fails for every file (missing `pluginStorage` parameter; only handles PDFs; images are rejected)
- The failures are logged to stderr; output JSON is still produced via graceful degradation

**Business Value:**
- Provides stable regression coverage using real, binary file types that synthetic test files cannot replicate
- Catches regressions in MIME detection, file stat extraction, and JSON output structure
- Documents the expected per-file-type output contract for `stat` and `file` plugins
- Flags the current `ocrmypdf` failure clearly so it is not silently ignored
- Foundation for future plugin integration tests (ocrmypdf, ocr plugins)

**What this delivers:**
- `tests/test_docs_integration.sh` — integration tests against `tests/docs/` fixture files
- Coverage for PDF, GIF, JPG, PNG file types
- Per-file assertions on `mimeType`, `fileSize`, `fileOwner`, `fileModified`, `fileMetadataChanged`, `filePath`
- Documented expected-failure tests for `ocrmypdf` gaps (as known failing assertions)

## Acceptance Criteria

### General

- [ ] `tests/test_docs_integration.sh` exists and is executable
- [ ] Tests run from the repository root: `bash tests/test_docs_integration.sh`
- [ ] Script exits code 0 only when all tests pass; exits 1 if any test fails
- [ ] Results summary line printed: `Results: X/Y passed, Z failed`
- [ ] Tests use the same assert helper style as `test_doc_doc.sh`

### Process Output — Overall Shape

- [ ] `doc.doc.sh process -d ./tests/docs` exits with code 0
- [ ] Output is valid JSON (parseable by `jq`)
- [ ] Output is a JSON array with exactly 4 elements (one per file)
- [ ] Each element contains a `filePath` field

### Per-File: `README-PDF.pdf`

- [ ] `mimeType` is `"application/pdf"`
- [ ] `fileSize` is a number greater than 0
- [ ] `fileModified` is a non-empty string (ISO-8601 timestamp)
- [ ] `fileMetadataChanged` is a non-empty string
- [ ] `filePath` contains `README-PDF.pdf`

### Per-File: `README-Screenshot-GIF.gif`

- [ ] `mimeType` is `"image/gif"`
- [ ] `fileSize` is a number greater than 0
- [ ] `fileModified` is a non-empty string
- [ ] `filePath` contains `README-Screenshot-GIF.gif`

### Per-File: `README-Screenshot-JPG.jpg`

- [ ] `mimeType` is `"image/jpeg"`
- [ ] `fileSize` is a number greater than 0
- [ ] `fileModified` is a non-empty string
- [ ] `filePath` contains `README-Screenshot-JPG.jpg`

### Per-File: `README-Screenshot-PNG.png`

- [ ] `mimeType` is `"image/png"`
- [ ] `fileSize` is a number greater than 0
- [ ] `fileModified` is a non-empty string
- [ ] `filePath` contains `README-Screenshot-PNG.png`

### MIME-Type Filter Integration

- [ ] `doc.doc.sh process -d ./tests/docs -i "application/pdf"` returns exactly 1 file (the PDF)
- [ ] `doc.doc.sh process -d ./tests/docs -i "image/jpeg"` returns exactly 1 file (the JPG)
- [ ] `doc.doc.sh process -d ./tests/docs -i "image/*"` returns exactly 3 files (GIF, JPG, PNG)
- [ ] `doc.doc.sh process -d ./tests/docs -e "image/*"` returns exactly 1 file (the PDF)
- [ ] `doc.doc.sh process -d ./tests/docs -i ".pdf"` returns exactly 1 file (extension filter, for comparison)

**Note:** MIME type filter tests via `-i "image/*"` currently depend on BUG_0003 (`filter.py` MIME type support) being fixed. Until then, these assertions will fail. Mark them with a `# BUG_0003` comment in the test file.

### Extension / Glob Filter Integration

- [ ] `doc.doc.sh process -d ./tests/docs -i ".gif"` returns exactly 1 file
- [ ] `doc.doc.sh process -d ./tests/docs -i ".jpg"` returns exactly 1 file
- [ ] `doc.doc.sh process -d ./tests/docs -i ".png"` returns exactly 1 file
- [ ] `doc.doc.sh process -d ./tests/docs -e ".gif,.jpg,.png"` returns exactly 1 file (the PDF)

### ocrmypdf Plugin — Known Failures (documented)

- [ ] Test: when `ocrmypdf` plugin is active, the error `Plugin 'ocrmypdf' failed` appears on stderr for each file
- [ ] Test documents this as an expected-failure condition linked to the `ocrmypdf` plugin needing `pluginStorage` parameter support
- [ ] Despite `ocrmypdf` errors, the output JSON is still produced (graceful degradation: `stat`+`file` results present)

## Scope

### In Scope
✅ Integration tests against real files in `tests/docs/`
✅ `stat` and `file` plugin output validation
✅ MIME type filter integration tests (marked with BUG_0003 for currently failing ones)
✅ Extension/glob filter integration tests
✅ `ocrmypdf` failure documentation tests

### Out of Scope
❌ `ocrmypdf` output validation (requires BUG_0003 fix + pluginStorage support)
❌ Testing with files outside `tests/docs/` — use existing `test_doc_doc.sh` for that
❌ Performance benchmarks
❌ Template output (`-t` flag) — that is a separate test concern

## Technical Requirements

- Same bash helper style (`assert_eq`, `assert_exit_code`, `assert_contains`, `assert_json_field`) as existing test files
- Use `jq` for all JSON assertions
- `DOCS_DIR="$REPO_ROOT/tests/docs"` — never use absolute paths not relative to `REPO_ROOT`
- Each file accessed by its known name (not glob discovery), so test intent is explicit
- The test script must not modify `tests/docs/` contents

## Dependencies

### Blocking Items
- **BUG_0003**: MIME type filter tests (`-i "image/*"`, `-i "application/pdf"`) will fail until `filter.py` MIME matching is implemented

### Related
- **FEATURE_0007** (MIME filter gate via file plugin) — the MIME integration tests partially verify this behavior
- **FEATURE_0005** (ocrmypdf plugin) — future ocrmypdf assertions can be added once the plugin is stable

## Related Links

### Tests
- [`tests/test_docs_integration.sh`](../../../../tests/test_docs_integration.sh)
- [`tests/test_doc_doc.sh`](../../../../tests/test_doc_doc.sh) — existing suite using synthetic files
- [`tests/test_filter_mime.sh`](../../../../tests/test_filter_mime.sh) — BUG_0003 failing tests

### Requirements
- [REQ_0009: Process Command](../../../02_project_vision/02_requirements/03_accepted/REQ_0009_process-command.md)
- [REQ_SEC_002: Filter Logic Correctness](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_002_filter_logic_correctness.md)

### Bugs
- [BUG_0003: filter.py MIME type not implemented](BUG_0003_filter_mime_type_not_implemented.md)
