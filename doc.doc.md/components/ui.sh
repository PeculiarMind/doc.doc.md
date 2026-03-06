#!/bin/bash
# ui.sh - User Interface module for doc.doc.md
# Part of doc.doc.md architecture (Level 3: Bash Components)
# Encapsulates all user-facing interaction: help text, argument parsing helpers,
# progress messages, and log formatting.
#
# Public Interface:
#   usage()                    - Print main CLI help text to stdout
#   usage_activate()           - Print activate sub-command help
#   usage_deactivate()         - Print deactivate sub-command help
#   usage_install()            - Print install sub-command help
#   usage_installed()          - Print installed sub-command help
#   usage_tree()               - Print tree sub-command help
#   log_info <msg>             - Print informational message to stderr
#   log_warn <msg>             - Print warning message to stderr
#   log_error <msg>            - Print error message to stderr
#   log_processed <src> <dst>  - Print file-processed progress to stderr

# --- Main help ---

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [OPTIONS]

Commands:
  process      Process files in the input directory through plugins
  list         List information about plugins
  activate     Activate a plugin
  deactivate   Deactivate a plugin
  install      Install plugins
  installed    Check if a plugin is installed
  tree         Display a dependency tree of all plugins

process Options:
  -d <dir>, --input-directory <dir>
                 Input directory to process (required)
  -o <dir>, --output-directory <dir>
                 Output directory for sidecar .md files (required)
  -t <file>, --template <file>
                 Markdown template file (optional, defaults to doc.doc.md/templates/default.md)
  -i <criteria>  Include filter criteria (repeatable)
                  Comma-separated values are ORed; multiple -i flags are ANDed
                  Examples: -i ".pdf,.txt" -i "**/2024/**"
  -e <criteria>  Exclude filter criteria (repeatable)
                  Comma-separated values are ORed; multiple -e flags are ANDed
                  Examples: -e ".log" -e "**/temp/**"

list Options:
  plugins            List all plugins with activation status
  plugins active     List only active plugins
  plugins inactive   List only inactive plugins
  parameters         List all parameters for all plugins
  --plugin <name>    Name of the plugin to inspect (required with --commands or --parameters)
  --commands         List all commands declared by the specified plugin
  --parameters       List all parameters for the specified plugin

activate Options:
  --plugin <name>, -p <name>   Name of the plugin to activate (required)

deactivate Options:
  --plugin <name>, -p <name>   Name of the plugin to deactivate (required)

install Options:
  --plugin <name>, -p <name>   Install a single named plugin
  plugins --all                Install all plugins

installed Options:
  --plugin <name>, -p <name>   Check if a named plugin is installed (required)

tree Options:
  (no options)   Render dependency tree for all plugins

  --help     Show this help message

Examples:
  $(basename "$0") process -d /path/to/documents -o /path/to/output
  $(basename "$0") process -d /path/to/documents -o /path/to/output -i ".pdf,.txt"
  $(basename "$0") process -d /path/to/documents -o /path/to/output -i ".pdf" -e "**/temp/**"
  $(basename "$0") process -d /path/to/documents -o /path/to/output -t /path/to/template.md
  $(basename "$0") list --plugin stat --commands
  $(basename "$0") list --plugin stat --parameters
  $(basename "$0") list parameters
  $(basename "$0") list plugins
  $(basename "$0") list plugins active
  $(basename "$0") list plugins inactive
  $(basename "$0") activate --plugin stat
  $(basename "$0") deactivate --plugin ocrmypdf
  $(basename "$0") install --plugin stat
  $(basename "$0") install plugins --all
  $(basename "$0") installed --plugin stat
  $(basename "$0") tree
EOF
}

# --- Sub-command help ---

usage_activate() {
  cat <<EOF
Usage: $(basename "$0") activate --plugin <plugin_name>
       $(basename "$0") activate -p <plugin_name>

Sets the 'active' field to true in the plugin's descriptor.json.
If the plugin is already active, exits 0 with an informational message.

Options:
  --plugin <name>, -p <name>   Name of the plugin to activate (required)
  --help                       Show this help message
EOF
}

usage_deactivate() {
  cat <<EOF
Usage: $(basename "$0") deactivate --plugin <plugin_name>
       $(basename "$0") deactivate -p <plugin_name>

Sets the 'active' field to false in the plugin's descriptor.json.
If the plugin is already inactive, exits 0 with an informational message.

Options:
  --plugin <name>, -p <name>   Name of the plugin to deactivate (required)
  --help                       Show this help message
EOF
}

usage_install() {
  cat <<EOF
Usage: $(basename "$0") install --plugin <plugin_name>
       $(basename "$0") install -p <plugin_name>
       $(basename "$0") install plugins --all

Install one or all plugins.

Options:
  --plugin <name>, -p <name>   Install a single named plugin
  plugins --all                Install all plugins in PLUGIN_DIR
  --help                       Show this help message
EOF
}

usage_installed() {
  cat <<EOF
Usage: $(basename "$0") installed --plugin <plugin_name>
       $(basename "$0") installed -p <plugin_name>

Checks whether a plugin is installed by running its installed.sh script.

Exit codes:
  0   Plugin is installed
  1   Plugin is not installed
  2   Plugin does not exist or other error

Options:
  --plugin <name>, -p <name>   Name of the plugin to check (required)
  --help                       Show this help message
EOF
}

usage_tree() {
  cat <<EOF
Usage: $(basename "$0") tree

Renders a dependency tree of all plugins showing activation status.
Active plugins are shown in green; inactive plugins in red.
Dependencies are derived from matching plugin process output parameters to input parameters.

Exit codes:
  0   Success
  1   Circular dependency detected
EOF
}

# --- Logging helpers ---

log_info() {
  echo "$*" >&2
}

log_warn() {
  echo "Warning: $*" >&2
}

log_error() {
  echo "Error: $*" >&2
}

log_processed() {
  local src="$1" dst="$2"
  echo "Processed: $src -> $dst" >&2
}
