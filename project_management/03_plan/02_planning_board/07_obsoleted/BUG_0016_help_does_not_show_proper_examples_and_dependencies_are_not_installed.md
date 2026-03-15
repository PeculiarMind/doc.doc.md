# Bug: `run <plugin> <command> --help` Shows JSON Field Names Instead of CLI Flags, and `csslearn`/`cssunlearn` Not Checked by `installed.sh`

- **ID:** BUG_0016
- **Priority:** Medium
- **Type:** Bug
- **Created at:** 2026-03-15
- **Created by:** Product Owner
- **Status:** OBSOLETED
- **Obsolescence reason:** CRM114 plugin requires massive rework and better preparation regarding requirements and resulting architecture; existing implementation and related bugs are no longer valid.
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

Two distinct problems discovered together during crm114 training:

1. **Misleading help text**: `./doc.doc.sh run crm114 train --help` displays raw JSON input field names (e.g. `inputDirectory`) as if they were CLI flags. This leads users to try `--inputDirectory`, which fails. The `run` command uses `-d` for input directory, not `--inputDirectory`.

2. **Incomplete `installed` check**: `installed.sh` only checks for the `crm` or `cssutil` binaries, but the `train` command (`train.sh`) also requires `csslearn` and `cssunlearn`. The Debian `crm114` apt package ships `crm` and `cssutil` but does **not** provide `csslearn` or `cssunlearn` as standalone binaries. As a result, `./doc.doc.sh setup` and `./doc.doc.sh installed --plugin crm114` both report the plugin as fully installed while the `train` command fails at runtime with `Error: csslearn is not available — install crm114 first.`

## Symptoms

**Problem 1 — misleading help:**
```
$ ./doc.doc.sh run crm114 train --help
...
Input fields:
  pluginStorage   (string)  required=true  Plugin storage directory. Derived automatically from -o <output-dir>.
  inputDirectory  (string)  required=true  Path to directory of documents to label.

$ ./doc.doc.sh run crm114 train --inputDirectory ./tests/docs/ -o ./tests/out
Error: Unknown option '--inputDirectory'. Use: run crm114 train --help
```

**Problem 2 — false installed status:**
```
$ ./doc.doc.sh setup
  ✓ crm114  installed: true   active: true    ← reported as fine

$ ./doc.doc.sh run crm114 train -d ./tests/docs/ -o ./tests/out
...
Error: csslearn is not available — install crm114 first.
```
`csslearn` and `cssunlearn` are absent from PATH despite the `crm114` apt package being installed.

## Root Cause

**Problem 1:**
`_run_command_help()` in `plugin_management.sh` renders the raw `input` object from `descriptor.json` verbatim, displaying JSON field names as if they were CLI flags. For commands used via `cmd_run`, users need the CLI flags (`-d`, `-o`, `--file`, `--category`), not the internal JSON field names.

**Problem 2:**
`installed.sh` checks:
```bash
if command -v crm >/dev/null 2>&1 || command -v cssutil >/dev/null 2>&1
```
The Debian `crm114` package (version `20100106-10`) provides `/usr/bin/crm` and `/usr/bin/cssutil` but does **not** include standalone `csslearn` or `cssunlearn` binaries. `train.sh` invokes `csslearn` directly, so it fails even when the package is installed. The `installed` check is therefore incomplete for the full set of commands the plugin offers.

## Expected Behaviour

**Problem 1:**
`./doc.doc.sh run crm114 train --help` should document the CLI flags accepted by `cmd_run` for this command — specifically:
```
  -o <output-dir>   Output directory. pluginStorage is derived as <output-dir>/.doc.doc.md/crm114/
  -d <input-dir>    Input directory containing documents to label.
```
It should not imply that `--inputDirectory` is a valid flag.

**Problem 2:**
`installed.sh` should check for all binaries actually required by the plugin's commands. Either:
- Verify that `csslearn` and `cssunlearn` are present alongside `crm`/`cssutil`, **or**
- Replace `csslearn`/`cssunlearn` calls in `train.sh`, `learn.sh`, and `unlearn.sh` with equivalent `crm -e 'learn ...'` / `crm -e 'unlearn ...'` invocations that only require the `crm` binary (which the apt package does provide)

The second option is preferable as it removes the dependency on tools not shipped by the standard package.

## Steps to Reproduce

```bash
# Problem 1
./doc.doc.sh run crm114 train --help
# → see inputDirectory listed as if it were a flag
./doc.doc.sh run crm114 train --inputDirectory ./tests/docs/ -o ./tests/out
# → Error: Unknown option '--inputDirectory'

# Problem 2
./doc.doc.sh install --plugin crm114   # → "already installed"
./doc.doc.sh run crm114 train -d ./tests/docs/ -o ./tests/out
# → enter any category name → Error: csslearn is not available
```

## Acceptance Criteria

### Problem 1 — Help text shows CLI flags
- [ ] `./doc.doc.sh run crm114 train --help` documents `-o <output-dir>` and `-d <input-dir>` as the CLI flags to use, not raw JSON field names
- [ ] No mention of `--inputDirectory` as a flag anywhere in the help output
- [ ] The pattern applies consistently: `_run_command_help()` should distinguish between JSON-protocol commands (show fields) and interactive commands (show CLI flags); for interactive commands the help is driven by a `"usage"` block in `descriptor.json` rather than the `input` object

### Problem 2 — Incomplete installed check
- [ ] `installed.sh` returns `{"installed": false}` if the binaries required for **all** plugin commands are not available
- [ ] Either `csslearn` and `cssunlearn` are explicitly checked, **or** `train.sh` / `learn.sh` / `unlearn.sh` are updated to use `crm -e 'learn ...'` / `crm -e 'unlearn ...'` instead (preferred — removes dependency on non-packaged binaries)
- [ ] After `./doc.doc.sh install --plugin crm114`, the full training workflow (`./doc.doc.sh run crm114 train -d ./tests/docs/ -o ./tests/out`) runs without a "csslearn not available" error
- [ ] `./doc.doc.sh setup` accurately reflects the usable state of the crm114 plugin

## Dependencies

### Blocking Items
- None — can be fixed independently

### Related Work Items
- **BUG_0015**: `run` command incompatible with interactive plugins — overlaps with Problem 1 (interactive command invocation via `cmd_run`)
- **FEATURE_0042**: CRM114 Model Management Commands — `train.sh`, `learn.sh`, `unlearn.sh` are the affected scripts
- **FEATURE_0043**: Plugin Command Runner — `_run_command_help()` is the function to fix for Problem 1

## Related Links

### Related Work Items
- [BUG_0015: run command incompatible with interactive plugins](BUG_0015_run-command-incompatible-with-interactive-plugins.md)
- [FEATURE_0042: CRM114 Model Management Commands](FEATURE_0042_crm114-model-management-commands.md)
- [FEATURE_0043: Plugin Command Runner](FEATURE_0043_plugin-command-runner.md)
