# loop Command — Interactive Document Pipeline

- **ID:** FEATURE_0045
- **Priority:** MEDIUM
- **Type:** Feature
- **Created at:** 2026-03-15
- **Created by:** Product Owner
- **Status:** IMPLEMENTING

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

Currently, interactive plugin commands (e.g. `train`) that need to iterate over a document collection must implement their own document-discovery and pipeline-execution logic internally. This creates duplication and coupling: the plugin must know how to run `doc.doc.sh` recursively or re-implement the file-scan / MIME-filter / plugin-execution pipeline.

This feature adds a `loop` top-level command that acts as a document-iteration wrapper for a single plugin command. `loop` is **interactive-mode only** — it requires a TTY and is not intended for scripted/batch use.

```
./doc.doc.sh loop -d <docsDir> -o <outputDir> --plugin <pluginName> <command>
./doc.doc.sh loop --help
```

`loop` performs the following for each file discovered in `<docsDir>`:

1. Determines the minimal plugin pipeline needed to satisfy all input parameters declared by `<pluginName> <command>` in the plugin's `descriptor.json`.
2. Runs that pipeline against the current file to produce the accumulated JSON context (using the same execution engine as the `process` command, without writing any sidecar output files).
3. Injects `pluginStorage` (derived from `<outputDir>`) into the accumulated JSON, as per the FEATURE_0041 convention.
4. Passes the accumulated JSON on stdin to the target plugin command script and streams its stdout/stderr directly to the terminal.

`loop` itself prints **only the startup banner**. All per-document output is the exclusive responsibility of the target plugin command — it may print prompts, results, progress, or nothing at all.

**Business Value:**
- Decouples interactive plugin commands from document iteration logic — plugins only need to handle a single document at a time
- Eliminates duplicate file-scan and pipeline-execution code across plugins
- Makes stateful interactive workflows (training, labelling, review) consistent and composable
- Enables future interactive plugins without requiring each to re-implement document looping

**Key distinctions from related commands:**

| Command   | Iterates docs? | Writes sidecar .md? | May write pluginStorage? | Invokes plugin command? | Interactive? |
|-----------|:--------------:|:-------------------:|:------------------------:|:-----------------------:|:------------:|
| `process` | yes            | yes                 | yes                      | no (pipeline only)      | yes / no     |
| `run`     | no             | no                  | yes (via plugin command) | yes (single invocation) | yes / no     |
| `loop`    | yes            | no                  | yes (via plugin command) | yes (once per doc)      | **yes only** |

## Acceptance Criteria

### Invocation and interactive gate
- [ ] `./doc.doc.sh loop -d <docsDir> -o <outputDir> --plugin <pluginName> <command>` is the canonical invocation
- [ ] If the terminal is **not** interactive (no TTY / `_IS_INTERACTIVE` is false), `loop` exits with code 1 and an error message explaining that it requires an interactive terminal
- [ ] `./doc.doc.sh loop --help` prints usage for the `loop` command and exits 0
- [ ] The main `./doc.doc.sh --help` lists `loop` as an available command
- [ ] If `-d`, `-o`, `--plugin`, or `<command>` are missing, an informative error is shown and exit code 1 is returned
- [ ] If `<pluginName>` is not a known active plugin, an error is shown and exit code 1 is returned
- [ ] If `<command>` is not declared in the plugin's `descriptor.json`, an error is shown and exit code 1 is returned

### Banner output
- [ ] The startup banner is printed once before document iteration begins, remembers the cursor position, and is not printed again during iteration
- [ ] `loop` produces no other output of its own during document iteration

### Pipeline determination
- [ ] `loop` reads the target plugin command's `descriptor.json` to identify the input fields it requires
- [ ] `loop` resolves, from the active plugin set, which plugins produce those fields (using the existing dependency/capability resolution logic)
- [ ] The `file` plugin always runs first (position 0), consistent with all other pipeline executions
- [ ] Only the minimal set of plugins required to satisfy the command's inputs is executed per document; unnecessary plugins are not run
- [ ] If a required input field cannot be satisfied by any active plugin (and is not provided by `loop` itself, e.g. `filePath`, `pluginStorage`), an error is shown before iteration begins and exit code 1 is returned

### Per-document execution
- [ ] `loop` discovers files in `<docsDir>` using the same scan mechanism as `process` (respecting `--include` / `--exclude` filters when provided)
- [ ] For each discovered file, the determined pipeline is executed in order, accumulating JSON output as `process` does — but **without writing any output files**
- [ ] `pluginStorage` is derived as `<canonical_outputDir>/.doc.doc.md/<pluginName>/` and is created (`mkdir -p`) before iteration begins if it does not yet exist
- [ ] `pluginStorage` and `filePath` are injected into the accumulated JSON before it is passed to the target plugin command
- [ ] The plugin command's stdin receives the accumulated JSON object
- [ ] The plugin command's stdout is streamed directly to the terminal (not captured or modified by `loop`)
- [ ] The plugin command's stderr is streamed directly to stderr
- [ ] If the pipeline emits exit code 65 (ADR-004 intentional skip) for a file, that file is silently skipped and `loop` continues with the next file
- [ ] If the pipeline emits any other non-zero exit code for a file, a warning is logged to stderr and `loop` continues with the next file (graceful degradation, consistent with `process`)
- [ ] The exit code of the plugin command per document does not stop iteration; `loop` always continues to the next file
- [ ] After each plugin command execution, the cursor resets to the position after the banner, allowing the next plugin command's output to overwrite the previous one (enabling dynamic prompts or progress display by the plugin command). The banner remains visible above all plugin command output. The cursor reset is implemented via ANSI escape codes and does not cause flicker. Text after the banner is cleared on each reset to prevent artifacts.

### No sidecar output files
- [ ] `loop` does not create or modify any sidecar `.md` files
- [ ] `loop` itself does not write any data to `<outputDir>` beyond creating the `pluginStorage` directory
- [ ] Files written inside `pluginStorage` are the exclusive responsibility of the target plugin command (e.g. model files written by `train`); `loop` does not control or constrain them

### Filter support
- [ ] `--include <pattern>` and `--exclude <pattern>` flags are supported, with identical semantics to the `process` command, for scoping which files are iterated

### Security
- [ ] `<pluginName>` is validated against known plugin directories (no path traversal, consistent with `run`)
- [ ] `<command>` is validated against the plugin's `descriptor.json` (no arbitrary script execution)
- [ ] `<docsDir>` is canonicalized via `readlink -f` and validated to exist and be readable
- [ ] `<outputDir>` is canonicalized via `readlink -f`; the derived `pluginStorage` path is validated to be under the canonical output directory (no traversal)
- [ ] All JSON field values passed to the plugin command are assembled via `jq` (no shell injection)

### Tests
- [ ] `tests/test_feature_0045.sh` verifies:
  - Loop is rejected when not in interactive mode (TTY check)
  - Banner is printed; no extra output from `loop` itself
  - Pipeline is correctly determined from plugin's descriptor
  - Each file in the docs directory is processed and the plugin command is invoked once per file
  - `pluginStorage` directory is created under `<outputDir>`
  - Files matching exit code 65 from the pipeline are silently skipped
  - `--include` / `--exclude` filters correctly scope the iterated files
  - Error cases: missing args, unknown plugin, unknown command
- [ ] All existing tests continue to pass

## Scope

### In Scope
- New `loop` top-level command in `doc.doc.sh`
- Argument parsing for `-d`, `-o`, `--plugin`, `<command>`, `--include`, `--exclude`
- TTY / interactive mode guard
- Pipeline determination logic (reads `descriptor.json` input field declarations, matches to active plugin capabilities)
- Per-document pipeline execution without output writing (reuse pipeline execution from `plugin_execution.sh`)
- `pluginStorage` derivation and injection (reuse from FEATURE_0041 / FEATURE_0044 convention)
- Help text (`ui_usage_loop`) added to `ui.sh`
- `loop` entry added to main `--help` listing
- TDD test suite `tests/test_feature_0045.sh`

### Out of Scope
- Changes to individual plugin scripts
- Changes to the `process` or `run` commands
- Non-interactive / batch mode for `loop` (out of scope by design)
- Parallel document processing
- Progress bar / per-document progress display (may be a future enhancement)
- Changing the `pluginStorage` path convention

## Technical Requirements

- Reuse `plugin_execution.sh` pipeline execution; do not duplicate JSON accumulation logic
- `pluginStorage` derivation must use the same pattern as FEATURE_0041 and FEATURE_0044: `<canonical_outputDir>/.doc.doc.md/<pluginName>/`
- TTY detection must use the same mechanism as existing interactive-mode guards (`_IS_INTERACTIVE`)
- Pipeline determination must read `descriptor.json` `commands.<command>.inputs` (or equivalent field) to identify required input fields; no hardcoding of field names

## Dependencies

- **FEATURE_0041** (plugin-storage-plumbing): `pluginStorage` derivation and injection pattern
- **FEATURE_0043** (plugin-command-runner / `run` command): plugin command invocation and validation pattern
- **FEATURE_0044** (`run` with `-d`/`-o`): `-o`-derived `pluginStorage` pattern
- **ADR-004** (exit code 65 skip contract): skip behaviour during pipeline execution
- **REQ_0029** (plugin storage): storage directory convention

## Related Links
- Architecture Vision: `project_documentation/01_architecture/`
- Requirements: `project_management/02_project_vision/02_requirements/`
- FEATURE_0041: `project_management/03_plan/02_planning_board/06_done/FEATURE_0041_plugin-storage-plumbing.md`
- FEATURE_0043: `project_management/03_plan/02_planning_board/06_done/FEATURE_0043_plugin-command-runner.md`
- FEATURE_0044: `project_management/03_plan/02_planning_board/06_done/FEATURE_0044_run-command-derive-pluginstorage-from-output-dir.md`
