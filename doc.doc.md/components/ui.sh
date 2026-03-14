#!/bin/bash
# ui.sh - User Interface module for doc.doc.md
# Part of doc.doc.md architecture (Level 3: Bash Components)
# Encapsulates all user-facing interaction: help text, argument parsing helpers,
# progress messages, and log formatting.
#
# Public Interface:
#   ui_usage()                    - Print main CLI help text to stdout
#   ui_usage_activate()           - Print activate sub-command help
#   ui_usage_deactivate()         - Print deactivate sub-command help
#   ui_usage_install()            - Print install sub-command help
#   ui_usage_installed()          - Print installed sub-command help
#   ui_usage_tree()               - Print tree sub-command help
#   log_info <msg>             - Print informational message to stderr
#   log_warn <msg>             - Print warning message (red) to stderr
#   log_error <msg>            - Print error message (red) to stderr
#   log_success <msg>          - Print success message (green) to stderr
#   log_processed <src> <dst>  - Print file-processed progress (green) to stderr

# --- Shared banner loader (FEATURE_0039) ---
# Reads banner.txt relative to ui.sh, applies {{key}} substitutions from
# key=value arguments, and prints the processed content to stdout.
# Returns 1 (silently) if the file is missing or unreadable.

_ui_read_banner() {
  local _banner_dir
  _banner_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local _banner_file="$_banner_dir/banner.txt"
  [ -f "$_banner_file" ] && [ -r "$_banner_file" ] || return 1
  local _banner_content
  _banner_content="$(cat "$_banner_file")" || return 1
  local _arg _key _val
  for _arg in "$@"; do
    _key="${_arg%%=*}"
    _val="${_arg#*=}"
    if [ "$_key" != "$_arg" ]; then
      _banner_content="${_banner_content//\{\{${_key}\}\}/${_val}}"
    fi
  done
  printf '%s' "$_banner_content"
}

# --- Banner display for help (no screen-clear, FEATURE_0038) ---

ui_show_help_banner() {
  local _content
  _content="$(_ui_read_banner)" || return 0
  echo -e "$_content"
  echo ""
}

# --- Main help (Relocated from doc.doc.sh - FEATURE_0029, trimmed FEATURE_0038) ---

ui_usage() {
  ui_show_help_banner
  cat <<'EOF'
doc.doc.md — command-line tool for processing document collections into Markdown

Usage: ./doc.doc.sh <command> [OPTIONS]

Commands:
  process      Process files in the input directory through plugins
  run          Invoke a command declared in a plugin's descriptor.json
  list         List information about plugins
  activate     Activate a plugin
  deactivate   Deactivate a plugin
  install      Install plugins
  installed    Check if a plugin is installed
  tree         Display a dependency tree of all plugins
  setup        Verify dependencies and configure plugins interactively

Examples:
  ./doc.doc.sh process -d /path/to/documents -o /path/to/output
  ./doc.doc.sh run crm114 listCategories --plugin-storage /data/models
  ./doc.doc.sh list plugins
  ./doc.doc.sh install --plugin markitdown
  ./doc.doc.sh setup

Run ./doc.doc.sh <command> --help for full options of a specific command.
EOF
}

# --- Sub-command help (Relocated from doc.doc.sh - FEATURE_0029, updated FEATURE_0038) ---

ui_usage_process() {
  ui_show_help_banner
  cat <<'EOF'
Process files in the input directory through the active plugin chain.

Usage: ./doc.doc.sh process [OPTIONS]

Options:
  -d <dir>, --input-directory <dir>
                 Input directory to process (required)
  -o <dir>, --output-directory <dir>
                 Output directory for sidecar .md files (required unless --echo)
  -t <file>, --template <file>
                 Markdown template file (optional, defaults to doc.doc.md/templates/default.md)
  -i <criteria>  Include filter criteria (repeatable)
                  Comma-separated values are ORed; multiple -i flags are ANDed
                  Examples: -i ".pdf,.txt" -i "**/2024/**"
  -e <criteria>  Exclude filter criteria (repeatable)
                  Comma-separated values are ORed; multiple -e flags are ANDed
                  Examples: -e ".log" -e "**/temp/**"
  --echo         Print rendered markdown to stdout instead of writing files (dry-run)
                  Mutually exclusive with -o
  -b <dir>, --base-path <dir>
                 Base path for computing relative file references in rendered output
  --progress     Force progress display even when stdout is not a TTY
  --no-progress  Suppress progress display even on a TTY
  --help         Show this help message

Output:
  When stdout is piped or redirected:
    A JSON array is streamed to stdout — one object per processed file (Unix
    pipeline behaviour; backward-compatible).
  When stdout is an interactive TTY and -o is given:
    The JSON array is suppressed; only the "Processed N documents." summary
    is printed to stderr.  Pipe stdout (e.g. | jq .) to receive JSON in a
    terminal session.

Examples:
  ./doc.doc.sh process -d /path/to/documents -o /path/to/output
  ./doc.doc.sh process -d /path/to/documents -o /path/to/output -i ".pdf,.txt"
  ./doc.doc.sh process -d /path/to/documents -o /path/to/output -i ".pdf" -e "**/temp/**"
  ./doc.doc.sh process -d /path/to/documents -o /path/to/output -t /path/to/template.md
  ./doc.doc.sh process -d /path/to/documents --echo
  ./doc.doc.sh process -d /path/to/documents -o /path/to/output -b /path/to/base
EOF
}

ui_usage_run() {
  ui_show_help_banner
  cat <<'EOF'
Invoke a command declared in a plugin's descriptor.json directly from the CLI.

Usage: ./doc.doc.sh run <pluginName> <commandName> [OPTIONS] [-- key=value...]
       ./doc.doc.sh run --help
       ./doc.doc.sh run <pluginName> --help

Arguments:
  <pluginName>             Name of the plugin to run a command from
  <commandName>            Name of the command (as declared in descriptor.json)

Options:
  --file <path>            Maps to the 'filePath' field in the JSON input
  --plugin-storage <dir>   Maps to the 'pluginStorage' field in the JSON input
  --category <name>        Maps to the 'category' field in the JSON input
  --                       End of named options; remaining key=value pairs
                           are merged into the JSON input object
  --help                   Show this help message

Output:
  The plugin script's stdout is streamed directly to stdout.
  The plugin script's stderr is streamed directly to stderr.
  The exit code of 'run' matches the exit code of the plugin script.

Security:
  <pluginName> is validated against known plugin directories (no path traversal).
  <commandName> is validated against the plugin's descriptor.json (no arbitrary
  script execution). key=value pairs are JSON-encoded safely via jq.

Examples:
  ./doc.doc.sh run crm114 listCategories --plugin-storage /data/models
  ./doc.doc.sh run crm114 learn --plugin-storage /data/models --file /docs/spam.txt --category spam
  ./doc.doc.sh run crm114 unlearn --plugin-storage /data/models --file /docs/spam.txt --category spam
  ./doc.doc.sh run --help
  ./doc.doc.sh run crm114 --help
EOF
}

ui_usage_list() {
  ui_show_help_banner
  cat <<'EOF'
List information about plugins — activation status, commands, and parameters.

Usage: ./doc.doc.sh list [SUB-COMMAND] [OPTIONS]

Sub-commands:
  plugins            List all plugins with activation status
  plugins active     List only active plugins
  plugins inactive   List only inactive plugins
  parameters         List all parameters for all plugins

Options:
  --plugin <name>    Name of the plugin to inspect (required with --commands or --parameters)
  --commands         List all commands declared by the specified plugin
  --parameters       List all parameters for the specified plugin
  --help             Show this help message

Examples:
  ./doc.doc.sh list plugins
  ./doc.doc.sh list plugins active
  ./doc.doc.sh list plugins inactive
  ./doc.doc.sh list parameters
  ./doc.doc.sh list --plugin stat --commands
  ./doc.doc.sh list --plugin stat --parameters
EOF
}

ui_usage_activate() {
  ui_show_help_banner
  cat <<'EOF'
Activate a plugin by setting its 'active' field to true in descriptor.json.

Usage: ./doc.doc.sh activate --plugin <plugin_name>
       ./doc.doc.sh activate -p <plugin_name>

Options:
  --plugin <name>, -p <name>   Name of the plugin to activate (required)
  --help                       Show this help message

Examples:
  ./doc.doc.sh activate --plugin stat
  ./doc.doc.sh activate -p ocrmypdf
EOF
}

ui_usage_deactivate() {
  ui_show_help_banner
  cat <<'EOF'
Deactivate a plugin by setting its 'active' field to false in descriptor.json.

Usage: ./doc.doc.sh deactivate --plugin <plugin_name>
       ./doc.doc.sh deactivate -p <plugin_name>

Options:
  --plugin <name>, -p <name>   Name of the plugin to deactivate (required)
  --help                       Show this help message

Examples:
  ./doc.doc.sh deactivate --plugin ocrmypdf
  ./doc.doc.sh deactivate -p markitdown
EOF
}

ui_usage_install() {
  ui_show_help_banner
  cat <<'EOF'
Install one or all plugins.

Usage: ./doc.doc.sh install --plugin <plugin_name>
       ./doc.doc.sh install -p <plugin_name>
       ./doc.doc.sh install plugins --all

Options:
  --plugin <name>, -p <name>   Install a single named plugin
  plugins --all                Install all plugins in PLUGIN_DIR
  --help                       Show this help message

Examples:
  ./doc.doc.sh install --plugin markitdown
  ./doc.doc.sh install -p stat
  ./doc.doc.sh install plugins --all
EOF
}

ui_usage_installed() {
  ui_show_help_banner
  cat <<'EOF'
Check whether a plugin is installed by running its installed.sh script.

Usage: ./doc.doc.sh installed --plugin <plugin_name>
       ./doc.doc.sh installed -p <plugin_name>

Exit codes:
  0   Plugin is installed
  1   Plugin is not installed
  2   Plugin does not exist or other error

Options:
  --plugin <name>, -p <name>   Name of the plugin to check (required)
  --help                       Show this help message

Examples:
  ./doc.doc.sh installed --plugin stat
  ./doc.doc.sh installed -p markitdown
EOF
}

ui_usage_tree() {
  ui_show_help_banner
  cat <<'EOF'
Render a dependency tree of all plugins showing activation status.

Usage: ./doc.doc.sh tree

Active plugins are shown in green; inactive plugins in red.
Dependencies are derived from matching plugin process output parameters to input parameters.

Exit codes:
  0   Success
  1   Circular dependency detected

Examples:
  ./doc.doc.sh tree
EOF
}

ui_usage_setup() {
  ui_show_help_banner
  cat <<'EOF'
Verify core dependencies, discover all plugins, check their installation
and activation status, and interactively prompt to install/activate.

Usage: ./doc.doc.sh setup [OPTIONS]

Options:
  -y, --yes              Auto-answer yes to all prompts (automated setup)
  -n, --non-interactive  Report status only, no prompts (dry-run check)
  --help                 Show this help message

Examples:
  ./doc.doc.sh setup
  ./doc.doc.sh setup --yes
  ./doc.doc.sh setup --non-interactive
EOF
}

# --- Backward-compatible aliases (FEATURE_0029) ---
usage()            { ui_usage "$@"; }
usage_process()    { ui_usage_process "$@"; }
usage_run()        { ui_usage_run "$@"; }
usage_list()       { ui_usage_list "$@"; }
usage_activate()   { ui_usage_activate "$@"; }
usage_deactivate() { ui_usage_deactivate "$@"; }
usage_install()    { ui_usage_install "$@"; }
usage_installed()  { ui_usage_installed "$@"; }
usage_tree()       { ui_usage_tree "$@"; }
usage_setup()      { ui_usage_setup "$@"; }

# --- Color helpers ---
# Only emit ANSI codes when stdout or stderr is a real TTY, so
# piped/redirected output stays clean.
if [ -t 1 ] || [ -t 2 ]; then
  UI_GREEN='\033[0;32m'
  UI_RED='\033[0;31m'
  UI_RESET='\033[0m'
else
  UI_GREEN=''
  UI_RED=''
  UI_RESET=''
fi

# ui_ok <text>   — return green-colored text on stdout (use inside $(...))
ui_ok()   { printf "${UI_GREEN}%s${UI_RESET}" "$*"; }
# ui_fail <text> — return red-colored text on stdout (use inside $(...))
ui_fail() { printf "${UI_RED}%s${UI_RESET}" "$*"; }

# ui_color_cell <value> <width>
# Returns <value> colored (green=true, red=false) and space-padded to <width>
# visual columns. Safe to use in printf columns since ANSI codes are excluded
# from the padding calculation.
ui_color_cell() {
  local value="$1" width="$2"
  local colored
  case "$value" in
    true)  colored="$(ui_ok "$value")" ;;
    false) colored="$(ui_fail "$value")" ;;
    *)     colored="$value" ;;
  esac
  local pad=$(( width - ${#value} ))
  [ "$pad" -lt 0 ] && pad=0
  printf '%s%*s' "$colored" "$pad" ''
}

# --- Logging helpers ---

log_info() {
  echo "$*" >&2
}

log_warn() {
  printf "${UI_RED}Warning:${UI_RESET} %s\n" "$*" >&2
}

log_error() {
  printf "${UI_RED}Error:${UI_RESET} %s\n" "$*" >&2
}

log_success() {
  printf "${UI_GREEN}%s${UI_RESET}\n" "$*" >&2
}

log_processed() {
  local src="$1" dst="$2"
  printf "${UI_GREEN}Processed:${UI_RESET} %s -> %s\n" "$src" "$dst" >&2
}

# --- Banner display (FEATURE_0030, externalised FEATURE_0039) ---

ui_show_banner() {
  # Only display when stderr is a TTY
  [ -t 2 ] || return 0
  local _content
  _content="$(_ui_read_banner "$@")" || return 0
  # Clear screen and print banner to stderr
  printf '\033c' >&2
  echo -e "$_content" >&2
}

# --- Progress bar rendering ---
# shellcheck source=ui_progressbar.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ui_progressbar.sh"
