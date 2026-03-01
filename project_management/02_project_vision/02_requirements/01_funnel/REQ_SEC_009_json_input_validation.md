# Requirement: JSON Input Validation

- **ID:** REQ_SEC_009
- **Status:** FUNNEL
- **Created at:** 2026-03-01
- **Created by:** Security Agent
- **Last Updated:** 2026-03-01
- **Updated by:** Security Agent
- **Source:** Security threat analysis (architectural change to JSON stdin/stdout)
- **Type:** Security Requirement
- **Priority:** CRITICAL
- **Related Threats:** JSON Injection, Plugin Exploitation, Arbitrary Code Execution, Type Confusion

## Change History

| Date | Author | Change |
|------|--------|--------|
| 2026-03-01 | Security Agent | Initial requirement created to replace REQ_SEC_008 following architectural change to JSON stdin/stdout |

## Description

All JSON input passed to plugins via stdin must be validated against the plugin's descriptor input schema to prevent JSON injection attacks, type confusion, and ensure plugins cannot exploit malformed or malicious JSON input.

**Architecture Context**: Per [ADR-003](../../03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md) and [ARC_0003](../../03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md), plugins receive input parameters as JSON via stdin (matching descriptor input schema) and return output as JSON to stdout. This replaces the previous environment variable-based parameter passing.

### Specific Requirements

1. **JSON Schema Validation**:
   - All JSON input to plugins must be validated against the plugin descriptor's `input` schema before execution
   - Input JSON must match the types, required fields, and structure defined in descriptor
   - Invalid JSON that does not match schema must be rejected with clear error message
   - Schema validation must occur BEFORE plugin execution

2. **JSON Format Validation**:
   - JSON must be well-formed and parseable
   - Malformed JSON (syntax errors, unterminated strings, etc.) must be rejected
   - Empty or null input handled according to descriptor schema requirements
   - Character encoding validated (UTF-8)

3. **Type Validation**:
   - String parameters: Validated as strings (no type coercion)
   - Number parameters: Validated as numbers with range checks if specified
   - Boolean parameters: Validated as true/false (reject strings like "true")
   - Array parameters: Validated as arrays with element type checking
   - Object parameters: Validated as objects with nested schema validation

4. **Parameter Name Validation**:
   - Parameter names must match descriptor schema exactly (lowerCamelCase)
   - Unknown/extra parameters rejected or ignored per schema specification
   - Required parameters must be present
   - Parameter name length: Maximum 64 characters
   - Parameter names must match pattern: `^[a-z][a-zA-Z0-9]*$` (lowerCamelCase per REQ_SEC_003)

5. **JSON Injection Prevention**:
   - Special characters in string values do not cause JSON parsing errors
   - Nested objects validated to prevent deeply nested attack (depth limit: 10 levels)
   - String escaping validated (ensure proper JSON string encoding)
   - No executable code in JSON values (sanitize before any eval-like operations)

6. **Size Limits**:
   - Maximum JSON input size: 1MB per plugin invocation
   - Maximum string value length: 4KB
   - Maximum array length: 1000 elements
   - Maximum object properties: 100 keys
   - Limits configurable per plugin descriptor if needed

7. **Required Standard Parameters** (provided by runtime):
   - `filePath` (string): Absolute path to file being processed
   - Additional parameters defined in plugin descriptor's `input.parameters` array

### Security Controls

- **SC-004**: JSON Input Validation - Validate JSON against descriptor schema
- **SC-008**: Plugin Execution Isolation - Controlled JSON input

### Threat Scenarios

| Attack | Example | Expected Behavior |
|--------|---------|-------------------|
| JSON injection via string | `{"filePath": "test.pdf\", \"malicious\": \"value"}` | Rejected: Invalid JSON syntax |
| Type confusion | `{"filePath": 123}` instead of string | Rejected: Type mismatch with schema |
| Missing required parameter | `{}` when filePath required | Rejected: Missing required parameter |
| Extra malicious parameters | `{"filePath": "test.pdf", "executeCommand": "rm -rf /"}` | Rejected or ignored per schema |
| Deeply nested objects | JSON with 100+ nesting levels | Rejected: Exceeds depth limit |
| Oversized input | 10MB JSON payload | Rejected: Exceeds size limit |
| Malformed JSON | `{filePath: test.pdf}` (missing quotes) | Rejected: JSON parse error |
| Unicode injection | `{"filePath": "test\u0000.pdf"}` | Sanitized: Null bytes stripped/rejected |

### Test Requirements

**Functional Tests**:
- Plugins receive correct JSON input matching descriptor schema
- Valid JSON passes validation and executes successfully
- Required parameters present and correct type
- Optional parameters handled correctly

**Security Tests**:
- **JSON Injection**: Attempt to inject additional fields via string escaping
- **Type Confusion**: Send wrong types for each parameter (string as number, etc.)
- **Missing Parameters**: Omit required parameters
- **Extra Parameters**: Include unexpected parameters not in schema
- **Malformed JSON**: Various syntax errors (unclosed braces, quotes, etc.)
- **Size Limits**: Oversized JSON, very long strings, large arrays
- **Nested Objects**: Deeply nested JSON beyond limit
- **Unicode Attacks**: Null bytes, control characters, special Unicode
- **Empty Input**: Empty object `{}`, empty string `""`, null
- **Schema Mismatch**: Valid JSON but wrong structure for plugin

### Acceptance Criteria

- [ ] All plugin input JSON validated against descriptor schema
- [ ] Invalid JSON rejected before plugin execution
- [ ] Type validation enforced (no type coercion)
- [ ] Size limits enforced (JSON, strings, arrays, objects)
- [ ] Depth limits enforced (max 10 levels nesting)
- [ ] Required parameters validated as present
- [ ] Unknown parameters handled per schema
- [ ] Malformed JSON rejected with clear error
- [ ] Security test suite passes with 100% coverage
- [ ] No false positives for legitimate JSON inputs

### JSON Validation Implementation

**Approach 1: JSON Schema Validator (Recommended)**
```bash
validate_plugin_json_input() {
    local descriptor_file="$1"
    local input_json="$2"
    
    # Extract input schema from descriptor
    local input_schema=$(jq '.input' "$descriptor_file")
    
    # Validate JSON against schema using jq or dedicated validator
    if ! echo "$input_json" | jq -e --argjson schema "$input_schema" \
        '. as $input | $schema | .parameters[] | 
         select(.required == true) | .name as $pname | 
         $input | has($pname)' > /dev/null; then
        die "JSON input validation failed: missing required parameters"
    fi
    
    # Validate types match descriptor
    # Validate size limits
    # Validate nesting depth
    
    echo "$input_json"
}
```

**Approach 2: Size and Structure Validation**
```bash
validate_json_structure() {
    local json="$1"
    
    # Check JSON size
    local size=$(echo "$json" | wc -c)
    if [[ $size -gt 1048576 ]]; then  # 1MB
        die "JSON input too large: ${size} bytes (max 1MB)"
    fi
    
    # Check nesting depth
    local depth=$(echo "$json" | jq 'path(recurse) | length' | sort -n | tail -1)
    if [[ $depth -gt 10 ]]; then
        die "JSON nesting too deep: ${depth} levels (max 10)"
    fi
    
    # Validate parseable
    if ! echo "$json" | jq empty 2>/dev/null; then
        die "Malformed JSON input"
    fi
}
```

**Approach 3: Type Validation**
```bash
validate_parameter_types() {
    local json="$1"
    local descriptor="$2"
    
    # For each parameter in descriptor
    jq -r '.input.parameters[] | "\(.name) \(.type) \(.required)"' "$descriptor" | \
    while read -r param_name param_type param_required; do
        # Check if parameter exists in input
        local value=$(echo "$json" | jq -r --arg name "$param_name" '.[$name]')
        
        if [[ "$value" == "null" ]] && [[ "$param_required" == "true" ]]; then
            die "Required parameter missing: $param_name"
        fi
        
        # Validate type
        case "$param_type" in
            string)
                if ! echo "$json" | jq -e --arg name "$param_name" '.[$name] | type == "string"' > /dev/null; then
                    die "Type mismatch: $param_name must be string"
                fi
                ;;
            number)
                if ! echo "$json" | jq -e --arg name "$param_name" '.[$name] | type == "number"' > /dev/null; then
                    die "Type mismatch: $param_name must be number"
                fi
                ;;
            boolean)
                if ! echo "$json" | jq -e --arg name "$param_name" '.[$name] | type == "boolean"' > /dev/null; then
                    die "Type mismatch: $param_name must be boolean"
                fi
                ;;
        esac
    done
}
```

### Plugin Interface Contract

**Runtime → Plugin (stdin)**:
```json
{
  "filePath": "/absolute/path/to/file.pdf",
  "customParam": "value"
}
```

**Plugin → Runtime (stdout)**:
```json
{
  "mimeType": "application/pdf",
  "otherField": "value"
}
```

**System Responsibilities** (this requirement's scope):
- Construct JSON input from descriptor schema and runtime values
- Validate JSON input against descriptor schema BEFORE passing to plugin
- Pass validated JSON to plugin via stdin
- Reject invalid JSON before plugin execution
- Enforce size and complexity limits

**Plugin Responsibilities**:
- Read JSON from stdin
- Parse JSON (assume valid if system validation passed)
- Return valid JSON to stdout matching output schema

### Comparison to Previous Architecture

**Old Architecture (Environment Variables)**:
```bash
# Runtime passed parameters via environment variables
FILE_PATH="/path/to/file.pdf"
CUSTOM_PARAM="value"

# Security concerns: Shell injection, variable expansion
```

**New Architecture (JSON stdin)**:
```json
{
  "filePath": "/path/to/file.pdf",
  "customParam": "value"
}
```

**Security Benefits**:
- **No shell injection**: JSON parsing doesn't execute commands
- **Type safety**: Explicit types enforced by schema
- **Structured validation**: Schema-based validation clearer than env var sanitization
- **Clear boundaries**: stdin/stdout separation cleaner than environment
- **Standard format**: JSON widely understood, tooling available

**New Security Concerns** (addressed by this requirement):
- **JSON injection**: Malicious JSON structure
- **Type confusion**: Wrong types passed to plugins
- **Size attacks**: Oversized JSON payloads
- **Depth attacks**: Deeply nested JSON structures

### Related Requirements

- REQ_SEC_003 (Plugin Descriptor Validation) - validates descriptor schema definition
- REQ_SEC_007 (Plugin Security Documentation) - documents JSON input requirements for plugin developers
- REQ_SEC_008 (Environment Variable Sanitization) - **OBSOLETED** by this requirement
- REQ_SEC_001 (Input Validation) - validates file paths before including in JSON

### Related Architecture

- [ADR-003: JSON Plugin Descriptors](../../03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md) - defines JSON stdin/stdout architecture
- [ARC_0003: Plugin Architecture](../../03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md) - describes JSON-based plugin communication
- [Security Concept SC-004](../../04_security_concept/01_security_concept.md) - JSON Input Validation control
- [ASSET-0205](../../04_security_concept/02_asset_catalog.md) - Plugin JSON Input asset

### Risk if Not Implemented

**Risk Level**: HIGH (3.53 - Plugin System risk)

Without JSON input validation:
- **Type Confusion**: Plugins receive wrong data types, causing crashes or unexpected behavior
- **JSON Injection**: Malicious JSON structure exploits parser vulnerabilities
- **Denial of Service**: Oversized or deeply nested JSON exhausts resources
- **Plugin Exploitation**: Invalid input causes plugin to behave unexpectedly
- **Data Corruption**: Wrong types passed through could corrupt output

JSON is generally safer than environment variables for parameter passing, but still requires validation to prevent injection and ensure type safety.

### Implementation Notes

**Layered Validation**:
1. **Design Time**: Descriptor schema defines allowed inputs (REQ_SEC_003)
2. **Runtime Construction**: System constructs JSON from validated runtime values
3. **Pre-Execution Validation** (this requirement): Validate JSON before plugin execution
4. **Plugin Parsing**: Plugin parses JSON (can assume valid)

**JSON Libraries**:
- Use `jq` for JSON validation and manipulation (already required for plugin output parsing)
- Consider JSON Schema validation library if available
- Fallback to manual validation if needed

**Performance Considerations**:
- JSON validation overhead minimal for typical payload sizes (<1KB)
- Schema validation can be cached per plugin
- Size limits prevent DoS via oversized payloads

### Testing Examples

**Test Case: Type Confusion**
```bash
# Plugin descriptor expects:
# "input": {"parameters": [{"name": "filePath", "type": "string", "required": true}]}

# Attack: Send number instead of string
echo '{"filePath": 12345}' | doc.doc.sh process-via-plugin file

# Expected: 
# - Validation error: "Type mismatch: filePath must be string"
# - Plugin NOT executed
# - Exit code 1
```

**Test Case: JSON Injection**
```bash
# Attack: Attempt to inject additional fields
malicious_json='{"filePath": "test.pdf\", \"malicious\": \"value"}'

# Expected:
# - JSON parse error (invalid syntax)
# - Plugin NOT executed
# - Clear error message about malformed JSON
```

**Test Case: Size Limit**
```bash
# Attack: Oversized JSON payload
huge_json=$(python3 -c "import json; print(json.dumps({'filePath': 'a' * 10000000}))")

# Expected:
# - Validation error: "JSON input too large"
# - Plugin NOT executed
# - No resource exhaustion
```

### References

- [OWASP: JSON Injection](https://owasp.org/www-community/vulnerabilities/JSON_Injection)
- [CWE-20: Improper Input Validation](https://cwe.mitre.org/data/definitions/20.html)
- [CWE-502: Deserialization of Untrusted Data](https://cwe.mitre.org/data/definitions/502.html)
- [JSON Schema Specification](https://json-schema.org/)
- RFC 8259: The JavaScript Object Notation (JSON) Data Interchange Format
