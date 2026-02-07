# Feature: Plugin Listing

**ID**: 0003  
**Type**: Feature Implementation  
**Status**: Ready  
**Created**: 2026-02-06  
**Updated**: 2026-02-07 (Moved to ready after analysis)  
**Priority**: High  
**Depends On**: feature_0001

## Overview
Implement the `-p list` command to discover and display all available plugins with their name, description, and activation status. This feature enables users to discover what analysis capabilities are available in their installation.

## Description
Extend the doc.doc.sh script with plugin discovery and listing functionality that:
- Discovers plugins from the `plugins/` directory structure
- Supports platform-specific plugin directories (e.g., `plugins/ubuntu/`, `plugins/all/`)
- Reads plugin descriptor.json files to extract metadata
- Displays formatted list showing plugin name, description, and active status
- Handles errors gracefully (missing directories, malformed JSON, permissions)
- Integrates with verbose logging from feature_0001

This feature implements the `-p list` subcommand, providing essential visibility into which plugins are available and active in the system.

## Business Value
- Provides users with discovery mechanism for available functionality
- Enables transparency about which plugins are active/inactive
- Reduces user friction in understanding tool capabilities
- Supports troubleshooting (users can verify plugin availability)
- Foundation for future plugin management commands

## Related Requirements
- [req_0001](../../01_vision/02_requirements/03_accepted/req_0001_single_command_directory_analysis.md) - Single Command Directory Analysis (CLI framework)
- [req_0006](../../01_vision/02_requirements/03_accepted/req_0006_verbose_logging_mode.md) - Verbose Logging Mode
- [req_0007](../../01_vision/02_requirements/03_accepted/req_0007_tool_availability_verification.md) - Tool Availability Verification (JSON parsing tools)
- [req_0009](../../01_vision/02_requirements/03_accepted/req_0009_lightweight_implementation.md) - Lightweight Implementation
- [req_0021](../../01_vision/02_requirements/03_accepted/req_0021_toolkit_extensibility_and_plugin_architecture.md) - Toolkit Extensibility (architectural context)
- [req_0022](../../01_vision/02_requirements/03_accepted/req_0022_plugin_based_extensibility.md) - Plugin-based Extensibility (descriptor schema)
- [req_0023](../../01_vision/02_requirements/03_accepted/req_0023_data_driven_execution_flow.md) - Data-driven Execution Flow (consumes/provides model)
- [req_0024](../../01_vision/02_requirements/03_accepted/req_0024_plugin_listing.md) - Plugin Listing (primary requirement implemented by this feature)

## Acceptance Criteria

### Argument Parsing Integration
- [ ] `-p list` or `--plugins list` argument triggers plugin listing
- [ ] Plugin listing command exits after displaying list (does not start analysis)
- [ ] Invalid `-p` subcommands show error and available subcommands

### Plugin Discovery
- [ ] Script correctly locates `plugins/` directory relative to script location
- [ ] Script discovers platform-specific plugin directories (e.g., `plugins/ubuntu/`)
- [ ] Script discovers generic/cross-platform plugins (e.g., `plugins/all/`)
- [ ] Script recursively scans plugin directories for descriptor.json files
- [ ] Script handles missing plugins directory gracefully (error message + exit code 2)
- [ ] Script uses platform detection from feature_0001 to prioritize plugins

### Plugin Metadata Reading
- [ ] Script reads and parses descriptor.json files for each plugin
- [ ] Script extracts plugin `name` field (required)
- [ ] Script extracts plugin `description` field (required)
- [ ] Script extracts plugin `active` field (boolean, default false)
- [ ] Script handles malformed JSON gracefully with clear error message
- [ ] Script handles missing required fields with warning (skip that plugin)
- [ ] Script uses `jq` if available, falls back to python or grep/sed parsing
- [ ] Script validates descriptor schema matches req_0022 specification

### Plugin List Display
- [ ] Display shows clear header (e.g., "Available Plugins:")
- [ ] Each plugin shown on separate line or in table format
- [ ] Plugin name displayed prominently
- [ ] Plugin description displayed (truncated if exceeds 80 characters)
- [ ] Active status clearly indicated (e.g., [ACTIVE] or [INACTIVE])
- [ ] List is sorted alphabetically by plugin name
- [ ] Output is human-readable and properly formatted
- [ ] Empty plugin list handled gracefully ("No plugins found" message)
- [ ] Output goes to stdout for piping compatibility

### Output Format Example
```
Available Plugins:
====================================
[ACTIVE]   stat
           Retrieves file statistics using stat command
           
[INACTIVE] ocrmypdf
           Performs OCR on PDF files to extract text content
           
[ACTIVE]   markdown-analyzer
           Analyzes markdown file structure and content
```

### Error Handling
- [ ] Missing plugins directory: Clear error message, exits with FILE_ERROR code
- [ ] Malformed JSON in descriptor: Shows plugin path and parsing error, continues with other plugins
- [ ] Permission errors accessing plugins: Shows error, exits with FILE_ERROR code
- [ ] Invalid plugin structure (missing descriptor.json): Logged in verbose mode, skipped silently otherwise
- [ ] Missing required fields: Warning in verbose mode, plugin skipped
- [ ] All errors include context for troubleshooting

### Plugin Directory Priority
- [ ] Platform-specific plugins discovered first (e.g., `ubuntu/` for Ubuntu systems)
- [ ] Generic plugins discovered second (`all/` directory)
- [ ] If same plugin exists in both, platform-specific takes precedence
- [ ] Priority logic clearly documented in code comments

### Verbose Mode Integration
- [ ] Verbose mode shows plugin directory search paths
- [ ] Verbose mode shows each descriptor.json file being read
- [ ] Verbose mode shows platform detection results
- [ ] Verbose mode shows any skipped plugins with reason
- [ ] Verbose mode shows plugin priority resolution (platform vs generic)
- [ ] Verbose output uses logging infrastructure from feature_0001

### Code Quality
- [ ] Plugin discovery logic in separate function (discover_plugins())
- [ ] JSON parsing logic in separate function (parse_descriptor())
- [ ] Display formatting in separate function (display_plugin_list())
- [ ] Functions follow single responsibility principle
- [ ] Plugin data stored in arrays or associative arrays
- [ ] No global mutable state except return values

## Technical Considerations

### Plugin Directory Structure
```
scripts/plugins/
├── all/                    # Cross-platform plugins
│   └── example/
│       └── descriptor.json
├── ubuntu/                 # Ubuntu-specific plugins
│   ├── stat/
│   │   ├── descriptor.json
│   │   └── install.sh
│   └── ocrmypdf/
│       └── descriptor.json
└── generic/                # Generic Unix plugins
```

### Plugin Discovery Pattern
```bash
discover_plugins() {
  local plugins_dir="${SCRIPT_DIR}/plugins"
  local platform_dir="${plugins_dir}/${PLATFORM}"
  local all_dir="${plugins_dir}/all"
  
  # Check if plugins directory exists
  if [[ ! -d "${plugins_dir}" ]]; then
    echo "Error: Plugins directory not found: ${plugins_dir}" >&2
    exit ${EXIT_FILE_ERROR}
  fi
  
  # Discover platform-specific plugins first
  if [[ -d "${platform_dir}" ]]; then
    find "${platform_dir}" -name "descriptor.json" -print
  fi
  
  # Then discover cross-platform plugins
  if [[ -d "${all_dir}" ]]; then
    find "${all_dir}" -name "descriptor.json" -print
  fi
}
```

### JSON Parsing Options Priority
1. **jq** (preferred if available): `jq -r '.name' descriptor.json`
2. **python** (fallback): `python3 -c "import json,sys; print(json.load(sys.stdin)['name'])"`
3. **grep/sed** (last resort for simple cases): Limited reliability, avoid if possible

### Descriptor.json Schema (from req_0022)
```json
{
  "name": "plugin-name",
  "description": "What this plugin does",
  "active": true,
  "version": "1.0.0",
  "processes": {
    "mime_types": [],
    "file_extensions": []
  },
  "consumes": {
    "file_path_absolute": {
      "type": "string",
      "description": "Input parameter"
    }
  },
  "provides": {
    "file_size": {
      "type": "integer",
      "description": "Output parameter"
    }
  },
  "commandline": "...",
  "check_commandline": "...",
  "install_commandline": "..."
}
```

**Required fields for listing**: name, description, active

### Plugin List Formatting Pattern
```bash
display_plugin_list() {
  local -a plugins=("$@")
  
  if [[ ${#plugins[@]} -eq 0 ]]; then
    echo "No plugins found."
    return
  fi
  
  echo "Available Plugins:"
  echo "===================================="
  
  # Sort plugins by name
  IFS=$'\n' sorted=($(sort <<<"${plugins[*]}"))
  unset IFS
  
  for plugin in "${sorted[@]}"; do
    local name="${plugin%%|*}"
    local rest="${plugin#*|}"
    local description="${rest%%|*}"
    local active="${rest##*|}"
    
    if [[ "${active}" == "true" ]]; then
      printf "[ACTIVE]   %s\n" "${name}"
    else
      printf "[INACTIVE] %s\n" "${name}"
    fi
    printf "           %s\n\n" "${description}"
  done
}
```

## Implementation Approach

### Phase 1: Argument Parsing Extension
1. Extend parse_arguments() from feature_0001 to handle `-p list`
2. Add validation for `-p` subcommands
3. Set flag to trigger plugin listing mode

### Phase 2: Plugin Discovery
1. Implement discover_plugins() function
2. Use platform detection from feature_0001
3. Find descriptor.json files recursively
4. Handle missing plugin directory errors

### Phase 3: Descriptor Parsing
1. Implement parse_descriptor() function
2. Detect available JSON parsing tool (jq, python, fallback)
3. Extract name, description, active fields
4. Handle parsing errors gracefully

### Phase 4: Plugin List Display
1. Implement display_plugin_list() function
2. Format output with active/inactive indicators
3. Sort plugins alphabetically
4. Handle empty lists

### Phase 5: Integration and Testing
1. Test with existing stat plugin
2. Test with missing plugins directory
3. Test with malformed descriptors
4. Test verbose mode output
5. Verify all acceptance criteria met

## Testing Scenarios

### Happy Path
- Script with valid plugins directory and multiple plugins
- Mix of active and inactive plugins
- Both platform-specific and generic plugins present
- Valid descriptor.json files

### Error Cases
- No plugins directory exists
- Empty plugins directory
- Descriptor.json missing in plugin directory
- Malformed JSON in descriptor
- Missing required fields (name, description) in descriptor
- No read permissions on plugin directory
- No read permissions on descriptor.json file

### Edge Cases
- Plugin with very long description (verify truncation)
- Zero plugins available
- Special characters in plugin names/descriptions
- Duplicate plugin names (platform vs all directory)
- descriptor.json with extra fields (should not error)

### Verbose Mode
- Verbose output shows all plugin discovery steps
- Verbose output shows JSON parsing details
- Verbose output shows skipped/invalid plugins

## Dependencies
- Feature 0001 (Basic Script Structure) - provides argument parsing, logging, platform detection
- bash 4.0+
- coreutils (find, sort)
- jq (preferred) or python3 (fallback) for JSON parsing

## Definition of Done
- [ ] All acceptance criteria met and verified
- [ ] Code reviewed for quality and best practices
- [ ] Tests pass for all scenarios (happy path, error cases, edge cases)
- [ ] Verbose mode testing complete
- [ ] Integration with feature_0001 verified
- [ ] Documentation updated (inline comments)
- [ ] Architect Agent confirms compliance with architecture vision
- [ ] No regression in feature_0001 functionality
- [ ] Pull request created and ready for human review
