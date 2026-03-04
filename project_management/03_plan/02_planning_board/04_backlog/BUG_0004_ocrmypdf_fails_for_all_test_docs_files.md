# ocrmypdf Plugin Fails for All Files in tests/docs

- **ID:** BUG_0004
- **Priority:** HIGH
- **Type:** Bug
- **Created at:** 2026-03-04
- **Created by:** Product Owner
- **Status:** Backlog
- **Assigned to:** developer.agent

## Overview

Running `./doc.doc.sh process -d ./tests/docs` produces `Error: Plugin 'ocrmypdf' failed` for all four files in `tests/docs/`. The failures have two distinct root causes depending on file type.

### Reproduction

```bash
./doc.doc.sh process -d ./tests/docs
# stderr:
# Error: Plugin 'ocrmypdf' failed for file: README-PDF.pdf
# Error: Plugin 'ocrmypdf' failed for file: README-Screenshot-GIF.gif
# Error: Plugin 'ocrmypdf' failed for file: README-Screenshot-JPG.jpg
# Error: Plugin 'ocrmypdf' failed for file: README-Screenshot-PNG.png
```

### Detailed failure per file type

**PDF file (`README-PDF.pdf`):**
```bash
echo '{"filePath":"./tests/docs/README-PDF.pdf","pluginStorage":"/tmp/ps"}' \
  | ./doc.doc.md/plugins/ocrmypdf/main.sh
# Error: ocrmypdf is not installed. Run the install command first.
# exit: 1
```
Root cause: the `ocrmypdf` binary is not installed on the system, yet the plugin descriptor has `"active": true`. The validation phase should detect this and abort before any files are processed.

**Image files (`README-Screenshot-GIF.gif`, `README-Screenshot-JPG.jpg`, `README-Screenshot-PNG.png`):**
```bash
echo '{"filePath":"./tests/docs/README-Screenshot-PNG.png","pluginStorage":"/tmp/ps"}' \
  | ./doc.doc.md/plugins/ocrmypdf/main.sh
# Error: Input file is not a PDF (detected MIME type: image/png)
# exit: 1
```
Root cause: `main.sh` contains a hard-coded validation that rejects any file that is not a PDF. **This validation is incorrect.** According to the [official ocrmypdf documentation](https://ocrmypdf.readthedocs.io/en/latest/cookbook.html#ocr-images-not-pdfs), `ocrmypdf` supports single image files (PNG, JPEG, TIFF, etc.) directly as input:

```bash
ocrmypdf --image-dpi 300 image.png output.pdf
ocrmypdf --image-dpi 300 scan.jpg output.pdf
```

The plugin should therefore accept image formats and pass them to `ocrmypdf` with `--image-dpi`. The current rejection of GIF/JPG/PNG inputs is a bug in `main.sh`, not correct behaviour.

> **Note:** GIF files are handled by passing them directly to the `ocrmypdf` CLI. ocrmypdf uses its internal tooling to perform the conversion. For the `process` command the efficient single-step pattern is:
> ```bash
> ocrmypdf --sidecar output.txt --output-type none input.gif /dev/null
> ```
> `--sidecar` writes extracted text directly; `--output-type none` suppresses PDF output; `/dev/null` satisfies the required output-path argument. This avoids a second `pdftotext` invocation.

## Root Causes

1. **Not-installed plugin is active**: `descriptor.json` has `"active": true` but `ocrmypdf` is not installed. The validation phase (`doc.doc.sh` Phase 1) is supposed to verify that active plugins are installed before processing begins. Either the check is missing or `installed.sh` is not being called.

2. **Plugin incorrectly rejects image inputs**: `main.sh` validates that input must be a PDF and exits with an error for image files. `ocrmypdf` supports single image files (PNG, JPEG, TIFF, BMP) directly. The plugin must be extended to detect image MIME types and invoke `ocrmypdf` with `--image-dpi` for those formats.

## Acceptance Criteria

### Root Cause 1 — Not installed but active
- [ ] If `ocrmypdf` binary is not installed and the plugin is `active: true`, `doc.doc.sh process` aborts with a clear error during the validation phase **before** processing any files — consistent with the documented validation phase behavior in project goals

### Root Cause 2 — Plugin incorrectly rejects image inputs
- [ ] `main.sh` accepts PDF, JPEG, PNG, TIFF, BMP, and GIF files as valid input
- [ ] For all image inputs (JPEG, PNG, TIFF, BMP, GIF), `main.sh` invokes `ocrmypdf` with `--image-dpi` (default: 300 DPI if not provided in input JSON); ocrmypdf handles the conversion internally
- [ ] Text extraction uses the single-step sidecar pattern: `ocrmypdf --image-dpi <dpi> --sidecar <sidecar.txt> --output-type none <input_image> /dev/null` — no `pdftotext` post-processing required
- [ ] The same sidecar pattern is used for PDF inputs: `ocrmypdf --sidecar <sidecar.txt> --output-type none <input.pdf> /dev/null`
- [ ] The plugin `descriptor.json` input schema is updated to document the accepted MIME types and the optional `imageDpi` parameter
- [ ] An optional `imageDpi` input parameter (integer, default 300) is accepted from JSON input and passed as `--image-dpi` to `ocrmypdf`

### Overall
- [ ] No `Plugin 'ocrmypdf' failed` error appears on stderr when processing `tests/docs/` after the fix (for JPEG, PNG; GIF still rejected with a clear per-file error)
- [ ] `./doc.doc.sh process -d ./tests/docs` exits 0 after the fix
- [ ] All 34 tests in `tests/test_docs_integration.sh` continue to pass after the fix
- [ ] All existing tests in `tests/test_doc_doc.sh` and `tests/test_plugins.sh` continue to pass

## Impact

- Severity: **Medium** — the tool continues to produce output (graceful degradation keeps stat+file results), but stderr is polluted with 4 errors per run on the standard test fixture, which masks real errors and causes `test_docs_integration.sh` Group 5 to document the failure as an expected condition
- Affects: all runs of `./doc.doc.sh process -d ./tests/docs` and any input directory containing non-PDF or non-image files while `ocrmypdf` is active but not installed

## Dependencies

- **Related:** FEATURE_0007 (MIME filter gate) — once implemented, GIF files can be filtered out before reaching the plugin entirely
- **Related:** FEATURE_0009 (integration tests) — `test_docs_integration.sh` Group 5 tests currently assert that this error is present; those assertions must be updated to assert the error is **absent** (for JPEG/PNG) after this bug is fixed
- **Related:** FEATURE_0010 (ocrmypdf convert command) — adds a dedicated `convert` command for image-to-PDF conversion; this bug fix covers the `process` command only

## Related Links

- Integration test suite: [`tests/test_docs_integration.sh`](../../../../tests/test_docs_integration.sh)
- ocrmypdf plugin: [`doc.doc.md/plugins/ocrmypdf/`](../../../../doc.doc.md/plugins/ocrmypdf/)
- Feature (MIME gate): [FEATURE_0007](../../06_done/FEATURE_0007_file_plugin_first_in_chain_and_mime_filter_gate.md)
- Feature (integration tests): [FEATURE_0009](FEATURE_0009_integration_tests_real_docs.md)
