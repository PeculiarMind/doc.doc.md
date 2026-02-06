---
title: CLI Interface Concept
arc42-chapter: 8
---

## 0003 CLI Interface Concept

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
  -f <format>       Output format (default: markdown)
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

**Design Principles**:
- Concise but complete
- Examples included
- Clear option descriptions
- Grouped logically

**Help Format**:
```
doc.doc - Document Analysis Toolkit

USAGE:
  ./doc.doc.sh -d <dir> -m <template> -t <target> -w <workspace> [OPTIONS]
  ./doc.doc.sh -p list

DESCRIPTION:
  Orchestrates CLI tools to extract metadata and content insights from files,
  generating human-readable Markdown reports.

REQUIRED OPTIONS (for analysis):
  -d <directory>    Source directory to analyze recursively
  -m <file>         Markdown template file for report generation
  -t <directory>    Target directory for generated reports
  -w <directory>    Workspace directory for state persistence

OPTIONAL FLAGS:
  -v, --verbose     Enable verbose logging (shows execution details)
  -f <format>       Output format (default: markdown)
  -h, --help        Display this help message and exit
  --version         Display version information and exit

SPECIAL COMMANDS:
  -p list           List all available plugins with their status
  --plugins list    List all available plugins (long form)

EXAMPLES:
  # Analyze directory and generate reports
  ./doc.doc.sh -d ~/documents -m template.md -t reports/ -w workspace/

  # Verbose mode for debugging
  ./doc.doc.sh -d ~/documents -m template.md -t reports/ -w workspace/ -v

  # List available plugins
  ./doc.doc.sh -p list

  # Incremental analysis (only changed files)
  ./doc.doc.sh -d ~/documents -m template.md -t reports/ -w workspace/

EXIT CODES:
  0    Success
  1    Invalid arguments or configuration error
  2    File system error (permissions, not found, etc.)
  3    Plugin execution error
  4    Report generation error

VERSION:
  doc.doc v1.0.0

PROJECT:
  https://github.com/yourusername/doc.doc
```

### Version Information

```bash
show_version() {
  cat <<EOF
doc.doc version 1.0.0

Copyright (C) 2026 Your Name
License: MIT License
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
