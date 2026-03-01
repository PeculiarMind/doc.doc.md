# Requirement: Path Traversal Prevention

- **ID:** REQ_SEC_005
- **Status:** FUNNEL
- **Created at:** 2026-02-25
- **Created by:** Security Agent
- **Source:** Security threat analysis (STRIDE/DREAD Scope 5), Quality Scenario QS-S01
- **Type:** Security Requirement
- **Priority:** CRITICAL
- **Related Threats:** Path Traversal (CWE-22), Arbitrary File Access, Information Disclosure

---

## Description

All file system operations must validate that file paths remain within intended directory boundaries to prevent unauthorized access to files outside the input/output directories.

### Specific Requirements

1. **Path Canonicalization**:
   - All paths must be canonicalized using `realpath` before use
   - Canonicalization must resolve symlinks, `.`, `..`, double slashes
   - Canonicalization failures must be treated as errors

2. **Boundary Enforcement**:
   - Input directory: All processed files must be within canonicalized input directory
   - Output directory: All generated files must be within canonicalized output directory
   - Template files: Must exist and be readable, but path not restricted
   - Plugin files: Must be within plugin directory

3. **Path Validation Rules**:
   - **Reject** paths containing `../` before canonicalization
   - **Reject** absolute paths in output file names (e.g., from metadata)
   - **Validate** symlinks: resolved target must remain within boundary
   - **Reject** paths that resolve to parent of boundary directory
   - **Reject** paths with null bytes or other special characters

4. **Output Path Construction**:
   - Output paths constructed from validated base + relative path
   - Relative paths derived from input structure (mirroring)
   - No user-controlled components in output paths except base output directory
   - Final output path validated before write

5. **Plugin Data Directory**:
   - Plugins given isolated temporary directory per execution
   - Plugin data directory created under system temp with restrictive permissions (700)
   - Cleaned up after plugin execution

### Security Controls

- **SC-001**: Input Path Validation - Canonicalize and validate boundaries
- **SC-007**: File Permission Enforcement - Respect Unix permissions

### Threat Scenarios

| Attack | Example | Expected Behavior |
|--------|---------|-------------------|
| Direct traversal | `--input-directory ../../../etc` | Rejected: path outside allowed area |
| Symlink escape | Input dir contains symlink to `/etc/passwd` | Validated: symlink target must be within input dir |
| Output traversal | Output path becomes `../../../etc/passwd.md` | Rejected: output outside output directory |
| Absolute path in metadata | File name contains `/etc/passwd` | Sanitized: absolute path component removed |
| Null byte injection | Path contains `\0` character | Rejected: invalid path character |
| Double encoding | Path contains encoded traversal like `%2e%2e%2f` | Rejected: resolved during canonicalization |

### Test Requirements

**Functional Tests**:
- Process files in nested input directory structure
- Symlinks within input directory work correctly
- Output mirroring preserves directory structure
- Template files loaded from various locations

**Security Tests**:
- `--input-directory ../../../etc` → Rejected
- `--output-directory ../../../tmp` → Rejected  
- Input dir contains symlink to `/etc` → Symlink target validated
- Input dir contains `../../escape.txt` → File ignored or rejected
- File name is `../../etc/passwd` → Sanitized in output path
- File name contains null byte → Rejected
- File path is double-encoded traversal → Detected after canonicalization
- Very long paths (> PATH_MAX) → Handled gracefully
- Paths with special characters → Validated correctly

### Acceptance Criteria

- [ ] All file paths canonicalized before use
- [ ] Path traversal attempts detected and rejected
- [ ] Symlinks validated to remain within boundaries
- [ ] Output paths verified before write operations
- [ ] Boundary validation has 100% unit test coverage
- [ ] Security test suite passes (no unauthorized access)
- [ ] Clear error messages for path violations
- [ ] No false positives for legitimate nested directories

### Path Validation Functions

**Canonicalize Path**:
```bash
canonicalize_path() {
    local path="$1"
    local canonical
    
    # Reject null bytes and other suspicious characters
    if [[ "$path" =~ $'\0' ]] || [[ "$path" =~ [[:cntrl:]] ]]; then
        die "Invalid characters in path: $path"
    fi
    
    # Canonicalize (resolves symlinks, .., ., etc.)
    canonical=$(realpath -m "$path" 2>/dev/null) || {
        die "Cannot canonicalize path: $path"
    }
    
    echo "$canonical"
}
```

**Validate Within Boundary**:
```bash
validate_within_boundary() {
    local base="$1"
    local target="$2"
    local base_canonical target_canonical
    
    # Canonicalize both paths
    base_canonical=$(canonicalize_path "$base")
    target_canonical=$(canonicalize_path "$target")
    
    # Check if target starts with base path
    case "$target_canonical" in
        "$base_canonical"|"$base_canonical/"*)
            return 0  # Within boundary
            ;;
        *)
            die "Path traversal detected: $target outside $base"
            ;;
    esac
}
```

**Safe Output Path Construction**:
```bash
construct_output_path() {
    local input_dir="$1"
    local input_file="$2"
    local output_dir="$3"
    local relative_path output_path
    
    # Get relative path from input dir to input file
    relative_path="${input_file#$input_dir/}"
    
    # Construct output path
    output_path="$output_dir/$relative_path.md"
    
    # Validate output path remains within output directory
    validate_within_boundary "$output_dir" "$output_path"
    
    echo "$output_path"
}
```

### Symlink Handling

Symlinks require special consideration:

1. **Within input directory**: Allowed if target is also within input directory
2. **Pointing outside**: Rejected with clear error
3. **Circular symlinks**: Detected during canonicalization (realpath handles this)
4. **Plugin attempts**: Plugins should not be able to create symlinks escaping boundaries

```bash
validate_symlink() {
    local symlink="$1"
    local boundary="$2"
    local target
    
    if [[ -L "$symlink" ]]; then
        # Resolve symlink target
        target=$(readlink -f "$symlink")
        
        # Validate target is within boundary
        validate_within_boundary "$boundary" "$target"
    fi
}
```

### Related Requirements

- REQ_SEC_001 (Input Validation and Sanitization) - includes path validation
- REQ_0009 (Process Command) - processes files safely
- REQ_0013 (Directory Structure Mirroring) - mirrors paths safely

### Risk if Not Implemented

**Risk Level**: MEDIUM (3.13)

**STRIDE Score**: 2.67 | **DREAD Score**: 3.6

Without path traversal prevention:
- **Arbitrary File Read**: Attacker could read sensitive files (e.g., `/etc/passwd`, SSH keys)
- **Arbitrary File Write**: Attacker could overwrite system files
- **Information Disclosure**: Reveal system structure and file locations
- **Privilege Escalation**: Write to startup scripts or cron jobs
- **Data Corruption**: Overwrite user data outside intended scope

Path traversal is OWASP Top 10 (A01:2021) and consistently appears in vulnerability reports. Well-understood by attackers and easily exploited.

### Implementation Notes

**Defense in Depth**:
1. **Validation on input**: Reject obvious traversal attempts using regex
2. **Canonicalization**: Resolve all relative paths and symlinks
3. **Boundary check**: Ensure canonical path within allowed boundary
4. **Final validation**: Re-check before filesystem operation
5. **Unix permissions**: Rely on OS permissions as final barrier

**Performance Consideration**:
Path canonicalization (realpath) involves filesystem operations and can be slow for many files. Consider:
- Caching canonicalized base directories
- Early rejection of obvious violations before canonicalization
- Batch validation where possible

**Platform Differences**:
- Linux: `realpath` available in GNU coreutils
- macOS: `realpath` may require installation (use `python -c "import os; print(os.path.realpath('$path'))"` as fallback)
- Ensure cross-platform compatibility

### References

- Security Concept Section 5.5 (Scope 5: File System Operations)
- Quality Requirements: QS-S01 (Path Traversal Attempt)
- OWASP Top 10 2021: A01 - Broken Access Control
- CWE-22: Improper Limitation of a Pathname to a Restricted Directory ('Path Traversal')
- CWE-59: Improper Link Resolution Before File Access ('Link Following')
