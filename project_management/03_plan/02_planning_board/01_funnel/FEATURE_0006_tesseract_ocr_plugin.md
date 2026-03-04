# Tesseract OCR Plugin

- **ID:** FEATURE_0006
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

Implement a `tesseract` plugin that extracts plain text from image files (PNG, JPEG, TIFF, BMP, WebP, etc.) using [Tesseract OCR](https://github.com/tesseract-ocr/tesseract). Extracted text results are cached in `pluginStorage` (REQ_0029) to avoid redundant re-processing on subsequent runs. The plugin accepts an optional `language` parameter to target specific OCR language models.

This plugin is **complementary to FEATURE_0005** (OCRmyPDF): OCRmyPDF handles PDF files, Tesseract handles raster images. Together they provide full OCR coverage for the doc.doc.md pipeline.

**Business Value:**
- Enables text extraction from scanned images, screenshots, and photo documents
- Extracted text feeds downstream classification (e.g. CRM114 plugin, FEATURE_0003)
- Multi-language OCR support enables international document collections
- Caching in `pluginStorage` prevents expensive re-runs on unchanged images

**What this delivers:**
- `tesseract` plugin that accepts an image `filePath`, runs OCR if needed, and returns extracted text
- Extracted text results cached as `pluginStorage/<sha256_of_filePath>.txt`
- Optional `language` input parameter (defaults to `eng`)
- Standard plugin commands: `process`, `install`, `installed`

## Acceptance Criteria

### tesseract Plugin - process Command (main.sh)

- [ ] `doc.doc.md/plugins/tesseract/main.sh` is executable (`chmod +x`)
- [ ] Script reads JSON input from stdin
- [ ] Script parses JSON to extract `filePath`, `pluginStorage`, and optional `language` parameters
- [ ] Script validates that `filePath` is provided and the file exists
- [ ] Script validates that `filePath` points to a supported image format (JPEG, PNG, TIFF, BMP, WebP, GIF); rejects PDFs and other non-image formats with a clear error
- [ ] Script validates that `pluginStorage` is provided
- [ ] Script creates `pluginStorage` directory if it does not already exist
- [ ] Script defaults `language` to `eng` if not provided
- [ ] Script computes a cache key from `filePath` + `language`: `sha256sum` of the concatenation `<filePath>:<language>`, used as the cache filename (`<hash>.txt`)
- [ ] If a cached text file already exists at `pluginStorage/<hash>.txt`, script skips Tesseract invocation and reads from the cache
- [ ] If no cached file exists, script runs `tesseract` on the input image and writes output to `pluginStorage/<hash>.txt`
- [ ] Script outputs valid JSON to stdout with these fields:
  - `ocrText` (string): full plain-text content extracted from the image
  - `language` (string): the language code used for OCR (e.g. `"eng"`, `"deu"`)
  - `wasCached` (boolean): `true` if the cached result was reused, `false` if OCR was freshly run
- [ ] Script handles errors gracefully (unsupported format, OCR failure, missing tool, invalid language code, invalid JSON)
- [ ] Script exits with code 0 on success, 1 on error
- [ ] Script logs errors to stderr (not stdout)
- [ ] Script never writes output outside of `pluginStorage`

**Example interaction:**
```bash
echo '{"filePath":"/docs/scan.png","pluginStorage":"/out/.doc.doc.md/tesseract","language":"eng"}' | ./main.sh
# Output: {"ocrText":"Invoice #1234 ...","language":"eng","wasCached":false}
```

```bash
echo '{"filePath":"/docs/scan.png","pluginStorage":"/out/.doc.doc.md/tesseract"}' | ./main.sh
# Output: {"ocrText":"Invoice #1234 ...","language":"eng","wasCached":true}
```

### tesseract Plugin - installed Command (installed.sh)

- [ ] `doc.doc.md/plugins/tesseract/installed.sh` is executable
- [ ] Script checks if `tesseract` command is available
- [ ] Script outputs valid JSON to stdout:
  - `installed` (boolean): `true` if `tesseract` is available, `false` otherwise
- [ ] Script exits with code 0 (always — reporting status, not failing)

**Example interaction:**
```bash
./installed.sh
# Output: {"installed":true}
```

### tesseract Plugin - install Command (install.sh)

- [ ] `doc.doc.md/plugins/tesseract/install.sh` is executable
- [ ] Script checks if `tesseract` is already available
- [ ] If already available, outputs success immediately
- [ ] If not available, attempts installation:
  - Linux: `apt-get install -y tesseract-ocr`
  - macOS: `brew install tesseract`
- [ ] Script attempts to install the English language pack (`tesseract-ocr-eng`) if not present
- [ ] Script outputs valid JSON to stdout:
  - `success` (boolean): `true` if `tesseract` is available after the attempt
  - `message` (string): human-readable status message
- [ ] Script exits with code 0 on success, 1 if installation could not be completed

**Example interaction:**
```bash
./install.sh
# Output: {"success":true,"message":"tesseract installed successfully"}
```

### Plugin Descriptor

- [ ] `doc.doc.md/plugins/tesseract/descriptor.json` exists and is valid JSON
- [ ] Descriptor declares `filePath` (string, required) and `pluginStorage` (string, required) as inputs on `process`
- [ ] Descriptor declares `language` (string, optional, default: `"eng"`) as an input on `process`
- [ ] Descriptor declares all output fields (`ocrText`, `language`, `wasCached`) with correct types
- [ ] Descriptor declares `install` and `installed` commands with correct output fields

### State Storage (Caching)

- [ ] Extracted text files are written exclusively to `pluginStorage/`
- [ ] Cache key is derived from `filePath` + `language` concatenation via `sha256sum`
- [ ] No output files are written outside `pluginStorage`
- [ ] Cache hit is correctly detected on repeated invocations for the same `filePath` + `language` combination
- [ ] Different `language` values for the same file produce separate cache entries
- [ ] The plugin works correctly when `pluginStorage` points to different paths (portability verified)

### Code Quality

- [ ] All scripts use `#!/bin/bash` shebang
- [ ] Scripts follow bash best practices (shellcheck passes)
- [ ] JSON parsing uses `jq`
- [ ] JSON output generation uses `jq`
- [ ] Error messages are clear and actionable
- [ ] Scripts include comments explaining Tesseract invocation and caching logic
- [ ] `pluginStorage` path is never hardcoded — always taken from input JSON

## Scope

### In Scope
✅ tesseract plugin implementation (main.sh, install.sh, installed.sh, descriptor.json)  
✅ JSON stdin/stdout communication  
✅ `pluginStorage` integration per REQ_0029 (extracted text caching)  
✅ Optional `language` parameter (default: `eng`)  
✅ Cache key includes both `filePath` and `language` to isolate multi-language results  
✅ Supported formats: JPEG, PNG, TIFF, BMP, WebP, GIF  
✅ Error handling and input validation  

### Out of Scope
❌ PDF input (use FEATURE_0005 OCRmyPDF plugin for PDFs)  
❌ Per-word or per-line bounding box output (full document text only)  
❌ Page segmentation mode (PSM) configuration (future enhancement)  
❌ OCR engine mode (OEM) configuration (future enhancement)  
❌ Automatic language detection (future enhancement)  
❌ Cross-platform Windows support  
❌ Cache invalidation based on file content changes (cache key is path + language based)  

## Technical Requirements

### Architecture Compliance

- **ADR-003**: JSON stdin/stdout plugin communication
  - Read input as JSON from stdin
  - Write output as JSON to stdout
  - Use lowerCamelCase parameter names
  - Never output non-JSON to stdout

- **REQ_0029 — Plugin State Storage**:
  - Accept `pluginStorage` from JSON input — never construct or assume this path
  - All extracted text cache files stored exclusively in `pluginStorage/`
  - Create `pluginStorage` directory if it does not exist

- **Plugin Descriptor Contract**:
  - Declare `pluginStorage`, `filePath` as required string inputs, `language` as optional string input
  - Match all output field names and types exactly

### Implementation Details

**Cache Key Derivation (language-aware):**
```bash
hash=$(echo -n "${file_path}:${language}" | sha256sum | awk '{print $1}')
cached_txt="${plugin_storage}/${hash}.txt"
```

**OCR Invocation (cache miss):**
```bash
tesseract "$file_path" "$plugin_storage/$hash" -l "$language"
# Tesseract appends .txt automatically: output is $plugin_storage/$hash.txt
```

**Reading cached result:**
```bash
ocr_text=$(cat "$cached_txt")
```

**Constructing JSON output:**
```bash
jq -n \
  --arg ocrText "$ocr_text" \
  --arg language "$language" \
  --argjson wasCached "$was_cached" \
  '{"ocrText": $ocrText, "language": $language, "wasCached": $wasCached}'
```

**Supported MIME types (validated via `file --mime-type`):**
- `image/jpeg`, `image/png`, `image/tiff`, `image/bmp`, `image/webp`, `image/gif`

**Storage Layout inside `pluginStorage`:**
```
<pluginStorage>/
  <sha256_of_filePath:language>.txt    # Cached OCR text, one per (file, language) pair
```

### Required Tools
- bash 4.0+
- jq
- tesseract-ocr (`apt-get install tesseract-ocr` or `brew install tesseract`)
- tesseract-ocr-eng language pack (installed alongside tesseract on most systems)
- file (for MIME type validation — already required by the `file` plugin, FEATURE_0002)

## Dependencies

### Blocking Items
- **REQ_0029** must be implemented (i.e. doc.doc.md passes `pluginStorage` to plugin invocations) before end-to-end testing is possible

### Blocks These Features
None

### Related Requirements
- **REQ_0003**: Plugin-Based Architecture
- **REQ_0029**: Plugin State Storage — caching mechanism for extracted text
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

### Related Features
- [FEATURE_0005: OCRmyPDF Plugin](FEATURE_0005_ocrmypdf_plugin.md) — PDF-specific OCR counterpart
- [FEATURE_0003: CRM114 Text Classification Plugin](FEATURE_0003_crm114_text_classification_plugin.md) — downstream consumer of `ocrText`

### Existing Plugin Reference Implementations
- [stat plugin](../../../../doc.doc.md/plugins/stat/)
- [file plugin](../../../../doc.doc.md/plugins/file/)
