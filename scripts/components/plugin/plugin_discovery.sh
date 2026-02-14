#!/usr/bin/env bash
# Component: plugin_discovery.sh
# Purpose: Plugin discovery and validation
# Dependencies: core/platform_detection.sh, plugin/plugin_parser.sh
# Exports: discover_plugins(), validate_plugin(), filter_active_plugins()
# Side Effects: Reads filesystem

# ==============================================================================
# Plugin Discovery Functions
# ==============================================================================

# Discover all plugins in the plugins directory
# Returns:
#   Echoes newline-separated list of pipe-delimited plugin data: "name|description|active|descriptor_path"
discover_plugins() {
  # Allow overriding plugins directory for testing
  local plugins_dir="${PLUGINS_DIR:-${SCRIPT_DIR}/plugins}"
  
  log "DEBUG" "PLUGIN" "Searching for plugins in: ${plugins_dir}"
  
  # Check if plugins directory exists
  if [[ ! -d "${plugins_dir}" ]]; then
    error_exit "Plugins directory not found: ${plugins_dir}" "${EXIT_FILE_ERROR}"
  fi
  
  # Platform-specific directory (e.g., plugins/ubuntu/)
  local platform_dir="${plugins_dir}/${PLATFORM}"
  
  # Generic/cross-platform directory (plugins/all/)
  local all_dir="${plugins_dir}/all"
  
  # Array to store discovered plugin data
  local -a plugin_list=()
  
  # Track plugin names to handle duplicates (platform-specific takes precedence)
  declare -A seen_plugins
  
  # Discover platform-specific plugins first (higher priority)
  if [[ -d "${platform_dir}" ]]; then
    log "DEBUG" "PLUGIN" "Searching platform-specific plugins in: ${platform_dir}"
    
    while IFS= read -r -d '' descriptor_file; do
      log "DEBUG" "PLUGIN" "Found descriptor: ${descriptor_file}"
      
      local plugin_data
      if plugin_data=$(parse_plugin_descriptor "${descriptor_file}"); then
        local plugin_name="${plugin_data%%|*}"
        
        if [[ -z "${seen_plugins[${plugin_name}]+x}" ]]; then
          # Check for .disabled directory suffix (overrides descriptor active field)
          local plugin_dir_name
          plugin_dir_name=$(basename "$(dirname "${descriptor_file}")")
          if [[ "${plugin_dir_name}" == *.disabled ]]; then
            log "DEBUG" "PLUGIN" "Plugin directory has .disabled suffix: ${plugin_name}"
            local name_desc="${plugin_data%|*}"
            plugin_data="${name_desc}|false"
          fi
          
          # Apply activation overrides from CLI flags (CLI > Config > Descriptor/.disabled)
          if [[ -v PLUGIN_ACTIVATION_OVERRIDES["${plugin_name}"] ]]; then
            local override_value="${PLUGIN_ACTIVATION_OVERRIDES[${plugin_name}]}"
            log "DEBUG" "PLUGIN" "Applying CLI override for ${plugin_name}: active=${override_value}"
            # Replace the active field in plugin_data
            local name_desc="${plugin_data%|*}"
            plugin_data="${name_desc}|${override_value}"
          fi
          
          # Append descriptor path to plugin data
          plugin_list+=("${plugin_data}|${descriptor_file}")
          seen_plugins[${plugin_name}]=1
          log "DEBUG" "PLUGIN" "Added platform plugin: ${plugin_name}"
        fi
      fi
    done < <(find "${platform_dir}" -name "descriptor.json" -type f -print0 2>/dev/null)
  fi
  
  # Discover cross-platform plugins (lower priority)
  if [[ -d "${all_dir}" ]]; then
    log "DEBUG" "PLUGIN" "Searching cross-platform plugins in: ${all_dir}"
    
    while IFS= read -r -d '' descriptor_file; do
      log "DEBUG" "PLUGIN" "Found descriptor: ${descriptor_file}"
      
      local plugin_data
      if plugin_data=$(parse_plugin_descriptor "${descriptor_file}"); then
        local plugin_name="${plugin_data%%|*}"
        
        # Only add if not already seen (platform-specific takes precedence)
        if [[ -z "${seen_plugins[${plugin_name}]+x}" ]]; then
          # Check for .disabled directory suffix (overrides descriptor active field)
          local plugin_dir_name
          plugin_dir_name=$(basename "$(dirname "${descriptor_file}")")
          if [[ "${plugin_dir_name}" == *.disabled ]]; then
            log "DEBUG" "PLUGIN" "Plugin directory has .disabled suffix: ${plugin_name}"
            local name_desc="${plugin_data%|*}"
            plugin_data="${name_desc}|false"
          fi
          
          # Apply activation overrides from CLI flags (CLI > Config > Descriptor/.disabled)
          if [[ -v PLUGIN_ACTIVATION_OVERRIDES["${plugin_name}"] ]]; then
            local override_value="${PLUGIN_ACTIVATION_OVERRIDES[${plugin_name}]}"
            log "DEBUG" "PLUGIN" "Applying CLI override for ${plugin_name}: active=${override_value}"
            # Replace the active field in plugin_data
            local name_desc="${plugin_data%|*}"
            plugin_data="${name_desc}|${override_value}"
          fi
          
          # Append descriptor path to plugin data
          plugin_list+=("${plugin_data}|${descriptor_file}")
          seen_plugins[${plugin_name}]=1
          log "DEBUG" "PLUGIN" "Added cross-platform plugin: ${plugin_name}"
        else
          log "DEBUG" "PLUGIN" "Skipped duplicate plugin (platform version exists): ${plugin_name}"
        fi
      fi
    done < <(find "${all_dir}" -name "descriptor.json" -type f -print0 2>/dev/null)
  fi
  
  # Return plugin list
  if [[ ${#plugin_list[@]} -eq 0 ]]; then
    log "DEBUG" "PLUGIN" "No valid plugins found"
    return 0
  fi
  
  printf "%s\n" "${plugin_list[@]}"
}

# Validate a plugin (future use)
# Arguments:
#   $1 - Plugin data (name|description|active)
# Returns:
#   0 if valid, 1 if invalid
validate_plugin() {
  local plugin_data="$1"
  # Placeholder for validation logic
  [[ -n "${plugin_data}" ]]
}

# Filter active plugins (future use)
# Arguments:
#   $@ - Array of plugin data strings
# Returns:
#   Active plugins only
filter_active_plugins() {
  local -a plugins=("$@")
  local -a active_plugins=()
  
  for plugin_data in "${plugins[@]}"; do
    local active="${plugin_data##*|}"
    if [[ "${active}" == "true" ]]; then
      active_plugins+=("${plugin_data}")
    fi
  done
  
  printf "%s\n" "${active_plugins[@]}"
}
