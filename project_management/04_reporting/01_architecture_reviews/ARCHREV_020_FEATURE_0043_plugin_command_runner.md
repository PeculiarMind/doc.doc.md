# Architecture Review: FEATURE_0043 Plugin Command Runner

- **ID:** ARCHREV_020
- **Created at:** 2026-03-14
- **Created by:** architect.agent
- **Work Item:** [FEATURE_0043: Plugin Command Runner](../../03_plan/02_planning_board/05_implementing/FEATURE_0043_plugin-command-runner.md)
- **Status:** Compliant with Notes

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
| `doc.doc.sh` | Registered `run` in `main()` case statement; routes to `cmd_run "$@"` |
| `doc.doc.md/components/ui.sh` | Added `ui_usage_run()` help function and `usage_run()` backward-compatible alias; updated `ui_usage()` to list `run` command |
| `doc.doc.md/components/plugin_management.sh` | Added `cmd_run()`, `_run_global_help()`, `_run_plugin_help()` in a new section guarded by a `# --- Run command (FEATURE_0043) ---` block comment; updated Public Interface header |

## Architecture Vision Reference

- **ADR-001:** [Mixed Bash/Python Implementation](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_001_mixed_bash_python_implementation.md) — `cmd_run` is pure Bash, consistent with all other cmd_* handlers
- **ADR-002:** [Prioritize Reuse of Existing Tools](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_002_prioritize_tool_reuse.md) — JSON input construction relies on `jq --arg` (existing dependency); plugin validation reuses the existing `_validate_plugin_dir` helper
- **ADR-003:** [JSON Plugin Descriptors](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md) — command resolution uses `commands.<commandName>.command` from descriptor.json, consistent with how `plugin_execution.sh` resolves the `process` command
- **REQ_0003:** [Plugin-Based Architecture](../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-system.md) — all invocable commands are discovered via descriptor.json; no hard-coded script paths
- **REQ_SEC_001:** [Input Validation and Sanitization](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_001_input_validation_sanitization.md) — plugin name validated via `_validate_plugin_dir`; command name validated against descriptor.json before any script execution
- **REQ_SEC_005:** [Path Traversal Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md) — `_validate_plugin_dir` canonicalises the plugin directory and verifies it remains under `$PLUGIN_DIR`; JSON values built via `jq --arg` prevent shell injection

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| ADR-001: Bash Implementation | ✅ Compliant | `cmd_run`, `_run_global_help`, `_run_plugin_help` are pure Bash. No new Python components introduced. |
| ADR-002: Tool Reuse | ✅ Compliant | `jq` (existing dependency) used for JSON construction and descriptor parsing. `_validate_plugin_dir` (existing helper) reused for plugin name validation. `discover_all_plugins` (existing function) reused for the help plugin list. |
| ADR-003: JSON Plugin Descriptors | ✅ Compliant | Command resolution follows `commands.<commandName>.command` path in descriptor.json — the same lookup pattern used by `plugin_execution.sh` for `process`. No command can be invoked without a matching descriptor.json entry. |
| cmd_* function pattern | ✅ Compliant | `cmd_run` follows the identical naming convention, argument-handling style, and `exit 1` on error pattern used by all other cmd_* functions (`cmd_activate`, `cmd_deactivate`, `cmd_list`, etc.). |
| ui.sh help pattern | ✅ Compliant | `ui_usage_run()` follows the same `ui_show_help_banner + heredoc` pattern as all other `ui_usage_*` functions. The backward-compatible alias `usage_run()` was added alongside the new function, consistent with the alias block at the bottom of ui.sh. `ui_usage()` updated to include `run` in the command list and usage example. |
| doc.doc.sh routing | ✅ Compliant | `run` registered in the `main()` case statement with `cmd_run "$@"`, identical to all other top-level command registrations. |
| Module placement of cmd_run | ✅ Compliant | `cmd_run` placed in `plugin_management.sh`, which owns descriptor.json parsing and plugin discovery. The function relies heavily on `_validate_plugin_dir`, `discover_all_plugins`, and `jq` descriptor queries — all assets of the management module. The module header boundary ("Contains NO process-pipeline invocation logic") remains accurate: `cmd_run` is a CLI-driven direct invocation, not part of the document-processing pipeline defined in `plugin_execution.sh`. |
| Public Interface header updated | ✅ Compliant | Line 21 of `plugin_management.sh` adds `cmd_run - Invoke any plugin command declared in descriptor.json` to the Public Interface block. All other entries in the block remain unchanged. |
| REQ_SEC_001: Input Validation | ✅ Compliant | Plugin name canonicalised via `_validate_plugin_dir` before any descriptor read. Command name resolved by strict jq lookup (`commands[$cmd].command // empty`) — an unrecognised command returns empty and is rejected with exit 1 before any script path is constructed. Unknown flags rejected with exit 1 via the `*` case branch. |
| REQ_SEC_005: Path Traversal | ✅ Compliant | `_validate_plugin_dir` verifies `canonical_dir` starts with `canonical_base/`; any `..` or symlink escape is caught before descriptor.json is read. JSON values (--file, --plugin-storage, --category, key=value pairs) are all passed through `jq --arg` — values are never shell-interpolated. |
| Exit code pass-through | ✅ Compliant | `printf '%s\n' "$json_input" \| bash "$script_path"` — the pipeline exit code is the plugin script's exit code, propagated directly to the caller. Error paths use `exit 1` consistently. |

## Deviations Found

None that require remediation.

**Note on `bash "$script_path"` invocation**: `cmd_run` invokes plugin scripts via `bash "$script_path"`, which assumes all plugin command scripts are Bash. This is consistent with ADR-001 (Bash implementation for all scripts) and with the existing `run_plugin` function in `plugin_execution.sh` which also uses `bash` invocation internally. Should a future plugin require a non-Bash script, the invocation strategy would need revisiting, but this is not a concern under the current ADR.

**Note on stdin for interactive plugins**: The pipeline `printf '%s\n' "$json_input" | bash "$script_path"` replaces the plugin script's stdin with the JSON pipe. This means plugin commands that require real terminal stdin (e.g. interactive prompts) cannot use `cmd_run`. The feature specification explicitly marks interactive prompting out of scope; interactive commands such as `crm114/train.sh` accept positional arguments rather than JSON stdin, so they receive an empty stdin stream and are unaffected in practice.

## Recommendations

1. **Update `05_building_block_view.md` subcommand list**: The building block view document (`project_documentation/01_architecture/05_building_block_view/05_building_block_view.md`) states "Implemented subcommands: `process`, `list`, `activate`, `deactivate`, `install`, `installed`, `tree`". The `run` command should be appended to keep the architecture document current. This is a low-priority documentation gap with no functional impact.

2. **Consider extending the `plugin_management.sh` module description**: The header currently describes the module as handling "plugin discovery, descriptor.json parsing, installation-state checking, and activation/deactivation state management." With `cmd_run` added, a brief mention of direct CLI command invocation would make the header fully accurate. This is cosmetic and low priority.

## Conclusion

**Status: Compliant with Notes** — The implementation integrates cleanly into the existing component model. `cmd_run` follows the established `cmd_*` function pattern, reuses existing security helpers (`_validate_plugin_dir`), builds JSON input safely via `jq --arg`, and passes stdout/stderr/exit codes through without modification. The placement in `plugin_management.sh` is architecturally sound given the module's descriptor.json ownership. The module boundary comment remains accurate. The two notes (building block view documentation gap, module header wording) are minor and require no code remediation.
