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

# --- Usage ---

usage() {
  cat <<EOF
Usage: $(basename "$0") process -d <input-dir> [OPTIONS]

Commands:
  process    Process files in the input directory through plugins

Options:
  -d <dir>   Input directory to process (required)
  -i <criteria>  Include filter criteria (repeatable)
                  Comma-separated values are ORed; multiple -i flags are ANDed
                  Examples: -i ".pdf,.txt" -i "**/2024/**"
  -e <criteria>  Exclude filter criteria (repeatable)
                  Comma-separated values are ORed; multiple -e flags are ANDed
                  Examples: -e ".log" -e "**/temp/**"
  --help     Show this help message

Examples:
  $(basename "$0") process -d /path/to/documents
  $(basename "$0") process -d /path/to/documents -i ".pdf,.txt"
  $(basename "$0") process -d /path/to/documents -i ".pdf" -e "**/temp/**"
EOF
}

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
      # Check plugin is active
      local active
      active=$(jq -r '.active // true' "$descriptor")
      if [ "$active" = "true" ]; then
        plugins+=("$(basename "$dir")")
      fi
    else
      echo "Warning: No descriptor.json in $(basename "$dir"), skipping" >&2
    fi
  done

  printf '%s\n' "${plugins[@]}"
}

# --- Plugin execution ---

run_plugin() {
  local plugin_name="$1"
  local file_path="$2"
  local plugin_dir="$PLUGIN_DIR/$plugin_name"
  local descriptor="$plugin_dir/descriptor.json"

  # Get the process command from descriptor
  local command_script
  command_script=$(jq -r '.commands.process.command // empty' "$descriptor")
  if [ -z "$command_script" ]; then
    echo "Error: No process command defined for plugin '$plugin_name'" >&2
    return 1
  fi

  local script_path="$plugin_dir/$command_script"
  if [ ! -x "$script_path" ]; then
    echo "Error: Plugin script not found or not executable: $plugin_name/$command_script" >&2
    return 1
  fi

  # Build JSON input and execute plugin
  local json_input
  json_input=$(jq -n --arg filePath "$file_path" '{filePath: $filePath}')

  local plugin_output
  plugin_output=$(echo "$json_input" | "$script_path" 2>/dev/null) || {
    echo "Error: Plugin '$plugin_name' failed for file: $(basename "$file_path")" >&2
    return 1
  }

  # Validate output is valid JSON
  if ! echo "$plugin_output" | jq empty 2>/dev/null; then
    echo "Error: Plugin '$plugin_name' returned invalid JSON for file: $(basename "$file_path")" >&2
    return 1
  fi

  echo "$plugin_output"
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
    if plugin_output=$(run_plugin "$plugin_name" "$file_path"); then
      # Merge plugin output into combined result
      combined_result=$(echo "$combined_result" "$plugin_output" | jq -s '.[0] * .[1]')
    else
      # Graceful degradation: continue with partial results
      continue
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

  if [ "$command" != "process" ]; then
    echo "Error: Unknown command '$command'. Use --help for usage." >&2
    exit 1
  fi

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

  # Build filter arguments
  local -a filter_args=()
  for inc in "${include_args[@]+"${include_args[@]}"}"; do
    filter_args+=("--include" "$inc")
  done
  for exc in "${exclude_args[@]+"${exclude_args[@]}"}"; do
    filter_args+=("--exclude" "$exc")
  done

  # Discover files and apply filters
  local -a file_list
  mapfile -t file_list < <(
    find "$input_dir" -type f | sort | \
    python3 "$FILTER_SCRIPT" "${filter_args[@]+"${filter_args[@]}"}"
  )

  if [ ${#file_list[@]} -eq 0 ]; then
    echo "[]"
    exit 0
  fi

  # Process each file through all plugins and collect results
  local first=true
  echo "["
  for file_path in "${file_list[@]}"; do
    [ -n "$file_path" ] || continue
    if [ "$first" = true ]; then
      first=false
    else
      echo ","
    fi
    process_file "$file_path" "${plugins[@]}"
  done
  echo ""
  echo "]"
}

main "$@"
