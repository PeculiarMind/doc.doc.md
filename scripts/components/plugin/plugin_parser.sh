#!/usr/bin/env bash
# Component: plugin_parser.sh
# Purpose: Plugin descriptor JSON parsing and file type filtering
# Dependencies: core/logging.sh
# Exports: parse_plugin_descriptor(), extract_plugin_field(), detect_mime_type(), get_plugin_processes_mime_types(), get_plugin_processes_extensions(), is_plugin_applicable_for_file()
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
    log "WARN" "PLUGIN" "Descriptor file not found: ${descriptor_path}"
    return 1
  fi
  
  if [[ ! -r "${descriptor_path}" ]]; then
    log "WARN" "PLUGIN" "Cannot read descriptor file: ${descriptor_path}"
    return 1
  fi
  
  log "DEBUG" "PLUGIN" "Parsing descriptor: ${descriptor_path}"
  
  # Use jq to parse JSON (preferred method)
  if command -v jq >/dev/null 2>&1; then
    local name description active
    
    # Extract fields using jq
    name=$(jq -r '.name // empty' "${descriptor_path}" 2>/dev/null)
    description=$(jq -r '.description // empty' "${descriptor_path}" 2>/dev/null)
    active=$(jq -r 'if has("active") then .active else true end' "${descriptor_path}" 2>/dev/null)
    
    # Validate required fields
    if [[ -z "${name}" ]]; then
      log "WARN" "PLUGIN" "Plugin descriptor missing 'name' field: ${descriptor_path}"
      return 1
    fi
    
    if [[ -z "${description}" ]]; then
      log "WARN" "PLUGIN" "Plugin descriptor missing 'description' field: ${descriptor_path}"
      return 1
    fi
    
    # Ensure active is a boolean (default to true if missing/invalid)
    if [[ "${active}" != "true" ]] && [[ "${active}" != "false" ]]; then
      log "DEBUG" "PLUGIN" "Invalid 'active' value, defaulting to true: ${descriptor_path}"
      active="true"
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
    active = str(data.get('active', True)).lower()
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
        log "WARN" "PLUGIN" "Failed to parse descriptor with python: ${descriptor_path}"
        return 1
      fi
    else
      log "ERROR" "PLUGIN" "No JSON parser available (jq or python3 required)"
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
  
  if [[ ! -f "${descriptor_path}" ]]; then
    return 1
  fi
  
  # Use jq if available
  if command -v jq >/dev/null 2>&1; then
    jq -r ".${field_name} // empty" "${descriptor_path}" 2>/dev/null
    return $?
  fi
  
  # Fallback to python
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json
import sys
try:
    with open('${descriptor_path}', 'r') as f:
        data = json.load(f)
    value = data.get('${field_name}', '')
    if value:
        print(value)
except:
    pass
" 2>/dev/null
    return $?
  fi
  
  return 1
}

# Get list of fields a plugin consumes (inputs)
# Arguments:
#   $1 - Path to descriptor.json file
# Returns:
#   Comma-separated list of input field names
get_plugin_consumes() {
  local descriptor_path="$1"
  
  if [[ ! -f "${descriptor_path}" ]]; then
    return 1
  fi
  
  # Use jq if available
  if command -v jq >/dev/null 2>&1; then
    jq -r '.consumes | keys | join(", ")' "${descriptor_path}" 2>/dev/null
    return $?
  fi
  
  # Fallback to python
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json
import sys
try:
    with open('${descriptor_path}', 'r') as f:
        data = json.load(f)
    consumes = data.get('consumes', {})
    if consumes:
        print(', '.join(consumes.keys()))
except:
    pass
" 2>/dev/null
    return $?
  fi
  
  return 1
}

# Get list of fields a plugin provides (outputs)
# Arguments:
#   $1 - Path to descriptor.json file
# Returns:
#   Comma-separated list of output field names
get_plugin_provides() {
  local descriptor_path="$1"
  
  if [[ ! -f "${descriptor_path}" ]]; then
    return 1
  fi
  
  # Use jq if available
  if command -v jq >/dev/null 2>&1; then
    jq -r '.provides | keys | join(", ")' "${descriptor_path}" 2>/dev/null
    return $?
  fi
  
  # Fallback to python
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json
import sys
try:
    with open('${descriptor_path}', 'r') as f:
        data = json.load(f)
    provides = data.get('provides', {})
    if provides:
        print(', '.join(provides.keys()))
except:
    pass
" 2>/dev/null
    return $?
  fi
  
  return 1
}

# ==============================================================================
# File Type Filtering Functions (Feature 0044)
# ==============================================================================

# Detect file MIME type using the `file` command
# Arguments:
#   $1 - Path to file
# Returns:
#   MIME type string on stdout (e.g., "text/plain", "application/pdf")
#   Returns "application/octet-stream" as fallback if detection fails
detect_mime_type() {
  local file_path="$1"
  
  # Check if file exists
  if [[ ! -f "${file_path}" ]]; then
    log "WARN" "PLUGIN" "Cannot detect MIME type: file not found: ${file_path}"
    echo "application/octet-stream"
    return 1
  fi
  
  # Check if file command is available
  if ! command -v file >/dev/null 2>&1; then
    log "WARN" "PLUGIN" "file command not available, using fallback MIME type"
    echo "application/octet-stream"
    return 0
  fi
  
  # Detect MIME type using file command
  local mime_type
  mime_type=$(file --brief --mime-type "${file_path}" 2>/dev/null)
  
  if [[ $? -eq 0 ]] && [[ -n "${mime_type}" ]]; then
    log "DEBUG" "PLUGIN" "Detected MIME type for ${file_path}: ${mime_type}"
    echo "${mime_type}"
    return 0
  else
    log "DEBUG" "PLUGIN" "Failed to detect MIME type for ${file_path}, using fallback"
    echo "application/octet-stream"
    return 0
  fi
}

# Extract MIME types array from plugin descriptor processes field
# Arguments:
#   $1 - Path to descriptor.json file
# Returns:
#   One MIME type per line on stdout
#   Returns empty if processes.mime_types is not defined or empty
get_plugin_processes_mime_types() {
  local descriptor_path="$1"
  
  if [[ ! -f "${descriptor_path}" ]]; then
    log "WARN" "PLUGIN" "Descriptor not found: ${descriptor_path}"
    return 1
  fi
  
  # Use jq if available
  if command -v jq >/dev/null 2>&1; then
    jq -r '.processes.mime_types[]? // empty' "${descriptor_path}" 2>/dev/null
    return 0
  fi
  
  # Fallback to python
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json
import sys
try:
    with open('${descriptor_path}', 'r') as f:
        data = json.load(f)
    mime_types = data.get('processes', {}).get('mime_types', [])
    for mime_type in mime_types:
        print(mime_type)
except:
    pass
" 2>/dev/null
    return 0
  fi
  
  return 1
}

# Extract file extensions array from plugin descriptor processes field
# Arguments:
#   $1 - Path to descriptor.json file
# Returns:
#   One extension per line on stdout (with leading dot, e.g., ".pdf")
#   Returns empty if processes.file_extensions is not defined or empty
get_plugin_processes_extensions() {
  local descriptor_path="$1"
  
  if [[ ! -f "${descriptor_path}" ]]; then
    log "WARN" "PLUGIN" "Descriptor not found: ${descriptor_path}"
    return 1
  fi
  
  # Use jq if available
  if command -v jq >/dev/null 2>&1; then
    jq -r '.processes.file_extensions[]? // empty' "${descriptor_path}" 2>/dev/null
    return 0
  fi
  
  # Fallback to python
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json
import sys
try:
    with open('${descriptor_path}', 'r') as f:
        data = json.load(f)
    extensions = data.get('processes', {}).get('file_extensions', [])
    for ext in extensions:
        print(ext)
except:
    pass
" 2>/dev/null
    return 0
  fi
  
  return 1
}

# Determine if a plugin is applicable for a given file
# Arguments:
#   $1 - Path to descriptor.json file
#   $2 - Path to file being processed
#   $3 - MIME type of the file (optional, will be detected if not provided)
# Returns:
#   0 if plugin should process the file
#   1 if plugin should skip the file
is_plugin_applicable_for_file() {
  local descriptor_path="$1"
  local file_path="$2"
  local file_mime_type="${3:-}"
  
  # Detect MIME type if not provided
  if [[ -z "${file_mime_type}" ]]; then
    file_mime_type=$(detect_mime_type "${file_path}")
  fi
  
  # Get file extension (case-insensitive)
  local file_extension="${file_path##*.}"
  if [[ "${file_extension}" == "${file_path}" ]]; then
    file_extension=""
  else
    file_extension=".${file_extension}"
  fi
  
  # Check if descriptor exists
  if [[ ! -f "${descriptor_path}" ]]; then
    log "WARN" "PLUGIN" "Descriptor not found for filtering: ${descriptor_path}"
    return 1
  fi
  
  # Check if processes object exists
  local has_processes=false
  if command -v jq >/dev/null 2>&1; then
    has_processes=$(jq -r 'has("processes")' "${descriptor_path}" 2>/dev/null)
  elif command -v python3 >/dev/null 2>&1; then
    has_processes=$(python3 -c "
import json
try:
    with open('${descriptor_path}', 'r') as f:
        data = json.load(f)
    print('true' if 'processes' in data else 'false')
except:
    print('false')
" 2>/dev/null)
  fi
  
  # If no processes object, plugin handles all files
  if [[ "${has_processes}" != "true" ]]; then
    log "DEBUG" "PLUGIN" "No processes filter, plugin applicable for all files"
    return 0
  fi
  
  # Get MIME types and extensions from descriptor
  local mime_types
  local extensions
  mime_types=$(get_plugin_processes_mime_types "${descriptor_path}")
  extensions=$(get_plugin_processes_extensions "${descriptor_path}")
  
  # If both arrays are empty, plugin handles all files
  if [[ -z "${mime_types}" ]] && [[ -z "${extensions}" ]]; then
    log "DEBUG" "PLUGIN" "Empty processes arrays, plugin applicable for all files"
    return 0
  fi
  
  # Check MIME type match
  if [[ -n "${mime_types}" ]]; then
    while IFS= read -r plugin_mime_type; do
      # Check for wildcard MIME type
      if [[ "${plugin_mime_type}" == "*/*" ]]; then
        log "DEBUG" "PLUGIN" "Wildcard MIME type match: ${plugin_mime_type}"
        return 0
      fi
      
      if [[ "${file_mime_type}" == "${plugin_mime_type}" ]]; then
        log "DEBUG" "PLUGIN" "MIME type match: ${file_mime_type} matches ${plugin_mime_type}"
        return 0
      fi
    done <<< "${mime_types}"
  fi
  
  # Check extension match (case-insensitive)
  if [[ -n "${extensions}" ]] && [[ -n "${file_extension}" ]]; then
    while IFS= read -r plugin_extension; do
      # Check for wildcard extension
      if [[ "${plugin_extension}" == "*" ]]; then
        log "DEBUG" "PLUGIN" "Wildcard extension match: ${plugin_extension}"
        return 0
      fi
      
      # Convert both to lowercase for case-insensitive comparison
      local plugin_ext_lower=$(echo "${plugin_extension}" | tr '[:upper:]' '[:lower:]')
      local file_ext_lower=$(echo "${file_extension}" | tr '[:upper:]' '[:lower:]')
      
      if [[ "${file_ext_lower}" == "${plugin_ext_lower}" ]]; then
        log "DEBUG" "PLUGIN" "Extension match: ${file_extension} matches ${plugin_extension}"
        return 0
      fi
    done <<< "${extensions}"
  fi
  
  # No match found
  log "DEBUG" "PLUGIN" "Plugin not applicable: MIME=${file_mime_type}, Extension=${file_extension}"
  return 1
}
