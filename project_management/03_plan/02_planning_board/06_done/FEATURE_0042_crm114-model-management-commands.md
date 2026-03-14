# CRM114 Model Management Commands (train, learn, unlearn, listCategories)

- **ID:** FEATURE_0042
- **Priority:** MEDIUM
- **Type:** Feature
- **Created at:** 2026-03-14
- **Created by:** Product Owner
- **Status:** DONE

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

FEATURE_0003 delivered the `process`, `install`, and `installed` commands for the crm114 plugin but left the model management commands unimplemented. This feature delivers the remaining commands defined in FEATURE_0003's acceptance criteria:

- **`train`** — Interactive command that iterates documents via `doc.doc.sh process`, displays each document's file path and first 100 words, and prompts the user y/n per document/category pair to `csslearn` (y) or `cssunlearn` (n) the document into the category model.
- **`learn`** — Non-interactive: trains a specified category model with text piped on stdin.
- **`unlearn`** — Non-interactive: removes text piped on stdin from a specified category model.
- **`listCategories`** — Lists all category names that have a trained `.css` model in `pluginStorage`.

All model files (`.css`) are stored exclusively under `pluginStorage`. This completes the crm114 plugin as originally designed in FEATURE_0003.

**Business Value:**
- Makes the crm114 plugin actually usable — without training, `process` always exits 65 (no trained categories)
- Delivers the interactive document-labeling workflow for building classification models
- Provides non-interactive `learn`/`unlearn` for scripted/batch training workflows
- Completes FEATURE_0003 as designed

## Acceptance Criteria

### train Command (Interactive)
- [ ] Accepts `pluginStorage` and an input directory path as arguments
- [ ] **Step 1 — Category management**: lists existing categories found in `pluginStorage` (`.css` filenames without extension)
- [ ] If no categories exist in `pluginStorage`, prompts user to enter one or more initial category names
- [ ] If categories exist, prompts user to optionally add new category names before starting the labeling loop
- [ ] **Step 2 — Document labeling loop**: iterates over documents in the input directory by invoking `doc.doc.sh process` (full pipeline) to extract text
- [ ] Displays the file path and first 100 words of extracted text before each labeling prompt
- [ ] Per document/category pair, prompts the user with y/n:
  - [ ] "y" → runs `csslearn` to train the category model with the document text
  - [ ] "n" → runs `cssunlearn` to anti-train the category model with the document text
- [ ] All `.css` model files are read from and written to `pluginStorage` exclusively
- [ ] `pluginStorage` path is validated before any file I/O (REQ_SEC_005)

### learn Command (Non-Interactive)
- [ ] Reads JSON from stdin with `category` (required) and `pluginStorage` (required) fields
- [ ] Accepts document text to train on via an additional `filePath` field or piped text
- [ ] Runs `csslearn` to train the specified category model with the provided text
- [ ] Outputs `{"success": true/false, "message": "..."}` to stdout
- [ ] Category name is sanitized (alphanumeric, dash, underscore, dot only) to prevent path traversal (REQ_SEC_005)
- [ ] Initializes the `.css` model file if it does not yet exist

### unlearn Command (Non-Interactive)
- [ ] Reads JSON from stdin with `category` (required) and `pluginStorage` (required) fields
- [ ] Accepts document text to remove via an additional `filePath` field or piped text
- [ ] Runs `cssunlearn` to remove the specified text from the category model
- [ ] Outputs `{"success": true/false, "message": "..."}` to stdout
- [ ] Fails gracefully (exit 1, JSON error output) if the `.css` model file does not exist

### listCategories Command
- [ ] Reads JSON from stdin with `pluginStorage` (required) field
- [ ] Lists all category names that have a trained `.css` model in `pluginStorage`
- [ ] Outputs `{"categories": ["cat1", "cat2", ...]}` to stdout
- [ ] Returns an empty array `[]` if no trained models exist (not an error)

### descriptor.json
- [ ] `train`, `learn`, `unlearn`, and `listCategories` commands are registered in `descriptor.json` with correct input/output schemas
- [ ] Each command entry references the correct `.sh` script file

### Security
- [ ] All `pluginStorage` paths validated against path traversal before any file I/O (REQ_SEC_005)
- [ ] All category names sanitized (no shell metacharacters, no `..` segments)
- [ ] All JSON input validated before use (REQ_SEC_009)
- [ ] No temporary files used — text passed to CRM114 tools via stdin only

### Tests
- [ ] `tests/test_feature_0042.sh` covers all four new commands
- [ ] Tests skip gracefully when `crm114` / `csslearn` / `cssunlearn` are not available
- [ ] Security tests verify category name sanitization and pluginStorage path validation
- [ ] All existing tests continue to pass

## Scope

### In Scope
- `train.sh` — interactive training command
- `learn.sh` — non-interactive learn command
- `unlearn.sh` — non-interactive unlearn command
- `listCategories.sh` — list trained categories command
- Updates to `descriptor.json` to register all four commands
- TDD test suite `tests/test_feature_0042.sh`

### Out of Scope
- Changes to the `process` command (already implemented in FEATURE_0003)
- Score normalization or probability calibration
- GUI or web interface
- Non-CRM114 classification backends

## Technical Requirements

- CRM114 binaries (`csslearn`, `cssunlearn`, `cssutil`) must be available on PATH
- `.css` database files stored at `<pluginStorage>/<categoryName>.css`
- Text content passed to CRM114 commands via stdin (no temporary files)
- `pluginStorage` path validated before any file I/O
- JSON input/output follows the plugin I/O protocol (stdin → stdout)
- `train` command invokes `doc.doc.sh process` as a subprocess for text extraction (loose coupling, as specified in FEATURE_0003)
- Consistent use of `plugin_input.sh` helpers for JSON parsing and path validation

## Dependencies

### Blocking Items
- **FEATURE_0041** (Plugin Storage Plumbing) — already DONE; `pluginStorage` injection is available

### Blocks These Features
None

### Related Requirements
- **REQ_0003**: Plugin-Based Architecture
- **REQ_0029**: Plugin State Storage
- **REQ_SEC_001**: Input Validation and Sanitization
- **REQ_SEC_005**: Path Traversal Prevention
- **REQ_SEC_009**: JSON Input Validation

## Related Links

### Parent Feature
- [FEATURE_0003: CRM114 Text Classification Plugin](../06_done/FEATURE_0003_crm114_text_classification_plugin.md)

### Requirements
- [REQ_0003: Plugin-Based Architecture](../../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-system.md)
- [REQ_0029: Plugin State Storage](../../../02_project_vision/02_requirements/03_accepted/REQ_0029_plugin-state-storage.md)
- [REQ_SEC_001: Input Validation and Sanitization](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_001_input_validation_sanitization.md)
- [REQ_SEC_005: Path Traversal Prevention](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md)
