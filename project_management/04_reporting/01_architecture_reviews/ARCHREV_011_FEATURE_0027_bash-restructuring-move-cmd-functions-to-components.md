# Architecture Review: FEATURE_0027 — Bash Restructuring: Move cmd_* Functions to Components

- **ID:** ARCHREV_011
- **Created at:** 2026-03-06
- **Created by:** architect.agent
- **Work Item:** `project_management/03_plan/02_planning_board/05_implementing/FEATURE_0027_bash-restructuring-move-cmd-functions-to-components.md`
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
| `doc.doc.sh` | Removed `cmd_activate`, `cmd_deactivate`, `cmd_install`, `_install_single_plugin`, `_install_all_plugins`, `cmd_installed`, `cmd_tree`, `_validate_plugin_dir`, `_list_plugins`, `cmd_list`, `process_file`; now contains only `main`, globals, usage strings, and `source` statements (382 lines) |
| `doc.doc.md/components/plugin_management.sh` | Received `cmd_activate`, `cmd_deactivate`, `cmd_install`, `_install_single_plugin`, `_install_all_plugins`, `cmd_installed`, `cmd_tree`, `_validate_plugin_dir`, `_list_plugins`, `cmd_list`; has `# Public Interface:` header block |
| `doc.doc.md/components/plugin_execution.sh` | Received `process_file`; has `# Public Interface:` header block listing `run_plugin` and `process_file` |

## Architecture Vision Reference

- **REQ_0033:** Separate Plugin Management from Plugin Execution — distinct modules for distinct concerns
- **REQ_0034:** Cohesive Plugin Execution Module — plugin command invocation, I/O, exit-code classification in one module
- **REQ_0035:** Cohesive Plugin Management Module — plugin discovery, descriptor loading, activation state in one module
- **REQ_0036:** Orchestration Isolation — `doc.doc.sh` is a pure orchestrator, no inline implementation
- **REQ_0037:** Module Interface Contract — each module has a header listing its public interface
- **ADR-001:** Mixed Bash/Python Implementation — Bash for CLI orchestration and output routing
- **Building Block View (Level 1):** Plugin Management and Plugin Execution are defined as distinct Level-1 building blocks

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| REQ_0033: Separation of management and execution | ✅ Compliant | `plugin_management.sh` contains zero plugin invocation; `plugin_execution.sh` contains zero activation state logic |
| REQ_0034: Cohesive Plugin Execution Module | ✅ Compliant | `plugin_execution.sh` owns `run_plugin` (invocation, I/O, exit-code classification, JSON output validation) and `process_file` (sequencing plugins over a file) |
| REQ_0035: Cohesive Plugin Management Module | ✅ Compliant | `plugin_management.sh` owns discovery (`discover_plugins`, `discover_all_plugins`), descriptor loading (`get_plugin_active_status`), activation state (`cmd_activate`, `cmd_deactivate`), installation (`cmd_install`, `cmd_installed`), and listing (`cmd_list`, `cmd_tree`) |
| REQ_0036: Orchestration Isolation | ✅ Compliant | `doc.doc.sh` at 382 lines contains only `main`, global variable declarations, usage/help strings, and `source` statements; all implementation delegates to components |
| REQ_0037: Module Interface Contract | ✅ Compliant | Both receiving component files contain a `# Public Interface:` header block explicitly listing their public functions |
| ADR-001: Bash for orchestration | ✅ Compliant | Refactoring is pure Bash; no language boundary changes; Python components untouched |
| Building Block separation | ✅ Compliant | Level-1 boundary between Plugin Management and Plugin Execution is now enforced at the file level |
| Backward compatibility | ✅ Compliant | All 757 test suite tests confirm identical observable behaviour; 0 new failures introduced |
| No cross-concern calls | ✅ Compliant | `plugin_management.sh` does not call `run_plugin` or `process_file`; `plugin_execution.sh` does not access `.active` fields or call `cmd_activate`/`cmd_deactivate` |

## Deviations Found

None.

The implementation is a strict move of functions with no logic changes. The resulting module structure matches the architecture vision exactly: `doc.doc.sh` as orchestrator, `plugin_management.sh` as the management building block, and `plugin_execution.sh` as the execution building block.

## Recommendations

1. **REQ_0037 full compliance** — The `# Public Interface:` blocks list function names. For complete compliance, each public function should also have an inline comment documenting its parameters and return contract. This is a follow-up action, not a blocker.
2. **Private-function marking** — `_`-prefixed helpers (e.g., `_install_single_plugin`, `_validate_plugin_dir`, `_list_plugins`, `_print_tree`) are conventionally private; consider adding a `# --- Private ---` section divider for clarity.
3. **FEATURE_0028 readiness** — The refactoring unblocks FEATURE_0028 (Python rewrite of tree/table logic). The clean boundary in `plugin_management.sh` means `cmd_tree` and `cmd_list` can be replaced independently without touching `plugin_execution.sh` or `doc.doc.sh`.

## Conclusion

**Result: ✅ Fully Compliant**

FEATURE_0027 delivers on all five architectural requirements it was designed to satisfy (REQ_0033–REQ_0037). `doc.doc.sh` is now a pure orchestrator at 382 lines. Plugin management and plugin execution concerns are cleanly separated at the file boundary. Both component files declare their public interfaces in header comments. No observable behaviour changes were introduced, and the full test suite regression confirms correctness. The architecture is in a stronger, more maintainable state than before.
