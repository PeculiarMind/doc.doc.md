#!/usr/bin/env bash
# Component: help_system.sh
# Purpose: All help text and display functions
# Dependencies: core/constants.sh, core/logging.sh
# Exports: show_help(), show_help_plugins(), show_help_template(), show_help_examples()
# Side Effects: None (pure display)

# ==============================================================================
# Help System Functions
# ==============================================================================

# Display main help message
show_help() {
  cat <<EOF
${SCRIPT_NAME} - Documentation Documentation Tool

Usage:
  ${SCRIPT_NAME} [OPTIONS]

Description:
  A lightweight Bash utility for analyzing documentation in directories,
  detecting documentation types, and generating reports. Supports plugins
  for extensibility and follows Unix tool design principles.

Options:
  -h, --help              Display this help message and exit
  -v, --verbose           Enable verbose logging output
  --version               Display version information and exit
  -d <directory>          Source directory to analyze
  -m <template>           Template file for report generation
  -t <directory>          Target directory for output reports
  -w <workspace>          Workspace directory for state storage
  -p, --plugin <cmd>      Plugin operations: list, info, enable, disable
                          (only 'list' currently implemented)
  -f                      Force full rescan of all files

Exit Codes:
  0  Success
  1  Invalid command-line arguments
  2  File or directory access error
  3  Plugin execution failure
  4  Report generation failure
  5  Workspace corruption or access error

Examples:
  ${SCRIPT_NAME}                   Show this help message (no arguments)
  ${SCRIPT_NAME} -h                Show this help message
  ${SCRIPT_NAME} --version         Show version information
  ${SCRIPT_NAME} -v                Run with verbose logging
  ${SCRIPT_NAME} -d ./docs -m template.md -t ./output -w ./workspace
                                   Analyze docs directory with template
  ${SCRIPT_NAME} -d ./docs -m template.md -t ./output -w ./workspace -f
                                   Force full rescan of all files
  ${SCRIPT_NAME} -p list           List available plugins
  ${SCRIPT_NAME} --plugin list     List available plugins (long form)

For more information, see the project documentation.

Advanced Help Topics:
  --help-plugins          Plugin system documentation
  --help-template         Template syntax reference
  --help-examples         Usage examples and scenarios
EOF
}

# Display plugin-specific help
show_help_plugins() {
  cat <<'EOF'
doc.doc.sh - Plugin System Help

OVERVIEW
  Plugins extend doc.doc.sh with custom analysis capabilities. Each plugin
  wraps a CLI tool and declares what data it consumes and provides. The
  system automatically orchestrates plugin execution based on dependencies.

PLUGIN DISCOVERY
  Plugins are discovered in these directories:
    scripts/plugins/all/       (all platforms)
    scripts/plugins/$PLATFORM/ (current platform only)

  Each plugin directory must contain a descriptor.json file.

PLUGIN STATUS
  active:        Plugin enabled, will execute if tools available
  inactive:      Plugin disabled, will not execute
  missing_tools: Plugin active but required tools unavailable

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

CREATING CUSTOM PLUGINS
  1. Create plugin directory: scripts/plugins/all/my_plugin/
  2. Create descriptor.json with required fields
  3. Implement plugin logic (can be separate script)
  4. Test with: ./doc.doc.sh -p list
  5. Activate: Set "active": true in descriptor

  See example plugins in scripts/plugins/ for reference.

SEE ALSO
  ./doc.doc.sh -p list            List available plugins
  ./doc.doc.sh --help-template    Template variable reference
  ./doc.doc.sh --help-examples    Usage examples

EOF
}

# Display template help
show_help_template() {
  cat <<'EOF'
doc.doc.sh - Template System Help

OVERVIEW
  Templates are Markdown files with special syntax for variable
  substitution, conditionals, and loops. The system merges workspace
  data with templates to generate customized reports.

SYNTAX REFERENCE

  Variables (substitute with data):
    ${variable_name}

  Template variables are replaced with values from workspace data
  when reports are generated.

AVAILABLE VARIABLES

  File Metadata:
    ${filename}              File name
    ${filepath_relative}     Path relative to source directory
    ${filepath_absolute}     Absolute path to file
    ${file_owner}            File owner
    ${file_created_at}       Creation timestamp
    ${file_created_by}       File creator
    ${doc_doc_version}       doc.doc.sh version used for analysis

  Analysis Metadata:
    ${file_last_analyzed_at} When file was last analyzed
    ${doc_content_summary}   Content summary

  Plugin Data (varies by plugins):
    ${doc_name}              Document name
    ${doc_categories}        Document categories
    ${doc_type}              Document type

COMPLETE EXAMPLE

  # ${doc_name}

  ## MetaData
  * **File name:** ${filename}
  * **Relative file path:** ${filepath_relative}
  * **File owner:** ${file_owner}
  * **Last analyzed at:** ${file_last_analyzed_at}

  ## Content Description
  ${doc_content_summary}

TROUBLESHOOTING

  Missing variable: Ensure the variable name matches exactly
  Empty output: Check that workspace data exists for the file

SEE ALSO
  ./doc.doc.sh --help-examples    Template usage examples
  ./doc.doc.sh --help-plugins     Plugin documentation

EOF
}

# Display examples help
show_help_examples() {
  cat <<'EOF'
doc.doc.sh - Usage Examples

BASIC USAGE

  Analyze directory with template:
    ./doc.doc.sh -d ~/documents -t ~/reports \
                 -w ~/workspace -m template.md

  Enable verbose logging:
    ./doc.doc.sh -d ~/documents -t ~/reports \
                 -w ~/workspace -m template.md -v

INCREMENTAL ANALYSIS

  First run (analyzes all files):
    ./doc.doc.sh -d ~/documents -t ~/reports \
                 -w ~/workspace -m template.md

  Subsequent runs (only changed files):
    ./doc.doc.sh -d ~/documents -t ~/reports \
                 -w ~/workspace -m template.md

  Force full rescan:
    ./doc.doc.sh -d ~/documents -t ~/reports \
                 -w ~/workspace -m template.md -f

PLUGIN MANAGEMENT

  List available plugins:
    ./doc.doc.sh -p list

  Get detailed plugin information:
    ./doc.doc.sh --help-plugins

CUSTOM TEMPLATES

  Use custom template:
    ./doc.doc.sh -d ~/docs -t ~/reports \
                 -w ~/workspace -m my_template.md

Automation

  Cron job (daily analysis at 2 AM):
    0 2 * * * /path/to/doc.doc.sh -d ~/documents \
              -t ~/reports -w ~/workspace -m template.md

  Shell script with error checking:
    #!/bin/bash
    if ./doc.doc.sh -d ~/docs -t ~/reports \
                    -w ~/workspace -m template.md; then
      echo "Analysis complete"
    else
      echo "Analysis failed" >&2
      exit 1
    fi

TROUBLESHOOTING

  Debug with verbose mode:
    ./doc.doc.sh -d ~/docs -t ~/reports \
                 -w ~/workspace -m template.md -v

SEE ALSO
  ./doc.doc.sh --help             General help
  ./doc.doc.sh --help-plugins     Plugin documentation
  ./doc.doc.sh --help-template    Template syntax reference

EOF
}
