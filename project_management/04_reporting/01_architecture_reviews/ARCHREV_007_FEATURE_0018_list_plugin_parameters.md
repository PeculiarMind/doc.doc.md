# Architecture Review: FEATURE_0018 — List Plugin Parameters Command

- **ID:** ARCHREV_007
- **Created at:** 2026-03-06
- **Created by:** architect.agent
- **Work Item:** [FEATURE_0018](../../03_plan/02_planning_board/06_done/FEATURE_0018_list_plugin_parameters.md)
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
| `doc.doc.sh` — `cmd_list()` | Modified | Added `list parameters` (all plugins) and `list --plugin <name> --parameters` (single plugin) sub-commands; updated `usage()` help text |

No plugin files were modified. The feature is a read-only introspection capability.

## Architecture Vision Reference

- [ADR-003: JSON-Based Plugin Descriptors with Shell Command Invocation](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md)
- [ARC-0003: Plugin Architecture Concept](../../02_project_vision/03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md)
- [ADR-001: Mixed Bash/Python Implementation](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_001_mixed_bash_python_implementation.md)

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| **ADR-003 — Read-only descriptor inspection** | ✅ Compliant | Neither `list parameters` nor `list --plugin --parameters` invoke any plugin process, install, or installed scripts. All data is extracted directly from `descriptor.json` via `jq`. Descriptor files are not modified. |
| **ADR-003 — jq for JSON parsing** | ✅ Compliant | Both sub-commands use a single `jq -r` expression to extract `input` and `output` blocks per command, emitting tab-separated rows. The jq query correctly handles commands with no `input` block (`// {}`) and no `output` block (`// {}`). |
| **ADR-003 — lowerCamelCase surface** | ✅ Compliant | The display reads parameter names directly from the descriptor; it does not rename or transform them. All existing plugin descriptors follow lowerCamelCase convention, so the output correctly reflects the established naming standard. |
| **ARC-0003 — Descriptor as single source of truth** | ✅ Compliant | Parameter information is read exclusively from `descriptor.json`. No hardcoded parameter lists or parallel data structures are introduced. |
| **ARC-0003 — Plugin discovery** | ✅ Compliant | `list parameters` (all plugins) uses `discover_all_plugins()` — the same discovery function used by `cmd_tree()` — which scans the plugin directory and returns all plugin names, regardless of `active` status. Consistent with the principle that `list` commands show all registered plugins. |
| **Output format — stdout/stderr separation** | ✅ Compliant | Parameter table is written to stdout. Error messages (unknown plugin, missing descriptor, invalid JSON) are written to stderr. Consistent with Unix convention and ARC-0004 error handling guidance. |
| **Output format — column alignment** | ✅ Compliant | `column -t -s $'\t'` is applied to the tab-separated jq output, producing space-padded columns. Output matches the example layout in the FEATURE_0018 acceptance criteria. |
| **Output format — direction column** | ✅ Compliant | Every row carries a `DIRECTION` value of either `input` or `output`, making the data flow unambiguous. Output parameters render `REQUIRED` and `DEFAULT` as `-`. |
| **Output format — sort order** | ✅ Compliant | jq output is piped to `sort`. Since the first field is the plugin name (for all-plugins form) or command name (for single-plugin form), and `sort` applies lexicographic ordering across all fields, the effective sort is: plugin → command → direction (`input` < `output` alphabetically) → parameter name. This matches the AC sort specification. |
| **Flag validation** | ✅ Compliant | `--parameters` without `--plugin` is rejected with a clear stderr error and exit 1. `--plugin` without `--commands` or `--parameters` is rejected. `list parameters extra_arg` is rejected. All flag validation uses standard `echo >&2; exit 1` patterns consistent with other `doc.doc.sh` commands. |
| **Error handling — unknown plugin** | ✅ Compliant | `list --plugin <name> --parameters` checks for plugin directory existence and descriptor file presence before proceeding. Invalid JSON in a descriptor is detected via `jq empty` and produces a clear error. |
| **Usage/help text** | ✅ Compliant | `usage()` documents both `list parameters` and `list --plugin <name> --parameters` with examples. Both forms are also listed in the `Examples:` block of the help output. |
| **No new external dependencies** | ✅ Compliant | `jq` (already a project dependency) and `column` (standard POSIX/Linux utility) are the only tools used. No new external tools are introduced. |

## Deviations Found

None.

## Recommendations

1. **Graceful handling of invalid `descriptor.json` in `list parameters` (all-plugins form)**: The all-plugins form silently skips descriptors that cannot be read (`jq ... 2>/dev/null`) but does not warn the user about corrupt or invalid descriptors. For consistency with the single-plugin form (which explicitly validates the descriptor and errors out), the all-plugins form could emit a `WARN` to stderr for any descriptor that fails to parse. This is a user-experience improvement, not an architectural requirement.

2. **Help text for sub-commands**: The `cmd_list` function does not have its own `--help` sub-handler that prints scoped help. When a user types `doc.doc.sh list --help`, the global `usage()` is called. This is consistent with how other commands behave in `doc.doc.sh` today, but as the `list` surface grows, a dedicated `cmd_list --help` handler that shows only list-related options would improve discoverability.

## Conclusion

FEATURE_0018 is **fully compliant** with the architecture vision. The implementation correctly extends the `cmd_list` function with two new sub-commands that inspect plugin descriptors read-only via `jq`. Parameter names, types, and direction are read directly from `descriptor.json` — the architectural single source of truth — without invoking any plugin processes. Output is column-aligned to stdout; errors go to stderr. Flag validation, error handling, and help text are all correctly implemented. No new external dependencies are introduced.

**Result: PASS**
