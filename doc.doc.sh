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
  process    Process files in the input directory through plugins
  list       List information about plugins

process Options:
  -d <dir>   Input directory to process (required)
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
  --plugin <name>    Name of the plugin to inspect (required with --commands)
  --commands         List all commands declared by the specified plugin

  --help     Show this help message

Examples:
  $(basename "$0") process -d /path/to/documents
  $(basename "$0") process -d /path/to/documents -i ".pdf,.txt"
  $(basename "$0") process -d /path/to/documents -i ".pdf" -e "**/temp/**"
  $(basename "$0") list --plugin stat --commands
  $(basename "$0") list plugins
  $(basename "$0") list plugins active
  $(basename "$0") list plugins inactive
EOF
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

  local plugin_name=""
  local show_commands=false

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
  if [ -n "$plugin_name" ] && [ "$show_commands" = false ]; then
    echo "Error: --plugin requires --commands to be specified" >&2
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

  # No recognized sub-command given
  usage >&2
  exit 1
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
    if plugin_output=$(run_plugin "$plugin_name" "$file_path" "$PLUGIN_DIR"); then
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
    *)
      echo "Error: Unknown command '$command'. Use --help for usage." >&2
      exit 1
      ;;
  esac

  local input_dir=""
  local -a include_args=()
  local -a exclude_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -d)
        [ $# -ge 2 ] || { echo "Error: -d requires an argument" >&2; exit 1; }
        input_dir="$2"
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

  # Process each file through all plugins and stream results
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
  done

  if [ "$printed_bracket" = false ]; then
    echo "[]"
  else
    echo ""
    echo "]"
  fi
}

main "$@"
