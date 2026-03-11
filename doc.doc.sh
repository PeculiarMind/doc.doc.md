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
PLUGIN_MGMT_COMPONENT="$SCRIPT_DIR/doc.doc.md/components/plugin_management.sh"
PLUGIN_EXEC_COMPONENT="$SCRIPT_DIR/doc.doc.md/components/plugin_execution.sh"
UI_COMPONENT="$SCRIPT_DIR/doc.doc.md/components/ui.sh"
TEMPLATES_COMPONENT="$SCRIPT_DIR/doc.doc.md/components/templates.sh"
DEFAULT_TEMPLATE="$SCRIPT_DIR/doc.doc.md/templates/default.md"

# Source components
source "$PLUGIN_MGMT_COMPONENT"
source "$PLUGIN_EXEC_COMPONENT"
source "$UI_COMPONENT"
source "$TEMPLATES_COMPONENT"

# Global MIME filter criteria (consumed by process_file in plugin_execution.sh)
_MIME_INCLUDE_ARGS=()
_MIME_EXCLUDE_ARGS=()
# Process command state — set by _parse/_validate/_prepare/_split functions
_PROC_INPUT_DIR=""
_PROC_OUTPUT_DIR=""
_PROC_TEMPLATE_FILE=""
_PROC_INCLUDE_ARGS=()
_PROC_EXCLUDE_ARGS=()
_PROC_PROGRESS_FLAG=""
_PROC_ECHO_MODE=false
_PROC_BASE_PATH=""
_PROC_BASE_PATH_RESOLVED=""
_PROC_CANONICAL_OUT=""
_PROC_PLUGINS=()
_PROC_PATH_INCLUDE_ARGS=()
_PROC_PATH_EXCLUDE_ARGS=()

_parse_process_args() {
  _PROC_INPUT_DIR=""
  _PROC_OUTPUT_DIR=""
  _PROC_TEMPLATE_FILE="$DEFAULT_TEMPLATE"
  _PROC_INCLUDE_ARGS=()
  _PROC_EXCLUDE_ARGS=()
  _PROC_PROGRESS_FLAG=""
  _PROC_ECHO_MODE=false
  _PROC_BASE_PATH=""

  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--input-directory)
        [ $# -ge 2 ] || { echo "Error: $1 requires an argument" >&2; exit 1; }
        _PROC_INPUT_DIR="$2"
        shift 2
        ;;
      -o|--output-directory)
        [ $# -ge 2 ] || { echo "Error: $1 requires an argument" >&2; exit 1; }
        _PROC_OUTPUT_DIR="$2"
        shift 2
        ;;
      -t|--template)
        [ $# -ge 2 ] || { echo "Error: $1 requires an argument" >&2; exit 1; }
        _PROC_TEMPLATE_FILE="$2"
        shift 2
        ;;
      -i)
        [ $# -ge 2 ] || { echo "Error: -i requires an argument" >&2; exit 1; }
        _PROC_INCLUDE_ARGS+=("$2")
        shift 2
        ;;
      -e)
        [ $# -ge 2 ] || { echo "Error: -e requires an argument" >&2; exit 1; }
        _PROC_EXCLUDE_ARGS+=("$2")
        shift 2
        ;;
      --progress)
        _PROC_PROGRESS_FLAG="on"
        shift
        ;;
      --no-progress)
        _PROC_PROGRESS_FLAG="off"
        shift
        ;;
      --echo)
        _PROC_ECHO_MODE=true
        shift
        ;;
      -b|--base-path)
        [ $# -ge 2 ] || { echo "Error: $1 requires an argument" >&2; exit 1; }
        _PROC_BASE_PATH="$2"
        shift 2
        ;;
      --help)
        ui_usage_process
        exit 0
        ;;
      *)
        echo "Error: Unknown option '$1'. Use --help for usage." >&2
        exit 1
        ;;
    esac
  done
}

_validate_process_inputs() {
  if [ -z "$_PROC_INPUT_DIR" ]; then
    echo "Error: Input directory is required (-d <dir>)" >&2
    usage >&2
    exit 1
  fi

  if [ ! -d "$_PROC_INPUT_DIR" ]; then
    echo "Error: Input directory does not exist: $_PROC_INPUT_DIR" >&2
    exit 1
  fi

  if [ ! -r "$_PROC_INPUT_DIR" ]; then
    echo "Error: Input directory is not readable: $_PROC_INPUT_DIR" >&2
    exit 1
  fi

  if [ "$_PROC_ECHO_MODE" = true ] && [ -n "$_PROC_OUTPUT_DIR" ]; then
    echo "Error: --echo and -o are mutually exclusive" >&2
    exit 1
  fi

  if [ "$_PROC_ECHO_MODE" = false ] && [ -z "$_PROC_OUTPUT_DIR" ]; then
    echo "Error: Output directory is required (-o <dir>)" >&2
    usage >&2
    exit 1
  fi

  if [ ! -f "$_PROC_TEMPLATE_FILE" ]; then
    echo "Error: Template file not found: $_PROC_TEMPLATE_FILE" >&2
    exit 1
  fi

  _PROC_BASE_PATH_RESOLVED=""
  if [ -n "$_PROC_BASE_PATH" ]; then
    _PROC_BASE_PATH_RESOLVED="$(readlink -f "$_PROC_BASE_PATH" 2>/dev/null || echo "")"
    if [ -z "$_PROC_BASE_PATH_RESOLVED" ] || [ ! -d "$_PROC_BASE_PATH_RESOLVED" ]; then
      echo "Error: Base path does not exist or is not a directory: $_PROC_BASE_PATH" >&2
      exit 1
    fi
  fi

  _PROC_CANONICAL_OUT=""
  if [ "$_PROC_ECHO_MODE" = false ]; then
    mkdir -p "$_PROC_OUTPUT_DIR" || { echo "Error: Cannot create output directory: $_PROC_OUTPUT_DIR" >&2; exit 1; }
    _PROC_CANONICAL_OUT="$(readlink -f "$_PROC_OUTPUT_DIR")"
  fi

  if [ ! -f "$FILTER_SCRIPT" ]; then
    echo "Error: Filter engine not found: $FILTER_SCRIPT" >&2
    exit 1
  fi
}

_prepare_plugins() {
  local -a plugins
  mapfile -t plugins < <(discover_plugins "$PLUGIN_DIR")

  if [ ${#plugins[@]} -eq 0 ]; then
    echo "Error: No active plugins found in $PLUGIN_DIR" >&2
    exit 1
  fi

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

  local -a _uninstalled_plugins=()
  for p in "${plugins[@]}"; do
    local p_installed_sh="$PLUGIN_DIR/$p/installed.sh"
    if [ -x "$p_installed_sh" ]; then
      local install_check
      install_check=$(bash "$p_installed_sh" 2>/dev/null | jq -r 'if .installed == false then "false" else "true" end' 2>/dev/null) || install_check="false"
      if [ "$install_check" = "false" ]; then
        _uninstalled_plugins+=("$p")
      fi
    fi
  done

  if [ ${#_uninstalled_plugins[@]} -gt 0 ]; then
    if ! [ -t 0 ]; then
      echo "Error: The following active plugin(s) are not installed: ${_uninstalled_plugins[*]}" >&2
      echo "Run: ./doc.doc.sh install --plugin <name>  or  ./doc.doc.sh setup" >&2
      exit 1
    fi

    local -a _skip_plugins=()
    for _up in "${_uninstalled_plugins[@]}"; do
      printf "Plugin '%s' is not installed.\n" "$_up" >&2
      printf "  [c] Continue without this plugin\n" >&2
      printf "  [a] Abort\n" >&2
      printf "  [i] Install now\n" >&2
      printf "Choice [c/a/i]: " >&2
      local _choice=""
      read -r _choice </dev/tty 2>/dev/null || _choice="a"
      case "$_choice" in
        c|C)
          _skip_plugins+=("$_up")
          ;;
        i|I)
          local _up_install_sh="$PLUGIN_DIR/$_up/install.sh"
          if [ -x "$_up_install_sh" ] && bash "$_up_install_sh"; then
            echo "Plugin '$_up' installed successfully." >&2
          else
            echo "Error: Installation failed for plugin '$_up'" >&2
            echo "Tip: sudo ./doc.doc.sh install --plugin $_up" >&2
            exit 1
          fi
          ;;
        *)
          exit 1
          ;;
      esac
    done

    if [ ${#_skip_plugins[@]} -gt 0 ]; then
      local -a _remaining_plugins=()
      for p in "${plugins[@]}"; do
        local _is_skipped=false
        for _sp in "${_skip_plugins[@]}"; do
          [ "$p" = "$_sp" ] && _is_skipped=true && break
        done
        [ "$_is_skipped" = false ] && _remaining_plugins+=("$p")
      done
      plugins=("${_remaining_plugins[@]}")
    fi
  fi

  _PROC_PLUGINS=("${plugins[@]}")
}

_split_filter_criteria() {
  local -a mime_include_args=()
  local -a mime_exclude_args=()
  _PROC_PATH_INCLUDE_ARGS=()
  _PROC_PATH_EXCLUDE_ARGS=()

  for inc in "${_PROC_INCLUDE_ARGS[@]+"${_PROC_INCLUDE_ARGS[@]}"}"; do
    if [[ "$inc" == *"/"* ]] && [[ "$inc" != *"**"* ]]; then
      mime_include_args+=("$inc")
    else
      _PROC_PATH_INCLUDE_ARGS+=("$inc")
    fi
  done
  for exc in "${_PROC_EXCLUDE_ARGS[@]+"${_PROC_EXCLUDE_ARGS[@]}"}"; do
    if [[ "$exc" == *"/"* ]] && [[ "$exc" != *"**"* ]]; then
      mime_exclude_args+=("$exc")
    else
      _PROC_PATH_EXCLUDE_ARGS+=("$exc")
    fi
  done

  _MIME_INCLUDE_ARGS=("${mime_include_args[@]+"${mime_include_args[@]}"}")
  _MIME_EXCLUDE_ARGS=("${mime_exclude_args[@]+"${mime_exclude_args[@]}"}")
}

_run_process_pipeline() {
  local show_progress=false
  if [ "$_PROC_ECHO_MODE" = true ]; then
    show_progress=false
  elif [ "$_PROC_PROGRESS_FLAG" = "on" ]; then
    show_progress=true
  elif [ "$_PROC_PROGRESS_FLAG" = "off" ]; then
    show_progress=false
  elif [ -t 2 ]; then
    show_progress=true
  fi

  # Suppress JSON when stdout is a TTY — JSON is only meaningful for pipelines
  local suppress_json=false
  if [ "$_PROC_ECHO_MODE" = true ]; then
    suppress_json=true
  elif [ -t 1 ]; then
    suppress_json=true
  fi

  local -a filter_args=()
  for inc in "${_PROC_PATH_INCLUDE_ARGS[@]+"${_PROC_PATH_INCLUDE_ARGS[@]}"}"; do
    filter_args+=("--include" "$inc")
  done
  for exc in "${_PROC_PATH_EXCLUDE_ARGS[@]+"${_PROC_PATH_EXCLUDE_ARGS[@]}"}"; do
    filter_args+=("--exclude" "$exc")
  done

  if [ "$show_progress" = true ] && [ "$_PROC_ECHO_MODE" = false ]; then
    ui_show_banner
  fi

  if [ "$show_progress" = true ]; then
    ui_progress_init 0
    ui_progress_update phase "Scan directory"
    ui_progress_update step "Reading directory tree"
  fi

  local -a file_list
  mapfile -t file_list < <(
    find "$_PROC_INPUT_DIR" -type f | \
    python3 "$FILTER_SCRIPT" "${filter_args[@]+"${filter_args[@]}"}"
  )

  if [ ${#file_list[@]} -eq 0 ]; then
    if [ "$show_progress" = true ]; then
      ui_progress_done 0
    fi
    if [ "$suppress_json" = false ]; then
      echo "[]"
    fi
    exit 0
  fi

  if [ "$show_progress" = true ]; then
    ui_progress_update step "Apply include/exclude filters"
    ui_progress_update found "${#file_list[@]}"
    ui_progress_update total "${#file_list[@]}"
    ui_progress_update phase "Process documents"
  fi

  local first=true printed_bracket=false processed_count=0
  for file_path in "${file_list[@]}"; do
    [ -n "$file_path" ] || continue

    local relative_path="${file_path#${_PROC_INPUT_DIR}/}"

    if [ "$show_progress" = true ]; then
      ui_progress_update step "Execute plugins"
      ui_progress_update file "$relative_path"
    fi

    local result
    result=$(process_file "$file_path" "${_PROC_PLUGINS[@]}")
    [ -n "$result" ] || continue

    local render_json="$result"
    if [ -n "$_PROC_BASE_PATH_RESOLVED" ]; then
      local bp_relative
      bp_relative=$(python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$file_path" "$_PROC_BASE_PATH_RESOLVED")
      render_json=$(echo "$result" | jq --arg fp "$bp_relative" '. + {filePath: $fp}')
    fi

    if [ "$_PROC_ECHO_MODE" = true ]; then
      if [ "$first" = true ]; then
        first=false
      else
        echo ""
      fi
      echo "=== $relative_path ==="
      render_template_json "$_PROC_TEMPLATE_FILE" "$render_json"
      echo ""
      processed_count=$((processed_count + 1))
      continue
    fi

    if [ "$suppress_json" = false ]; then
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
    else
      printed_bracket=true
      first=false
    fi

    local sidecar_path="${_PROC_CANONICAL_OUT}/${relative_path}.md"
    local sidecar_dir
    sidecar_dir="$(dirname "$sidecar_path")"

    mkdir -p "$sidecar_dir"
    local canonical_sidecar
    canonical_sidecar="$(readlink -f "$sidecar_dir" 2>/dev/null)"
    if [ -z "$canonical_sidecar" ]; then
      echo "Error: Cannot resolve sidecar path for '$file_path'" >&2
      continue
    fi

    if [[ "$canonical_sidecar" != "${_PROC_CANONICAL_OUT}" && "$canonical_sidecar" != "${_PROC_CANONICAL_OUT}/"* ]]; then
      echo "Error: path traversal detected for '$file_path'" >&2
      continue
    fi

    if [ "$show_progress" = true ]; then
      ui_progress_update step "Write output"
    fi

    render_template_json "$_PROC_TEMPLATE_FILE" "$render_json" > "$sidecar_path"
    processed_count=$((processed_count + 1))

    if [ "$show_progress" = true ]; then
      ui_progress_update done "$processed_count"
    else
      log_processed "$file_path" "$sidecar_path"
    fi
  done

  if [ "$show_progress" = true ]; then
    ui_progress_update phase "Done"
    ui_progress_update step ""
    ui_progress_done "$processed_count"
  else
    echo "Processed $processed_count documents." >&2
  fi

  if [ "$suppress_json" = false ]; then
    if [ "$printed_bracket" = false ]; then
      echo "[]"
    else
      echo ""
      echo "]"
    fi
  fi
}

# --- Entry point ---

main() {
  if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
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
    setup)
      cmd_setup "$@"
      exit $?
      ;;
    *)
      echo "Error: Unknown command '$command'. Use --help for usage." >&2
      exit 1
      ;;
  esac

  _parse_process_args "$@"
  _validate_process_inputs
  _prepare_plugins
  _split_filter_criteria
  _run_process_pipeline
}

main "$@"
