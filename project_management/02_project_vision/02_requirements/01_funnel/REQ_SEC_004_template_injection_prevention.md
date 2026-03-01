# Requirement: Template Injection Prevention

- **ID:** REQ_SEC_004
- **Status:** FUNNEL
- **Created at:** 2026-02-25
- **Created by:** Security Agent
- **Source:** Security threat analysis (STRIDE/DREAD Scope 4), Risk R-T07
- **Type:** Security Requirement
- **Priority:** HIGH
- **Related Threats:** Template Injection, Command Execution, Code Injection

---

> **FUNNEL STATUS NOTE:**  
> This requirement is pending formal review and approval by PeculiarMind. It is referenced in the architecture vision for planning purposes but is not yet formally accepted into the project scope.

---

## Description

Template processing must prevent injection attacks by using safe string substitution mechanisms that cannot execute arbitrary code or shell commands through template variables or template content.

### Specific Requirements

1. **Safe Substitution Only**:
   - Template variables must be replaced using safe string substitution (e.g., `sed`, `awk`, parameter expansion)
   - **NEVER** use `eval`, `exec`, or shell command expansion on template content
   - **NEVER** use shell expansion (`$()`, ``` `` ```, `${}`) in template processing

2. **Variable Escaping**:
   - All template variable values must be escaped before substitution
   - Special shell characters must be neutralized: `` ` `` `$` `\` `"` `'` `;` `|` `&` `>` `<` `(` `)` `{` `}`
   - Escaping must prevent both command execution and template breakout

3. **Template Syntax Validation**:
   - Template files must be validated for correct syntax before processing
   - Variable placeholders must match pattern `{{variable_name}}`
   - Invalid variable references should be handled gracefully (empty string or warning)

4. **Variable Naming**:
   - Variable names must match `[a-zA-Z0-9_]+` pattern
   - Reserved variable names documented and enforced
   - No user-controlled variable names (only predefined set)

5. **Read-Only Variables**:
   - Template variables are read-only (values from plugins/system, not user input)
   - Variables populated from trusted sources only
   - No dynamic variable creation from template content

### Security Controls

- **SC-005**: Template Variable Escaping - Safe string substitution only
- **SC-006**: Error Message Sanitization - No template errors reveal internals

### Supported Template Variables

| Variable | Source | Sanitization | Example |
|----------|--------|--------------|---------|
| `{{file_name}}` | File system | Escape special chars | `report.pdf` |
| `{{file_path}}` | File system | Escape special chars | `/input/docs/report.pdf` |
| `{{file_size}}` | stat plugin | Integer only | `1048576` |
| `{{file_size_human}}` | stat plugin | Alphanumeric + units | `1.0 MB` |
| `{{mime_type}}` | file plugin | MIME format validation | `application/pdf` |
| `{{mime_description}}` | file plugin | Escape special chars | `PDF document` |
| `{{modified_date}}` | stat plugin | Date format validation | `2024-02-25 14:30:00` |
| `{{created_date}}` | stat plugin | Date format validation | `2024-02-20 09:15:00` |
| `{{permissions}}` | stat plugin | Permission format | `rw-r--r--` |
| `{{owner}}` | stat plugin | Alphanumeric + colon | `user:group` |
| `{{generation_timestamp}}` | System | Date format validation | `2024-02-25 15:00:00` |

### Template Processing Rules

1. **No User-Provided Variables**: Only predefined variables allowed
2. **No Nested Substitution**: Variables substituted in single pass
3. **No Template Includes**: No dynamic template loading
4. **No Conditional Logic**: Templates are static with variable placeholders
5. **Size Limits**: Template file max 100KB, processed output max 1MB

### Test Requirements

**Functional Tests**:
- All supported variables substitute correctly
- Unknown variables handled gracefully (empty string or warning)
- Special characters in file names render correctly
- Unicode in file paths handled correctly

**Security Tests**:
- Command injection via file name: `file_name = "test$(rm -rf /).pdf"`
- Shell expansion: `file_name = "test\`whoami\`.pdf"`
- Variable substitution: `file_name = "test${PATH}.pdf"`
- Template injection: template contains `{{$(whoami)}}`
- Special chars: file names with `;`, `|`, `&`, `>`, `<`, `$`, `` ` ``
- Path traversal in template variable: `file_path = "../../../etc/passwd"`
- Large variables: 100KB+ file names (DoS prevention)

### Acceptance Criteria

- [ ] Template processing uses safe substitution only (no eval/exec)
- [ ] All template variables escaped before substitution
- [ ] Command injection attempts fail security tests
- [ ] Template breakout attempts fail security tests
- [ ] Unknown variables handled without crashes
- [ ] Documentation clearly states safe template authoring practices
- [ ] Security test suite passes with 100% coverage
- [ ] Code review confirms no use of eval/exec/shell expansion

### Safe Template Processing Examples

**GOOD - Safe sed substitution**:
```bash
process_template() {
    local template="$1"
    local file_name="$2"
    
    # Escape special characters for sed
    file_name=$(printf '%s\n' "$file_name" | sed 's/[&/\]/\\&/g; s/`/\\`/g; s/\$/\\$/g')
    
    # Safe substitution (no eval)
    sed "s/{{file_name}}/$file_name/g" "$template"
}
```

**GOOD - Safe awk substitution**:
```bash
process_template_awk() {
    local template="$1"
    local file_name="$2"
    
    awk -v fname="$file_name" '{gsub(/{{file_name}}/, fname); print}' "$template"
}
```

**BAD - VULNERABLE**:
```bash
# NEVER DO THIS - Command injection vulnerability
process_template_bad() {
    local template="$1"
    eval "echo \"$(cat "$template")\""  # DANGEROUS!
}

# NEVER DO THIS - Shell expansion vulnerability  
process_template_bad2() {
    local template="$1"
    local file_name="$2"
    echo "Filename: $file_name" >> output.md  # If file_name contains $(command)
}
```

### Safe Template Authoring Documentation

Template documentation must include:

1. **What variables are available**: Complete list with examples
2. **What to avoid**: No shell syntax, no eval constructs
3. **How substitution works**: Variables replaced literally, no execution
4. **Security note**: Templates from untrusted sources could expose metadata
5. **Examples**: Safe template patterns

Example warning text:
```
⚠️ Security Note: Template variables contain metadata from processed files.
If you process sensitive files, ensure templates don't expose information
you want to keep confidential. All variables are replaced as literal text
and cannot execute code.
```

### Related Requirements

- REQ_0009 (Process Command) - uses template processing
- REQ_SEC_006 (Error Information Disclosure) - template errors must be safe

### Risk if Not Implemented

**Risk Level**: MEDIUM (3.05)

**STRIDE Score**: 2.5 | **DREAD Score**: 3.6 | **Risk**: R-T07

Without template injection prevention:
- **Arbitrary Code Execution**: Malicious file names could execute commands
- **Data Exfiltration**: Template injection could leak sensitive data
- **System Compromise**: Command execution with user's privileges
- **Difficult Detection**: Injection via file names hard to identify

Template injection is well-documented (OWASP template injection, SSTI) and easily exploitable if not properly mitigated.

### Implementation Notes

Key principle: Treat all template variable values as **untrusted data** even though they come from filesystem metadata. A malicious user could craft file names specifically to exploit template vulnerabilities.

Recommended approach:
1. Parse template to identify variables
2. Escape all variable values
3. Use safe substitution (sed/awk with escaped values)
4. Never pass template content to eval or shell expansion

Consider creating a whitelist of allowed characters for certain variables (e.g., dates should only contain 0-9, :, -, space).

### References

- Security Concept Section 5.4 (Scope 4: Template Processing)
- Architecture Vision: 08_concepts.md - Template Processing
- OWASP: Server-Side Template Injection
- CWE-94: Improper Control of Generation of Code (Code Injection)
- OWASP: Command Injection
