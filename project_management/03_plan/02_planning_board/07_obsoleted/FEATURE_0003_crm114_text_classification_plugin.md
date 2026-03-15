# CRM114 Text Classification Plugin

- **ID:** FEATURE_0003
- **Priority:** MEDIUM
- **Type:** Feature
- **Created at:** 2026-03-02
- **Created by:** Product Owner
- **Status:** OBSOLETED
- **Obsolescence reason:** CRM114 plugin requires massive rework and better preparation regarding requirements and resulting architecture; existing implementation is no longer valid.

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

Implement a `crm114` plugin that performs statistical text classification on documents using the CRM114 Discriminator. The plugin stores its classification model files (`.css` database files) in the dedicated plugin state storage directory provided by doc.doc.md via the `pluginStorage` attribute (REQ_0029), keeping all state isolated from the plugin implementation.

**Business Value:**
- Enables automatic text classification of documents in the processed collection
- Demonstrates the plugin state storage mechanism (REQ_0029) with a real-world use case
- Adds a powerful spam/content filtering and categorization capability to the toolchain
- Validates that the `pluginStorage` pattern works correctly for stateful plugins

**What this delivers:**
- `crm114` plugin that classifies a file's text content and returns the classification result and confidence score
- Persistent CRM114 models stored in `pluginStorage` (`.doc.doc.md/crm114/` under the output folder)
- Interactive `train` command: manages categories in `pluginStorage`, iterates documents via `doc.doc.sh process` (full pipeline), displays file path and first 100 words per document, asks per-document/category (y → `csslearn`, n → `cssunlearn` anti-training)
- Manual `learn`/`unlearn` commands for non-interactive direct model manipulation
- `listCategories` command to inspect which categories have trained models in `pluginStorage`
- Standard plugin commands: `process`, `install`, `installed`
- Reference implementation for stateful plugins using `pluginStorage`

### Required Tools
- bash 4.0+
- jq (JSON processor)
- crm114 (CRM114 Discriminator — installable via `apt install crm114` or `brew install crm114`)

## Acceptance Criteria

### process Command
- [ ] Accepts `filePath` (required) and `pluginStorage` (required) as JSON fields on stdin
- [ ] Classifies document text using CRM114 and returns a `categories` JSON object
- [ ] `categories` maps category name → raw CRM114 pR value (float); only categories with pR > 0 are included
- [ ] If no trained categories exist in `pluginStorage`, plugin exits with code 65 (skip — ADR-004)
- [ ] If the document yields no extractable text, plugin exits with code 65

### train Command (Interactive Mode)
- [ ] **Step 1 — Category management**: lists existing categories found in `pluginStorage`
- [ ] If no categories exist, prompts user to enter one or more initial category names
- [ ] If categories exist, prompts user to optionally add new category names
- [ ] **Step 2 — Document labeling loop**: iterates over documents in the input directory using `doc.doc.sh process` (full pipeline) to extract text
- [ ] Displays the file path and first 100 words of extracted text before each labeling prompt
- [ ] Per document/category pair, prompts user with y/n:
  - [ ] "y" → runs `csslearn` to train the category model with the document text
  - [ ] "n" → runs `cssunlearn` to anti-train (remove) the document text from the category model
- [ ] All `.css` model files are read from and written to `pluginStorage` exclusively

### learn / unlearn Commands
- [ ] `learn` trains a specified category model with text provided via stdin (non-interactive)
- [ ] `unlearn` removes text from a specified category model (non-interactive)

### listCategories Command
- [ ] Lists all category names that have a trained `.css` model in `pluginStorage`

### install / installed Commands
- [ ] `install` installs the `crm114` system dependency
- [ ] `installed` exits 0 if `crm114` is available on PATH, non-zero otherwise

### Storage and Security
- [ ] All `.css` model files stored exclusively under `pluginStorage`; no state written elsewhere
- [ ] `pluginStorage` path is validated to prevent path traversal before any file I/O (REQ_SEC_005)
- [ ] All JSON input is validated before processing (REQ_SEC_009)

## Scope

### In Scope
- Interactive `train` command integrating with `doc.doc.sh process` (full pipeline) for text extraction
- Statistical text classification per category using CRM114 `.css` databases
- `categories` output with raw pR scores (float), filtered to pR > 0
- `pluginStorage` as the sole state persistence mechanism
- `listCategories`, `learn`, `unlearn`, `install`, `installed` commands
- Reference implementation for stateful plugins using `pluginStorage`

### Out of Scope
- GUI or web interface for training
- Score normalization or probability calibration
- Multi-label classification strategies beyond per-category pR scoring
- Non-CRM114 classification backends

## Technical Requirements

- CRM114 binaries (`csslearn`, `cssunlearn`, `crmclassify`) must be available on PATH
- `.css` database files stored at `<pluginStorage>/<categoryName>.css`
- Text content passed to CRM114 commands via stdin (no temporary files)
- `pluginStorage` path validated (no `..` path segments) before any file I/O
- JSON input/output follows the plugin I/O protocol (stdin → stdout)
- Exit code 65 (ADR-004) used for intentional skips
- `train` command invokes `doc.doc.sh process` as a subprocess for text extraction (loose coupling)

## Dependencies

### Blocking Items
- **FEATURE_0041** (Plugin Storage Plumbing) must be implemented first — it delivers the `pluginStorage` attribute injection into plugin JSON input that this feature depends on

### Blocks These Features
None

### Related Requirements
- **REQ_0003**: Plugin-Based Architecture
- **REQ_0029**: Plugin State Storage — core mechanism this feature exercises
- **REQ_SEC_001**: Input Validation and Sanitization
- **REQ_SEC_003**: Plugin Descriptor Validation
- **REQ_SEC_005**: Path Traversal Prevention — `pluginStorage` path must be validated
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
