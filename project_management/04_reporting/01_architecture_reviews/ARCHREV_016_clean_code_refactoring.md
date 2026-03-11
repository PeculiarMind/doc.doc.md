# Architecture Review: ARCHREV_016 — Clean Code Refactoring

**Date:** 2026-03-11
**Scope:** Code maintainability improvements across core components

## Summary

Systematic clean code refactoring of the doc.doc.md codebase, focused on eliminating code duplication, extracting shared modules, removing dead code, and improving function decomposition.

## Changes Assessed

### 1. `doc.doc.sh` — God Function Extraction
**Before:** 465-line `main()` handling argument parsing, validation, plugin discovery, filtering, and the entire processing pipeline.
**After:** 5 focused functions with clear single responsibilities:
- `_parse_process_args()` — CLI argument parsing
- `_validate_process_inputs()` — input/output validation
- `_prepare_plugins()` — plugin discovery and installation checks
- `_split_filter_criteria()` — MIME vs path filter classification
- `_run_process_pipeline()` — file processing loop

**Assessment:** ✅ Clean separation of concerns. Each function has a single reason to change. State communication via `_PROC_*` globals is documented.

### 2. `plugin_management.sh` — Duplication Elimination (880→725 lines)
**Extracted helpers:**
- `_parse_plugin_arg`: replaced 3 duplicated argument parsing blocks
- `_set_plugin_active`: unified cmd_activate/cmd_deactivate (57 lines each → 3 lines each)
- `_check_plugin_installed`: unified 3 duplicated installed.sh check patterns
- `_require_plugin_descriptor`: shared plugin dir/descriptor validation
- `_resolve_plugin_descriptor`: shared descriptor resolution with path traversal check
- `_JQ_EXTRACT_PARAMS`: shared jq expression for parameter extraction (was duplicated 2x)

**Assessment:** ✅ Significant DRY improvement. Public API unchanged.

### 3. `plugin_input.sh` — New Shared Module
**Created:** Shared plugin input validation module (66 lines) providing:
- `plugin_read_input()` — stdin reading with 1MB limit (REQ_SEC_009)
- `plugin_get_field()` — safe JSON field extraction
- `plugin_validate_filepath()` — path resolution, restricted dir check (REQ_SEC_005)

**Impact on plugins:**
| Plugin | Before | After | Reduction |
|--------|--------|-------|-----------|
| file/main.sh | 54 | 20 | 63% |
| stat/main.sh | 102 | 60 | 41% |
| markitdown/main.sh | 87 | 66 | 24% |
| ocrmypdf/main.sh | 153 | 115 | 25% |

**Assessment:** ✅ Single source of truth for security-critical validation. New plugins automatically inherit REQ_SEC_005 and REQ_SEC_009 compliance.

### 4. Dead Code Removal
- Deleted `plugins.sh` (52 lines) — legacy module, no longer sourced by any file

**Assessment:** ✅ Reduces confusion for new contributors.

## Architecture Compliance

| ADR | Status | Notes |
|-----|--------|-------|
| ADR-001 (Python filter engine) | ✅ Compliant | No changes to filter.py |
| ADR-003 (JSON I/O protocol) | ✅ Compliant | Plugin I/O unchanged |
| ADR-004 (Three-state exit codes) | ✅ Compliant | Exit code handling preserved |

## Metrics

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Total source lines | 2,811 | 2,535 | -10% |
| plugin_management.sh | 880 | 725 | -18% |
| Plugin main.sh total | 396 | 261 | -34% |
| Dead code files | 1 | 0 | -100% |
| Duplicated code blocks | 11 | 0 | -100% |

## Recommendations

1. **Consider Python rewrite for templates.sh** — deferred because test_bug_0009 specifically validates the bash implementation pattern (jq 'keys[]' approach)
2. **ui.sh + ui_progressbar.sh** (432 lines combined) — could benefit from similar extraction of shared patterns in a future pass
3. **plugin_management.sh cmd_setup** (still ~150 lines) — contains interactive prompting logic that could be further decomposed
