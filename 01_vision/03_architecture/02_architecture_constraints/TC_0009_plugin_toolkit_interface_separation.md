# TC-0009: Plugin-Toolkit Interface Separation

**ID**: TC-0009  
**Status**: Active  
**Created**: 2026-02-11  
**Source**: Security Review of Feature 0009 Plugin Execution Engine

## Constraint

**Plugins MUST NOT have direct access to JSON workspace data. All plugin-toolkit communication MUST occur via controlled environment variables and declared interfaces.**

## Rationale

Security review identified **Critical** vulnerabilities (Risk Score: 268) from exposing workspace data directly to plugin environments:

**Security Risks:**
- **Environment Data Exposure**: Complete workspace metadata leaked to untrusted plugin processes
- **Cross-File Information Disclosure**: Plugins accessing workspace data from other files
- **Workspace Tampering**: Direct JSON access enables workspace corruption
- **Credential Exfiltration**: Plugin subprocesses inheriting sensitive environment data
- **Privilege Escalation**: Exposed system paths and metadata enable reconnaissance

**Architectural Benefits:**
- **Separation of Concerns**: Clear boundary between trusted toolkit and untrusted plugins
- **Interface Stability**: Plugin interface isolated from workspace format evolution
- **Data Minimization**: Plugins receive only explicitly required data
- **Audit Trail**: Complete visibility into plugin data access patterns

## Technical Requirements

### Interface Architecture

#### Plugin Descriptor Variable Declaration
**Required Fields:**
```json
{
  "requires_variables": ["VAR1", "VAR2"],  // Input variables needed
  "provides_variables": ["RESULT1", "RESULT2"]  // Output variables produced
}
```

#### Variable Naming Standards
- **Format**: Alphanumeric and underscore only: `[a-zA-Z0-9_]+`
- **Reserved Names**: No collision with system variables (PATH, HOME, USER, etc.)
- **Length**: Maximum 64 characters per variable name
- **Case**: UPPER_CASE_WITH_UNDERSCORES convention

#### Data Classification Filtering
- **Public**: Environment variables for non-sensitive data (file sizes, MIME types)
- **Internal**: Filtered environment variables for operational data
- **Confidential**: NO environment variable exposure - alternative interfaces required
- **Highly Confidential**: NO plugin access - toolkit-only processing

### Prohibited Practices

#### Direct Workspace Access
```bash
# PROHIBITED - Direct JSON file access
jq '.file_metadata' "$workspace_dir/file_hash.json"  # ❌ FORBIDDEN

# PROHIBITED - Environment variable workspace export
export WORKSPACE_DATA="$(cat workspace.json)"  # ❌ FORBIDDEN
```

#### Correct Interface Usage
```bash
# REQUIRED - Declared variable provisioning
export FILE_SIZE="$calculated_size"           # ✅ CORRECT
export MIME_TYPE="$detected_mime_type"         # ✅ CORRECT
export PREVIOUS_OCR_TEXT="$ocr_result"         # ✅ CORRECT (if classified as Internal/Public)
```

## Implementation Standards

### Toolkit Responsibilities

#### Variable Provisioning
```bash
validate_plugin_variables() {
    local plugin_descriptor="$1"
    local -a required_vars
    
    # Parse required variables from descriptor
    readarray -t required_vars < <(jq -r '.requires_variables[]' "$plugin_descriptor")
    
    # Validate each variable name
    for var_name in "${required_vars[@]}"; do
        if ! [[ "$var_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
            log "ERROR" "VALIDATION" "Invalid variable name: $var_name"
            return 1
        fi
        
        if [[ "$var_name" =~ ^(PATH|HOME|USER|SHELL|PWD|LD_.*|PS[0-9])$ ]]; then
            log "ERROR" "VALIDATION" "Reserved variable name: $var_name"
            return 1
        fi
    done
}

provision_plugin_environment() {
    local plugin_descriptor="$1"
    local workspace_data="$2"
    local file_path="$3"
    
    # Only export declared variables after CIA classification
    for var_name in $(jq -r '.requires_variables[]' "$plugin_descriptor"); do
        case "$var_name" in
            FILE_SIZE)
                export FILE_SIZE="$(stat -f%z "$file_path")"
                ;;
            MIME_TYPE)
                export MIME_TYPE="$(file -b --mime-type "$file_path")"
                ;;
            PREVIOUS_*)
                # Extract from workspace with CIA filtering
                if var_value=$(extract_workspace_variable "$workspace_data" "$var_name"); then
                    export "$var_name"="$var_value"
                fi
                ;;
            *)
                log "DEBUG" "PROVISION" "Variable $var_name not available"
                ;;
        esac
    done
}
```

#### Result Collection
```bash
collect_plugin_results() {
    local plugin_descriptor="$1"
    local workspace_data="$2"
    local -A results
    
    # Collect declared output variables
    for var_name in $(jq -r '.provides_variables[]' "$plugin_descriptor"); do
        if [[ -n "${!var_name:-}" ]]; then
            results["$var_name"]="${!var_name}"
            log "DEBUG" "COLLECT" "Collected: $var_name = ${!var_name}"
        fi
    done
    
    # Validate and merge results into workspace
    merge_plugin_results "$workspace_data" results
}
```

### Plugin Responsibilities

#### Environment Variable Reading
```bash
# Plugin implementation example
#!/bin/bash
# extract_metadata.sh

file_path="$1"

# Verify required variables available
if [[ -z "${FILE_SIZE:-}" ]] || [[ -z "${MIME_TYPE:-}" ]]; then
    echo "ERROR: Required variables not provided" >&2
    exit 1
fi

# Process file using available variables
if [[ "$MIME_TYPE" == "application/pdf" ]] && [[ "$FILE_SIZE" -gt 1024 ]]; then
    # Extract PDF metadata
    PDF_TITLE=$(pdfinfo "$file_path" | grep "^Title:" | cut -d: -f2- | xargs)
    PDF_AUTHOR=$(pdfinfo "$file_path" | grep "^Author:" | cut -d: -f2- | xargs)
    
    # Export results (plugin descriptor declares these in 'provides_variables')
    export PDF_TITLE
    export PDF_AUTHOR
fi

exit 0
```

## Quality Attributes Impacted

### Security (PRIMARY)
- **Confidentiality**: Workspace data exposure minimized through controlled interface
- **Integrity**: Workspace corruption prevented by eliminating direct plugin access
- **Availability**: Plugin isolation prevents cascade failures

### Maintainability
- **Interface Stability**: Plugin interface independent of workspace format changes
- **Code Clarity**: Clear separation between toolkit and plugin responsibilities
- **Testing**: Independent testing of plugin and toolkit components

### Reliability
- **Fault Isolation**: Plugin failures don't corrupt workspace data
- **Dependency Management**: Explicit variable dependency declarations
- **Error Detection**: Clear error messages for missing variables

## Compliance Verification

### Static Analysis
- **Code Review**: Verify no direct workspace file access in plugin code
- **Descriptor Validation**: Ensure all plugins have variable declarations
- **Interface Compliance**: Verify toolkit uses only declared variables

### Dynamic Testing
```bash
# Test plugin isolation
test_plugin_isolation() {
    local test_plugin="$1"
    local workspace_file="/tmp/test_workspace.json"
    
    # Create test workspace with sensitive data
    echo '{"secret": "confidential_data", "other_file_data": "cross_contamination"}' > "$workspace_file"
    
    # Execute plugin with minimal environment
    unset $(compgen -A variable | grep -E '^(WORKSPACE|SECRET|CONFIDENTIAL)')
    
    # Plugin should fail to access undeclared data
    if "$test_plugin" /dev/null 2>&1 | grep -q "confidential_data"; then
        echo "FAIL: Plugin accessed undeclared workspace data" >&2
        return 1
    fi
    
    echo "PASS: Plugin properly isolated from workspace data"
}
```

### Security Audit
- **Environment Inspection**: Verify plugins receive only declared variables
- **Workspace Access**: Confirm no plugin can read workspace JSON files
- **Data Leakage**: Test for cross-file data exposure
- **Variable Injection**: Attempt command injection via variable values

## Documentation Requirements

### Plugin Development Guide
- **Variable Declaration**: How to declare required and provided variables
- **Environment Access**: Best practices for reading environment variables
- **Result Export**: Methods for returning data to toolkit
- **Security Considerations**: Data handling and validation requirements

### Architecture Documentation
- **Interface Specification**: Complete variable-based interface documentation
- **Security Controls**: How interface prevents data exposure
- **CIA Classification**: Data sensitivity handling guidelines

## Migration Path

### Existing Plugin Updates
1. **Add Variable Declarations**: Update plugin.json with `requires_variables` and `provides_variables`
2. **Remove Direct Access**: Replace workspace file reading with environment variable access
3. **Update Result Handling**: Change from JSON file output to environment variable export
4. **Validation Testing**: Verify plugin works with new interface

### Toolkit Updates
1. **Variable Provisioning**: Implement controlled environment variable export
2. **Result Collection**: Add environment variable result collection
3. **Validation Logic**: Add variable name and access validation
4. **Error Handling**: Graceful handling of missing variables

## Exceptions

**No exceptions permitted.** Direct workspace access creates unacceptable security vulnerabilities.

### Future Enhancements
- **Advanced Data Types**: Structured data passing beyond simple variables
- **Streaming Interfaces**: Real-time data exchange for large datasets
- **Encrypted Communication**: Secure data exchange for highly confidential data

## Related Architecture

- **ADR-0010**: Plugin-Toolkit Interface Architecture → Implementation decision
- **ADR-0009**: Plugin Security Sandboxing → Complementary execution isolation
- **ADR-0002**: JSON Workspace State → Protected from plugin access
- **TC-0008**: Mandatory Plugin Sandboxing → Enforcement mechanism

## Validation Criteria

### Functional
- [ ] Plugins declare required variables in descriptors
- [ ] Toolkit provides only declared variables
- [ ] Plugin result collection works correctly
- [ ] Missing variable dependencies detected

### Security
- [ ] Plugin cannot access undeclared workspace data
- [ ] Plugin cannot read workspace JSON files
- [ ] Variable name validation prevents injection
- [ ] Cross-file data isolation maintained

### Interface
- [ ] Variable-based interface stable across toolkit updates
- [ ] Plugin development simplified compared to direct JSON access
- [ ] Clear error messages for interface violations

## Implementation Status

**Status**: Required for Feature 0009 Plugin Execution Engine  
**Priority**: Critical - security blocking requirement  
**Dependencies**: Plugin descriptor schema updates, toolkit interface implementation

---
**Compliance**: This constraint is **mandatory** for security and architectural integrity.