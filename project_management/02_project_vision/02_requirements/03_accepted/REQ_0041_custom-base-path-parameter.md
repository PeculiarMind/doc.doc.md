# Requirement: Custom Base Path Parameter

- **ID:** REQ_0041
- **State:** Accepted
- **Type:** Functional
- **Priority:** Medium
- **Created at:** 2026-03-07
- **Last Updated:** 2026-03-07

## Overview
`doc.doc.sh process` shall accept an optional `--base-path` parameter that sets the assumed root directory used to resolve references in generated markdown files.

## Description
The `--base-path` parameter is an optional addition to the `process` command. It specifies the base directory from which references (links to source documents) inside the generated markdown sidecar files are resolved. It is **not** the input directory and **not** the output directory — it is a separate path used solely for constructing correct relative links at generation time.

### Purpose
During processing time, the script, the input documents, and the output markdown files may reside in different locations on the filesystem. During management time (e.g., when browsing an Obsidian vault), the same files may be accessed through a different directory structure — typically via symlinks that group input and output under a common root.

The `--base-path` allows the user to specify the path that bridges these two perspectives, so that references embedded in generated markdown files remain valid in both contexts.

### Parameter Definition

| Long Parameter | Short Parameter | Description | Required | Default Value |
|---|---|---|---|---|
| `--base-path` | `-b` | The assumed root directory for resolving references in generated markdown files. Accepts absolute or relative paths. | false | Input directory |

### Example

```
/home/peculiarmind/documentstore/           <- input directory
/usr/local/bin/doc.doc.md/                  <- tool location
/home/peculiarmind/doc.doc.out/             <- output directory
/home/peculiarmind/obsidianvault/attachments -> symlink to documentstore
/home/peculiarmind/obsidianvault/documents  -> symlink to doc.doc.out
```

With `--base-path ../attachments`, references in the generated markdown files point to source documents relative to the output location as seen from within the Obsidian vault, ensuring links resolve correctly when the vault is opened in Obsidian.

### Behaviour
- When `--base-path` is not supplied, the default behaviour (using the input directory as reference root) is preserved.
- When `--base-path` is supplied, the framework uses this path instead of the input directory when constructing references inside generated markdown files.
- Both absolute and relative values for `--base-path` shall be accepted. Relative values are resolved against the current working directory at invocation time (not relative to the input or output directory) and then validated for existence.
- An invalid or non-existent `--base-path` value shall produce a clear validation error before processing begins.
- The `{{filePath}}` template placeholder in each generated sidecar markdown file is set to `<resolved-base-path>/<file-subpath-relative-to-input-dir>` (using the platform path separator). This produces the correct relative link regardless of whether the output is consumed directly or via a management-time directory abstraction such as Obsidian vault symlinks.
- `--base-path` is a link-construction parameter only. It does not affect which files are read from the input directory, where output files are written, or which plugins are invoked. It has no effect on actual filesystem access during processing.

## Motivation
Derived from:
[project_management/02_project_vision/01_project_goals/project_goals.md](../../01_project_goals/project_goals.md) — TODO 3: "create a feature that doc.doc.sh allows to specify a custom base path … The purpose is to clearly separate the locations of doc.doc.sh, the input directory, and the output directory during processing time from the directory structure used by the user during management time."

## Acceptance Criteria
- [ ] `doc.doc.sh process --base-path <path>` is accepted as a valid invocation without error
- [ ] `--base-path` / `-b` is listed and documented in `doc.doc.sh process --help` output
- [ ] When `--base-path` is omitted, processing behaviour is identical to pre-existing behaviour (no regression)
- [ ] The `{{filePath}}` value written into each generated sidecar markdown file is `<resolved-base-path>/<file-subpath-relative-to-input-dir>` when `--base-path` is supplied
- [ ] Both absolute and relative values for `--base-path` are accepted; relative values are resolved from the current working directory at invocation time
- [ ] Supplying a `--base-path` value that does not exist on the filesystem (after resolving relative paths from CWD) produces a validation error before any processing begins
- [ ] `--base-path` does not alter which input files are discovered, where output files are written, or which plugins are executed
- [ ] The feature is covered by at least one automated test (`tests/test_feature_0041.sh` or equivalent)
- [ ] Existing test suite passes without modification after the feature is implemented

## Related Requirements
- [REQ_0009 Process Command](REQ_0009_process-command.md)
- [REQ_0008 Obsidian Compatibility](REQ_0008_obsidian-compatibility.md)
- [REQ_0013 Directory Mirroring](REQ_0013_directory-mirroring.md)
- [REQ_0038 Backward-Compatible CLI](REQ_0038_backward-compatible-cli.md)
