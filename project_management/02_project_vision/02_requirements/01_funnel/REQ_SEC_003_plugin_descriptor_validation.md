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

> **FUNNEL STATUS NOTE:**  
> This requirement is pending formal review and approval by PeculiarMind. It is referenced in the architecture vision for planning purposes but is not yet formally accepted into the project scope.

---

## Description

All plugin descriptor files (descriptor.json) must be validated against the canonical plugin descriptor schema (defined in [ADR-003](../../03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md)) before plugin loading to prevent malformed or malicious plugins from compromising system security and stability.

### Specific Requirements

1. **Schema Validation**:
   - Descriptor must be valid JSON format
   - Required fields must be present: `name`, `version`, `description`, `commands` (per ADR-003)
   - Field types must match canonical schema (string, boolean, object, array)
   - Unknown fields should generate warnings but not block loading

2. **Required Fields** (per ADR-003):
   - `name`: String matching `[a-zA-Z0-9_-]+`, max 64 characters
   - `version`: Semantic version string (e.g., "1.0.0")
   - `description`: String, max 500 characters
   - `commands`: Object - plugin command definitions (REQUIRED)
     - **Standard Required Commands** (all plugins must implement):
       - `process`: Main file processing command
         - Must have `description` and `command` fields
         - Must define `input.filePath` parameter (type: string, required: true)
         - Must define `output` parameters (each with type and description)
       - `install`: Installation script command
         - Must have `description` and `command` fields
         - Must NOT have `input` parameters
         - Should define `output` parameters (e.g., success status)
       - `installed`: Installation check command
         - Must have `description` and `command` fields
         - Must NOT have `input` parameters
         - Should define `output` parameters (e.g., installed status)
     - **Optional Custom Commands**: Plugins may define additional commands
     - Each command structure:
       - `description` (string, required): What the command does
       - `command` (string, required): Shell command/script path
       - `input` (object, optional): Input parameter definitions
         - Each parameter must have: `type`, `description`
         - Optional: `required` (boolean, default: false)
         - **Parameter names must follow lowerCamelCase convention** (pattern: `^[a-z][a-zA-Z0-9]*$`)
       - `output` (object, optional): Output variable definitions
         - Each variable must have: `type`, `description`
         - **Variable names must follow lowerCamelCase convention** (pattern: `^[a-z][a-zA-Z0-9]*$`)

3. **Optional Fields** (per ADR-003):
   - `active`: Boolean indicating activation status (default: true)
   - `author`: String - plugin author information

4. **Command Parameter Validation**:
   - All input parameters must specify `type` (string, number, boolean, object, array)
   - All input parameters must specify `description`
   - All output parameters must specify `type` and `description`
   - **Parameter names must follow lowerCamelCase convention** (pattern: `^[a-z][a-zA-Z0-9]*$`)
   - Examples of valid names: `filePath`, `mimeType`, `fileSize`, `isActive`
   - Examples of invalid names: `FILE_PATH`, `file_path`, `FilePath`, `_filePath`
   - `install` and `installed` commands must not define `input` parameters

### Security Controls

- **SC-003**: Plugin Descriptor Validation - JSON schema enforcement
- **SC-008**: Plugin Execution Isolation - Error handling for invalid plugins

### Validation Rules

| Field | Type | Required | Constraints | Error if Invalid |
|-------|------|----------|-------------|------------------|
| `name` | string | Yes | `^[a-zA-Z0-9_-]{1,64}$` | Fatal: reject plugin |
| `version` | string | Yes | Semantic version format | Fatal: reject plugin |
| `description` | string | Yes | max 500 chars | Fatal: reject plugin |
| `commands` | object | Yes | must contain `process`, `install`, `installed` | Fatal: reject plugin |
| `commands.process` | object | Yes | requires `description`, `command`, `input.filePath`, `output` | Fatal: reject plugin |
| `commands.process.input.filePath` | object | Yes | must have `type: "string"`, `required: true`, `description` | Fatal: reject plugin |
| `commands.install` | object | Yes | requires `description`, `command`; must NOT have `input` | Fatal: reject plugin |
| `commands.installed` | object | Yes | requires `description`, `command`; must NOT have `input` | Fatal: reject plugin |
| `commands.*.description` | string | Yes | max 200 chars | Fatal: reject command |
| `commands.*.command` | string | Yes | shell command/script path | Fatal: reject command |
| `commands.*.input.*` | object | No | must have `type` and `description`; name must match `^[a-z][a-zA-Z0-9]*$` | Fatal: reject parameter |
| `commands.*.output.*` | object | No | must have `type` and `description`; name must match `^[a-z][a-zA-Z0-9]*$` | Fatal: reject parameter |
| `active` | boolean | No | true \| false (default: true) | Warning if invalid |
| `author` | string | No | no specific constraint | Warning only |

### Test Requirements

**Valid Descriptor Tests**:
- Minimal valid descriptor (name, version, description, commands with process/install/installed)
- Full descriptor with all optional fields
- Multiple commands (process, install, installed, plus custom commands)

**Invalid Descriptor Tests**:
- Missing required field (name, version, description, commands)
- Missing required commands (process, install, or installed)
- Invalid JSON syntax
- Invalid field types (active as string, commands as array)
- Invalid plugin name (spaces, special chars, too long)
- Command without description or command string
- Empty commands object

**Security Tests**:
- Command injection in command string: `"; rm -rf / #"`
- Path traversal in plugin name: `../../malicious`
- Oversized fields (buffer overflow attempt)
- Unicode/special characters in fields

### Acceptance Criteria

- [ ] JSON schema defined for plugin descriptors
- [ ] Schema validation implemented in plugins.sh
- [ ] Invalid descriptors rejected with clear error message
- [ ] Valid descriptors loaded successfully
- [ ] Unknown fields generate warnings (logged)
- [ ] Plugin name uniqueness enforced
- [ ] Required commands (process, install, installed) presence validated
- [ ] All validation tests pass
- [ ] Security tests detect malicious descriptors

### Plugin Descriptor JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["name", "version", "description", "commands"],
  "properties": {
    "name": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_-]{1,64}$",
      "description": "Unique plugin identifier"
    },
    "version": {
      "type": "string",
      "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$",
      "description": "Semantic version (e.g., 1.0.0)"
    },
    "description": {
      "type": "string",
      "maxLength": 500,
      "description": "Human-readable plugin description"
    },
    "author": {
      "type": "string",
      "description": "Plugin author/maintainer information"
    },
    "active": {
      "type": "boolean",
      "default": true,
      "description": "Whether plugin is active (default: true)"
    },
    "commands": {
      "type": "object",
      "required": ["process", "install", "installed"],
      "properties": {
        "process": {
          "allOf": [
            { "$ref": "#/definitions/command" },
            {
              "required": ["input", "output"],
              "properties": {
                "input": {
                  "type": "object",
                  "required": ["filePath"],
                  "properties": {
                    "filePath": {
                      "$ref": "#/definitions/parameter",
                      "properties": {
                        "type": { "const": "string" },
                        "required": { "const": true }
                      }
                    }
                  },
                  "additionalProperties": { "$ref": "#/definitions/parameter" },
                  "propertyNames": {
                    "pattern": "^[a-z][a-zA-Z0-9]*$",
                    "description": "Parameter names must follow lowerCamelCase convention"
                  }
                }
              }
            }
          ]
        },
        "install": {
          "allOf": [
            { "$ref": "#/definitions/command" },
            {
              "not": { "required": ["input"] },
              "description": "Install command must not have input parameters"
            }
          ]
        },
        "installed": {
          "allOf": [
            { "$ref": "#/definitions/command" },
            {
              "not": { "required": ["input"] },
              "description": "Installed command must not have input parameters"
            }
          ]
        }
      },
      "additionalProperties": { "$ref": "#/definitions/command" },
      "description": "Plugin commands - must include process, install, installed"
    }
  },
  "definitions": {
    "command": {
      "type": "object",
      "required": ["description", "command"],
      "properties": {
        "description": { "type": "string", "maxLength": 200 },
        "command": { "type": "string", "maxLength": 1000 },
        "input": {
          "type": "object",
          "additionalProperties": { "$ref": "#/definitions/parameter" },
          "propertyNames": {
            "pattern": "^[a-z][a-zA-Z0-9]*$",
            "description": "Parameter names must follow lowerCamelCase convention"
          }
        },
        "output": {
          "type": "object",
          "additionalProperties": { "$ref": "#/definitions/parameter" },
          "propertyNames": {
            "pattern": "^[a-z][a-zA-Z0-9]*$",
            "description": "Variable names must follow lowerCamelCase convention"
          }
        }
      }
    },
    "parameter": {
      "type": "object",
      "required": ["type", "description"],
      "properties": {
        "type": {
          "type": "string",
          "enum": ["string", "number", "boolean", "object", "array"]
        },
        "description": { "type": "string" },
        "required": { "type": "boolean", "default": false }
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
- **Plugin conflicts** from name collisions
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
