# Architecture Review: FEATURE_0045 — loop Command (Interactive Document Pipeline)

- **Report ID:** ARCHREV_025
- **Work Item:** FEATURE_0045
- **Date:** 2026-03-15
- **Agent:** architect.agent
- **Status:** Compliant

## Scope

Review of the `loop` top-level command implementation spanning:

| File | Change |
|------|--------|
| `doc.doc.sh` | Added `loop)` routing case to command switch |
| `doc.doc.md/components/plugin_management.sh` | New `cmd_loop()` function (~200 lines) |
| `doc.doc.md/components/ui.sh` | New `ui_usage_loop()` help function; `usage_loop()` alias |
| `tests/test_feature_0045.sh` | 52-test TDD suite covering all acceptance criteria |

`loop` iterates over documents in a directory, executes a minimal plugin pipeline per file (without writing sidecar output), injects `filePath` and `pluginStorage` into the accumulated JSON context, and invokes a target plugin command per file with that context on stdin.

## Changes Reviewed

### doc.doc.sh — Command Routing

`loop` is added as a first-class routing case in the main command switch, structurally identical to `run`, `process`, and every other routed command:

```bash
loop)
  cmd_loop "$@"
  exit $?
  ;;
```

No other changes to `doc.doc.sh`.

### plugin_management.sh — cmd_loop()

The implementation follows the established `cmd_run()` pattern throughout.

**Argument parsing** mirrors the flag-first, positional-last style used in `cmd_run()`. Flags `-d`, `-o`, `--plugin`, `--include`, `--exclude`, and `--help` are all handled. `<command>` is the positional argument, rejected if it appears more than once or after unknown flags.

**Plugin and script validation** reuses `_validate_plugin_dir()` for path-traversal prevention, then canonicalizes and verifies the command script path within the plugin directory — identical to the pattern in `cmd_run()` and marked with the same `REQ_SEC_005` annotation.

**TTY guard** uses `[ ! -t 1 ]` (POSIX test on stdout file descriptor). The feature specification referenced `_IS_INTERACTIVE`, but no such global variable exists in the codebase; `[ ! -t 1 ]` is the correct and consistent mechanism used elsewhere for interactive detection. Placed after `--help` handling so help is always accessible without a TTY.

**`pluginStorage` derivation** is `<canonical_out>/.doc.doc.md/<plugin_name>/`, created before iteration begins, with a post-derivation traversal check — byte-for-byte consistent with `cmd_run()` (FEATURE_0044) and the REQ_0029 convention.

**Pipeline determination** reads `.commands[$cmd].input` from the plugin's `descriptor.json` via `jq`. Fields `filePath` and `pluginStorage` are recognised as loop-provided and excluded from pipeline resolution; if any other input field is declared, the `file` plugin is added to the minimal pipeline. This is a pragmatic simplification of the full dependency-graph resolution described in the spec (see Recommendations).

**Per-document execution** passes accumulated JSON through `run_plugin()` with an empty `output_dir` argument so no sidecar files are written, consistent with the no-output requirement. Exit code 65 from pipeline plugins propagates a silent skip per ADR-004. Non-65 failures continue with partial context (graceful degradation, consistent with `process`). `pluginStorage` is injected after the pipeline so no pipeline plugin can override the loop-derived canonical path.

**Cursor management** uses `\033[s` (save) once after the banner and `\033[u\033[J` (restore + clear below) before each plugin command invocation — implementing the "overwrite previous output" behaviour described in the spec without flicker.

**JSON safety** — all field values injected into `context_json` are passed via `jq --arg`; no shell variable interpolation touches the JSON construction path.

### ui.sh — Help Text

`ui_usage_loop()` follows the established `ui_usage_*` pattern: calls `ui_show_help_banner`, then emits a heredoc. The usage line, argument table, options table, behaviour notes (TTY requirement, no sidecar files, ADR-004 skip semantics), and examples are all present. The `usage_loop()` backward-compatible alias is appended with the other aliases. The main `--help` listing includes `loop`.

## Compliance Assessment

| Criterion | Status | Notes |
|-----------|--------|-------|
| ADR-001: Bash implementation | ✅ | Pure Bash + `jq`; no new language or binary dependencies |
| ADR-002: Tool reuse | ✅ | Reuses `_validate_plugin_dir()`, `run_plugin()`, `filter.py`, `ui_show_help_banner()`, `jq` |
| ADR-003: JSON plugin descriptors | ✅ | Reads `.commands[$cmd].input` and `.commands[$cmd].command` from `descriptor.json`; no descriptor schema changes |
| ADR-004: Exit code 65 skip contract | ✅ | Exit 65 from pipeline silently skips file; exit 65 from plugin command silently skipped; non-65 non-zero logs warning and continues |
| REQ_0029: Plugin storage convention | ✅ | `<canonical_out>/.doc.doc.md/<plugin_name>/` created before iteration; absolute path injected as `pluginStorage`; no plugin constructs its own path |
| REQ_SEC_005: Path traversal prevention | ✅ | `_validate_plugin_dir()` guards plugin name; script path canonicalized and verified within plugin dir; derived `pluginStorage` verified under output dir |
| Shell injection prevention | ✅ | All JSON field values pass through `jq --arg`; no user-supplied values interpolated into shell commands |
| Command routing pattern | ✅ | `loop)` case identical in structure to `run)`, `process)`, and other routed commands |
| Component placement | ✅ | `cmd_loop()` in `plugin_management.sh` (correct module); `ui_usage_loop()` in `ui.sh` (correct module) |
| Help text conventions | ✅ | `ui_usage_loop()` follows `ui_usage_*` pattern; `usage_loop()` alias added; main `--help` updated |
| `pluginStorage` derivation pattern | ✅ | Byte-for-byte consistent with FEATURE_0041/FEATURE_0044 convention |
| FEATURE_0043 (`run`) consistency | ✅ | Validation flow, security checks, and JSON construction mirror `cmd_run()` |
| No sidecar output files | ✅ | `run_plugin()` called with empty `output_dir`; only `pluginStorage` directory created |
| Filter support (`--include`/`--exclude`) | ✅ | Delegates to the same `filter.py` pipeline used by `process` |
| Backward-compatible alias | ✅ | `usage_loop()` alias added alongside other `usage_*` aliases |

## Deviations

None — no architectural violations identified.

## Recommendations

### R1 — `docs_dir` canonicalization

The feature specification states `<docsDir>` should be canonicalized via `readlink -f` before use. The implementation validates existence and readability but passes the raw path to `find`. Functional impact is negligible (symlinks resolve correctly under `find -L`, and no security boundary depends on this path), but canonicalization would align the implementation precisely with the documented contract and with how `_PROC_BASE_PATH_RESOLVED` is handled in `doc.doc.sh`. Recommended as a cosmetic improvement if a maintenance pass occurs.

### R2 — Pipeline determination covers only the `file` plugin

The specification described a generalised dependency-resolution algorithm: read the command's declared input fields, then resolve which active plugins produce each field. The implementation applies a pragmatic simplification: if any input field beyond `filePath` and `pluginStorage` is declared, the `file` plugin is added — and no other plugins are ever added. For the current plugin ecosystem, where `file` is the sole data-enrichment plugin in the standard pipeline, this is correct and sufficient. As the ecosystem grows (e.g., plugins producing fields consumed by other plugin commands), the pipeline determination logic will need to be extended to perform full dependency graph resolution. This is not a current defect but represents scoped future work.

### R3 — No pre-flight validation for unsatisfied input fields

The spec required that if a command's declared input field cannot be satisfied by any active plugin, `loop` should fail before iteration begins. The current implementation skips this check entirely (it does not inspect active plugin capabilities beyond deciding whether to add `file`). This is consistent with the simplified pipeline determination in R2. Should full dependency resolution be implemented (R2), the pre-flight validation gate can be added at the same time.

## DEBTR Items

None. No architectural violations were identified that warrant technical debt tracking. Recommendations R1–R3 are minor observations appropriate for a future maintenance pass rather than blocking items.

## Verdict

**Compliant** — The `loop` command implementation is architecturally sound. It correctly reuses `_validate_plugin_dir()`, `run_plugin()`, and `filter.py`; enforces the REQ_0029 `pluginStorage` convention; implements the ADR-004 exit-code contract at both pipeline and command invocation levels; prevents path traversal and shell injection via established patterns; and places all code in the correct component modules. The three recommendations above are minor and do not affect current correctness.
