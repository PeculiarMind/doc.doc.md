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

# Source components
source "$PLUGIN_MGMT_COMPONENT"
source "$PLUGIN_EXEC_COMPONENT"
source "$UI_COMPONENT"
source "$TEMPLATES_COMPONENT"

# Global MIME filter criteria (set by main, consumed by process_file)
_MIME_INCLUDE_ARGS=()
_MIME_EXCLUDE_ARGS=()

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
    setup)
      cmd_setup "$@"
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
  local progress_flag=""
  local echo_mode=false
  local base_path=""

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
      --progress)
        progress_flag="on"
        shift
        ;;
      --no-progress)
        progress_flag="off"
        shift
        ;;
      --echo)
        echo_mode=true
        shift
        ;;
      -b|--base-path)
        [ $# -ge 2 ] || { echo "Error: $1 requires an argument" >&2; exit 1; }
        base_path="$2"
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

  # Validate --echo and -o mutual exclusivity
  if [ "$echo_mode" = true ] && [ -n "$output_dir" ]; then
    echo "Error: --echo and -o are mutually exclusive" >&2
    exit 1
  fi

  # Validate output directory (required unless --echo)
  if [ "$echo_mode" = false ] && [ -z "$output_dir" ]; then
    echo "Error: Output directory is required (-o <dir>)" >&2
    usage >&2
    exit 1
  fi

  # Validate template file
  if [ ! -f "$template_file" ]; then
    echo "Error: Template file not found: $template_file" >&2
    exit 1
  fi

  # Validate --base-path if provided
  local base_path_resolved=""
  if [ -n "$base_path" ]; then
    base_path_resolved="$(readlink -f "$base_path" 2>/dev/null || echo "")"
    if [ -z "$base_path_resolved" ] || [ ! -d "$base_path_resolved" ]; then
      echo "Error: Base path does not exist or is not a directory: $base_path" >&2
      exit 1
    fi
  fi

  # Canonicalize and create output directory (only when not in echo mode)
  local canonical_out=""
  if [ "$echo_mode" = false ]; then
    mkdir -p "$output_dir" || { echo "Error: Cannot create output directory: $output_dir" >&2; exit 1; }
    canonical_out="$(readlink -f "$output_dir")"
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

  # Determine whether to show progress display
  local show_progress=false
  if [ "$echo_mode" = true ]; then
    show_progress=false
  elif [ "$progress_flag" = "on" ]; then
    show_progress=true
  elif [ "$progress_flag" = "off" ]; then
    show_progress=false
  elif [ -t 2 ]; then
    show_progress=true
  fi

  # Suppress JSON output when stdout is an interactive TTY and an output
  # directory is provided — JSON is only meaningful for Unix pipelines.
  local suppress_json=false
  if [ "$echo_mode" = true ]; then
    suppress_json=true
  elif [ -t 1 ]; then
    suppress_json=true
  fi

  # Build path-only filter arguments for the pre-processing find step
  local -a filter_args=()
  for inc in "${path_include_args[@]+"${path_include_args[@]}"}"; do
    filter_args+=("--include" "$inc")
  done
  for exc in "${path_exclude_args[@]+"${path_exclude_args[@]}"}"; do
    filter_args+=("--exclude" "$exc")
  done

  # Banner: Show ASCII art when interactive and not in echo mode (FEATURE_0030)
  if [ "$show_progress" = true ] && [ "$echo_mode" = false ]; then
    ui_show_banner
  fi

  # Progress: Scan phase
  if [ "$show_progress" = true ]; then
    ui_progress_init 0
    ui_progress_update phase "Scan directory"
    ui_progress_update step "Reading directory tree"
  fi

  # Discover files and apply filters
  local -a file_list
  mapfile -t file_list < <(
    find "$input_dir" -type f | \
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

  # Progress: Update found count and transition to process phase
  if [ "$show_progress" = true ]; then
    ui_progress_update step "Apply include/exclude filters"
    ui_progress_update found "${#file_list[@]}"
    ui_progress_update total "${#file_list[@]}"
    ui_progress_update phase "Process documents"
  fi

  # Process each file through all plugins, write sidecar .md files, stream JSON results
  # Track bracket state: print '[' only on first non-skipped result to handle
  # the case where all files are MIME-filtered out (need to print '[]' then).
  local first=true
  local printed_bracket=false
  local processed_count=0
  for file_path in "${file_list[@]}"; do
    [ -n "$file_path" ] || continue

    local relative_path="${file_path#${input_dir}/}"

    if [ "$show_progress" = true ]; then
      ui_progress_update step "Execute plugins"
      ui_progress_update file "$relative_path"
    fi

    local result
    result=$(process_file "$file_path" "${plugins[@]}")
    [ -n "$result" ] || continue

    # Apply --base-path rewrite for template rendering (FEATURE_0031)
    local render_json="$result"
    if [ -n "$base_path_resolved" ]; then
      local bp_relative
      bp_relative=$(python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$file_path" "$base_path_resolved")
      render_json=$(echo "$result" | jq --arg fp "$bp_relative" '. + {filePath: $fp}')
    fi

    if [ "$echo_mode" = true ]; then
      # --echo mode: print rendered content to stdout with delimiter
      if [ "$first" = true ]; then
        first=false
      else
        echo ""
      fi
      echo "=== $relative_path ==="
      render_template_json "$template_file" "$render_json"
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

    # Write sidecar .md file to output directory
    local sidecar_path="${canonical_out}/${relative_path}.md"
    local sidecar_dir
    sidecar_dir="$(dirname "$sidecar_path")"

    # Create sidecar dir first so readlink -f can canonicalize it
    mkdir -p "$sidecar_dir"
    local canonical_sidecar
    canonical_sidecar="$(readlink -f "$sidecar_dir" 2>/dev/null)"
    if [ -z "$canonical_sidecar" ]; then
      echo "Error: Cannot resolve sidecar path for '$file_path'" >&2
      continue
    fi

    # Boundary check: ensure sidecar stays within output_dir
    if [[ "$canonical_sidecar" != "${canonical_out}" && "$canonical_sidecar" != "${canonical_out}/"* ]]; then
      echo "Error: path traversal detected for '$file_path'" >&2
      continue
    fi

    if [ "$show_progress" = true ]; then
      ui_progress_update step "Write output"
    fi

    render_template_json "$template_file" "$render_json" > "$sidecar_path"
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

main "$@"
