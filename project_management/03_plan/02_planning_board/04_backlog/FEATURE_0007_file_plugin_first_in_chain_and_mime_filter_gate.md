# File Plugin as Processing Chain Gate with MIME Type Filter

- **ID:** FEATURE_0007
- **Priority:** HIGH
- **Type:** Feature
- **Created at:** 2026-03-03
- **Created by:** Product Owner
- **Status:** Backlog

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

The `file` plugin must be executed as the **first** plugin in the processing chain for every file. Its output — specifically the `mimeType` field — is consumed by doc.doc's filter logic immediately after execution. If the filter determines that the file's MIME type matches an exclude criterion or does not match any include criterion, the file is **silently skipped**: no output file is created, no entry is added to the mirrored directory structure, and doc.doc proceeds with the next file.

**Business Value:**
- Enables accurate MIME type-based filtering at the earliest possible point, avoiding wasted work by downstream plugins on files that will ultimately be excluded
- Ensures the filter's MIME type criteria (specified via `--include` and `--exclude`) are evaluated against the actual detected MIME type of each file, not just its extension
- Keeps the output directory clean: excluded files leave no trace in the mirror
- Provides a clear, consistent contract — the `file` plugin always runs first, all other plugins can rely on MIME type being known

**What this delivers:**
- `file` plugin already outputs `mimeType` — no changes to the plugin itself are required
- doc.doc processing pipeline enforces `file` as the mandatory first plugin regardless of user-configured plugin order
- Filter logic applied after `file` plugin execution; files rejected by the filter are silently aborted
- Skipped files produce no markdown output and no mirrored directory entry
- doc.doc continues processing the next file without error or warning for skipped files

## Acceptance Criteria

### file Plugin — No Changes Required

- [ ] `doc.doc.md/plugins/file/descriptor.json` already declares `mimeType` as an output field of type `string` on the `process` command — no changes needed
- [ ] `doc.doc.md/plugins/file/main.sh` already outputs a `mimeType` field — no changes needed
- [ ] `mimeType` is a non-empty string (e.g., `"application/pdf"`, `"text/plain"`)

**Example output from the existing file plugin:**
```json
{
  "mimeType": "application/pdf"
}
```

### Processing Chain — file Plugin Executes First

- [ ] doc.doc's planning phase always places the `file` plugin at position 0 in the execution order, regardless of user-configured plugin activation order or declared plugin dependencies
- [ ] If the `file` plugin is not active or not installed, the `process` command aborts with a clear error message before processing any files
- [ ] All other active plugins execute after the `file` plugin has completed successfully for each file
- [ ] The `mimeType` value from the `file` plugin's output is available to the filter logic before any other plugin processes the file

### Filter Gate — MIME Type Evaluation

- [ ] After `stat` executes for a file, doc.doc evaluates the `mimeType` output against the active `--include` and `--exclude` filter criteria
- [ ] If the file's `mimeType` matches an exclude criterion, the file is **silently skipped** (no log entry, no warning, no error)
- [ ] If `--include` criteria are specified and the file's `mimeType` does not satisfy them, the file is **silently skipped**
- [ ] Filter evaluation for MIME types follows the existing AND/OR logic defined in REQ_0009:
  - OR within a single `--include` or `--exclude` parameter (comma-separated)
  - AND between multiple `--include` or `--exclude` parameters
- [ ] MIME type filter criteria are recognized by the filter engine when they contain a `/` character (e.g., `application/pdf`, `text/plain`, `image/*`)
- [ ] Glob-style MIME type patterns are supported (e.g., `image/*` matches `image/jpeg`, `image/png`)

### Skipped File Behavior

- [ ] No markdown output file is created for a skipped file
- [ ] No directory entry is created in the mirrored output directory for a skipped file (the directory itself is not created if all its files are skipped)
- [ ] doc.doc does **not** log a message for each skipped file (silent abort)
- [ ] doc.doc continues to the next file in the input collection immediately after a skip decision
- [ ] Other plugins (after stat) are **not** invoked for skipped files

### Backward Compatibility

- [ ] Files without explicit MIME type filter criteria are unaffected: if no MIME type patterns appear in `--include` or `--exclude`, the filter behavior is identical to the pre-feature behavior
- [ ] Extension-based and glob-based filter criteria continue to work as before
- [ ] Existing tests for the `stat` plugin pass (new `mimeType` field is additive)

## Scope

### In Scope
✅ `file` plugin already provides `mimeType` — no plugin changes required  
✅ Processing pipeline enforces `file` as first plugin  
✅ Filter logic extended to evaluate MIME type criteria using stat's `mimeType` output  
✅ Silent skip behavior for MIME-type-excluded files  
✅ No output file, no mirror directory entry for skipped files  
✅ MIME type glob pattern support in filter (e.g., `image/*`)  

### Out of Scope
❌ Changes to extension-based or glob-based filter logic (existing behavior unchanged)  
❌ Logging or reporting of skipped file counts (future enhancement)  
❌ User-configurable override to disable file-first enforcement  
❌ Plugin dependency graph changes beyond enforcing file-first position  
❌ MIME type detection for directories or special files  
❌ Changes to the `file` plugin implementation (already outputs `mimeType`)  

## Technical Requirements

### Architecture Compliance

- **REQ_0009 — Process Command**:
  - MIME type filter criteria identified by presence of `/` in the criterion string
  - Glob-style MIME matching (e.g., `image/*`) handled by `fnmatch` or equivalent
  - AND/OR filter logic unchanged; MIME type criteria participate alongside extension and glob criteria

- **REQ_0003 — Plugin-Based Architecture**:
  - file-first enforcement is a pipeline-level concern, not a plugin-level concern
  - `file` plugin remains a standard plugin (communicates via JSON stdin/stdout)
  - The pipeline passes the `file` plugin's output directly to the filter gate before invoking remaining plugins

- **REQ_0013 — Directory Mirroring**:
  - Output directories for a file are only created when the file passes the filter gate
  - Skipped files leave no trace in the output directory tree

- **REQ_SEC_002 — Filter Logic Correctness**:
  - MIME type filter must be covered by tests verifying include/exclude correctness
  - Edge cases: wildcard MIME types (`*/*`), unknown MIME type fallback

### Implementation Notes

**MIME type criterion detection in `filter.py`:**
- A criterion containing `/` and no `*` at start/end is treated as a literal MIME type match
- A criterion containing `/` and `*` (e.g., `image/*`) is treated as a glob MIME pattern
- `fnmatch.fnmatch(mime_type, criterion)` handles both literal and glob cases

**file-first enforcement in `doc.doc.sh` planning phase:**
- After plugin dependency resolution, move `file` to index 0 in the execution list
- If `file` is absent from the active plugin list, abort with: `"Error: file plugin must be active and installed to run the process command."`

**Filter gate integration in document processing phase:**
- Execute `file` plugin for the file
- Pass `mimeType` from `file` plugin output to filter logic alongside file path
- If filter returns `exclude`: skip to next file, do not invoke remaining plugins

### Required Tools
- bash 4.0+
- jq (JSON processor)
- `file` command (part of `file` package, standard on Linux/macOS)

## Dependencies

### Blocking Items
- **FEATURE_0002** (stat and file plugins) must be in `done` — `file` plugin must exist ✅ (already done)
- **REQ_0009** must be accepted — MIME type filtering is part of the process command spec ✅ (already accepted)

### Blocks These Features
- Any feature relying on MIME type availability in plugin outputs or templates

### Related Requirements
- **REQ_0003**: Plugin-Based Architecture
- **REQ_0009**: Process Command — MIME type filter criteria
- **REQ_0013**: Directory Mirroring — skipped files produce no output directory entry
- **REQ_SEC_002**: Filter Logic Correctness

## Related Links

### Requirements
- [REQ_0003: Plugin-Based Architecture](../../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-system.md)
- [REQ_0009: Process Command](../../../02_project_vision/02_requirements/03_accepted/REQ_0009_process-command.md)
- [REQ_0013: Directory Mirroring](../../../02_project_vision/02_requirements/03_accepted/REQ_0013_directory-mirroring.md)
- [REQ_SEC_002: Filter Logic Correctness](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_002_filter_logic_correctness.md)

### Existing Plugin Reference
- [file plugin](../../../../doc.doc.md/plugins/file/)
- [filter component](../../../../doc.doc.md/components/filter.py)

### Completed Feature
- [FEATURE_0002: Stat and File Plugins](../../06_done/FEATURE_0002_implement_stat_and_file_plugins.md)
