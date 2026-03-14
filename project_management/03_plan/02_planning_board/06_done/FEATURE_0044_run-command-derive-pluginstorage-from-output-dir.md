# run Command: Derive pluginStorage from -d / -o Instead of --plugin-storage

- **ID:** FEATURE_0044
- **Priority:** MEDIUM
- **Type:** Feature
- **Created at:** 2026-03-14
- **Created by:** Product Owner
- **Status:** DONE
- **Assigned to:** developer.agent

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

When invoking plugin commands via `./doc.doc.sh run <plugin> <command>`, users currently must know and supply the internal `pluginStorage` path via `--plugin-storage <dir>`. This path is an implementation detail (`<output_dir>/.doc.doc.md/<pluginname>/`) that the `process` command already derives automatically (FEATURE_0041).

This feature makes `run` consistent with `process` by accepting `-d <input-dir>` and `-o <output-dir>` as standard parameters and deriving the `pluginStorage` path the same way the `process` command does — eliminating the need for users to know or spell out the internal storage directory path.

```
./doc.doc.sh run crm114 train -d /path/to/docs -o /path/to/output
./doc.doc.sh run crm114 listCategories -o /path/to/output
./doc.doc.sh run crm114 learn -o /path/to/output --file /path/to/doc.txt --category spam
```

`pluginStorage` is then injected into the plugin's JSON input as `<output_dir>/.doc.doc.md/<pluginname>/`, created if it does not yet exist — identical to the behaviour in `plugin_execution.sh`.

**Business Value:**
- Users work in terms they already know (`-d`, `-o`) rather than internal directory conventions
- Consistent UX across `process` and `run` commands
- Removes a footgun: users cannot accidentally point `--plugin-storage` at the wrong directory

## Acceptance Criteria

### -d / -o flag support
- [x] `./doc.doc.sh run <plugin> <command> -d <input-dir>` sets the input directory; passed as `inputDirectory` in the JSON input if the command declares it, otherwise ignored
- [x] `./doc.doc.sh run <plugin> <command> -o <output-dir>` sets the output directory and causes `pluginStorage` to be derived and injected automatically
- [x] `pluginStorage` is derived as `<canonical_output_dir>/.doc.doc.md/<pluginname>/` — identical to the FEATURE_0041 convention
- [x] The `pluginStorage` directory is created (`mkdir -p`) before the plugin script is invoked if it does not yet exist
- [x] `--plugin-storage <dir>` continues to work as an explicit override when `-o` is not provided
- [x] If both `-o` and `--plugin-storage` are provided, `-o`-derived storage takes precedence and a warning is emitted to stderr

### Path validation and security
- [x] `<output-dir>` is canonicalized via `readlink -f` before constructing the `pluginStorage` path (REQ_SEC_005)
- [x] The derived `pluginStorage` path is validated to be under the canonical output directory (no traversal)
- [x] `<input-dir>` is validated to exist and be readable if provided

### Behaviour when -o is omitted
- [x] If neither `-o` nor `--plugin-storage` is provided and the invoked command's `descriptor.json` declares a `pluginStorage` input field as required, an error is shown and exit code 1 is returned
- [x] If the command does not declare `pluginStorage`, the field is omitted from the JSON input silently

### Help text
- [x] `./doc.doc.sh run --help` and `./doc.doc.sh run <plugin> --help` document `-d` and `-o` options
- [x] `./doc.doc.sh run <plugin> <command> --help` notes that `-o` derives `pluginStorage` automatically

### Tests
- [x] `tests/test_feature_0044.sh` verifies that `-o` correctly derives and injects `pluginStorage`
- [x] Test verifies that the `.doc.doc.md/<pluginname>/` directory is created under the output dir
- [x] Test verifies that `--plugin-storage` still works as a manual override
- [x] Test verifies error when neither `-o` nor `--plugin-storage` are provided for a command requiring `pluginStorage`
- [x] All existing tests continue to pass

## Scope

### In Scope
- `-d` and `-o` flag handling in the `run` command argument parser
- `pluginStorage` derivation and directory creation logic (reuse or extract from `plugin_execution.sh`)
- Updated help text in `ui_usage_run` and `ui_usage_run_plugin`
- TDD test suite `tests/test_feature_0044.sh`

### Out of Scope
- Changes to individual plugin scripts
- Changes to the `process` command pipeline
- Changing the `pluginStorage` path convention (stays `<output_dir>/.doc.doc.md/<pluginname>/`)

## Technical Requirements

- Reuse or extract the `pluginStorage` path resolution logic from `plugin_execution.sh` into a shared helper to avoid duplication
- Use `readlink -f` for output directory canonicalization consistent with `_PROC_CANONICAL_OUT` in `doc.doc.sh`
- Validate that the derived path sits under the canonical output directory before creating it
- Use `log_error` for all error output (colored output consistency)

## Dependencies

### Blocking Items
- **FEATURE_0043** (Plugin Command Runner) — this feature extends the `run` command implemented there

### Related Work Items
- **BUG_0014** — `--help` at `run <plugin> <command>` level should be fixed in FEATURE_0043 before or alongside this feature

## Related Links

### Related Work Items
- [FEATURE_0043: Plugin Command Runner](FEATURE_0043_plugin-command-runner.md)
- [FEATURE_0042: CRM114 Model Management Commands](FEATURE_0042_crm114-model-management-commands.md)
- [BUG_0014: run --help treated as unknown option](BUG_0014_run-command-help-flag-treated-as-unknown-option.md)

### Requirements
- [REQ_0029: Plugin State Storage](../../../02_project_vision/02_requirements/03_accepted/REQ_0029_plugin-state-storage.md)
- [REQ_SEC_005: Path Traversal Prevention](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md)

### Prior Art
- [FEATURE_0041: Plugin Storage Plumbing](../06_done/FEATURE_0041_plugin-storage-plumbing.md)
