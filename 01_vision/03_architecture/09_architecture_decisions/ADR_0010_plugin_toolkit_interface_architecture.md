# ADR-0010: Plugin-Toolkit Interface Architecture (REVISED)

**ID**: ADR-0010  
**Status**: Accepted  
**Created**: 2026-02-11  
**Last Updated**: 2026-02-11 (Revised based on user architecture interview)

## Context

Feature 0009 security review identified **Critical** vulnerabilities from insecure plugin execution. The original design needed secure plugin isolation while maintaining practical command-based plugin development.

Through architecture interviews, the preferred approach combines:
- **Command template execution** with variable substitution (practical for plugin developers)
- **Bubblewrap sandboxing** for security isolation  
- **Plugin directory working environment** for flexible plugin scripts/tools
- **Read -r parsing** for structured output capture

## Decision

Implement **Sandboxed Command Template Architecture** that executes plugin commands securely within isolated environments while maintaining developer-friendly command specifications.

### Core Principles
- **Command Templates**: Plugins specify commands with variable substitution in descriptors
- **Variable Substitution**: Toolkit substitutes `${variable}` patterns with actual data
- **Sandboxed Execution**: All plugin commands execute in Bubblewrap sandboxes
- **Plugin Directory Working Environment**: Commands execute in plugin directory as working directory
- **Structured Output Capture**: Read -r parsing captures plugin results inside sandbox
- **Automatic Resource Management**: Temp directories and cleanup handled automatically

### Interface Components

1. **Command Template Interface**
   - Plugin descriptors contain three command templates:
     - `commandline`: Main processing command with variable substitution
     - `check_commandline`: Availability verification command
     - `install_commandline`: Installation command
   - Variable substitution pattern: `${variable_name}`
   - Commands can reference local scripts (e.g., `./process.sh`)

2. **Variable Substitution Interface** 
   - Toolkit substitutes declared variables from workspace data
   - File path provided via `${file_path_absolute}` substitution
   - Additional data via environment variables
   - Type validation based on `consumes` field specifications

3. **Sandboxed Execution Interface**
   - All commands execute inside Bubblewrap sandbox
   - Plugin directory mounted as working directory
   - Minimal system access (read-only /usr, /bin, /lib)
   - Isolation: no network, no other filesystem access
   - Automatic temp directory within plugin directory

4. **Result Collection Interface**
   - Primary: Plugins export result variables to environment
   - Fallback: Key-value format via temporary file
   - Toolkit collects results and updates workspace JSON
   - Plugin output validation before workspace integration

## Rationale

### Security Benefits
- **Data Minimization**: Plugins receive only explicitly required data
- **Scope Isolation**: No access to complete workspace or other file data
- **Environment Control**: Toolkit manages what data is exposed via environment
- **Result Validation**: All plugin outputs validated before workspace integration
- **Audit Trail**: Complete data flow tracking between toolkit and plugins

### Technical Advantages  
- **Simplified Plugin Development**: No JSON parsing or workspace format knowledge required
- **Language Agnostic**: Works with any language that can read environment variables
- **Backward Compatible**: Existing plugins with minor descriptor updates
- **Performance**: No large JSON serialization/deserialization in plugin environment
- **Debugging**: Clear separation between toolkit and plugin responsibilities

### Maintainability Benefits
- **Interface Stability**: Plugin interface isolated from workspace format changes
- **Version Management**: Workspace schema evolution doesn't affect plugins
- **Testing**: Plugin and toolkit components can be tested independently
- **Code Quality**: Clear separation of concerns and responsibilities

## Implementation Details

### Plugin Descriptor Schema (Standard Format)
```json
{
  "name": "stat",
  "description": "Retrieves file statistics using stat command",
  "active": true,
  "processes": {
    "mime_types": ["*/*"],
    "file_extensions": ["*"]
  },
  "consumes": {
    "file_path_absolute": {
      "type": "string",
      "description": "Absolute path to the file to be analyzed"
    }
  },
  "provides": {
    "file_last_modified": {
      "type": "integer", 
      "description": "Last modified time as Unix timestamp"
    },
    "file_size": {
      "type": "integer",
      "description": "Size of the file in bytes"
    },
    "file_owner": {
      "type": "string",
      "description": "Owner of the file"
    }
  },
  "commandline": "read -r file_last_modified file_size file_owner < <(stat -c '%Y,%s,%U' '${file_path_absolute}')",
  "check_commandline": "read -r plugin_works < <(which stat > /dev/null 2>&1 && echo 'true' || echo 'false')",
  "install_commandline": "read -r plugin_successfully_installed < <(echo 'true')"
}
```

### Variable Substitution and Command Execution
```bash
# 1. Toolkit substitutes variables in command template
substitute_variables() {
    local command_template="$1"
    local file_path="$2"
    
    # Validate variable names for security (prevent command injection)
    if [[ ! "$file_path" =~ ^[^;'\"$`\|&<>]+$ ]]; then
        log "ERROR" "SECURITY" "Invalid file path characters: $file_path"
        return 1
    fi
    
    # Safe variable substitution
    local command
    command=$(echo "$command_template" | sed "s|\${file_path_absolute}|$file_path|g")
    echo "$command"
}

# 2. Sandboxed execution in plugin directory
execute_plugin_sandboxed() {
    local plugin_name="$1"
    local file_path="$2"
    local workspace_data="$3"
    
    local plugin_dir="$PLUGINS_DIR/$plugin_name"
    local descriptor="$plugin_dir/descriptor.json"
    
    # Load and substitute command template
    local command_template
    command_template=$(jq -r '.commandline' "$descriptor")
    local command
    command=$(substitute_variables "$command_template" "$file_path") || return 1
    
    # Create temporary directory in plugin directory
    local temp_dir="$plugin_dir/tmp_$$"
    mkdir -p "$temp_dir"
    trap "rm -rf '$temp_dir'" RETURN
    
    # Execute with Bubblewrap sandboxing in plugin directory
    local output
    output=$(bwrap \
        --ro-bind /usr /usr \
        --ro-bind /bin /bin \
        --ro-bind /lib /lib \
        --ro-bind /lib64 /lib64 \
        --ro-bind "$file_path" /input_file \
        --bind "$plugin_dir" /plugin \
        --bind "$temp_dir" /plugin/temp \
        --unshare-net \
        --unshare-pid \
        --new-session \
        --die-with-parent \
        --chdir /plugin \
        --setenv TEMP_DIR /plugin/temp \
        /bin/bash -c "$command" 2>&1)
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo "$output"
        return 0
    else
        log "ERROR" "PLUGIN" "$plugin_name failed with exit code $exit_code"
        return 1
    fi
}
```

### Read -r Output Parsing Inside Sandbox
```bash
# The command template uses read -r pattern for structured output parsing
# Example: read -r field1 field2 field3 < <(command that outputs "value1,value2,value3")

parse_plugin_output() {
    local plugin_name="$1"
    local raw_output="$2"
    local provides_spec="$3"
    
    # The read -r pattern captures variables within the sandbox
    # Output from sandbox contains the captured variable values
    # Toolkit receives the parsed results directly
    
    log "DEBUG" "PLUGIN" "$plugin_name output: $raw_output"
    
    # Validate output format matches provides specification
    validate_plugin_output "$raw_output" "$provides_spec"
}

# Security validation for variable substitution
validate_variable_substitution() {
    local variable_name="$1"
    local variable_value="$2"
    
    # Only allow declared variable names (prevent injection)
    if [[ ! "$variable_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
        log "ERROR" "SECURITY" "Invalid variable name: $variable_name"
        return 1
    fi
    
    # Prevent shell metacharacters in values
    if [[ "$variable_value" =~ [\;\'\"\$\`\|\&\<\>] ]]; then
        log "WARN" "SECURITY" "Shell metacharacters in value, escaping: $variable_value"
        # Apply safe escaping
        variable_value=$(printf '%q' "$variable_value")
    fi
    
    echo "$variable_value"
}
```

### Plugin Directory Structure
```
plugins/platform/plugin_name/
├── descriptor.json          # Plugin metadata with command templates
├── install.sh              # Optional installation script  
├── helper_script.sh         # Optional helper scripts referenced by command
├── temp/                    # Temporary directory (auto-created/cleaned)
└── README.md               # Plugin documentation
```

## Consequences

### Positive
- **Security**: All plugin execution isolated in Bubblewrap sandboxes
- **Familiar Interface**: Command template approach familiar to shell developers
- **Flexibility**: Plugins can be simple commands or complex scripts in their directory
- **Performance**: Read -r parsing efficiently captures structured output in single operation
- **Resource Management**: Automatic temp directory creation and cleanup
- **Development Ease**: Plugin developers can use familiar shell patterns and tools

### Negative  
- **Command Injection Risk**: Variable substitution requires careful validation
- **Platform Dependency**: Requires Bubblewrap for sandboxing (Linux-specific)
- **Complexity**: Sandboxed execution adds complexity compared to direct execution
- **Limited Cross-Platform**: Template substitution patterns may vary between platforms

### Security Considerations
- **Variable Validation**: All substituted variables must be validated for shell metacharacters
- **Sandbox Enforcement**: No plugin execution allowed without Bubblewrap sandbox
- **Directory Isolation**: Plugin working directory contains execution and prevents filesystem traversal
- **Resource Limits**: Sandbox provides automatic resource and access controls

### Migration Impact
- **Existing Plugins**: Current plugins already using command templates work with minimal changes
- **New Security**: All plugins automatically gain sandboxing protection
- **Descriptor Updates**: Plugins need `processes` field added for file type filtering
- **Standard Format**: Unified schema across all plugin implementations
- **Environment Size**: Large variable values may hit environment size limits
- **Variable Naming**: Strict constraints on variable names for security
- **Fallback Complexity**: File-based result passing adds complexity

### Neutral
- **Plugin Language**: Interface works with any programming language
- **Performance**: Minimal impact from variable-based data transfer
- **Backward Compatibility**: Descriptor migration path available

## Alternative Considered

### Direct JSON Workspace Access
**Rejected**: Creates Critical security vulnerabilities identified in security review

### Command Template Approach
**Rejected**: Command injection risks, complex escaping requirements

### File-based Data Exchange Only
**Rejected**: More complex than environment variables, temporary file management overhead

### Plugin API Library
**Rejected**: Adds dependency management complexity, not suitable for shell-based architecture

## Verification

### Functionality Tests
- [ ] Plugin declares required variables in descriptor
- [ ] Toolkit provides only declared variables to plugin environment
- [ ] Plugin receives correct variable values
- [ ] Plugin exports result variables successfully
- [ ] Toolkit collects results and updates workspace JSON
- [ ] Missing variable dependencies detected and reported

### Security Tests
- [ ] Plugin cannot access undeclared workspace data
- [ ] Plugin cannot access workspace data from other files
- [ ] Variable name validation rejects injection attempts
- [ ] System variables protected from collision
- [ ] Plugin environment isolated from toolkit environment
- [ ] Result validation prevents workspace corruption

### Interface Tests
- [ ] Multiple plugins can be executed with different variable sets
- [ ] Variable dependency chain resolved correctly
- [ ] Large variable values handled appropriately
- [ ] Fallback file-based result collection works
- [ ] Plugin execution failure doesn't corrupt workspace

## Related Decisions

- **ADR-0009**: Plugin Security Sandboxing → Provides execution isolation for this interface
- **ADR-0003**: Data-Driven Plugin Orchestration → Uses this interface for plugin coordination
- **ADR-0002**: JSON Workspace State → Toolkit-only access maintained

## Related Requirements

- req_0023: Data-Driven Execution Flow → Variable-based dependency resolution
- req_0021: Plugin Architecture → Secure plugin interface implementation
- req_0048: Command Injection Prevention → Variable name validation
- req_0053: Plugin Validation → Descriptor variable declaration validation

## Security Controls Addressed

- **NO-001 [CRITICAL]**: Environment Data Exposure → Minimized variable exposure
- **NO-005-007 [HIGH]**: Workspace Security → No direct workspace access
- **Command Injection**: Strict variable name validation
- **Cross-File Leakage**: Per-plugin variable scoping

## Migration Path

### Existing Plugin Updates
1. **Add Variable Declarations**: Update plugin.json with `requires_variables` and `provides_variables`
2. **Environment Access**: Modify plugin scripts to read from environment variables instead of workspace JSON
3. **Result Export**: Update result handling to export variables instead of writing JSON files
4. **Validation**: Test plugin with new interface using toolkit validation tools

### Backward Compatibility
- **Phase 1**: Support both old and new interfaces during transition
- **Phase 2**: Deprecation warnings for old interface usage
- **Phase 3**: Complete migration to new interface architecture

## Documentation Updates Required

- **Plugin Development Guide**: Complete rewrite for new interface architecture
- **Plugin Descriptor Schema**: Add variable declaration fields
- **Security Guidelines**: Document secure variable handling practices
- **Migration Guide**: Step-by-step plugin conversion instructions
- **API Reference**: Environment variable interface specification

## Implementation Priority

**Critical**: Must be implemented before Feature 0009 development. The plugin interface is fundamental to the orchestration engine security architecture.