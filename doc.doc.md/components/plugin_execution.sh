#!/bin/bash
# plugin_execution.sh - Plugin Execution module for doc.doc.md
# Part of doc.doc.md architecture (Level 3: Bash Components)
# Handles plugin command invocation, stdin/stdout JSON I/O wiring,
# exit-code classification (0 = success, 1 = plugin error, 2 = fatal),
# and output validation per ADR-003.
# Contains NO plugin discovery, descriptor loading, or activation state logic.
#
# Public Interface:
#   run_plugin <name> <file_path> <plugin_base_dir> [context_json]
#       - Invoke a plugin's process command with JSON I/O
#       - Returns 0 on success, 1 on plugin error

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
