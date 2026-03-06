#!/bin/bash
# plugin_management.sh - Plugin Management module for doc.doc.md
# Part of doc.doc.md architecture (Level 3: Bash Components)
# Handles plugin discovery, descriptor.json parsing, installation-state
# checking, and activation/deactivation state management.
# Contains NO plugin invocation, stdin/stdout JSON I/O, or exit-code
# classification logic.
#
# Public Interface:
#   discover_plugins <plugin_dir>            - Discover active plugins with valid descriptors
#   discover_all_plugins <plugin_dir>        - Discover all plugins (active + inactive), sorted
#   get_plugin_active_status <descriptor>    - Get activation status from descriptor.json
#   cmd_activate                             - Activate a plugin by name
#   cmd_deactivate                           - Deactivate a plugin by name
#   cmd_install                              - Install a plugin or all plugins
#   cmd_installed                            - Check if a plugin is installed
#   cmd_tree                                 - Display plugin dependency tree
#   cmd_list                                 - List plugins and their parameters/commands

# --- Plugin discovery and validation ---

discover_plugins() {
  local plugin_dir="$1"
  local plugins=()

  if [ ! -d "$plugin_dir" ]; then
    echo "Error: Plugin directory not found: $plugin_dir" >&2
    return 1
  fi

  for dir in "$plugin_dir"/*/; do
    [ -d "$dir" ] || continue
    local descriptor="$dir/descriptor.json"
    if [ -f "$descriptor" ]; then
      # Validate descriptor has required fields
      if ! jq -e '.name and .version and .description and .commands' "$descriptor" >/dev/null 2>&1; then
        echo "Warning: Invalid descriptor in $(basename "$dir"), skipping" >&2
        continue
      fi
      # Check plugin is active (.active defaults to true when absent; explicit false disables)
      local active
      active=$(jq -r 'if .active == false then "false" else "true" end' "$descriptor")
      if [ "$active" = "true" ]; then
        plugins+=("$(basename "$dir")")
      fi
    else
      echo "Warning: No descriptor.json in $(basename "$dir"), skipping" >&2
    fi
  done

  printf '%s\n' "${plugins[@]}"
}

# Discover ALL plugins (active and inactive) in the plugin directory.
# Returns plugin names sorted alphabetically.
discover_all_plugins() {
  local plugin_dir="$1"

  if [ ! -d "$plugin_dir" ]; then
    echo "Error: Plugin directory not found: $plugin_dir" >&2
    return 1
  fi

  for dir in "$plugin_dir"/*/; do
    [ -d "$dir" ] || continue
    local descriptor="$dir/descriptor.json"
    [ -f "$descriptor" ] || continue
    jq -e '.name and .commands' "$descriptor" >/dev/null 2>&1 || continue
    basename "$dir"
  done | sort
}

# Get the activation status of a plugin from its descriptor.json.
# Returns "true" if active (or absent), "false" if explicitly false.
get_plugin_active_status() {
  local descriptor="$1"
  jq -r 'if .active == false then "false" else "true" end' "$descriptor"
}

# --- Activate command (FEATURE_0012) ---

cmd_activate() {
  local plugin_name=""

  if [ "${1:-}" = "--help" ]; then
    usage_activate
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
    usage_deactivate
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
    usage_install
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
    usage_installed
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
    usage_tree
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

# Validate that a plugin path stays within PLUGIN_DIR (prevents path traversal).
# Usage: _validate_plugin_dir "$PLUGIN_DIR" "$plugin_name"
# Returns 0 if valid, 1 if traversal detected. Prints canonical path on success.
_validate_plugin_dir() {
  local base_dir="$1" plugin_name="$2"
  local raw_dir="$base_dir/$plugin_name"

  local canonical_base canonical_dir
  canonical_base="$(cd "$base_dir" 2>/dev/null && pwd -P)" || return 1
  canonical_dir="$(cd "$raw_dir" 2>/dev/null && pwd -P)" || return 1

  # Ensure resolved path is strictly inside the base directory
  if [ "${canonical_dir#"$canonical_base/"}" = "$canonical_dir" ]; then
    return 1
  fi

  printf '%s' "$canonical_dir"
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
    local plugin_dir
    plugin_dir="$(_validate_plugin_dir "$PLUGIN_DIR" "$plugin_name")" || {
      echo "Error: Plugin '$plugin_name' not found in $PLUGIN_DIR" >&2
      exit 1
    }
    local descriptor="$plugin_dir/descriptor.json"

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
    local plugin_dir
    plugin_dir="$(_validate_plugin_dir "$PLUGIN_DIR" "$plugin_name")" || {
      echo "Error: Plugin '$plugin_name' not found in $PLUGIN_DIR" >&2
      exit 1
    }
    local descriptor="$plugin_dir/descriptor.json"

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
