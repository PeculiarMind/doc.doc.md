# Security Review: FEATURE_0043 Plugin Command Runner

- **ID:** SECREV_020
- **Created at:** 2026-03-14
- **Created by:** security.agent
- **Work Item:** [FEATURE_0043: Plugin Command Runner](../../03_plan/02_planning_board/05_implementing/FEATURE_0043_plugin-command-runner.md)
- **Status:** Approved with Recommendations

## Table of Contents
1. [Reviewed Scope](#reviewed-scope)
2. [Security Concept Reference](#security-concept-reference)
3. [Assessment Methodology](#assessment-methodology)
4. [Findings](#findings)
5. [Conclusion](#conclusion)

## Reviewed Scope

| File | Changes | Security Relevance |
|------|---------|-------------------|
| `doc.doc.md/components/plugin_management.sh` | Added `cmd_run()`, `_run_global_help()`, `_run_plugin_help()` | High — plugin name/command validation, path construction, script invocation |
| `doc.doc.sh` | Registered `run` in `main()` case statement | Low — routing only |
| `doc.doc.md/components/ui.sh` | Added `ui_usage_run()` help text | None — display only |

## Security Concept Reference

| Requirement | Relevance |
|-------------|-----------|
| REQ_SEC_001 (Input Validation and Sanitization) | CLI arguments (plugin name, command name, flags, key=value pairs) must be validated before any filesystem or script execution |
| REQ_SEC_005 (Path Traversal Prevention) | Plugin name must be validated against `$PLUGIN_DIR` boundary; command script path must remain within the plugin's own directory |

## Assessment Methodology

1. **Plugin name path traversal analysis** — `cmd_run` passes the user-supplied `$plugin_name` to `_validate_plugin_dir "$PLUGIN_DIR" "$plugin_name"`. That function:
   ```bash
   canonical_base="$(cd "$base_dir" 2>/dev/null && pwd -P)" || return 1
   canonical_dir="$(cd "$raw_dir" 2>/dev/null && pwd -P)" || return 1
   if [ "${canonical_dir#"$canonical_base/"}" = "$canonical_dir" ]; then
     return 1
   fi
   ```
   This canonicalises both the base and the candidate directory via `cd + pwd -P` (resolves symlinks and `..`), then checks that the resolved path begins with `$canonical_base/`. Traversal attempts like `../../etc`, `../other-plugin`, or absolute paths are all caught because `cd` to a non-existent directory returns non-zero (failing the function), and because any directory outside `$PLUGIN_DIR/` fails the prefix check. The returned `canonical_dir` is the safe, canonical plugin path used for all subsequent file operations.

2. **Command name injection analysis** — `command_name` is passed exclusively via `jq --arg`:
   ```bash
   command_script=$(jq -r --arg cmd "$command_name" '.commands[$cmd].command // empty' "$descriptor")
   ```
   `jq --arg` treats the value as a plain string; it cannot escape the JSON string context or inject jq filter syntax. Only commands explicitly declared in descriptor.json are reachable. An unrecognised command name returns empty string, which is caught and rejected with `exit 1` before any script path is constructed.

3. **Command script path boundary check** — Once `command_script` is retrieved from descriptor.json, the script path is assembled as:
   ```bash
   local script_path="$plugin_dir/$command_script"
   ```
   The `command_script` value is taken directly from descriptor.json without path canonicalisation or boundary enforcement. If descriptor.json contained a traversal path (e.g. `../../other-plugin/evil.sh`) or an absolute path (e.g. `/bin/sh`), the resulting `script_path` would resolve outside `$plugin_dir`. The `-f` and `-x` checks use the raw path, so a traversal path pointing to an existing executable file would pass both checks and be executed.

   **Threat model context**: exploiting this requires control over descriptor.json. An attacker who can write to descriptor.json can equally write to any `.sh` file within the plugin directory, making the marginal impact limited. Nonetheless, REQ_SEC_005 explicitly states "Plugin files: Must be within plugin directory", so the missing boundary check is a compliance gap.

4. **JSON input construction via `jq --arg`** — All user-supplied values (--file, --plugin-storage, --category, and all key=value pair values) are passed to `jq` exclusively via `--arg`:
   ```bash
   json_input=$(printf '%s' "$json_input" | jq --arg v "$file_path" '. + {filePath: $v}')
   json_input=$(printf '%s' "$json_input" | jq --arg k "$key" --arg v "$val" '. + {($k): $v}')
   ```
   `jq --arg` interns values as JSON strings; no value can escape the string context to inject jq filter syntax or shell metacharacters into the JSON blob. No user input is ever interpolated directly in a shell word.

5. **key=value pair parsing** — Pairs are split using shell parameter expansion:
   ```bash
   key="${pair%%=*}"
   val="${pair#*=}"
   if [ "$key" = "$pair" ]; then
     log_error "Invalid key=value pair: '$pair'. Expected format: key=value"
     exit 1
   fi
   ```
   The guard `[ "$key" = "$pair" ]` correctly rejects pairs with no `=` character (e.g. `foo`). However, pairs beginning with `=` (e.g. `=value`) produce an empty key (`key=""`); the guard does not catch this because `"" != "=value"`. The result is `{"": "value"}` in the JSON object — structurally valid JSON and not exploitable for code execution or injection, but an unexpected edge case that most plugin scripts will silently ignore or fail on with an unhelpful error.

6. **Script invocation** — The plugin script is invoked as:
   ```bash
   printf '%s\n' "$json_input" | bash "$script_path"
   ```
   `$script_path` is not quoted inside a dynamic command string; it is a literal argument to `bash`, so no word-splitting or glob expansion occurs on its value. The JSON blob is passed only via stdin (a pipe), never as a shell argument, so the plugin script cannot receive JSON-injected shell arguments. The `-x` check gates execution, and the `bash` invocation is consistent with how `plugin_execution.sh` invokes plugin scripts elsewhere in the codebase.

7. **Help output safety** — `_run_global_help` and `_run_plugin_help` display plugin names and descriptions read from descriptor.json via `jq -r`. Output goes to the terminal only; no values are used in file paths or command construction during help rendering. Newlines or ANSI codes embedded in description fields would be printed but cannot trigger code execution.

8. **Unused option handling** — Unknown flags are rejected via the `*` case branch with `exit 1`. All recognised flags (`--file`, `--plugin-storage`, `--category`) require a following argument and fail with `exit 1` if omitted. These controls prevent ambiguous or partially-constructed input objects from reaching the plugin script.

## Findings

| # | Severity | Description | Status |
|---|----------|-------------|--------|
| 1 | LOW | `command_script` path not validated to remain within `plugin_dir` — REQ_SEC_005 compliance gap | Open |
| 2 | INFO | Empty-string key accepted in `-- =value` extra pairs, producing `{"": "value"}` in JSON | Open |

### Finding 1 — Missing Boundary Check on `command_script` Path (LOW)

**Location**: `doc.doc.md/components/plugin_management.sh`, `cmd_run()`, lines assembling `script_path`

**Description**: The `command_script` value read from descriptor.json (`commands.<name>.command`) is concatenated with `$plugin_dir` to form `script_path` without subsequently verifying the resolved path remains inside `$plugin_dir`. REQ_SEC_005 requires all plugin files to be within the plugin directory.

**Attack scenario**: An attacker who can write to a plugin's descriptor.json and who controls an executable file reachable via a traversal path (e.g. `../../other-plugin/privesc.sh`) could cause `cmd_run` to execute that file. Exploiting this requires write access to the descriptor.json file, which implies existing control of the plugin directory contents.

**Recommended fix**:
```bash
# After constructing script_path, canonicalise and verify boundary:
local canonical_script
canonical_script="$(cd "$(dirname "$script_path")" 2>/dev/null && pwd -P)/$(basename "$script_path")" || {
  log_error "Cannot resolve script path for command '$command_name'"
  exit 1
}
if [ "${canonical_script#"$plugin_dir/"}" = "$canonical_script" ]; then
  log_error "Command script is outside plugin directory: $canonical_script"
  exit 1
fi
script_path="$canonical_script"
```

### Finding 2 — Empty String Key Accepted in Extra Pairs (INFO)

**Location**: `doc.doc.md/components/plugin_management.sh`, `cmd_run()`, key=value parsing loop

**Description**: The input `-- =value` produces `key=""` which passes the guard `[ "$key" = "$pair" ]` (since `"" != "=value"`). The JSON object receives an empty-string key `{"": "value"}`. This is not exploitable but produces silently malformed input to the plugin.

**Recommended fix**: Add an explicit check for empty key after splitting:
```bash
if [ -z "$key" ]; then
  log_error "Key must not be empty in key=value pair: '$pair'"
  exit 1
fi
```

### Positive Observations

| # | Observation |
|---|------------|
| 1 | **`_validate_plugin_dir` is sound** — `cd + pwd -P` canonicalisation and prefix check robustly prevents all plugin-name path traversal variants, including `../`, absolute paths, and symlink escapes. |
| 2 | **Strict command whitelist via `jq --arg`** — `command_name` cannot escape jq argument context; only names literally present in `commands` object of descriptor.json are reachable. |
| 3 | **All JSON values built with `jq --arg`** — No user-supplied string is ever shell-interpolated during JSON construction; injection via `--file`, `--plugin-storage`, `--category`, or key=value pairs is not possible. |
| 4 | **Unknown flags rejected** — The `*` case branch exits 1 for any unrecognised option, preventing ambiguous input from silently reaching the plugin script. |
| 5 | **Pipeline invocation isolates stdin** — Piping JSON via `printf | bash "$script_path"` means user-supplied data reaches the plugin only through a well-defined stdin channel, not as shell arguments. |

## Conclusion

**Status: Approved with Recommendations** — The primary attack surface (user-supplied CLI arguments: plugin name, command name, flags, and key=value pairs) is well protected. Plugin name path traversal is blocked by the canonicalising `_validate_plugin_dir` helper, command names are whitelisted via strict jq lookup, and all JSON values are built safely through `jq --arg`.

One LOW-severity finding (F-1) represents a defence-in-depth gap relative to REQ_SEC_005: the `command_script` path from descriptor.json is not validated to remain within `plugin_dir`. Practical exploitability is low because it requires prior write access to descriptor.json, but the fix is straightforward and recommended. One INFO finding (F-2) covers an empty-string key edge case with no security impact.

The feature may be shipped as-is; addressing F-1 in a follow-up patch is recommended to achieve full REQ_SEC_005 compliance.
