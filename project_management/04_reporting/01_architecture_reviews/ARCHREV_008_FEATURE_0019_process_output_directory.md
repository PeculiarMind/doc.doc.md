# Architecture Review: FEATURE_0019 — Process Output Directory

- **ID:** ARCHREV_008
- **Created at:** 2026-03-06
- **Created by:** architect.agent
- **Work Item:** [FEATURE_0019](../../03_plan/02_planning_board/06_done/FEATURE_0019_process_output_directory.md)
- **Status:** Conditionally Compliant

## TOC

1. [Reviewed Scope](#reviewed-scope)
2. [Architecture Vision Reference](#architecture-vision-reference)
3. [Compliance Assessment](#compliance-assessment)
4. [Deviations Found](#deviations-found)
5. [Recommendations](#recommendations)
6. [Conclusion](#conclusion)

## Reviewed Scope

| File | Change | Purpose |
|------|--------|---------|
| `doc.doc.sh` — `main()` | Modified | Added `-o`/`--output-directory` (required) and `-t`/`--template` (optional) flag parsing; output directory creation; per-file sidecar path computation; boundary check; template rendering call |
| `doc.doc.sh` — `render_template_json()` | New | Renders a markdown template by substituting `{{key}}` placeholders with values from a JSON result object |
| `doc.doc.sh` — `usage()` | Modified | Documents `-o` and `-t` flags, updated examples |
| `doc.doc.md/templates/default.md` | New | Default markdown template with `{{fileName}}`, `{{fileSize}}`, `{{fileOwner}}`, `{{fileCreated}}`, `{{fileModified}}`, `{{fileMetadataChanged}}` placeholders |

## Architecture Vision Reference

- [ARC-0002: Template Processing Concept](../../02_project_vision/03_architecture_vision/08_concepts/ARC_0002_template_processing.md)
- [ARC-0006: Security Considerations](../../02_project_vision/03_architecture_vision/08_concepts/ARC_0006_security_considerations.md)
- [ADR-003: JSON-Based Plugin Descriptors with Shell Command Invocation](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md)
- [ADR-001: Mixed Bash/Python Implementation](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_001_mixed_bash_python_implementation.md)

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| **ARC-0002 — Template structure (`{{placeholder}}` syntax)** | ✅ Compliant | `render_template_json()` substitutes `{{key}}` placeholders using bash parameter expansion (`${content//\{\{${key}\}\}/${val}}`). The placeholder syntax matches the `{{variableName}}` pattern specified in ARC-0002. |
| **ARC-0002 — Variable sources (file system + plugins)** | ✅ Compliant | The combined JSON object passed to `render_template_json` accumulates the file path from the file system and all plugin outputs (stat, file, markitdown, etc.) via `process_file()`. Template variables are sourced from this merged result, consistent with ARC-0002's "Aggregate all data into a variable dictionary" step. |
| **ARC-0002 — Template resolution order** | ✅ Compliant | Default template is `doc.doc.md/templates/default.md`. A user-specified template via `-t`/`--template` takes precedence. This implements ARC-0002's resolution order: user-specified first, built-in fallback. |
| **ARC-0002 — Missing variables** | ✅ Compliant | Unrecognised placeholders remain in the rendered output unchanged. ARC-0002 explicitly permits "leaving placeholder" as a handling strategy for missing variables. *(Note: FEATURE_0019 acceptance criteria specified replacing unrecognised placeholders with empty strings — this is an AC deviation but not an architectural deviation. See [Deviations Found](#deviations-found).)* |
| **ARC-0006 — Output path canonicalization** | ✅ Compliant | `readlink -f "$output_dir"` is called after `mkdir -p` to resolve the canonical output directory path. The canonical path is stored in `canonical_out` and used for all subsequent boundary checks. |
| **ARC-0006 — Path traversal protection** | ✅ Compliant | Before writing each sidecar file, the canonicalized sidecar directory is compared against `canonical_out` using `[[ "$canonical_sidecar" != "${canonical_out}"* ]]`. Crafted filenames containing `..` or symlinks pointing outside the output directory are detected and rejected with a stderr error; processing continues for remaining files. |
| **ARC-0006 — Template injection prevention** | ✅ Compliant | Placeholder substitution uses bash parameter expansion, which does not evaluate the replacement string as shell code. Plugin output values are treated as literal strings. No `eval` or `$()` is applied to template content or substituted values. |
| **ARC-0006 — Required flag validation** | ✅ Compliant | `-o`/`--output-directory` is validated as required before processing begins. Missing flag, non-existent input directory, non-existent template file, and non-creatable output directory all produce clear stderr errors with exit 1, before any file processing starts. |
| **ARC-0004 — Error categorisation** | ✅ Compliant | Pre-processing errors (missing required flag, unreadable directory, missing template) cause immediate exit 1. Per-file sidecar write failures log a warning to stderr and continue processing (graceful degradation), consistent with ARC-0004's "File Processing Errors → skip file, continue" strategy. |
| **ARC-0004 — stderr for status messages** | ✅ Compliant | Progress messages (`Processed: <file> → <sidecar>`) and per-file errors are written to stderr via `>&2`. The JSON array result is written to stdout, preserving the composability of the `process` command output. |
| **Directory structure mirroring** | ✅ Compliant | The relative path of each input file is derived with `${file_path#${input_dir}/}` and appended to `canonical_out` to construct the sidecar path, preserving the full subdirectory hierarchy from the input directory. Intermediate directories are created with `mkdir -p`. |
| **Default template** | ✅ Compliant | `default.md` uses the standard `{{key}}` placeholder syntax and references variables produced by the `stat` plugin (`fileSize`, `fileOwner`, `fileCreated`, `fileModified`, `fileMetadataChanged`) and the derived `fileName` variable. Consistent with ARC-0002's standard variable table. |
| **`-t`/`--template` flag** | ✅ Compliant | The flag is parsed and the template file is validated for existence before processing begins. |

## Deviations Found

### DEV-001: `render_template_json` does not handle multiline string values correctly

**Affected file:** `doc.doc.sh` — `render_template_json()` (lines 880–907)

**Description:**
`render_template_json` extracts key-value pairs from the merged JSON result using:

```bash
while IFS= read -r line; do
  local key="${line%%=*}"
  local val="${line#*=}"
  ...
done < <(echo "$result_json" | jq -r 'to_entries[] | "\(.key)=\(.value)"')
```

When a plugin produces a string value containing embedded newlines — such as `documentText` from the `markitdown` plugin, which contains the full extracted markdown of a multi-page document — `jq -r` emits those newlines literally. The `while IFS= read -r line` loop processes one line at a time. The first line is correctly parsed as `key=first_line_of_value`, but subsequent lines of the value are treated as separate iterations where `key` is empty (filtered by `[ -n "$key" ] || continue`). The result is that only the first line of the value is substituted into the template placeholder; the remainder of the content is silently discarded.

**Impact:**
- For the current default template (`default.md`), which only uses single-line metadata values from the `stat` plugin, this defect has no observable effect.
- For any template that includes `{{documentText}}` (the markitdown plugin's primary output) or other future multiline plugin outputs, the rendered sidecar file will be silently truncated to the first line of the value. This silently produces incorrect documentation output.
- The `markitdown` plugin (FEATURE_0017) and the `ocrmypdf` plugin (`ocrText` output) both produce multiline string values, making this a near-term integration risk.

**Severity:** Medium — The defect is currently dormant but will produce silent data loss in the primary use case for which FEATURE_0017 was built, as soon as a user adds `{{documentText}}` to a custom template.

**Remediation:** Replace the line-by-line key=value parsing with a null-delimited approach or use `jq` to perform the substitution loop over each key, using bash process substitution with proper handling of embedded newlines. One safe approach: iterate over keys separately from values, or use `jq` to emit a safe single-line JSON object and apply per-key substitutions using `jq -r --arg`.

**DEBTR Record:** [DEBTR_003](../../03_plan/02_planning_board/04_backlog/DEBTR_003_render_template_json_multiline_values.md)

---

### DEV-002: Unrecognised template placeholders remain in output (AC deviation, not architectural)

**Affected file:** `doc.doc.sh` — `render_template_json()`

**Description:**
The `render_template_json` function iterates over all JSON keys in the result and substitutes matching `{{key}}` placeholders. Placeholders with no matching key in the result JSON are left unchanged in the output (e.g., `{{mimeDescription}}` remains as-is if that key is absent).

FEATURE_0019 acceptance criteria specifies: *"Unrecognised placeholders (no matching plugin output key) are replaced with an empty string."* The implementation leaves them as the literal placeholder string.

**Architectural alignment:** ARC-0002 explicitly permits *"leaving placeholder"* as a handling strategy for missing variables. The implementation is therefore aligned with the architecture concept.

**Severity:** Low — This is an AC deviation, not an architectural violation. The behaviour is predictable and visible to users who inspect the generated sidecar files.

**Recommendation:** Either update the FEATURE_0019 acceptance criteria to reflect the leave-placeholder behaviour (aligning the AC with ARC-0002), or add a cleanup pass in `render_template_json` that replaces any remaining `{{...}}` patterns with empty strings after all substitutions have been applied. No DEBTR required; a simple code change can resolve this if the replace-with-empty-string behaviour is preferred.

## Recommendations

1. **Resolve DEBTR_003 (multiline value substitution) before activating markitdown or adding `{{documentText}}` to templates**: The multiline substitution defect will produce silently truncated documentation output as soon as any template references a multiline plugin output. Resolution should be prioritised before `markitdown` is activated on a production installation.

2. **Decide on unrecognised placeholder behaviour (DEV-002)**: The current leave-placeholder behaviour is consistent with ARC-0002. A cleanup pass is a one-liner (`content="${content//\{\{*\}\}/}"`) and may produce cleaner output. Align the AC accordingly whichever direction is chosen.

3. **Relative path stripping robustness**: The input path is stripped with `${file_path#${input_dir}/}`. If `input_dir` was provided without a trailing slash and a file path exactly equals `input_dir` (edge case), the relative path would be empty. In practice this cannot happen because `find -type f` never returns a directory, but canonicalising `input_dir` with `readlink -f` before use (as is done for `output_dir`) would make this path arithmetic more robust.

## Conclusion

FEATURE_0019 is **conditionally compliant** with the architecture vision. The core requirements — output directory creation, input-to-output directory mirroring, template-rendered sidecar file generation, path canonicalization, and path traversal protection — are all correctly implemented. Security requirements from ARC-0006 are properly addressed.

One medium-severity deviation was identified: `render_template_json` uses a line-by-line parsing approach that silently truncates multiline string values, making it incompatible with plugin outputs such as `documentText` (markitdown) and `ocrText` (ocrmypdf). A DEBTR_003 work item has been created to track remediation. A second, low-severity AC deviation was found regarding unrecognised placeholder handling; this is architecturally acceptable per ARC-0002 but should be explicitly decided.

**Result: Conditionally Compliant** — pending resolution of [DEBTR_003](../../03_plan/02_planning_board/04_backlog/DEBTR_003_render_template_json_multiline_values.md).
