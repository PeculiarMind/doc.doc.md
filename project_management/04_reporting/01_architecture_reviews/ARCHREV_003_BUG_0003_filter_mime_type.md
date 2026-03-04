# Architecture Review: BUG_0003 — Filter Engine MIME Type Criterion Support

- **ID:** ARCHREV_003
- **Created at:** 2026-03-04
- **Created by:** architect.agent
- **Work Item:** [BUG_0003](../../03_plan/02_planning_board/05_implementing/BUG_0003_filter_mime_type_not_implemented.md)
- **Status:** Compliant

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
| `doc.doc.md/components/filter.py` | Modified | Added `_get_mime_type()` helper and MIME branch in `matches_criterion()` |

No other files were changed.

## Architecture Vision Reference

- [ARC_0001: Filtering Logic Concept](../../02_project_vision/03_architecture_vision/08_concepts/ARC_0001_filtering_logic.md)
- [REQ_SEC_002: Filter Logic Correctness](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_002_filter_logic_correctness.md)
- [REQ_0031: Include-before-exclude filter evaluation order](../../02_project_vision/02_requirements/03_accepted/REQ_0031_filter-include-exclude-precedence.md)

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| **ARC_0001 — MIME criterion identification** | ✅ Compliant | Criterion is classified as MIME when it contains `/` but not `**`, consistent with ARC_0001 and the criterion routing in `doc.doc.sh`. |
| **ARC_0001 — MIME type resolution** | ✅ Compliant | `_get_mime_type()` calls `file --mime-type -b <path>`, consistent with ARC_0001 ("MIME type detection via `file --mime-type`") and the existing `file` plugin. |
| **ARC_0001 — fnmatch for glob MIME patterns** | ✅ Compliant | `fnmatch.fnmatch(mime_type, criterion)` handles both exact (`text/plain`) and glob (`image/*`) MIME criteria consistently. |
| **ARC_0001 — MIME gate passthrough** | ✅ Compliant | When `filter.py` receives a MIME type string directly (e.g., from the `doc.doc.sh` MIME gate), `os.path.isfile()` returns `False` and `fnmatch` is used directly — exactly as described in ARC_0001's MIME gate pseudocode. |
| **REQ_SEC_002 — Filter logic correctness** | ✅ Compliant | All 19 BUG_0003 tests and all 162 pre-existing tests pass. Include/exclude precedence (REQ_0031) is unchanged. |
| **Backward compatibility** | ✅ Compliant | Extension criteria (`.pdf`) and glob patterns (`**/2024/**`) are unaffected. The new MIME branch is only entered when criterion contains `/` but not `**`. |
| **Error handling** | ✅ Compliant | `file` command absence is detected at the first MIME criterion evaluation via `shutil.which` (cached at module load), an error is written to stderr, and the process exits non-zero — consistent with ARC_0004 (Error Handling). |
| **Separation of concerns** | ✅ Compliant | `filter.py` remains general-purpose and stateless. `_get_mime_type()` is a narrow helper used only in `matches_criterion()`. No global state is introduced. |

## Deviations Found

None. The implementation correctly aligns with ARC_0001, including both the direct-invocation path (file paths with MIME criteria) and the MIME gate passthrough path (MIME type strings from `doc.doc.sh`).

Note: DEBTR_002 (updating ARC_0001 pseudocode to reflect the actual MIME matching approach) was already completed in a prior iteration.

## Recommendations

1. **Consider caching MIME type results per file path** if large directory trees are processed. Currently `_get_mime_type()` calls `file` once per criterion per file, which means multiple MIME criteria trigger multiple `file` subprocess calls on the same file. A simple `functools.lru_cache` on `_get_mime_type()` would eliminate redundant calls. This is a performance optimisation, not a correctness issue; track as future technical debt if needed.

## Conclusion

The BUG_0003 fix is **fully compliant** with the architecture vision. The implementation:

- Correctly identifies MIME criteria (`/` in criterion, no `**`)
- Resolves MIME types via `file --mime-type -b` (consistent with ARC_0001 and the `file` plugin)
- Uses `fnmatch` for both exact and wildcard MIME matching
- Gracefully handles the MIME gate passthrough case via `os.path.isfile()`
- Introduces no architectural violations or regressions

No DEBTR items are raised. The fix is clean and minimal.
