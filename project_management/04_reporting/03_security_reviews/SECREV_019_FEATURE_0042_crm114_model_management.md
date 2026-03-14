# Security Review: FEATURE_0042 CRM114 Model Management Commands

- **ID:** SECREV_019
- **Created at:** 2026-03-14
- **Created by:** security.agent
- **Work Item:** [FEATURE_0042: CRM114 Model Management Commands](../../03_plan/02_planning_board/06_done/FEATURE_0042_crm114-model-management-commands.md)
- **Status:** Approved

## Table of Contents
1. [Reviewed Scope](#reviewed-scope)
2. [Security Concept Reference](#security-concept-reference)
3. [Assessment Methodology](#assessment-methodology)
4. [Findings](#findings)
5. [Conclusion](#conclusion)

## Reviewed Scope

| File | Changes | Security Relevance |
|------|---------|-------------------|
| `doc.doc.md/plugins/crm114/learn.sh` (new) | JSON stdin input; category name sanitization; pluginStorage + filePath validation; csslearn invocation | High — input validation, path traversal, command execution |
| `doc.doc.md/plugins/crm114/unlearn.sh` (new) | JSON stdin input; category name sanitization; pluginStorage + filePath validation; cssunlearn invocation | High — input validation, path traversal, command execution |
| `doc.doc.md/plugins/crm114/listCategories.sh` (new) | JSON stdin input; pluginStorage validation; reads .css filenames | Medium — pluginStorage path validation, directory listing |
| `doc.doc.md/plugins/crm114/train.sh` (new) | Positional args; pluginStorage + input_dir validation; interactive csslearn/cssunlearn invocation; doc.doc.sh subprocess | High — argument validation, path traversal, subprocess invocation |
| `doc.doc.md/plugins/crm114/descriptor.json` (updated) | Adds four new command entries | Low — JSON schema only |
| `tests/test_feature_0042.sh` (new) | Tests including security validation tests | None — test code |

## Security Concept Reference

| Requirement | Relevance |
|-------------|-----------|
| REQ_SEC_001 (Input Validation and Sanitization) | All JSON input fields validated before use; category names regex-validated |
| REQ_SEC_005 (Path Traversal Prevention) | pluginStorage resolved via `readlink -f`; category name restricted to safe charset; CSS file path verified under canonical pluginStorage |
| REQ_SEC_009 (JSON Input Validation) | stdin limited to 1MB via plugin_input.sh; `jq` used for JSON parsing |

## Assessment Methodology

1. **Category name injection analysis** — learn.sh, unlearn.sh, and listCategories.sh all validate the `category` field against the regex `^[a-zA-Z0-9._-]+$` before constructing the .css file path. This eliminates:
   - Path traversal: `../` patterns are rejected (no `.` sequences and no `/`)
   - Shell metacharacter injection: `;`, `|`, `&`, `$`, `` ` ``, `>`, `<`, space are all rejected
   - The constructed path `$CANONICAL_STORAGE/$CATEGORY.css` is safe because CANONICAL_STORAGE is canonicalized and CATEGORY contains only safe characters
   
2. **pluginStorage path validation** — All four scripts validate `pluginStorage` via `readlink -f` before any file I/O. Non-existent or unresolvable paths are rejected. This prevents:
   - Symlink-based path traversal attacks
   - Access to arbitrary filesystem locations
   
3. **CSS file path boundary check** — In learn.sh and unlearn.sh, after constructing `$CANONICAL_STORAGE/$CATEGORY.css`, the parent directory of the constructed path is verified to equal `$CANONICAL_STORAGE`:
   ```bash
   CSS_DIR=$(readlink -f "$(dirname "$CSS_FILE")" 2>/dev/null) || CSS_DIR=""
   if [ -z "$CSS_DIR" ] || [ "$CSS_DIR" != "$CANONICAL_STORAGE" ]; then
     exit 1
   fi
   ```
   This provides defense-in-depth against any edge case where a category name could escape the directory boundary.

4. **filePath validation** — learn.sh and unlearn.sh use `plugin_validate_filepath` from `plugin_input.sh`, which:
   - Requires the file to exist and be readable
   - Rejects access to restricted system directories (`/proc`, `/dev`, `/sys`, `/etc`)
   - Canonicalizes the path via `readlink -f`
   
5. **stdin size limit** — All JSON-reading scripts use `plugin_read_input` which limits stdin to 1MB (REQ_SEC_009). File content passed to csslearn/cssunlearn is separately limited to 1MB via `head -c 1048576`.

6. **Command injection in CRM114 invocations** — learn.sh and unlearn.sh invoke:
   ```bash
   echo "$file_text" | csslearn "$CSS_FILE"
   ```
   `$CSS_FILE` is constructed from validated path components (no special characters possible). `$file_text` is piped via stdin to csslearn, not interpolated in a shell command. No command injection is possible.

7. **train.sh argument validation** — train.sh validates both positional arguments (pluginStorage, input_dir) via `readlink -f` before any directory operations. Interactive category name input is validated with the same `sanitize_category` function using the same regex as learn/unlearn.

8. **train.sh subprocess invocation** — `doc.doc.sh process` is invoked via:
   ```bash
   bash "$DOC_DOC_SH" process -d "$(dirname "$file_path")" -i "$(basename "$file_path")" --echo --no-progress
   ```
   `DOC_DOC_SH` is resolved from the known plugin directory path. File path arguments are bash-quoted. No user-controlled data is interpolated into the command string without quoting.

9. **Error message review** — Error messages in all new scripts write to stderr only. No raw user input (category names, file paths) is echoed back in output that goes to stdout. JSON error output uses `jq -n` with `--arg` to safely encode values.

## Findings

| # | Severity | Description | Status |
|---|----------|-------------|--------|
| — | — | No security vulnerabilities found | — |

### Positive Observations

| # | Observation |
|---|------------|
| 1 | **Strict category name regex** — `^[a-zA-Z0-9._-]+$` comprehensively blocks all shell metacharacters, path traversal, and whitespace. 10 invalid patterns tested and rejected. |
| 2 | **Defense-in-depth CSS path check** — Verifying `dirname(CSS_FILE) == CANONICAL_STORAGE` after construction provides a second layer of protection even if the regex were somehow bypassed. |
| 3 | **Consistent use of plugin_input.sh** — Reusing the shared input helper ensures stdin size limits and path validation logic are applied consistently across all new commands. |
| 4 | **No temporary files** — Text content piped directly to CRM114 tools via stdin eliminates temporary file security risks (TOCTOU, sensitive data on disk). |
| 5 | **Graceful failure on missing models** — unlearn.sh returns JSON error output and exits 1 cleanly when the .css model file does not exist, rather than creating it or failing with an uncaught error. |

## Conclusion

**Status: Approved** — All four new commands implement input validation, path traversal prevention, and safe command invocation consistent with the project's security requirements. No vulnerabilities were identified. The implementation adheres to REQ_SEC_001, REQ_SEC_005, and REQ_SEC_009.
