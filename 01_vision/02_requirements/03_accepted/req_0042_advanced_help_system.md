# Requirement: Advanced Multi-Level Help System

**ID**: req_0042

## Status
State: Accepted  
Created: 2026-02-09  
Last Updated: 2026-02-09

## Overview
The system shall provide multi-level help documentation including specialized help topics for plugins, templates, and detailed usage examples, accessible via dedicated command-line flags.

## Description
Requirement req_0035 defines basic help system (`-h`, `--help`) showing general usage, but the CLI Interface Concept (08_0003) specifies advanced help topics: `--help-plugins` for plugin system information and available plugins, `--help-template` for template syntax and variable reference, and `--help-examples` for detailed usage scenarios. These specialized help topics provide focused, in-depth information for specific aspects of the toolkit without overwhelming the primary help text. Plugin help enables users to discover available analysis capabilities, template help documents template authoring, and examples help demonstrates common workflows. All help content should be comprehensive yet concise, terminal-friendly (80-column max), and include practical examples.

## Motivation
From CLI Interface Concept (08_0003_cli_interface_concept.md):
```
HELP OPTIONS
  -h, --help                  Display this help message
  --help-plugins              List available plugins with descriptions
  --help-template             Show template variable reference
  --help-examples             Show detailed usage examples
```

From quality scenario U2: "User wants to know available capabilities, runs `./doc.doc.sh -p list`, sees formatted list of plugins with descriptions."

From quality scenario U4: "User encounters issue, runs with `-v` flag, detailed logging shows execution flow."

Advanced help topics improve discoverability, reduce learning curve, and enable self-service troubleshooting without external documentation.

## Category
- Type: Non-Functional (Usability)
- Priority: Medium

## Acceptance Criteria

### Plugin Help (`--help-plugins`)
- [ ] Running `./doc.doc.sh --help-plugins` displays comprehensive plugin system documentation
- [ ] Plugin help includes: plugin discovery mechanism, plugin status (active/inactive), descriptor format specification
- [ ] Plugin help includes dynamically generated list of available plugins with names, descriptions, status
- [ ] Plugin help explains how to create custom plugins with step-by-step guide
- [ ] Plugin help provides example descriptor.json with annotated fields
- [ ] Plugin help cross-references `-p list` command for runtime plugin listing

### Template Help (`--help-template`)
- [ ] Running `./doc.doc.sh --help-template` displays template system documentation
- [ ] Template help documents template syntax: variable substitution `{{var}}`, conditionals `{{#if}}`, loops `{{#each}}`, comments `{{!}}`
- [ ] Template help lists all available template variables organized by category (file metadata, analysis metadata, plugin data)
- [ ] Template help includes variable data types and example values
- [ ] Template help provides complete example template demonstrating all syntax features
- [ ] Template help explains template customization workflow (copy default, edit, test)
- [ ] Template help references default template location

### Examples Help (`--help-examples`)
- [ ] Running `./doc.doc.sh --help-examples` displays detailed usage examples
- [ ] Examples help includes at least 6 scenarios: basic analysis, workspace usage, incremental analysis, custom templates, debugging, scheduled/automated analysis
- [ ] Each example includes: scenario description, complete command with all flags, explanation of what command does
- [ ] Examples are copy-pasteable (properly escaped, complete commands)
- [ ] Examples demonstrate integration with other tools (piping, chaining commands, using workspace data)
- [ ] Examples include workspace maintenance scenarios (checking size, cleaning up)

### Help System Implementation
- [ ] Help topics implemented as separate functions (show_plugin_help, show_template_help, show_examples_help)
- [ ] Help system detects terminal width and formats accordingly (default 80 columns)
- [ ] Help topics respect `--no-pager` flag for piping to other commands
- [ ] All help output goes to stdout (not stderr) for piping to `less`, `grep`
- [ ] Help system exits with EXIT_SUCCESS after displaying (status code 0)

### Content Quality
- [ ] All help text follows consistent formatting (headings, indentation, spacing)
- [ ] Technical terms defined or explained on first use
- [ ] Help text includes references to additional documentation where appropriate
- [ ] Examples use realistic paths and filenames (not `foo`, `bar`)
- [ ] Help content reviewed for accuracy and completeness

### Integration with Basic Help
- [ ] Basic help (`-h`) mentions advanced help topics and how to access them
- [ ] Basic help remains concise (fits on one screen) by deferring details to advanced topics
- [ ] Advanced help topics include reference back to basic help for general usage
- [ ] Help topics can be accessed individually or collectively

## Related Requirements
- req_0035 (Comprehensive Help System) - defines basic help, this extends to advanced topics
- req_0024 (Plugin Listing) - `--help-plugins` complements `-p list` runtime listing
- req_0005 (Template-Based Reporting) - `--help-template` documents template system
- req_0034 (Default Template Provision) - template help references default template

## Technical Considerations

### Help System Architecture
```bash
show_help() {
  local topic="${1:-main}"
  
  case "$topic" in
    main|"") show_main_help ;;
    plugins) show_plugin_help ;;
    template) show_template_help ;;
    examples) show_examples_help ;;
    *) 
      echo "Unknown help topic: $topic" >&2
      echo "Available: main, plugins, template, examples" >&2
      exit 1
      ;;
  esac
}

# Argument parsing
case "$1" in
  --help-plugins) show_help plugins; exit 0 ;;
  --help-template) show_help template; exit 0 ;;
  --help-examples) show_help examples; exit 0 ;;
  -h|--help) show_help main; exit 0 ;;
esac
```

### Plugin Help Content Structure
- **Overview**: Purpose and benefits of plugin system
- **Discovery**: How plugins are found (platform-specific, generic)
- **Status**: Active vs inactive plugins, tool availability
- **Available Plugins**: Dynamically generated list from current installation
- **Descriptor Format**: Complete specification with examples
- **Creating Plugins**: Step-by-step guide with example

### Template Help Content Structure
- **Overview**: Purpose of template system
- **Template Location**: Default and custom template paths
- **Syntax Reference**: Variables, conditionals, loops, comments with examples
- **Available Variables**: Complete listing organized by category
- **Example Template**: Demonstrating all features
- **Customization Workflow**: How to create and test custom templates

### Examples Help Content Structure
- **Basic Usage**: First-time analysis scenarios
- **Workspace and Incremental**: Using workspace for performance
- **Custom Templates**: Template customization examples
- **Debugging**: Verbose mode, troubleshooting
- **Automation**: Cron jobs, scripting, error handling
- **Integration**: Combining with other tools, using workspace data

## Transition History
- [2026-02-09] Created in funnel by Requirements Engineer Agent - extracted from CLI Interface Concept analysis
- [2026-02-09] Moved to analyze for detailed analysis
- [2026-02-09] Moved to accepted by user - ready for implementation
