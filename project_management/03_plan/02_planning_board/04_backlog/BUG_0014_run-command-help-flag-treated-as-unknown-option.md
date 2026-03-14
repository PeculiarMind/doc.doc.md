# Bug: `run <plugin> <command> --help` Treated as Unknown Option

- **ID:** BUG_0014
- **Priority:** Medium
- **Type:** Bug
- **Created at:** 2026-03-14
- **Created by:** Product Owner
- **Status:** BACKLOG

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

When a user passes `--help` after a fully-specified `run <plugin> <command>` invocation, the flag is not recognised and the error message incorrectly tells the user to use the very syntax they already used.

## Symptoms

```
$ ./doc.doc.sh run crm114 train --help
Error: Unknown option '--help'. Use: run crm114 train --help
```

The error message is self-referential and unhelpful — it suggests `run crm114 train --help` as the remedy while that is exactly what was invoked.

## Root Cause

The argument parser for the `run` command's third positional level (`run <plugin> <command> [options]`) does not handle `--help` before attempting to parse remaining options. The `--help` flag falls through to the unknown-option error branch, which then incorrectly echoes the exact invocation as a suggested fix.

## Expected Behaviour

`./doc.doc.sh run crm114 train --help` should print the help text for the `train` command of the `crm114` plugin (description, accepted input fields, output fields — sourced from `descriptor.json`) and exit 0.

Consistent with the two-level help pattern already specified in FEATURE_0043:
- `./doc.doc.sh run --help` → list all plugins
- `./doc.doc.sh run <plugin> --help` → list commands for that plugin
- `./doc.doc.sh run <plugin> <command> --help` → show details for that specific command

## Steps to Reproduce

```bash
./doc.doc.sh run crm114 train --help
```

Expected: command help text, exit 0  
Actual: `Error: Unknown option '--help'. Use: run crm114 train --help`, exit 1

## Acceptance Criteria

- [ ] `./doc.doc.sh run <plugin> <command> --help` prints the command's `description`, its declared input fields (names, types, required flag), and its declared output fields — all sourced from `descriptor.json`
- [ ] Exit code is 0
- [ ] The self-referential error message is removed
- [ ] `./doc.doc.sh run --help` and `./doc.doc.sh run <plugin> --help` continue to work correctly
- [ ] `tests/test_feature_0043.sh` (or a new `tests/test_bug_0014.sh`) verifies `--help` at all three levels exits 0 and prints expected text

## Dependencies

### Blocking Items
- **FEATURE_0043** (Plugin Command Runner) — this bug is in the `run` command implemented by FEATURE_0043

## Related Links

### Related Work Items
- [FEATURE_0043: Plugin Command Runner](FEATURE_0043_plugin-command-runner.md)
