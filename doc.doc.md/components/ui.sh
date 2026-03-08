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
#   log_warn <msg>             - Print warning message to stderr
#   log_error <msg>            - Print error message to stderr
#   log_processed <src> <dst>  - Print file-processed progress to stderr

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
  list         List information about plugins
  activate     Activate a plugin
  deactivate   Deactivate a plugin
  install      Install plugins
  installed    Check if a plugin is installed
  tree         Display a dependency tree of all plugins
  setup        Verify dependencies and configure plugins interactively

Examples:
  ./doc.doc.sh process -d /path/to/documents -o /path/to/output
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
usage_list()       { ui_usage_list "$@"; }
usage_activate()   { ui_usage_activate "$@"; }
usage_deactivate() { ui_usage_deactivate "$@"; }
usage_install()    { ui_usage_install "$@"; }
usage_installed()  { ui_usage_installed "$@"; }
usage_tree()       { ui_usage_tree "$@"; }
usage_setup()      { ui_usage_setup "$@"; }

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

# --- Progress state struct (DEBTR_004) ---
# All progress display state variables are grouped here.
# Reset all state via ui_progress_init; no other function re-initialises from scratch.
_UI_PROGRESS_ENABLED=false
_UI_PROGRESS_TOTAL=0
_UI_PROGRESS_DONE=0
_UI_PROGRESS_PHASE=""
_UI_PROGRESS_STEP=""
_UI_PROGRESS_FOUND=0
_UI_PROGRESS_FILE=""
_UI_PROGRESS_PLUGIN=""
_UI_PROGRESS_DRAWN=false
_UI_PROGRESS_FRAME=0

ui_progress_init() {
  local total="${1:-0}"
  _UI_PROGRESS_ENABLED=true
  _UI_PROGRESS_TOTAL="$total"
  _UI_PROGRESS_DONE=0
  _UI_PROGRESS_PHASE=""
  _UI_PROGRESS_STEP=""
  _UI_PROGRESS_FOUND=0
  _UI_PROGRESS_FILE=""
  _UI_PROGRESS_PLUGIN=""
  _UI_PROGRESS_DRAWN=false
  _UI_PROGRESS_FRAME=0

  trap '_ui_progress_clear; exit 130' INT
}

ui_progress_update() {
  local key="$1" value="$2"
  case "$key" in
    phase)   _UI_PROGRESS_PHASE="$value" ;;
    step)    _UI_PROGRESS_STEP="$value" ;;
    found)   _UI_PROGRESS_FOUND="$value" ;;
    file)    _UI_PROGRESS_FILE="$value" ;;
    plugin)  _UI_PROGRESS_PLUGIN="$value" ;;
    done)    _UI_PROGRESS_DONE="$value" ;;
    total)   _UI_PROGRESS_TOTAL="$value" ;;
  esac
  _ui_progress_render
}

ui_progress_done() {
  local count="${1:-$_UI_PROGRESS_DONE}"
  _ui_progress_clear
  _UI_PROGRESS_ENABLED=false
  echo "Processed $count documents." >&2
  trap - INT
}

_ui_progress_render() {
  [ "$_UI_PROGRESS_ENABLED" = true ] || return 0

  local pct=0
  if [ "$_UI_PROGRESS_TOTAL" -gt 0 ]; then
    pct=$(( (_UI_PROGRESS_DONE * 100) / _UI_PROGRESS_TOTAL ))
  fi
  [ "$pct" -gt 100 ] && pct=100

  local bar_width=50
  local filled=$(( (pct * bar_width) / 100 ))
  local empty=$(( bar_width - filled ))

  # Advance animation frame on every render (cycles 0→1→0→…)
  _UI_PROGRESS_FRAME=$(( (_UI_PROGRESS_FRAME + 1) % 2 ))

  # Pick fill character for this frame — alternates to create a pulse effect
  local fill_char
  if   [ "$pct" -eq 100 ]; then fill_char="▓"
  elif [ "$_UI_PROGRESS_FRAME" -eq 0 ]; then fill_char="▒"
  else fill_char="▓"
  fi

  local bar=""
  if [ "$pct" -eq 0 ]; then
    bar=$(printf '%.0s░' $(seq 1 "$bar_width"))
  else
    [ "$filled" -gt 0 ] && bar=$(printf "%.0s${fill_char}" $(seq 1 "$filled"))
    [ "$empty" -gt 0 ] && bar+=$(printf '%.0s░' $(seq 1 "$empty"))
  fi

  if [ "$_UI_PROGRESS_DRAWN" = true ]; then
    printf '\033[u' >&2   # restore to saved position (robust against extra stderr lines)
  else
    printf '\033[s' >&2   # save cursor position before first render
  fi

  printf '\r\033[K%s\n' "Progress: ${bar} ${pct}%" >&2
  printf '\033[K%s\n' "Phase:    ${_UI_PROGRESS_PHASE}" >&2
  printf '\033[K%s\n' "Step:     ${_UI_PROGRESS_STEP}" >&2
  printf '\033[K%s\n' "Found:    ${_UI_PROGRESS_FOUND} documents" >&2
  printf '\033[K%s\n' "Process:  ${_UI_PROGRESS_FILE}" >&2
  printf '\033[K%s\n' "Execute:  ${_UI_PROGRESS_PLUGIN}" >&2

  _UI_PROGRESS_DRAWN=true
}

_ui_progress_clear() {
  [ "$_UI_PROGRESS_DRAWN" = true ] || return 0
  printf '\033[u' >&2   # restore to saved position (start of progress block)
  printf '\r\033[K\n%.0s' $(seq 1 6) >&2
  printf '\033[u' >&2   # leave cursor at start of cleared block for summary output
  _UI_PROGRESS_DRAWN=false
}
