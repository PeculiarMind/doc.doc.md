#!/usr/bin/env bash
# Component: plugin_display.sh
# Purpose: Plugin listing and formatting
# Dependencies: plugin/plugin_discovery.sh, plugin/plugin_parser.sh
# Exports: list_plugins(), format_plugin_info(), display_plugin_list()
# Side Effects: None (pure formatting, outputs to stdout)

# ==============================================================================
# Plugin Display Functions
# ==============================================================================

# Display formatted plugin list
# Arguments:
#   $@ - Array of plugin data strings (name|description|active)
display_plugin_list() {
  local -a plugins=("$@")
  
  if [[ ${#plugins[@]} -eq 0 ]]; then
    echo "No plugins found."
    return
  fi
  
  echo "Available Plugins:"
  echo "===================================="
  echo
  
  # Sort plugins by name
  local -a sorted_plugins
  IFS=$'\n' sorted_plugins=($(sort <<<"${plugins[*]}"))
  unset IFS
  
  # Display each plugin
  for plugin_data in "${sorted_plugins[@]}"; do
    # Parse pipe-delimited data
    local name="${plugin_data%%|*}"
    local rest="${plugin_data#*|}"
    local description="${rest%%|*}"
    local active="${rest##*|}"
    
    # Truncate description if too long
    if [[ ${#description} -gt 80 ]]; then
      description="${description:0:77}..."
    fi
    
    # Display with status indicator
    if [[ "${active}" == "true" ]]; then
      printf "[ACTIVE]   %s\n" "${name}"
    else
      printf "[INACTIVE] %s\n" "${name}"
    fi
    printf "           %s\n\n" "${description}"
  done
}

# List all available plugins
list_plugins() {
  log "INFO" "PLUGIN" "Listing available plugins"
  
  # Discover plugins
  local plugin_data
  plugin_data=$(discover_plugins)
  
  # Convert to array
  local -a plugins=()
  while IFS= read -r line; do
    [[ -n "${line}" ]] && plugins+=("${line}")
  done <<< "${plugin_data}"
  
  # Display plugin list
  display_plugin_list "${plugins[@]}"
}

# Format plugin info for display (future use)
# Arguments:
#   $1 - Plugin data (name|description|active)
# Returns:
#   Formatted string
format_plugin_info() {
  local plugin_data="$1"
  # Placeholder for formatting logic
  echo "${plugin_data}"
}
