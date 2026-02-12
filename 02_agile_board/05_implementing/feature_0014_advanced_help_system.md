# Feature: Advanced Help System

**ID**: 0014  
**Type**: Feature Implementation  
**Status**: Implementing  
**Created**: 2026-02-09  
**Updated**: 2026-02-12 (Moved to implementing - TDD Red Phase)  
**Priority**: Medium

## Overview
Implement multi-level help system with specialized help topics for plugins, templates, and usage examples, providing comprehensive documentation accessible via command-line flags.

## Description
Enhance the basic help system with dedicated help topics that provide focused, in-depth information for specific toolkit aspects. Users can access plugin documentation (`--help-plugins`), template syntax reference (`--help-template`), and practical usage examples (`--help-examples`) without overwhelming the primary help text. Each help topic is comprehensive, terminal-friendly, and includes practical guidance for the specific feature area.

This feature improves discoverability, reduces learning curve, and enables self-service problem solving.

## Business Value
- Improves user onboarding experience
- Reduces support burden through comprehensive documentation
- Enables self-service learning and troubleshooting
- Demonstrates professionalism and completeness
- Facilitates plugin and template customization
- Enhances usability quality goal

## Related Requirements
- [req_0042](../../01_vision/02_requirements/03_accepted/req_0042_advanced_help_system.md) - Advanced Help System (PRIMARY)
- [req_0035](../../01_vision/02_requirements/03_accepted/req_0035_help_text.md) - Basic Help System
- [req_0034](../../01_vision/02_requirements/03_accepted/req_0034_template_variable_reference_documentation.md) - Template Variable Reference

## Acceptance Criteria

### Plugin Help (`--help-plugins`)
- [ ] System displays comprehensive plugin documentation when `--help-plugins` invoked
- [ ] Plugin help includes:
  - Plugin system overview (purpose, architecture)
  - Plugin discovery mechanism (directories, platforms)
  - Plugin status (active/inactive) explanation
  - Descriptor format specification with examples
- [ ] Plugin help includes dynamically generated list of available plugins:
  - Plugin name
  - Description
  - Status (active/inactive)
  - Required tools
  - File types supported
- [ ] Plugin help includes "Creating Custom Plugins" guide:
  - Step-by-step instructions
  - Descriptor template with annotations
  - Best practices
  - Common pitfalls
- [ ] Plugin help cross-references `-p list` command
- [ ] Plugin help is terminal-friendly (80 columns, proper formatting)

### Template Help (`--help-template`)
- [ ] System displays template documentation when `--help-template` invoked
- [ ] Template help documents complete template syntax:
  - Variable substitution: `{{variable}}` with examples
  - Conditionals: `{{#if}}...{{/if}}` and `{{#if}}...{{else}}...{{/if}}`
  - Loops: `{{#each array}}...{{/each}}` with context variables
  - Comments: `{{! comment}}`
  - Nesting rules and limitations
- [ ] Template help lists all available variables organized by category:
  - **File Metadata**: file_path, file_size, file_type, file_last_modified, etc.
  - **Analysis Metadata**: last_scanned, plugins_executed
  - **Plugin Data**: content.*, metadata.* (dynamically from plugins)
- [ ] Template help includes data types and example values for each variable
- [ ] Template help provides complete template example with annotations
- [ ] Template help includes troubleshooting section:
  - Common errors (unbalanced tags, missing variables)
  - Debugging tips
  - Performance considerations
- [ ] Template help is terminal-friendly (80 columns, proper formatting)

### Examples Help (`--help-examples`)
- [ ] System displays usage examples when `--help-examples` invoked
- [ ] Examples help includes multiple use case scenarios:
  - **Basic Usage**: Simple directory analysis with default template
  - **Custom Templates**: Using custom template for specialized reports
  - **Incremental Analysis**: Only processing changed files
  - **Full Rescan**: Forcing complete re-analysis
  - **Plugin Management**: Listing and managing plugins
  - **Verbose Mode**: Debugging with verbose logging
  - **Automation**: Cron job and scripting examples
  - **Integration**: Using workspace data with other tools
- [ ] Each example includes:
  - Scenario description
  - Complete command with all flags
  - Expected output or result
  - Explanation of what happens
- [ ] Examples help organized by user persona:
  - First-time user
  - Advanced user
  - Automation/integration
  - Template customization
- [ ] Examples help is terminal-friendly (80 columns, proper formatting)

### Help System Infrastructure
- [ ] System implements `show_help()` function for each help topic
- [ ] System validates help flag before other argument processing
- [ ] System exits after displaying help (doesn't execute main workflow)
- [ ] System formats help text for terminal readability:
  - 80-column max width
  - Consistent indentation
  - Clear section headers
  - Code blocks properly formatted
- [ ] System provides consistent header/footer for all help topics

### Error Handling
- [ ] System handles unknown help flags gracefully (suggest valid options)
- [ ] System handles help display errors (shouldn't happen, but catch anyway)

## Technical Considerations

### Implementation Approach
```bash
show_help_plugins() {
  cat <<'EOF'
doc.doc.sh - Plugin System Help

OVERVIEW
  Plugins extend doc.doc.sh with custom analysis capabilities. Each plugin
  wraps a CLI tool and declares what data it consumes and provides. The
  system automatically orchestrates plugin execution based on dependencies.

PLUGIN DISCOVERY
  Plugins are discovered in these directories:
    • scripts/plugins/all/       (all platforms)
    • scripts/plugins/$PLATFORM/ (current platform only)

  Each plugin directory must contain a descriptor.json file.

PLUGIN STATUS
  • active: Plugin enabled, will execute if tools available
  • inactive: Plugin disabled, will not execute
  • missing_tools: Plugin active but required tools unavailable

DESCRIPTOR FORMAT
  {
    "name": "plugin_name",
    "description": "What this plugin does",
    "active": true,
    "check_commandline": "command -v tool_name",
    "install_commandline": "apt-get install -y tool_name",
    "execute_commandline": "tool_name ... | read -r output",
    "consumes": ["input_field"],
    "provides": ["output_field"],
    "processes": {
      "mime_types": ["application/pdf"],
      "file_extensions": [".pdf"]
    }
  }

AVAILABLE PLUGINS
EOF
  
  # Dynamically list plugins
  list_plugins_detailed
  
  cat <<'EOF'

CREATING CUSTOM PLUGINS
  1. Create plugin directory: scripts/plugins/all/my_plugin/
  2. Create descriptor.json with required fields
  3. Implement plugin logic (can be separate script)
  4. Test with: ./doc.doc.sh -p list
  5. Activate: Set "active": true in descriptor

  See example plugins in scripts/plugins/all/ for reference.

SEE ALSO
  ./doc.doc.sh -p list            List available plugins
  ./doc.doc.sh --help-template    Template variable reference
  ./doc.doc.sh --help-examples    Usage examples

EOF
}

show_help_template() {
  cat <<'EOF'
doc.doc.sh - Template System Help

OVERVIEW
  Templates are Markdown files with special syntax for variable substitution,
  conditionals, and loops. The system merges workspace data with templates
  to generate customized reports.

SYNTAX REFERENCE

  Variables (substitute with data):
    {{variable_name}}
    {{nested.field.name}}
    
  Conditionals (render block if condition true):
    {{#if variable}}
      Content shown if variable exists and non-empty
    {{/if}}
    
    {{#if variable}}
      Shown if true
    {{else}}
      Shown if false
    {{/if}}
    
  Loops (iterate over arrays):
    {{#each array_name}}
      {{this}}          (current item)
      {{@index}}        (0-based position)
    {{/each}}
    
  Comments (removed from output):
    {{! This won't appear in the report}}

AVAILABLE VARIABLES

  File Metadata:
    {{file_path}}              Absolute path to file
    {{file_path_relative}}     Path relative to source directory
    {{file_size}}              Size in bytes (number)
    {{file_size_human}}        Human-readable size (e.g., "2.5 MB")
    {{file_type}}              MIME type (e.g., "application/pdf")
    {{file_last_modified}}     Modification timestamp
    {{format_date file_last_modified}}  Formatted date
    
  Analysis Metadata:
    {{last_scanned}}           When file was last analyzed
    {{plugins_executed}}       Array of plugin execution records
    
  Plugin Data (varies by plugins):
    {{content.text}}           Extracted text content
    {{content.word_count}}     Word count
    {{content.summary}}        Content summary
    {{content.tags}}           Array of tags/keywords

COMPLETE EXAMPLE

  # Analysis Report: {{filename}}

  ## File Information
  - **Path**: `{{file_path_relative}}`
  - **Size**: {{file_size_human}}
  - **Type**: {{file_type}}

  ## Content Summary
  {{#if content.summary}}
  {{content.summary}}
  {{else}}
  No summary available.
  {{/if}}

  ## Tags
  {{#if content.tags}}
  {{#each content.tags}}
  - {{this}}
  {{/each}}
  {{else}}
  No tags.
  {{/if}}

TROUBLESHOOTING

  • "Unbalanced tags" error: Check all {{#if}}/{{/if}} and {{#each}}/{{/each}}
    pairs are properly closed
  • Missing variable: Use {{#if variable}} to handle optional data gracefully
  • Nested loops: Supported up to 2 levels deep

SEE ALSO
  ./doc.doc.sh --help-examples    Template usage examples

EOF
}

show_help_examples() {
  cat <<'EOF'
doc.doc.sh - Usage Examples

BASIC USAGE

  Analyze directory with default template:
    ./doc.doc.sh -d ~/documents -t ~/reports -w ~/workspace -m template.md

  Enable verbose logging:
    ./doc.doc.sh -d ~/documents -t ~/reports -w ~/workspace -m template.md -v

INCREMENTAL ANALYSIS

  First run (analyzes all files):
    ./doc.doc.sh -d ~/documents -t ~/reports -w ~/workspace -m template.md

  Subsequent runs (only changed files):
    ./doc.doc.sh -d ~/documents -t ~/reports -w ~/workspace -m template.md

  Force full rescan:
    ./doc.doc.sh -d ~/documents -t ~/reports -w ~/workspace -m template.md -f

PLUGIN MANAGEMENT

  List available plugins:
    ./doc.doc.sh -p list

  Get detailed plugin information:
    ./doc.doc.sh --help-plugins

CUSTOM TEMPLATES

  Use custom template:
    ./doc.doc.sh -d ~/docs -t ~/reports -w ~/workspace -m my_template.md

  Generate aggregated summary (opt-in):
    ./doc.doc.sh -d ~/docs -t ~/reports -w ~/workspace -m template.md --summary

AUTOMATION

  Cron job (daily analysis at 2 AM):
    0 2 * * * /path/to/doc.doc.sh -d ~/documents -t ~/reports -w ~/workspace -m template.md

  Shell script with error checking:
    #!/bin/bash
    if ./doc.doc.sh -d ~/docs -t ~/reports -w ~/workspace -m template.md; then
      echo "Analysis complete"
    else
      echo "Analysis failed" >&2
      exit 1
    fi

TROUBLESHOOTING

  Debug with verbose mode:
    ./doc.doc.sh -d ~/docs -t ~/reports -w ~/workspace -m template.md -v

  Check what would be analyzed:
    find ~/documents -type f | wc -l

  Verify workspace integrity:
    ls -la ~/workspace/files/ | head

SEE ALSO
  ./doc.doc.sh --help             General help
  ./doc.doc.sh --help-plugins     Plugin documentation
  ./doc.doc.sh --help-template    Template syntax reference

EOF
}
```

### Integration Points
- **CLI Argument Parser**: Recognizes help flags
- **Plugin Manager**: Provides plugin list for help display
- **Template Engine**: Reference for template syntax

### Dependencies
- Basic script structure (feature_0001) ✅
- Plugin listing (feature_0003) ✅ (for plugin help)

### Performance Considerations
- Help display is fast (no processing required)
- Dynamic plugin listing efficient

### Security Considerations
- No security implications (read-only documentation display)

## Dependencies
- Requires: Basic script structure (feature_0001) ✅
- Requires: Plugin listing (feature_0003) ✅

## Testing Strategy
- Unit tests: Help text generation
- Integration tests: Help flag recognition
- Integration tests: Dynamic plugin listing in help
- Manual tests: Terminal formatting and readability
- User acceptance tests: Help usefulness

## Definition of Done
- [ ] All acceptance criteria met
- [ ] All help topics implemented and tested
- [ ] Terminal formatting verified (80 columns)
- [ ] Code reviewed and approved
- [ ] User feedback incorporated
- [ ] Documentation  complete and accurate
