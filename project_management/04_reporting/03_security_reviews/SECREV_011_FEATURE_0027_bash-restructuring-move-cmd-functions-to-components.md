# Security Review: FEATURE_0027 — Bash Restructuring: Move cmd_* Functions to Components

- **ID:** SECREV_011
- **Created at:** 2026-03-06
- **Created by:** security.agent
- **Work Item:** `project_management/03_plan/02_planning_board/05_implementing/FEATURE_0027_bash-restructuring-move-cmd-functions-to-components.md`
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
| `doc.doc.md/components/plugin_management.sh` | `cmd_activate`, `cmd_deactivate`, `cmd_install`, `_install_single_plugin`, `_install_all_plugins`, `cmd_installed`, `cmd_tree`, `_validate_plugin_dir`, `_list_plugins`, `cmd_list` | Received from `doc.doc.sh`; manages plugin lifecycle |
| `doc.doc.md/components/plugin_execution.sh` | `process_file` | Received from `doc.doc.sh`; sequences plugins over a file |
| `doc.doc.sh` | Removal of above functions; now sources both components | Pure orchestrator after refactoring |

## Security Concept Reference

| Requirement | Relevance |
|-------------|-----------|
| REQ_SEC_001 (Input Validation and Sanitization) | Relevant — plugin name and file path inputs pass through moved functions |
| REQ_SEC_003 (Plugin Descriptor Validation) | Relevant — `discover_plugins` and `discover_all_plugins` validate descriptors with `jq` |
| REQ_SEC_005 (Path Traversal Prevention) | Relevant — `_validate_plugin_dir` specifically addresses path traversal for plugin directories |
| REQ_SEC_006 (Error Information Disclosure Prevention) | Relevant — error messages in moved functions reviewed for sensitive data leakage |

## Assessment Methodology

1. **Code review** of all functions moved into both component files
2. **Path traversal analysis** of `_validate_plugin_dir`, `cmd_install`, and file-path handling in `process_file`
3. **Input validation review** for plugin-name and file-path parameters in all moved functions
4. **Credential/secret scan** of all moved code for hardcoded secrets or sensitive values
5. **Comparison review** against SECREV_009 (security posture baseline) and SECREV_010

## Findings

| # | Severity | Location | Description | Remediation | Bug |
|---|----------|----------|-------------|-------------|-----|
| — | — | — | No security vulnerabilities found | — | — |

### Positive Observations

| # | Observation |
|---|------------|
| 1 | **Path traversal guard preserved and moved intact**: `_validate_plugin_dir` uses `cd ... && pwd -P` (canonical path resolution) and a strict prefix check to ensure plugin paths remain within `$PLUGIN_DIR`; this pattern complies with REQ_SEC_005 |
| 2 | **No new input sources introduced**: The refactoring is a pure move of existing functions; no new CLI arguments, environment variable reads, or stdin channels are introduced |
| 3 | **No hardcoded credentials or secrets**: Grepping all moved functions confirms no hardcoded tokens, passwords, API keys, or other sensitive values |
| 4 | **Plugin descriptor validation unchanged**: `discover_plugins` still validates presence of `.name`, `.version`, `.description`, and `.commands` via `jq -e` before accepting a plugin, maintaining REQ_SEC_003 compliance |
| 5 | **JSON injection boundary maintained**: `process_file` and `run_plugin` continue to pass file paths via `jq --arg` (which escapes the value), preventing JSON injection through manipulated file names |
| 6 | **Error messages use `basename`**: Error output in `run_plugin` uses `$(basename "$file_path")`, limiting accidental disclosure of full directory structure on stderr |
| 7 | **No cross-module secret sharing**: Separation of `plugin_management.sh` and `plugin_execution.sh` means activation state is never exposed to the execution layer, reducing attack surface |
| 8 | **No `eval` or dynamic execution**: None of the moved functions use `eval`, `exec`, or dynamic command construction beyond controlled plugin dispatch via verified executable paths |

## Threat Model

### Threat Context
FEATURE_0027 is a pure structural refactoring — functions are moved verbatim with no logic changes. The security posture of moved functions is identical to that reviewed in prior security assessments. The principal concern is whether the move introduces any new attack surface at module boundaries.

### Threat Scenarios

| Threat (STRIDE) | Scenario | Risk | Mitigation |
|-----------------|----------|------|------------|
| Path Traversal | Plugin name containing `../` passed to `_validate_plugin_dir` | LOW | `_validate_plugin_dir` uses canonical path comparison; traversal attempt results in a `return 1` rejection |
| Command Injection | Malicious plugin descriptor `commands.process.command` value | LOW | Script path is validated for existence and executability (`[ ! -x "$script_path" ]`) before invocation; no shell expansion of the value |
| Information Disclosure | Error messages exposing internal paths | LOW | `run_plugin` uses `basename` on file paths in error output; plugin directory paths not echoed in errors |
| Privilege Escalation | Sourcing manipulated component files | LOW | Component files are sourced from a fixed repository path; no user-controlled source path |

### Residual Risks
- None identified for this change. The refactoring introduces no new residual risks beyond those already accepted in the security baseline.

## Recommendations

1. **No immediate actions required** — No security vulnerabilities identified
2. **Plugin name allow-list** (future hardening): `_validate_plugin_dir` catches traversal via canonical paths; a complementary allow-list check on plugin name characters (`[a-zA-Z0-9_-]`) would provide defence in depth
3. **REQ_SEC_007 documentation**: Ensure the plugin security documentation is updated if FEATURE_0028 changes the plugin invocation surface area

## Conclusion

**Result: ✅ Passed — No Security Issues Found**

FEATURE_0027 introduces no security vulnerabilities. The move is verbatim — all existing security controls (path traversal prevention, descriptor validation, JSON injection boundaries, error message hygiene) are preserved in their new locations. The structural separation of plugin management and execution concerns reduces attack surface by ensuring activation state is never accessible from the execution layer. The refactoring is approved from a security standpoint.

## Document Control

| Field | Value |
|-------|-------|
| Created | 2026-03-06 |
| Author | security.agent |
| Status | Passed |
| Next review trigger | Changes to plugin invocation logic, descriptor parsing, or path handling in component files |
