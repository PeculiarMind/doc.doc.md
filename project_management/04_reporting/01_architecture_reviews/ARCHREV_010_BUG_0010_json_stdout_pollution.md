# Architecture Review: BUG_0010 — JSON stdout Pollution in Interactive Mode

- **ID:** ARCHREV_010
- **Created at:** 2026-03-06
- **Created by:** architect.agent
- **Work Item:** `project_management/03_plan/02_planning_board/05_implementing/BUG_0010_json_stdout_pollution.md`
- **Status:** Compliant

## Table of Contents
1. [Reviewed Scope](#reviewed-scope)
2. [Architecture Vision Reference](#architecture-vision-reference)
3. [Compliance Assessment](#compliance-assessment)
4. [Deviations Found](#deviations-found)
5. [Recommendations](#recommendations)
6. [Conclusion](#conclusion)

## Reviewed Scope

| File | Change Purpose |
|------|---------------|
| `doc.doc.sh` | Added `suppress_json` flag using `[ -t 1 ]` TTY detection; wrapped all JSON `echo` statements with `if [ "$suppress_json" = false ]` guards |

## Architecture Vision Reference

- **ADR-001:** Mixed Bash/Python Implementation — Bash for CLI orchestration and output routing
- **ADR-002:** Tool Reuse — POSIX `[ -t fd ]` construct; no external dependencies
- **Solution Strategy:** Usability (Priority 1), Backward Compatibility
- **REQ_0038:** Backward-Compatible CLI
- **Existing Pattern:** TTY detection for stderr (`[ -t 2 ]`) was already established in `doc.doc.sh` for suppressing progress display in non-interactive contexts; this fix applies the same idiom to stdout

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| ADR-001: Bash for orchestration | ✅ Compliant | Fix is pure Bash in the existing orchestration script; no new modules introduced |
| ADR-002: Tool Reuse | ✅ Compliant | Uses POSIX `[ -t 1 ]` test; no external dependencies added |
| Separation of Concerns (stdout/stderr) | ✅ Compliant | stdout is reserved for machine-readable data (pipelines); interactive output belongs on stderr or is suppressed — fix enforces this boundary |
| Existing TTY detection pattern | ✅ Compliant | Consistent with the `[ -t 2 ]` pattern introduced for FEATURE_0026; applying the same idiom to stdout is architecturally coherent |
| REQ_0038: Backward-Compatible CLI | ✅ Compliant | JSON output is unchanged in non-TTY (piped) mode; existing pipeline consumers are unaffected |
| Quality Goal: Usability | ✅ Compliant | Interactive users no longer see raw JSON mixed with terminal output |
| Quality Goal: Maintainability | ✅ Compliant | Fix is localised to a single function; the `suppress_json` flag follows the same guard pattern as `suppress_progress` |

## Deviations Found

None.

## Recommendations

1. **No immediate action required** — Implementation is architecturally compliant and consistent with established patterns.
2. **Future consideration** — If additional output channels are introduced (e.g., machine-readable YAML), extend the same TTY-detection guard pattern rather than adding separate flags.

## Conclusion

**Result: ✅ Fully Compliant**

The fix for BUG_0010 is a minimal, targeted change that reinforces the existing separation-of-concerns principle (stdout for data, stderr/suppressed for status). It reuses the TTY detection idiom already established by FEATURE_0026, introduces no new dependencies or structural changes, and preserves full backward compatibility for pipeline consumers. No technical debt was created.
