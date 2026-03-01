# Requirement: Filter Logic Correctness and Security

- **ID:** REQ_SEC_002
- **Status:** ACCEPTED
- **Created at:** 2026-02-25
- **Created by:** Security Agent
- **Source:** Security threat analysis (STRIDE/DREAD Scope 2)
- **Type:** Security + Functional Requirement
- **Priority:** HIGH
- **Related Threats:** Filter Bypass, Information Disclosure, DoS via Complex Patterns

---

## Description

The file filtering logic must correctly implement the documented AND/OR semantics and prevent filter bypass vulnerabilities that could expose unintended files or cause denial of service.

### Specific Requirements

1. **Correct Filter Implementation**:
   - Within single `--include` parameter: values ORed together
   - Between multiple `--include` parameters: ANDed together
   - Within single `--exclude` parameter: values ORed together
   - Between multiple `--exclude` parameters: ANDed together
   - Final result: include AND NOT exclude

2. **Filter Type Support**:
   - File extensions (`.pdf`, `.txt`) - exact suffix match
   - Glob patterns (`**/2024/**`) - fnmatch or equivalent
   - MIME types (`application/pdf`) - exact match against file command output

3. **Security Validations**:
   - Glob patterns must not cause regex DoS
   - Filter evaluation must timeout after reasonable period
   - Complex filter combinations must not cause resource exhaustion
   - Filter logic must not allow escape from input directory

4. **Comprehensive Testing**:
   - All 8 example cases from project goals must pass
   - Edge cases: empty filters, single criterion, all three types combined
   - Adversarial cases: malicious globs, nested patterns, symlinks
   - Performance: large filter sets, complex patterns

### Security Controls

- **SC-002**: Filter Syntax Validation - Validate patterns, implement timeout
- **SC-009**: Resource Limits - Timeout for complex filter evaluation (future)

### Test Requirements

**Functional Test Cases** (from project goals):
1. `/path/2024/notes.txt` with `.txt` + `**/2024/**` → ✅ Include
2. `/path/2023/notes.txt` with `.txt` + `**/2024/**` → ❌ Exclude
3. `/path/2024/data.csv` with `.txt,.pdf` + `**/2024/**` → ❌ Exclude
4. `/path/2024/temp/debug.log` with `.txt,.pdf` + `**/2024/**`, exclude `.log` + `**/temp/**` → ❌ Exclude
5. `/path/2024/temp/notes.txt` with exclude `.log` + `**/temp/**` → ✅ Include
6. All combinations from filtering examples table

**Security Test Cases**:
- Regex DoS: `--include "(a+)+"` with large input
- Complex glob: `--include "**/**/**/**/**/**/**/**/**/**/**/**/**"`
- Filter escape: `--include "../../../*"`
- Symlink handling: symlink pointing outside input directory
- MIME type validation: invalid MIME format strings
- Large filter count: 100+ include/exclude parameters
- Performance: 10,000 files with complex filters (< 10ms per file)

### Acceptance Criteria

- [ ] All documented filter examples pass functional tests
- [ ] Filter logic matches specification exactly
- [ ] Complex patterns timeout within 5 seconds per file
- [ ] Malicious glob patterns detected and rejected
- [ ] Filter bypass attempts fail security tests
- [ ] Unit test coverage ≥ 95% for filter.py
- [ ] Performance tests pass (< 10ms per file overhead)
- [ ] Security test suite passes (no bypass, no DoS)

### Related Requirements

- REQ_0009 (Process Command) - implements this filtering logic
- REQ_SEC_001 (Input Validation) - validates filter syntax

### Risk if Not Implemented

**Risk Level**: MEDIUM (3.01)

**STRIDE Score**: 2.83 | **DREAD Score**: 3.2

Without correct and secure filter implementation:
- **Information Disclosure**: Filter bypass could expose unintended sensitive files
- **Denial of Service**: Complex patterns could hang processing
- **Incorrect Processing**: Bug in logic processes wrong files
- **User Trust**: Incorrect filtering undermines tool reliability

### Implementation Notes

The filter engine should:
1. Validate all filter patterns before evaluation
2. Use safe pattern matching (fnmatch, not regex)
3. Implement timeout mechanism for complex evaluations
4. Cache MIME type results to improve performance
5. Process filters in order: validate → canonicalize → evaluate

Example filter validation:
```python
def validate_glob_pattern(pattern):
    """Validate glob pattern is safe to evaluate."""
    # Check for excessive wildcards
    if pattern.count('*') > 20:
        raise ValueError("Glob pattern too complex")
    
    # Check for path escape attempts
    if '..' in pattern or pattern.startswith('/'):
        raise ValueError("Glob pattern contains path traversal")
    
    return True

def evaluate_filter_with_timeout(file_path, criteria, timeout=5):
    """Evaluate filter with timeout protection."""
    import signal
    
    def timeout_handler(signum, frame):
        raise TimeoutError("Filter evaluation timeout")
    
    signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(timeout)
    
    try:
        result = matches_criterion(file_path, criteria)
        signal.alarm(0)  # Cancel alarm
        return result
    except TimeoutError:
        log_error(f"Filter timeout: {criteria}")
        return False
```

### References

- Project Goals: Filter Logic Examples
- Architecture Vision: 08_concepts.md - Filtering Logic
- Security Concept Section 5.2 (Scope 2: File Filtering)
- CWE-400: Uncontrolled Resource Consumption
- OWASP: Regular Expression Denial of Service (ReDoS)
