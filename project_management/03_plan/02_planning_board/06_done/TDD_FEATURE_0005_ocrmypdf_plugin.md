# TDD Task: OCRmyPDF Text Extraction Plugin

- **ID:** TDD_FEATURE_0005
- **Priority:** MEDIUM
- **Type:** TDD Task
- **Created at:** 2026-03-04
- **Created by:** developer.agent
- **Status:** DONE
- **Assigned to:** tester.agent
- **Related Feature:** FEATURE_0005

## Overview

Implement failing tests for FEATURE_0005 following TDD workflow.
Tests cover plugin structure, error handling, and (when ocrmypdf/pdftotext are installed) OCR processing.

## Acceptance Criteria Covered

### Plugin Structure
- main.sh, install.sh, installed.sh exist and are executable with #!/bin/bash shebang
- descriptor.json exists and is valid JSON
- descriptor declares filePath and pluginStorage as process inputs
- descriptor declares ocrText, pageCount, wasCached, outputPdf as process outputs
- descriptor declares install and installed commands

### installed.sh
- exits with 0 always
- output is valid JSON with boolean 'installed' field

### main.sh Error Cases
- missing filePath → exit 1
- missing pluginStorage → exit 1
- malformed JSON → exit 1
- non-existent file → exit 1
- non-PDF file → exit 1
- error messages to stderr, not stdout

### main.sh OCR Processing (when tools available)
- output is valid JSON with ocrText (string), pageCount (number), wasCached (boolean), outputPdf (string)
- wasCached is false on first run, true on subsequent runs
- outputPdf is within pluginStorage
- outputPdf file exists after processing

### list command integration
- `list --plugin ocrmypdf --commands` lists process, install, installed commands

## Test File

`tests/test_feature_0005.sh`
