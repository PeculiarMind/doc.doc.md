# Bug: `run` Command Incompatible with Interactive Plugin Commands (train.sh)

- **ID:** BUG_0015
- **Priority:** Medium
- **Type:** Bug
- **Created at:** 2026-03-14
- **Created by:** Product Owner
- **Status:** IMPLEMENTING
- **Assigned to:** developer.agent

## TOC
1. [Overview](#overview)
2. [Symptoms](#symptoms)
3. [Root Cause](#root-cause)
4. [Expected Behaviour](#expected-behaviour)
5. [Steps to Reproduce](#steps-to-reproduce)
6. [Acceptance Criteria](#acceptance-criteria)
7. [Dependencies](#dependencies)
8. [Related Links](#related-links)

## Overview

`cmd_run` always invokes plugin command scripts by piping a JSON object to their stdin:

```bash
printf '%s\n' "$json_input" | bash "$canonical_script"
```

This works for non-interactive plugin commands (e.g. `process`, `learn`, `unlearn`, `listCategories`) that read their configuration from JSON stdin. However, the interactive `train` command (`train.sh`) needs stdin for user prompts and therefore uses positional command-line arguments instead. These two conventions are incompatible: `cmd_run` consumes stdin with JSON before `train.sh` can use it interactively.

## Symptoms

```
$ ./doc.doc.sh run crm114 train -o ./tests/out -d ./tests/docs/
Usage: train.sh <pluginStorage> <input_dir>
  pluginStorage  Path to crm114 plugin storage directory
  input_dir      Path to directory of documents to label
exit: 1
```

`train.sh` receives no positional arguments (because `cmd_run` doesn't pass any) and its stdin is already consumed by the JSON pipe, so the interactive labeling loop cannot start.

**Workaround** (invoke the plugin script directly):
```bash
./doc.doc.md/plugins/crm114/train.sh ./tests/out/.doc.doc.md/crm114/ ./tests/docs/
```

## Root Cause

Two conflicting conventions:
1. **`cmd_run`** assembles a JSON object and pipes it to the plugin script's stdin — suitable for non-interactive, JSON-protocol commands.
2. **`train.sh`** takes positional command-line arguments and reads stdin interactively from the user — incompatible with receiving configuration via a JSON pipe on stdin.

The `descriptor.json` schema currently has no way to declare that a command is interactive or uses positional arguments rather than JSON stdin, so `cmd_run` has no way to detect this and behave differently.

## Expected Behaviour

`./doc.doc.sh run crm114 train -o ./tests/out -d ./tests/docs/` should start the interactive training session, deriving `pluginStorage` from `-o ./tests/out` and passing the input directory to `train.sh`.

## Steps to Reproduce

```bash
mkdir -p ./tests/out
./doc.doc.sh run crm114 train -o ./tests/out -d ./tests/docs/
```

Expected: interactive labeling session starts  
Actual: `Usage: train.sh <pluginStorage> <input_dir>`, exit 1

## Acceptance Criteria

- [ ] `./doc.doc.sh run crm114 train -o ./tests/out -d ./tests/docs/` starts the interactive training session
- [ ] `cmd_run` detects that a command is interactive (via a `descriptor.json` field, see below) and passes derived values as positional CLI arguments instead of piping JSON to stdin
- [ ] Non-interactive commands continue to receive JSON via stdin unchanged
- [ ] `descriptor.json` supports an `"interactive": true` field on a command entry to signal the positional-arg / interactive-stdin convention
- [ ] When `"interactive": true`, `cmd_run` passes `pluginStorage` (derived from `-o`) and `inputDirectory` (from `-d`) as positional arguments in that order, and does NOT pipe JSON to stdin — leaving stdin free for user interaction
- [ ] `tests/test_bug_0015.sh` verifies that a mock interactive plugin command is invoked with positional args when `"interactive": true` is set in its descriptor

### descriptor.json fixes (crm114 `train` command)
- [ ] `"interactive": true` is added to the `train` command entry in `descriptor.json`
- [ ] The `pluginStorage` input field description no longer mentions "positional argument 1" — it should describe the field semantically (e.g. "Plugin storage directory. Derived automatically from `-o <output-dir>`.")
- [ ] The `input_dir` input field is renamed to `inputDirectory` (camelCase, consistent with all other commands) and its description no longer mentions "positional argument 2"
- [ ] `./doc.doc.sh run crm114 train --help` reflects the corrected field names and descriptions

## Dependencies

### Blocking Items
- **FEATURE_0043** (Plugin Command Runner) — `cmd_run` is implemented there
- **FEATURE_0044** (run command: derive pluginStorage from -o) — pluginStorage derivation must be in place for the positional pass-through to receive the correct path

### Related Work Items
- **FEATURE_0042** (CRM114 Model Management) — `train.sh` is the affected script

## Related Links

### Related Work Items
- [FEATURE_0042: CRM114 Model Management Commands](FEATURE_0042_crm114-model-management-commands.md)
- [FEATURE_0043: Plugin Command Runner](FEATURE_0043_plugin-command-runner.md)
- [FEATURE_0044: run Command — Derive pluginStorage from -o](FEATURE_0044_run-command-derive-pluginstorage-from-output-dir.md)
- [BUG_0014: run --help treated as unknown option](BUG_0014_run-command-help-flag-treated-as-unknown-option.md)
