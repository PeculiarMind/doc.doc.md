#!/bin/bash
# doc.doc.sh - Main CLI entry point for doc.doc.md
# Processes document collections and generates metadata via plugins.
# Uses Python filter engine for include/exclude logic (ADR-001).
# Plugins communicate via JSON stdin/stdout (ADR-003).
# Exit code: 0 on success, non-zero on errors

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/doc.doc.md/plugins"
FILTER_SCRIPT="$SCRIPT_DIR/doc.doc.md/components/filter.py"
PLUGINS_COMPONENT="$SCRIPT_DIR/doc.doc.md/components/plugins.sh"

# Source components
source "$PLUGINS_COMPONENT"

# Global MIME filter criteria (set by main, consumed by process_file)
_MIME_INCLUDE_ARGS=()
_MIME_EXCLUDE_ARGS=()

# --- Usage ---

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

# --- Activate command (FEATURE_0012) ---

cmd_activate() {
  local plugin_name=""

  if [ "${1:-}" = "--help" ]; then
    cat <<EOF
Usage: $(basename "$0") activate --plugin <plugin_name>
       $(basename "$0") activate -p <plugin_name>

Sets the 'active' field to true in the plugin's descriptor.json.
If the plugin is already active, exits 0 with an informational message.

Options:
  --plugin <name>, -p <name>   Name of the plugin to activate (required)
  --help                       Show this help message
EOF
    exit 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --plugin|-p)
        [ $# -ge 2 ] || { echo "Error: $1 requires an argument" >&2; exit 1; }
        plugin_name="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown option '$1'. Use --help for usage." >&2
        exit 1
        ;;
    esac
  done

  if [ -z "$plugin_name" ]; then
    echo "Error: --plugin / -p is required" >&2
    exit 1
  fi

  local plugin_dir="$PLUGIN_DIR/$plugin_name"
  local descriptor="$plugin_dir/descriptor.json"

  if [ ! -d "$plugin_dir" ]; then
    echo "Error: Plugin '$plugin_name' not found in $PLUGIN_DIR" >&2
    exit 1
  fi

  if [ ! -f "$descriptor" ]; then
    echo "Error: Plugin descriptor not found: $descriptor" >&2
    exit 1
  fi

  local current_status
  current_status=$(get_plugin_active_status "$descriptor")
  if [ "$current_status" = "true" ]; then
    echo "plugin '$plugin_name' is already active"
    exit 0
  fi

  local tmp
  tmp=$(mktemp)
  if jq '.active = true' "$descriptor" > "$tmp" && mv "$tmp" "$descriptor"; then
    echo "plugin '$plugin_name' activated"
  else
    rm -f "$tmp"
    echo "Error: Could not update descriptor.json for plugin '$plugin_name'" >&2
    exit 1
  fi
}

# --- Deactivate command (FEATURE_0013) ---

cmd_deactivate() {
  local plugin_name=""

  if [ "${1:-}" = "--help" ]; then
    cat <<EOF
Usage: $(basename "$0") deactivate --plugin <plugin_name>
       $(basename "$0") deactivate -p <plugin_name>

Sets the 'active' field to false in the plugin's descriptor.json.
If the plugin is already inactive, exits 0 with an informational message.

Options:
  --plugin <name>, -p <name>   Name of the plugin to deactivate (required)
  --help                       Show this help message
EOF
    exit 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --plugin|-p)
        [ $# -ge 2 ] || { echo "Error: $1 requires an argument" >&2; exit 1; }
        plugin_name="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown option '$1'. Use --help for usage." >&2
        exit 1
        ;;
    esac
  done

  if [ -z "$plugin_name" ]; then
    echo "Error: --plugin / -p is required" >&2
    exit 1
  fi

  local plugin_dir="$PLUGIN_DIR/$plugin_name"
  local descriptor="$plugin_dir/descriptor.json"

  if [ ! -d "$plugin_dir" ]; then
    echo "Error: Plugin '$plugin_name' not found in $PLUGIN_DIR" >&2
    exit 1
  fi

  if [ ! -f "$descriptor" ]; then
    echo "Error: Plugin descriptor not found: $descriptor" >&2
    exit 1
  fi

  local current_status
  current_status=$(get_plugin_active_status "$descriptor")
  if [ "$current_status" = "false" ]; then
    echo "plugin '$plugin_name' is already inactive"
    exit 0
  fi

  local tmp
  tmp=$(mktemp)
  if jq '.active = false' "$descriptor" > "$tmp" && mv "$tmp" "$descriptor"; then
    echo "plugin '$plugin_name' deactivated"
  else
    rm -f "$tmp"
    echo "Error: Could not update descriptor.json for plugin '$plugin_name'" >&2
    exit 1
  fi
}

# --- Install command (FEATURE_0011 + FEATURE_0014) ---

cmd_install() {
  if [ "${1:-}" = "--help" ]; then
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
    exit 0
  fi

  # Sub-command: install plugins --all (FEATURE_0011)
  if [ "${1:-}" = "plugins" ]; then
    shift
    if [ "${1:-}" != "--all" ]; then
      echo "Error: Expected '--all' after 'plugins'. Use --help for usage." >&2
      exit 1
    fi
    _install_all_plugins
    return $?
  fi

  # Single plugin install (FEATURE_0014)
  local plugin_name=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --plugin|-p)
        [ $# -ge 2 ] || { echo "Error: $1 requires an argument" >&2; exit 1; }
        plugin_name="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown option '$1'. Use --help for usage." >&2
        exit 1
        ;;
    esac
  done

  if [ -z "$plugin_name" ]; then
    echo "Error: --plugin / -p is required" >&2
    exit 1
  fi

  _install_single_plugin "$plugin_name"
}

_install_single_plugin() {
  local plugin_name="$1"
  local plugin_dir="$PLUGIN_DIR/$plugin_name"
  local descriptor="$plugin_dir/descriptor.json"

  if [ ! -d "$plugin_dir" ]; then
    echo "Error: Plugin '$plugin_name' not found in $PLUGIN_DIR" >&2
    exit 1
  fi

  if [ ! -f "$descriptor" ]; then
    echo "Error: Plugin descriptor not found: $descriptor" >&2
    exit 1
  fi

  local installed_sh="$plugin_dir/installed.sh"
  local install_sh="$plugin_dir/install.sh"

  # Check if already installed
  if [ -f "$installed_sh" ]; then
    local installed_output installed_val
    installed_output=$(bash "$installed_sh" 2>/dev/null) || true
    installed_val=$(echo "$installed_output" | jq -r '.installed // "false"' 2>/dev/null) || installed_val="false"
    if [ "$installed_val" = "true" ]; then
      echo "$plugin_name: already installed"
      return 0
    fi
  fi

  # Run install.sh
  if [ ! -f "$install_sh" ]; then
    echo "$plugin_name: no install.sh found, skipping"
    return 0
  fi

  echo "$plugin_name: installing..."
  if bash "$install_sh"; then
    echo "$plugin_name: installed"
  else
    echo "Error: Installation failed for plugin '$plugin_name'" >&2
    exit 1
  fi
}

_install_all_plugins() {
  local all_plugins
  mapfile -t all_plugins < <(discover_all_plugins "$PLUGIN_DIR")

  if [ ${#all_plugins[@]} -eq 0 ]; then
    echo "No plugins found in $PLUGIN_DIR"
    return 0
  fi

  local failed=0

  for plugin_name in "${all_plugins[@]}"; do
    local plugin_dir="$PLUGIN_DIR/$plugin_name"
    local descriptor="$plugin_dir/descriptor.json"
    [ -f "$descriptor" ] || continue

    local installed_sh="$plugin_dir/installed.sh"
    local install_sh="$plugin_dir/install.sh"

    # Check if already installed
    local already_installed=false
    if [ -f "$installed_sh" ]; then
      local installed_output installed_val
      installed_output=$(bash "$installed_sh" 2>/dev/null) || true
      installed_val=$(echo "$installed_output" | jq -r '.installed // "false"' 2>/dev/null) || installed_val="false"
      if [ "$installed_val" = "true" ]; then
        already_installed=true
      fi
    fi

    if [ "$already_installed" = "true" ]; then
      echo "$plugin_name: already installed"
      continue
    fi

    if [ ! -f "$install_sh" ]; then
      echo "$plugin_name: no install.sh found, skipping"
      continue
    fi

    echo "$plugin_name: installing..."
    if bash "$install_sh"; then
      echo "$plugin_name: installed"
    else
      echo "Error: Installation failed for plugin '$plugin_name'" >&2
      failed=$((failed + 1))
    fi
  done

  if [ "$failed" -gt 0 ]; then
    echo "Error: $failed plugin(s) failed to install" >&2
    return 1
  fi
  return 0
}

# --- Installed command (FEATURE_0015) ---

cmd_installed() {
  if [ "${1:-}" = "--help" ]; then
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
    exit 0
  fi

  local plugin_name=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --plugin|-p)
        [ $# -ge 2 ] || { echo "Error: $1 requires an argument" >&2; exit 1; }
        plugin_name="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown option '$1'. Use --help for usage." >&2
        exit 2
        ;;
    esac
  done

  if [ -z "$plugin_name" ]; then
    echo "Error: --plugin / -p is required" >&2
    exit 2
  fi

  local plugin_dir="$PLUGIN_DIR/$plugin_name"
  local descriptor="$plugin_dir/descriptor.json"

  if [ ! -d "$plugin_dir" ]; then
    echo "Error: Plugin '$plugin_name' not found in $PLUGIN_DIR" >&2
    exit 2
  fi

  if [ ! -f "$descriptor" ]; then
    echo "Error: Plugin descriptor not found: $descriptor" >&2
    exit 2
  fi

  local installed_sh="$plugin_dir/installed.sh"

  if [ ! -f "$installed_sh" ]; then
    echo "$plugin_name: no installed.sh found — assuming not installed"
    exit 1
  fi

  local installed_output installed_val
  installed_output=$(bash "$installed_sh" 2>/dev/null) || true
  installed_val=$(echo "$installed_output" | jq -r '.installed // "false"' 2>/dev/null) || installed_val="false"

  if [ "$installed_val" = "true" ]; then
    echo "$plugin_name: installed"
    exit 0
  else
    echo "$plugin_name: not installed"
    exit 1
  fi
}

# --- Tree command (FEATURE_0016) ---

cmd_tree() {
  if [ "${1:-}" = "--help" ]; then
    cat <<EOF
Usage: $(basename "$0") tree

Renders a dependency tree of all plugins showing activation status.
Active plugins are shown in green; inactive plugins in red.
Dependencies are derived from matching plugin process output parameters to input parameters.

Exit codes:
  0   Success
  1   Circular dependency detected
EOF
    exit 0
  fi

  local all_plugins
  mapfile -t all_plugins < <(discover_all_plugins "$PLUGIN_DIR")

  if [ ${#all_plugins[@]} -eq 0 ]; then
    return 0
  fi

  # Build dependency map: derive dependencies from output→input parameter name matching.
  # Plugin A depends on plugin B if any of B's process.output parameter names
  # appear in A's process.input parameter names.
  declare -A plugin_deps    # plugin_name -> space-separated dep names
  declare -A plugin_active  # plugin_name -> true/false
  declare -A plugin_outputs # plugin_name -> space-separated output param names

  # First pass: collect active status and output parameter names
  for plugin_name in "${all_plugins[@]}"; do
    local descriptor="$PLUGIN_DIR/$plugin_name/descriptor.json"
    [ -f "$descriptor" ] || continue
    local active
    active=$(get_plugin_active_status "$descriptor")
    plugin_active["$plugin_name"]="$active"

    local outputs
    outputs=$(jq -r '(.commands.process.output // {}) | keys[]' "$descriptor" 2>/dev/null | tr '\n' ' ') || outputs=""
    plugin_outputs["$plugin_name"]="${outputs% }"
  done

  # Second pass: for each plugin, find which other plugins provide its inputs
  for plugin_name in "${all_plugins[@]}"; do
    local descriptor="$PLUGIN_DIR/$plugin_name/descriptor.json"
    [ -f "$descriptor" ] || continue

    local inputs
    inputs=$(jq -r '(.commands.process.input // {}) | keys[]' "$descriptor" 2>/dev/null) || inputs=""

    local deps=""
    for input_param in $inputs; do
      for other_plugin in "${all_plugins[@]}"; do
        [ "$other_plugin" = "$plugin_name" ] && continue
        local other_outputs="${plugin_outputs[$other_plugin]:-}"
        for out_param in $other_outputs; do
          if [ "$input_param" = "$out_param" ]; then
            if ! echo " $deps " | grep -q " $other_plugin "; then
              deps="${deps:+$deps }$other_plugin"
            fi
          fi
        done
      done
    done
    plugin_deps["$plugin_name"]="$deps"
  done

  # Detect circular dependencies using DFS
  # Returns 0 if no cycle, 1 if cycle found
  _detect_cycle() {
    local start="$1"
    local -n _visited="$2"
    local -n _in_stack="$3"

    _in_stack["$start"]=1
    _visited["$start"]=1

    local deps="${plugin_deps[$start]:-}"
    for dep in $deps; do
      if [ -z "${_visited[$dep]+x}" ]; then
        if ! _detect_cycle "$dep" "$2" "$3"; then
          return 1
        fi
      elif [ "${_in_stack[$dep]+x}" ]; then
        return 1
      fi
    done
    unset '_in_stack[$start]'
    return 0
  }

  declare -A visited_global
  for plugin_name in "${all_plugins[@]}"; do
    [ -z "${visited_global[$plugin_name]+x}" ] || continue
    declare -A in_stack_local=()
    if ! _detect_cycle "$plugin_name" visited_global in_stack_local; then
      echo "Error: Circular dependency detected involving plugin '$plugin_name'" >&2
      return 1
    fi
  done

  # Determine which plugins are dependencies of others (children)
  declare -A is_child
  for plugin_name in "${all_plugins[@]}"; do
    local deps="${plugin_deps[$plugin_name]:-}"
    for dep in $deps; do
      is_child["$dep"]=1
    done
  done

  # Find root plugins (not a child of any other plugin)
  local root_plugins=()
  for plugin_name in "${all_plugins[@]}"; do
    if [ -z "${is_child[$plugin_name]+x}" ]; then
      root_plugins+=("$plugin_name")
    fi
  done

  # Render a plugin node with color
  _render_plugin_label() {
    local name="$1"
    local active="${plugin_active[$name]:-true}"
    # Check if plugin exists in our list
    local exists=false
    for p in "${all_plugins[@]}"; do
      [ "$p" = "$name" ] && exists=true && break
    done

    if [ "$exists" = "false" ]; then
      # Missing dependency
      echo "${name} [missing]"
      return
    fi

    if [ "$active" = "true" ]; then
      printf '\033[32m%s\033[0m' "$name"
    else
      printf '\033[31m%s\033[0m' "$name"
    fi
  }

  # Recursively print tree
  _print_tree() {
    local plugin_name="$1"
    local prefix="$2"
    local is_last="$3"

    local connector
    if [ "$is_last" = "true" ]; then
      connector="└──"
    else
      connector="├──"
    fi

    local label
    label=$(_render_plugin_label "$plugin_name")
    echo "${prefix}${connector} ${label}"

    local child_prefix
    if [ "$is_last" = "true" ]; then
      child_prefix="${prefix}    "
    else
      child_prefix="${prefix}│   "
    fi

    local deps="${plugin_deps[$plugin_name]:-}"
    local dep_arr=()
    for dep in $deps; do
      dep_arr+=("$dep")
    done

    local n=${#dep_arr[@]}
    local i=0
    for dep in "${dep_arr[@]}"; do
      i=$((i + 1))
      local last="false"
      [ "$i" -eq "$n" ] && last="true"
      _print_tree "$dep" "$child_prefix" "$last"
    done
  }

  local n=${#root_plugins[@]}
  local i=0
  for plugin_name in "${root_plugins[@]}"; do
    i=$((i + 1))
    local last="false"
    [ "$i" -eq "$n" ] && last="true"
    _print_tree "$plugin_name" "" "$last"
  done
}

# --- _list_plugins helper ---

_list_plugins() {
  local filter="$1"  # "all", "active", or "inactive"
  local plugin_dir="$PLUGIN_DIR"

  local all_plugins
  mapfile -t all_plugins < <(discover_all_plugins "$plugin_dir")

  if [ ${#all_plugins[@]} -eq 0 ]; then
    return 0
  fi

  for plugin_name in "${all_plugins[@]}"; do
    local descriptor="$plugin_dir/$plugin_name/descriptor.json"
    [ -f "$descriptor" ] || continue
    local active
    active=$(get_plugin_active_status "$descriptor")
    case "$filter" in
      all)
        if [ "$active" = "true" ]; then
          echo "$plugin_name  [active]"
        else
          echo "$plugin_name  [inactive]"
        fi
        ;;
      active)
        if [ "$active" = "true" ]; then echo "$plugin_name"; fi
        ;;
      inactive)
        if [ "$active" = "false" ]; then echo "$plugin_name"; fi
        ;;
    esac
  done
}

# --- List command ---

cmd_list() {
  # Handle 'plugins' sub-command (FEATURE_0008)
  if [ "${1:-}" = "plugins" ]; then
    local filter="${2:-all}"
    # Validate no extra arguments
    if [ $# -gt 2 ]; then
      echo "Error: Too many arguments for 'list plugins'. Use: list plugins [active|inactive]" >&2
      exit 1
    fi
    case "$filter" in
      all|"")  _list_plugins "all" ;;
      active)  _list_plugins "active" ;;
      inactive) _list_plugins "inactive" ;;
      *)
        echo "Error: Unknown filter '$filter'. Use: list plugins [active|inactive]" >&2
        exit 1
        ;;
    esac
    return 0
  fi

  # Handle 'parameters' sub-command (FEATURE_0018): list parameters for all plugins
  if [ "${1:-}" = "parameters" ]; then
    if [ $# -gt 1 ]; then
      echo "Error: Too many arguments for 'list parameters'. Use: list parameters" >&2
      exit 1
    fi
    local all_plugins
    mapfile -t all_plugins < <(discover_all_plugins "$PLUGIN_DIR")
    {
      printf 'PLUGIN\tCOMMAND\tDIRECTION\tPARAMETER\tTYPE\tREQUIRED\tDEFAULT\tDESCRIPTION\n'
      for plugin_name in "${all_plugins[@]}"; do
        local descriptor="$PLUGIN_DIR/$plugin_name/descriptor.json"
        [ -f "$descriptor" ] || continue
        jq -r '
          .name as $plugin |
          .commands | to_entries[] |
          .key as $cmd |
          .value as $cmdval |
          (
            ($cmdval.input // {} | to_entries[] |
              [$plugin, $cmd, "input", .key, .value.type,
               (if .value.required then "required" else "optional" end),
               (.value.default | if . != null then "default:\(.)" else "-" end),
               .value.description]
            ),
            ($cmdval.output // {} | to_entries[] |
              [$plugin, $cmd, "output", .key, .value.type, "-", "-",
               .value.description]
            )
          ) | @tsv
        ' "$descriptor" 2>/dev/null | sort
      done
    } | column -t -s $'\t'
    return 0
  fi

  local plugin_name=""
  local show_commands=false
  local show_parameters=false

  while [ $# -gt 0 ]; do
    case "$1" in
      --plugin)
        [ $# -ge 2 ] || { echo "Error: --plugin requires an argument" >&2; exit 1; }
        plugin_name="$2"
        shift 2
        ;;
      --commands)
        show_commands=true
        shift
        ;;
      --parameters)
        show_parameters=true
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        echo "Error: Unknown option '$1'. Use --help for usage." >&2
        exit 1
        ;;
    esac
  done

  # Validate flag combinations
  if [ "$show_parameters" = true ] && [ -z "$plugin_name" ]; then
    echo "Error: --parameters requires --plugin <name> to be specified" >&2
    exit 1
  fi

  if [ -n "$plugin_name" ] && [ "$show_commands" = false ] && [ "$show_parameters" = false ]; then
    echo "Error: --plugin requires --commands or --parameters to be specified" >&2
    exit 1
  fi

  if [ "$show_commands" = true ] && [ -z "$plugin_name" ]; then
    echo "Error: --commands requires --plugin <name> to be specified" >&2
    exit 1
  fi

  if [ "$show_commands" = true ] && [ -n "$plugin_name" ]; then
    local plugin_dir="$PLUGIN_DIR/$plugin_name"
    local descriptor="$plugin_dir/descriptor.json"

    # Validate plugin directory exists
    if [ ! -d "$plugin_dir" ]; then
      echo "Error: Plugin '$plugin_name' not found in $PLUGIN_DIR" >&2
      exit 1
    fi

    # Validate descriptor exists and is valid JSON
    if [ ! -f "$descriptor" ]; then
      echo "Error: Plugin descriptor not found: $descriptor" >&2
      exit 1
    fi

    if ! jq empty "$descriptor" 2>/dev/null; then
      echo "Error: Plugin descriptor is not valid JSON: $descriptor" >&2
      exit 1
    fi

    # Extract and print commands sorted alphabetically
    jq -r '.commands | to_entries[] | "\(.key)\t\(.value.description)"' "$descriptor" \
      | sort
    exit 0
  fi

  if [ "$show_parameters" = true ] && [ -n "$plugin_name" ]; then
    local plugin_dir="$PLUGIN_DIR/$plugin_name"
    local descriptor="$plugin_dir/descriptor.json"

    if [ ! -d "$plugin_dir" ]; then
      echo "Error: Plugin '$plugin_name' not found in $PLUGIN_DIR" >&2
      exit 1
    fi

    if [ ! -f "$descriptor" ]; then
      echo "Error: Plugin descriptor not found: $descriptor" >&2
      exit 1
    fi

    if ! jq empty "$descriptor" 2>/dev/null; then
      echo "Error: Plugin descriptor is not valid JSON: $descriptor" >&2
      exit 1
    fi

    {
      printf 'COMMAND\tDIRECTION\tPARAMETER\tTYPE\tREQUIRED\tDEFAULT\tDESCRIPTION\n'
      jq -r '
        .commands | to_entries[] |
        .key as $cmd |
        .value as $cmdval |
        (
          ($cmdval.input // {} | to_entries[] |
            [$cmd, "input", .key, .value.type,
             (if .value.required then "required" else "optional" end),
             (.value.default | if . != null then "default:\(.)" else "-" end),
             .value.description]
          ),
          ($cmdval.output // {} | to_entries[] |
            [$cmd, "output", .key, .value.type, "-", "-",
             .value.description]
          )
        ) | @tsv
      ' "$descriptor" 2>/dev/null | sort
    } | column -t -s $'\t'
    exit 0
  fi

  # No recognized sub-command given
  usage >&2
  exit 1
}

# --- Template rendering (FEATURE_0019) ---

# render_template_json renders a template file replacing {{key}} placeholders
# with values from the provided JSON string.
render_template_json() {
  local template="$1"
  local result_json="$2"
  local content
  content="$(cat "$template")"

  # Replace placeholders from JSON fields
  while IFS= read -r line; do
    local key="${line%%=*}"
    local val="${line#*=}"
    [ -n "$key" ] || continue
    content="${content//\{\{${key}\}\}/${val}}"
  done < <(echo "$result_json" | jq -r 'to_entries[] | "\(.key)=\(.value)"')

  # Derive and replace fileName from filePath
  local fp
  fp=$(echo "$result_json" | jq -r '.filePath // empty')
  if [ -n "$fp" ]; then
    local fname
    fname="$(basename "$fp")"
    content="${content//\{\{fileName\}\}/${fname}}"
  fi

  printf '%s' "$content"
}

# --- Main processing ---

process_file() {
  local file_path="$1"
  shift
  local plugins=("$@")

  local combined_result
  combined_result=$(jq -n --arg filePath "$file_path" '{filePath: $filePath}')

  for plugin_name in "${plugins[@]}"; do
    local plugin_output
    if plugin_output=$(run_plugin "$plugin_name" "$file_path" "$PLUGIN_DIR" "$combined_result"); then
      # Merge plugin output into combined result
      combined_result=$(echo "$combined_result" "$plugin_output" | jq -s '.[0] * .[1]')
    else
      # If the file plugin fails and MIME criteria are active, skip this file (fail-closed)
      if [ "$plugin_name" = "file" ]; then
        local _has_mime=false
        [ ${#_MIME_INCLUDE_ARGS[@]} -gt 0 ] && _has_mime=true
        [ ${#_MIME_EXCLUDE_ARGS[@]} -gt 0 ] && _has_mime=true
        [ "$_has_mime" = false ] || return 0
      fi
      # Graceful degradation: continue with partial results
      continue
    fi

    # After the file plugin runs (always position 0), apply the MIME filter gate
    if [ "$plugin_name" = "file" ]; then
      local _has_mime_criteria=false
      [ ${#_MIME_INCLUDE_ARGS[@]} -gt 0 ] && _has_mime_criteria=true
      [ ${#_MIME_EXCLUDE_ARGS[@]} -gt 0 ] && _has_mime_criteria=true
      if [ "$_has_mime_criteria" = true ]; then
        local mime_type
        mime_type=$(echo "$combined_result" | jq -r '.mimeType // empty')
        if [ -n "$mime_type" ]; then
          local mime_filter_args=()
          for _inc in "${_MIME_INCLUDE_ARGS[@]+"${_MIME_INCLUDE_ARGS[@]}"}"; do
            mime_filter_args+=("--include" "$_inc")
          done
          for _exc in "${_MIME_EXCLUDE_ARGS[@]+"${_MIME_EXCLUDE_ARGS[@]}"}"; do
            mime_filter_args+=("--exclude" "$_exc")
          done
          local mime_check
          mime_check=$(echo "$mime_type" | python3 "$FILTER_SCRIPT" "${mime_filter_args[@]+"${mime_filter_args[@]}"}")
          # Empty result means MIME filter rejected this file — skip it silently
          [ -n "$mime_check" ] || return 0
        fi
      fi
    fi
  done

  echo "$combined_result"
}

# --- Entry point ---

main() {
  if [ $# -eq 0 ] || [ "$1" = "--help" ]; then
    usage
    exit 0
  fi

  local command="$1"
  shift

  case "$command" in
    process)
      : # fall through to process logic below
      ;;
    list)
      cmd_list "$@"
      # Exit explicitly to prevent fallthrough into the process argument parser below.
      exit $?
      ;;
    activate)
      cmd_activate "$@"
      exit $?
      ;;
    deactivate)
      cmd_deactivate "$@"
      exit $?
      ;;
    install)
      cmd_install "$@"
      exit $?
      ;;
    installed)
      cmd_installed "$@"
      exit $?
      ;;
    tree)
      cmd_tree "$@"
      exit $?
      ;;
    *)
      echo "Error: Unknown command '$command'. Use --help for usage." >&2
      exit 1
      ;;
  esac

  local input_dir=""
  local output_dir=""
  local template_file="$SCRIPT_DIR/doc.doc.md/templates/default.md"
  local -a include_args=()
  local -a exclude_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--input-directory)
        [ $# -ge 2 ] || { echo "Error: $1 requires an argument" >&2; exit 1; }
        input_dir="$2"
        shift 2
        ;;
      -o|--output-directory)
        [ $# -ge 2 ] || { echo "Error: $1 requires an argument" >&2; exit 1; }
        output_dir="$2"
        shift 2
        ;;
      -t|--template)
        [ $# -ge 2 ] || { echo "Error: $1 requires an argument" >&2; exit 1; }
        template_file="$2"
        shift 2
        ;;
      -i)
        [ $# -ge 2 ] || { echo "Error: -i requires an argument" >&2; exit 1; }
        include_args+=("$2")
        shift 2
        ;;
      -e)
        [ $# -ge 2 ] || { echo "Error: -e requires an argument" >&2; exit 1; }
        exclude_args+=("$2")
        shift 2
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        echo "Error: Unknown option '$1'. Use --help for usage." >&2
        exit 1
        ;;
    esac
  done

  # Validate input directory
  if [ -z "$input_dir" ]; then
    echo "Error: Input directory is required (-d <dir>)" >&2
    usage >&2
    exit 1
  fi

  if [ ! -d "$input_dir" ]; then
    echo "Error: Input directory does not exist: $input_dir" >&2
    exit 1
  fi

  if [ ! -r "$input_dir" ]; then
    echo "Error: Input directory is not readable: $input_dir" >&2
    exit 1
  fi

  # Validate output directory (required)
  if [ -z "$output_dir" ]; then
    echo "Error: Output directory is required (-o <dir>)" >&2
    usage >&2
    exit 1
  fi

  # Validate template file
  if [ ! -f "$template_file" ]; then
    echo "Error: Template file not found: $template_file" >&2
    exit 1
  fi

  # Canonicalize and create output directory
  mkdir -p "$output_dir" || { echo "Error: Cannot create output directory: $output_dir" >&2; exit 1; }
  local canonical_out
  canonical_out="$(readlink -f "$output_dir")"

  # Verify filter script exists
  if [ ! -f "$FILTER_SCRIPT" ]; then
    echo "Error: Filter engine not found: $FILTER_SCRIPT" >&2
    exit 1
  fi

  # Discover active plugins
  local -a plugins
  mapfile -t plugins < <(discover_plugins "$PLUGIN_DIR")

  if [ ${#plugins[@]} -eq 0 ]; then
    echo "Error: No active plugins found in $PLUGIN_DIR" >&2
    exit 1
  fi

  # Enforce file plugin is present and at position 0
  # (discover_plugins already excludes inactive plugins via descriptor.json active field)
  local file_plugin_found=false
  for p in "${plugins[@]}"; do
    if [ "$p" = "file" ]; then
      file_plugin_found=true
      break
    fi
  done
  if [ "$file_plugin_found" = false ]; then
    echo "Error: file plugin must be active and installed to run the process command." >&2
    exit 1
  fi
  local -a ordered_plugins=("file")
  for p in "${plugins[@]}"; do
    [ "$p" != "file" ] || continue
    ordered_plugins+=("$p")
  done
  plugins=("${ordered_plugins[@]}")

  # Validate that all active plugins are installed
  for p in "${plugins[@]}"; do
    local p_descriptor="$PLUGIN_DIR/$p/descriptor.json"
    local p_installed_sh="$PLUGIN_DIR/$p/installed.sh"
    if [ -x "$p_installed_sh" ]; then
      local install_check
      install_check=$(bash "$p_installed_sh" 2>/dev/null | jq -r '.installed // "true"' 2>/dev/null) || install_check="false"
      if [ "$install_check" = "false" ]; then
        echo "Error: Plugin '$p' is active but not installed. Run: $(basename "$0") list --plugin $p --commands to see install options." >&2
        exit 1
      fi
    fi
  done

  # Split include/exclude args into MIME criteria and path criteria.
  # Path criteria: contain '**' (recursive globs like **/2024/**) or have no '/'
  # MIME criteria: contain '/' but not '**' (e.g., text/plain, image/*, text/*)
  local -a mime_include_args=()
  local -a mime_exclude_args=()
  local -a path_include_args=()
  local -a path_exclude_args=()
  for inc in "${include_args[@]+"${include_args[@]}"}"; do
    if [[ "$inc" == *"/"* ]] && [[ "$inc" != *"**"* ]]; then
      mime_include_args+=("$inc")
    else
      path_include_args+=("$inc")
    fi
  done
  for exc in "${exclude_args[@]+"${exclude_args[@]}"}"; do
    if [[ "$exc" == *"/"* ]] && [[ "$exc" != *"**"* ]]; then
      mime_exclude_args+=("$exc")
    else
      path_exclude_args+=("$exc")
    fi
  done

  # Publish MIME criteria for process_file to consume via globals
  _MIME_INCLUDE_ARGS=("${mime_include_args[@]+"${mime_include_args[@]}"}")
  _MIME_EXCLUDE_ARGS=("${mime_exclude_args[@]+"${mime_exclude_args[@]}"}")

  # Build path-only filter arguments for the pre-processing find step
  local -a filter_args=()
  for inc in "${path_include_args[@]+"${path_include_args[@]}"}"; do
    filter_args+=("--include" "$inc")
  done
  for exc in "${path_exclude_args[@]+"${path_exclude_args[@]}"}"; do
    filter_args+=("--exclude" "$exc")
  done

  # Discover files and apply filters
  local -a file_list
  mapfile -t file_list < <(
    find "$input_dir" -type f | \
    python3 "$FILTER_SCRIPT" "${filter_args[@]+"${filter_args[@]}"}"
  )

  if [ ${#file_list[@]} -eq 0 ]; then
    echo "[]"
    exit 0
  fi

  # Process each file through all plugins, write sidecar .md files, stream JSON results
  # Track bracket state: print '[' only on first non-skipped result to handle
  # the case where all files are MIME-filtered out (need to print '[]' then).
  local first=true
  local printed_bracket=false
  for file_path in "${file_list[@]}"; do
    [ -n "$file_path" ] || continue
    local result
    result=$(process_file "$file_path" "${plugins[@]}")
    [ -n "$result" ] || continue
    if [ "$printed_bracket" = false ]; then
      echo "["
      printed_bracket=true
    fi
    if [ "$first" = true ]; then
      first=false
    else
      echo ","
    fi
    echo "$result"

    # Write sidecar .md file to output directory
    local relative_path="${file_path#${input_dir}/}"
    local sidecar_path="${canonical_out}/${relative_path}.md"
    local sidecar_dir
    sidecar_dir="$(dirname "$sidecar_path")"
    local canonical_sidecar
    canonical_sidecar="$(readlink -f "$sidecar_dir" 2>/dev/null || echo "$sidecar_dir")"

    # Boundary check: ensure sidecar stays within output_dir
    if [[ "$canonical_sidecar" != "${canonical_out}"* ]]; then
      echo "Error: path traversal detected for '$file_path'" >&2
      continue
    fi

    mkdir -p "$sidecar_dir"
    render_template_json "$template_file" "$result" > "$sidecar_path"
    echo "Processed: $file_path -> $sidecar_path" >&2
  done

  if [ "$printed_bracket" = false ]; then
    echo "[]"
  else
    echo ""
    echo "]"
  fi
}

main "$@"
