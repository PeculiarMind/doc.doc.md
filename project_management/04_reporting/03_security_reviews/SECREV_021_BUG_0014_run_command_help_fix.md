# Security Review: BUG_0014 — run command-level --help fix

- **Report ID:** SECREV_021
- **Work Item:** BUG_0014
- **Date:** 2026-03-14
- **Agent:** security.agent
- **Status:** Approved

## Scope

Security review of the `--help` flag handling added to `cmd_run()` at the `run <plugin> <command>` level.

## Changes Reviewed

| File | Change |
|------|--------|
| `doc.doc.md/components/plugin_management.sh` | `_run_command_help()` function, `--help` check in `cmd_run()` |

## Assessment

| Finding | Severity | Status |
|---------|----------|--------|
| None | — | — |

## Analysis

1. **Input handling:** The `--help` check occurs after both `plugin_name` and `command_name` have been fully validated (plugin via `_validate_plugin_dir`, command via `jq` lookup against `descriptor.json`). No new user input is introduced.

2. **jq usage:** `_run_command_help()` uses `jq -r --arg cmd "$command_name"` with already-validated `command_name`. Values are read from the local `descriptor.json` file, not from user input. Safe.

3. **Output:** Function prints text to stdout only. No file writes, no code execution.

4. **Information disclosure:** Field names, types, descriptions, and required flags from `descriptor.json` are already visible to anyone with filesystem access. Displaying them via `--help` does not expand the attack surface.

## Verdict

**Approved** — No security concerns. The change is a read-only display function with no new input vectors.
