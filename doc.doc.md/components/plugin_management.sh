#!/bin/bash
# plugin_management.sh - Plugin Management module for doc.doc.md
# Part of doc.doc.md architecture (Level 3: Bash Components)
# Handles plugin discovery, descriptor.json parsing, installation-state
# checking, and activation/deactivation state management.
# Contains NO plugin invocation, stdin/stdout JSON I/O, or exit-code
# classification logic.
#
# Public Interface:
#   discover_plugins <plugin_dir>            - Discover active plugins with valid descriptors
#   discover_all_plugins <plugin_dir>        - Discover all plugins (active + inactive), sorted
#   get_plugin_active_status <descriptor>    - Get activation status from descriptor.json

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
