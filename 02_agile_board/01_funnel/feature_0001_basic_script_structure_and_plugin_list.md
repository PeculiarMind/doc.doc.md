# Feature: Basic Script Structure and Plugin List Command

**ID**: 0001  
**Type**: Feature Implementation  
**Status**: New  
**Created**: 2026-02-06  
**Priority**: High

## Overview
Establish the foundational structure of the doc.doc.sh script and implement the `-p list` argument to display all available plugins with their name, description, and activation status. This feature provides the core framework for the tool and enables users to discover available plugins.

## Description
Create the basic skeleton structure of the doc.doc.sh script with proper argument parsing, help system, and plugin discovery functionality. The script will:
- Parse command-line arguments following POSIX conventions
- Implement help text accessible via `-h` flag
- Discover plugins from the `plugins/` directory structure
- Read plugin descriptor.json files to extract metadata
- Display formatted list of plugins showing name, description, and active status
- Support platform-specific plugin discovery (e.g., Ubuntu, generic)
- Provide clear, user-friendly output

This feature establishes the foundation upon which all other features will be built and provides essential plugin visibility for users.

## Business Value
- Provides users with discovery mechanism for available functionality
- Establishes consistent CLI interface following Unix conventions
- Creates extensible foundation for adding future features
- Enables transparency about which plugins are active/inactive
- Reduces user friction in understanding tool capabilities

## Related Requirements
- [req_0001](../../01_vision/02_requirements/03_accepted/req_0001_single_command_directory_analysis.md) - Single Command Directory Analysis
- [req_0006](../../01_vision/02_requirements/03_accepted/req_0006_verbose_logging_mode.md) - Verbose Logging Mode
- [req_0007](../../01_vision/02_requirements/03_accepted/req_0007_tool_availability_verification.md) - Tool Availability Verification
- [req_0009](../../01_vision/02_requirements/03_accepted/req_0009_lightweight_implementation.md) - Lightweight Implementation
- [req_0010](../../01_vision/02_requirements/01_funnel/req_0010_unix_tool_composability.md) - Unix Tool Composability
- [req_0017](../../01_vision/02_requirements/01_funnel/req_0017_script_entry_point.md) - Script Entry Point
- [req_0022](../../01_vision/02_requirements/03_accepted/req_0022_plugin_based_extensibility.md) - Plugin-based Extensibility

## Acceptance Criteria

### Script Structure
- [ ] Script has proper shebang line (`#!/usr/bin/env bash`)
- [ ] Script includes usage/help function showing all available arguments
- [ ] Script has argument parsing logic supporting POSIX-style flags
- [ ] Script includes version information
- [ ] Script has proper error handling and exit codes
- [ ] Script follows bash best practices (set -e, set -u, set -o pipefail)
- [ ] Script is executable (`chmod +x`)
- [ ] Script has clear comments documenting major sections

### Argument Parsing
- [ ] `-h` or `--help` displays usage information and exits
- [ ] `-v` or `--verbose` enables verbose logging mode
- [ ] `-p list` or `--plugins list` displays plugin list
- [ ] Invalid arguments display usage and exit with error code
- [ ] Help text shows all available options with descriptions
- [ ] Help text includes usage examples

### Plugin Discovery
- [ ] Script correctly locates `plugins/` directory relative to script location
- [ ] Script discovers platform-specific plugin directories (e.g., `plugins/ubuntu/`)
- [ ] Script discovers generic/cross-platform plugins (e.g., `plugins/all/`)
- [ ] Script recursively scans plugin directories for descriptor.json files
- [ ] Script handles missing plugins directory gracefully
- [ ] Script detects platform (Ubuntu, generic Unix, etc.) for platform-specific discovery

### Plugin Metadata Reading
- [ ] Script reads and parses descriptor.json files for each plugin
- [ ] Script extracts plugin `name` field
- [ ] Script extracts plugin `description` field
- [ ] Script extracts plugin `active` field (boolean)
- [ ] Script handles malformed JSON gracefully with error message
- [ ] Script handles missing required fields in descriptor
- [ ] Script uses `jq` or native bash JSON parsing (lightweight approach)

### Plugin List Display (`-p list`)
- [ ] Display shows clear header (e.g., "Available Plugins:")
- [ ] Each plugin shown on separate line or in table format
- [ ] Plugin name displayed prominently
- [ ] Plugin description displayed (truncated if too long)
- [ ] Active status clearly indicated (e.g., [ACTIVE] or [INACTIVE])
- [ ] List is sorted alphabetically by plugin name
- [ ] Output is human-readable and properly formatted
- [ ] Empty plugin list handled gracefully ("No plugins found")

### Output Format Example
```
Available Plugins:
====================================
[ACTIVE]   stat
           Extracts file metadata using stat command
           
[INACTIVE] ocrmypdf
           Performs OCR on PDF files to extract text content
           
[ACTIVE]   markdown-analyzer
           Analyzes markdown file structure and content
```

### Error Handling
- [ ] Missing plugins directory shows informative message
- [ ] Malformed JSON in descriptor shows plugin path and error
- [ ] Permission errors accessing plugins show clear message
- [ ] Invalid plugin structure (missing descriptor.json) logged in verbose mode
- [ ] All errors include context for troubleshooting

### Platform Support
- [ ] Script detects current platform (uname, /etc/os-release, etc.)
- [ ] Script prioritizes platform-specific plugins over generic
- [ ] Script handles both Ubuntu and generic Unix plugins
- [ ] Platform detection failure defaults to generic/all plugins

### Verbose Mode Integration
- [ ] Verbose mode (`-v`) shows plugin directory search paths
- [ ] Verbose mode shows which descriptor files are being read
- [ ] Verbose mode shows platform detection information
- [ ] Verbose mode shows any skipped plugins (malformed, inaccessible)
- [ ] Verbose output uses consistent prefix (e.g., "[VERBOSE]")

### Code Quality
- [ ] Functions are small and focused (single responsibility)
- [ ] Variables use meaningful names
- [ ] Magic numbers/strings extracted to named constants
- [ ] Code follows consistent indentation (2 or 4 spaces)
- [ ] Error messages are clear and actionable
- [ ] No hardcoded paths (use relative to script location)

## Technical Considerations

### Script Location and Paths
- Use `$0` and `dirname` to determine script location
- Construct plugin paths relative to script: `$(dirname "$0")/plugins`
- Support being called from any directory

### JSON Parsing Options
1. **jq** (preferred if available): Lightweight, standard JSON processor
2. **python -m json.tool** (fallback): Available on most systems
3. **grep/sed parsing** (last resort): Limited but no dependencies

### Platform Detection
```bash
# Detect OS/platform
if [ -f /etc/os-release ]; then
    . /etc/os-release
    PLATFORM="${ID:-generic}"
else
    PLATFORM="generic"
fi
```

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

### Descriptor.json Schema (Reference)
```json
{
  "name": "plugin-name",
  "description": "What this plugin does",
  "active": true,
  "version": "1.0.0",
  "commandline": "command to execute",
  "check_commandline": "command to check availability",
  "consumes": [],
  "provides": []
}
```

## Implementation Approach

### Phase 1: Basic Structure
1. Create script skeleton with shebang and basic setup
2. Implement help function with usage text
3. Add argument parsing for `-h`, `-v`, `-p`
4. Add exit codes for different error conditions

### Phase 2: Plugin Discovery
1. Implement platform detection logic
2. Create function to find plugin directories
3. Create function to recursively find descriptor.json files
4. Add error handling for missing directories

### Phase 3: Descriptor Parsing
1. Implement JSON parsing (try jq first, fallback to alternatives)
2. Create function to extract name, description, active fields
3. Add validation for required fields
4. Add error handling for malformed JSON

### Phase 4: Plugin List Display
1. Create formatting function for plugin list
2. Implement sorting by name
3. Add active/inactive status indicators
4. Format output for readability

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

### Error Cases
- No plugins directory exists
- Empty plugins directory
- Descriptor.json missing in plugin directory
- Malformed JSON in descriptor
- Missing required fields in descriptor
- No read permissions on plugin directory

### Edge Cases
- Plugin with very long description (test truncation)
- Zero plugins available
- Special characters in plugin names/descriptions
- Called from different working directories

## Dependencies
- bash 4.0+
- coreutils (dirname, basename, readlink)
- jq (preferred) or python (fallback) for JSON parsing
- Platform detection: /etc/os-release or uname

## Future Enhancements (Out of Scope)
- Plugin filtering by status (only active, only inactive)
- Plugin search/filter by name or description
- Detailed plugin information view (`-p info <plugin-name>`)
- Plugin enable/disable functionality
- Plugin installation/management commands

## Definition of Done
- [ ] All acceptance criteria met and verified
- [ ] Code reviewed for quality and best practices
- [ ] Tests pass for all scenarios (happy path and error cases)
- [ ] Documentation updated (inline comments, help text)
- [ ] Architect Agent confirms compliance with architecture vision
- [ ] No regression in existing functionality
- [ ] Pull request created and ready for human review
