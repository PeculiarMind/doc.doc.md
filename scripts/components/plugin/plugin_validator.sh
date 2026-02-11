#!/usr/bin/env bash
# Component: plugin_validator.sh
# Purpose: Plugin descriptor validation and security checks
# Dependencies: core/logging.sh, core/constants.sh
# Exports: validate_plugin_descriptor(), validate_command_template_safety(), validate_variable_substitution(), validate_data_objects(), validate_sandbox_compatibility(), validate_processes_field(), detect_circular_dependencies()
# Side Effects: Reads filesystem

# ==============================================================================
# Plugin Validation Functions
# ==============================================================================

# Main validation function for plugin descriptors
# Arguments:
#   $1 - Path to descriptor.json file
# Returns:
#   0 if valid, 1 if invalid
validate_plugin_descriptor() {
  local descriptor_file="$1"
  local validation_failed=0

  # Check file exists and is readable
  if [[ ! -f "${descriptor_file}" ]]; then
    log "ERROR" "VALIDATOR" "Descriptor file not found: ${descriptor_file}"
    return 1
  fi

  if [[ ! -r "${descriptor_file}" ]]; then
    log "ERROR" "VALIDATOR" "Descriptor file not readable: ${descriptor_file}"
    return 1
  fi

  # Check for path traversal
  if [[ "${descriptor_file}" == *".."* ]]; then
    log "ERROR" "VALIDATOR" "Path traversal detected in descriptor path: ${descriptor_file}"
    return 1
  fi

  # Validate JSON syntax
  if ! jq empty "${descriptor_file}" 2>/dev/null; then
    log "ERROR" "VALIDATOR" "Invalid JSON syntax in: ${descriptor_file}"
    return 1
  fi

  # Validate required fields exist
  local required_fields=("name" "description" "active" "commandline" "check_commandline" "install_commandline")
  for field in "${required_fields[@]}"; do
    local value
    value=$(jq -r ".${field} // empty" "${descriptor_file}" 2>/dev/null)
    if [[ -z "${value}" ]]; then
      log "ERROR" "VALIDATOR" "Missing required field '${field}' in: ${descriptor_file}"
      validation_failed=1
    fi
  done

  if [[ ${validation_failed} -ne 0 ]]; then
    return 1
  fi

  # Validate name field format
  local name
  name=$(jq -r '.name' "${descriptor_file}" 2>/dev/null)
  if [[ ! "${name}" =~ ^[a-zA-Z0-9_-]{3,50}$ ]]; then
    log "ERROR" "VALIDATOR" "Invalid plugin name '${name}': must be 3-50 alphanumeric/underscore/hyphen characters"
    validation_failed=1
  fi

  # Validate description
  local description
  description=$(jq -r '.description' "${descriptor_file}" 2>/dev/null)
  if [[ -z "${description}" ]]; then
    log "ERROR" "VALIDATOR" "Description must not be empty in: ${descriptor_file}"
    validation_failed=1
  elif [[ ${#description} -gt 500 ]]; then
    log "ERROR" "VALIDATOR" "Description exceeds 500 characters in: ${descriptor_file}"
    validation_failed=1
  fi

  # Validate active is boolean
  local active
  active=$(jq -r '.active' "${descriptor_file}" 2>/dev/null)
  if [[ "${active}" != "true" ]] && [[ "${active}" != "false" ]]; then
    log "ERROR" "VALIDATOR" "Field 'active' must be boolean true/false in: ${descriptor_file}"
    validation_failed=1
  fi

  # Validate command template safety
  local commandline check_commandline install_commandline
  commandline=$(jq -r '.commandline' "${descriptor_file}" 2>/dev/null)
  check_commandline=$(jq -r '.check_commandline' "${descriptor_file}" 2>/dev/null)
  install_commandline=$(jq -r '.install_commandline' "${descriptor_file}" 2>/dev/null)

  if ! validate_command_template_safety "${commandline}" "commandline"; then
    validation_failed=1
  fi
  if ! validate_command_template_safety "${check_commandline}" "check_commandline"; then
    validation_failed=1
  fi
  if ! validate_command_template_safety "${install_commandline}" "install_commandline"; then
    validation_failed=1
  fi

  # Validate variable substitution
  if ! validate_variable_substitution "${commandline}" "${descriptor_file}"; then
    validation_failed=1
  fi

  # Validate consumes/provides data objects
  if jq -e '.consumes' "${descriptor_file}" >/dev/null 2>&1; then
    if ! validate_data_objects "${descriptor_file}" "consumes"; then
      validation_failed=1
    fi
  fi
  if jq -e '.provides' "${descriptor_file}" >/dev/null 2>&1; then
    if ! validate_data_objects "${descriptor_file}" "provides"; then
      validation_failed=1
    fi
  fi

  # Validate processes field
  if ! validate_processes_field "${descriptor_file}"; then
    validation_failed=1
  fi

  # Validate sandbox compatibility
  if ! validate_sandbox_compatibility "${commandline}"; then
    validation_failed=1
  fi

  # Warn if directory name doesn't match descriptor name
  local dir_name
  dir_name=$(basename "$(dirname "${descriptor_file}")")
  if [[ "${dir_name}" != "${name}" ]]; then
    log "WARN" "VALIDATOR" "Plugin directory '${dir_name}' does not match descriptor name '${name}'"
  fi

  if [[ ${validation_failed} -ne 0 ]]; then
    log "ERROR" "VALIDATOR" "Validation failed for: ${descriptor_file}"
    return 1
  fi

  log "INFO" "VALIDATOR" "Validation passed for plugin: ${name}"
  return 0
}

# Check command template for injection patterns
# Arguments:
#   $1 - Command string to check
#   $2 - Field name (commandline, check_commandline, install_commandline)
# Returns:
#   0 if safe, 1 if unsafe
validate_command_template_safety() {
  local command="$1"
  local field_name="$2"

  # Check for dangerous injection patterns
  if [[ "${command}" == *";"* ]]; then
    log "ERROR" "VALIDATOR" "Injection pattern detected in '${field_name}': semicolon"
    return 1
  fi

  if [[ "${command}" == *'&&'* ]]; then
    log "ERROR" "VALIDATOR" "Injection pattern detected in '${field_name}': &&"
    return 1
  fi

  if [[ "${command}" == *'||'* ]]; then
    log "ERROR" "VALIDATOR" "Injection pattern detected in '${field_name}': ||"
    return 1
  fi

  if [[ "${command}" == *'$('* ]]; then
    log "ERROR" "VALIDATOR" "Injection pattern detected in '${field_name}': command substitution"
    return 1
  fi

  if [[ "${command}" == *'`'* ]]; then
    log "ERROR" "VALIDATOR" "Injection pattern detected in '${field_name}': backtick"
    return 1
  fi

  if [[ "${command}" =~ eval[[:space:]] ]]; then
    log "ERROR" "VALIDATOR" "Injection pattern detected in '${field_name}': eval"
    return 1
  fi

  if [[ "${command}" =~ bash[[:space:]]+-c ]]; then
    log "ERROR" "VALIDATOR" "Injection pattern detected in '${field_name}': bash -c"
    return 1
  fi

  if [[ "${command}" =~ sh[[:space:]]+-c ]]; then
    log "ERROR" "VALIDATOR" "Injection pattern detected in '${field_name}': sh -c"
    return 1
  fi

  # For install_commandline: must use recognized package manager
  if [[ "${field_name}" == "install_commandline" ]]; then
    if [[ ! "${command}" =~ (apt|yum|dnf|pacman|brew|true|:) ]]; then
      log "ERROR" "VALIDATOR" "install_commandline must use a recognized package manager"
      return 1
    fi
  fi

  # Check for unauthorized environment variable references (except in check_commandline)
  if [[ "${field_name}" != "check_commandline" ]]; then
    local cleaned="${command}"
    # Remove ${var} patterns (those are plugin variable substitutions)
    cleaned=$(echo "${cleaned}" | sed 's/\${[a-zA-Z_][a-zA-Z0-9_]*}//g')
    # Check for remaining $VAR patterns
    if [[ "${cleaned}" =~ \$[A-Z_][A-Z0-9_]* ]]; then
      log "ERROR" "VALIDATOR" "Unauthorized environment variable reference in '${field_name}'"
      return 1
    fi
  fi

  return 0
}

# Validate ${var} references against consumes declarations
# Arguments:
#   $1 - Command string
#   $2 - Descriptor file path
# Returns:
#   0 if valid, 1 if invalid
validate_variable_substitution() {
  local command="$1"
  local descriptor_file="$2"
  local validation_failed=0

  # Extract all ${variable_name} patterns
  local variables
  variables=$(echo "${command}" | grep -oP '\$\{\K[a-zA-Z_][a-zA-Z0-9_]*(?=\})' 2>/dev/null || true)

  if [[ -z "${variables}" ]]; then
    return 0
  fi

  while IFS= read -r var; do
    # Check if variable is declared in consumes
    local declared
    declared=$(jq -r ".consumes.${var} // empty" "${descriptor_file}" 2>/dev/null)
    if [[ -z "${declared}" ]]; then
      log "ERROR" "VALIDATOR" "Variable '\${${var}}' not declared in consumes"
      validation_failed=1
    fi
  done <<< "${variables}"

  return ${validation_failed}
}

# Validate consumes/provides data object fields
# Arguments:
#   $1 - Descriptor file path
#   $2 - Field type ("consumes" or "provides")
# Returns:
#   0 if valid, 1 if invalid
validate_data_objects() {
  local descriptor_file="$1"
  local field_type="$2"
  local validation_failed=0

  # Get field names
  local field_names
  field_names=$(jq -r ".${field_type} | keys[]" "${descriptor_file}" 2>/dev/null || true)

  if [[ -z "${field_names}" ]]; then
    return 0
  fi

  while IFS= read -r field_name; do
    # Validate field name format
    if [[ ! "${field_name}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
      log "ERROR" "VALIDATOR" "Invalid ${field_type} field name: '${field_name}'"
      validation_failed=1
      continue
    fi

    # Validate type sub-field exists
    local type_value
    type_value=$(jq -r ".${field_type}.\"${field_name}\".type // empty" "${descriptor_file}" 2>/dev/null)
    if [[ -z "${type_value}" ]]; then
      log "ERROR" "VALIDATOR" "Missing 'type' in ${field_type}.${field_name}"
      validation_failed=1
    elif [[ "${type_value}" != "string" ]] && [[ "${type_value}" != "integer" ]] && [[ "${type_value}" != "boolean" ]]; then
      log "ERROR" "VALIDATOR" "Invalid type '${type_value}' in ${field_type}.${field_name}: must be string, integer, or boolean"
      validation_failed=1
    fi

    # Validate description sub-field exists
    local desc_value
    desc_value=$(jq -r ".${field_type}.\"${field_name}\".description // empty" "${descriptor_file}" 2>/dev/null)
    if [[ -z "${desc_value}" ]]; then
      log "ERROR" "VALIDATOR" "Missing 'description' in ${field_type}.${field_name}"
      validation_failed=1
    fi
  done <<< "${field_names}"

  return ${validation_failed}
}

# Check command for sandbox-incompatible operations
# Arguments:
#   $1 - Command string
# Returns:
#   0 if compatible, 1 if not
validate_sandbox_compatibility() {
  local command="$1"
  local validation_failed=0

  # Check for restricted paths/operations
  if [[ "${command}" == *"/proc/"* ]]; then
    log "ERROR" "VALIDATOR" "Sandbox violation: /proc/ access not allowed"
    validation_failed=1
  fi

  if [[ "${command}" == *"/sys/"* ]]; then
    log "ERROR" "VALIDATOR" "Sandbox violation: /sys/ access not allowed"
    validation_failed=1
  fi

  if [[ "${command}" =~ (^|[[:space:]])mount([[:space:]]|$) ]]; then
    log "ERROR" "VALIDATOR" "Sandbox violation: mount not allowed"
    validation_failed=1
  fi

  if [[ "${command}" =~ (^|[[:space:]])chroot([[:space:]]|$) ]]; then
    log "ERROR" "VALIDATOR" "Sandbox violation: chroot not allowed"
    validation_failed=1
  fi

  if [[ "${command}" =~ (^|[[:space:]])sudo([[:space:]]|$) ]]; then
    log "ERROR" "VALIDATOR" "Sandbox violation: sudo not allowed"
    validation_failed=1
  fi

  # Warn about network tools
  local network_tools=("curl" "wget" "nc" "telnet" "ssh" "ftp")
  for tool in "${network_tools[@]}"; do
    if [[ "${command}" =~ (^|[[:space:]])${tool}([[:space:]]|$) ]]; then
      log "WARN" "VALIDATOR" "Network tool detected: ${tool} - may not work in sandbox"
    fi
  done

  return ${validation_failed}
}

# Validate processes field (MIME types and file extensions)
# Arguments:
#   $1 - Descriptor file path
# Returns:
#   0 if valid, 1 if invalid
validate_processes_field() {
  local descriptor_file="$1"
  local validation_failed=0

  # processes is optional
  if ! jq -e '.processes' "${descriptor_file}" >/dev/null 2>&1; then
    return 0
  fi

  # Validate MIME types
  local mime_types
  mime_types=$(jq -r '.processes.mime_types[]? // empty' "${descriptor_file}" 2>/dev/null || true)

  if [[ -n "${mime_types}" ]]; then
    while IFS= read -r mime; do
      if [[ "${mime}" != "*/*" ]] && [[ ! "${mime}" =~ ^[a-z]+/[a-z0-9+.*-]+$ ]]; then
        log "ERROR" "VALIDATOR" "Invalid MIME type: '${mime}'"
        validation_failed=1
      fi
    done <<< "${mime_types}"
  fi

  # Validate file extensions
  local extensions
  extensions=$(jq -r '.processes.file_extensions[]? // empty' "${descriptor_file}" 2>/dev/null || true)

  if [[ -n "${extensions}" ]]; then
    while IFS= read -r ext; do
      if [[ "${ext}" != "*" ]] && [[ "${ext}" != .* ]]; then
        log "ERROR" "VALIDATOR" "Invalid file extension '${ext}': must start with . or be *"
        validation_failed=1
      fi
    done <<< "${extensions}"
  fi

  return ${validation_failed}
}

# Detect circular dependencies among plugins
# Arguments:
#   $1 - Plugins directory path
# Returns:
#   0 if no cycles, 1 if cycles found
detect_circular_dependencies() {
  local plugins_dir="$1"

  if [[ ! -d "${plugins_dir}" ]]; then
    log "ERROR" "VALIDATOR" "Plugins directory not found: ${plugins_dir}"
    return 1
  fi

  # Build dependency graph: map plugin name -> consumes fields
  # and map provides fields -> plugin name
  declare -A provides_map
  declare -A plugin_deps
  declare -A in_degree
  local all_plugins=()

  while IFS= read -r -d '' descriptor_file; do
    local plugin_name
    plugin_name=$(jq -r '.name // empty' "${descriptor_file}" 2>/dev/null)
    if [[ -z "${plugin_name}" ]]; then
      continue
    fi

    all_plugins+=("${plugin_name}")
    in_degree["${plugin_name}"]=0
    plugin_deps["${plugin_name}"]=""

    # Register provides
    local provides_fields
    provides_fields=$(jq -r '.provides | keys[]? // empty' "${descriptor_file}" 2>/dev/null || true)
    if [[ -n "${provides_fields}" ]]; then
      while IFS= read -r field; do
        provides_map["${field}"]="${plugin_name}"
      done <<< "${provides_fields}"
    fi
  done < <(find "${plugins_dir}" -name "descriptor.json" -type f -print0 2>/dev/null)

  # Build edges: for each plugin, check what it consumes and find who provides it
  for plugin_name in "${all_plugins[@]}"; do
    local descriptor_file
    descriptor_file=$(find "${plugins_dir}" -path "*/${plugin_name}/descriptor.json" -type f 2>/dev/null | head -1)
    if [[ -z "${descriptor_file}" ]]; then
      continue
    fi

    local consumes_fields
    consumes_fields=$(jq -r '.consumes | keys[]? // empty' "${descriptor_file}" 2>/dev/null || true)
    if [[ -n "${consumes_fields}" ]]; then
      while IFS= read -r field; do
        local provider="${provides_map[${field}]:-}"
        if [[ -n "${provider}" ]] && [[ "${provider}" != "${plugin_name}" ]]; then
          plugin_deps["${plugin_name}"]="${plugin_deps[${plugin_name}]} ${provider}"
          in_degree["${plugin_name}"]=$(( ${in_degree["${plugin_name}"]} + 1 ))
        fi
      done <<< "${consumes_fields}"
    fi
  done

  # Kahn's algorithm for topological sort / cycle detection
  local queue=()
  for plugin_name in "${all_plugins[@]}"; do
    if [[ ${in_degree["${plugin_name}"]} -eq 0 ]]; then
      queue+=("${plugin_name}")
    fi
  done

  local processed=0
  while [[ ${#queue[@]} -gt 0 ]]; do
    local current="${queue[0]}"
    queue=("${queue[@]:1}")
    processed=$((processed + 1))

    # For each plugin that depends on current (current provides something they need)
    for other_plugin in "${all_plugins[@]}"; do
      local deps="${plugin_deps[${other_plugin}]:-}"
      if [[ " ${deps} " == *" ${current} "* ]]; then
        in_degree["${other_plugin}"]=$(( ${in_degree["${other_plugin}"]} - 1 ))
        if [[ ${in_degree["${other_plugin}"]} -eq 0 ]]; then
          queue+=("${other_plugin}")
        fi
      fi
    done
  done

  if [[ ${processed} -lt ${#all_plugins[@]} ]]; then
    # Report cycle participants
    for plugin_name in "${all_plugins[@]}"; do
      if [[ ${in_degree["${plugin_name}"]} -gt 0 ]]; then
        log "ERROR" "VALIDATOR" "Circular dependency detected involving plugin: ${plugin_name}"
      fi
    done
    return 1
  fi

  log "DEBUG" "VALIDATOR" "No circular dependencies detected"
  return 0
}
