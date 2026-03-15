# Security Review: BUG_0015 — Interactive plugin command support

- **Report ID:** SECREV_023
- **Work Item:** BUG_0015
- **Date:** 2026-03-14
- **Agent:** security.agent
- **Status:** Approved

## Scope

Security review of the interactive command dispatch logic added to `cmd_run()` in `plugin_management.sh`, and descriptor changes to `crm114/descriptor.json`.

## Changes Reviewed

| File | Change |
|------|--------|
| `doc.doc.md/components/plugin_management.sh` | Interactive mode detection via jq; conditional positional-arg invocation |
| `doc.doc.md/plugins/crm114/descriptor.json` | Added `"interactive": true` to `train` command |

## Assessment

| Finding | Severity | Status |
|---------|----------|--------|
| None | — | — |

## Analysis

1. **Interactive field source:** The `"interactive"` value is read from the plugin's local `descriptor.json` file using `jq -r`, not from user input. The descriptor file is already validated earlier in `cmd_run()` (existence + valid JSON). This is a trusted source.

2. **Script execution path:** The interactive branch (`bash "$canonical_script" "$plugin_storage" "$input_dir"`) uses the same `canonical_script` variable that has already been:
   - Validated against the descriptor's command whitelist
   - Canonicalized via `cd/pwd -P`
   - Verified to be within the plugin directory (REQ_SEC_005)
   - Verified to be executable

3. **Argument passing:** `$plugin_storage` and `$input_dir` are passed as positional arguments to the script. These values have already been validated:
   - `plugin_storage`: derived from `-o` via `readlink -f` with prefix check (FEATURE_0044, REQ_SEC_005), or from `--plugin-storage` flag
   - `input_dir`: validated for existence and readability (FEATURE_0044)

4. **No new user input vectors:** The `"interactive"` field is read-only from the descriptor. Users cannot control whether a command runs in interactive mode — this is determined by the plugin author via `descriptor.json`.

5. **stdin implications:** In interactive mode, stdin is NOT consumed by a JSON pipe, leaving it available for the script. This is the intended behavior and does not introduce any injection vector since the script receives only validated positional arguments.

6. **Backward compatibility:** Commands without `"interactive"` field default to `false` via `jq`'s `// false`, preserving existing JSON-stdin behavior exactly.

## Verdict

**Approved** — No security concerns. All values used in the interactive execution path have been validated through existing security gates. The change introduces no new input vectors.
