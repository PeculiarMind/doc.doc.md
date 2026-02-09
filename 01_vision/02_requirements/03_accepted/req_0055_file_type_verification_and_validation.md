# Requirement: File Type Verification and Validation

**ID**: req_0055

## Status
State: Accepted  
Created: 2026-02-09  
Last Updated: 2026-02-09

## Overview
The system shall verify and validate file types by accepting only regular files, validating symlink targets, rejecting special files (devices, FIFOs, sockets), and enforcing file size limits to prevent abuse through malicious or unexpected file types.

## Description
File type validation prevents security vulnerabilities arising from unexpected file types. Regular files are predictable and safe to process, but special file types (devices, named pipes, sockets) can cause blocking I/O, resource exhaustion, or privilege escalation. Symbolic links may point outside workspace boundaries, enabling path traversal attacks. Overly large files cause denial-of-service through memory or disk exhaustion. The system must validate file type using `stat` or equivalent, verify symlink targets are within allowed paths, reject special files before processing, and enforce maximum file size limits. File type validation is a defense-in-depth control preventing unexpected behavior from filesystem quirks.

## Motivation
From Security Principles:
- Defense-in-Depth: validate assumptions about file system objects
- Fail-Secure: reject unexpected file types rather than process them

From Security Concept:
- Filesystem operations on special files can cause unexpected behavior
- Symlinks are a common path traversal vector

From UNIX Security:
- Special file types (devices, FIFOs, sockets) have non-file semantics
- Opening special files can block indefinitely or have side effects

Without file type verification, the system may attempt to process device files (`/dev/random`, `/dev/zero`), causing resource exhaustion, or follow symlinks outside workspace, enabling path traversal.

## Category
- Type: Non-Functional (Security)
- Priority: Medium

## STRIDE Threat Analysis
- **Denial of Service**: Device files or large files cause resource exhaustion
- **Tampering**: Symlinks enable path traversal to modify unauthorized files
- **Information Disclosure**: Symlinks enable reading files outside workspace

## Risk Assessment (DREAD)
- **Damage**: 6/10 - Can cause DoS, path traversal; not direct code execution
- **Reproducibility**: 9/10 - Reproducible with crafted filesystem entries
- **Exploitability**: 5/10 - Requires creating special files or symlinks in workspace
- **Affected Users**: 7/10 - Users processing untrusted workspaces or shared filesystems
- **Discoverability**: 6/10 - Security researchers testing filesystem handling

**DREAD Likelihood**: (6 + 9 + 5 + 7 + 6) / 5 = **6.6**  
**Risk Score**: 6.6 × 7 (DoS) × 2 (Internal) = **92 (MEDIUM)**

## Acceptance Criteria

### Regular Files Only
- [ ] File type verified using `stat` command or equivalent before processing
- [ ] Only regular files (type `-` in `ls -l`) accepted for processing
- [ ] Special file types rejected: block devices (`b`), character devices (`c`)
- [ ] Named pipes/FIFOs rejected (type `p`)
- [ ] Sockets rejected (type `s`)
- [ ] Directories handled separately (not as general files to process)
- [ ] File type rejection logged with file path and detected type
- [ ] Error message explains which file types acceptable

### Symlink Validation
- [ ] Symbolic links detected using file type check or `readlink`
- [ ] Symlink targets resolved to canonical absolute path
- [ ] Symlink target verified to be within workspace boundary (no `..` escape)
- [ ] Symlink target verified to be regular file (not device, FIFO, etc.)
- [ ] Circular symlinks detected (prevent infinite loop)
- [ ] Maximum symlink depth enforced (≤ 5 symlinks in resolution chain)
- [ ] Symlink validation failure prevents file processing (fail closed)
- [ ] Symlink policy configurable: allow, deny, or follow-with-validation (default: follow-with-validation)

### Special File Rejection
- [ ] Device files explicitly rejected: `/dev/*`, character/block devices
- [ ] FIFO/named pipes rejected (can block indefinitely on open)
- [ ] Unix domain sockets rejected (have non-file semantics)
- [ ] Attempting to process rejected types logs security event (potential attack)
- [ ] Special file rejection tested with mock device files in test suite
- [ ] Clear error message explains why special file rejected
- [ ] No fallback or workaround for special files (hard rejection)

### Size Limits
- [ ] Maximum file size enforced before reading (default: 100MB)
- [ ] File size checked using `stat` before opening (not after reading entire file)
- [ ] Size limit configurable per file type or globally
- [ ] Oversized files rejected with error message including size and limit
- [ ] Size limit applies to symlink target size (not link size)
- [ ] Cumulative size limit for workspace processing (default: 10GB total)
- [ ] Size limit exceeded logged to security audit log
- [ ] Streaming processing for large files (if size limit relaxed explicitly)

### Validation Before Processing
- [ ] All file type validation performed before opening file
- [ ] Validation failures prevent file open (no partial reads)
- [ ] File type validation failures do not crash or halt processing of other files
- [ ] Validation errors reported to user with file path and reason
- [ ] Multiple validation failures batched and reported together (not one at a time)
- [ ] Validation bypass not possible (no flag or config to skip file type checks)

### Edge Cases
- [ ] Empty files (0 bytes) handled gracefully (not rejected, but not processed)
- [ ] Files with unusual permissions (no-read, no-write) detected and reported
- [ ] Files with unusual ownership (owned by root, foreign UID) handled appropriately
- [ ] Files with null bytes in names handled safely (if filesystem allows)
- [ ] Case-insensitive filesystems considered (no reliance on case for security)
- [ ] Files with unusual timestamps (future dates, epoch 0) accepted

## Related Requirements
- req_0038 (Input Validation and Sanitization) - complementary input validation
- req_0047 (Plugin Descriptor Validation) - plugin descriptor is a file requiring validation
- req_0050 (Workspace Integrity Verification) - workspace files validated
- req_0052 (Secure Defaults and Configuration Hardening) - size limit defaults
- req_0056 (Security Testing Requirements) - test special file handling

## Transition History
- [2026-02-09] Created by Requirements Engineer Agent based on security review analysis
  -- Comment: Prevents DoS and path traversal via filesystem edge cases (Risk Score: 92)
- [2026-02-09] Moved to analyze for detailed analysis
- [2026-02-09] Moved to accepted by user - ready for implementation
