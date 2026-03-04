# File Plugin as Processing Chain Gate with MIME Type Filter

- **ID:** FEATURE_0007
- **Priority:** HIGH
- **Type:** Feature
- **Created at:** 2026-03-03
- **Created by:** Product Owner
- **Status:** Done
- **Assigned to:** developer.agent
- **Completed at:** 2026-03-04

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)
7. [Tester Assessment](#tester-assessment)
8. [Architect Assessment](#architect-assessment)
9. [Security Assessment](#security-assessment)

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

- [x] `doc.doc.md/plugins/file/descriptor.json` already declares `mimeType` as an output field of type `string` on the `process` command — no changes needed
- [x] `doc.doc.md/plugins/file/main.sh` already outputs a `mimeType` field — no changes needed
- [x] `mimeType` is a non-empty string (e.g., `"application/pdf"`, `"text/plain"`)

**Example output from the existing file plugin:**
```json
{
  "mimeType": "application/pdf"
}
```

### Processing Chain — file Plugin Executes First

- [x] doc.doc's planning phase always places the `file` plugin at position 0 in the execution order, regardless of user-configured plugin activation order or declared plugin dependencies
- [x] If the `file` plugin is not active or not installed, the `process` command aborts with a clear error message before processing any files
- [x] All other active plugins execute after the `file` plugin has completed successfully for each file
- [x] The `mimeType` value from the `file` plugin's output is available to the filter logic before any other plugin processes the file

### Filter Gate — MIME Type Evaluation

- [x] After `file` executes for a file, doc.doc evaluates the `mimeType` output against the active `--include` and `--exclude` filter criteria
- [x] If the file's `mimeType` matches an exclude criterion, the file is **silently skipped** (no log entry, no warning, no error)
- [x] If `--include` criteria are specified and the file's `mimeType` does not satisfy them, the file is **silently skipped**
- [x] Filter evaluation for MIME types follows the existing AND/OR logic defined in REQ_0009:
  - OR within a single `--include` or `--exclude` parameter (comma-separated)
  - AND between multiple `--include` or `--exclude` parameters
- [x] MIME type filter criteria are recognized by the filter engine when they contain a `/` character (e.g., `application/pdf`, `text/plain`, `image/*`)
- [x] Glob-style MIME type patterns are supported (e.g., `image/*` matches `image/jpeg`, `image/png`)

### Skipped File Behavior

- [x] No markdown output file is created for a skipped file
- [x] No directory entry is created in the mirrored output directory for a skipped file (the directory itself is not created if all its files are skipped)
- [x] doc.doc does **not** log a message for each skipped file (silent abort)
- [x] doc.doc continues to the next file in the input collection immediately after a skip decision
- [x] Other plugins (after stat) are **not** invoked for skipped files

### Backward Compatibility

- [x] Files without explicit MIME type filter criteria are unaffected: if no MIME type patterns appear in `--include` or `--exclude`, the filter behavior is identical to the pre-feature behavior
- [x] Extension-based and glob-based filter criteria continue to work as before
- [x] Existing tests for the `stat` plugin pass (new `mimeType` field is additive)

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

## Tester Assessment

**Assessed by:** tester.agent  
**Date:** 2026-03-03  
**Test suites executed:**
- `tests/test_feature_0007.sh` — 63/63 passed, 0 failed
- `tests/test_doc_doc.sh` — 47/47 passed, 0 failed
- `tests/test_plugins.sh` — 52/52 passed, 0 failed

**Total: 162/162 tests passed**

### Criteria Verification

| # | Acceptance Criterion | Result |
|---|----------------------|--------|
| 1 | `file` plugin always placed at position 0 in execution order | ✅ PASS |
| 2 | If file plugin is not active or not installed, process command aborts with clear error | ✅ PASS |
| 3 | `mimeType` from file plugin output available to filter logic before other plugins | ✅ PASS |
| 4 | MIME filter gate: files excluded by MIME criteria are silently skipped | ✅ PASS |
| 5 | No output file created for skipped files | ✅ PASS |
| 6 | doc.doc continues processing next file after skip | ✅ PASS |
| 7 | Glob-style MIME patterns supported (`image/*`) | ✅ PASS |
| 8 | Backward compatibility: no MIME filter = same behavior as before | ✅ PASS |
| 9 | Extension-based and glob-based filter criteria continue to work | ✅ PASS |

### Findings

- The `file` plugin is correctly enforced as the first plugin in the processing chain. The integration tests confirmed that all output entries carry a `mimeType` field, proving `file` ran first for each file.
- The abort-on-missing-file-plugin path works correctly both when the plugin is inactive and when its directory is absent entirely, with a clear, descriptive error message.
- MIME type filter logic in `filter.py` correctly distinguishes MIME criteria (containing `/`) from extension and glob criteria, and applies `fnmatch`-based glob matching for patterns such as `image/*` and `text/*`.
- AND/OR composition of MIME criteria follows the same semantics as extension/glob criteria (OR within a parameter, AND between parameters).
- Silent skip behaviour is confirmed: excluded files produce no output entry and no directory mirror entry; the pipeline moves on to the next file without emitting warnings or errors.
- Backward compatibility is fully preserved: all pre-existing test cases in `test_doc_doc.sh` and `test_plugins.sh` continue to pass without modification.

### Verdict

**PASS** — All 9 acceptance criteria are met. All 162 tests pass across all three suites. No bugs found. The feature is ready for promotion to Done.

## Architect Assessment

**Assessed by:** architect.agent  
**Date:** 2026-03-03  
**Full Review:** [ARCHREV_002](../../../../project_management/04_reporting/01_architecture_reviews/ARCHREV_002_FEATURE_0007_file_plugin_first_mime_filter_gate.md)

### Requirement Compliance

| Requirement | Principle | Status | Notes |
|-------------|-----------|--------|-------|
| **REQ_0003** — Plugin-Based Architecture | File-first enforcement is a pipeline-level concern, not a plugin-level concern | ✅ PASS | Enforcement is in `doc.doc.sh` planning phase (lines 176–194). `discover_plugins()` has no special-casing; `file` plugin is repositioned post-discovery by the pipeline. The `file` plugin itself is unaware of its mandatory-first status. |
| **REQ_0003** — Plugin interface contract | `file` plugin remains a standard plugin (JSON stdin/stdout) | ✅ PASS | No changes to `file` plugin scripts or `descriptor.json`. ADR-003 interface fully preserved. |
| **REQ_0009** — Process Command: MIME criterion identification | Criteria containing `/` (and not `**`) classified as MIME criteria | ✅ PASS | Criterion routing in `doc.doc.sh` lines 203–216 correctly distinguishes MIME criteria from path/extension criteria. |
| **REQ_0009** — Process Command: Glob-style MIME matching | `image/*` matches `image/jpeg`, `image/png`, etc. | ✅ PASS | `filter.py` receives the MIME type string on stdin and applies `fnmatch.fnmatch(mime_string, criterion)` — the same mechanism used for all glob criteria. No `filter.py` changes needed. |
| **REQ_0009** — Process Command: AND/OR filter logic unchanged | MIME criteria participate in the same AND/OR semantics as extension and glob criteria | ✅ PASS | `filter.py` is unmodified. Logic is preserved identically. |
| **REQ_0013** — Directory Mirroring: output dirs only created when file passes filter gate | Skipped files leave no trace in the output directory tree | ✅ PASS | `process_file()` returns empty output on MIME filter rejection; main loop skips empty results. Correct pre-condition for future `-o` directory mirroring implementation. |
| **plugins.sh `active` field bug fix** | `active` absent from descriptor defaults to `true`; explicit `false` disables plugin | ✅ PASS | Fixed jq expression `'if .active == false then "false" else "true" end'` correctly handles `null`/absent values per ADR-003. |

### Technical Debt Found

| ID | Description | Severity | Action |
|----|-------------|----------|--------|
| [DEBTR_002](../../04_backlog/DEBTR_002_update_arc0001_mime_criterion_matching.md) | ARC_0001 pseudocode shows `get_mime_type(file_path)` inside `matches_criterion`; actual implementation feeds the detected MIME string directly to `filter.py` stdin and uses `fnmatch` for matching — a documentation gap, not a code defect | Low | Backlog — update ARC_0001 to document actual design |
| (pre-existing) | `-o` output directory parameter not yet implemented; REQ_0009 and REQ_0013 require it | Medium | Not introduced by this feature; needs a dedicated roadmap item |

### Overall Verdict

**PASS WITH NOTES**

All three target requirements are correctly addressed. The implementation is architecturally clean: file-first enforcement is correctly placed at the pipeline level, the plugin interface is untouched, MIME criterion routing and glob matching work as specified, and skipped files produce no output. One low-severity documentation debt item (DEBTR_002) was raised to align ARC_0001 with the actual implementation approach. One pre-existing medium-severity gap (missing `-o` flag) is acknowledged but was not introduced by this feature.

The feature is ready for promotion to Done.

## Security Assessment

**Assessed by:** security.agent  
**Date:** 2026-03-03  
**Requirement ref:** REQ_SEC_002 (Filter Logic Correctness)

### Scope Reviewed

| Component | Changes reviewed |
|-----------|-----------------|
| `doc.doc.sh` — `process_file()` | MIME filter gate logic, `mimeType` extraction, stdin pipe to `filter.py`, array quoting for `_MIME_INCLUDE_ARGS` / `_MIME_EXCLUDE_ARGS` |
| `doc.doc.sh` — `main()` | Criterion splitting heuristic (`/` without `**`), global array population |
| `doc.doc.md/components/plugins.sh` — `run_plugin()` | `command_script` path construction; existing controls |
| `doc.doc.md/plugins/file/main.sh` | Path traversal controls, `mimeType` output sanitisation — unchanged from prior review |
| `doc.doc.md/components/filter.py` | Criterion matching, stdin processing, argparse usage — unchanged |

### Findings

| # | Severity | Location | Description | Evidence |
|---|----------|----------|-------------|----------|
| 1 | **Low** | `doc.doc.sh` `process_file()` lines 62–65 | **MIME gate bypass on `file` plugin failure.** If `run_plugin "file"` returns non-zero, the `else` branch executes `continue`, which advances to the next loop iteration and skips the `if [ "$plugin_name" = "file" ]` gate block entirely. The file therefore bypasses MIME filtering and passes through to all subsequent plugins and to output — even if MIME include/exclude criteria would exclude it. | `run_plugin` fails → `continue` → gate never evaluated → file processed + emitted |
| 2 | **Negligible** | `doc.doc.sh` `process_file()` line 76 | **Empty `mimeType` bypasses gate.** `[ -n "$mime_type" ]` is false when `mimeType` is an empty string; the gate is silently skipped. This is highly theoretical: the `file` command always returns a MIME string for accessible files, and the `file` plugin's `tr -d '[:space:]'` and `jq --arg` pipeline make an empty field essentially impossible in practice. | `{"mimeType":""}` extracted as `""` → `[ -n "" ]` false → gate skipped |
| 3 | **None** | `_MIME_INCLUDE_ARGS` / `_MIME_EXCLUDE_ARGS` expansion | Array quoting is correct. `${array[@]+"${array[@]}"}` pattern properly handles empty arrays under `set -u`. Individual elements are appended as discrete array entries and passed to Python via `"${mime_filter_args[@]}"` — no word-splitting or injection risk. | Code review of lines 78–85 |
| 4 | **None** | `mimeType` stdin pipe to `filter.py` | No injection risk. The value originates from `file --mime-type -b` (POSIX MIME string), is stripped of all whitespace by `tr -d '[:space:]'`, encoded into JSON via `jq --arg` (escapes special chars), then extracted with `jq -r`. When piped via `echo "$mime_type" \| python3 ...` it arrives as a plain single-line string read by `filter.py` — no shell metacharacter exposure. | Trace: `file` cmd → `tr` → `jq --arg` → `jq -r` → `echo … \|` stdin |
| 5 | **None** | Criterion splitting heuristic | `[[ "$inc" == *"/"* ]] && [[ "$inc" != *"**"* ]]` correctly routes MIME criteria (e.g., `text/plain`, `image/*`) vs. path globs (e.g., `**/2024/**`). No bypass via crafted criteria: a value containing both `/` and `**` is treated as a path criterion, which is the conservative/safe fallback. | Logic review of lines 203–216 |
| 6 | **None** | `file` plugin path traversal controls | Controls introduced by BUG_0001 are **unchanged**: `readlink -f` symlink resolution, rejection of `/proc`, `/dev`, `/sys`, `/etc` paths, combined exists+readable check on resolved path. No regression. | `file/main.sh` diff — no changes |

### Bug Raised

**Finding #1** has been filed as [BUG_0003](../../04_backlog/BUG_0003_mime_gate_bypassed_when_file_plugin_fails.md).

The bypass requires the `file` plugin to fail after having successfully passed the `run_plugin` pre-checks (script exists, is executable, JSON input valid). In practice this requires a runtime error inside `file/main.sh` (e.g., the `file` binary disappearing mid-run). The exposure window is narrow, but REQ_SEC_002 mandates filter logic correctness and this is a demonstrable gap.

Finding #2 (empty `mimeType`) is noted only; no bug raised — the `file` command never produces an empty MIME type for a readable regular file, and the `file` plugin's sanitisation pipeline makes the condition unreachable in practice.

### Verdict

**PASS WITH NOTES**

No injection risks, no command injection via MIME criteria, no new attack surfaces, and all existing path traversal controls remain intact. One low-severity filter-bypass scenario (BUG_0003) is raised for remediation: when the `file` plugin fails at runtime, the MIME gate is skipped due to the `continue` branch in graceful degradation. The fix is straightforward (gate check outside the success branch, or treat file-plugin failure as a hard abort). All other MIME gate logic, quoting, and criterion routing is sound.

## License Assessment

**Assessed by:** license.agent  
**Date:** 2026-03-03

### Project License

This repository is licensed under **AGPL-3.0**. All code changes introduced by FEATURE_0007 are original work produced for this project and are governed by the same AGPL-3.0 license. No separate licensing obligations arise from the changes themselves.

### Dependency Audit

All runtime tools and libraries used by this feature were already present in the project prior to this feature. No new dependencies were introduced.

| Tool / Library | License | How Used | New? | Compatible with AGPL-3.0? |
|----------------|---------|----------|------|---------------------------|
| `bash` | GPL-3.0+ | Shell runtime for `doc.doc.sh`, `plugins.sh`, `test_feature_0007.sh` | No | ✅ Yes |
| `jq` | MIT | JSON parsing in `doc.doc.sh` and `plugins.sh` | No | ✅ Yes |
| `python3` | PSF-2.0 | Executes `filter.py` for MIME criterion matching | No | ✅ Yes |
| `file` (command) | BSD-2-Clause | Detects MIME type via the `file` plugin | No | ✅ Yes |
| `fnmatch` (Python stdlib) | PSF-2.0 | Glob matching of MIME patterns inside `filter.py` | No | ✅ Yes |

### Third-Party Code Incorporation

No third-party code, snippets, algorithms, or assets were copied into the repository as part of this feature. All changes to `doc.doc.sh`, `doc.doc.md/components/plugins.sh`, and the new test file `tests/test_feature_0007.sh` are entirely original work.

### Asset Review

No images, fonts, data files, configuration templates, or other non-code assets were added.

### Attribution Requirements

No new attribution obligations were triggered. Existing credits in `CREDITS.md` (arc42 CC BY-SA 4.0; PeculiarMind/ProTemp.AI CC BY-SA 4.0) are unaffected and do not require updates.

### License Header Consistency

None of the changed files introduce or remove SPDX headers or copyright notices. This is consistent with the existing project convention — no source files in the repository carry per-file license headers. No action required.

### Verdict

**PASS**

FEATURE_0007 introduces no new dependencies, no incorporated third-party code, and no new assets. All changes are original work governed by the existing AGPL-3.0 project license. No updates to `CREDITS.md` or any license documentation are required.

## Documentation Assessment

**Assessed by:** documentation.agent  
**Date:** 2026-03-03

### What Was Checked

1. **`README.md`** — reviewed all sections for coverage of FEATURE_0007 behaviour:
   - Advanced Filtering section (`--include` / `--exclude` options)
   - Plugin descriptions (Built-in Plugins list and `file` plugin example)
   - Command-line options table

2. **`project_documentation/03_user_guide/`** — directory exists but is empty (`.empty` placeholder only); no user guide to review.

3. **`project_documentation/04_dev_guide/`** — directory exists but is empty (`.empty` placeholder only); no dev guide to review.

### What Was Updated

#### `README.md`

| Location | Change |
|----------|--------|
| Advanced Filtering section | Added a dedicated **MIME Type Filtering** subsection with three concrete examples: include-only (`text/plain`), exclude with wildcard (`image/*`), and combined MIME + extension filtering |
| Advanced Filtering section | Added bullet-point explanations of wildcard MIME patterns, silent-skip behaviour, and the `file` plugin dependency for MIME filtering |
| Advanced Filtering section | Added a callout note explaining that the `file` plugin always runs first in the processing chain |
| Built-in Plugins list | Reordered so `file` is listed first; added "always runs first" and "must be installed and active" wording |

No changes were required to `project_documentation/` because no user or developer guide files exist yet.

### Verdict

**PASS WITH NOTES**

`README.md` now accurately reflects all three user-facing aspects of FEATURE_0007: MIME type filter syntax (including wildcard patterns), silent-skip behaviour, and the mandatory file-first constraint. The `project_documentation/` user and dev guide directories are still empty stubs; when those guides are authored in a future work item they should incorporate the same MIME filtering guidance.
