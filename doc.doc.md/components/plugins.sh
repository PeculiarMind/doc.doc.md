#!/bin/bash
# plugins.sh - Plugin execution component
# Part of doc.doc.md architecture (Level 3: Bash Components)
# Handles plugin command invocation and JSON I/O per ADR-003
# NOTE: Plugin discovery and management functions have been moved to
# plugin_management.sh (FEATURE_0021).

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
