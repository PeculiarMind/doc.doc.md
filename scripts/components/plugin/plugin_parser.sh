#!/usr/bin/env bash
# Component: plugin_parser.sh
# Purpose: Plugin descriptor JSON parsing
# Dependencies: core/logging.sh
# Exports: parse_plugin_descriptor(), extract_plugin_field()
# Side Effects: None (pure parsing)

# ==============================================================================
# Plugin Parsing Functions
# ==============================================================================

# Parse plugin descriptor.json file and extract metadata
# Arguments:
#   $1 - Path to descriptor.json file
# Returns:
#   Echoes a pipe-delimited string: "name|description|active"
#   Returns empty string on error
parse_plugin_descriptor() {
  local descriptor_path="$1"
  
  if [[ ! -f "${descriptor_path}" ]]; then
    log "WARN" "Descriptor file not found: ${descriptor_path}"
    return 1
  fi
  
  if [[ ! -r "${descriptor_path}" ]]; then
    log "WARN" "Cannot read descriptor file: ${descriptor_path}"
    return 1
  fi
  
  log "DEBUG" "Parsing descriptor: ${descriptor_path}"
  
  # Use jq to parse JSON (preferred method)
  if command -v jq >/dev/null 2>&1; then
    local name description active
    
    # Extract fields using jq
    name=$(jq -r '.name // empty' "${descriptor_path}" 2>/dev/null)
    description=$(jq -r '.description // empty' "${descriptor_path}" 2>/dev/null)
    active=$(jq -r '.active // false' "${descriptor_path}" 2>/dev/null)
    
    # Validate required fields
    if [[ -z "${name}" ]]; then
      log "WARN" "Plugin descriptor missing 'name' field: ${descriptor_path}"
      return 1
    fi
    
    if [[ -z "${description}" ]]; then
      log "WARN" "Plugin descriptor missing 'description' field: ${descriptor_path}"
      return 1
    fi
    
    # Ensure active is a boolean
    if [[ "${active}" != "true" ]] && [[ "${active}" != "false" ]]; then
      log "DEBUG" "Invalid 'active' value, defaulting to false: ${descriptor_path}"
      active="false"
    fi
    
    echo "${name}|${description}|${active}"
    return 0
  else
    # Fallback to python if jq not available
    if command -v python3 >/dev/null 2>&1; then
      local result
      result=$(python3 -c "
import json
import sys
try:
    with open('${descriptor_path}', 'r') as f:
        data = json.load(f)
    name = data.get('name', '')
    description = data.get('description', '')
    active = str(data.get('active', False)).lower()
    if not name or not description:
        sys.exit(1)
    print(f'{name}|{description}|{active}')
except Exception as e:
    sys.exit(1)
" 2>&1)
      
      if [[ $? -eq 0 ]] && [[ -n "${result}" ]]; then
        echo "${result}"
        return 0
      else
        log "WARN" "Failed to parse descriptor with python: ${descriptor_path}"
        return 1
      fi
    else
      log "ERROR" "No JSON parser available (jq or python3 required)"
      error_exit "Cannot parse plugin descriptors without jq or python3" "${EXIT_PLUGIN_ERROR}"
    fi
  fi
}

# Extract a specific field from plugin descriptor (future use)
# Arguments:
#   $1 - Path to descriptor.json file
#   $2 - Field name to extract
# Returns:
#   Field value on stdout
extract_plugin_field() {
  local descriptor_path="$1"
  local field_name="$2"
  
  if command -v jq >/dev/null 2>&1; then
    jq -r ".${field_name} // empty" "${descriptor_path}" 2>/dev/null
  else
    log "ERROR" "extract_plugin_field requires jq"
    return 1
  fi
}
