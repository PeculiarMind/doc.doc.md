---
title: CLI Interface Concept
arc42-chapter: 8
---

## 0003 CLI Interface Concept

## Table of Contents

- [Purpose](#purpose)
- [Rationale](#rationale)
- [Command Structure](#command-structure)
- [Arguments and Options](#arguments-and-options)
- [Exit Codes](#exit-codes)
- [Help System](#help-system)
- [Logging and Verbosity](#logging-and-verbosity)
- [Error Messages](#error-messages)
- [Related Requirements](#related-requirements)

The command-line interface provides the primary user interaction point for the doc.doc toolkit, following POSIX conventions and Unix philosophy principles.

### Purpose

The CLI interface:
- **Simplifies Interaction**: Single command to analyze directories
- **Follows Standards**: POSIX-compliant argument parsing
- **Provides Discoverability**: Help text and plugin listing
- **Enables Scripting**: Predictable exit codes and output
- **Supports Automation**: Suitable for cron jobs and scripts

### Rationale

- **Unix Philosophy**: Do one thing well, composable with other tools
- **Accessibility**: Familiar interface for system administrators
- **Scriptability**: Easy to integrate into existing workflows
- **Simplicity**: No configuration files, all options via arguments

### Command Structure

**Main Entry Point**:
```bash
./doc.doc.sh [OPTIONS]

Required (for analysis):
  -d <directory>    Source directory to analyze
  -m <file>         Markdown template file
  -t <directory>    Target directory for reports  
  -w <directory>    Workspace directory for state

Optional:
  -v, --verbose     Enable verbose logging
  -f fullscan       Force full re-analysis of all files (default: incremental)
  -h, --help        Show help message
  --version         Show version information

Special Commands:
  -p list           List available plugins
  --plugins list    List available plugins (long form)
```

### Argument Parsing

**Implementation Pattern**:
```bash
parse_arguments() {
  local OPTIND opt
  
  # Defaults
  VERBOSE=false
  FORMAT="markdown"
  COMMAND=""
  
  while getopts "d:m:t:w:vf:hp:-:" opt; do
    case "${opt}" in
      d) SOURCE_DIR="${OPTARG}" ;;
      m) TEMPLATE_FILE="${OPTARG}" ;;
      t) TARGET_DIR="${OPTARG}" ;;
      w) WORKSPACE_DIR="${OPTARG}" ;;
      v) VERBOSE=true ;;
      f) FORMAT="${OPTARG}" ;;
      h) show_help; exit 0 ;;
      p) COMMAND="${OPTARG}" ;;  # list
      -) handle_long_option "${OPTARG}" ;;
      *) show_help; exit 1 ;;
    esac
  done
  
  validate_arguments
}

handle_long_option() {
  case "$1" in
    verbose) VERBOSE=true ;;
    help) show_help; exit 0 ;;
    version) show_version; exit 0 ;;
    plugins) COMMAND="${!OPTIND}"; ((OPTIND++)) ;;
    *) echo "Unknown option: --$1"; exit 1 ;;
  esac
}
```

### Help Text

The help system provides comprehensive, multi-level documentation accessible via command-line flags.

**Design Principles**:
- Concise but complete
- Examples included
- Clear option descriptions
- Grouped logically
- Multiple detail levels

**Primary Help (`-h` or `--help`)**:
```
doc.doc - Document Analysis Toolkit

SYNOPSIS
  ./doc.doc.sh -d <directory> -t <target> [OPTIONS]
  ./doc.doc.sh [COMMAND]

DESCRIPTION
  Analyzes directories and generates Markdown reports using CLI tools.
  Supports incremental analysis, plugin-based extensibility, and template customization.

REQUIRED PARAMETERS
  -d, --directory <path>      Directory to analyze (recursive scan)
  -t, --target <path>         Target directory for generated reports

OPTIONAL PARAMETERS
  -m, --template <file>       Markdown template file (default: built-in template)
  -w, --workspace <path>      Workspace directory for metadata and state
  -v, --verbose               Enable verbose logging (shows execution details)
  -f, --fullscan              Force full re-analysis (ignore timestamps)

HELP OPTIONS
  -h, --help                  Display this help message
  --help-plugins              List available plugins with descriptions
  --help-template             Show template variable reference
  --help-examples             Show detailed usage examples

INFORMATION OPTIONS
  --version                   Show version and build information
  -p list, --plugins list     List all available plugins

EXAMPLES
  # Basic analysis with default template
  ./doc.doc.sh -d ~/documents -t ~/reports

  # Analysis with custom template and workspace
  ./doc.doc.sh -d ~/documents -m custom.md -t reports/ -w workspace/

  # Verbose mode for debugging
  ./doc.doc.sh -d ~/documents -t reports/ -v

  # Force full re-analysis (ignore workspace)
  ./doc.doc.sh -d ~/documents -t reports/ -w workspace/ -f

  # List available plugins
  ./doc.doc.sh -p list

EXIT CODES
  0    Success
  1    Invalid arguments or input validation error
  2    File system error (permissions, not found)
  3    Plugin execution error
  4    Report generation error
  5    Workspace error (corruption, access denied)

DOCUMENTATION
  Full documentation: README.md
  Bug reports: https://github.com/yourusername/doc.doc/issues

VERSION
  doc.doc v1.0.0
```

**Advanced Help: Plugins (`--help-plugins`)**:
```
Plugin System Help

OVERVIEW
  Plugins extend analysis capabilities by integrating CLI tools. Each plugin declares
  what data it consumes and what data it provides, enabling automatic execution ordering.

PLUGIN DISCOVERY
  Plugins are discovered from:
    1. plugins/{platform}/       Platform-specific (preferred)
    2. plugins/all/              Cross-platform generic

  Platform-specific plugins override generic versions with the same name.

PLUGIN STATUS
  Plugins can be:
    - ACTIVE: Tool available, will execute
    - INACTIVE: Tool missing, will be skipped

  Use './doc.doc.sh -p list' to see all plugins and their status.

AVAILABLE PLUGINS
  (This section dynamically populated at runtime)

PLUGIN DESCRIPTOR FORMAT
  Plugins are defined by descriptor.json:
  {
    "name": "plugin-name",
    "description": "What the plugin does",
    "processes": ["application/pdf", ".pdf"],
    "consumes": ["file_path_absolute"],
    "provides": ["content.text", "content.page_count"],
    "execute_commandline": "tool -flags '{{file_path}}'",
    "check_commandline": "command -v tool",
    "install_commandline": "apt install tool"
  }

CREATING PLUGINS
  1. Create directory: plugins/all/my-plugin/
  2. Create descriptor.json with required fields
  3. Test with: ./doc.doc.sh -p list
  4. Run analysis to verify plugin executes

  See CONTRIBUTING.md for detailed plugin development guide.

EXAMPLES
  # List all plugins
  ./doc.doc.sh -p list

  # List with verbose details
  ./doc.doc.sh -p list -v

  # Run analysis and see which plugins execute
  ./doc.doc.sh -d test/ -t out/ -v
```

**Advanced Help: Templates (`--help-template`)**:
```
Template System Help

OVERVIEW
  Templates define the structure of generated Markdown reports. Templates use variable
  substitution to insert extracted metadata and analysis results.

TEMPLATE LOCATION
  - Default template: scripts/template.doc.doc.md (used if -m not specified)
  - Custom templates: specify with -m flag

TEMPLATE SYNTAX
  Variables:     {{variable_name}}
  Conditionals:  {{#if variable}}...{{/if}}
  Loops:         {{#each array}}...{{/each}}
  Comments:      {{! This is a comment}}

AVAILABLE VARIABLES

  File Metadata:
    {{file_path}}                Absolute path to analyzed file
    {{file_relative_path}}       Path relative to source directory
    {{filename}}                 Filename without path
    {{file_size}}                File size in bytes
    {{file_size_human}}          Human-readable file size (e.g., "2.5 MB")
    {{file_type}}                MIME type (e.g., "application/pdf")
    {{file_extension}}           Extension including dot (e.g., ".pdf")
    {{modification_time}}        Last modified timestamp (ISO 8601)
    {{checksum_sha256}}          SHA-256 checksum of file content

  Analysis Metadata:
    {{analysis_timestamp}}       When analysis was performed
    {{tool_version}}             doc.doc version used for analysis
    {{workspace_path}}           Workspace directory used

  Plugin Data:
    {{metadata.*}}               Plugin-contributed metadata fields
    {{content.*}}                Plugin-contributed content fields
    
  Array variables accessed in loops:
    {{content.tags}}             Array of tags/keywords
    {{plugins_executed}}         Array of plugin execution records

EXAMPLE TEMPLATE
  # Analysis Report: {{filename}}

  ## File Information
  - **Path**: {{file_relative_path}}
  - **Size**: {{file_size_human}}
  - **Type**: {{file_type}}
  - **Modified**: {{modification_time}}

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
  No tags assigned.
  {{/if}}

  ---
  *Generated by doc.doc v{{tool_version}} on {{analysis_timestamp}}*

TEMPLATE CUSTOMIZATION
  1. Copy default template: cp scripts/template.doc.doc.md my-template.md
  2. Edit variables and structure as needed
  3. Test template: ./doc.doc.sh -d test/ -m my-template.md -t out/
  4. Iterate until satisfied

  See docs/template-guide.md for advanced template techniques.
```

**Advanced Help: Examples (`--help-examples`)**:
```
Detailed Usage Examples

BASIC USAGE

  # First-time analysis of a directory
  ./doc.doc.sh -d ~/documents -t ~/reports

  This performs:
    - Discovers all files in ~/documents recursively
    - Detects file types and applies appropriate plugins
    - Generates Markdown report per file in ~/reports
    - Uses built-in default template

WORKSPACE AND INCREMENTAL ANALYSIS

  # Initial scan with workspace
  ./doc.doc.sh -d ~/documents -t ~/reports -w ~/workspace

  # Later incremental scans (only changed files)
  ./doc.doc.sh -d ~/documents -t ~/reports -w ~/workspace

  Workspace enables:
    - Fast re-scans (only analyzes changed files)
    - Persistent metadata storage
    - External tool integration

CUSTOM TEMPLATES

  # Use organization-specific template
  ./doc.doc.sh -d ~/contracts -m templates/contract.md -t reports/ -w workspace/

  # Test template on single file
  ./doc.doc.sh -d testfile.pdf -m my-template.md -t output/

DEBUGGING AND TROUBLESHOOTING

  # Verbose mode shows execution details
  ./doc.doc.sh -d ~/documents -t ~/reports -v

  # Force full re-analysis (ignore workspace cache)
  ./doc.doc.sh -d ~/documents -t ~/reports -w ~/workspace -f

  # List plugins to check what's available
  ./doc.doc.sh -p list

  # Check specific plugin availability
  ./doc.doc.sh -p list -v | grep ocrmypdf

SCHEDULED/AUTOMATED ANALYSIS

  # Cron job for daily incremental analysis
  0 2 * * * /opt/doc.doc/doc.doc.sh -d /data/docs -t /var/www/reports -w /var/lib/workspace

  # Wrapper script for error handling
  #!/bin/bash
  ./doc.doc.sh -d /data/docs -t /reports -w /workspace
  if [ $? -ne 0 ]; then
    echo "Analysis failed" | mail -s "doc.doc error" admin@example.com
  fi

INTEGRATION WITH OTHER TOOLS

  # Generate reports then build search index
  ./doc.doc.sh -d docs/ -t reports/ -w workspace/ && build-index reports/

  # Process workspace with external tool
  ./doc.doc.sh -d docs/ -w workspace/
  jq -r '.content.text' workspace/*.json | sentiment-analyzer

  # Parallel analysis of multiple directories
  ./doc.doc.sh -d dir1/ -t reports/dir1/ -w workspace/ &
  ./doc.doc.sh -d dir2/ -t reports/dir2/ -w workspace/ &
  wait

WORKSPACE MAINTENANCE

  # Check workspace size
  du -sh ~/workspace

  # Clean up workspace for deleted files
  # (Not yet implemented - manual for now:)
  for json in workspace/*.json; do
    file=$(jq -r '.file_path' "$json")
    [ ! -f "$file" ] && rm "$json"
  done

  # Force full re-analysis by deleting workspace
  rm -rf ~/workspace
  ./doc.doc.sh -d ~/documents -t ~/reports -w ~/workspace

For more examples, see: docs/cookbook.md
```

**Help System Implementation**:
```bash
show_help() {
    local help_topic="${1:-main}"
    
    case "$help_topic" in
        main|"")
            show_main_help
            ;;
        plugins)
            show_plugin_help
            ;;
        template)
            show_template_help
            ;;
        examples)
            show_examples_help
            ;;
        *)
            echo "Unknown help topic: $help_topic" >&2
            echo "Available topics: main, plugins, template, examples" >&2
            exit 1
            ;;
    esac
}

# Argument parsing for help
if [[ "$1" == "--help-plugins" ]]; then
    show_help plugins
    exit 0
elif [[ "$1" == "--help-template" ]]; then
    show_help template
    exit 0
elif [[ "$1" == "--help-examples" ]]; then
    show_help examples
    exit 0
fi
```

### Help System Features

- Multi-levelhelp (main, plugins, templates, examples)
- Copy-pasteable examples
- Clear parameter documentation with defaults
- Context-sensitive help
- Terminal-width aware formatting (80 column max)

### Version Information

```bash
show_version() {
  cat <<EOF
doc.doc version 1.0.0

Copyright (C) 2026 Your Name
License: GPL-3.0
This is free software: you are free to change and redistribute it.

Written in Bash for maximum portability and simplicity.
EOF
}
```

### Exit Codes

**Standard Convention**:
```bash
EXIT_SUCCESS=0          # All operations completed successfully
EXIT_INVALID_ARGS=1     # Invalid command-line arguments
EXIT_FILE_ERROR=2       # File or directory access error
EXIT_PLUGIN_ERROR=3     # Plugin execution failed
EXIT_REPORT_ERROR=4     # Report generation failed
EXIT_WORKSPACE_ERROR=5  # Workspace corruption or access error
```

**Usage**:
```bash
# Check if analysis succeeded
./doc.doc.sh -d src/ -m tmpl.md -t reports/ -w workspace/
if [ $? -eq 0 ]; then
  echo "Analysis complete"
else
  echo "Analysis failed"
fi

# In scripts
set -e  # Exit on any error
./doc.doc.sh -d src/ -m tmpl.md -t reports/ -w workspace/
```

### Output Conventions

**Standard Output (stdout)**:
- Informational messages
- Progress updates (if verbose)
- Plugin list output
- Summary statistics
- Intended for human reading or piping

**Standard Error (stderr)**:
- Error messages
- Warning messages
- Debugging information (if verbose)
- Not intended for piping

**Example Output**:
```bash
# Normal mode (quiet)
$ ./doc.doc.sh -d docs/ -m tmpl.md -t reports/ -w workspace/
Analyzing 152 files...
Analysis complete. 152 reports generated.

# Verbose mode
$ ./doc.doc.sh -d docs/ -m tmpl.md -t reports/ -w workspace/ -v
[INFO] Discovering plugins...
[INFO] Found 3 active plugins: stat, file, content-analyzer
[INFO] Scanning directory: docs/
[INFO] Found 152 files for analysis
[INFO] Building dependency graph...
[INFO] Plugin execution order: stat → file → content-analyzer
[INFO] Processing: docs/manual.pdf
[DEBUG]   Executing plugin: stat
[DEBUG]   Executing plugin: file
[DEBUG]   Executing plugin: content-analyzer
[INFO]   Generated report: reports/docs/manual.md
...
[INFO] Analysis complete. 152 files processed, 152 reports generated.
[INFO] Workspace: workspace/
```

### Logging Format

**Structured Logging**:
```bash
log() {
  local level="$1"
  local component="$2"
  local message="$3"
  local timestamp=$(date -Iseconds)
  
  if [ "${VERBOSE}" = true ] || [ "${level}" = "ERROR" ] || [ "${level}" = "WARN" ]; then
    echo "[${timestamp}] [${level}] [${component}] ${message}" >&2
  fi
}

# Usage
log "INFO" "Scanner" "Found 152 files"
log "ERROR" "Plugin" "stat tool not found"
log "DEBUG" "Orchestrator" "Executing plugin: stat"
```

### Validation

**Argument Validation**:
```bash
validate_arguments() {
  local errors=0
  
  # Special command mode (list)
  if [ "${COMMAND}" = "list" ]; then
    return 0  # No other args required
  fi
  
  # Analysis mode requires all four main arguments
  if [ -z "${SOURCE_DIR}" ]; then
    echo "Error: Source directory (-d) is required" >&2
    errors=$((errors + 1))
  fi
  
  if [ -z "${TEMPLATE_FILE}" ]; then
    echo "Error: Template file (-m) is required" >&2
    errors=$((errors + 1))
  fi
  
  if [ -z "${TARGET_DIR}" ]; then
    echo "Error: Target directory (-t) is required" >&2
    errors=$((errors + 1))
  fi
  
  if [ -z "${WORKSPACE_DIR}" ]; then
    echo "Error: Workspace directory (-w) is required" >&2
    errors=$((errors + 1))
  fi
  
  # Path validation
  if [ -n "${SOURCE_DIR}" ] && [ ! -d "${SOURCE_DIR}" ]; then
    echo "Error: Source directory does not exist: ${SOURCE_DIR}" >&2
    errors=$((errors + 1))
  fi
  
  if [ -n "${TEMPLATE_FILE}" ] && [ ! -f "${TEMPLATE_FILE}" ]; then
    echo "Error: Template file does not exist: ${TEMPLATE_FILE}" >&2
    errors=$((errors + 1))
  fi
  
  # Create target and workspace if they don't exist
  mkdir -p "${TARGET_DIR}" "${WORKSPACE_DIR}" 2>/dev/null || {
    echo "Error: Cannot create target or workspace directory" >&2
    errors=$((errors + 1))
  }
  
  if [ ${errors} -gt 0 ]; then
    echo "" >&2
    echo "Run './doc.doc.sh -h' for usage information." >&2
    exit ${EXIT_INVALID_ARGS}
  fi
}
```

### Interactive vs Non-Interactive Mode

**Detection**:
```bash
is_interactive() {
  [ -t 0 ] && [ -t 1 ]  # stdin and stdout are terminals
}

# Usage
if is_interactive; then
  # Prompt user for missing tool installation
  read -p "Install missing tool? [y/N] " response
else
  # Non-interactive (cron job, script), just log and continue
  log "WARN" "CLI" "Tool not available, skipping plugin"
fi
```

### Composability with Other Tools

**Pipeline Examples**:
```bash
# Count total files analyzed
./doc.doc.sh -d docs/ -m tmpl.md -t reports/ -w workspace/ | grep -oP '\\d+ files' | cut -d' ' -f1

# Analyze only if directory changed
if [ "$(find docs/ -newer workspace/.last_run -type f | wc -l)" -gt 0 ]; then
  ./doc.doc.sh -d docs/ -m tmpl.md -t reports/ -w workspace/
  touch workspace/.last_run
fi

# Chain with notification
./doc.doc.sh -d docs/ -m tmpl.md -t reports/ -w workspace/ && notify-send "Analysis complete"

# Capture exit code
./doc.doc.sh -d docs/ -m tmpl.md -t reports/ -w workspace/
exit_code=$?
if [ ${exit_code} -ne 0 ]; then
  send_alert "doc.doc failed with code ${exit_code}"
fi
```

### Design Principles

1. **POSIX Compliance**: Standard argument format (-short, --long)
2. **Fail Fast**: Validate early, provide clear error messages
3. **Predictable**: Consistent behavior, documented exit codes
4. **Scriptable**: Clean output, reliable exit codes
5. **Discoverable**: Help text, examples, version info
6. **Flexible**: Support both interactive and automated use

### Future Enhancements

**Potential Additions**:
- Configuration file support (optional, ~/.doc.doc.conf)
- Progress bar for large directories
- JSON output mode for machine parsing
- Dry-run mode (--dry-run)
- Filter options (--include, --exclude patterns)
- Parallel processing flag (--jobs N)

**Backward Compatibility**:
- New options must be optional
- Existing argument behavior must not change
- Exit codes remain stable
- Output format changes opt-in only
