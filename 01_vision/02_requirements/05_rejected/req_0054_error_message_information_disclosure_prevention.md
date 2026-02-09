# Requirement: Error Message Information Disclosure Prevention

**ID**: req_0054

## Status
State: Rejected  
Created: 2026-02-09  
Last Updated: 2026-02-09

## Rejection Reason
Error message information disclosure prevention is not necessary given the operational context and threat model. The toolkit operates locally on the user's own system processing their own documents. The operator is either the owner of the data being analyzed or has explicit read access to it (otherwise they cannot run the analysis in the first place). Path disclosure in error messages does not constitute a security vulnerability in this context because:

1. **Operator = Data Owner**: The user running the tool already has filesystem access to all documents being processed
2. **Local-Only Operation**: No remote access or multi-user scenarios where path disclosure aids privilege escalation
3. **Single-User Context**: Homelab, NAS, personal workstation usage means the operator and system owner are the same entity
4. **Read Access Prerequisite**: If the user lacks access to certain paths, they cannot analyze them anyway

Detailed error messages with full paths actually improve troubleshooting and usability (showing exactly which file failed and where). The security concern addressed by this requirement applies primarily to multi-user systems, web applications, or remote services where error messages might leak information to lesser-privileged users or external attackers. This is scope creep for an offline, single-user toolkit.

**Architectural Assumption**: The operator has read access to all source data being analyzed and runs the toolkit on their own system with their own privileges. See architecture documentation for formalization of this assumption.

## Overview
The system shall prevent information disclosure through error messages by excluding absolute file paths, stack traces, internal implementation details, and sensitive configuration from user-facing errors, providing actionable guidance without exposing system internals.

## Description
Error messages are a common source of information disclosure vulnerabilities, leaking system paths, usernames, implementation details, or configuration that aids attackers in reconnaissance. Error messages should provide users with actionable information to resolve problems without disclosing sensitive system internals. The system must filter error messages to remove absolute paths (use workspace-relative paths), suppress stack traces in normal mode, hide internal function/variable names, and sanitize any user input echoed in errors. Verbose/debug modes may include additional detail but require explicit opt-in with security warning.

## Motivation
From Security Concept (STRIDE):
- **Information Disclosure** is a primary STRIDE threat category
- Error messages are low-hanging fruit for reconnaissance

From Industry Best Practices:
- OWASP recommends generic error messages for security-relevant failures
- CWE-209: Information Exposure Through an Error Message

Without error message sanitization, attackers gain valuable information about system structure, file locations, internal logic, and validation rules that assists in crafting targeted attacks.

## Category
- Type: Non-Functional (Security)
- Priority: Medium

## STRIDE Threat Analysis
- **Information Disclosure**: Error messages leak paths, configuration, implementation details
- **Repudiation**: Detailed errors facilitate attack without leaving obvious evidence
- **Spoofing**: Internal details help attackers craft convincing impersonation attempts

## Risk Assessment (DREAD)
- **Damage**: 5/10 - Assists reconnaissance; enables other attacks
- **Reproducibility**: 10/10 - Errors consistently reproducible
- **Exploitability**: 8/10 - Trivial to trigger errors and read messages
- **Affected Users**: 10/10 - All users see error messages
- **Discoverability**: 9/10 - Obvious to security testers

**DREAD Likelihood**: (5 + 10 + 8 + 10 + 9) / 5 = **8.4**  
**Risk Score**: 8.4 × 6 (Information Disclosure) × 2 (Internal) = **101 (MEDIUM)**

## Acceptance Criteria

### No Absolute Paths in Errors
- [ ] Error messages use workspace-relative paths only (not absolute filesystem paths)
- [ ] Home directory paths replaced with `~` or `$HOME` (not `/home/username`)
- [ ] System paths replaced with generic descriptors: "configuration directory", "plugin directory"
- [ ] Temporary file paths sanitized (not full `/tmp/xyz123/` path)
- [ ] Path sanitization tested with workspace at various absolute locations
- [ ] Path disclosure prevention tested in error message test suite

### No Stack Traces in Normal Mode
- [ ] Stack traces suppressed in normal operation (not shown to users)
- [ ] Stack traces available only in verbose/debug mode with `--verbose` flag
- [ ] Verbose mode shows warning about information disclosure risk
- [ ] Stack traces logged to security audit log (not displayed to user)
- [ ] Function names and line numbers removed from normal error messages
- [ ] Internal implementation details (variable names, code structure) hidden
- [ ] Generic error categories used: "validation failed", "execution error", "internal error"

### Actionable Error Guidance
- [ ] Error messages explain what went wrong at user-understandable level
- [ ] Error messages suggest how to resolve the problem (actionable steps)
- [ ] Error messages reference documentation for complex issues
- [ ] Error messages do not blame user or use technical jargon excessively
- [ ] Error codes or identifiers included for support/debugging (no sensitive data in code)
- [ ] Validation errors specify which field/value invalid (without echoing full user input)
- [ ] Configuration errors explain expected format and provide examples

### Input Echoing Sanitization
- [ ] User input truncated in error messages (maximum 64 characters displayed)
- [ ] Control characters stripped from echoed input (no terminal escape sequences)
- [ ] Sensitive input types never echoed: passwords, tokens, keys
- [ ] File content not echoed in errors (only filename and line number if needed)
- [ ] Command-line arguments sanitized before inclusion in errors (no injection patterns)
- [ ] Newlines escaped in echoed input (prevent log injection via error messages)

### Verbose/Debug Mode Controls
- [ ] Verbose mode requires explicit `--verbose` or `--debug` flag
- [ ] Verbose mode shows warning on startup about information disclosure
- [ ] Verbose mode includes full details: paths, stack traces, internal state
- [ ] Debug mode separate from verbose (debug = developer-level detail)
- [ ] Verbose mode logs all details to file, subset to console (user controls output)
- [ ] Verbose mode output clearly marked (prefix or formatting distinguishes from normal output)
- [ ] No environment variable to globally enable verbose mode (must be explicit per invocation)

### Configuration and System Detail Hiding
- [ ] Error messages do not reveal configuration file content
- [ ] Error messages do not reveal environment variable values
- [ ] Error messages do not reveal system information: OS version, hostname, architecture
- [ ] Error messages do not reveal tool versions or paths (unless relevant to error)
- [ ] Error messages do not reveal network configuration: IP addresses, ports
- [ ] Error messages do not reveal timing information that aids side-channel attacks

### Testing and Validation
- [ ] Error message sanitization tested across all error code paths
- [ ] Deliberate error triggering in tests verifies no information leakage
- [ ] Path disclosure tested with edge cases: symbolic links, long paths, special characters
- [ ] Error message examples documented showing secure vs. insecure messages
- [ ] Security review of error messages before release

## Related Requirements
- req_0038 (Input Validation and Sanitization) - validation error messages
- req_0047 (Plugin Descriptor Validation) - plugin validation error messages
- req_0050 (Workspace Integrity Verification) - workspace validation error messages
- req_0051 (Security Logging and Audit Trail) - full details logged, not displayed
- req_0052 (Secure Defaults and Configuration Hardening) - sanitized errors by default
- req_0053 (Dependency Tool Security Verification) - tool error sanitization

## Transition History
- [2026-02-09] Created by Requirements Engineer Agent based on security review analysis
  -- Comment: Prevents information disclosure through error messages (Risk Score: 101)
- [2026-02-09] Moved to rejected - not applicable to single-user, local-only operation model where operator has data access
