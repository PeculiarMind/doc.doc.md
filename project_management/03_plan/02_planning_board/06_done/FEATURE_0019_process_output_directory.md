# Process Output Directory Option

- **ID:** FEATURE_0019
- **Priority:** High
- **Type:** Feature
- **Created at:** 2026-03-05
- **Created by:** Product Owner
- **Status:** DONE
- **Assigned to:** developer

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

Add `-o`/`--output-directory` support to the `process` command. When provided, the output directory receives a mirrored copy of the input directory structure, and a template-rendered markdown sidecar file is written for each processed file.

**Updated command signature:**
```
doc.doc.sh process -d <inputDir> -o <outputDir> [-t <template>] [-i <criteria>] [-e <criteria>]
doc.doc.sh process --input-directory <inputDir> --output-directory <outputDir> [--template <template>] [--include <criteria>] [--exclude <criteria>]
```

**Current state:** The `process` command outputs a JSON array to stdout and has no output directory concept. Directory mirroring and markdown file generation are completely unimplemented. `-o`/`--output-directory` is not parsed.

**Business value:**
- Delivers the primary user-facing output of the tool: persistent markdown sidecar files on disk
- Enables Obsidian compatibility — mirrored directory structure plus `.md` sidecars can be opened directly as an Obsidian vault
- Fulfils the core product promise: a document collection processed into a navigable markdown knowledge base without a full DMS
- Unblocks template rendering (FEATURE_0020 candidate) and downstream Obsidian-specific features
- Implements the `-o` parameter defined as **required** in REQ_0009 and the project goals

**What this delivers:**
- `-o <dir>` / `--output-directory <dir>` flag accepted by `process`
- Output directory created if it does not exist
- Subdirectory hierarchy from input mirrored exactly under output directory
- One `.md` sidecar file written per processed file, rendered from the active template (`default.md` unless `-t` is specified), with plugin output substituted into template placeholders
- Existing stdout JSON output replaced by progress/status messages to stderr; exit code signals success or failure
- Updated `usage()` / `--help` text

## Acceptance Criteria

### Flag Parsing

- [ ] `doc.doc.sh process -d <dir> -o <dir>` is accepted without error
- [ ] `doc.doc.sh process --input-directory <dir> --output-directory <dir>` is accepted without error
- [ ] Short (`-o`) and long (`--output-directory`) forms are equivalent
- [ ] `-o` and `--output-directory` can appear in any position relative to other flags
- [ ] If `-o`/`--output-directory` is omitted, print a clear error to stderr and exit 1 (the flag is required)
- [ ] If the value for `-o`/`--output-directory` is missing (flag present but no path), print a clear error to stderr and exit 1

### Output Directory Creation

- [ ] If the specified output directory does not exist, it is created (including any intermediate parent directories)
- [ ] If the output directory already exists, processing proceeds without error
- [ ] If the output directory cannot be created (e.g. permission denied), print a clear error to stderr and exit 1

### Directory Structure Mirroring

- [ ] For every file that passes the include/exclude filter, the corresponding subdirectory path is created under the output directory, mirroring the input directory hierarchy
- [ ] Relative paths are preserved: a file at `<inputDir>/a/b/file.pdf` produces a sidecar at `<outputDir>/a/b/file.pdf.md`
- [ ] Intermediate subdirectories are created as needed
- [ ] Directories that contain no files surviving the filter are not created in the output (no empty directory creation)

### Sidecar File Generation

- [ ] For each processed file, a `.md` sidecar file is written at `<outputDir>/<relative-path>/<filename>.<ext>.md`
- [ ] The sidecar file is rendered from the template: each `{{placeholder}}` is replaced with the corresponding plugin output value
- [ ] Unrecognised placeholders (no matching plugin output key) are replaced with an empty string
- [ ] If a sidecar file already exists at the target path, it is overwritten
- [ ] If the sidecar file cannot be written (e.g. permission denied), print a clear error to stderr and exit 1 and continue processing remaining files (best-effort); final exit code is 1 if any file failed

### Template Selection

- [ ] When `-t <path>` / `--template <path>` is not specified, `doc.doc.md/templates/default.md` is used
- [ ] When `-t <path>` / `--template <path>` is specified, the given template file is used
- [ ] If the specified template file does not exist, print a clear error to stderr and exit 1 before processing any files

### Output and Exit Codes

- [ ] Status and progress information is written to stderr, not stdout
- [ ] On successful completion exit code is 0
- [ ] If one or more sidecar files could not be written, exit code is 1
- [ ] If a fatal error occurs before processing begins (missing required flag, missing template, unreadable input directory), exit code is 1 and no partial output is written

### Security

- [ ] The output directory path is validated and canonicalized with `readlink -f` before use (`REQ_SEC_005`)
- [ ] The constructed sidecar file path is verified to be within the output directory before writing — no path traversal via crafted input filenames (`REQ_SEC_005`)
- [ ] Template placeholder substitution uses a safe replacement strategy; no shell evaluation of template content or plugin output values (`REQ_SEC_001`, `REQ_SEC_004`)

### CLI Help

- [ ] `doc.doc.sh --help` documents `-o`/`--output-directory` as a required option of `process`
- [ ] `doc.doc.sh process --help` lists `-o`/`--output-directory` with a description

## Scope

**In scope:**
- `-o`/`--output-directory` flag parsing and validation
- Output directory creation (including parent directories)
- Input-to-output directory structure mirroring
- Sidecar `.md` file generation using template placeholder substitution
- Default template (`default.md`) used when `-t` is not specified
- `-t`/`--template` flag parsing and template file validation (the flag must be wired up even if full template selection is considered a follow-on — validation and default fallback are required for this feature)
- Updated `usage()` help text
- Security: output path canonicalization and sidecar path boundary enforcement

**Out of scope:**
- Custom template authoring guidelines or advanced placeholder syntax (documentation scope)
- Plugin storage directory (`pluginStorage`) plumbing — that is REQ_0029 scope
- Processing files in parallel
- Incremental / watch mode (only re-process changed files)
- Dry-run mode

## Technical Requirements

### Sidecar Path Construction

```bash
relative_path="${file_path#${input_dir}/}"          # strip inputDir prefix
sidecar_path="${output_dir}/${relative_path}.md"    # append .md
sidecar_dir="$(dirname "$sidecar_path")"

# Boundary check
canonical_out="$(readlink -f "$output_dir")"
canonical_sidecar="$(readlink -f "$sidecar_dir")"
if [[ "$canonical_sidecar" != "$canonical_out"* ]]; then
  echo "Error: path traversal detected for '$file_path'" >&2
  continue
fi

mkdir -p "$sidecar_dir"
```

### Template Rendering

```bash
render_template() {
  local template="$1"
  local -n _vars="$2"   # nameref to associative array of key→value
  local content
  content="$(cat "$template")"
  for key in "${!_vars[@]}"; do
    content="${content//\{\{${key}\}\}/${_vars[$key]}}"
  done
  printf '%s' "$content"
}
```

All substitution is pure string replacement — no `eval`, no subshell with user data, no `sed -e` with unescaped values.

### Argument Parser Extension

```bash
-o|--output-directory)
  output_dir="$2"; shift 2 ;;
-t|--template)
  template_file="$2"; shift 2 ;;
```

Both `output_dir` and `template_file` validated after parsing, before any processing begins.

### Architecture Compliance

- File writes confined to `output_dir` subtree (boundary-checked)
- Plugin communication unchanged (JSON stdin/stdout)
- No new external dependencies

## Dependencies

- REQ_0009 (Process Command) — defines `-o`/`--output-directory` as a required parameter
- REQ_0013 (Directory Mirroring) — defines the mirroring contract
- REQ_0007 (Markdown Output Format) — defines `.md` output requirement
- REQ_SEC_001 (Input Validation & Sanitization)
- REQ_SEC_004 (Template Injection Prevention)
- REQ_SEC_005 (Path Traversal Prevention)
- FEATURE_0001 (Walking Skeleton CLI and Plugin Execution, DONE) — established plugin JSON chain this feature writes output from
- FEATURE_0007 (File Plugin First in Chain and MIME Filter Gate, DONE) — `mimeType` is available in plugin output at write time

## Related Links

- Project Goals: [project_goals.md](../../../02_project_vision/01_project_goals/project_goals.md)
- Requirements: [REQ_0009](../../../02_project_vision/02_requirements/03_accepted/REQ_0009_process-command.md), [REQ_0013](../../../02_project_vision/02_requirements/03_accepted/REQ_0013_directory-mirroring.md), [REQ_0007](../../../02_project_vision/02_requirements/03_accepted/REQ_0007_markdown-output.md)
- Architecture: [05_building_block_view.md](../../../../project_documentation/01_architecture/05_building_block_view/05_building_block_view.md)
- Template: [default.md](../../../../doc.doc.md/templates/default.md)

## Workflow Assessment Log

### Step 5: Tester Assessment
- **Date:** 2026-03-05
- **Agent:** tester.agent
- **Result:** PASS
- **Report:** [TESTREP_006](../../../04_reporting/02_tests_reports/TESTREP_006_FEATURE_0019_process_output_directory.md)
- **Summary:** All 19 tests pass. `-o`/`--output-directory` flag parsing, output directory creation, directory mirroring, sidecar `.md` file generation, template substitution, custom template support, invalid template rejection, and stderr progress reporting all verified.

### Step 6: Architect Assessment
- **Date:** 2026-03-05
- **Agent:** architect.agent
- **Result:** Conditionally Compliant
- **Report:** [ARCHREV_008](../../../04_reporting/01_architecture_reviews/ARCHREV_008_FEATURE_0019_process_output_directory.md)
- **Summary:** Compliant with ARC-0002 (template syntax, variable sources, resolution order), ARC-0006 (output path canonicalization, path traversal protection, required flag validation), and ARC-0004 (error categorisation). One medium-severity deviation: `render_template_json` truncates multiline string values (e.g., `documentText`). DEBTR_003 created to track remediation before activating markitdown with templates.

### Step 7: Security Assessment
- **Date:** 2026-03-05
- **Agent:** security.agent
- **Result:** Issues Found
- **Report:** [SECREV_008](../../../04_reporting/03_security_reviews/SECREV_008_FEATURE_0019_process_output_directory.md)
- **Summary:** Two medium-severity issues found: (1) boundary check uses bare string prefix instead of directory-aware prefix, allowing sibling-directory paths to bypass the sidecar escape check — BUG_0008 filed; (2) `render_template_json` processes multiline JSON values line-by-line, allowing embedded newlines in plugin output to inject fake `key=value` pairs and override template placeholder values — BUG_0009 filed (also resolves DEBTR_003).

### Step 8: License Assessment
- **Date:** 2026-03-05
- **Agent:** license.agent
- **Result:** PASS
- **Summary:** Pure Bash implementation with no new dependencies and no third-party code. Template rendering uses only standard Bash parameter expansion. No CREDITS.md update required. Full compatibility with project AGPL-3.0 license maintained.

### Step 9: Documentation Assessment
- **Date:** 2026-03-05
- **Agent:** documentation.agent
- **Result:** PASS
- **Summary:** README.md already correctly documents `-o`/`--output-directory` as a required flag in the Process Command options table, with full usage examples. No additional changes required for this item.
