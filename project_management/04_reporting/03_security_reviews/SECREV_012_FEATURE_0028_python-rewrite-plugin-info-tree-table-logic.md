# Security Review: FEATURE_0028 — Python Rewrite: plugin_info.py for Tree and Table Logic

- **ID:** SECREV_012
- **Created at:** 2026-03-06
- **Created by:** security.agent
- **Work Item:** `project_management/03_plan/02_planning_board/06_done/FEATURE_0028_python-rewrite-plugin-info-tree-table-logic.md`
- **Status:** Passed

## Table of Contents
1. [Reviewed Scope](#reviewed-scope)
2. [Security Concept Reference](#security-concept-reference)
3. [Assessment Methodology](#assessment-methodology)
4. [Findings](#findings)
5. [Threat Model](#threat-model)
6. [Recommendations](#recommendations)
7. [Conclusion](#conclusion)

## Reviewed Scope

| File | Functions/Changes | Purpose |
|------|-------------------|---------|
| `doc.doc.md/components/plugin_info.py` | `run_tree`, `run_table`, `_read_plugin`, `_detect_cycle`, `_render_label`, `_print_tree`, `main` | New Python component; reads plugin directories and parses `descriptor.json`; formats TSV from stdin |
| `doc.doc.md/components/plugin_management.sh` | `cmd_tree` (refactored), `cmd_list` (table paths refactored) | Thin wrappers replacing Bash DFS and `column -t` with Python calls |

## Security Concept Reference

| Requirement | Relevance |
|-------------|-----------|
| REQ_SEC_001 (Input Validation and Sanitization) | Relevant — `plugins_dir` path is accepted as CLI argument; TSV data accepted from stdin |
| REQ_SEC_003 (Plugin Descriptor Validation) | Relevant — `_read_plugin` parses `descriptor.json` with `json.load` |
| REQ_SEC_005 (Path Traversal Prevention) | Relevant — `run_tree` reads plugin directories under a caller-supplied path |
| REQ_SEC_006 (Error Information Disclosure Prevention) | Relevant — error messages in `plugin_info.py` reviewed for sensitive data exposure |

## Assessment Methodology

1. **Code review** of all functions in `plugin_info.py` and the refactored sections of `plugin_management.sh`
2. **Path traversal analysis** of `run_tree` and `_read_plugin` (directory enumeration and file reading)
3. **JSON parsing security review** for `_read_plugin` (untrusted `descriptor.json` content)
4. **Shell injection analysis** — verifying `plugin_info.py` introduces no subprocess calls or shell expansion
5. **stdin attack surface review** for `run_table` (size, content, encoding)
6. **Error message audit** for sensitive information disclosure
7. **Dependency scan** — verifying only Python stdlib modules are used

## Findings

| # | Severity | Location | Description | Remediation | Bug |
|---|----------|----------|-------------|-------------|-----|
| — | — | — | No security vulnerabilities found | — | — |

### Positive Observations

| # | Observation |
|---|------------|
| 1 | **No shell injection surface**: `plugin_info.py` contains zero subprocess calls (`subprocess`, `os.system`, `os.popen`), zero `eval` usage, and zero `exec` usage; the `plugins_dir` path argument is passed only to Python stdlib `os`/`json` functions, never to a shell |
| 2 | **Directory traversal bounded by `os.listdir`**: `run_tree` calls `os.listdir(plugins_dir)` and then constructs paths as `os.path.join(plugins_dir, name)` — this does not escape `plugins_dir` because `os.listdir` returns bare filenames, not paths; a name containing `/` would require a crafted filesystem entry (out of attacker scope in this threat model) |
| 3 | **JSON parsing with exception handling**: `_read_plugin` wraps `json.load` in a `try/except (json.JSONDecodeError, IOError)` block; malformed or unreadable `descriptor.json` returns `None` gracefully without crashing or leaking file content |
| 4 | **Required field validation after JSON parse**: `_read_plugin` validates `d.get("name")` and `"commands" in d` before accepting a descriptor; plugins with minimal or missing fields are silently skipped, consistent with the existing `jq -e` validation in Bash discovery functions |
| 5 | **stdin is internal-only data**: `run_table` reads from `sys.stdin` which is exclusively piped from `jq` output in `cmd_list`; no external attacker can inject arbitrary stdin to `plugin_info.py` in normal operation; the `sys.stdin.read()` call has no size limit, but the input is bounded by the number and size of plugin descriptors on disk |
| 6 | **No sensitive data in error messages**: Error messages use the caller-supplied `plugins_dir` path (which is the repository's own plugin directory, not a user-supplied path) and plugin names from the filesystem; no credentials, tokens, or internal stack traces are exposed |
| 7 | **ANSI codes are hardcoded constants**: Color codes (`\033[32m`, `\033[31m`, `\033[0m`) are static string literals; they cannot be injected or manipulated by plugin descriptor content |
| 8 | **Pure stdlib dependencies**: `plugin_info.py` imports only `json`, `os`, `sys` — all Python standard library modules; no third-party packages are introduced, eliminating supply-chain risk |
| 9 | **Calling convention in `plugin_management.sh` is injection-safe**: `cmd_tree` passes `"$PLUGIN_DIR"` as a single quoted argument to `python3 plugin_info.py tree "$PLUGIN_DIR"`; `PLUGIN_DIR` is a fixed repository path set at startup, not user-supplied |

## Threat Model

### Threat Context
FEATURE_0028 introduces a new Python component that reads plugin directories and parses `descriptor.json` files. The primary new attack surfaces are: (1) the `plugins_dir` path argument to `run_tree`, (2) `descriptor.json` content read by `_read_plugin`, and (3) TSV data from stdin in `run_table`. All three are controlled by the repository itself or its plugins, not by end users.

### Threat Scenarios

| Threat (STRIDE) | Scenario | Risk | Mitigation |
|-----------------|----------|------|------------|
| Path Traversal | `plugins_dir` argument contains `../` or symlink pointing outside plugin dir | LOW | `os.listdir` returns bare filenames; constructed paths stay within `plugins_dir`; calling `cmd_tree` passes fixed `$PLUGIN_DIR`, not user input |
| Malicious JSON | `descriptor.json` with crafted content (very deep nesting, large strings) triggers DoS or injection | LOW | `json.load` has no recursion depth issue for expected descriptor sizes; content is read for metadata only, never executed or passed to a shell |
| Stdin Injection | Malicious TSV data piped to `run_table` contains escape sequences or oversized lines | LOW | `run_table` only splits on `\t` and calls `str.ljust`; no code execution path; content is printed to stdout unchanged except for padding |
| Information Disclosure | Error message reveals internal path structure | LOW | Error messages include only the `plugins_dir` value, which is the repository's own plugin path — not a secret |
| Supply Chain | Malicious third-party Python package introduced | NONE | No third-party packages used; all imports are Python stdlib |

### Residual Risks
None identified for this change. The new Python component introduces no residual security risks beyond those already present in the plugin descriptor reading logic (which was previously performed by `jq` in Bash and is now replicated in Python with equivalent safety).

## Recommendations

1. **No immediate actions required** — No security vulnerabilities identified
2. **stdin size hardening** (future): If `plugin_info.py` is ever exposed to user-supplied stdin (e.g., in a future piped workflow), adding a `MAX_STDIN_BYTES` guard would provide defence in depth
3. **Symlink policy** (future): If the plugin directory may contain symlinks to external directories, adding a `os.path.realpath` check in `run_tree` to confirm each plugin path stays within `PLUGIN_DIR` would strengthen the path traversal guarantee

## Conclusion

**Result: ✅ Passed — No Security Issues Found**

FEATURE_0028 introduces no security vulnerabilities. `plugin_info.py` is a pure-Python, stdlib-only component with no shell subprocess calls, no `eval`, and no user-controlled external input. JSON parsing is wrapped in exception handling with field validation. Error messages are informative but do not disclose sensitive data. The calling convention in `plugin_management.sh` passes a fixed repository path, not user input. The component is approved from a security standpoint.

## Document Control

| Field | Value |
|-------|-------|
| Created | 2026-03-06 |
| Author | security.agent |
| Status | Passed |
| Next review trigger | Changes to `plugin_info.py` path handling, JSON parsing logic, or introduction of subprocess calls |
