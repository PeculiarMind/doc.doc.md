# Requirement: TOCTOU Mitigation Strategy

**ID**: req_0063  
**Status**: Funnel  
**Priority**: MEDIUM  
**Created**: 2026-02-11  
**Source**: Security Review Agent (Finding-002)

## Description

The system must mitigate Time-of-Check Time-of-Use (TOCTOU) race conditions in workspace permission validation where an attacker could change file/directory permissions between security checks and file operations.

## Rationale

**Security Finding**: FINDING-002 identified TOCTOU vulnerability in workspace security:
- `validate_workspace_permissions()` checks permissions with `stat`
- File operations occur later in caller code
- Attacker with local access could change permissions between check and use
- Could expose confidential workspace data on multi-user systems

**Risk Assessment**:
- **DREAD Likelihood**: 6.0 (Damage=7, Reproducibility=6, Exploitability=5, Affected=8, Discoverability=4)
- **STRIDE Impact**: Tampering=8, Information Disclosure=7
- **Risk Score**: 6.0 × 8 × 3 = **144 (MEDIUM, upgrade to HIGH)**
- **CWE**: CWE-367 (Time-of-Check Time-of-Use Race Condition)

## Requirements

### Functional Requirements

**FR-063-01**: The system MUST enforce permissions immediately before sensitive file operations, not just during initial validation.

**FR-063-02**: Workspace file write operations MUST use atomic file creation patterns:
- Open with `O_CREAT | O_EXCL` flags (via mktemp)
- Write to temporary file
- Verify integrity
- Atomic rename to final location

**FR-063-03**: The system MUST provide wrapper functions that combine permission enforcement and file operations:
- `secure_write_workspace_file(path, data)` - hardens permissions before write
- `secure_read_workspace_file(path)` - verifies permissions before read
- `secure_mkdir_workspace(path)` - creates directory with correct permissions atomically

**FR-063-04**: Permission hardening operations MUST be logged.

### Security Requirements

**SR-063-01**: Sensitive file operations MUST occur within minimal time window after permission verification (< 100ms).

**SR-063-02**: The system MUST detect permission changes between operations.

**SR-063-03**: File descriptor-based operations SHOULD be used where possible.

**SR-063-04**: On multi-user systems, workspace operations SHOULD use file locks.

## Implementation Notes

Secure write wrapper using atomic pattern to minimize TOCTOU window.

## Test Cases

Race condition simulation and atomic write integrity tests required.

## Dependencies

- **Blocks**: v1.0 documentation, v1.1 implementation
- **Related**: req_0050, req_0059

## Review Status

- **Created By**: Security Review Agent
- **Status**: Funnel

---

**Notes**: Addresses HIGH-priority gap. Documentation v1.0, implementation v1.1.
