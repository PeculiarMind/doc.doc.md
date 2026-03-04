# Security Review: BUG_0003 — Filter Engine MIME Type Criterion Support

- **ID:** SECREV_003
- **Created at:** 2026-03-04
- **Created by:** security.agent
- **Work Item:** [BUG_0003](../../03_plan/02_planning_board/05_implementing/BUG_0003_filter_mime_type_not_implemented.md)
- **Status:** No Issues Found

## TOC

1. [Reviewed Scope](#reviewed-scope)
2. [Security Concept Reference](#security-concept-reference)
3. [Assessment Methodology](#assessment-methodology)
4. [Findings](#findings)
5. [Threat Model](#threat-model)
6. [Recommendations](#recommendations)
7. [Conclusion](#conclusion)

## Reviewed Scope

| File | Change | Purpose |
|------|--------|---------|
| `doc.doc.md/components/filter.py` | Modified | Added `_get_mime_type()` helper and MIME branch in `matches_criterion()` |

## Security Concept Reference

- [REQ_SEC_001: Input Validation and Sanitization](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_001_input_validation_sanitization.md)
- [REQ_SEC_002: Filter Logic Correctness](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_002_filter_logic_correctness.md)
- [REQ_SEC_005: Path Traversal Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md)
- [REQ_SEC_006: Error Information Disclosure Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_006_error_information_disclosure_prevention.md)

## Assessment Methodology

Manual code review of the modified `filter.py` focused on:

1. **Command injection** — `subprocess.run()` usage and argument construction
2. **Path traversal** — file path passed to `file` command
3. **Information disclosure** — error messages written to stderr
4. **Input validation** — handling of malformed or adversarial criterion strings

## Findings

### Finding 1: subprocess.run() uses a list — no shell injection risk

`_get_mime_type()` invokes:

```python
subprocess.run(
    [_FILE_CMD, '--mime-type', '-b', file_path],
    capture_output=True,
    text=True,
)
```

Using a list of arguments (not a shell string) with `subprocess.run()` means the
`file_path` value is passed as a literal argument to the OS `execve()` call.
No shell interpolation occurs, so **shell injection via a crafted file path is
not possible**.

**Verdict: No vulnerability.**

### Finding 2: Path traversal — consistent with existing behaviour

`file_path` is passed directly to the `file` command. Path traversal would
require an adversary to supply a crafted path (e.g., `../../etc/passwd`).

This exposure is **pre-existing and unchanged** — the `file` plugin
(`doc.doc.md/plugins/file/main.sh`) already calls `file --mime-type -b "$filePath"`
with the same trust model. All file paths originate from `find "$input_dir" -type f`
in `doc.doc.sh`, which constrains the search to the user-specified input directory.
Path traversal protection from the input directory is a `doc.doc.sh`-level concern
(addressed by BUG_0001, now in `06_done`) and is orthogonal to this fix.

**Verdict: Pre-existing, not introduced by this change. No new risk.**

### Finding 3: Error messages — no sensitive information disclosure

`_get_mime_type()` writes two types of error messages to stderr:

1. `"error: 'file' command not found — required for MIME type filtering"` —
   discloses no sensitive data; communicates dependency absence.
2. `f"warning: could not determine MIME type for '{file_path}': {result.stderr.strip()}"` —
   includes the file path and the raw stderr from the `file` command.

The `file` command stderr typically contains generic error descriptions (e.g.,
"No such file or directory"). This mirrors the behaviour of the existing `file`
plugin and `stat` plugin which also write file paths to stderr in error conditions.
No secrets, credentials, or system internals are exposed.

**Verdict: Acceptable. Consistent with existing error handling patterns.**

### Finding 4: MIME criterion string — no injection via criterion

The `criterion` argument to `matches_criterion()` comes from user-supplied
`--include`/`--exclude` CLI arguments. It is used only as the second argument
to `fnmatch.fnmatch()` and never passed to `subprocess.run()` or any shell.
`fnmatch` patterns are purely in-process string matching; a crafted criterion
cannot escape to the shell or OS.

**Verdict: No vulnerability.**

### Finding 5: `os.path.isfile()` on user-supplied path

`os.path.isfile(file_path)` is called before invoking `_get_mime_type()`.
This is a read-only filesystem metadata check and does not open or read the
file. It is not a TOCTOU (time-of-check / time-of-use) concern in this context
because the subsequent `file` command call would fail gracefully if the file
were removed between the two calls (returning empty string, treated as non-match).

**Verdict: No vulnerability.**

## Threat Model

| Threat | Vector | Mitigation | Residual Risk |
|--------|--------|-----------|---------------|
| Shell injection via file path | Crafted path as `--include`/`--exclude` value | `subprocess.run()` with list args; no `shell=True` | None |
| Path traversal outside input dir | Crafted file path in directory being processed | File paths originate from `find -type f` scoped to input dir (BUG_0001 fix) | Low (pre-existing, unchanged) |
| Information disclosure via stderr | `file` command error output leaked to stderr | Error written to stderr, not stdout; no secrets in messages | Low (acceptable) |
| Denial of service via crafted criterion | Very long or complex `fnmatch` pattern | Python `fnmatch` is not backtracking-susceptible for typical MIME patterns | Low |

## Recommendations

1. **No blocking security issues identified** — the fix may be merged as-is.
2. (Future) Consider limiting the maximum length of criterion strings to prevent
   pathological `fnmatch` patterns. This is a hardening measure, not a current
   vulnerability.

## Conclusion

The BUG_0003 fix introduces **no new security vulnerabilities**. The `subprocess.run()`
call uses a list of arguments (no shell injection risk), the file path passed to
the `file` command is consistent with the pre-existing trust model, and error
messages do not disclose sensitive information. All relevant security requirements
(REQ_SEC_001, REQ_SEC_002, REQ_SEC_005, REQ_SEC_006) are satisfied.

**Security assessment result: PASS.**
