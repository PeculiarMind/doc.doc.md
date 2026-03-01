# Requirement: Plugin Descriptor Validation

- **ID:** REQ_SEC_003
- **Status:** FUNNEL
- **Created at:** 2026-02-25
- **Created by:** Security Agent
- **Source:** Security threat analysis (STRIDE/DREAD Scope 3)
- **Type:** Security Requirement
- **Priority:** CRITICAL
- **Related Threats:** Malicious Plugin Execution, System Compromise, Plugin Spoofing

---

## Description

All plugin descriptor files (descriptor.json) must be validated against a defined schema before plugin loading to prevent malformed or malicious plugins from compromising system security and stability.

### Specific Requirements

1. **Schema Validation**:
   - Descriptor must be valid JSON format
   - Required fields must be present: `name`, `active`, `description`, `commands`
   - Field types must match schema (string, boolean, object)
   - Unknown fields should generate warnings but not block loading

2. **Required Fields**:
   - `name`: String matching `[a-zA-Z0-9_-]+`, max 64 characters
   - `active`: Boolean indicating activation status
   - `description`: String, max 500 characters
   - `commands`: Object with at least `main` command defined

3. **Command Validation**:
   - Each command must have: `description`, `command` (shell command string)
   - Optional: `input`, `output` parameter specifications
   - Command strings must not contain obvious injection patterns
   - Input/output specs must define parameter names and types

4. **Dependency Validation** (Future):
   - Optional `dependencies` array listing required plugins
   - Dependency names must reference existing plugin names
   - Circular dependencies must be detected and rejected

5. **System Requirements Validation** (Future):
   - Optional `system_requirements` array listing required external tools
   - Tool names must match `[a-zA-Z0-9_-]+` pattern

### Security Controls

- **SC-003**: Plugin Descriptor Validation - JSON schema enforcement
- **SC-008**: Plugin Execution Isolation - Error handling for invalid plugins

### Validation Rules

| Field | Type | Required | Constraints | Error if Invalid |
|-------|------|----------|-------------|------------------|
| `name` | string | Yes | `^[a-zA-Z0-9_-]{1,64}$` | Fatal: reject plugin |
| `active` | boolean | Yes | true \| false | Fatal: reject plugin |
| `description` | string | Yes | max 500 chars | Fatal: reject plugin |
| `commands` | object | Yes | must contain `main` | Fatal: reject plugin |
| `commands.*.description` | string | Yes | max 200 chars | Fatal: reject command |
| `commands.*.command` | string | Yes | shell command | Fatal: reject command |
| `commands.*.input` | object | No | param name → spec | Warning if malformed |
| `commands.*.output` | object | No | param name → spec | Warning if malformed |
| `dependencies` | array | No | array of strings | Warning: dependency resolution disabled |
| `system_requirements` | array | No | array of tool names | Warning only |

### Test Requirements

**Valid Descriptor Tests**:
- Minimal valid descriptor (name, active, description, main command)
- Full descriptor with all optional fields
- Multiple commands (main, install, installed)
- Plugin with dependencies
- Plugin with system requirements

**Invalid Descriptor Tests**:
- Missing required field (name, active, description, commands)
- Invalid JSON syntax
- Invalid field types (active as string, commands as array)
- Invalid plugin name (spaces, special chars, too long)
- Command without description or command string
- Empty commands object
- Malformed dependency references
- Malformed system requirements

**Security Tests**:
- Command injection in command string: `"; rm -rf / #"`
- Path traversal in plugin name: `../../malicious`
- Oversized fields (buffer overflow attempt)
- Unicode/special characters in fields
- Circular dependency detection

### Acceptance Criteria

- [ ] JSON schema defined for plugin descriptors
- [ ] Schema validation implemented in plugins.sh
- [ ] Invalid descriptors rejected with clear error message
- [ ] Valid descriptors loaded successfully
- [ ] Unknown fields generate warnings (logged)
- [ ] Plugin name uniqueness enforced
- [ ] All validation tests pass
- [ ] Security tests detect malicious descriptors

### Plugin Descriptor JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["name", "active", "description", "commands"],
  "properties": {
    "name": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_-]{1,64}$",
      "description": "Unique plugin identifier"
    },
    "active": {
      "type": "boolean",
      "description": "Whether plugin is active"
    },
    "description": {
      "type": "string",
      "maxLength": 500,
      "description": "Human-readable plugin description"
    },
    "commands": {
      "type": "object",
      "required": ["main"],
      "properties": {
        "main": { "$ref": "#/definitions/command" },
        "install": { "$ref": "#/definitions/command" },
        "installed": { "$ref": "#/definitions/command" }
      },
      "additionalProperties": { "$ref": "#/definitions/command" }
    },
    "dependencies": {
      "type": "array",
      "items": { "type": "string", "pattern": "^[a-zA-Z0-9_-]+$" },
      "description": "List of required plugin names"
    },
    "system_requirements": {
      "type": "array",
      "items": { "type": "string", "pattern": "^[a-zA-Z0-9_-]+$" },
      "description": "List of required system tools"
    }
  },
  "definitions": {
    "command": {
      "type": "object",
      "required": ["description", "command"],
      "properties": {
        "description": { "type": "string", "maxLength": 200 },
        "command": { "type": "string", "maxLength": 1000 },
        "input": { "type": "object" },
        "output": { "type": "object" }
      }
    }
  }
}
```

### Related Requirements

- REQ_0003 (Plugin-Based Architecture)
- REQ_SEC_007 (Plugin Security Documentation)
- REQ_SEC_008 (Environment Variable Sanitization)

### Risk if Not Implemented

**Risk Level**: HIGH (3.53)

**STRIDE Score**: 3.67 | **DREAD Score**: 3.4

Without descriptor validation:
- **Malicious plugins** could be loaded with crafted descriptors
- **System crashes** from malformed JSON or invalid data types
- **Command injection** via unsanitized command strings
- **Plugin conflicts** from name collisions or circular dependencies
- **Difficult debugging** when plugins fail to load

### Implementation Notes

Validation should occur during plugin discovery phase before any plugin execution. Consider using Python's `jsonschema` library for robust validation, or implement custom validation in bash.

Example validation approach:
```bash
validate_plugin_descriptor() {
    local descriptor_file="$1"
    local plugin_name
    
    # Check file exists and is readable
    [[ -r "$descriptor_file" ]] || {
        log_error "Plugin descriptor not readable: $descriptor_file"
        return 1
    }
    
    # Validate JSON syntax
    jq empty "$descriptor_file" 2>/dev/null || {
        log_error "Invalid JSON in plugin descriptor: $descriptor_file"
        return 1
    }
    
    # Validate required fields
    plugin_name=$(jq -r '.name // empty' "$descriptor_file")
    [[ -n "$plugin_name" ]] || {
        log_error "Missing required field 'name' in: $descriptor_file"
        return 1
    }
    
    # Validate plugin name format
    [[ "$plugin_name" =~ ^[a-zA-Z0-9_-]{1,64}$ ]] || {
        log_error "Invalid plugin name '$plugin_name' in: $descriptor_file"
        return 1
    }
    
    # Additional validations...
    
    return 0
}
```

### References

- Security Concept Section 5.3 (Scope 3: Plugin System)
- Architecture Vision: 08_concepts.md - Plugin Architecture
- CWE-20: Improper Input Validation
- OWASP API Security: API8:2019 Injection
