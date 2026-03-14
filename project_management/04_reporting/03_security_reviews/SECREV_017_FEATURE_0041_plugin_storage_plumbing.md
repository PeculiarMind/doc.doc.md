# Security Review: FEATURE_0041 Plugin Storage Plumbing

- **ID:** SECREV_017
- **Created at:** 2026-03-14
- **Created by:** security.agent
- **Work Item:** [FEATURE_0041: Plugin Storage Plumbing](../../03_plan/02_planning_board/05_implementing/FEATURE_0041_plugin-storage-plumbing.md)
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
| `doc.doc.md/components/plugin_execution.sh` | `run_plugin` extended with `output_dir`; `pluginStorage` injection via `jq`; `mkdir -p` for storage directory; `readlink -f` canonicalization | High — path construction, directory creation, JSON injection |
| `doc.doc.md/components/plugin_execution.sh` | `process_file` propagates `output_dir` | Medium — parameter passing in processing pipeline |
| `doc.doc.sh` | Passes `_PROC_CANONICAL_OUT` to `process_file`; `--echo` mode omits output directory | Medium — output directory propagation, echo-mode bypass |
| `tests/test_feature_0041.sh` | 14 tests including security path-containment checks | None — test code only |

## Security Concept Reference

| Requirement | Relevance |
|-------------|-----------|
| REQ_SEC_005 (Path Traversal Prevention) | Primary — `pluginStorage` path must be canonicalized and validated to remain under output directory |
| REQ_SEC_002 (Path Validation) | Verified — storage path resolved via `readlink -f`; no unvalidated path construction |
| REQ_SEC_003 (Command Injection Prevention) | Verified — no `eval`, no command substitution on user-controlled values; `jq` handles JSON injection safely |
| REQ_SEC_004 (Privilege Management) | Verified — no privilege escalation; directory creation inherits process umask |

## Assessment Methodology

1. **Path traversal analysis** — The `pluginStorage` path is constructed as `<output_dir>/.doc.doc.md/<pluginname>/` where `output_dir` is the canonical output directory (resolved via `readlink -f` in `doc.doc.sh` as `_PROC_CANONICAL_OUT`). The plugin name is derived from the plugin descriptor (controlled value, not user input). The final path is canonicalized again via `readlink -f` before injection, which resolves any `..` or `.` segments. This double canonicalization ensures no traversal is possible.
2. **Containment validation** — The resolved `pluginStorage` path is validated to start with the canonical output directory prefix. If a manipulated plugin name or symlink attack caused the path to resolve outside the output directory, the prefix check would detect and prevent it. Test cases T13 and T14 verify this containment.
3. **Directory creation safety** — `mkdir -p` is idempotent and safe. It creates directories with the process's current umask. No `chmod` or explicit permission setting is used, so no world-writable directories are introduced. If the directory already exists, `mkdir -p` is a no-op.
4. **JSON injection safety** — The `pluginStorage` field is added to the JSON object via `jq`, which properly escapes all string values. No shell interpolation occurs inside the JSON construction. Existing plugins that do not consume `pluginStorage` are unaffected — the field is simply ignored.
5. **Echo-mode isolation** — When `--echo` mode is active, no output directory is passed to `process_file`, and `pluginStorage` is omitted from the JSON input. No `.doc.doc.md/` directory is created in the input directory or the current working directory. Test cases T08–T10 verify this isolation.
6. **Attack surface assessment** — The change introduces no new external input vectors. The `pluginStorage` path is derived entirely from internal values (`_PROC_CANONICAL_OUT` and the plugin name from descriptors). Existing plugins receive the additional JSON field but are not required to use it, so no existing plugin behaviour changes.

## Findings

| # | Severity | Description | Status |
|---|----------|-------------|--------|
| — | — | No security vulnerabilities found | — |

### Positive Observations

| # | Observation |
|---|------------|
| 1 | **Path canonicalization via `readlink -f`** — Storage paths are canonicalized before injection, eliminating `..` and `.` traversal segments. This directly satisfies REQ_SEC_005 path canonicalization requirements. |
| 2 | **Containment prefix check** — The resolved storage path is validated to start with the canonical output directory. This prevents any path that resolves outside the output boundary from being passed to a plugin. |
| 3 | **No world-writable permissions** — `mkdir -p` inherits the process umask. No explicit permission changes are applied, so directories follow the system's default restrictive permissions. |
| 4 | **Existing plugins unaffected** — The `pluginStorage` field is additive. Plugins that do not read this field continue to operate identically, introducing no new attack surface. |
| 5 | **Idempotent directory creation** — `mkdir -p` does not fail on existing directories, preventing denial-of-service via pre-created directories or race conditions. |
| 6 | **Safe JSON construction via `jq`** — Using `jq` for JSON field injection avoids shell interpolation risks and ensures proper string escaping. |

## Conclusion

FEATURE_0041 is **approved**. The plugin storage plumbing implementation was reviewed for path traversal, command injection, permission escalation, and attack surface expansion. No vulnerabilities were found or introduced. Path security is ensured through `readlink -f` canonicalization and output-directory containment validation, satisfying REQ_SEC_005. Directory creation via `mkdir -p` is idempotent and inherits umask-controlled permissions. JSON injection via `jq` is safe and does not introduce shell interpolation risks. Existing plugins are unaffected by the additive `pluginStorage` field.
