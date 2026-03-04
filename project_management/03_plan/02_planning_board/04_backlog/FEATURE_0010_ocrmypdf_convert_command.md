# ocrmypdf Plugin: Image-to-PDF Convert Command

- **ID:** FEATURE_0010
- **Priority:** MEDIUM
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

Add a dedicated `convert` command to the ocrmypdf plugin. This command converts image files (JPEG, PNG, TIFF, BMP, GIF) into searchable PDFs using `ocrmypdf`. Unlike the `process` command — which focuses on text extraction — the `convert` command's primary output is the PDF artifact itself, making it useful for archival and downstream document pipelines.

**Motivation from the `--sidecar` pattern:**

When extracting text from an image, the most efficient invocation is:

```bash
ocrmypdf --sidecar output.txt --output-type none input.gif /dev/null
```

- `--sidecar output.txt` — writes the extracted plain text directly alongside the image, no `pdftotext` post-processing needed
- `--output-type none` — suppresses PDF creation entirely when a PDF artifact is not needed
- `/dev/null` — satisfies the required output path argument while discarding PDF output

The `convert` command, by contrast, targets the opposite use case: the caller **does** want the PDF artifact. It writes a searchable PDF to a caller-specified path.

**Two distinct use cases now clearly separated:**

| Use Case | Command | Approach |
|----------|---------|----------|
| Extract text from a document/image | `process` | `--sidecar --output-type none` → sidecar text |
| Convert image to searchable PDF | `convert` | `ocrmypdf --image-dpi <dpi> <input> <output.pdf>` |

**Business Value:**

- Enables users to archive images as searchable PDFs in a single CLI call
- Provides a building block for document ingestion pipelines (convert → index)
- Keeps plugin commands single-purpose and composable
- Aligns with standard ocrmypdf CLI patterns, reducing implementation complexity

## Acceptance Criteria

### `convert` command — basic behavior

- [ ] A `convert` command is defined in `descriptor.json` under `commands.convert`
- [ ] A `convert.sh` script is present in `doc.doc.md/plugins/ocrmypdf/`
- [ ] `convert.sh` is executable
- [ ] `convert.sh` reads input as JSON from stdin (consistent with all other plugin commands)

### Supported input formats

- [ ] `convert` accepts JPEG, PNG, TIFF, BMP, and GIF files as valid `filePath` input
- [ ] `convert` rejects unsupported MIME types with exit code 1 and a clear error message on stderr

### Invocation pattern

- [ ] For image inputs, `convert.sh` invokes:
  ```bash
  ocrmypdf --image-dpi <imageDpi> <filePath> <outputPath>
  ```
- [ ] `imageDpi` defaults to `300` if not provided in JSON input
- [ ] The resulting searchable PDF is written to `outputPath`
- [ ] If `outputPath` is not specified in input JSON, the output PDF is placed next to the source file with a `.pdf` extension

### Output JSON

- [ ] On success, `convert.sh` emits JSON to stdout:
  ```json
  { "outputPdf": "<absolute-path-to-output.pdf>", "success": true }
  ```
- [ ] On failure, `convert.sh` emits JSON to stdout and exits with code 1:
  ```json
  { "success": false, "error": "<error-message>" }
  ```

### Descriptor

- [ ] `descriptor.json` `commands.convert` defines:
  - Input: `filePath` (required, string), `outputPath` (optional, string), `imageDpi` (optional, integer, default 300)
  - Output: `outputPdf` (string), `success` (boolean)
- [ ] `descriptor.json` `description` field at plugin level is updated to mention image-to-PDF conversion capability

### Integration

- [ ] `installed.sh` and `install.sh` remain unchanged (ocrmypdf binary covers this command)
- [ ] The `convert` command is covered by tests in `tests/test_plugins.sh` or a dedicated `tests/test_ocrmypdf_convert.sh`
- [ ] Tests verify: success for JPEG/PNG input, success for GIF input, rejection of unsupported MIME type, default DPI applied

## Scope

**In scope:**
- New `convert.sh` script in `doc.doc.md/plugins/ocrmypdf/`
- `descriptor.json` update with `commands.convert` definition
- Tests for the convert command

**Out of scope:**
- Batch conversion (multiple files per invocation) — one file per call, consistent with plugin contract
- Video or multi-page document formats (e.g. multi-page TIFF beyond what ocrmypdf handles natively)
- Changes to the `process` command (covered by BUG_0004)

## Technical Requirements

- `ocrmypdf` binary must be installed (same prerequisite as `process`)
- No additional system dependencies beyond what `install.sh` already installs
- Input JSON contract: `{"filePath": "...", "outputPath": "...", "imageDpi": 300}`
- Uses the `--sidecar` pattern insight: `--output-type none` can be combined if only text is needed, but `convert.sh` explicitly targets PDF output

### Key CLI patterns

```bash
# Standard image-to-PDF conversion (the convert command's core invocation)
ocrmypdf --image-dpi 300 input.jpg output.pdf

# GIF input — handled directly by ocrmypdf's internal tooling
ocrmypdf --image-dpi 300 input.gif output.pdf

# Text extraction only (without PDF output — used by process command per BUG_0004 fix)
ocrmypdf --sidecar output.txt --output-type none input.gif /dev/null
```

## Dependencies

- **Depends on:** BUG_0004 fix — `ocrmypdf` binary must be installed and the not-installed validation must be working before this feature is testable end-to-end
- **Related:** BUG_0004 (ocrmypdf failures, image support in `process` command)
- **Related:** FEATURE_0005 (ocrmypdf plugin, in backlog)
- **Related:** FEATURE_0009 (integration tests with real docs in `tests/docs/`)

## Related Links

- ocrmypdf plugin: [`doc.doc.md/plugins/ocrmypdf/`](../../../../doc.doc.md/plugins/ocrmypdf/)
- BUG_0004: [BUG_0004_ocrmypdf_fails_for_all_test_docs_files.md](BUG_0004_ocrmypdf_fails_for_all_test_docs_files.md)
- FEATURE_0005: [`04_backlog/FEATURE_0005_ocrmypdf_plugin.md`](FEATURE_0005_ocrmypdf_plugin.md)
- Integration tests: [`tests/test_docs_integration.sh`](../../../../tests/test_docs_integration.sh)
- official ocrmypdf docs: https://ocrmypdf.readthedocs.io/en/latest/cookbook.html#ocr-images-not-pdfs
