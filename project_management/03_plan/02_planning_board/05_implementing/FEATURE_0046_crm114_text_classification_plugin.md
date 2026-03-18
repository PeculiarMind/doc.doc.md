# CRM114 Text Classification Plugin

- **ID:** FEATURE_0046
- **Priority:** MEDIUM
- **Type:** Feature
- **Created at:** 2026-03-15
- **Created by:** PeculiarMind
- **Status:** IMPLEMENTING
- **TDD Status:** DONE — `tests/test_feature_0046.sh` (94 passed, 0 failed, 9 skipped when crm114 not installed)


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
- Adds a powerful categorization capability to the toolchain
- Validates that the `pluginStorage` pattern works correctly for stateful plugins

**What this delivers:**
- `crm114` plugin that classifies a file's text content and returns the classification result and probability score (confidence score)
- Persistent CRM114 models stored in `pluginStorage` (`.doc.doc.md/crm114/` under the output folder)
- `manageCategories` command: one-time interactive setup (run via `doc.doc.sh run`) that lists, adds, and removes category names in `pluginStorage`
- `train` command: **per-document** interactive labeling command designed to be driven by `doc.doc.sh loop`; receives a single document's pre-extracted context on stdin, displays file path and first 100 words, and prompts the user to train (t), untrain (u), or skip (s) per category
- `learn` / `unlearn` commands: non-interactive scripted training
- `listCategories` command to inspect which categories have trained models in `pluginStorage`
- Standard plugin commands: `process`, `install`, `installed`
- Reference implementation for stateful per-document interactive plugins using `pluginStorage` and `loop`

**Typical interactive training workflow:**
```
# 1. Set up categories once
./doc.doc.sh run crm114 manageCategories -o <outputDir>

# 2. Label documents interactively (loop drives iteration, train handles each doc)
./doc.doc.sh loop -d <docsDir> -o <outputDir> --plugin crm114 train
```

### Required Tools
- bash 4.0+
- jq (JSON processor)
- crm114 (CRM114 Discriminator — installable via `apt install crm114` or `brew install crm114`)

## Acceptance Criteria

### process Command
- [ ] Accepts the following input parameters via JSON on stdin: 
  - `filePath` (required) and 
  - `pluginStorage` (required). `pluginStorage` will be derived by doc.doc.md based on the output folder and is injected by doc.doc.md as per REQ_0029.
  - `textContent` (required) containing the text extracted from the document, provided by doc.doc.md's processing pipeline (full pipeline via `doc.doc.sh process`) to avoid coupling the plugin to text extraction details.
- [ ] Classifies document text using CRM114 and returns a `categories` JSON object on stdout
```json
{
  "categories": [
     {
       "categoryName": "<categoryName1>",
       "pR": <pR_value1>
     },
     {
       "categoryName": "<categoryName2>",
       "pR": <pR_value2>
     }
     ...
  ]
}
```
- [ ] doc.doc.md will interpret the `categories` output and attach it to the document's metadata in the output collection
- [ ] If no trained categories exist in `pluginStorage`, plugin exits with code 65 (skip — ADR-004)
- [ ] If the document yields no extractable text, plugin exits with code 65

### manageCategories Command (Interactive — run once via `doc.doc.sh run`)
- [ ] Reads `pluginStorage` from JSON on stdin (injected by `doc.doc.sh run -o <outputDir>`)
- [ ] Lists existing category names found in `pluginStorage` (`.css` filenames without extension)
- [ ] If no categories exist, prompts user to enter one or more initial category names
- [ ] If categories exist, prompts user to optionally add or remove category names
- [ ] Initializes the `.css` model file for each new category
- [ ] Removes the `.css` model file for each deleted category (with confirmation prompt)
- [ ] All `.css` model files are read from and written to `pluginStorage` exclusively

### train Command (Per-document interactive — invoked by `doc.doc.sh loop`)
- [ ] Designed to be invoked once per document by `doc.doc.sh loop -d <docsDir> -o <outputDir> --plugin crm114 train`
- [ ] Accepts the following input parameters via JSON on stdin (all injected by `loop` from the pre-executed pipeline context):
  - `filePath` (required)
  - `pluginStorage` (required, derived from `-o` by `loop` per FEATURE_0041)
  - `textContent` and/or `ocrText` — at least one required; extracted by the pipeline upstream
- [ ] If no categories exist in `pluginStorage`, prints a message instructing the user to run `manageCategories` first and exits with code 65 (skip — ADR-004)
- [ ] Displays the file path and first 100 words of extracted text before the labeling prompt
- [ ] Per category, prompts the user with:
  - [ ] **"t"** (train) → runs `csslearn` to add the document text to the category model
  - [ ] **"u"** (untrain) → runs `cssunlearn` to remove the document text from the category model
  - [ ] **"s"** (skip) → leaves the category model unchanged for this document
- [ ] Does **not** iterate over documents itself; document iteration is delegated entirely to `doc.doc.sh loop`
- [ ] All `.css` model files are read from and written to `pluginStorage` exclusively



### learn Command (Non-Interactive)
- [ ] Reads JSON from stdin with `filePath` (required), `category` (required), `pluginStorage` (required), and `textContent` or `ocrText` (at least one required)
- [ ] Runs `csslearn` to train the specified category model with the provided text
- [ ] Outputs `{"success": true, "category": "<name>"}` to stdout on success
- [ ] Category name is sanitized (alphanumeric, dash, underscore, dot only) to prevent path traversal (REQ_SEC_005)
- [ ] Initializes the `.css` model file if it does not yet exist

### unlearn Command (Non-Interactive)
- [ ] Reads JSON from stdin with `filePath` (required), `category` (required), `pluginStorage` (required), and `textContent` or `ocrText` (at least one required)
- [ ] Runs `cssunlearn` to remove the document text from the specified category model
- [ ] Outputs `{"success": true, "category": "<name>"}` to stdout on success
- [ ] Fails gracefully (exit 1, JSON error output) if the `.css` model file does not exist

### listCategories Command
- [ ] Reads JSON from stdin with `pluginStorage` (required)
- [ ] Lists all category names that have a trained `.css` model in `pluginStorage`
- [ ] Outputs `{"categories": ["cat1", "cat2", ...]}` to stdout
- [ ] Returns an empty array `[]` if no trained models exist (not an error)

### install / installed Commands
- [ ] `install` installs the `crm114` system dependency
- [ ] `installed` exits 0 if `crm114` is available on PATH, non-zero otherwise

### Storage and Security
- [ ] All `.css` model files stored exclusively under `pluginStorage`; no state written elsewhere
- [ ] `pluginStorage` path is validated to prevent path traversal before any file I/O (REQ_SEC_005)
- [ ] All JSON input is validated before processing (REQ_SEC_009)

## Technical Requirements

- CRM114 binaries (`csslearn`, `cssunlearn`, `crmclassify`) must be available on PATH
- `.css` database files stored at `<pluginStorage>/<categoryName>.css`
- Text content passed to CRM114 commands via stdin (no temporary files)
- `pluginStorage` path validated (no `..` path segments) before any file I/O
- JSON input/output follows the plugin I/O protocol (stdin → stdout)
- Exit code 65 (ADR-004) used for intentional skips
- `train` command receives pre-extracted text in JSON on stdin; it does **not** invoke `doc.doc.sh` as a subprocess or iterate over documents — document iteration is the sole responsibility of `doc.doc.sh loop` (FEATURE_0045)
- `manageCategories` and `train` commands declare themselves as interactive-only in `descriptor.json` so that `loop` and `run` can guard against non-TTY invocations

## Scope

### In Scope
- `crm114` plugin directory with `descriptor.json` and all command scripts
- `process.sh` — pipeline classification command
- `manageCategories.sh` — interactive one-time category setup command
- `train.sh` — per-document interactive labeling command (designed for `loop`)
- `learn.sh` — non-interactive learn command
- `unlearn.sh` — non-interactive unlearn command
- `listCategories.sh` — list trained categories command
- `install.sh` and `installed.sh`
- TDD test suite `tests/test_feature_0046.sh`

### Out of Scope
- Changes to `doc.doc.sh`, `plugin_execution.sh`, or any other core component
- Changes to the `loop` or `run` commands (already defined in FEATURE_0045 / FEATURE_0043)
- Score normalization or probability calibration
- Non-interactive batch training mode for `train` (use `learn` for scripted workflows)

## Dependencies

- **FEATURE_0045** (`loop` command): document iteration for the `train` interactive labeling workflow
- **FEATURE_0041** (plugin storage plumbing): `pluginStorage` derivation and injection
- **FEATURE_0043** (`run` command): invocation of `manageCategories` and one-shot plugin commands
- **FEATURE_0044** (`run` with `-d`/`-o`): `pluginStorage` derivation from `-o` in `run`
- **ADR-004** (exit code 65 skip contract)
- **REQ_0029** (plugin storage convention)

## Related Links
- Architecture Vision: `project_documentation/01_architecture/`
- Requirements: `project_management/02_project_vision/02_requirements/`
- FEATURE_0041: `project_management/03_plan/02_planning_board/06_done/FEATURE_0041_plugin-storage-plumbing.md`
- FEATURE_0043: `project_management/03_plan/02_planning_board/06_done/FEATURE_0043_plugin-command-runner.md`
- FEATURE_0044: `project_management/03_plan/02_planning_board/06_done/FEATURE_0044_run-command-derive-pluginstorage-from-output-dir.md`
- FEATURE_0045: `project_management/03_plan/02_planning_board/04_backlog/FEATURE_0045_loop-command-interactive-document-pipeline.md`
