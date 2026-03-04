# OCRmyPDF Text Extraction Plugin

- **ID:** FEATURE_0005
- **Priority:** MEDIUM
- **Type:** Feature
- **Created at:** 2026-03-02
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

Implement an `ocrmypdf` plugin that runs OCR on PDF files using [OCRmyPDF](https://ocrmypdf.readthedocs.io/), producing a searchable PDF with an embedded text layer and returning the extracted plain text as JSON output. OCR'd output PDFs are cached in `pluginStorage` (REQ_0029) to avoid redundant re-processing on subsequent runs.

**Business Value:**
- Makes scanned PDF documents searchable and indexable within the doc.doc.md pipeline
- Extracted text enables downstream classification (e.g. CRM114 plugin) and full-text search
- OCR'd PDFs are cached in `pluginStorage`, preventing expensive re-runs on unchanged files
- Demonstrates composition of stateful plugin caching with the `pluginStorage` mechanism

**What this delivers:**
- `ocrmypdf` plugin that accepts a PDF `filePath`, runs OCR if needed, and returns extracted text and metadata
- OCR'd output PDFs cached as `pluginStorage/<sha256_of_filePath>.pdf`
- Standard plugin commands: `process`, `install`, `installed`

## Acceptance Criteria

### ocrmypdf Plugin - process Command (main.sh)

- [ ] `doc.doc.md/plugins/ocrmypdf/main.sh` is executable (`chmod +x`)
- [ ] Script reads JSON input from stdin
- [ ] Script parses JSON to extract `filePath` and `pluginStorage` parameters
- [ ] Script validates that `filePath` is provided and the file exists
- [ ] Script validates that `filePath` points to a PDF file (MIME type `application/pdf` or `.pdf` extension)
- [ ] Script validates that `pluginStorage` is provided
- [ ] Script creates `pluginStorage` directory if it does not already exist
- [ ] Script computes a cache key from the input file path: `sha256sum` of `filePath` string, used as the output filename (`<hash>.pdf`)
- [ ] If a cached OCR'd PDF already exists at `pluginStorage/<hash>.pdf`, script skips OCRmyPDF invocation and uses the cached file
- [ ] If no cached file exists, script runs `ocrmypdf` on the input PDF and writes output to `pluginStorage/<hash>.pdf`
- [ ] Script extracts the plain text from the OCR'd PDF using `pdftotext` (or `pdftotext` via `poppler-utils`)
- [ ] Script outputs valid JSON to stdout with these fields:
  - `ocrText` (string): full plain-text content extracted from the OCR'd PDF
  - `pageCount` (number): number of pages in the PDF
  - `wasCached` (boolean): `true` if the cached OCR'd PDF was reused, `false` if OCR was freshly run
  - `outputPdf` (string): absolute path to the OCR'd PDF in `pluginStorage`
- [ ] Script handles errors gracefully (non-PDF input, OCR failure, missing tool, invalid JSON)
- [ ] Script exits with code 0 on success, 1 on error
- [ ] Script logs errors to stderr (not stdout)
- [ ] Script never writes output outside of `pluginStorage`

**Example interaction:**
```bash
echo '{"filePath":"/docs/scan.pdf","pluginStorage":"/out/.doc.doc.md/ocrmypdf"}' | ./main.sh
# Output: {"ocrText":"Invoice #1234 ...","pageCount":3,"wasCached":false,"outputPdf":"/out/.doc.doc.md/ocrmypdf/a3f1...cd.pdf"}
```

### ocrmypdf Plugin - installed Command (installed.sh)

- [ ] `doc.doc.md/plugins/ocrmypdf/installed.sh` is executable
- [ ] Script checks if both `ocrmypdf` and `pdftotext` commands are available
- [ ] Script outputs valid JSON to stdout:
  - `installed` (boolean): `true` only if both `ocrmypdf` and `pdftotext` are available, `false` otherwise
- [ ] Script exits with code 0 (always — reporting status, not failing)

**Example interaction:**
```bash
./installed.sh
# Output: {"installed":true}
```

### ocrmypdf Plugin - install Command (install.sh)

- [ ] `doc.doc.md/plugins/ocrmypdf/install.sh` is executable
- [ ] Script checks if `ocrmypdf` and `pdftotext` are already available
- [ ] If already available, outputs success immediately
- [ ] If not available, attempts installation:
  - `ocrmypdf`: `pip install ocrmypdf` or `apt-get install ocrmypdf`
  - `pdftotext`: `apt-get install poppler-utils` or `brew install poppler`
- [ ] Script outputs valid JSON to stdout:
  - `success` (boolean): `true` if both tools are available after the attempt
  - `message` (string): human-readable status message
- [ ] Script exits with code 0 on success, 1 if installation could not be completed

**Example interaction:**
```bash
./install.sh
# Output: {"success":true,"message":"ocrmypdf and pdftotext installed successfully"}
```

### Plugin Descriptor

- [ ] `doc.doc.md/plugins/ocrmypdf/descriptor.json` exists and is valid JSON
- [ ] Descriptor declares `filePath` (string, required) and `pluginStorage` (string, required) as inputs on `process`
- [ ] Descriptor declares all output fields (`ocrText`, `pageCount`, `wasCached`, `outputPdf`) with correct types
- [ ] Descriptor declares `install` and `installed` commands with correct output fields

### State Storage (Caching)

- [ ] OCR'd PDFs are written exclusively to `pluginStorage/`
- [ ] Cache key is derived from `filePath` (not from file content) via `sha256sum`
- [ ] No output files are written outside `pluginStorage`
- [ ] Cache hit is correctly detected on repeated invocations for the same `filePath`
- [ ] The plugin works correctly when `pluginStorage` points to different paths (portability verified)

### Code Quality

- [ ] All scripts use `#!/bin/bash` shebang
- [ ] Scripts follow bash best practices (shellcheck passes)
- [ ] JSON parsing uses `jq`
- [ ] JSON output generation uses `jq`
- [ ] Error messages are clear and actionable
- [ ] Scripts include comments explaining OCR and caching logic
- [ ] `pluginStorage` path is never hardcoded — always taken from input JSON

## Scope

### In Scope
✅ ocrmypdf plugin implementation (main.sh, install.sh, installed.sh, descriptor.json)  
✅ JSON stdin/stdout communication  
✅ `pluginStorage` integration per REQ_0029 (OCR output caching)  
✅ Plain-text extraction via `pdftotext` from the OCR'd PDF  
✅ Cache-hit detection to skip redundant OCR runs  
✅ Page count extraction  
✅ Error handling and input validation  

### Out of Scope
❌ Non-PDF input formats (images, DOCX, etc.)  
❌ Per-page text output (full document text only)  
❌ Language hint configuration (OCRmyPDF's `--language` flag — future enhancement)  
❌ OCR quality/deskew options (future enhancement)  
❌ Cross-platform Windows support  
❌ Cache invalidation based on file content changes (cache key is path-based only)  

## Technical Requirements

### Architecture Compliance

- **ADR-003**: JSON stdin/stdout plugin communication
  - Read input as JSON from stdin
  - Write output as JSON to stdout
  - Use lowerCamelCase parameter names
  - Never output non-JSON to stdout

- **REQ_0029 — Plugin State Storage**:
  - Accept `pluginStorage` from JSON input — never construct or assume this path
  - All OCR'd output PDFs and cache artefacts stored exclusively in `pluginStorage/`
  - Create `pluginStorage` directory if it does not exist

- **Plugin Descriptor Contract**:
  - Declare `pluginStorage` and `filePath` as required string inputs
  - Match all output field names and types exactly

### Implementation Details

**Cache Key Derivation:**
```bash
hash=$(echo -n "$file_path" | sha256sum | awk '{print $1}')
cached_pdf="$plugin_storage/${hash}.pdf"
```

**OCR Invocation (cache miss):**
```bash
ocrmypdf --skip-text "$file_path" "$cached_pdf"
```
- `--skip-text` preserves pages that already have a text layer, preventing double-OCR

**Text Extraction:**
```bash
ocr_text=$(pdftotext "$cached_pdf" -)
```

**Page Count:**
```bash
page_count=$(pdfinfo "$cached_pdf" | grep "^Pages:" | awk '{print $2}')
```
(`pdfinfo` is part of `poppler-utils`, same package as `pdftotext`)

**Storage Layout inside `pluginStorage`:**
```
<pluginStorage>/
  <sha256_of_filePath>.pdf    # Cached OCR'd PDF, one per processed input file
```

### Required Tools
- bash 4.0+
- jq
- ocrmypdf (`pip install ocrmypdf` or `apt-get install ocrmypdf`)
- pdftotext + pdfinfo (from `poppler-utils`: `apt-get install poppler-utils`)
- tesseract-ocr (pulled in as a dependency of ocrmypdf)

## Dependencies

### Blocking Items
- **REQ_0029** must be implemented (i.e. doc.doc.md passes `pluginStorage` to plugin invocations) before end-to-end testing is possible

### Blocks These Features
None

### Related Requirements
- **REQ_0003**: Plugin-Based Architecture
- **REQ_0029**: Plugin State Storage — caching mechanism for OCR'd PDFs
- **REQ_SEC_001**: Input Validation and Sanitization
- **REQ_SEC_003**: Plugin Descriptor Validation
- **REQ_SEC_005**: Path Traversal Prevention — `filePath` and `pluginStorage` must be validated
- **REQ_SEC_009**: JSON Input Validation

## Related Links

### Requirements
- [REQ_0003: Plugin-Based Architecture](../../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-system.md)
- [REQ_0029: Plugin State Storage](../../../02_project_vision/02_requirements/03_accepted/REQ_0029_plugin-state-storage.md)
- [REQ_SEC_001: Input Validation and Sanitization](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_001_input_validation_sanitization.md)
- [REQ_SEC_005: Path Traversal Prevention](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md)
- [REQ_SEC_009: JSON Input Validation](../../../02_project_vision/02_requirements/01_funnel/REQ_SEC_009_json_input_validation.md)

### Architecture Vision
- [ARC_0003: Plugin Architecture](../../../02_project_vision/03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md)

### Existing Plugin Reference Implementations
- [stat plugin](../../../../doc.doc.md/plugins/stat/)
- [file plugin](../../../../doc.doc.md/plugins/file/)

### Related Feature (downstream consumer of ocrText)
- [FEATURE_0003: CRM114 Text Classification Plugin](FEATURE_0003_crm114_text_classification_plugin.md)
