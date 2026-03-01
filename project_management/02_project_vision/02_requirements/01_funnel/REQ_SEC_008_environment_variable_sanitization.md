# Requirement: Environment Variable Sanitization

- **ID:** REQ_SEC_008
- **Status:** FUNNEL
- **Created at:** 2026-02-25
- **Created by:** Security Agent
- **Source:** Security threat analysis (STRIDE/DREAD Scope 3)
- **Type:** Security Requirement
- **Priority:** CRITICAL
- **Related Threats:** Command Injection, Plugin Exploitation, Arbitrary Code Execution

---

## Description

All environment variables passed to plugins must be sanitized to prevent command injection and ensure plugins cannot exploit environment variable values for malicious purposes.

### Specific Requirements

1. **Environment Variables Passed to Plugins**:
   - `FILE_PATH`: Absolute path to file being processed
   - `OUTPUT_DIR`: Directory for generated output
   - `PLUGIN_DATA_DIR`: Temporary directory for plugin-specific data
   - Additional variables as needed (documented in plugin interface)

2. **Sanitization Requirements**:
   - All special shell characters must be escaped or quoted
   - Variables must be validated before being set
   - No user-controlled variable names (only predefined set)
   - Plugin execution must use clean environment (`env -i` or equivalent)

3. **Special Character Handling**:
   Characters requiring escaping or handling:
   - Shell metacharacters: `` ` `` `$` `\` `"` `'` `;` `|` `&` `>` `<` `(` `)` `{` `}`
   - Whitespace: spaces, tabs, newlines
   - Wildcards: `*` `?` `[` `]`
   - Null bytes: `\0`

4. **Plugin Execution Environment**:
   - Use minimal, controlled environment for plugin execution
   - Unset potentially dangerous variables (e.g., `LD_PRELOAD`, `LD_LIBRARY_PATH`)
   - Set only necessary variables explicitly
   - Consider using `env -i` to start with clean environment

### Security Controls

- **SC-004**: Environment Variable Sanitization - Escape special characters
- **SC-008**: Plugin Execution Isolation - Controlled environment

### Threat Scenarios

| Attack | Example | Expected Behavior |
|--------|---------|-------------------|
| Command injection via FILE_PATH | `FILE_PATH='test.pdf; rm -rf /'` | Escaped: plugin sees literal string, no command execution |
| Shell expansion via $() | `FILE_PATH='$(whoami).pdf'` | Escaped: `$` neutralized, no substitution occurs |
| Backtick execution | ``FILE_PATH='test`whoami`.pdf'`` | Escaped: backticks treated as literal characters |
| Variable substitution | `FILE_PATH='test${HOME}.pdf'` | Escaped: `${}` treated as literal string |
| Path traversal | `OUTPUT_DIR='../../../etc'` | Validated before setting (separate requirement REQ_SEC_005) |

### Test Requirements

**Functional Tests**:
- Plugins receive correct FILE_PATH values
- Special characters in file names handled correctly
- Plugins execute with required environment variables
- Output written to correct OUTPUT_DIR

**Security Tests**:
- File name with command substitution: `test$(whoami).pdf`
- File name with backticks: ``test`id`.pdf``
- File name with variables: `test${PATH}.pdf`
- File name with semicolons: `test;whoami.pdf`
- File name with pipes: `test|cat /etc/passwd.pdf`
- File name with redirects: `test>malicious.pdf`
- File name with newlines: `test\nrm -rf /.pdf`
- File name with null bytes: `test\0.pdf`
- Very long file paths (buffer overflow)
- Unicode and non-ASCII characters in paths

### Acceptance Criteria

- [ ] All environment variables sanitized before plugin execution
- [ ] Plugins execute with clean, minimal environment
- [ ] Special characters in file paths do not cause command execution
- [ ] Command injection tests fail (no execution occurs)
- [ ] Plugins receive properly escaped values
- [ ] Security test suite passes with 100% coverage
- [ ] No false positives for legitimate file names

### Sanitization Implementation

**Approach 1: Proper Quoting (Recommended)**
```bash
execute_plugin() {
    local plugin_cmd="$1"
    local file_path="$2"
    local output_dir="$3"
    local plugin_data_dir="$4"
    
    # Execute with clean environment and properly quoted variables
    env -i \
        PATH="/usr/local/bin:/usr/bin:/bin" \
        FILE_PATH="$file_path" \
        OUTPUT_DIR="$output_dir" \
        PLUGIN_DATA_DIR="$plugin_data_dir" \
        /bin/bash -c "$plugin_cmd"
}
```

**Approach 2: Explicit Escaping**
```bash
escape_for_env() {
    local value="$1"
    
    # Escape special characters for shell
    # Note: Single quotes prevent all expansion
    printf '%s' "$value" | sed "s/'/'\\\\''/g"
    # Result wrapped in single quotes when used
}

execute_plugin_escaped() {
    local plugin_cmd="$1"
    local file_path="$2"
    
    # Escape the file path
    local escaped_path=$(escape_for_env "$file_path")
    
    # Execute with escaped variable
    env -i \
        PATH="/usr/local/bin:/usr/bin:/bin" \
        /bin/bash -c "FILE_PATH='$escaped_path' $plugin_cmd"
}
```

**Approach 3: Variable Validation (Additional Layer)**
```bash
validate_env_var() {
    local var_name="$1"
    local var_value="$2"
    
    case "$var_name" in
        FILE_PATH|OUTPUT_DIR|PLUGIN_DATA_DIR)
            # Validate path hasn't been exploited
            if [[ "$var_value" =~ $'\n' ]] || [[ "$var_value" =~ $'\0' ]]; then
                die "Invalid characters in $var_name"
            fi
            ;;
        *)
            die "Unknown environment variable: $var_name"
            ;;
    esac
}
```

### Plugin Interface Contract

Plugins expect environment variables to be:
1. **Properly set**: Variable exists when plugin runs
2. **Correctly valued**: Contains intended path/value
3. **Safe to use**: Can be used directly in shell commands when properly quoted

Plugin responsibilities:
```bash
#!/bin/bash
# Example plugin: main.sh

# Access environment variables  
file_path="${FILE_PATH}"
output_dir="${OUTPUT_DIR}"

# Validate received values
[[ -f "$file_path" ]] || { echo "ERROR: File not found" >&2; exit 1; }
[[ -d "$output_dir" ]] || { echo "ERROR: Output dir not found" >&2; exit 1; }

# Use properly quoted in commands
mime_type=$(file -b --mime-type "$file_path")

# Return JSON output
jq -n --arg mime "$mime_type" '{mime_type: $mime}'
```

### Clean Environment Variables

**Variables to SET**:
```bash
# Minimal required environment
PATH="/usr/local/bin:/usr/bin:/bin"
HOME="${USER_HOME}"  # If needed
LANG="${USER_LANG:-C}"  # For consistent output
FILE_PATH="..."  # Plugin input
OUTPUT_DIR="..."  # Plugin output
PLUGIN_DATA_DIR="..."  # Plugin temporary data
```

**Variables to UNSET** (security):
```bash
# Clear potentially dangerous variables
unset LD_PRELOAD
unset LD_LIBRARY_PATH
unset LD_AUDIT
unset BASH_ENV
unset ENV
unset SHELLOPTS
unset IFS  # Or set to default
```

### Testing Examples

**Test Case: Command Injection in File Name**
```bash
# Setup: Create file with malicious name
touch 'test$(whoami).pdf'

# Execute: Process file through plugin
doc.doc.sh process -d . -o /tmp/output

# Expected: 
# - Plugin receives FILE_PATH='test$(whoami).pdf' as literal string
# - No command substitution occurs
# - whoami command NOT executed
# - Output file created as 'test$(whoami).pdf.md'

# Verification:
# Check plugin didn't execute whoami
# Check no unexpected command activity in logs
# Verify output file name matches input (escaped)
```

**Test Case: Environment Variable Escaping**
```bash
# Test script
#!/bin/bash

# Malicious file path
malicious_path='test; rm -rf /tmp/testdir; echo pwned.pdf'

# Create test directory
mkdir -p /tmp/testdir
touch /tmp/testdir/important.txt

# Execute plugin with sanitization
execute_plugin "echo \$FILE_PATH" "$malicious_path" "/tmp/out" "/tmp/plugin"

# Verify:
# - /tmp/testdir still exists (rm command didn't run)
# - Plugin echo shows literal string, not command execution
# - Exit code 0 (successful, no injection)

# Cleanup
rm -rf /tmp/testdir /tmp/out /tmp/plugin
```

### Related Requirements

- REQ_SEC_001 (Input Validation) - validates before sanitizing
- REQ_SEC_003 (Plugin Descriptor Validation) - validates plugin commands
- REQ_SEC_005 (Path Traversal Prevention) - validates paths before env vars
- REQ_SEC_007 (Plugin Security Documentation) - documents plugin environment contract

### Risk if Not Implemented

**Risk Level**: HIGH (3.53 - Plugin System risk)

**STRIDE Score**: 3.67 | **DREAD Score**: 3.4

Without environment variable sanitization:
- **Arbitrary Command Execution**: Malicious file names execute arbitrary commands
- **System Compromise**: Commands run with user privileges
- **Data Loss**: `rm` or similar commands could delete user data
- **Privilege Escalation**: Combined with other vulnerabilities
- **Difficult Detection**: Injection via file names is non-obvious

Environment variable injection is a well-known attack vector, especially in shell scripts processing file names. Easy to exploit if not properly sanitized.

### Implementation Notes

**Layered Defense**:
1. **Input Validation** (REQ_SEC_001): Reject obviously malicious inputs early
2. **Path Validation** (REQ_SEC_005): Ensure paths are valid before use
3. **Variable Sanitization** (this requirement): Escape before passing to plugins
4. **Plugin Execution** (SC-004): Use clean environment, proper quoting
5. **Plugin Responsibility**: Plugins should still quote variables when using

**Performance Consideration**:
Sanitization overhead is minimal (escaping is simple string operation). The `env -i` approach is slightly slower but provides better security isolation.

**Cross-Platform Compatibility**:
- Linux: `env -i` available in GNU coreutils
- macOS: `env -i` available, behavior identical
- Escaping methods platform-independent

**Common Pitfalls to Avoid**:
```bash
# BAD: Unquoted variable in command
FILE_PATH=$malicious_path /bin/bash -c "echo $FILE_PATH"

# BAD: Double quotes allow substitution
FILE_PATH="$malicious_path" /bin/bash -c "echo $FILE_PATH"

# BAD: eval allows arbitrary code execution
eval "FILE_PATH='$malicious_path' plugin_cmd"

# GOOD: Single quotes prevent all expansion
# GOOD: env -i provides clean environment
# GOOD: Proper quoting in plugin command
```

### References

- Security Concept Section 5.3 (Scope 3: Plugin System)
- Architecture Vision: 08_concepts.md - Plugin Interface
- CWE-78: Improper Neutralization of Special Elements used in an OS Command ('OS Command Injection')
- OWASP: Command Injection
- OWASP: Injection Flaws
- Bash Pitfalls: http://mywiki.wooledge.org/BashPitfalls
