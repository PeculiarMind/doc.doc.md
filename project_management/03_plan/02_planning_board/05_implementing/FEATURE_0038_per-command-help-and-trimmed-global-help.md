# Feature: Per-Command --help and Trimmed Global Help

- **ID:** FEATURE_0038
- **Priority:** Medium
- **Type:** Feature
- **Created at:** 2026-03-08
- **Created by:** Product Owner
- **Status:** IMPLEMENTING

## TOC
1. [Overview](#overview)
2. [Motivation](#motivation)
3. [Scope](#scope)
4. [Implementation Notes](#implementation-notes)
5. [Acceptance Criteria](#acceptance-criteria)
6. [Dependencies](#dependencies)
7. [Related Links](#related-links)

## Overview

Every `doc.doc.sh` sub-command gets its own `--help` option that prints the ASCII art banner followed by full command-specific usage, options, and examples. In return, the global `doc.doc.sh --help` is trimmed to a compact overview: ASCII art banner, a one-liner purpose statement, the command list with short summaries, and a small set of illustrative example invocations. All example lines across global and per-command help always start with `./` to enable direct copy-paste.

## Motivation

The current global `--help` is lengthy — it contains the full option reference for every command simultaneously, making it hard to scan. Users who know which command they want must scroll past unrelated content. Conversely, running `doc.doc.sh process --help` today falls back to the same full global dump rather than showing process-specific guidance.

The desired UX is:
- `./doc.doc.sh --help` → quick orientation (what commands exist, what the tool does, copy-pasteable examples)
- `./doc.doc.sh <command> --help` → deep dive into that specific command (banner + all options + examples for that command)

## Scope

### 1 — Global `--help` (trimmed)

`./doc.doc.sh --help` must output:
1. ASCII art banner (via `ui_show_banner`)
2. One-line purpose: `doc.doc.md — command-line tool for processing document collections into Markdown`
3. Usage line: `Usage: ./doc.doc.sh <command> [OPTIONS]`
4. Command list with short one-line descriptions (same as today's Commands table)
5. A concise set of example invocations (covering the most common use cases, one per command at most)
6. A footer: `Run ./doc.doc.sh <command> --help for full options of a specific command.`

The process-specific options block, the full filter-logic explanation, and the long example list are **removed** from the global output and moved exclusively to per-command help.

### 2 — Per-command `--help`

Each of the following commands must respond to `--help` with command-specific output:

| Command | Trigger |
|---------|---------|
| `process` | `./doc.doc.sh process --help` |
| `list` | `./doc.doc.sh list --help` |
| `activate` | `./doc.doc.sh activate --help` |
| `deactivate` | `./doc.doc.sh deactivate --help` |
| `install` | `./doc.doc.sh install --help` *(already partial — align to new spec)* |
| `installed` | `./doc.doc.sh installed --help` |
| `tree` | `./doc.doc.sh tree --help` |
| `setup` | `./doc.doc.sh setup --help` *(already partial — align to new spec)* |

Each per-command help output must include:
1. ASCII art banner (via `ui_show_banner`)
2. Purpose line for the command (one sentence)
3. `Usage:` line showing the command signature
4. Full `Options:` block (all flags and arguments with descriptions)
5. `Examples:` block with command-specific example invocations, all starting with `./`

### 3 — Example formatting rule

**All** example invocations in both global and per-command help must start with `./`:
```
./doc.doc.sh process -d /path/to/documents -o /path/to/output
./doc.doc.sh install --plugin markitdown
./doc.doc.sh setup
```

This applies to all examples, whether in the global help or per-command help. No bare `doc.doc.sh` examples — always `./doc.doc.sh`.

## Implementation Notes

- The `usage()` function and per-command help strings live in `doc.doc.md/components/ui.sh` (introduced by FEATURE_0029). All changes must be made there.
- `ui_show_banner` already exists in `ui.sh` and clears the screen before printing the banner to stderr. For help output, the banner should be printed **without** clearing the screen so that any prior context (e.g. an error message that triggered the help) is not lost.
- The `--help` flag for each command must be parsed in the argument-handling section of each command's dispatch path in `doc.doc.sh`, before any validation of other arguments (so `./doc.doc.sh process --help` works even without `-d`).
- Commands that already have `--help` (`install`, `setup`) must be updated to conform to the new format (add banner, align examples to `./` prefix, ensure completeness).
- The global `--help` is still triggered by `doc.doc.sh --help`, `doc.doc.sh -h`, and when no command is given.

## Acceptance Criteria

### Global help
- [ ] `./doc.doc.sh --help` prints the ASCII art banner without clearing the screen
- [ ] Output contains the command list with one-line descriptions for all 8 commands
- [ ] Output contains a compact examples block; every example starts with `./doc.doc.sh`
- [ ] Output ends with `Run ./doc.doc.sh <command> --help for full options of a specific command.`
- [ ] Output does **not** contain the full option reference for any individual command
- [ ] `./doc.doc.sh -h` produces the same output as `./doc.doc.sh --help`

### Per-command help
- [ ] `./doc.doc.sh process --help` prints banner + purpose + usage + all process options + process examples (including filter examples)
- [ ] `./doc.doc.sh list --help` prints banner + purpose + usage + all list sub-commands and options + examples
- [ ] `./doc.doc.sh activate --help` prints banner + purpose + usage + options + example
- [ ] `./doc.doc.sh deactivate --help` prints banner + purpose + usage + options + example
- [ ] `./doc.doc.sh install --help` prints banner + purpose + usage + options + examples
- [ ] `./doc.doc.sh installed --help` prints banner + purpose + usage + options + example
- [ ] `./doc.doc.sh tree --help` prints banner + purpose + usage + example
- [ ] `./doc.doc.sh setup --help` prints banner + purpose + usage + options + examples
- [ ] All per-command `--help` flags are recognised **before** argument validation (no spurious "missing required argument" errors)

### Example formatting
- [ ] Every example line in every help output (global and per-command) starts with `./doc.doc.sh`

### Backward compatibility
- [ ] `./doc.doc.sh` (no arguments) still shows the global help (or a usage error followed by global help)
- [ ] Existing commands and tests are unaffected (REQ_0038)
- [ ] New tests verify: global help does not contain per-command option blocks; each per-command help contains at least its own options section and banner

## Dependencies

- REQ_0004 (Documentation and Help System)
- REQ_0006 (User-Friendly Interface)
- REQ_0038 (Backward-Compatible CLI)
- FEATURE_0029 (Move Usage Strings to UI Module — baseline location of help strings)

## Related Links

- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0004_documentation-help-system.md`
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0006_user-friendly-interface.md`
- UI module: `doc.doc.md/components/ui.sh`
