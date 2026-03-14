#!/bin/bash
# plugin_management.sh - Plugin Management module for doc.doc.md
# Part of doc.doc.md architecture (Level 3: Bash Components)
# Handles plugin discovery, descriptor.json parsing, installation-state
# checking, and activation/deactivation state management.
# Contains NO plugin invocation, stdin/stdout JSON I/O, or exit-code
# classification logic.
#
# Requires: plugin_info.py (sibling Python component) for tree rendering
#           and table formatting in cmd_tree and cmd_list.
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
      if ! jq -e '.name and .version and .description and .commands' "$descriptor" >/dev/null 2>&1; then
        echo "Warning: Invalid descriptor in $(basename "$dir"), skipping" >&2
        continue
      fi
      local active
      active=$(get_plugin_active_status "$descriptor")
      if [ "$active" = "true" ]; then
        plugins+=("$(basename "$dir")")
      fi
    else
      echo "Warning: No descriptor.json in $(basename "$dir"), skipping" >&2
    fi
  done

  printf '%s\n' "${plugins[@]}"
}

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

get_plugin_active_status() {
  local descriptor="$1"
  jq -r 'if .active == false then "false" else "true" end' "$descriptor"
}

# --- Shared helpers to reduce duplication ---

# Parse --plugin/-p argument from command args. Prints the plugin name.
# Caller must handle --help before calling this function.
_parse_plugin_arg() {
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
  echo "$plugin_name"
}

# Validate that a plugin directory and descriptor exist. Exits on error.
_require_plugin_descriptor() {
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
}

# Set plugin active field to true or false. Used by cmd_activate/cmd_deactivate.
_set_plugin_active() {
  local plugin_name="$1"
  local target_state="$2"  # "true" or "false"
  local descriptor="$PLUGIN_DIR/$plugin_name/descriptor.json"

  _require_plugin_descriptor "$plugin_name"

  local current_status
  current_status=$(get_plugin_active_status "$descriptor")

  if [ "$current_status" = "$target_state" ]; then
    if [ "$target_state" = "true" ]; then
      echo "plugin '$plugin_name' is already active"
    else
      echo "plugin '$plugin_name' is already inactive"
    fi
    exit 0
  fi

  local tmp
  tmp=$(mktemp)
  if jq ".active = $target_state" "$descriptor" > "$tmp" && mv "$tmp" "$descriptor"; then
    if [ "$target_state" = "true" ]; then
      echo "plugin '$plugin_name' activated"
    else
      echo "plugin '$plugin_name' deactivated"
    fi
  else
    rm -f "$tmp"
    echo "Error: Could not update descriptor.json for plugin '$plugin_name'" >&2
    exit 1
  fi
}

# Check if a plugin is installed by running its installed.sh.
# Returns "true" or "false" via stdout.
_check_plugin_installed() {
  local plugin_name="$1"
  local installed_sh="$PLUGIN_DIR/$plugin_name/installed.sh"
  if [ -f "$installed_sh" ]; then
    local installed_output installed_val
    installed_output=$(bash "$installed_sh" 2>/dev/null) || true
    installed_val=$(echo "$installed_output" | jq -r 'if .installed == false then "false" else "true" end' 2>/dev/null) || installed_val="false"
    echo "$installed_val"
  else
    echo "unknown"
  fi
}

# Validate plugin dir + descriptor for cmd_list (with path traversal check).
# Prints descriptor path on success; exits on failure.
_resolve_plugin_descriptor() {
  local plugin_name="$1"
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
  echo "$descriptor"
}

# Validate that a plugin path stays within PLUGIN_DIR (prevents path traversal).
_validate_plugin_dir() {
  local base_dir="$1" plugin_name="$2"
  local raw_dir="$base_dir/$plugin_name"
  local canonical_base canonical_dir
  canonical_base="$(cd "$base_dir" 2>/dev/null && pwd -P)" || return 1
  canonical_dir="$(cd "$raw_dir" 2>/dev/null && pwd -P)" || return 1
  if [ "${canonical_dir#"$canonical_base/"}" = "$canonical_dir" ]; then
    return 1
  fi
  printf '%s' "$canonical_dir"
}

# --- Activate / Deactivate commands ---

cmd_activate() {
  if [ "${1:-}" = "--help" ]; then usage_activate; exit 0; fi
  local plugin_name
  plugin_name=$(_parse_plugin_arg "$@")
  _set_plugin_active "$plugin_name" true
}

cmd_deactivate() {
  if [ "${1:-}" = "--help" ]; then usage_deactivate; exit 0; fi
  local plugin_name
  plugin_name=$(_parse_plugin_arg "$@")
  _set_plugin_active "$plugin_name" false
}

# --- Install command (FEATURE_0011 + FEATURE_0014) ---

cmd_install() {
  if [ "${1:-}" = "--help" ]; then
    usage_install
    exit 0
  fi

  if [ "${1:-}" = "plugins" ]; then
    shift
    if [ "${1:-}" != "--all" ]; then
      echo "Error: Expected '--all' after 'plugins'. Use --help for usage." >&2
      exit 1
    fi
    _install_all_plugins
    return $?
  fi

  local plugin_name
  plugin_name=$(_parse_plugin_arg "$@")
  _install_single_plugin "$plugin_name"
}

_install_single_plugin() {
  local plugin_name="$1"
  local plugin_dir="$PLUGIN_DIR/$plugin_name"
  local descriptor="$plugin_dir/descriptor.json"

  if [ ! -d "$plugin_dir" ]; then
    echo "Error: Plugin '$plugin_name' not found in $PLUGIN_DIR" >&2
    local -a available
    mapfile -t available < <(discover_all_plugins "$PLUGIN_DIR")
    if [ ${#available[@]} -gt 0 ]; then
      echo "Available plugins: ${available[*]}" >&2
    fi
    exit 1
  fi

  if [ ! -f "$descriptor" ]; then
    echo "Error: Plugin descriptor not found: $descriptor" >&2
    exit 1
  fi

  if [ "$(_check_plugin_installed "$plugin_name")" = "true" ]; then
    echo "$plugin_name: already installed"
    return 0
  fi

  local install_sh="$plugin_dir/install.sh"
  if [ ! -f "$install_sh" ]; then
    echo "$plugin_name: no install.sh found, skipping"
    return 0
  fi

  echo "$plugin_name: installing..."
  local install_err_file
  install_err_file=$(mktemp)
  if bash "$install_sh" 2>"$install_err_file"; then
    rm -f "$install_err_file"
    echo "$plugin_name: installed"
  else
    local install_err
    install_err=$(cat "$install_err_file" 2>/dev/null) || install_err=""
    rm -f "$install_err_file"
    if [ -n "$install_err" ]; then
      echo "$install_err" >&2
    fi
    echo "Error: Installation failed for plugin '$plugin_name'" >&2
    echo "Tip: try re-running with elevated privileges: sudo ./doc.doc.sh install --plugin $plugin_name" >&2
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
    [ -f "$plugin_dir/descriptor.json" ] || continue

    if [ "$(_check_plugin_installed "$plugin_name")" = "true" ]; then
      echo "$plugin_name: already installed"
      continue
    fi

    local install_sh="$plugin_dir/install.sh"
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
  if [ ! -d "$plugin_dir" ]; then
    echo "Error: Plugin '$plugin_name' not found in $PLUGIN_DIR" >&2
    exit 2
  fi
  if [ ! -f "$plugin_dir/descriptor.json" ]; then
    echo "Error: Plugin descriptor not found: $plugin_dir/descriptor.json" >&2
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

  local plugin_info_script
  plugin_info_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/plugin_info.py"

  if [ ! -f "$plugin_info_script" ]; then
    echo "Error: plugin_info.py not found: $plugin_info_script" >&2
    exit 1
  fi

  python3 "$plugin_info_script" tree "$PLUGIN_DIR"
  return $?
}

# --- _list_plugins helper ---

_list_plugins() {
  local filter="$1"
  local all_plugins
  mapfile -t all_plugins < <(discover_all_plugins "$PLUGIN_DIR")
  [ ${#all_plugins[@]} -eq 0 ] && return 0

  for plugin_name in "${all_plugins[@]}"; do
    local descriptor="$PLUGIN_DIR/$plugin_name/descriptor.json"
    [ -f "$descriptor" ] || continue
    local active
    active=$(get_plugin_active_status "$descriptor")
    case "$filter" in
      all)
        if [ "$active" = "true" ]; then echo "$plugin_name  [active]"
        else echo "$plugin_name  [inactive]"; fi
        ;;
      active)   [ "$active" = "true" ]  && echo "$plugin_name" || true ;;
      inactive) [ "$active" = "false" ] && echo "$plugin_name" || true ;;
    esac
  done
}

# Shared jq fragment: extracts parameter arrays from descriptor.json commands.
# Produces arrays of [cmd, direction, param, type, required, default, desc].
# Callers pipe through @tsv (or prepend plugin name before @tsv).
_JQ_EXTRACT_PARAMS='
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
  )
'

# --- List command ---

cmd_list() {
  if [ "${1:-}" = "--help" ]; then
    ui_usage_list
    return 0
  fi

  local plugin_info_script
  plugin_info_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/plugin_info.py"

  # Sub-command: list plugins [active|inactive]
  if [ "${1:-}" = "plugins" ]; then
    local filter="${2:-all}"
    if [ $# -gt 2 ]; then
      echo "Error: Too many arguments for 'list plugins'. Use: list plugins [active|inactive]" >&2
      exit 1
    fi
    case "$filter" in
      all|"")   _list_plugins "all" ;;
      active)   _list_plugins "active" ;;
      inactive) _list_plugins "inactive" ;;
      *)
        echo "Error: Unknown filter '$filter'. Use: list plugins [active|inactive]" >&2
        exit 1
        ;;
    esac
    return 0
  fi

  # Sub-command: list parameters (all plugins)
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
        jq -r ".name as \$plugin | $_JQ_EXTRACT_PARAMS | [(\$plugin)] + . | @tsv" "$descriptor" 2>/dev/null | sort
      done
    } | python3 "$plugin_info_script" table
    return 0
  fi

  local show_commands=false show_parameters=false plugin_name=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --plugin)
        [ $# -ge 2 ] || { echo "Error: --plugin requires an argument" >&2; exit 1; }
        plugin_name="$2"; shift 2 ;;
      --commands)    show_commands=true; shift ;;
      --parameters)  show_parameters=true; shift ;;
      --help)        usage; exit 0 ;;
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
    local descriptor
    descriptor=$(_resolve_plugin_descriptor "$plugin_name")
    jq -r '.commands | to_entries[] | "\(.key)\t\(.value.description)"' "$descriptor" | sort
    exit 0
  fi

  if [ "$show_parameters" = true ] && [ -n "$plugin_name" ]; then
    local descriptor
    descriptor=$(_resolve_plugin_descriptor "$plugin_name")
    {
      printf 'COMMAND\tDIRECTION\tPARAMETER\tTYPE\tREQUIRED\tDEFAULT\tDESCRIPTION\n'
      jq -r "$_JQ_EXTRACT_PARAMS | @tsv" "$descriptor" 2>/dev/null | sort
    } | python3 "$plugin_info_script" table
    exit 0
  fi

  # No recognized sub-command given
  usage >&2
  exit 1
}

# --- Setup command (FEATURE_0025) ---

cmd_setup() {
  local auto_yes=false
  local non_interactive=false

  while [ $# -gt 0 ]; do
    case "$1" in
      -y|--yes)           auto_yes=true; shift ;;
      -n|--non-interactive) non_interactive=true; shift ;;
      --help)             ui_usage_setup; exit 0 ;;
      *)
        echo "Error: Unknown option '$1'. Use --help for usage." >&2
        exit 1
        ;;
    esac
  done

  local deps_satisfied=0 deps_installed=0 deps_failed=0
  local plugins_activated=0 plugins_failed=0

  # --- Section 1: Dependency checks ---
  echo "=== Dependency Check ===" >&2
  local -a mandatory_deps=("jq" "column" "awk" "sed" "find" "python3" "file" "stat" "bash")
  for dep in "${mandatory_deps[@]}"; do
    if command -v "$dep" >/dev/null 2>&1; then
      echo "  $(ui_ok '✓') $dep — found" >&2
      deps_satisfied=$((deps_satisfied + 1))
    else
      echo "  $(ui_fail '✗') $dep — missing" >&2
      if [ "$non_interactive" = true ]; then
        deps_failed=$((deps_failed + 1))
        continue
      fi
      local install_ok=false
      if command -v apt-get >/dev/null 2>&1; then
        if apt-get install -y "$dep" >/dev/null 2>&1; then
          install_ok=true
        fi
      fi
      if [ "$install_ok" = true ]; then
        echo "  $(ui_ok '✓') $dep — installed" >&2
        deps_installed=$((deps_installed + 1))
      else
        echo "  $(ui_fail '✗') $dep — could not install automatically. Please install manually." >&2
        deps_failed=$((deps_failed + 1))
      fi
    fi
  done

  if [ "$deps_failed" -gt 0 ] && [ "$non_interactive" = false ]; then
    echo "" >&2
    echo "Error: $deps_failed mandatory dependency(ies) missing and could not be installed." >&2
    exit 1
  fi

  # --- Section 1b: Python library checks (libs declared by each component) ---
  local -a python_libs=()
  mapfile -t python_libs < <(
    { type templates_required_python_libs >/dev/null 2>&1 && templates_required_python_libs; } || true
  )
  if command -v python3 >/dev/null 2>&1; then
    for pylib in "${python_libs[@]}"; do
      if python3 -c "import $pylib" >/dev/null 2>&1; then
        echo "  $(ui_ok '✓') python3:$pylib — found" >&2
        deps_satisfied=$((deps_satisfied + 1))
      else
        echo "  $(ui_fail '✗') python3:$pylib — missing" >&2
        if [ "$non_interactive" = true ]; then
          deps_failed=$((deps_failed + 1))
          continue
        fi
        local py_install_ok=false
        local pip_cmd=""
        if command -v pip3 >/dev/null 2>&1; then
          pip_cmd="pip3"
        elif command -v pip >/dev/null 2>&1; then
          pip_cmd="pip"
        fi
        if [ -n "$pip_cmd" ]; then
          if $pip_cmd install "$pylib" >/dev/null 2>&1; then
            py_install_ok=true
          elif $pip_cmd install --break-system-packages "$pylib" >/dev/null 2>&1; then
            py_install_ok=true
          fi
        fi
        if [ "$py_install_ok" = true ]; then
          echo "  $(ui_ok '✓') python3:$pylib — installed" >&2
          deps_installed=$((deps_installed + 1))
        else
          echo "  $(ui_fail '✗') python3:$pylib — could not install automatically. Run: pip3 install $pylib" >&2
          deps_failed=$((deps_failed + 1))
        fi
      fi
    done
  fi

  if [ "$deps_failed" -gt 0 ] && [ "$non_interactive" = false ]; then
    echo "" >&2
    echo "Error: $deps_failed mandatory dependency(ies) missing and could not be installed." >&2
    exit 1
  fi

  # --- Section 2: Plugin discovery and status ---
  echo "" >&2
  echo "=== Plugin Status ===" >&2

  local -a all_plugins
  mapfile -t all_plugins < <(
    find "$PLUGIN_DIR" -maxdepth 2 -name "descriptor.json" -exec dirname {} \; | \
    while read -r pdir; do basename "$pdir"; done | sort
  )

  printf "  %-20s %-12s %-12s\n" "Plugin" "Installed" "Active" >&2
  printf "  %-20s %-12s %-12s\n" "------" "---------" "------" >&2

  local -a plugins_to_install=() plugins_to_activate=()

  for pname in "${all_plugins[@]}"; do
    local p_descriptor="$PLUGIN_DIR/$pname/descriptor.json"
    local p_active
    p_active=$(jq -r '.active // false' "$p_descriptor" 2>/dev/null) || p_active="false"

    local p_installed
    p_installed=$(_check_plugin_installed "$pname")
    [ "$p_installed" = "unknown" ] && p_installed="true"

    printf "  %-20s %s %s\n" "$pname" "$(ui_color_cell "$p_installed" 12)" "$(ui_color_cell "$p_active" 12)" >&2

    if [ "$p_installed" = "false" ]; then
      plugins_to_install+=("$pname")
    fi
    if [ "$p_active" = "false" ] && [ "$p_installed" != "false" ]; then
      plugins_to_activate+=("$pname")
    fi
  done

  # --- Section 3: Interactive prompting ---
  echo "" >&2

  if [ "$non_interactive" = true ]; then
    echo "=== Non-interactive mode: skipping prompts ===" >&2
  else
    for pname in "${plugins_to_install[@]+"${plugins_to_install[@]}"}"; do
      local answer="n"
      if [ "$auto_yes" = true ]; then
        answer="y"
      elif [ -t 0 ]; then
        printf "Plugin '%s' is not installed. Install now? [y/N] " "$pname" >&2
        read -r answer </dev/tty 2>/dev/null || answer="n"
      fi

      if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        local install_sh="$PLUGIN_DIR/$pname/install.sh"
        if [ -x "$install_sh" ]; then
          local _setup_err_file
          _setup_err_file=$(mktemp)
          if bash "$install_sh" >/dev/null 2>"$_setup_err_file"; then
            rm -f "$_setup_err_file"
            echo "  $(ui_ok '✓') Plugin '$pname' installed" >&2
            deps_installed=$((deps_installed + 1))
          else
            local _setup_err
            _setup_err=$(cat "$_setup_err_file" 2>/dev/null) || _setup_err=""
            rm -f "$_setup_err_file"
            echo "  $(ui_fail '✗') Plugin '$pname' installation failed" >&2
            [ -n "$_setup_err" ] && echo "    $_setup_err" >&2
            echo "  Tip: sudo ./doc.doc.sh install --plugin $pname  or  sudo ./doc.doc.sh setup" >&2
            plugins_failed=$((plugins_failed + 1))
          fi
        else
          echo "  $(ui_fail '✗') Plugin '$pname' has no install script" >&2
          plugins_failed=$((plugins_failed + 1))
        fi
      fi
    done

    for pname in "${plugins_to_activate[@]+"${plugins_to_activate[@]}"}"; do
      local answer="n"
      if [ "$auto_yes" = true ]; then
        answer="y"
      elif [ -t 0 ]; then
        printf "Plugin '%s' is installed but inactive. Activate now? [y/N] " "$pname" >&2
        read -r answer </dev/tty 2>/dev/null || answer="n"
      fi

      if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        local p_descriptor="$PLUGIN_DIR/$pname/descriptor.json"
        local tmp_desc
        tmp_desc=$(mktemp)
        if jq '.active = true' "$p_descriptor" > "$tmp_desc" 2>/dev/null && mv "$tmp_desc" "$p_descriptor"; then
          echo "  $(ui_ok '✓') Plugin '$pname' activated" >&2
          plugins_activated=$((plugins_activated + 1))
        else
          echo "  $(ui_fail '✗') Plugin '$pname' activation failed" >&2
          rm -f "$tmp_desc"
          plugins_failed=$((plugins_failed + 1))
        fi
      fi
    done
  fi

  # --- Section 4: Final summary ---
  echo "" >&2
  echo "=== Summary ===" >&2
  echo "  Dependencies already satisfied: $deps_satisfied" >&2
  echo "  Dependencies installed: $deps_installed" >&2
  echo "  Plugins activated: $plugins_activated" >&2
  if [ "$deps_failed" -gt 0 ] || [ "$plugins_failed" -gt 0 ]; then
    echo "  Failures: $((deps_failed + plugins_failed))" >&2
  fi
  echo "" >&2

  if [ "$deps_failed" -gt 0 ] || [ "$plugins_failed" -gt 0 ]; then
    return 1
  fi
  return 0
}
