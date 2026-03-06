# Security Review: BUG_0010 — JSON stdout Pollution

- **ID:** SECREV_010
- **Created at:** 2026-03-06
- **Created by:** security.agent
- **Work Item:** `project_management/03_plan/02_planning_board/05_implementing/BUG_0010_json_stdout_pollution.md`
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
| `doc.doc.sh` | `process_command()` — `suppress_json` flag, TTY detection on stdout, JSON echo guards | Suppress JSON output when stdout is an interactive TTY |

## Security Concept Reference

| Requirement | Relevance |
|-------------|-----------|
| REQ_SEC_004 (Input Sanitization) | Not applicable — no new input paths introduced |
| REQ_SEC_005 (Path Validation) | Not applicable — no new file operations introduced |
| REQ_SEC_006 (Information Disclosure) | Relevant — fix reduces unintended exposure of file metadata in interactive terminals |

## Assessment Methodology

1. **Code review** of all new and modified lines in `doc.doc.sh`
2. **Data flow analysis** confirming no new data sources or sinks are introduced
3. **STRIDE analysis** of the `suppress_json` flag and TTY detection logic
4. **Comparison review** against SECREV_009 (stdout/stderr TTY detection precedent)

## Findings

| # | Severity | Location | Description | Remediation | Bug |
|---|----------|----------|-------------|-------------|-----|
| — | — | — | No security vulnerabilities found | — | — |

### Positive Observations

| # | Observation |
|---|------------|
| 1 | **Standard POSIX mechanism**: `[ -t 1 ]` is a well-established POSIX file-descriptor test with no injection risk or side effects |
| 2 | **No new input handling**: The fix adds no new parameters, environment variable reads, or stdin consumption |
| 3 | **No new file operations**: The flag only gates existing `echo` statements; no files are read or written by the new code |
| 4 | **No new data processing**: `suppress_json` is a boolean derived solely from the TTY state of file descriptor 1 |
| 5 | **Reduced information exposure**: Suppressing JSON in interactive terminals prevents unintended display of sensitive file metadata (paths, sizes, timestamps) to terminal sessions where machine-readable output is not expected |
| 6 | **Consistent with established pattern**: The fix mirrors the existing `[ -t 2 ]` stderr TTY check introduced in FEATURE_0026 (SECREV_009), applying the same pattern to stdout |
| 7 | **No external commands**: The TTY check uses only a Bash builtin conditional; no subshell or external process is spawned |
| 8 | **Pipeline behaviour unchanged**: When stdout is a pipe or redirected to a file, `[ -t 1 ]` evaluates false and JSON output is emitted as before, preserving all machine-readable use-cases |

## Threat Model

### Threat Context
The fix gates JSON output on whether stdout is an interactive terminal. The only new runtime state is a boolean variable (`suppress_json`) set once per invocation and never exposed outside `process_command()`.

### Threat Scenarios

| Threat (STRIDE) | Scenario | Risk | Mitigation |
|-----------------|----------|------|------------|
| Information Disclosure | JSON containing file paths displayed in terminals without user intent | REDUCED | Fix explicitly prevents this; metadata is no longer shown in interactive sessions |
| Tampering | Attacker manipulates TTY state to force/suppress JSON output | LOW | TTY state is controlled by the OS; an attacker able to manipulate fd 1 already has equivalent privilege to read the output directly |
| Spoofing | `suppress_json` flag bypassed by environment variable or argument injection | LOW | Flag is a local variable derived only from `[ -t 1 ]`; no external override mechanism exists |

### Residual Risks
- None identified for this change.

## Recommendations

1. **No immediate actions required** — No security vulnerabilities identified
2. **Future consideration**: If JSON output ever includes secrets or credentials, consider adding an explicit `--no-json` flag as a user-facing control independent of TTY detection

## Conclusion

**Result: ✅ Passed — No Security Issues Found**

The BUG_0010 fix introduces no security vulnerabilities. The `suppress_json` flag relies on the standard POSIX `[ -t 1 ]` test, adds no new data sources or file operations, and introduces no injectable code paths. The change positively improves the security posture of the tool by reducing unintended exposure of file metadata in interactive terminal sessions. Pipeline and non-interactive use-cases are completely unaffected.

## Document Control

| Field | Value |
|-------|-------|
| Created | 2026-03-06 |
| Author | security.agent |
| Status | Passed |
| Next review trigger | Changes to JSON output handling or stdout TTY detection logic |
