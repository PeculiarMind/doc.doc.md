#!/bin/bash
# plugins.sh - Plugin lifecycle management component
# Part of doc.doc.md architecture (Level 3: Bash Components)
# Handles plugin discovery, validation, and execution per ADR-003

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
