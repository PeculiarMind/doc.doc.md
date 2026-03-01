# Security Review: FEATURE_0002 stat and file Plugin Implementation

- **ID:** SECREV_002
- **Created at:** 2026-03-01
- **Created by:** security.agent
- **Work Item:** [FEATURE_0002](../../03_plan/02_planning_board/05_implementing/FEATURE_0002_implement_stat_and_file_plugins.md)
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

Six bash shell scripts implementing the stat and file plugins for doc.doc.md:

| Script | Purpose |
|--------|---------|
| `doc.doc.md/plugins/stat/main.sh` | Extracts file statistics (size, owner, timestamps) via `stat` command |
| `doc.doc.md/plugins/stat/installed.sh` | Checks if `stat` command is available |
| `doc.doc.md/plugins/stat/install.sh` | Reports installation status of `stat` command |
| `doc.doc.md/plugins/file/main.sh` | Detects MIME type via `file` command |
| `doc.doc.md/plugins/file/installed.sh` | Checks if `file` command is available |
| `doc.doc.md/plugins/file/install.sh` | Reports installation status of `file` command |

## Security Concept Reference

- [Security Concept — Scope 3: Plugin System Architecture](../../02_project_vision/04_security_concept/01_security_concept.md) (Risk: 3.53 HIGH)
- [REQ_SEC_001: Input Validation and Sanitization](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_001_input_validation_sanitization.md)
- [REQ_SEC_005: Path Traversal Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md)
- [REQ_SEC_006: Error Information Disclosure Prevention](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_006_error_information_disclosure_prevention.md)
- [REQ_SEC_009: JSON Input Validation](../../02_project_vision/02_requirements/01_funnel/REQ_SEC_009_json_input_validation.md)
- Security Controls: SC-001, SC-004, SC-006, SC-008

## Assessment Methodology

1. **Static analysis**: ShellCheck linting of all 6 scripts — all passed clean (zero warnings)
2. **Code review**: Manual review of every line for shell injection, quoting, error handling
3. **Adversarial testing**: 27 manual test cases covering command injection, path traversal, type confusion, DoS, information disclosure, symlink attacks, device file access, and malformed input
4. **Requirements traceability**: Each finding mapped to applicable security requirements and controls

## Findings

| # | Severity | Location | Description | Evidence | Remediation | Bug |
|---|----------|----------|-------------|----------|-------------|-----|
| 1 | High | `stat/main.sh`, `file/main.sh` | **No path boundary enforcement.** Plugins accept any absolute path and operate on any readable file. `/etc/passwd`, `/proc/self/environ`, device files (`/dev/null`), and symlinks to sensitive files are all accessible. No canonicalization or boundary checking is performed. | `echo '{"filePath":"/etc/passwd"}' \| main.sh` → returns file stats successfully. `echo '{"filePath":"/proc/self/environ"}' \| main.sh` → returns stats for process environment. Symlink `/tmp/link → /etc/passwd` → follows and returns data. | Add path validation as a defense-in-depth measure. At minimum, reject paths outside the working context. Full boundary enforcement will be provided by the runtime (SC-001, REQ_SEC_005), but plugins should reject obviously dangerous paths (e.g., `/proc`, `/dev`, `/sys`). | [BUG_0001](../../03_plan/02_planning_board/04_backlog/BUG_0001_plugin_path_traversal_no_boundary_enforcement.md) |
| 2 | Medium | `stat/main.sh`, `file/main.sh` | **Error messages disclose full file paths.** Error messages include the complete user-supplied file path, revealing system structure. Examples: `"Error: File not found: /home/secretuser/documents/classified.pdf"` and `"Error: File is not readable: /etc/shadow"`. The readability check also acts as a file-existence oracle (attacker can distinguish "not found" vs "not readable"). | `echo '{"filePath":"/etc/shadow"}' \| main.sh` → `"Error: File is not readable: /etc/shadow"` (confirms file exists). `echo '{"filePath":"/home/secretuser/documents/classified.pdf"}' \| main.sh` → reveals full path in error. | Per REQ_SEC_006, production error messages should show only the basename or a generic message. Combine "not found" and "not readable" into a single generic error to prevent the existence oracle. | [BUG_0002](../../03_plan/02_planning_board/04_backlog/BUG_0002_plugin_error_message_information_disclosure.md) |
| 3 | Medium | `stat/main.sh`, `file/main.sh` | **No JSON input size limit.** `input=$(cat)` reads all of stdin into memory without any size constraint. An attacker or malformed caller could send gigabytes of data, causing memory exhaustion (DoS). REQ_SEC_009 specifies a 1 MB maximum. | `python3 -c "print('{\"filePath\":\"/etc/hostname\",\"x\":\"' + 'A'*5000000 + '\"}')" \| main.sh` → 5 MB payload processed without rejection. | Add `head -c` or `dd` size limit before reading stdin. Example: `input=$(head -c 1048576)` with a check that stdin didn't exceed the limit. | Included as secondary concern in [BUG_0001](../../03_plan/02_planning_board/04_backlog/BUG_0001_plugin_path_traversal_no_boundary_enforcement.md) |
| 4 | Low | `stat/main.sh`, `file/main.sh` | **No type validation for filePath parameter.** When `filePath` is a non-string JSON type (number, boolean, array), `jq -r` silently coerces it to a string representation. `{"filePath": 12345}` becomes the string `"12345"`, `{"filePath": true}` becomes `"true"`. REQ_SEC_009 requires explicit type checking. | `echo '{"filePath": 12345}' \| main.sh` → `"Error: File not found: 12345"` (coerced to string, no type error). `echo '{"filePath": ["/etc/passwd"]}' \| main.sh` → coerced to multiline string. | Validate filePath is a string type using `jq -e 'if (.filePath \| type) == "string" then . else error end'` before extraction. | Deferred — runtime validation (REQ_SEC_009) will enforce type checking before plugin invocation. |
| 5 | Low | `stat/main.sh`, `file/main.sh` | **No JSON nesting depth limit.** Deeply nested JSON objects are accepted and parsed by jq without restriction. REQ_SEC_009 specifies max 10 levels. | Deeply nested JSON with arbitrary depth accepted. | Deferred — runtime validation (REQ_SEC_009) will enforce depth limits before plugin invocation. |

### Positive Security Observations

The following security practices are correctly implemented:

| # | Area | Observation |
|---|------|-------------|
| P1 | **Shell Injection Prevention** | All uses of `$filePath` in shell commands (`stat`, `file`, `date`) are properly double-quoted, preventing shell word splitting and glob expansion. ShellCheck confirms no quoting issues. |
| P2 | **`set -euo pipefail`** | Both `main.sh` scripts use strict mode: errors cause immediate exit (`-e`), undefined variables are errors (`-u`), and pipe failures propagate (`pipefail`). |
| P3 | **JSON handling via jq** | All JSON parsing and generation uses `jq`, avoiding manual string manipulation that could produce invalid JSON or allow injection. |
| P4 | **stderr/stdout separation** | All error messages go to stderr; only valid JSON goes to stdout. This prevents error text from being parsed as plugin output. |
| P5 | **No eval/exec usage** | No use of `eval`, `exec`, backtick execution, or other dangerous shell constructs on user-controlled data. |
| P6 | **Command injection safe** | Adversarial inputs containing `$(whoami)`, `` `whoami` ``, `; ls`, `| cat` were all treated as literal filenames, not executed. |
| P7 | **Malformed JSON rejection** | Invalid JSON input is properly rejected with error exit code 1. |
| P8 | **installed.sh / install.sh safety** | These scripts take no user input, use only `command -v` checks, and produce fixed JSON output. No security concerns. |

## Threat Model

### Threat Context

These plugins run as subprocesses of the doc.doc.md runtime. Per the security concept (Scope 3), plugins execute with the same privileges as the calling user. The primary threat scenario is:

1. **Malicious or crafted file paths** passed via JSON stdin that cause the plugin to access unintended files or disclose sensitive information.
2. **Denial of service** via oversized inputs or resource exhaustion.

### Mitigating Architecture

The JSON stdin/stdout architecture (ADR-003) provides inherent protection against many shell injection attacks since jq parsing does not execute embedded commands. The proper quoting of all variables provides a second layer of defense.

### Residual Risks

| Risk | Severity | Status |
|------|----------|--------|
| Arbitrary file metadata read via path manipulation | High | **Open** — requires runtime path validation (SC-001) or plugin-level defense |
| File existence oracle via differentiated error messages | Medium | **Open** — requires error message sanitization |
| Memory exhaustion via large stdin | Medium | **Open** — requires stdin size limiting |
| Type confusion via non-string filePath | Low | **Accepted** — runtime validation will enforce types (REQ_SEC_009) |

## Recommendations

### Immediate (before FEATURE_0002 can move to DONE)

1. **Create BUG_0001**: Path traversal / no boundary enforcement — HIGH severity. The plugins should not blindly operate on any file path. At minimum, add defense-in-depth rejection of paths in `/proc`, `/dev`, `/sys`, and symlink resolution validation. Full boundary enforcement is a runtime responsibility but plugins should not be completely passive.

2. **Create BUG_0002**: Error information disclosure — MEDIUM severity. Error messages must not include full user-supplied file paths. Use basename only or a generic message per REQ_SEC_006.

### Deferred (to runtime implementation)

3. **JSON input size limits** (REQ_SEC_009): The runtime must enforce the 1 MB stdin limit before invoking plugins. Plugin-level `head -c` is a defense-in-depth measure that can be added with BUG_0001.

4. **Type validation** (REQ_SEC_009): The runtime must validate JSON types against the plugin descriptor schema before invocation. Plugin-level type checking is low priority since jq handles coercion safely.

5. **Nesting depth limits** (REQ_SEC_009): The runtime must enforce JSON complexity limits.

### Design Consideration

6. **Plugin sandboxing** (SC-010, planned for v0.3.0): These findings reinforce the importance of the planned plugin sandboxing feature. Until sandboxing is available, the runtime path validation (SC-001) is the critical control.

## Conclusion

**Overall Assessment: Issues Found**

The stat and file plugin implementations demonstrate good security fundamentals: proper variable quoting, jq-based JSON handling, strict bash mode, stderr/stdout separation, and no use of dangerous shell constructs. Command injection is effectively prevented.

However, two actionable security issues were identified:

1. **HIGH: No path boundary enforcement** — plugins will operate on any readable file on the system, including sensitive files (`/etc/passwd`, `/proc/self/environ`), device files, and symlink targets. This violates REQ_SEC_005 (Path Traversal Prevention) and SC-001 (Input Path Validation).

2. **MEDIUM: Error information disclosure** — error messages reveal full file paths and differentiate between "not found" and "not readable", creating a file-existence oracle. This violates REQ_SEC_006 (Error Information Disclosure Prevention) and SC-006 (Error Message Sanitization).

**Bug work items BUG_0001 and BUG_0002 have been created in the backlog** and assigned to developer.agent for remediation. The feature should not advance to DONE until at least BUG_0002 (information disclosure) is resolved. BUG_0001 (path validation) may be partially deferred to the runtime implementation if the team accepts the risk for MVP, but a defense-in-depth measure is strongly recommended.

---

**Document Control:**
- **Created:** 2026-03-01
- **Author:** security.agent
- **Status:** Complete
- **Next Review:** After BUG_0001 and BUG_0002 remediation, or before MVP release
