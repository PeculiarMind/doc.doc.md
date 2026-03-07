#!/bin/bash
# plugin_execution.sh - Plugin Execution module for doc.doc.md
# Part of doc.doc.md architecture (Level 3: Bash Components)
# Handles plugin command invocation, stdin/stdout JSON I/O wiring,
# exit-code classification (ADR-004: 0 = success, 65 = skip, 1 = error, 2 = fatal),
# and output validation per ADR-003.
# Contains NO plugin discovery, descriptor loading, or activation state logic.
#
# Public Interface:
#   run_plugin <name> <file_path> <plugin_base_dir> [context_json]
#       - Invoke a plugin's process command with JSON I/O
#       - Returns the plugin's exit code (0 success, 65 skip, other = error)
#   process_file <file_path> <plugin...>
#       - Run a file through a sequence of plugins, merging JSON output

# --- Plugin execution ---

run_plugin() {
  local plugin_name="$1"
  local file_path="$2"
  local plugin_base_dir="$3"
  local context_json="${4:-}"
  local plugin_dir="$plugin_base_dir/$plugin_name"
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

  # Build JSON input: start with filePath, then merge any accumulated context
  local json_input
  json_input=$(jq -n --arg filePath "$file_path" '{filePath: $filePath}')
  if [ -n "$context_json" ]; then
    json_input=$(printf '%s\n%s' "$json_input" "$context_json" | jq -s '.[0] * .[1]')
  fi

  local plugin_output
  local plugin_exit=0
  plugin_output=$(echo "$json_input" | "$script_path" 2>/dev/null) || plugin_exit=$?

  # Propagate exit 65 (ADR-004 intentional skip) directly to caller
  if [ "$plugin_exit" -eq 65 ]; then
    echo "$plugin_output"
    return 65
  fi

  # Any other non-zero exit is a plugin error
  if [ "$plugin_exit" -ne 0 ]; then
    echo "Error: Plugin '$plugin_name' failed for file: $(basename "$file_path")" >&2
    return 1
  fi

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
    local plugin_rc=0
    plugin_output=$(run_plugin "$plugin_name" "$file_path" "$PLUGIN_DIR" "$combined_result") || plugin_rc=$?

    if [ "$plugin_rc" -eq 0 ]; then
      # Success: merge plugin output into combined result
      combined_result=$(echo "$combined_result" "$plugin_output" | jq -s '.[0] * .[1]')
    elif [ "$plugin_rc" -eq 65 ]; then
      # ADR-004 intentional skip: silently discard — no merge, no error
      continue
    else
      # Plugin error
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
