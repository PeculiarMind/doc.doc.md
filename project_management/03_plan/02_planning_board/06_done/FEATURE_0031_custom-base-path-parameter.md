# Feature: Custom Base Path Parameter

- **ID:** FEATURE_0031
- **Priority:** Medium
- **Type:** Feature
- **Created at:** 2026-03-07
- **Created by:** Product Owner
- **Status:** BACKLOG

## Overview
Add a `--base-path` / `-b` parameter to the `process` command. This parameter specifies the root directory used to compute relative references to source documents in the generated markdown output. It is distinct from the input and output directories and is intended to bridge the gap between where files physically reside during processing and how they are referenced when the output is consumed (e.g., within an Obsidian vault using symlinks).

## Motivation
A typical home-lab setup uses symlinks so that an Obsidian vault can reference both source documents and generated markdown files via consistent relative paths:

```
/home/user/documentstore/           ← input directory
/home/user/doc.doc.out/             ← output directory
/home/user/obsidianvault/attachments  → symlink to documentstore
/home/user/obsidianvault/documents    → symlink to doc.doc.out
```

Without `--base-path`, generated markdown links to source files use the raw input directory path, which does not match the Obsidian vault's relative path (`../attachments/...`). Setting `--base-path ../attachments` fixes the references without changing where files are read from or written to.

## Implementation Notes (from architecture review)

- `--base-path` / `-b` is parsed in `doc.doc.sh`'s `process` argument-parsing block alongside `--input-directory`, `--output-directory`, etc.
- The base-path value is applied **only at template rendering time**. `combined_result.filePath` is **never mutated** — a render-time copy (`render_json`) is created with the base-path-relative link and passed to `render_template_json`. The original `combined_result` (including its real filesystem path) is passed to the JSON stdout stream unchanged. The rewrite only occurs when `--base-path` is explicitly supplied.
- The relative path is computed as: `python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$file" "$base_path_resolved"` (no new dependency).
- Relative `--base-path` values are resolved from **CWD at invocation time**, not from the input or output directory.
- Validation: `readlink -f` to resolve, then `[ -d ]` check before processing begins. Note that `readlink -f` canonicalises symlinks — document this for users with symlinked base paths.
- The `process()` function in `doc.doc.sh` is the authoritative entry point; there is no `cmd_process` function.

## Acceptance Criteria
- [ ] A new `--base-path` (`-b`) option is accepted by `doc.doc.sh process`
- [ ] `--base-path` is listed and documented in `doc.doc.sh process --help` output
- [ ] When `--base-path` is omitted, processing behaviour is identical to today — `{{filePath}}` uses the input directory as root (REQ_0038, no regression)
- [ ] When `--base-path` is supplied, the `{{filePath}}` value in generated markdown files equals `<resolved-base-path>/<file-subpath-relative-to-input-dir>`
- [ ] The JSON output stream (stdout) continues to contain the real filesystem path in `filePath` — `--base-path` only affects `{{filePath}}` in the rendered sidecar `.md` file
- [ ] Relative `--base-path` values are resolved from CWD at invocation time
- [ ] Both absolute and relative base path values are accepted
- [ ] A `--base-path` value that does not exist on the filesystem produces a clear validation error before any processing begins
- [ ] `--base-path` does not affect which files are read, where output files are written, or any filesystem access — it is a link-construction parameter only
- [ ] Existing tests pass without modification
- [ ] At least one test (`tests/test_feature_0031.sh` or equivalent) validates the `{{filePath}}` rewriting behaviour

## Dependencies
- REQ_0041 (Custom Base Path Parameter)
- REQ_0009 (Process Command)
- REQ_0038 (Backward-Compatible CLI)

## Related Links
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0041_custom-base-path-parameter.md`
- Architecture Concept: `project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_0009_base_path_parameter.md`
