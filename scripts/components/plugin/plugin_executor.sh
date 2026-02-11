#!/usr/bin/env bash
# Component: plugin_executor.sh
# Purpose: Plugin execution orchestration with dependency graph and sandbox support
# Dependencies: plugin/plugin_discovery.sh, plugin/plugin_validator.sh, plugin/plugin_tool_checker.sh, orchestration/workspace.sh
# Exports: execute_plugin(), build_dependency_graph(), orchestrate_plugins(), execute_plugin_sandboxed(), substitute_variables_secure(), should_execute_plugin()
# Side Effects: Executes external commands, modifies workspace

# ==============================================================================
# Configuration
# ==============================================================================

readonly PLUGIN_EXEC_TIMEOUT="${PLUGIN_EXEC_TIMEOUT:-300}"
readonly PLUGIN_MAX_PLUGINS="${PLUGIN_MAX_PLUGINS:-100}"

# ==============================================================================
# Dependency Graph
# ==============================================================================

# Build plugin execution order using topological sort (Kahn's algorithm)
# Arguments:
#   $1 - Plugins directory path
# Returns:
#   Ordered plugin names on stdout (one per line)
#   0 on success, 1 on circular dependency or error
build_dependency_graph() {
  local plugins_dir="$1"

  log "DEBUG" "PLUGIN" "Building plugin dependency graph"

  if [[ -z "$plugins_dir" ]] || [[ ! -d "$plugins_dir" ]]; then
    log "ERROR" "PLUGIN" "Invalid plugins directory: ${plugins_dir:-empty}"
    return 1
  fi

  # Collect all descriptor files
  local descriptor_files=()
  while IFS= read -r -d '' dfile; do
    descriptor_files+=("$dfile")
  done < <(find "$plugins_dir" -name "descriptor.json" -type f -print0 2>/dev/null)

  # DoS protection: limit number of plugins
  if [[ ${#descriptor_files[@]} -gt $PLUGIN_MAX_PLUGINS ]]; then
    log "ERROR" "PLUGIN" "Too many plugins (${#descriptor_files[@]}), max is ${PLUGIN_MAX_PLUGINS}"
    return 1
  fi

  # Build maps
  declare -A provides_map
  declare -A plugin_descriptor
  local all_plugins=()

  for dfile in "${descriptor_files[@]}"; do
    local pname
    pname=$(jq -r '.name // empty' "$dfile" 2>/dev/null)
    [[ -z "$pname" ]] && continue

    # Validate plugin name
    if [[ ! "$pname" =~ ^[a-zA-Z0-9_-]+$ ]]; then
      log "WARN" "PLUGIN" "Skipping plugin with invalid name: ${pname}"
      continue
    fi

    local active
    active=$(jq -r '.active // false' "$dfile" 2>/dev/null)
    [[ "$active" != "true" ]] && continue

    all_plugins+=("$pname")
    plugin_descriptor["$pname"]="$dfile"

    # Register provides fields
    local provides_fields
    provides_fields=$(jq -r '.provides | keys[]? // empty' "$dfile" 2>/dev/null || true)
    if [[ -n "$provides_fields" ]]; then
      while IFS= read -r field; do
        if [[ "$field" =~ ^[a-zA-Z0-9_]+$ ]]; then
          provides_map["$field"]="$pname"
        else
          log "WARN" "PLUGIN" "Skipping invalid field name '${field}' in plugin ${pname}"
        fi
      done <<< "$provides_fields"
    fi
  done

  if [[ ${#all_plugins[@]} -eq 0 ]]; then
    log "DEBUG" "PLUGIN" "No active plugins found"
    return 0
  fi

  # Build in-degree map and adjacency
  declare -A in_degree
  declare -A dependents  # provider -> space-separated list of consumers

  for pname in "${all_plugins[@]}"; do
    in_degree["$pname"]=0
  done

  for pname in "${all_plugins[@]}"; do
    local dfile="${plugin_descriptor[$pname]}"
    local consumes_fields
    consumes_fields=$(jq -r '.consumes | keys[]? // empty' "$dfile" 2>/dev/null || true)
    if [[ -n "$consumes_fields" ]]; then
      while IFS= read -r field; do
        if [[ ! "$field" =~ ^[a-zA-Z0-9_]+$ ]]; then
          continue
        fi
        local provider="${provides_map[$field]:-}"
        if [[ -n "$provider" ]] && [[ "$provider" != "$pname" ]]; then
          in_degree["$pname"]=$(( ${in_degree[$pname]} + 1 ))
          dependents["$provider"]="${dependents[$provider]:-} $pname"
        fi
      done <<< "$consumes_fields"
    fi
  done

  # Kahn's algorithm
  local queue=()
  for pname in "${all_plugins[@]}"; do
    if [[ ${in_degree[$pname]} -eq 0 ]]; then
      queue+=("$pname")
    fi
  done

  local sorted=()
  while [[ ${#queue[@]} -gt 0 ]]; do
    local current="${queue[0]}"
    queue=("${queue[@]:1}")
    sorted+=("$current")

    local deps="${dependents[$current]:-}"
    if [[ -n "$deps" ]]; then
      for dep in $deps; do
        in_degree["$dep"]=$(( ${in_degree[$dep]} - 1 ))
        if [[ ${in_degree[$dep]} -eq 0 ]]; then
          queue+=("$dep")
        fi
      done
    fi
  done

  if [[ ${#sorted[@]} -lt ${#all_plugins[@]} ]]; then
    log "ERROR" "PLUGIN" "Circular dependency detected in plugin graph"
    return 1
  fi

  for pname in "${sorted[@]}"; do
    echo "$pname"
  done
  return 0
}

# ==============================================================================
# File Type Filtering
# ==============================================================================

# Check if a plugin should execute for a given file
# Arguments:
#   $1 - Plugin name
#   $2 - File path
#   $3 - Plugins directory
# Returns:
#   0 if plugin should execute, 1 if not
should_execute_plugin() {
  local plugin_name="$1"
  local file_path="$2"
  local plugins_dir="$3"

  if [[ -z "$plugin_name" ]] || [[ -z "$file_path" ]] || [[ -z "$plugins_dir" ]]; then
    log "ERROR" "PLUGIN" "should_execute_plugin requires plugin_name, file_path, and plugins_dir"
    return 1
  fi

  local descriptor_file
  descriptor_file=$(find "$plugins_dir" -path "*/${plugin_name}/descriptor.json" -type f 2>/dev/null | head -1)
  if [[ -z "$descriptor_file" ]]; then
    log "WARN" "PLUGIN" "Descriptor not found for plugin: ${plugin_name}"
    return 1
  fi

  # Check if processes field exists
  local has_processes
  has_processes=$(jq -r '.processes // empty' "$descriptor_file" 2>/dev/null)
  if [[ -z "$has_processes" ]]; then
    log "DEBUG" "PLUGIN" "Plugin ${plugin_name} has no processes filter, applies to all files"
    return 0
  fi

  # Check for wildcard MIME type
  local wildcard_mime
  wildcard_mime=$(jq -r '.processes.mime_types[]? // empty' "$descriptor_file" 2>/dev/null | grep -c '^\*\/\*$' || true)
  if [[ "$wildcard_mime" -gt 0 ]]; then
    return 0
  fi

  # Check for wildcard extension
  local wildcard_ext
  wildcard_ext=$(jq -r '.processes.file_extensions[]? // empty' "$descriptor_file" 2>/dev/null | grep -c '^\*$' || true)
  if [[ "$wildcard_ext" -gt 0 ]]; then
    return 0
  fi

  # Check file extension
  local file_ext
  file_ext=".${file_path##*.}"
  local extensions
  extensions=$(jq -r '.processes.file_extensions[]? // empty' "$descriptor_file" 2>/dev/null || true)
  if [[ -n "$extensions" ]]; then
    while IFS= read -r ext; do
      if [[ "$ext" == "$file_ext" ]]; then
        return 0
      fi
    done <<< "$extensions"
  fi

  # Check MIME type
  if [[ -f "$file_path" ]] && command -v file >/dev/null 2>&1; then
    local file_mime
    file_mime=$(file --mime-type -b "$file_path" 2>/dev/null || true)
    if [[ -n "$file_mime" ]]; then
      local mime_types
      mime_types=$(jq -r '.processes.mime_types[]? // empty' "$descriptor_file" 2>/dev/null || true)
      if [[ -n "$mime_types" ]]; then
        while IFS= read -r mime; do
          if [[ "$mime" == "$file_mime" ]]; then
            return 0
          fi
        done <<< "$mime_types"
      fi
    fi
  fi

  log "DEBUG" "PLUGIN" "Plugin ${plugin_name} does not apply to file: ${file_path}"
  return 1
}

# ==============================================================================
# Variable Substitution
# ==============================================================================

# Securely substitute variables in a command template
# Arguments:
#   $1 - Command template string
#   $2 - JSON object with variable values
# Returns:
#   Substituted command on stdout
#   0 on success, 1 on security validation failure
substitute_variables_secure() {
  local command_template="$1"
  local variable_json="$2"

  if [[ -z "$command_template" ]]; then
    log "ERROR" "PLUGIN" "Empty command template for variable substitution"
    return 1
  fi

  if [[ -z "$variable_json" ]]; then
    echo "$command_template"
    return 0
  fi

  local result="$command_template"

  # Get all keys from the variable JSON
  local keys
  keys=$(echo "$variable_json" | jq -r 'keys[]' 2>/dev/null || true)

  if [[ -n "$keys" ]]; then
    while IFS= read -r key; do
      local value
      value=$(echo "$variable_json" | jq -r --arg k "$key" '.[$k] // empty' 2>/dev/null)

      # Security: reject values with injection characters
      if [[ "$value" == *";"* ]] || [[ "$value" == *"|"* ]] || [[ "$value" == *"&"* ]] || [[ "$value" == *'`'* ]] || [[ "$value" == *'$'* ]]; then
        log "ERROR" "PLUGIN" "Injection characters detected in variable '${key}' value"
        return 1
      fi

      # Replace ${key} with quoted value using sed
      result=$(echo "$result" | sed "s|\${${key}}|${value}|g")
    done <<< "$keys"
  fi

  echo "$result"
  return 0
}

# ==============================================================================
# Sandboxed Execution
# ==============================================================================

# Execute a plugin command in a sandbox using bubblewrap
# Arguments:
#   $1 - Plugin name
#   $2 - Command to execute
#   $3 - Plugin directory
#   $4 - File path to process
# Returns:
#   Command output on stdout
#   0 on success, 1 on failure, 2 if bwrap not available
execute_plugin_sandboxed() {
  local plugin_name="$1"
  local command="$2"
  local plugin_dir="$3"
  local file_path="$4"

  # Check if bwrap is available
  if ! command -v bwrap >/dev/null 2>&1; then
    log "DEBUG" "PLUGIN" "bwrap not available for sandboxed execution"
    return 2
  fi

  log "DEBUG" "PLUGIN" "Executing plugin ${plugin_name} in sandbox"

  local temp_dir
  temp_dir=$(mktemp -d "/tmp/plugin_sandbox_${plugin_name}_XXXXXX")

  # Build bwrap arguments
  local bwrap_args=()

  # Read-only system binds
  for sys_dir in /usr /bin /lib /lib64; do
    if [[ -d "$sys_dir" ]]; then
      bwrap_args+=(--ro-bind "$sys_dir" "$sys_dir")
    fi
  done

  # Read-only bind for the input file
  if [[ -f "$file_path" ]]; then
    bwrap_args+=(--ro-bind "$file_path" "/input_file")
  fi

  # Read-only bind for plugin directory
  if [[ -d "$plugin_dir" ]]; then
    bwrap_args+=(--ro-bind "$plugin_dir" "/plugin")
  fi

  # Bind temp dir for output
  bwrap_args+=(--bind "$temp_dir" "/tmp")

  # Security flags
  bwrap_args+=(--unshare-net --unshare-pid --new-session --die-with-parent)

  # Provide /dev/null and basic proc
  bwrap_args+=(--dev /dev)

  local output
  local exit_code

  if command -v timeout >/dev/null 2>&1; then
    output=$(timeout "$PLUGIN_EXEC_TIMEOUT" bwrap "${bwrap_args[@]}" -- /bin/sh -c "$command" 2>/dev/null)
    exit_code=$?
  else
    output=$(bwrap "${bwrap_args[@]}" -- /bin/sh -c "$command" 2>/dev/null)
    exit_code=$?
  fi

  # Cleanup temp directory
  rm -rf "$temp_dir" 2>/dev/null

  if [[ $exit_code -ne 0 ]]; then
    log "ERROR" "PLUGIN" "Sandboxed execution of ${plugin_name} failed with exit code ${exit_code}"
    echo "$output"
    return 1
  fi

  echo "$output"
  return 0
}

# ==============================================================================
# Plugin Execution
# ==============================================================================

# Execute a single plugin
# Arguments:
#   $1 - Plugin name
#   $2 - Plugins directory
#   $3 - Variable JSON for substitution
# Returns:
#   Captured output on stdout
#   0 on success, 1 on failure
execute_plugin() {
  local plugin_name="$1"
  local plugins_dir="$2"
  local variable_json="${3:-{\}}"

  log "INFO" "PLUGIN" "Executing plugin: ${plugin_name}"

  # Validate plugin name
  if [[ ! "$plugin_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    log "ERROR" "PLUGIN" "Invalid plugin name: ${plugin_name}"
    return 1
  fi

  # Find descriptor
  local descriptor_file
  descriptor_file=$(find "$plugins_dir" -path "*/${plugin_name}/descriptor.json" -type f 2>/dev/null | head -1)
  if [[ -z "$descriptor_file" ]] || [[ ! -f "$descriptor_file" ]]; then
    log "ERROR" "PLUGIN" "Descriptor not found for plugin: ${plugin_name}"
    return 1
  fi

  # Validate descriptor if validator is available
  if declare -f validate_plugin_descriptor >/dev/null 2>&1; then
    if ! validate_plugin_descriptor "$descriptor_file" 2>/dev/null; then
      log "ERROR" "PLUGIN" "Descriptor validation failed for plugin: ${plugin_name}"
      return 1
    fi
  fi

  # Load command template
  local command_template
  command_template=$(jq -r '.commandline // empty' "$descriptor_file" 2>/dev/null)
  if [[ -z "$command_template" ]]; then
    log "ERROR" "PLUGIN" "No commandline defined for plugin: ${plugin_name}"
    return 1
  fi

  # Substitute variables
  local final_command
  final_command=$(substitute_variables_secure "$command_template" "$variable_json")
  if [[ $? -ne 0 ]]; then
    log "ERROR" "PLUGIN" "Variable substitution failed for plugin: ${plugin_name}"
    return 1
  fi

  local plugin_dir
  plugin_dir=$(dirname "$descriptor_file")

  # Determine file_path from variable_json for sandbox
  local file_path
  file_path=$(echo "$variable_json" | jq -r '.file_path_absolute // empty' 2>/dev/null)

  # Try sandboxed execution first
  local output
  local exec_code
  output=$(execute_plugin_sandboxed "$plugin_name" "$final_command" "$plugin_dir" "$file_path" 2>/dev/null)
  exec_code=$?

  if [[ $exec_code -eq 2 ]]; then
    # bwrap not available, fall back to contained execution
    log "WARN" "PLUGIN" "Sandbox not available, executing ${plugin_name} without sandbox"
    if command -v timeout >/dev/null 2>&1; then
      output=$(timeout "$PLUGIN_EXEC_TIMEOUT" /bin/sh -c "$final_command" 2>/dev/null)
      exec_code=$?
    else
      output=$(/bin/sh -c "$final_command" 2>/dev/null)
      exec_code=$?
    fi
  fi

  if [[ $exec_code -ne 0 ]]; then
    log "ERROR" "PLUGIN" "Plugin ${plugin_name} execution failed with exit code ${exec_code}"
    echo "$output"
    return 1
  fi

  log "INFO" "PLUGIN" "Plugin ${plugin_name} executed successfully"
  echo "$output"
  return 0
}

# ==============================================================================
# Orchestration
# ==============================================================================

# Orchestrate plugin execution for a file
# Arguments:
#   $1 - File path to process
#   $2 - Workspace directory
#   $3 - Plugins directory
# Returns:
#   0 on success, 1 on error
orchestrate_plugins() {
  local file_path="$1"
  local workspace_dir="$2"
  local plugins_dir="$3"

  log "INFO" "ORCHESTRATOR" "Orchestrating plugin execution for: ${file_path}"

  if [[ -z "$file_path" ]] || [[ -z "$workspace_dir" ]] || [[ -z "$plugins_dir" ]]; then
    log "ERROR" "ORCHESTRATOR" "orchestrate_plugins requires file_path, workspace_dir, and plugins_dir"
    return 1
  fi

  if [[ ! -f "$file_path" ]]; then
    log "ERROR" "ORCHESTRATOR" "File does not exist: ${file_path}"
    return 1
  fi

  # Build dependency graph to get execution order
  local plugin_order
  plugin_order=$(build_dependency_graph "$plugins_dir")
  if [[ $? -ne 0 ]]; then
    log "ERROR" "ORCHESTRATOR" "Failed to build dependency graph"
    return 1
  fi

  if [[ -z "$plugin_order" ]]; then
    log "INFO" "ORCHESTRATOR" "No active plugins to execute"
    return 0
  fi

  # Generate file hash
  local file_hash
  file_hash=$(generate_file_hash "$file_path")
  if [[ $? -ne 0 ]] || [[ -z "$file_hash" ]]; then
    log "ERROR" "ORCHESTRATOR" "Failed to generate file hash for: ${file_path}"
    return 1
  fi

  # Load existing workspace data
  local workspace_data
  workspace_data=$(load_workspace "$workspace_dir" "$file_hash")

  # Prepare absolute file path
  local file_path_absolute
  file_path_absolute=$(cd "$(dirname "$file_path")" && echo "$(pwd)/$(basename "$file_path")")

  # Prepare base variable JSON
  local base_variables
  base_variables=$(jq -n --arg fp "$file_path_absolute" '{"file_path_absolute": $fp}')

  # Execute each plugin in order
  local had_error=0
  while IFS= read -r plugin_name; do
    [[ -z "$plugin_name" ]] && continue

    # Check if plugin should execute for this file type
    if ! should_execute_plugin "$plugin_name" "$file_path" "$plugins_dir"; then
      log "DEBUG" "ORCHESTRATOR" "Skipping plugin ${plugin_name} (file type mismatch)"
      continue
    fi

    # Build variable JSON: merge base variables with workspace data
    local variable_json
    variable_json=$(echo "$base_variables" "$workspace_data" | jq -s '.[0] * (.[1] // {})' 2>/dev/null)

    # Execute plugin
    local plugin_output
    plugin_output=$(execute_plugin "$plugin_name" "$plugins_dir" "$variable_json" 2>/dev/null)
    local plugin_exit=$?

    if [[ $plugin_exit -ne 0 ]]; then
      log "WARN" "ORCHESTRATOR" "Plugin ${plugin_name} failed, continuing with remaining plugins"
      workspace_data=$(merge_plugin_data "$workspace_data" "$plugin_name" '{}' "failure")
      had_error=1
      continue
    fi

    # Parse output: map comma-separated values to provides fields
    local descriptor_file
    descriptor_file=$(find "$plugins_dir" -path "*/${plugin_name}/descriptor.json" -type f 2>/dev/null | head -1)

    local result_json="{}"
    if [[ -n "$descriptor_file" ]] && [[ -n "$plugin_output" ]]; then
      local provides_keys
      provides_keys=$(jq -r '.provides | keys[]? // empty' "$descriptor_file" 2>/dev/null || true)
      if [[ -n "$provides_keys" ]]; then
        # Split output by comma and map to provides fields
        IFS=',' read -ra output_values <<< "$plugin_output"
        local idx=0
        result_json="{"
        local first=true
        while IFS= read -r pkey; do
          local val="${output_values[$idx]:-}"
          # Trim whitespace
          val=$(echo "$val" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          if [[ "$first" == "true" ]]; then
            first=false
          else
            result_json+=","
          fi
          # Escape value for JSON
          local escaped_val
          escaped_val=$(jq -n --arg v "$val" '$v' 2>/dev/null)
          result_json+="\"${pkey}\":${escaped_val}"
          idx=$((idx + 1))
        done <<< "$provides_keys"
        result_json+="}"
      fi
    fi

    # Validate result_json
    if ! echo "$result_json" | jq empty 2>/dev/null; then
      result_json="{}"
    fi

    # Merge results into workspace
    workspace_data=$(merge_plugin_data "$workspace_data" "$plugin_name" "$result_json" "success")

  done <<< "$plugin_order"

  # Save workspace
  if ! save_workspace "$workspace_dir" "$file_hash" "$workspace_data"; then
    log "ERROR" "ORCHESTRATOR" "Failed to save workspace data"
    return 1
  fi

  if [[ $had_error -ne 0 ]]; then
    log "WARN" "ORCHESTRATOR" "Orchestration completed with errors"
    return 1
  fi

  log "INFO" "ORCHESTRATOR" "Orchestration completed successfully for: ${file_path}"
  return 0
}
