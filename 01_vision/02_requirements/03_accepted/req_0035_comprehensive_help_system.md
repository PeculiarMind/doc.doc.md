# Requirement: Comprehensive Help System

**ID**: req_0035

## Status
State: Accepted  
Created: 2026-02-09  
Last Updated: 2026-02-09

## Overview
The system shall provide comprehensive, multi-level help documentation accessible via command-line flags, including usage examples, parameter descriptions, and common workflows.

## Description
While req_0010 and req_0017 mention `-h` flag support, there is no explicit requirement defining the completeness and quality of the help system. First-time users must understand the toolkit's capabilities, required parameters, optional flags, and usage patterns without consulting external documentation. The help system should provide quick reference (`-h` or `--help`), detailed usage examples, parameter descriptions with default values, and examples of common workflows. Help output must be concise yet comprehensive, following standard CLI conventions for formatting and organization.

## Motivation
From quality goals (1.2): "Usability - Provide an intuitive and user-friendly interface for both technical and non-technical users."

From quality scenario U1: "User unfamiliar with tool runs `./doc.doc.sh -h`, receives clear help text with examples, understands basic usage within 2 minutes."

From req_0010: "Command-line interface follows standard UNIX conventions (e.g., `-h` for help)."

A comprehensive help system is fundamental to usability and reduces the barrier to entry for new users. The toolkit should be self-documenting to the extent possible, allowing users to discover functionality through the CLI without external documentation.

## Category
- Type: Non-Functional (Usability)
- Priority: Medium

## Acceptance Criteria

### Basic Help Output
- [ ] Running `./doc.doc.sh -h` or `./doc.doc.sh --help` displays help documentation
- [ ] Running `./doc.doc.sh` without arguments displays concise usage summary and suggests `-h` for details
- [ ] Help output includes synopsis (one-line description of purpose)
- [ ] Help output includes all command-line parameters with descriptions
- [ ] Help output includes default values for all optional parameters
- [ ] Help output indicates which parameters are required vs. optional

### Usage Examples
- [ ] Help includes at least 3 concrete usage examples:
  - Basic analysis with default template
  - Analysis with custom template and verbose output
  - Incremental re-analysis with workspace
- [ ] Examples use realistic paths and demonstrate common workflows
- [ ] Examples are copy-pasteable (properly escaped, complete commands)
- [ ] Examples include explanatory text describing what each does

### Parameter Documentation
- [ ] Each parameter documented with:
  - Short flag and long flag (e.g., `-d, --directory`)
  - Parameter type (path, string, flag)
  - Description of purpose
  - Default value if applicable
  - Example value
- [ ] Parameter constraints documented (e.g., "must be absolute path")
- [ ] Related parameters grouped logically (input, output, configuration, debugging)

### Advanced Help Features
- [ ] System supports `--help-plugins` to list available plugins with descriptions
- [ ] System supports `--help-template` to show template variable reference
- [ ] System supports `--version` to show version and build information
- [ ] Help output respects terminal width (wraps text appropriately)

### Help Output Formatting
- [ ] Clear visual hierarchy (headings, indentation, spacing)
- [ ] Consistent formatting across all help sections
- [ ] No line exceeds 80 characters (terminal-friendly)
- [ ] Uses standard UNIX man page conventions where applicable

### Discoverability
- [ ] Invalid parameters result in error message suggesting `--help` for usage
- [ ] Missing required parameters result in specific error and suggest `--help`
- [ ] Help text mentions where to find additional documentation (README, website)

## Related Requirements
- req_0010 (Unix Tool Composability) - help follows UNIX conventions
- req_0017 (Script Entry Point) - help accessible via main script
- req_0024 (Plugin Listing) - help system includes plugin information

## Technical Considerations

### Help Output Structure
```
Usage: doc.doc.sh -d <directory> -t <target> [options]

DESCRIPTION
    Analyzes directories and generates Markdown reports using CLI tools.
    Supports incremental analysis, plugin-based extensibility, and template customization.

REQUIRED PARAMETERS
    -d, --directory <path>      Directory to analyze (recursive)
    -t, --target <path>         Target directory for generated reports

OPTIONAL PARAMETERS
    -m, --template <file>       Markdown template file (default: built-in template)
    -w, --workspace <path>      Workspace directory for metadata and state
    -v, --verbose               Enable verbose logging
    -f, --fullscan              Force full re-analysis (ignore timestamps)

HELP OPTIONS
    -h, --help                  Show this help message
    --help-plugins              List available plugins
    --help-template             Show template variable reference
    --version                   Show version information

EXAMPLES
    # Basic analysis with defaults
    ./doc.doc.sh -d ./documents -t ./reports

    # Custom template with verbose output
    ./doc.doc.sh -d ./docs -t ./output -m custom.md -v

    # Incremental re-analysis using workspace
    ./doc.doc.sh -d ./docs -t ./output -w ./.workspace

    # Force full re-analysis
    ./doc.doc.sh -d ./docs -t ./output -w ./.workspace -f

DOCUMENTATION
    Full documentation: README.md
    Plugin development: docs/plugins.md

Exit codes: 0 (success), 1 (general error), 2 (invalid arguments)
```

### Help System Implementation
- Single function `show_help()` called for `-h` or `--help`
- Separate functions for extended help (`show_plugin_help()`, `show_template_help()`)
- Help text stored as heredoc for maintainability
- Consider generating help from parameter definitions (DRY principle)

## Transition History
- [2026-02-09] Created and placed in Funnel by Requirements Engineer Agent  
-- Comment: Help mentioned in multiple requirements but comprehensive help system not formalized
- [2026-02-09] Moved to Accepted by user  
-- Comment: Accepted as usability requirement supporting 2-minute learning goal
