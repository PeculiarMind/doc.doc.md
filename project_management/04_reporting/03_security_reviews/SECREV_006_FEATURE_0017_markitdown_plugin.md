# Security Review: FEATURE_0017 — Markitdown MS Office Plugin

- **ID:** SECREV_006
- **Created at:** 2026-03-10
- **Created by:** security.agent
- **Work Item:** [FEATURE_0017](../../03_plan/02_planning_board/06_done/FEATURE_0017_markitdown_ms_office_plugin.md)
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

| File | Purpose |
|------|---------|
| `doc.doc.md/plugins/markitdown/main.sh` | Core plugin: reads JSON stdin, validates path and MIME type, invokes markitdown |
| `doc.doc.md/plugins/markitdown/install.sh` | Installs markitdown Python library via pip |
| `doc.doc.md/plugins/markitdown/installed.sh` | Checks if markitdown binary is available |
| `doc.doc.md/plugins/markitdown/descriptor.json` | Plugin descriptor: declares process/install/installed commands |

## Security Concept Reference

- [Security Concept — Scope 3: Plugin System Architecture](../../02_project_vision/04_security_concept/01_security_concept.md) (Risk: 3.53 HIGH)
- [REQ_SEC_001: Input Validation and Sanitization](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_001_input_validation_sanitization.md)
- [REQ_SEC_005: Path Traversal Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md)
- [REQ_SEC_006: Error Information Disclosure Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_006_error_information_disclosure_prevention.md)
- Security Controls: SC-001, SC-004, SC-006

## Assessment Methodology

1. **Static analysis**: Full line-by-line review of `main.sh`, `install.sh`, `installed.sh`, and `descriptor.json`.
2. **Data flow tracing**: Traced user-controlled data (`filePath`, `mimeType`) from JSON stdin through canonicalization, validation gates, and invocation of `markitdown`.
3. **Comparison with established remediation**: Cross-checked against BUG_0001/BUG_0002 remediations applied to `stat`, `file`, and `ocrmypdf` plugins.
4. **Adversarial input consideration**: Evaluated crafted `filePath` and `mimeType` values for injection, traversal, and disclosure risks.

## Findings

| # | Severity | Location | Description | Evidence | Remediation | Bug |
|---|----------|----------|-------------|----------|-------------|-----|
| 1 | MEDIUM | `main.sh:21` | **No stdin size limit.** `input_json="$(cat)"` reads all stdin without a size constraint. BUG_0001 established the 1 MB limit (`head -c 1048576`) as the standard for all plugins, and `stat`, `file`, and `ocrmypdf` all implement it. The markitdown plugin was implemented after BUG_0001 was resolved but did not inherit this safeguard, creating a consistency gap. An attacker can exhaust process memory by sending a multi-gigabyte payload. | `python3 -c "print('{\"filePath\":\"/tmp/x\",\"x\":\"' + 'A'*10000000 + '\"}')" \| ./main.sh` — unbounded memory consumption with no rejection. | Replace `input_json="$(cat)"` with `input_json="$(head -c 1048576)"` per REQ_SEC_009 and the pattern established by BUG_0001. | [BUG_0006](../../03_plan/02_planning_board/04_backlog/BUG_0006_markitdown_plugin_missing_stdin_size_limit.md) |
| 2 | LOW | `main.sh:57` | **Error message echoes unsanitized `$mime_type` to stderr.** `echo "Error: Unsupported MIME type: $mime_type"` outputs the raw user-supplied value. Since `jq -r` decodes JSON string escapes (including `\n`), a mimeType value containing embedded newlines produces multi-line stderr output, enabling log injection. Example: `"mimeType": "text/plain\nfake error: exploited"` → two distinct stderr lines, where the second fabricates an error message. | `echo '{"filePath":"/tmp/x","mimeType":"text/plain\nINJECTED LINE"}' \| ./main.sh 2>&1` → two stderr lines including the injected one. | Truncate or sanitize `$mime_type` before echoing: use `${mime_type%%$'\n'*}` to strip at first newline, or pass through a safe formatter. | No bug created — LOW severity, limited to local CLI context. |

### Positive Security Observations

| # | Area | Observation |
|---|------|-------------|
| P1 | **Path canonicalization** | `readlink -f "$file_path"` resolves symlinks and `..` sequences before any filesystem operation. Canonicalization failures result in immediate exit. |
| P2 | **Restricted path blocking** | `canonical_path` is checked against `/proc/*`, `/dev/*`, `/sys/*`, `/etc/*` via a `case` pattern. Access to these paths is rejected before the file is opened. This implements the defense-in-depth layer introduced by BUG_0001. |
| P3 | **No path disclosure in errors** | Error messages for missing files, unresolvable paths, and failed conversions do not include the user-supplied or resolved file path. This complies with REQ_SEC_006. |
| P4 | **MIME type allowlisting** | `mimeType` is validated against an explicit allowlist of 6 MS Office MIME types using exact equality — not substring or glob matching. Unknown MIME types are rejected. |
| P5 | **Safe binary invocation** | `markitdown "$canonical_path"` — the canonical path is double-quoted. No shell expansion or injection is possible through the path argument. |
| P6 | **Secure temp file handling** | `_mkd_err_file="$(mktemp)"` creates a cryptographically random temp file. It is cleaned up via `rm -f` in both success and failure branches. No predictable filename or race condition exists. |
| P7 | **jq-only JSON output** | `jq -n --arg documentText "$document_text" '{"documentText": $documentText}'` — uses `--arg` to safely pass multi-line text as a JSON string value, preventing injection into the JSON output. |
| P8 | **set -euo pipefail** | Strict bash mode. Undefined variable use is a fatal error; pipeline failures propagate. |
| P9 | **install.sh / installed.sh safety** | Take no user input, use only `pip install` and `command -v` respectively, and produce fixed JSON output. No security concerns. |

## Threat Model

### Threat Context

The markitdown plugin is invoked as a subprocess by the doc.doc.md runtime, receiving JSON on stdin and writing JSON to stdout. The primary threat scenarios are:

1. **Crafted file path** causing the plugin to process a file outside the intended document collection (path traversal, symlink abuse).
2. **Crafted MIME type** bypassing the MIME allowlist and causing `markitdown` to be invoked on an unsupported or sensitive file type.
3. **Oversized stdin** causing memory exhaustion (DoS).
4. **Log injection** via crafted MIME type, poisoning log aggregation output.

### Mitigating Architecture

`readlink -f` + path restriction (P1, P2) addresses scenarios 1 and 2. MIME allowlisting (P4) is a second gate against scenario 2. Scenario 4 impact is limited to stderr in a CLI context.

### Residual Risks

| Risk | Severity | Status |
|------|----------|--------|
| Memory exhaustion via oversized stdin | MEDIUM | **Open** — BUG_0006 filed |
| Log injection via newline in mimeType | LOW | **Accepted** — limited to local CLI stderr |
| Partial path restriction (home dirs, `/var`, `/tmp` not blocked) | LOW | **Accepted** — consistent with other plugins post-BUG_0001; full sandboxing deferred to SC-010 |

## Recommendations

### Immediate (before FEATURE_0017 considered fully secure)

1. **Fix BUG_0006**: Add `head -c 1048576` stdin size limit to `main.sh:21` to align with the standard established by BUG_0001 and implemented in `stat`, `file`, and `ocrmypdf` plugins.

### Optional Hardening

2. **Sanitize mimeType in error messages** (LOW): Strip embedded newlines from `$mime_type` before echoing to stderr to prevent log injection. The fix is one line and low risk.

## Conclusion

**Overall Assessment: Issues Found**

The markitdown plugin demonstrates strong security fundamentals: `readlink -f` canonicalization, restricted path blocking, MIME type allowlisting, secure temp file handling, no path disclosure in errors, and safe binary invocation. Command injection and path traversal are effectively prevented.

One medium-severity gap was identified: the plugin omits the 1 MB stdin size limit (`head -c 1048576`) that BUG_0001 established as the standard for all plugins. This creates a memory exhaustion vulnerability and an inconsistency in the security posture across plugins.

**Bug work item BUG_0006 has been created in the backlog** and assigned to developer.agent for remediation.

---

**Document Control:**
- **Created:** 2026-03-10
- **Author:** security.agent
- **Status:** Complete
- **Next Review:** After BUG_0006 remediation
