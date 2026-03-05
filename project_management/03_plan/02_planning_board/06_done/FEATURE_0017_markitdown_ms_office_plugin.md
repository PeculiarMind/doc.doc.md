# Markitdown MS Office Plugin

- **ID:** FEATURE_0017
- **Priority:** Medium
- **Type:** Feature
- **Created at:** 2026-03-05
- **Created by:** Product Owner
- **Status:** DONE
- **Assigned to:** developer

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Dependencies](#dependencies)
5. [Related Links](#related-links)

## Overview

Implement a `markitdown` plugin that converts MS Office documents to markdown text using the [markitdown](https://github.com/microsoft/markitdown) Python library. The plugin slots into the standard plugin chain and contributes extracted document content as `documentText` to the markdown output.

**Command signature (process phase):**
```
doc.doc.sh process <inputDir> <outputDir> [--include ...] [--exclude ...]
```
The plugin is invoked automatically per-file during the `process` command when the file's MIME type matches a supported MS Office type.

**Supported MS Office MIME types:**

| Extension | MIME Type |
|-----------|-----------|
| `.docx` | `application/vnd.openxmlformats-officedocument.wordprocessingml.document` |
| `.xlsx` | `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` |
| `.pptx` | `application/vnd.openxmlformats-officedocument.presentationml.presentation` |
| `.doc` | `application/msword` |
| `.xls` | `application/vnd.ms-excel` |
| `.ppt` | `application/vnd.ms-powerpoint` |

**Current state:** No plugin exists for processing MS Office files. These files are currently processed without any content extraction, meaning their textual content is absent from the generated markdown output.

**Business value:**
- Unlocks content extraction from the most widely used document formats in home and office environments
- Enables Obsidian-compatible markdown output enriched with the full text of Word, Excel, and PowerPoint files
- Consistent with the project's goal of processing heterogeneous document collections without a full DMS
- Leverages Microsoft's own open-source `markitdown` library, ensuring format coverage is well-maintained

**What this delivers:**
- A `markitdown` plugin under `doc.doc.md/plugins/markitdown/` following the standard four-file plugin structure (`descriptor.json`, `main.sh`, `install.sh`, `installed.sh`)
- `main.sh` accepts JSON input with `filePath` and `mimeType`, gates on supported MS Office MIME types, invokes `markitdown` to convert the file, and returns `documentText` in the JSON output
- `install.sh` installs `markitdown` via `pip` (requires Python 3 and pip)
- `installed.sh` checks whether `markitdown` is available on `PATH`
- The `descriptor.json` declares `file` as a required dependency (to provide `mimeType` for the MIME gate)

## Acceptance Criteria

### Plugin Structure

- [ ] Plugin directory `doc.doc.md/plugins/markitdown/` contains `descriptor.json`, `main.sh`, `install.sh`, and `installed.sh`
- [ ] `descriptor.json` declares the plugin `name`, `version`, `description`, `active` flag, `dependencies` (requires `file`), and a `process` command with `input`/`output` JSON schemas
- [ ] `descriptor.json` passes the existing plugin descriptor validation (`REQ_SEC_003`)

### Installation

- [ ] `install.sh` installs `markitdown` via `pip install markitdown` (or equivalent) and exits with code 0 on success
- [ ] `installed.sh` outputs `{"installed": true}` when `markitdown` is available, `{"installed": false}` otherwise

### Process Command — Happy Path

- [ ] `main.sh` reads JSON from stdin containing at minimum `filePath` and `mimeType`
- [ ] Given a `.docx`, `.xlsx`, `.pptx`, `.doc`, `.xls`, or `.ppt` file with a matching MIME type, `main.sh` invokes `markitdown` on the file and outputs a JSON object containing `documentText` with the extracted markdown content
- [ ] Output JSON exits with code 0 on successful conversion

### Process Command — MIME Gate

- [ ] Given a `mimeType` that is **not** in the supported MS Office list, `main.sh` outputs an error message to stderr and exits with code 1
- [ ] The file is not processed when the MIME type is unsupported (no partial output)

### Process Command — Error Handling

- [ ] If `filePath` is missing or empty in the input JSON, `main.sh` writes an error to stderr and exits with code 1
- [ ] If the file does not exist at `filePath`, `main.sh` writes an error to stderr and exits with code 1
- [ ] If `markitdown` conversion fails (non-zero exit from the tool), `main.sh` writes the error to stderr and exits with code 1
- [ ] No internal paths, stack traces, or system details are leaked to stdout on error (`REQ_SEC_006`)

### Security

- [ ] `filePath` is validated and canonicalized with `readlink -f`; traversal into `/proc`, `/dev`, `/sys`, `/etc` is rejected (`REQ_SEC_005`, `REQ_SEC_001`)
- [ ] Input JSON is validated for required fields before use (`REQ_SEC_001`)
- [ ] Plugin does not execute any shell-constructed command with unsanitized user-supplied values (`REQ_SEC_001`)

### Integration

- [ ] `doc.doc.sh install plugins --all` installs the markitdown plugin without errors
- [ ] `doc.doc.sh list plugins` lists `markitdown` as an available plugin after installation
- [ ] `doc.doc.sh process <inputDir> <outputDir>` — when a supported MS Office file is in `inputDir`, the generated markdown for that file contains the `documentText` section populated by the plugin

## Scope

**In scope:**
- Plugin implementing conversion of MS Office OOXML formats (`.docx`, `.xlsx`, `.pptx`) and legacy binary formats (`.doc`, `.xls`, `.ppt`) via `markitdown`
- MIME-type gate (only process supported types)
- Installation via `pip install markitdown`
- Standard four-file plugin structure
- Security hardening (path validation, input sanitization, no information disclosure)

**Out of scope:**
- Support for non-Office formats (PDF, images, ODT/ODS/ODP — LibreOffice formats) — these belong in separate plugins
- Any GUI or interactive conversion interface
- Conversion quality tuning or post-processing of `markitdown` output
- Caching or incremental processing of already-converted files

## Dependencies

- REQ_0002 (Modular and Extensible Architecture)
- REQ_0003 (Plugin-Based Architecture)
- REQ_0007 (Markdown Output Format)
- REQ_0009 (Process Command)
- REQ_SEC_001 (Input Validation & Sanitization)
- REQ_SEC_003 (Plugin Descriptor Validation)
- REQ_SEC_005 (Path Traversal Prevention)
- REQ_SEC_006 (Error Information Disclosure Prevention)
- FEATURE_0007 (File Plugin First in Chain and MIME Filter Gate, DONE) — establishes `mimeType` passing contract

## Related Links

- Project Goals: [project_goals.md](../../../02_project_vision/01_project_goals/project_goals.md)
- Requirements: [REQ_0002](../../../02_project_vision/02_requirements/03_accepted/REQ_0002_modular-extensible-architecture.md), [REQ_0003](../../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-based-architecture.md), [REQ_0007](../../../02_project_vision/02_requirements/03_accepted/REQ_0007_markdown-output-format.md)
- Architecture: [05_building_block_view.md](../../../../project_documentation/01_architecture/05_building_block_view/05_building_block_view.md)

## Workflow Assessment Log

### Step 5: Tester Assessment
- **Date:** 2026-03-05
- **Agent:** tester.agent
- **Result:** PASS
- **Report:** [TESTREP_004](../../../04_reporting/02_tests_reports/TESTREP_004_FEATURE_0017_markitdown_plugin.md)
- **Summary:** All 45 tests pass. Plugin structure, descriptor validation, input validation, MIME-type gating, path traversal prevention, and CLI integration (`list`, `tree`) all verified. Environment-constrained tests (markitdown binary not in CI) noted as non-defects.

### Step 6: Architect Assessment
- **Date:** 2026-03-05
- **Agent:** architect.agent
- **Result:** PASS
- **Report:** [ARCHREV_006](../../../04_reporting/01_architecture_reviews/ARCHREV_006_FEATURE_0017_markitdown_plugin.md)
- **Summary:** Fully compliant with ADR-003 (four-file structure, JSON stdin/stdout, jq usage, lowerCamelCase, no `dependencies` key) and ARC-0003 (standard commands, plugin interface contract). Dependency on `file` plugin correctly expressed via `mimeType` parameter name matching.

### Step 7: Security Assessment
- **Date:** 2026-03-05
- **Agent:** security.agent
- **Result:** Issues Found
- **Report:** [SECREV_006](../../../04_reporting/03_security_reviews/SECREV_006_FEATURE_0017_markitdown_plugin.md)
- **Summary:** One medium-severity issue found: `main.sh` reads stdin without a size limit (`cat` instead of `head -c 1048576`), inconsistent with the 1 MB standard established by BUG_0001. BUG_0006 filed in backlog for remediation.

### Step 8: License Assessment
- **Date:** 2026-03-05
- **Agent:** license.agent
- **Result:** PASS
- **Summary:** `markitdown` (Microsoft, MIT License) is invoked as an external shell process — not imported, linked, or distributed with this project. No license propagation applies. MIT is compatible with AGPL-3.0 for external-tool invocation. CREDITS.md updated to acknowledge `markitdown` and document the invocation-only relationship.

### Step 9: Documentation Assessment
- **Date:** 2026-03-05
- **Agent:** documentation.agent
- **Result:** CHANGES MADE
- **Summary:** README.md updated: `markitdown` added to Built-in Plugins list and Project Structure tree. `user_guide.md` updated: new `markitdown` plugin section added (description, supported types, output fields, install commands), `{{documentText}}` added to template variables table, built-in plugins trust table updated. `dev_guide.md` updated: `markitdown/` added to project structure tree, `{{documentText}}` added to template variables, optional dev dependency noted.
