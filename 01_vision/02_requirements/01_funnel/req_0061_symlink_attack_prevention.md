# Requirement: Symlink Attack Prevention

**ID**: req_0061  
**Status**: Funnel  
**Priority**: HIGH  
**Created**: 2026-02-11  
**Source**: Security Review Agent (Finding-004)

## Description

The system must detect and safely handle symbolic links during directory scanning to prevent information disclosure attacks where attackers create symlinks pointing outside the source directory.

## Rationale

**Security Finding**: FINDING-004 identified that the scanner component processes symlinks without validating their targets, allowing potential information disclosure:
- Attacker creates symlink in source directory pointing to `/etc/passwd`
- Scanner follows symlink and processes sensitive file
- Content may be exposed in reports or workspace

**Risk Assessment**:
- **DREAD Likelihood**: 7.6 (Damage=6, Reproducibility=9, Exploitability=7, Affected=10, Discoverability=6)
- **STRIDE Impact**: Information Disclosure = 8
- **Risk Score**: 7.6 × 8 × 2 = **122 (MEDIUM)**
- **CWE**: CWE-59 (Improper Link Resolution Before File Access)

## Requirements

### Functional Requirements

**FR-061-01**: The scanner MUST detect symbolic links during directory traversal.

**FR-061-02**: For each symlink encountered, the system MUST resolve its canonical target path using `realpath` or equivalent.

**FR-061-03**: The system MUST validate that symlink targets are within the source directory tree (prefix check).

**FR-061-04**: The system MUST provide a configuration option to control symlink behavior:
- `follow`: Follow symlinks after validation (default)
- `skip`: Skip symlinks entirely  
- `error`: Treat symlinks as errors

**FR-061-05**: The system MUST detect and reject symlink loops (A→B→A).

**FR-061-06**: The system MUST log all symlink traversal attempts with:
- Link path
- Target path  
- Action taken (followed/skipped/rejected)
- Reason if rejected

### Security Requirements

**SR-061-01**: Symlink targets pointing outside the source directory MUST be rejected with ERROR log.

**SR-061-02**: Symlink chains (A→B→C) MUST be fully resolved and validated.

**SR-061-03**: Dangling symlinks (broken links) MUST be handled gracefully (skip with WARN log).

**SR-061-04**: The system MUST resist TOCTOU attacks where symlink targets change between check and use (atomic resolution).

## Acceptance Criteria

1. ✅ Symlink detection implemented in scanner component
2. ✅ Target validation against source directory prefix
3. ✅ Configuration option for symlink handling behavior
4. ✅ Loop detection prevents infinite traversal
5. ✅ Security test suite passes:
   - Symlink to `/etc/passwd` rejected
   - Symlink to parent directory rejected (`../../../`)
   - Symlink loop detected and rejected
   - Symlink chain validated correctly
   - Dangling symlink skipped gracefully
   - Valid in-tree symlinks followed correctly
6. ✅ Logging captures all symlink events
7. ✅ Documentation updated (security scope, user guide)

## Test Cases

### Test-061-01: Symlink to System File
```bash
cd /tmp/source
ln -s /etc/passwd evil.txt
./doc.doc.sh -d /tmp/source -w /tmp/workspace -t /tmp/output
# Expected: ERROR logged, file skipped, no /etc/passwd content in output
```

### Test-061-02: Symlink to Parent Directory
```bash
ln -s ../../../ escape_link
./doc.doc.sh -d /tmp/source ...
# Expected: ERROR logged, link rejected
```

### Test-061-03: Symlink Loop
```bash
ln -s link_b link_a
ln -s link_a link_b
./doc.doc.sh -d /tmp/source ...
# Expected: Loop detected, ERROR logged
```

### Test-061-04: Valid In-Tree Symlink
```bash
ln -s subdir/valid_file.txt alias.txt
./doc.doc.sh -d /tmp/source ...
# Expected: Link followed, file processed normally
```

### Test-061-05: Dangling Symlink
```bash
ln -s /tmp/nonexistent.txt broken.txt
./doc.doc.sh -d /tmp/source ...
# Expected: WARN logged, link skipped
```

## Implementation Notes

### Scanner Component Changes
```bash
# In scanner.sh, add symlink checking function
check_symlink_safe() {
  local link_path="$1"
  local source_dir="$2"
  
  if [[ ! -L "$link_path" ]]; then
    return 0  # Not a symlink
  fi
  
  local target
  target=$(readlink -f "$link_path" 2>/dev/null)
  
  if [[ -z "$target" ]]; then
    log "WARN" "SCANNER" "Dangling symlink: $link_path"
    return 1
  fi
  
  # Validate target is within source directory
  if [[ "$target" != "$source_dir"* ]]; then
    log "ERROR" "SCANNER" "Symlink escapes source directory: $link_path -> $target"
    return 1
  fi
  
  return 0
}
```

### Configuration
```bash
# In constants.sh
SYMLINK_POLICY="${SYMLINK_POLICY:-follow}"  # follow|skip|error
```

## Dependencies

- **Requires**: `readlink` command with `-f` flag (canonical path resolution)
- **Blocks**: v1.1 release (security hardening milestone)
- **Related**: req_0047 (Path Traversal Prevention), FINDING-004

## Security Scope Updates

Update `02_runtime_application_security.md`:
- Add symlink attack threat model
- Document symlink handling controls
- Add STRIDE analysis for symlink interface

## Traceability

- **Security Finding**: FINDING-004 (Medium Priority, Risk=122)
- **Security Scope**: scope_runtime_app_001
- **Related Requirements**: req_0047 (Path Traversal Prevention)
- **Feature**: Enhancement to scanner component (Feature 0006)

## Review Status

- **Created By**: Security Review Agent
- **Reviewed By**: (Pending)
- **Approved By**: (Pending)
- **Status**: Funnel (Requires analysis and acceptance)

---

**Notes**: This requirement addresses a MEDIUM-priority security gap identified during comprehensive security review. Implementation target is v1.1 release.
