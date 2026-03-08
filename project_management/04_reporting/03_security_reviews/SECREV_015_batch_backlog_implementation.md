# Security Review: Batch Backlog Implementation

- **ID:** SECREV_015
- **Created at:** 2026-03-08
- **Created by:** security.agent
- **Work Item:** Batch Backlog Implementation (BUG_0012, FEATURE_0037, FEATURE_0038, FEATURE_0039)
- **Status:** Passed

## Table of Contents
1. [Reviewed Scope](#reviewed-scope)
2. [Security Concept Reference](#security-concept-reference)
3. [Assessment Methodology](#assessment-methodology)
4. [Findings](#findings)
5. [Conclusion](#conclusion)

## Reviewed Scope

| File | Changes | Security Relevance |
|------|---------|-------------------|
| `doc.doc.md/plugins/markitdown/main.sh` | Forward stderr on failure (BUG_0012) | Medium — error messages must not disclose sensitive paths |
| `doc.doc.md/components/plugin_management.sh` | Install validation, error guidance, jq fix (FEATURE_0037) | Medium — new interactive prompts, install execution |
| `doc.doc.sh` | Process validation phase, -h alias (FEATURE_0037, FEATURE_0038) | Medium — new CLI input surface |
| `doc.doc.md/components/ui.sh` | Help restructuring, banner externalisation (FEATURE_0038, FEATURE_0039) | Low — output-only changes |
| `doc.doc.md/components/banner.txt` | New static text file (FEATURE_0039) | None — static asset |
| `tests/*` | New and updated test suites | None — test code only |

## Security Concept Reference

| Requirement | Relevance |
|-------------|-----------|
| REQ_SEC_001 (Input Size Limits) | Verified — no new stdin/file reading without size limits |
| REQ_SEC_002 (Path Validation) | Verified — banner.txt path resolved via `dirname "${BASH_SOURCE[0]}"` (safe) |
| REQ_SEC_003 (Command Injection Prevention) | Verified — no eval, no command injection vectors |
| REQ_SEC_004 (Privilege Management) | Verified — sudo advice is printed as user guidance only; no automatic privilege escalation |
| REQ_SEC_005 (Output Channel Separation) | Verified — errors to stderr, help to stdout, JSON pipeline unaffected |
| REQ_SEC_006 (Error Information Disclosure Prevention) | Verified — BUG_0012 forwards markitdown's own stderr (tool output, not internal paths); no system paths disclosed |

## Assessment Methodology

1. **Error disclosure audit** — BUG_0012 forwards the markitdown binary's stderr. This is the tool's own error output, not internal system information. The plugin's existing path validation (`readlink -f`, restricted directory check) remains unchanged.
2. **Command injection review** — FEATURE_0037 uses `bash "$install_sh"` to run install scripts. The `$install_sh` path is derived from `$PLUGIN_DIR/$plugin_name/install.sh` where both `$PLUGIN_DIR` (hardcoded) and `$plugin_name` (from `discover_all_plugins`) are controlled values. No user-controlled string is passed to eval or command substitution.
3. **Interactive prompt safety** — FEATURE_0037 interactive prompts read a single character (`read -r _choice`) and validate against a whitelist (`c/a/i`). Invalid input defaults to abort (safe default). In non-interactive mode (stdin not a TTY), validation fails immediately with an error (CI-safe).
4. **File read audit** — FEATURE_0039 reads `banner.txt` via `cat "$_banner_file"` where the path is resolved relative to `ui.sh` using `dirname "${BASH_SOURCE[0]}"`. This is a safe, deterministic path. Silent fallback on missing file prevents denial-of-service via file deletion.
5. **Privilege escalation check** — FEATURE_0037 prints `sudo` advice as a user-facing tip. No actual privilege escalation is performed. The `setup` command continues to use standard bash patterns with no `sudo`, `chmod`, or `setuid`.
6. **{{key}} substitution safety** — FEATURE_0039 uses bash parameter expansion (`${content//\{\{key\}\}/value}`) for banner placeholders. This is string replacement only, no eval or command execution. Unresolved placeholders are passed through unchanged.

## Findings

| # | Severity | Description | Status |
|---|----------|-------------|--------|
| — | — | No security vulnerabilities found | — |

### Positive Observations

| # | Observation |
|---|------------|
| 1 | **BUG_0012: Safe error forwarding** — The fix reads the temp file content via `cat` and includes it in the error message via `echo`. No command execution on the error content. Temp file always cleaned up. |
| 2 | **FEATURE_0037: Safe default for interactive prompts** — Invalid input defaults to abort (exit non-zero). Non-interactive mode treats missing plugins as hard errors. |
| 3 | **FEATURE_0037: No privilege escalation** — `sudo` tip is advisory text only. No automatic privilege elevation. |
| 4 | **FEATURE_0039: Safe file reading** — Banner file path is deterministic (relative to source file). Missing file handled gracefully (silent no-op). |
| 5 | **FEATURE_0039: No eval in substitution** — `{{key}}` replacement uses bash string substitution, not eval or command substitution. |
| 6 | **jq fix: Correctness improvement** — The change from `// "true"` to `if .installed == false then "false" else "true" end` fixes a logic error where boolean `false` was treated as null. This is a security-positive change: plugins that report `installed: false` are now correctly detected as uninstalled. |

## Conclusion

The batch backlog implementation is **approved**. All 4 work items (BUG_0012, FEATURE_0037, FEATURE_0038, FEATURE_0039) were reviewed for security impact. No vulnerabilities were found or introduced. Error forwarding (BUG_0012) is safe and does not disclose internal paths. Interactive prompts (FEATURE_0037) use safe defaults. Banner externalisation (FEATURE_0039) uses deterministic file resolution and string-only substitution. The jq boolean fix is a correctness improvement with positive security implications.
