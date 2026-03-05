# Security Review: FEATURE_0019 — Process Output Directory

- **ID:** SECREV_008
- **Created at:** 2026-03-10
- **Created by:** security.agent
- **Work Item:** [FEATURE_0019](../../03_plan/02_planning_board/06_done/FEATURE_0019_process_output_directory.md)
- **Status:** Issues Found

## TOC

1. [Reviewed Scope](#reviewed-scope)
2. [Security Concept Reference](#security-concept-reference)
3. [Assessment Methodology](#assessment-methodology)
4. [Findings](#findings)
5. [Threat Model](#threat-model)
6. [Recommendations](#recommendations)
7. [Conclusion](#conclusion)

## Reviewed Scope

| File / Function | Change | Purpose |
|-----------------|--------|---------|
| `doc.doc.sh` — process argument parser | Extended | Added `-o`/`--output-directory` (required) and `-t`/`--template` (optional) argument handling |
| `doc.doc.sh` — process main block (lines 1083–1227) | Extended | Canonicalizes output directory; constructs and boundary-checks sidecar paths; writes sidecar `.md` files |
| `doc.doc.sh` — `render_template_json()` (lines 882–906) | New | Replaces `{{key}}` placeholders in a template file with values from the merged JSON result |

## Security Concept Reference

- [Security Concept — Scope 4: Template Processing](../../02_project_vision/04_security_concept/01_security_concept.md)
- [Security Concept — Scope 5: File System Operations](../../02_project_vision/04_security_concept/01_security_concept.md)
- [REQ_SEC_004: Template Injection Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_004_template_injection_prevention.md)
- [REQ_SEC_005: Path Traversal Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md)
- [REQ_SEC_006: Error Information Disclosure Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_006_error_information_disclosure_prevention.md)
- Security Controls: SC-001, SC-005

## Assessment Methodology

1. **Static analysis**: Full review of the output directory processing block and `render_template_json()`.
2. **Path traversal analysis**: Traced all paths from user-supplied `-o` / `-t` arguments and from `$file_path` through canonicalization and boundary checks to the final `> "$sidecar_path"` write.
3. **Template injection analysis**: Traced plugin output values through `render_template_json()` substitution logic, evaluating multiline injection and nested substitution risks.
4. **REQ_SEC_004 compliance check**: Validated that the substitution mechanism is safe from code execution and that the implementation aligns with the "no nested substitution" and "no user-controlled variable names" rules.
5. **Boundary check correctness analysis**: Verified the correctness of the `[[ "$canonical_sidecar" != "${canonical_out}"* ]]` prefix test.

## Findings

| # | Severity | Location | Description | Evidence | Remediation | Bug |
|---|----------|----------|-------------|----------|-------------|-----|
| 1 | MEDIUM | `doc.doc.sh:1221` | **Boundary check uses bare string prefix, not directory prefix.** The check `[[ "$canonical_sidecar" != "${canonical_out}"* ]]` uses bash glob `*` to test for the string prefix `canonical_out`. A canonical sidecar path that STARTS WITH the same characters as `canonical_out` but is NOT a subdirectory (e.g., `canonical_out=/out`, `canonical_sidecar=/out_evil`) would PASS the check. REQ_SEC_005 specifies using `"$base_canonical/"*` — with a trailing slash — to enforce a true directory-boundary check. | If `canonical_out=/tmp/output`, a path `/tmp/output_evil/x` incorrectly satisfies `[[ "/tmp/output_evil/x" != "/tmp/output"* ]]` as false (matches), bypassing the boundary rejection. | Change the check to: `if [[ "$canonical_sidecar" != "${canonical_out}" && "$canonical_sidecar" != "${canonical_out}/"* ]]; then` — this enforces the exact directory boundary as specified in REQ_SEC_005. | [BUG_0008](../../03_plan/02_planning_board/04_backlog/BUG_0008_process_output_boundary_check_prefix_flaw.md) |
| 2 | MEDIUM | `doc.doc.sh:889–894` | **`render_template_json` processes multiline JSON values line-by-line, allowing embedded newlines in plugin output to inject fake `key=value` pairs into the substitution loop.** `jq -r 'to_entries[] \| "\(.key)=\(.value)"'` emits raw newlines for JSON string values containing `\n`. The `while IFS= read -r line` loop processes each line independently; continuation lines of a multiline value are parsed as if they were new `key=value` entries. A line of the form `fieldName=value` in document content (e.g., `documentText`) would be interpreted as: substitute `{{fieldName}}` with `value` — allowing document content to override the values of template placeholders. This violates REQ_SEC_004 rules "No Nested Substitution" and "No user-controlled variable names." | A document whose first line is `filePath=/evil/override` produces jq output with a second parsing line `filePath=/evil/override`. The loop would then substitute `{{filePath}}` in the template with `/evil/override` instead of the actual file path. | Fix the multiline handling per the remediation already described in [DEBTR_003](../../03_plan/02_planning_board/04_backlog/DEBTR_003_render_template_json_multiline_values.md): iterate over keys with `jq -r 'keys[]'` and extract each value with a separate `jq -r --arg k "$key" '.[$k] // empty'` call. This also resolves DEBTR_003's truncation defect. | [BUG_0009](../../03_plan/02_planning_board/04_backlog/BUG_0009_render_template_json_multiline_injection.md) |

### Positive Security Observations

| # | Area | Observation |
|---|------|-------------|
| P1 | **Output directory canonicalization** | `readlink -f "$output_dir"` canonicalizes the output directory before sidecar paths are constructed. Symlinks, `..`, and double slashes in the user-supplied path are fully resolved. |
| P2 | **Sidecar directory canonicalization** | `readlink -f "$sidecar_dir"` resolves the constructed sidecar directory before the boundary check, ensuring the check operates on real filesystem paths. |
| P3 | **`mkdir -p` before `readlink -f`** | The sidecar directory is created before canonicalization, ensuring `readlink -f` can resolve it even if it is newly created. |
| P4 | **No code execution via template substitution** | `render_template_json` uses bash parameter expansion `${content//pattern/replacement}` — not `eval`, `exec`, `sed -e`, or any other mechanism that would execute content. Replacement values are treated as literal strings, preventing arbitrary code execution even if file content contains shell metacharacters (`$`, `` ` ``, `&`, `\`). |
| P5 | **`find -type f` does not follow symlinks** | `find "$input_dir" -type f` reports only regular files (not symlinks). This prevents symlinked directories or files from producing unexpected `file_path` values with `..` traversal. |
| P6 | **Relative path stripping is safe in normal use** | `relative_path="${file_path#${input_dir}/}"` strips the input directory prefix. Since `find -type f` returns paths rooted at `$input_dir` without `..` components, `relative_path` will be a clean relative path in all normal cases. |
| P7 | **Template file existence check** | `[ ! -f "$template_file" ]` ensures the template is a regular file before processing. Non-existent or non-file paths are rejected cleanly. |

## Threat Model

### Threat Context

FEATURE_0019 introduces two new data flows that intersect with security boundaries:

1. **Sidecar path construction**: User-supplied output directory → canonicalized base → concatenated with file-derived relative path → written to disk. The boundary check must correctly prevent writes outside the output directory.
2. **Template substitution**: Plugin JSON output values (including document content from markitdown/ocrmypdf) → substituted into a user-supplied template file → written to sidecar files. Untrusted document content must not control which template variables are substituted.

### Threat Scenarios

| Threat | Attack Vector | Finding | Status |
|--------|--------------|---------|--------|
| **Write outside output dir** | Craft input directory to produce `relative_path` with traversal (limited by `find -type f`) or create output dir at a name where sibling directory passes prefix check | Finding 1 | **Open** — BUG_0008 filed |
| **Template value injection** | Craft document content with lines matching `key=value` format to override template placeholder values | Finding 2 | **Open** — BUG_0009 filed |
| **Code execution via template** | Embed shell metacharacters in document content or file path | Mitigated | **Closed** — bash expansion is literal |
| **Output directory path traversal** | Pass `../../` in `-o` argument | Mitigated | **Closed** — `readlink -f` canonicalization + `mkdir -p` |

### Residual Risks

| Risk | Severity | Status |
|------|----------|--------|
| Boundary check prefix flaw enables sidecar escape under specific conditions | MEDIUM | **Open** — BUG_0008 filed |
| Multiline document content can inject fake key=value pairs in template rendering | MEDIUM | **Open** — BUG_0009 filed |
| Template file can be any user-accessible file (read into sidecar output) | LOW | **Accepted** — intended CLI behavior; user controls both the template and the output |

## Recommendations

### Immediate (before FEATURE_0019 considered fully secure)

1. **Fix BUG_0008**: Correct the boundary check at line 1221 to use a directory-aware prefix test:
   ```bash
   if [[ "$canonical_sidecar" != "${canonical_out}" && "$canonical_sidecar" != "${canonical_out}/"* ]]; then
   ```
   This aligns with the pattern specified in REQ_SEC_005 and prevents false-positive matches for directories whose names share a string prefix with `canonical_out`.

2. **Fix BUG_0009 / DEBTR_003**: Replace the line-by-line `while read` parsing in `render_template_json()` with per-key extraction using `jq -r 'keys[]'` + `jq -r --arg k "$key" '.[$k] // empty'`. This eliminates the multiline injection vector and simultaneously resolves the known truncation defect (DEBTR_003). The bash `${content//.../.}` substitution mechanism itself is safe; only the value extraction needs to change.

## Conclusion

**Overall Assessment: Issues Found**

FEATURE_0019 introduces sound security architecture: `readlink -f` canonicalization of both the output directory and sidecar directory, `mkdir -p` before canonicalization, and bash parameter expansion for template substitution (preventing code execution). The overall design correctly mitigates path traversal and command injection.

Two medium-severity implementation gaps were identified:

1. **MEDIUM: Boundary check prefix flaw** — `"${canonical_out}"*` matches paths whose names merely share a string prefix with `canonical_out`, not only its subdirectories. Under the current `find -type f` code path this is not directly exploitable, but it violates REQ_SEC_005's specification and leaves a latent escape vector.

2. **MEDIUM: Template injection via multiline values** — `render_template_json()` parses `jq -r` output line-by-line, allowing embedded newlines in document content to inject fake `key=value` substitution entries. This violates REQ_SEC_004's "No Nested Substitution" and "No user-controlled variable names" rules. The functional manifestation is already tracked as DEBTR_003; this finding escalates it from technical debt to a security bug.

**Bug work items BUG_0008 and BUG_0009 have been created in the backlog** and assigned to developer.agent for remediation.

---

**Document Control:**
- **Created:** 2026-03-10
- **Author:** security.agent
- **Status:** Complete
- **Next Review:** After BUG_0008 and BUG_0009 remediation
