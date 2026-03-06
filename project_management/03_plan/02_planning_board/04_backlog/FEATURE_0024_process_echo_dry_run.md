# Feature: Process --echo Dry-Run Output Mode

- **ID:** FEATURE_0024
- **Priority:** Medium
- **Type:** Feature
- **Created at:** 2026-03-06
- **Created by:** Product Owner
- **Status:** BACKLOG

## Overview
Add an `--echo` flag to the `process` command so users can perform a dry-run: instead of writing output markdown files to disk via `-o <outputPath>`, the rendered content is printed to stdout. This enables previewing output, piping to other tools, and verifying processing without side effects.

## Acceptance Criteria
- [ ] `./doc.doc.sh process -d <inputPath> --echo` prints rendered markdown to stdout for each processed file
- [ ] `--echo` and `-o` are mutually exclusive; the command exits with an error if both are provided
- [ ] When `--echo` is used without `-o`, no files are written to disk
- [ ] Each file's output is separated by a clear delimiter (e.g., `=== <filePath> ===`) so multiple files are distinguishable in stdout
- [ ] All existing `process` flags (`--template`, `--include`, `--exclude`) work as expected in combination with `--echo`
- [ ] Help text / usage output documents the `--echo` flag
- [ ] Existing tests continue to pass (backward compatibility preserved per REQ_0038)
- [ ] New tests cover `--echo` behaviour for single-file and multi-file input

## Dependencies
- REQ_0009 (Process Command) — extends the process command parameter set
- REQ_0038 (Backward-Compatible CLI) — must not break existing `-o` usage
- FEATURE_0019 (process output directory) — baseline implementation being extended

## Related Links
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0009_process-command.md`
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0038_backward-compatible-cli.md`
- Baseline feature: `project_management/03_plan/02_planning_board/06_done/FEATURE_0019_process_output_directory.md`
