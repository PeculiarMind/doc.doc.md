#!/bin/bash
# plugin_management.sh - Plugin Management module for doc.doc.md
# Part of doc.doc.md architecture (Level 3: Bash Components)
# Handles plugin discovery, descriptor.json parsing, installation-state
# checking, and activation/deactivation state management.
# Contains NO process-pipeline invocation logic (that belongs in plugin_execution.sh).
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
#   cmd_run                                  - Invoke any plugin command declared in descriptor.json

# --- Plugin discovery and validation ---

discover_plugins() {
  local plugin_dir="$1"
  local plugins=()

  if [ ! -d "$plugin_dir" ]; then
    log_error "Plugin directory not found: $plugin_dir"
    return 1
  fi

  for dir in "$plugin_dir"/*/; do
    [ -d "$dir" ] || continue
    local descriptor="$dir/descriptor.json"
    if [ -f "$descriptor" ]; then
      if ! jq -e '.name and .version and .description and .commands' "$descriptor" >/dev/null 2>&1; then
        log_warn "Invalid descriptor in $(basename "$dir"), skipping"
        continue
      fi
      local active
      active=$(get_plugin_active_status "$descriptor")
      if [ "$active" = "true" ]; then
        plugins+=("$(basename "$dir")")
      fi
    else
      log_warn "No descriptor.json in $(basename "$dir"), skipping"
    fi
  done

  printf '%s\n' "${plugins[@]}"
}

discover_all_plugins() {
  local plugin_dir="$1"
  if [ ! -d "$plugin_dir" ]; then
    log_error "Plugin directory not found: $plugin_dir"
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
        [ $# -ge 2 ] || { log_error "$1 requires an argument"; exit 1; }
        plugin_name="$2"
        shift 2
        ;;
      *)
        log_error "Unknown option '$1'. Use --help for usage."
        exit 1
        ;;
    esac
  done

  if [ -z "$plugin_name" ]; then
    log_error "--plugin / -p is required"
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
    log_error "Plugin '$plugin_name' not found in $PLUGIN_DIR"
    exit 1
  fi
  if [ ! -f "$descriptor" ]; then
    log_error "Plugin descriptor not found: $descriptor"
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
      echo "$(ui_ok "plugin '$plugin_name' is already active")"
    else
      echo "$(ui_fail "plugin '$plugin_name' is already inactive")"
    fi
    exit 0
  fi

  local tmp
  tmp=$(mktemp)
  if jq ".active = $target_state" "$descriptor" > "$tmp" && mv "$tmp" "$descriptor"; then
    if [ "$target_state" = "true" ]; then
      echo "$(ui_ok "plugin '$plugin_name' activated")"
    else
      echo "$(ui_fail "plugin '$plugin_name' deactivated")"
    fi
  else
    rm -f "$tmp"
    log_error "Could not update descriptor.json for plugin '$plugin_name'"
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
    log_error "Plugin '$plugin_name' not found in $PLUGIN_DIR"
    exit 1
  }
  local descriptor="$plugin_dir/descriptor.json"
  if [ ! -f "$descriptor" ]; then
    log_error "Plugin descriptor not found: $descriptor"
    exit 1
  fi
  if ! jq empty "$descriptor" 2>/dev/null; then
    log_error "Plugin descriptor is not valid JSON: $descriptor"
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
      log_error "Expected '--all' after 'plugins'. Use --help for usage."
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
    log_error "Plugin '$plugin_name' not found in $PLUGIN_DIR"
    local -a available
    mapfile -t available < <(discover_all_plugins "$PLUGIN_DIR")
    if [ ${#available[@]} -gt 0 ]; then
      echo "Available plugins: ${available[*]}" >&2
    fi
    exit 1
  fi

  if [ ! -f "$descriptor" ]; then
    log_error "Plugin descriptor not found: $descriptor"
    exit 1
  fi

  if [ "$(_check_plugin_installed "$plugin_name")" = "true" ]; then
    echo "$(ui_ok "$plugin_name: already installed")"
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
    echo "$(ui_ok "$plugin_name: installed")"
  else
    local install_err
    install_err=$(cat "$install_err_file" 2>/dev/null) || install_err=""
    rm -f "$install_err_file"
    if [ -n "$install_err" ]; then
      echo "$install_err" >&2
    fi
    log_error "Installation failed for plugin '$plugin_name'"
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
      echo "$(ui_ok "$plugin_name: already installed")"
      continue
    fi

    local install_sh="$plugin_dir/install.sh"
    if [ ! -f "$install_sh" ]; then
      echo "$plugin_name: no install.sh found, skipping"
      continue
    fi

    echo "$plugin_name: installing..."
    if bash "$install_sh"; then
      echo "$(ui_ok "$plugin_name: installed")"
    else
      log_error "Installation failed for plugin '$plugin_name'"
      failed=$((failed + 1))
    fi
  done

  if [ "$failed" -gt 0 ]; then
    log_error "$failed plugin(s) failed to install"
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
        [ $# -ge 2 ] || { log_error "$1 requires an argument"; exit 1; }
        plugin_name="$2"
        shift 2
        ;;
      *)
        log_error "Unknown option '$1'. Use --help for usage."
        exit 2
        ;;
    esac
  done

  if [ -z "$plugin_name" ]; then
    log_error "--plugin / -p is required"
    exit 2
  fi

  local plugin_dir="$PLUGIN_DIR/$plugin_name"
  if [ ! -d "$plugin_dir" ]; then
    log_error "Plugin '$plugin_name' not found in $PLUGIN_DIR"
    exit 2
  fi
  if [ ! -f "$plugin_dir/descriptor.json" ]; then
    log_error "Plugin descriptor not found: $plugin_dir/descriptor.json"
    exit 2
  fi

  local installed_sh="$plugin_dir/installed.sh"
  if [ ! -f "$installed_sh" ]; then
    echo "$(ui_fail "$plugin_name: no installed.sh found — assuming not installed")"
    exit 1
  fi

  local installed_output installed_val
  installed_output=$(bash "$installed_sh" 2>/dev/null) || true
  installed_val=$(echo "$installed_output" | jq -r '.installed // "false"' 2>/dev/null) || installed_val="false"

  if [ "$installed_val" = "true" ]; then
    echo "$(ui_ok "$plugin_name: installed")"
    exit 0
  else
    echo "$(ui_fail "$plugin_name: not installed")"
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
    log_error "plugin_info.py not found: $plugin_info_script"
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
        if [ "$active" = "true" ]; then echo "$plugin_name  $(ui_ok '[active]')"
        else echo "$plugin_name  $(ui_fail '[inactive]')"; fi
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
      log_error "Too many arguments for 'list plugins'. Use: list plugins [active|inactive]"
      exit 1
    fi
    case "$filter" in
      all|"")   _list_plugins "all" ;;
      active)   _list_plugins "active" ;;
      inactive) _list_plugins "inactive" ;;
      *)
        log_error "Unknown filter '$filter'. Use: list plugins [active|inactive]"
        exit 1
        ;;
    esac
    return 0
  fi

  # Sub-command: list parameters (all plugins)
  if [ "${1:-}" = "parameters" ]; then
    if [ $# -gt 1 ]; then
      log_error "Too many arguments for 'list parameters'. Use: list parameters"
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
        [ $# -ge 2 ] || { log_error "--plugin requires an argument"; exit 1; }
        plugin_name="$2"; shift 2 ;;
      --commands)    show_commands=true; shift ;;
      --parameters)  show_parameters=true; shift ;;
      --help)        usage; exit 0 ;;
      *)
        log_error "Unknown option '$1'. Use --help for usage."
        exit 1
        ;;
    esac
  done

  # Validate flag combinations
  if [ "$show_parameters" = true ] && [ -z "$plugin_name" ]; then
    log_error "--parameters requires --plugin <name> to be specified"
    exit 1
  fi
  if [ -n "$plugin_name" ] && [ "$show_commands" = false ] && [ "$show_parameters" = false ]; then
    log_error "--plugin requires --commands or --parameters to be specified"
    exit 1
  fi
  if [ "$show_commands" = true ] && [ -z "$plugin_name" ]; then
    log_error "--commands requires --plugin <name> to be specified"
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
        log_error "Unknown option '$1'. Use --help for usage."
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
    log_error "$deps_failed mandatory dependency(ies) missing and could not be installed."
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
    log_error "$deps_failed mandatory dependency(ies) missing and could not be installed."
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
    echo "  $(ui_fail "Failures: $((deps_failed + plugins_failed))")" >&2
  fi
  echo "" >&2

  if [ "$deps_failed" -gt 0 ] || [ "$plugins_failed" -gt 0 ]; then
    return 1
  fi
  return 0
}

# --- Run command (FEATURE_0043) ---
# Invoke any command declared in a plugin's descriptor.json from the CLI.
# Builds a JSON input object from flags and pipes it to the plugin script.
# stdout/stderr and exit code are passed through directly.

# Print global run help: static usage + dynamic plugin list.
_run_global_help() {
  ui_usage_run
  echo "Available plugins:"
  local -a all_plugins
  mapfile -t all_plugins < <(discover_all_plugins "$PLUGIN_DIR")
  for plugin_name in "${all_plugins[@]}"; do
    local descriptor="$PLUGIN_DIR/$plugin_name/descriptor.json"
    [ -f "$descriptor" ] || continue
    local desc
    desc=$(jq -r '.description // ""' "$descriptor" 2>/dev/null)
    printf '  %-20s %s\n' "$plugin_name" "$desc"
  done
}

# Print per-plugin help: plugin description + command list from descriptor.json.
_run_plugin_help() {
  local plugin_name="$1" descriptor="$2"
  local plugin_desc
  plugin_desc=$(jq -r '.description // ""' "$descriptor" 2>/dev/null)
  ui_show_help_banner
  echo "Plugin: $plugin_name"
  echo ""
  echo "$plugin_desc"
  echo ""
  echo "Commands:"
  jq -r '.commands | to_entries[] | "  \(.key)\t\(.value.description // "")"' \
    "$descriptor" 2>/dev/null | sort | column -t -s $'\t'
}

# Print per-command help: description, input fields, and output fields from descriptor.json.
_run_command_help() {
  local plugin_name="$1" command_name="$2" descriptor="$3"
  local cmd_desc
  cmd_desc=$(jq -r --arg cmd "$command_name" '.commands[$cmd].description // ""' "$descriptor" 2>/dev/null)
  ui_show_help_banner
  echo "Plugin: $plugin_name"
  echo "Command: $command_name"
  echo ""
  echo "$cmd_desc"

  # Interactive commands with a "usage" block: show CLI flags instead of raw JSON fields
  local usage_len
  usage_len=$(jq -r --arg cmd "$command_name" '.commands[$cmd].usage // [] | length' "$descriptor" 2>/dev/null)
  if [ -n "$usage_len" ] && [ "$usage_len" -gt 0 ] 2>/dev/null; then
    echo ""
    echo "Usage:"
    jq -r --arg cmd "$command_name" '
      .commands[$cmd].usage[] |
      "  \(.flag)  \(.description // "")"
    ' "$descriptor" 2>/dev/null
    return 0
  fi

  # Input fields (non-interactive / no usage block)
  local has_input
  has_input=$(jq -r --arg cmd "$command_name" '.commands[$cmd].input // empty | length' "$descriptor" 2>/dev/null)
  if [ -n "$has_input" ] && [ "$has_input" -gt 0 ] 2>/dev/null; then
    echo ""
    echo "Input fields:"
    jq -r --arg cmd "$command_name" '
      .commands[$cmd].input | to_entries[] |
      "  \(.key)  (\(.value.type // "unknown"))  required=\(.value.required // false)  \(.value.description // "")"
    ' "$descriptor" 2>/dev/null
  fi

  # Output fields
  local has_output
  has_output=$(jq -r --arg cmd "$command_name" '.commands[$cmd].output // empty | length' "$descriptor" 2>/dev/null)
  if [ -n "$has_output" ] && [ "$has_output" -gt 0 ] 2>/dev/null; then
    echo ""
    echo "Output fields:"
    jq -r --arg cmd "$command_name" '
      .commands[$cmd].output | to_entries[] |
      "  \(.key)  (\(.value.type // "unknown"))  \(.value.description // "")"
    ' "$descriptor" 2>/dev/null
  fi
}

cmd_run() {
  # No args or --help: print global help with plugin list and exit 0
  if [ $# -eq 0 ] || [ "${1:-}" = "--help" ]; then
    _run_global_help
    return 0
  fi

  local plugin_name="$1"
  shift

  # Validate plugin name (security: prevent path traversal via _validate_plugin_dir)
  local plugin_dir
  plugin_dir="$(_validate_plugin_dir "$PLUGIN_DIR" "$plugin_name")" || {
    log_error "Plugin '$plugin_name' not found"
    exit 1
  }

  local descriptor="$plugin_dir/descriptor.json"
  if [ ! -f "$descriptor" ] || ! jq empty "$descriptor" 2>/dev/null; then
    log_error "Plugin '$plugin_name' not found or has invalid descriptor"
    exit 1
  fi

  # <pluginName> --help: print per-plugin command list and exit 0
  if [ "${1:-}" = "--help" ]; then
    _run_plugin_help "$plugin_name" "$descriptor"
    return 0
  fi

  # Command name is required (and --help was not passed)
  if [ $# -eq 0 ]; then
    log_error "Command name is required. Use: run $plugin_name --help"
    exit 1
  fi

  local command_name="$1"
  shift

  # Validate command name against descriptor.json (prevents arbitrary script execution)
  local command_script
  command_script=$(jq -r --arg cmd "$command_name" '.commands[$cmd].command // empty' \
    "$descriptor" 2>/dev/null)
  if [ -z "$command_script" ]; then
    log_error "Command '$command_name' not found in plugin '$plugin_name'"
    exit 1
  fi

  local script_path="$plugin_dir/$command_script"
  # Canonicalize script path and verify it stays within the plugin directory (REQ_SEC_005)
  local canonical_script canonical_plugin
  canonical_plugin="$(cd "$plugin_dir" 2>/dev/null && pwd -P)" || {
    log_error "Cannot resolve plugin directory: $plugin_dir"
    exit 1
  }
  canonical_script="$(cd "$(dirname "$script_path")" 2>/dev/null && pwd -P)/$(basename "$script_path")" 2>/dev/null || {
    log_error "Command script not found: $script_path"
    exit 1
  }
  if [ "${canonical_script#"$canonical_plugin/"}" = "$canonical_script" ]; then
    log_error "Command script is outside plugin directory (path traversal blocked): $command_script"
    exit 1
  fi
  if [ ! -f "$canonical_script" ]; then
    log_error "Command script not found: $script_path"
    exit 1
  fi
  if [ ! -x "$canonical_script" ]; then
    log_error "Command script is not executable: $script_path"
    exit 1
  fi

  # <pluginName> <commandName> --help: print per-command details and exit 0
  if [ "${1:-}" = "--help" ]; then
    _run_command_help "$plugin_name" "$command_name" "$descriptor"
    return 0
  fi

  # Parse flags: --file, --plugin-storage, --category, -d, -o, and -- key=value pairs
  local file_path="" plugin_storage="" category="" input_dir="" output_dir=""
  local -a extra_pairs=()
  local in_extra=false

  while [ $# -gt 0 ]; do
    if [ "$in_extra" = true ]; then
      extra_pairs+=("$1")
      shift
      continue
    fi
    case "$1" in
      --file)
        [ $# -ge 2 ] || { log_error "--file requires an argument"; exit 1; }
        file_path="$2"; shift 2 ;;
      --plugin-storage)
        [ $# -ge 2 ] || { log_error "--plugin-storage requires an argument"; exit 1; }
        plugin_storage="$2"; shift 2 ;;
      --category)
        [ $# -ge 2 ] || { log_error "--category requires an argument"; exit 1; }
        category="$2"; shift 2 ;;
      -d)
        [ $# -ge 2 ] || { log_error "-d requires an argument"; exit 1; }
        input_dir="$2"; shift 2 ;;
      -o)
        [ $# -ge 2 ] || { log_error "-o requires an argument"; exit 1; }
        output_dir="$2"; shift 2 ;;
      --)
        in_extra=true; shift ;;
      *)
        log_error "Unknown option '$1'. Use: run $plugin_name $command_name --help"
        exit 1 ;;
    esac
  done

  # Validate -d (input directory) if provided
  if [ -n "$input_dir" ]; then
    if [ ! -d "$input_dir" ] || [ ! -r "$input_dir" ]; then
      log_error "Input directory does not exist or is not readable: $input_dir"
      exit 1
    fi
  fi

  # Derive pluginStorage from -o if provided (FEATURE_0044, consistent with FEATURE_0041)
  if [ -n "$output_dir" ]; then
    local canonical_out
    canonical_out="$(readlink -f "$output_dir")" || {
      log_error "Cannot resolve output directory: $output_dir"
      exit 1
    }
    local derived_storage="$canonical_out/.doc.doc.md/$plugin_name"
    # Security: verify derived path is under output directory (REQ_SEC_005)
    if [ "${derived_storage#"$canonical_out/"}" = "$derived_storage" ]; then
      log_error "Derived pluginStorage is outside output directory (path traversal blocked)"
      exit 1
    fi
    mkdir -p "$derived_storage"
    if [ -n "$plugin_storage" ]; then
      log_warn "-o derives pluginStorage automatically; ignoring --plugin-storage"
    fi
    plugin_storage="$derived_storage"
  fi

  # Build JSON input safely via jq (all values passed as --arg, never interpolated)
  local json_input='{}'
  if [ -n "$file_path" ]; then
    json_input=$(printf '%s' "$json_input" | jq --arg v "$file_path" '. + {filePath: $v}')
  fi
  if [ -n "$plugin_storage" ]; then
    json_input=$(printf '%s' "$json_input" | jq --arg v "$plugin_storage" '. + {pluginStorage: $v}')
  fi
  if [ -n "$category" ]; then
    json_input=$(printf '%s' "$json_input" | jq --arg v "$category" '. + {category: $v}')
  fi
  if [ -n "$input_dir" ]; then
    json_input=$(printf '%s' "$json_input" | jq --arg v "$input_dir" '. + {inputDirectory: $v}')
  fi

  # Merge extra key=value pairs (keys and values both passed via --arg, preventing injection)
  for pair in "${extra_pairs[@]+"${extra_pairs[@]}"}"; do
    local key="${pair%%=*}"
    local val="${pair#*=}"
    if [ "$key" = "$pair" ] || [ -z "$key" ]; then
      log_error "Invalid key=value pair: '$pair'. Expected format: key=value"
      exit 1
    fi
    json_input=$(printf '%s' "$json_input" | jq --arg k "$key" --arg v "$val" '. + {($k): $v}')
  done

  # Invoke the plugin script
  # Check if command is interactive (BUG_0015): pass positional args, leave stdin free
  local is_interactive
  is_interactive=$(jq -r --arg cmd "$command_name" \
    '.commands[$cmd].interactive // false' "$descriptor" 2>/dev/null)

  if [ "$is_interactive" = "true" ]; then
    # Interactive mode: pass pluginStorage and inputDirectory as positional args
    bash "$canonical_script" "$plugin_storage" "$input_dir"
  else
    # Non-interactive mode: pipe JSON to stdin (existing behavior)
    printf '%s\n' "$json_input" | bash "$canonical_script"
  fi
}

# cmd_loop — Interactive Document Pipeline (FEATURE_0045)
# Iterates over all files in a docs directory, invoking a plugin command
# per file with pluginStorage and filePath injected into the JSON context.
# Requires an interactive terminal (TTY); exits 1 otherwise.
cmd_loop() {
  # --help before TTY check so users can always view help without a TTY
  if [ "${1:-}" = "--help" ]; then
    ui_usage_loop
    return 0
  fi

  # --- Argument parsing ---
  local docs_dir="" output_dir="" plugin_name="" loop_command=""
  local -a include_args=() exclude_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -d)
        [ $# -ge 2 ] || { log_error "-d requires an argument"; exit 1; }
        docs_dir="$2"; shift 2 ;;
      -o)
        [ $# -ge 2 ] || { log_error "-o requires an argument"; exit 1; }
        output_dir="$2"; shift 2 ;;
      --plugin)
        [ $# -ge 2 ] || { log_error "--plugin requires an argument"; exit 1; }
        plugin_name="$2"; shift 2 ;;
      --include)
        [ $# -ge 2 ] || { log_error "--include requires an argument"; exit 1; }
        include_args+=("$2"); shift 2 ;;
      --exclude)
        [ $# -ge 2 ] || { log_error "--exclude requires an argument"; exit 1; }
        exclude_args+=("$2"); shift 2 ;;
      --help)
        ui_usage_loop; return 0 ;;
      --*|-*)
        log_error "Unknown option '$1'. Use --help for usage."
        exit 1 ;;
      *)
        if [ -z "$loop_command" ]; then
          loop_command="$1"; shift
        else
          log_error "Unexpected argument '$1'. Use --help for usage."
          exit 1
        fi ;;
    esac
  done

  # --- Validate required arguments ---
  [ -n "$docs_dir" ]    || { log_error "-d <docsDir> is required. Use --help for usage."; exit 1; }
  [ -n "$output_dir" ]  || { log_error "-o <outputDir> is required. Use --help for usage."; exit 1; }
  [ -n "$plugin_name" ] || { log_error "--plugin <pluginName> is required. Use --help for usage."; exit 1; }
  [ -n "$loop_command" ] || { log_error "<command> is required. Use --help for usage."; exit 1; }

  # --- Validate plugin (path traversal guard) ---
  local plugin_dir
  plugin_dir="$(_validate_plugin_dir "$PLUGIN_DIR" "$plugin_name")" || {
    log_error "Plugin '$plugin_name' not found"
    exit 1
  }

  local descriptor="$plugin_dir/descriptor.json"
  if [ ! -f "$descriptor" ] || ! jq empty "$descriptor" 2>/dev/null; then
    log_error "Plugin '$plugin_name' not found or has invalid descriptor"
    exit 1
  fi

  # --- Validate command exists in descriptor ---
  local command_script
  command_script=$(jq -r --arg cmd "$loop_command" \
    '.commands[$cmd].command // empty' "$descriptor" 2>/dev/null)
  if [ -z "$command_script" ]; then
    log_error "Command '$loop_command' not found in plugin '$plugin_name'"
    exit 1
  fi

  # Canonicalize script path; verify it stays within the plugin directory (REQ_SEC_005)
  local canonical_plugin
  canonical_plugin="$(cd "$plugin_dir" 2>/dev/null && pwd -P)" || {
    log_error "Cannot resolve plugin directory: $plugin_dir"
    exit 1
  }
  local script_path="$plugin_dir/$command_script"
  local canonical_script
  canonical_script="$(cd "$(dirname "$script_path")" 2>/dev/null && pwd -P)/$(basename "$script_path")" || {
    log_error "Command script not found: $script_path"
    exit 1
  }
  if [ "${canonical_script#"$canonical_plugin/"}" = "$canonical_script" ]; then
    log_error "Command script is outside plugin directory (path traversal blocked)"
    exit 1
  fi
  if [ ! -x "$canonical_script" ]; then
    log_error "Command script is not executable: $script_path"
    exit 1
  fi

  # --- Validate input directory ---
  if [ ! -d "$docs_dir" ] || [ ! -r "$docs_dir" ]; then
    log_error "Input directory does not exist or is not readable: $docs_dir"
    exit 1
  fi

  # --- TTY check: loop requires an interactive terminal ---
  if [ ! -t 1 ]; then
    log_error "loop requires an interactive terminal; use --help for details"
    exit 1
  fi

  # --- Create output directory and derive pluginStorage ---
  mkdir -p "$output_dir" || { log_error "Cannot create output directory: $output_dir"; exit 1; }
  local canonical_out
  canonical_out="$(readlink -f "$output_dir")"
  local plugin_storage="$canonical_out/.doc.doc.md/$plugin_name"
  # Security: derived path must be under outputDir
  if [ "${plugin_storage#"$canonical_out/"}" = "$plugin_storage" ]; then
    log_error "Derived pluginStorage path traversal blocked"
    exit 1
  fi
  mkdir -p "$plugin_storage"

  # --- Determine minimal pipeline ---
  # Read the command's declared input fields; skip plugins whose outputs are
  # not needed (filePath and pluginStorage are always injected by loop itself).
  local -a loop_pipeline=()
  local needs_extra=false
  local _field
  while IFS= read -r _field; do
    [ -n "$_field" ] || continue
    case "$_field" in
      filePath|pluginStorage) : ;;
      *) needs_extra=true; break ;;
    esac
  done < <(jq -r --arg cmd "$loop_command" \
    '.commands[$cmd].input // {} | keys[]' "$descriptor" 2>/dev/null || true)

  if [ "$needs_extra" = true ]; then
    # At minimum, run the file plugin (provides mimeType, fileName, hash, etc.)
    loop_pipeline+=("file")
  fi

  # --- Print startup banner once ---
  ui_show_help_banner
  # Save cursor position just after the banner
  printf '\033[s'

  # --- Build file list via filter.py ---
  local -a filter_args=()
  for _inc in "${include_args[@]+"${include_args[@]}"}"; do
    filter_args+=("--include" "$_inc")
  done
  for _exc in "${exclude_args[@]+"${exclude_args[@]}"}"; do
    filter_args+=("--exclude" "$_exc")
  done

  local -a file_list
  mapfile -t file_list < <(
    find "$docs_dir" -type f | \
    python3 "$FILTER_SCRIPT" "${filter_args[@]+"${filter_args[@]}"}"
  )

  # --- Process each file ---
  for file_path in "${file_list[@]}"; do
    [ -n "$file_path" ] || continue

    # Build base JSON context
    local context_json
    context_json=$(jq -n --arg fp "$file_path" '{filePath: $fp}')

    # Run minimal pipeline plugins (graceful degradation on failure)
    local skip_file=false
    for _pname in "${loop_pipeline[@]+"${loop_pipeline[@]}"}"; do
      local _p_output="" _p_rc=0
      _p_output=$(run_plugin "$_pname" "$file_path" "$PLUGIN_DIR" "" "$context_json") || _p_rc=$?
      if [ "$_p_rc" -eq 65 ]; then
        skip_file=true
        break
      elif [ "$_p_rc" -ne 0 ]; then
        # Graceful degradation: continue with partial context
        continue
      else
        context_json=$(printf '%s\n%s' "$context_json" "$_p_output" | jq -s '.[0] * .[1]')
      fi
    done

    if [ "$skip_file" = true ]; then
      continue  # Silent skip (exit 65 from pipeline — ADR-004)
    fi

    # Inject pluginStorage (always provided by loop)
    context_json=$(printf '%s' "$context_json" | \
      jq --arg ps "$plugin_storage" '. + {pluginStorage: $ps}')

    # Reset cursor to just after banner, clear below to remove previous output
    printf '\033[u\033[J'

    # Invoke target plugin command
    local cmd_rc=0
    printf '%s\n' "$context_json" | bash "$canonical_script" || cmd_rc=$?

    if [ "$cmd_rc" -eq 65 ]; then
      : # Silent skip per ADR-004
    elif [ "$cmd_rc" -ne 0 ]; then
      log_warn "Command '$loop_command' failed (exit $cmd_rc) for: $(basename "$file_path"); continuing"
    fi
  done
}
