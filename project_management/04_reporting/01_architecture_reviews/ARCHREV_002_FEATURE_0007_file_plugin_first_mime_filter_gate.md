# Architecture Review: FEATURE_0007 — File Plugin First in Chain and MIME Filter Gate

- **ID:** ARCHREV_002
- **Created at:** 2026-03-03
- **Created by:** architect.agent
- **Work Item:** [FEATURE_0007](../../../project_management/03_plan/02_planning_board/05_implementing/FEATURE_0007_file_plugin_first_in_chain_and_mime_filter_gate.md)
- **Status:** Compliant with Notes

## TOC

1. [Reviewed Scope](#reviewed-scope)
2. [Architecture Vision Reference](#architecture-vision-reference)
3. [Compliance Assessment](#compliance-assessment)
4. [Deviations Found](#deviations-found)
5. [Recommendations](#recommendations)
6. [Conclusion](#conclusion)

## Reviewed Scope

| File | Change | Purpose |
|------|--------|---------|
| `doc.doc.sh` | Modified | File-first enforcement in planning phase; MIME filter gate in processing phase; criterion routing (MIME vs path) |
| `doc.doc.md/components/plugins.sh` | Modified | Fixed `active` field defaulting bug in `discover_plugins()` |
| `doc.doc.md/components/filter.py` | Unchanged | Filter engine; reused as-is for MIME string matching |
| `tests/test_feature_0007.sh` | New | 63-test suite covering all FEATURE_0007 acceptance criteria |

## Architecture Vision Reference

- [REQ_0003: Plugin-Based Architecture](../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-system.md)
- [REQ_0009: Process Command](../../02_project_vision/02_requirements/03_accepted/REQ_0009_process-command.md)
- [REQ_0013: Directory Structure Mirroring](../../02_project_vision/02_requirements/03_accepted/REQ_0013_directory-mirroring.md)
- [REQ_SEC_002: Filter Logic Correctness](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_002_filter_logic_correctness.md)
- [ARC_0001: Filtering Logic Concept](../../02_project_vision/03_architecture_vision/08_concepts/ARC_0001_filtering_logic.md)
- [ARC_0003: Plugin Architecture Concept](../../02_project_vision/03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md)
- [ADR-003: JSON-Based Plugin Descriptors](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md)

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| **REQ_0003 — file-first as pipeline concern** | ✅ Compliant | File-first enforcement lives entirely in `doc.doc.sh` planning phase (lines 176–194), not in `plugins.sh` or in the `file` plugin itself. `discover_plugins()` returns plugins in filesystem order with no special-casing; `doc.doc.sh` re-orders the list post-discovery. Clean separation of concerns. |
| **REQ_0003 — file plugin remains standard plugin** | ✅ Compliant | `file` plugin continues to communicate via JSON stdin/stdout per ADR-003. No changes to `descriptor.json`, `main.sh`, `installed.sh`, or `install.sh`. The plugin is unaware of its mandatory-first status. |
| **REQ_0009 — MIME criterion identification** | ✅ Compliant | Criteria containing `/` and not containing `**` are classified as MIME criteria. This correctly captures `application/pdf`, `text/plain`, `image/*`, `text/*`, `*/*` while correctly excluding recursive path globs like `**/2024/**`. |
| **REQ_0009 — Glob-style MIME matching** | ✅ Compliant | `filter.py` receives the MIME type string on stdin and matches it using `fnmatch.fnmatch(mime_string, criterion)`. This handles both literal MIME types (`text/plain`) and glob patterns (`image/*`, `text/*`) correctly and uniformly. |
| **REQ_0009 — AND/OR filter logic unchanged** | ✅ Compliant | `filter.py` is unmodified. AND-between-parameters / OR-within-parameter logic is preserved for MIME criteria exactly as for extension and glob criteria. |
| **REQ_0013 — skipped files produce no output** | ✅ Compliant | MIME filter gate in `process_file()` issues `return 0` (empty output) on rejection. The main loop in `doc.doc.sh` skips empty results. No JSON entry, no directory trace is produced for filtered files. Pre-condition for correct directory mirroring when the `-o` flag is implemented. |
| **ARC_0003 — plugin interface not violated** | ✅ Compliant | No changes to plugin input/output contracts. `run_plugin()` in `plugins.sh` is unchanged. |
| **ADR-003 — descriptor schema** | ✅ Compliant | No descriptor changes. `active` field bug fix in `plugins.sh` now correctly evaluates `null`/absent `active` as `true`, consistent with ADR-003's documented default. |
| **REQ_SEC_002 — filter logic correctness** | ✅ Compliant | 63 new tests in `test_feature_0007.sh` cover MIME include/exclude with exact types, glob patterns, AND/OR combinations, no-MIME-criteria baseline, and file-plugin-absent abort. All 162 tests across all three suites pass. |
| **Backward compatibility** | ✅ Compliant | When no MIME criteria are present, `_MIME_INCLUDE_ARGS` and `_MIME_EXCLUDE_ARGS` are empty; the MIME filter gate is skipped entirely. Pre-existing tests in `test_doc_doc.sh` (47) and `test_plugins.sh` (52) pass unchanged. |

## Deviations Found

### DEV-001: ARC_0001 pseudocode diverges from actual MIME matching implementation

**Affected files:**
- `project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_0001_filtering_logic.md`

**Description:**
The `matches_criterion` pseudocode in ARC_0001 shows MIME matching as:

```python
elif '/' in criterion:
    mime_type = get_mime_type(file_path)
    return mime_type == criterion
```

The actual implementation is architecturally superior but differs in two ways:
1. MIME type detection does not occur inside `matches_criterion` — it is performed once by the `file` plugin and the result is passed directly to `filter.py` as stdin input (so `filter.py` treats the MIME string as the "file_path" subject of matching).
2. `fnmatch.fnmatch` is used for all matching, making glob MIME patterns (`image/*`, `text/*`) first-class citizens without special-casing.

The divergence is a **documentation gap**, not an implementation error. The implementation is correct and better than the pseudocode describes. There is no architectural violation — ARC_0001's pseudocode is aspirational design guidance, and the FEATURE_0007 approach is consistent with ARC_0001's stated goals ("MIME type-based filtering").

**Severity:** Low — Documentation only. No functional or structural impact.

**Remediation:** Update ARC_0001 to document the actual design (criterion routing in `doc.doc.sh`; MIME string as filter.py stdin input; fnmatch-based matching).

**DEBTR Record:** [DEBTR_002](../../03_plan/02_planning_board/04_backlog/DEBTR_002_update_arc0001_mime_criterion_matching.md)

---

### DEV-002 (Pre-existing): `-o` output directory not yet implemented

**Affected files:**
- `doc.doc.sh`

**Description:**
REQ_0009 specifies a required `--output-directory` / `-o` parameter, and REQ_0013 requires the input directory structure to be mirrored in the output directory. Neither is implemented in `doc.doc.sh` — the tool currently streams JSON to stdout only.

This is **pre-existing technical debt** that predates FEATURE_0007 and was not introduced by this feature. FEATURE_0007 correctly ensures that filtered-out files produce no JSON output, which is the necessary prerequisite for correct directory mirroring once the `-o` flag is added.

**Severity:** Medium (pre-existing) — Not a regression. Tracked separately from this feature.

**Note:** This deviation was known at FEATURE_0002 review. No new DEBTR is raised here; it should be addressed in a dedicated feature (e.g., FEATURE_0008 or equivalent).

## Recommendations

1. **Update ARC_0001** (tracked as DEBTR_002): Revise the `matches_criterion` pseudocode to document the actual MIME matching approach — MIME type string fed directly to filter.py stdin, matched with `fnmatch`. This keeps the architecture documentation accurate for future contributors.

2. **Plan the `-o` output directory feature**: REQ_0009 and REQ_0013 require an output directory parameter and directory mirroring. FEATURE_0007 provides the correct foundation (no output for filtered files). The `-o` implementation should be the next infrastructure feature on the roadmap.

3. **Consider refactoring global bash arrays** (non-blocking): `_MIME_INCLUDE_ARGS` and `_MIME_EXCLUDE_ARGS` are process-level globals used to pass MIME filter state from `main()` to `process_file()`. This is idiomatic bash but makes `process_file()` implicitly dependent on global state. A future refactor could pass these as positional parameters or via a helper function. This is a very low priority style note — not a functional concern.

## Conclusion

The FEATURE_0007 implementation is **compliant** with the architecture vision. All three target requirements are correctly addressed:

- **REQ_0003**: File-first enforcement is cleanly placed at the pipeline level in `doc.doc.sh`, not in the plugin layer. The `file` plugin remains a standard plugin and is unaware of its mandatory-first status.
- **REQ_0009**: MIME criterion identification (presence of `/`, absence of `**`), glob-style MIME matching via `fnmatch`, and the unchanged AND/OR filter logic are all correctly implemented.
- **REQ_0013**: Skipped files produce no output, correctly avoiding any directory trace — the required pre-condition for future directory mirroring.

One low-severity documentation deviation (DEV-001) was identified: ARC_0001's pseudocode does not match the actual MIME matching approach. A DEBTR_002 work item has been created to update ARC_0001. One pre-existing medium-severity gap (DEV-002) — the missing `-o` output directory — is acknowledged but was not introduced by this feature.

No architectural violations or regressions were found. The implementation is clean, well-tested (162/162 tests passing), and establishes a sound foundation for future MIME-type-aware features.
