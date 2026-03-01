# Requirement: Environment Variable Sanitization

- **ID:** REQ_SEC_008
- **Status:** OBSOLETED
- **Created at:** 2026-02-25
- **Created by:** Security Agent
- **Last Updated:** 2026-03-01
- **Updated by:** Security Agent
- **Obsoleted at:** 2026-03-01
- **Obsoleted by:** Security Agent
- **Obsoleted Reason:** Architectural change from environment variable to JSON stdin/stdout parameter passing
- **Superseded by:** REQ_SEC_009 (JSON Input Validation)
- **Source:** Security threat analysis (STRIDE/DREAD Scope 3)
- **Type:** Security Requirement
- **Original Priority:** CRITICAL
- **Related Threats:** Command Injection, Plugin Exploitation, Arbitrary Code Execution

## Obsolescence Rationale

This requirement is **OBSOLETED** as of 2026-03-01 due to architectural change documented in:
- [ADR-003: JSON Plugin Descriptors](../../03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md) (updated)
- [ARC_0003: Plugin Architecture](../../03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md) (updated)

**Architectural Change**: The plugin architecture has been updated to pass parameters via **JSON stdin** instead of environment variables:
- **Old approach**: Parameters passed as environment variables (`FILE_PATH`, `OUTPUT_DIR`, etc.)
- **New approach**: Parameters passed as JSON object via stdin matching descriptor input schema
- **Reason**: JSON provides better type safety, schema validation, and clearer security boundaries

**Security Impact**:
- **Eliminated threats**: Shell metacharacter injection, environment variable expansion attacks
- **New requirement**: REQ_SEC_009 (JSON Input Validation) addresses JSON-specific threats
- **Net security improvement**: JSON stdin/stdout is more secure than environment variables

**Migration Path**:
- All references to environment variable sanitization updated to JSON input validation
- Security control SC-004 updated from "Environment Variable Sanitization" to "JSON Input Validation"
- Asset ASSET-0205 updated from "Environment Variables" to "Plugin JSON Input"

This requirement is preserved for historical reference and audit trail.

---

## Change History

| Date | Author | Change |
|------|--------|--------|
| 2026-02-25 | Security Agent | Initial requirement created |
| 2026-03-01 | Security Agent | Refined to align with ADR-003 architecture; clarified descriptor-to-environment parameter mapping; added lowerCamelCase → UPPER_SNAKE_CASE naming convention details |
| 2026-03-01 | Security Agent | Marked as OBSOLETED due to architectural change to JSON stdin/stdout; superseded by REQ_SEC_009 |

## Description

All environment variables passed to plugins at runtime must be sanitized to prevent command injection and ensure plugins cannot exploit environment variable values for malicious purposes.

**Architecture Context**: Per [ADR-003](../../03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md) and [ARC_0003](../../03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md), plugins receive input parameters via environment variables at runtime and return output as JSON to stdout. Plugin descriptors define parameters using lowerCamelCase (e.g., `filePath`), but the runtime environment variables use UPPER_SNAKE_CASE (e.g., `FILE_PATH`).

### Specific Requirements

1. **Standard Environment Variables Passed to Plugins** (per ADR-003):
   - `FILE_PATH`: Absolute path to file being processed (maps to descriptor parameter `filePath`)
   - `OUTPUT_DIR`: Directory for generated output (runtime-provided)
   - `PLUGIN_DATA_DIR`: Temporary directory for plugin-specific data (runtime-provided)
   - Additional custom parameters may be defined in plugin descriptors using lowerCamelCase names, then mapped to UPPER_SNAKE_CASE environment variables at runtime

2. **Sanitization Requirements**:
   - **ALL environment variable values** must be escaped or quoted (standard and custom)
   - Variables must be validated before being set
   - No user-controlled variable names (only descriptor-defined parameters mapped to validated names)
   - Plugin execution must use clean environment (`env -i` or equivalent)
   - **Parameter name mapping validation**:
     - Descriptor parameter names must match `^[a-z][a-zA-Z0-9]*$` (lowerCamelCase, enforced by REQ_SEC_003)
     - Mapped environment variable names must follow convention: convert lowerCamelCase to UPPER_SNAKE_CASE
     - Reject mapping to system/reserved environment variables (PATH, HOME, LD_PRELOAD, LD_LIBRARY_PATH, etc.)
     - Maximum parameter name length: 64 characters (to prevent environment space exhaustion)

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
- Very long file paths (buffer overflow / environment space exhaustion)
- Unicode and non-ASCII characters in paths
- **Custom parameter injection**: Plugin with custom parameter containing malicious values
- **Reserved environment variable names**: Attempt to map descriptor parameter to PATH, LD_PRELOAD, etc.
- **Parameter name validation**: Descriptor with invalid parameter names (UPPER_CASE, snake_case, etc.)

### Acceptance Criteria

- [ ] All environment variables sanitized before plugin execution (standard and custom)
- [ ] Plugins execute with clean, minimal environment
- [ ] Special characters in file paths do not cause command execution
- [ ] Command injection tests fail (no execution occurs)
- [ ] Plugins receive properly escaped values
- [ ] Security test suite passes with 100% coverage
- [ ] No false positives for legitimate file names
- [ ] Parameter name mapping validated (lowerCamelCase → UPPER_SNAKE_CASE)
- [ ] System/reserved environment variable names rejected
- [ ] Custom descriptor parameters sanitized same as standard parameters
- [ ] Environment variable size limits enforced

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

**Per [ADR-003](../../03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md) and [ARC_0003](../../03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md):**

**Parameter Naming Convention:**
- **Descriptor Definition**: Plugin descriptors define input parameters using lowerCamelCase (e.g., `filePath`, `mimeType`, `fileSize`)
- **Runtime Environment Variables**: System maps descriptor parameters to UPPER_SNAKE_CASE environment variables (e.g., `filePath` → `FILE_PATH`)
- **Plugin Output**: Plugins return JSON to stdout using lowerCamelCase names matching the descriptor output definitions

Plugins expect environment variables to be:
1. **Properly set**: Variable exists when plugin runs
2. **Correctly valued**: Contains intended path/value  
3. **Safe to use**: Can be used directly in shell commands when properly quoted within the plugin

Plugin responsibilities:
```bash
#!/bin/bash
# Example plugin: main.sh (process command per ADR-003)

# Access standard environment variables (runtime provides these)
file_path="${FILE_PATH}"
output_dir="${OUTPUT_DIR}"
plugin_data_dir="${PLUGIN_DATA_DIR}"

# Validate received values (defensive programming)
[[ -f "$file_path" ]] || { echo "ERROR: File not found" >&2; exit 1; }
[[ -d "$output_dir" ]] || { echo "ERROR: Output dir not found" >&2; exit 1; }

# Use properly quoted in commands (plugin's responsibility within its scope)
mime_type=$(file -b --mime-type "$file_path")

# Return JSON output (using lowerCamelCase matching descriptor)
jq -n --arg mime "$mime_type" '{mimeType: $mime}'
```

**System Responsibilities** (this requirement's scope):
- Sanitize and escape all environment variable values BEFORE passing to plugins
- Use clean, minimal environment for plugin execution
- Prevent command injection through environment variable values
- Map descriptor parameter names to environment variables safely

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

- REQ_SEC_001 (Input Validation) - validates paths before sanitizing for environment variables
- REQ_SEC_003 (Plugin Descriptor Validation) - validates plugin parameter definitions in descriptors
- REQ_SEC_005 (Path Traversal Prevention) - validates paths before setting environment variables
- REQ_SEC_007 (Plugin Security Documentation) - documents plugin environment contract

### Related Architecture

- [ADR-003: JSON Plugin Descriptors](../../03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md) - defines plugin descriptor schema and invocation interface
- [ARC_0003: Plugin Architecture](../../03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md) - describes environment variable-based plugin communication
- [Security Concept SC-004](../../04_security_concept/01_security_concept.md) - Environment Variable Sanitization control
- [ASSET-0205](../../04_security_concept/02_asset_catalog.md) - Environment Variables asset

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

### Additional Security Considerations (Identified 2026-03-01)

During security review and alignment with ADR-003, the following additional security concerns were identified:

**1. Parameter Name Mapping Security**
- **Concern**: System must securely map descriptor parameter names (lowerCamelCase) to environment variables (UPPER_SNAKE_CASE)
- **Risk**: Malicious descriptors could define parameters that map to dangerous environment variable names (e.g., `PATH`, `LD_PRELOAD`)
- **Mitigation**: Validate parameter names in descriptor against allowed patterns; reject system/reserved environment variable names
- **Coverage**: Partially covered by REQ_SEC_003 (descriptor validation); may need explicit name validation rules

**2. JSON Output Validation**
- **Concern**: Plugins return JSON to stdout; malicious plugins could inject malformed JSON or attempt JSON injection attacks
- **Risk**: System parsing plugin JSON output could be exploited if not properly validated
- **Status**: NOT currently covered by any requirement
- **Recommendation**: Create new requirement for plugin JSON output validation (schema validation, injection prevention)
- **Related**: REQ_SEC_004 covers template injection but not plugin output JSON

**3. Environment Variable Value Size Limits**
- **Concern**: Very long file paths or values could cause buffer overflows or DoS
- **Risk**: Malicious inputs with extremely long paths could exhaust environment space or cause crashes
- **Coverage**: Partially covered by REQ_SEC_001 input validation; may need explicit size limits for environment variables

**4. Custom Parameter Handling**
- **Concern**: Plugins may define custom input parameters beyond standard `filePath`; these need same sanitization
- **Risk**: Custom parameters could bypass sanitization if only standard variables are considered
- **Mitigation**: Ensure sanitization applies to ALL environment variables passed to plugins, not just FILE_PATH/OUTPUT_DIR/PLUGIN_DATA_DIR
- **Coverage**: This requirement should explicitly cover custom parameters

### Recommendations

1. **Accept REQ_SEC_008** after review - environment variable sanitization is critical and correct
2. **Create new requirement**: REQ_SEC_009 - Plugin JSON Output Validation
   - Validate JSON format from plugin stdout
   - Validate output matches descriptor schema
   - Prevent JSON injection attacks
   - Handle malformed plugin output gracefully
3. **Enhance REQ_SEC_003**: Add explicit validation rules for parameter name mapping to prevent dangerous environment variable names
4. **Update REQ_SEC_001**: Add explicit size limits for file paths and other inputs that become environment variables

### References

- Security Concept Section 5.3 (Scope 3: Plugin System)
- [ADR-003: JSON Plugin Descriptors](../../03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md)
- [ARC_0003: Plugin Architecture](../../03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md)
- CWE-78: Improper Neutralization of Special Elements used in an OS Command ('OS Command Injection')
- OWASP: Command Injection
- OWASP: Injection Flaws
- Bash Pitfalls: http://mywiki.wooledge.org/BashPitfalls
