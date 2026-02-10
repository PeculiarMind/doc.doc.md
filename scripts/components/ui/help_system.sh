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
  -d <directory>          Analyze specified directory (future)
  -m <format>             Output format: markdown, json, html (future)
  -t <types>              Filter by document types (future)
  -w <workspace>          Specify workspace directory (future)
  -p, --plugin <cmd>      Plugin operations: list, info, enable, disable
                          (only 'list' currently implemented)
  -f                      Enable fullscan mode (future)

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
  ${SCRIPT_NAME} -d ./docs         Analyze docs directory (future)
  ${SCRIPT_NAME} -p list           List available plugins
  ${SCRIPT_NAME} --plugin list     List available plugins (long form)

For more information, see the project documentation.
EOF
}

# Display plugin-specific help (future)
show_help_plugins() {
  echo "Plugin help not yet implemented"
}

# Display template help (future)
show_help_template() {
  echo "Template help not yet implemented"
}

# Display examples help (future)
show_help_examples() {
  echo "Examples help not yet implemented"
}
