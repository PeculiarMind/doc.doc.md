# TC-0007: Single-User Operator Trust Model

**ID**: TC-0007  
**Status**: Active  
**Created**: 2026-02-09  
**Last Updated**: 2026-02-09

## Constraint

The toolkit operates in a **single-user, local-only context** where the operator (user running the toolkit) is the owner of the data being analyzed OR has explicit authorized read access to all source documents. The operator is a trusted entity with respect to data access and operations.

## Source

This constraint emerges from the project vision's target deployment environments:
- **Personal workstations**: Home office, developer machines
- **Homelabs**: Self-hosted infrastructure on personal networks  
- **NAS devices**: Personal or small business network-attached storage
- **SSH-accessible servers**: Single-user remote systems

The operational model assumes:
1. **Operator = Data Owner**: User running tool owns or has authorized access to documents
2. **Local Filesystem**: All operations on local filesystem the operator has access to
3. **No Privilege Separation**: No multi-user scenarios where different privilege levels exist
4. **Single-User Systems**: Target environment is personal/individual use
5. **Read Access Prerequisite**: If user cannot read source files, analysis cannot proceed anyway

## Rationale

### Threat Model Implications

The threat model for this toolkit excludes scenarios where:
- The operator is malicious or untrusted
- Multiple users share the same system with different privilege levels
- The toolkit runs as a service accessed by remote users
- Error messages or logs might be visible to lesser-privileged users

**Threats In Scope**:
- External attackers exploiting vulnerabilities remotely
- Malicious input data (documents, templates, configuration)
- Malicious third-party plugins
- Supply chain attacks (compromised dependencies)
- Accidental data corruption or loss

**Threats Out of Scope**:
- Malicious operator intentionally misusing the toolkit
- Information disclosure to the operator via error messages/logs
- Operator privilege escalation (operator already has full access to their data)
- Multi-user access control and privilege separation

### Security Controls Focus

This constraint means security controls focus on:
- **Input Validation**: Protecting against malicious documents, templates, configuration
- **Plugin Sandboxing**: Isolating third-party code execution
- **Data Integrity**: Preventing corruption from malicious input
- **Dependency Verification**: Ensuring trusted tool chains

Security controls do NOT focus on:
- **Path Disclosure Prevention**: Operator has filesystem access already
- **Information Hiding from Operator**: Operator owns the data
- **Multi-User Access Controls**: Single-user environment
- **Privilege Separation**: Operator runs toolkit with their own privileges

## Impact

### On Architecture Decisions

1. **Error Messages**: Detailed error messages with full paths are acceptable and beneficial for troubleshooting. Path disclosure is NOT a security vulnerability in this context.

2. **Logging**: Security logs may include absolute paths, detailed stack traces in verbose mode, and internal implementation details because the operator is the intended audience.

3. **Access Controls**: No need for complex permission systems or user isolation. The toolkit operates with the operator's privileges.

4. **Information Disclosure**: Focus is on preventing data exfiltration (sending data outside the system), NOT on hiding information from the operator.

5. **Audit Trail**: Security logging is for operator troubleshooting and debugging, not for forensic evidence against a malicious operator.

### On Requirements

Requirements addressing multi-user scenarios or information hiding from the operator are out of scope:
- **req_0054** (Error Message Information Disclosure Prevention) - **REJECTED** based on this constraint
- Path sanitization in error messages is unnecessary complexity
- Detailed error messages improve usability without security risk

Requirements remain relevant when protecting against external threats:
- **req_0048** (Plugin Execution Sandboxing) - Valid: protects operator from malicious plugins
- **req_0051** (Security Logging) - Valid: helps operator detect attacks and debug issues
- Input validation requirements - Valid: protects operator from malicious input data

## Compliance Verification

To verify compliance with this constraint:

1. **Documentation Review**: Ensure all architecture documents reflect single-user, local-only operational model
2. **Requirements Analysis**: Reject requirements assuming multi-user scenarios or untrusted operators
3. **Threat Model Validation**: Confirm threat models exclude malicious operator scenarios
4. **Security Control Justification**: Ensure security controls address external threats, not operator trust

## Related Constraints

- **TC-0003** (User-Space Execution): Reinforces single-user model - toolkit runs with operator's privileges
- **TC-0002** (No Network Access): Reduces attack surface by eliminating remote attack vectors
- **TC-0006** (No External Service Dependencies): Ensures local-only operation

## Related Requirements

- **req_0054** (Error Message Information Disclosure Prevention) - **REJECTED** - See rejection rationale for detailed explanation of how this constraint invalidates the requirement
- **req_0048** (Plugin Execution Sandboxing) - **COMPATIBLE** - Protects operator from malicious third-party code
- **req_0051** (Security Logging) - **COMPATIBLE** - Provides operator with security visibility and troubleshooting data
