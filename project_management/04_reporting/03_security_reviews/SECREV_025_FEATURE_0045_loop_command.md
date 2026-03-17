# Security Review: FEATURE_0045 — Loop Command

- **Report ID:** SECREV_025
- **Work Item:** FEATURE_0045
- **Date:** 2026-03-15
- **Agent:** security.agent
- **Status:** Approved with Minor Note

## Scope

Security review of the `loop` command implementation:

1. `cmd_loop()` in `doc.doc.md/components/plugin_management.sh`
2. Loop routing in `doc.doc.sh`
3. `ui_usage_loop()` in `doc.doc.md/components/ui.sh`
4. `run_plugin()` in `doc.doc.md/components/plugin_execution.sh` (as called by loop)

## Changes Reviewed

| File | Change |
|------|--------|
| `doc.doc.md/components/plugin_management.sh` | `cmd_loop()` — full implementation |
| `doc.doc.sh` | Routing of `loop` subcommand |
| `doc.doc.md/components/ui.sh` | `ui_usage_loop()` help text |
| `doc.doc.md/components/plugin_execution.sh` | `run_plugin()` called by the pipeline section |

## Assessment

| Finding | Severity | Status |
|---------|----------|--------|
| `readlink -f` return not checked in `cmd_loop` (inconsistency with `cmd_run`) | LOW | Noted — accepted risk |
| All other reviewed areas | — | No finding |

## Analysis

### 1. Plugin Name / Path Traversal (REQ_SEC_005)

`_validate_plugin_dir()` canonicalizes both the base plugin directory and the requested plugin name using `cd … && pwd -P`, then verifies the result has the canonical base as a strict prefix. This correctly prevents `../` traversal and symlink escapes. `cmd_loop` uses the same guard as `cmd_run` and `cmd_install`.

### 2. Command Script Validation

`loop_command` is passed to `jq` via `--arg`, preventing any injection into the jq filter expression. The `command_script` value retrieved from `descriptor.json` is then:

1. Prepended with the already-validated `plugin_dir` to form `script_path`.
2. Canonicalized via `cd "$(dirname …)" && pwd -P` / `basename`.
3. Verified to have `canonical_plugin/` as a strict prefix (path traversal blocked).
4. Verified to be executable before invocation.

This chain satisfies REQ_SEC_005 end-to-end.

### 3. JSON Context Assembly (Shell Injection)

All user-supplied values (`file_path`, `plugin_storage`) are passed into jq via `--arg`, never interpolated into a filter string. Pipeline-produced JSON is merged with `jq -s '.[0] * .[1]'`, which is also injection-free. Context JSON is piped to the target script via stdin (`printf '%s\n' "$context_json" | bash "$canonical_script"`), not via command-line arguments. No shell injection vector exists.

### 4. Input Directory (`docs_dir`)

`docs_dir` is validated for existence and readability (`[ ! -d … ] || [ ! -r … ]`). It is intentionally **not** canonicalized because no boundary restriction is defined for input directories — users may legitimately point `-d` at a symlink. `find "$docs_dir" -type f` does not follow symlink directories by default, so deeply nested symlink traversal is not a concern. File paths discovered by `find` are passed into jq via `--arg`, preventing injection.

### 5. Output Directory Canonicalization — Minor Note

In `cmd_run` (line 981), the `readlink -f` call is guarded:

```bash
canonical_out="$(readlink -f "$output_dir")" || {
  log_error "Cannot resolve output directory: $output_dir"
  exit 1
}
```

In `cmd_loop` (line 1150), the equivalent call is unguarded:

```bash
canonical_out="$(readlink -f "$output_dir")"
```

In practice this is safe because `mkdir -p "$output_dir"` immediately precedes this call and only proceeds on success, meaning the directory exists when `readlink -f` runs. However, the inconsistency is a code quality concern. If `readlink -f` were to return an empty string for any reason, `plugin_storage` would resolve to `/.doc.doc.md/$plugin_name`, and the subsequent prefix check (`${plugin_storage#"$canonical_out/"}`) would compare against an empty prefix, which would pass — potentially creating a root-level directory.

**Risk level:** LOW. The scenario requires `readlink -f` to fail on a directory that was just successfully created, which is not realistically possible under normal conditions.

**Recommendation:** Add the error-handling guard for consistency, matching the `cmd_run` pattern. No bug work item raised; the fix is a one-line improvement.

### 6. `pluginStorage` Derivation

`plugin_storage` is derived as `"$canonical_out/.doc.doc.md/$plugin_name"`. The containment check `[ "${plugin_storage#"$canonical_out/"}" = "$plugin_storage" ]` correctly blocks any traversal outside `canonical_out`. The `plugin_name` component was validated by `_validate_plugin_dir`, which prevents names containing path separators that resolve outside `PLUGIN_DIR`.

### 7. TTY Enforcement

The TTY check (`[ ! -t 1 ]`) is placed after argument parsing and plugin validation so that validation errors are still reported in non-TTY contexts. The check itself prevents unintended execution in scripted pipelines where cursor-control escape sequences would corrupt output. This is the correct placement.

### 8. ANSI Escape Handling

All ANSI sequences emitted by `cmd_loop` (`\033[s`, `\033[u\033[J`) are hardcoded literals, not derived from user input. `ui_show_help_banner` uses static strings. Filenames appearing in `log_warn` output (via `basename "$file_path"`) could theoretically contain embedded ANSI sequences if an attacker controls the filesystem; however, this is a general terminal output concern not specific to this feature, and the impact is limited to cosmetic terminal corruption with no code-execution path.

### 9. `--include` / `--exclude` Filter Arguments

These values are forwarded to `python3 "$FILTER_SCRIPT"` as array elements, not shell-expanded strings. No shell injection is possible. Pattern safety within the Python filter is out of scope for this review.

### 10. `run_plugin` Pipeline Invocation

`run_plugin` is called with a hardcoded pipeline plugin name (`"file"`) derived from the descriptor's declared input fields — no user-controlled value reaches the `run_plugin` call's first argument. This matches the established pattern reviewed in SECREV_020.

## Verdict

**Approved** — The `loop` command correctly implements all five security requirements specified in FEATURE_0045:

- Plugin name validated against known plugin directories (no path traversal).
- Command validated against `descriptor.json` before execution (no arbitrary script execution).
- `outputDir` canonicalized via `readlink -f`; derived `pluginStorage` verified to be under canonical output dir.
- All JSON field values assembled via `jq --arg` (no shell injection).
- TTY enforcement prevents silent misuse in scripted contexts.

One low-severity inconsistency noted: the `readlink -f` call in `cmd_loop` lacks the error-handling guard present in `cmd_run`. Recommended to fix for robustness but not blocking approval.
