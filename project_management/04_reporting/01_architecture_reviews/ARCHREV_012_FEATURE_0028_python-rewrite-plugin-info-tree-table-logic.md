# Architecture Review: FEATURE_0028 — Python Rewrite: plugin_info.py for Tree and Table Logic

- **ID:** ARCHREV_012
- **Created at:** 2026-03-06
- **Created by:** architect.agent
- **Work Item:** `project_management/03_plan/02_planning_board/06_done/FEATURE_0028_python-rewrite-plugin-info-tree-table-logic.md`
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
| `doc.doc.md/components/plugin_info.py` | New Python component implementing DFS dependency tree rendering with cycle detection (`tree` mode) and column-aligned table formatting (`table` mode); carries a `# CLI Interface:` header block documenting argument syntax, exit codes, and stdout contract |
| `doc.doc.md/components/plugin_management.sh` | `cmd_tree` refactored from ~200-line DFS Bash implementation to a thin wrapper invoking `python3 plugin_info.py tree`; both `column -t -s $'\t'` calls in `cmd_list` replaced with `python3 plugin_info.py table`; module header updated with `# Requires: plugin_info.py` annotation |
| `tests/test_feature_0028.sh` | 29 shell integration tests covering existence, interface, thin-wrapper behaviour, CLI output contract, and error handling |
| `tests/test_feature_0028.py` | 16 Python unit tests covering tree rendering, cycle detection, ANSI colors, table alignment, and error paths — all executable without a shell environment |

## Architecture Vision Reference

- **REQ_0036:** Orchestration Isolation — `doc.doc.sh` is a pure orchestrator, no inline implementation
- **REQ_0037:** Module Interface Contract — each module has a header listing its public CLI interface
- **REQ_0035:** Cohesive Plugin Management Module — plugin management concerns contained in one module
- **REQ_0002:** Modular and Extensible Architecture — extension without modifying core code; unit-testable logic
- **REQ_0038:** Backward-Compatible CLI — observable CLI output unchanged after rewrite
- **ADR-001:** Mixed Bash/Python Implementation — Python used for complex logic; Bash for CLI orchestration
- **Building Block View (Level 1):** Python Components are a distinct Level-1 building block alongside Bash Components

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| REQ_0036: Orchestration Isolation | ✅ Compliant | `cmd_tree` in `plugin_management.sh` is now a thin wrapper (no DFS, no cycle detection, no rendering logic); `cmd_list` table paths delegate entirely to `plugin_info.py table`; `doc.doc.sh` is unchanged |
| REQ_0037: Module Interface Contract | ✅ Compliant | `plugin_info.py` carries a `# CLI Interface:` header block explicitly documenting both modes (`tree <plugins_dir>` and `table`), their argument syntax, exit codes (0/1), and stdout contract; `plugin_management.sh` header updated with `# Requires: plugin_info.py` annotation |
| REQ_0035: Cohesive Plugin Management Module | ✅ Compliant | `plugin_management.sh` continues to own all plugin lifecycle concerns; `plugin_info.py` is a subordinate rendering utility called exclusively by `plugin_management.sh`, not by any other module |
| REQ_0002: Modular and Extensible Architecture | ✅ Compliant | DFS graph traversal, cycle detection, and column alignment are now pure Python functions, independently unit-testable without a shell environment; `bsdextrautils` system dependency eliminated |
| REQ_0038: Backward-Compatible CLI | ✅ Compliant | All 29 shell integration tests confirm identical observable output for `tree` and `list` commands; 745/767 suite tests pass (22 failures are pre-existing environmental) |
| ADR-001: Mixed Bash/Python | ✅ Compliant | Pattern consistent with the established `filter.py` precedent: complex logic moves to Python, Bash remains the CLI orchestration layer |
| No inline DFS logic in Bash | ✅ Compliant | `plugin_management.sh` `cmd_tree` contains only path resolution, existence check, and `python3 ... tree` invocation |
| `column` dependency eliminated | ✅ Compliant | Both `column -t -s $'\t'` invocations removed; no external `bsdextrautils` calls remain in `plugin_management.sh` |
| Python component unit-testable in isolation | ✅ Compliant | 16 unit tests in `test_feature_0028.py` exercise `run_tree`, `run_table`, and `main` with no shell process required |

## Deviations Found

None.

The implementation follows the established Bash+Python architecture pattern (ADR-001) exactly. `plugin_info.py` mirrors the interface style of `filter.py`: a header-documented CLI component callable from Bash with well-defined exit codes and stdout contracts. The Bash layer in `plugin_management.sh` is reduced to delegation only, which is the intended orchestration-isolation pattern from REQ_0036.

## Recommendations

1. **Update Building Block View** — `project_documentation/01_architecture/05_building_block_view/05_building_block_view.md` currently lists `plugins.sh` in the Level-3 source layout. It should be updated to reflect the current component structure: `plugin_management.sh`, `plugin_execution.sh`, and the new `plugin_info.py`. *(Updated as part of this review — see below.)*
2. **`# Requires:` convention** — `plugin_management.sh` now carries a `# Requires: plugin_info.py` annotation. This convention of declaring inter-component dependencies in headers should be applied to all component files that call Python siblings (e.g., `plugin_execution.sh` if it gains Python dependencies).
3. **Public function annotation** (carry-forward from ARCHREV_011) — The `# Public Interface:` blocks in `plugin_management.sh` list function names. For full REQ_0037 compliance, each public function should include inline parameter/return contract comments. This remains a follow-up item, not a blocker.

## Conclusion

**Result: ✅ Fully Compliant**

FEATURE_0028 advances the modular architecture goal (REQ_0002) by extracting complex DFS tree rendering and table formatting logic from Bash into a dedicated, unit-testable Python component. The `bsdextrautils` system dependency is eliminated. The Bash layer in `plugin_management.sh` is reduced to thin wrappers, reinforcing the orchestration-isolation principle (REQ_0036). The `plugin_info.py` component carries a complete CLI interface header (REQ_0037), and backward compatibility is confirmed by the full test suite (REQ_0038). The implementation is consistent with ADR-001 and extends the established `filter.py` precedent cleanly.
