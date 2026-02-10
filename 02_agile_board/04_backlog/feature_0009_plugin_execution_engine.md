# Feature: Plugin Execution Engine

**ID**: 0009  
**Type**: Feature Implementation  
**Status**: Backlog  
**Created**: 2026-02-09  
**Updated**: 2026-02-10 (Moved to backlog)  
**Priority**: Critical

## Overview
Implement the plugin execution orchestrator that builds dependency graphs, orders plugin execution based on data dependencies, executes plugins with proper environment setup, captures results, and updates workspace with new data.

## Description
Create the core orchestration engine that brings the plugin architecture to life. This feature implements data-driven execution flow where plugins declare what data they consume and provide, the system automatically determines optimal execution order, and plugins execute only when their dependencies are satisfied. The orchestrator manages the execution environment, captures plugin output, merges results into workspace, and handles execution errors gracefully.

This is the heart of the toolkit's extensibility, enabling automatic workflow management without users needing to configure explicit execution sequences.

## Business Value
- Enables automatic plugin workflow orchestration without manual configuration
- Provides consistent plugin execution environment
- Enables plugin ecosystem through data-driven dependencies
- Supports parallel execution optimization (future enhancement)
- Critical dependency for core analysis functionality

## Related Requirements
- [req_0023](../../01_vision/02_requirements/03_accepted/req_0023_data_driven_execution_flow.md) - Data-driven Execution Flow (PRIMARY)
- [req_0024](../../01_vision/02_requirements/03_accepted/req_0024_plugin_dependency_graph_construction.md) - Plugin Dependency Graph
- [req_0022](../../01_vision/02_requirements/03_accepted/req_0022_plugin_based_extensibility.md) - Plugin Architecture
- [req_0043](../../01_vision/02_requirements/03_accepted/req_0043_plugin_file_type_filtering.md) - Plugin File Type Filtering
- [req_0047](../../01_vision/02_requirements/03_accepted/req_0047_plugin_descriptor_validation.md) - Plugin Descriptor Validation

## Acceptance Criteria

### Dependency Graph Construction
- [ ] System analyzes all plugin descriptors to extract `consumes` and `provides` fields
- [ ] System builds directed dependency graph: Plugin A → Plugin B if B consumes A's output
- [ ] System detects circular dependencies and reports error
- [ ] System validates all `consumes` references can be satisfied by some plugin's `provides`
- [ ] System handles plugins with no dependencies (execution order: any)
- [ ] System handles plugins with multiple dependencies (execute after all deps satisfied)

### Topological Sort
- [ ] System performs topological sort on dependency graph
- [ ] System produces ordered plugin execution sequence
- [ ] System ensures dependencies always execute before consumers
- [ ] System handles multiple valid orderings deterministically (consistent results)
- [ ] System logs execution order in verbose mode

### Plugin Filtering
- [ ] System filters plugins by file type using `processes` field from descriptor
- [ ] System matches file MIME type against plugin `processes.mime_types` array
- [ ] System matches file extension against plugin `processes.file_extensions` array
- [ ] System executes plugin only if file type matches (or `processes` is empty = all types)
- [ ] System logs per-file plugin filtering decisions in verbose mode

### Execution Environment Setup
- [ ] System loads workspace data for current file
- [ ] System exports workspace data as environment variables for plugin access
- [ ] System changes working directory to plugin directory before execution
- [ ] System sets up isolated environment (prevent pollution of main script environment)
- [ ] System provides file path to plugin via standard variable name

### Plugin Execution
- [ ] System executes plugin `execute_commandline` from descriptor
- [ ] System captures plugin stdout and stderr
- [ ] System enforces execution timeout (configurable, default 5 minutes)
- [ ] System handles plugin execution failures gracefully (log error, skip, continue)
- [ ] System validates plugin returns expected data format
- [ ] System logs plugin execution time in verbose mode

### Result Capture
- [ ] System captures plugin output variables using `read -r` pattern from descriptor
- [ ] System validates captured data matches plugin's `provides` declaration
- [ ] System handles missing optional outputs gracefully
- [ ] System handles malformed output with clear error message
- [ ] System logs captured data in verbose mode

### Workspace Update
- [ ] System merges plugin results with existing workspace data
- [ ] System updates `plugins_executed` array with execution record (name, timestamp, status)
- [ ] System writes updated workspace atomically (using workspace manager)
- [ ] System handles workspace write failures gracefully
- [ ] System preserves existing data when merging new results

### Dependency Satisfaction Check
- [ ] System checks if all plugin's `consumes` dependencies are satisfied before execution
- [ ] System looks for required data in workspace for current file
- [ ] System skips plugin if dependencies not satisfied (log warning)
- [ ] System re-evaluates dependencies after each plugin execution (for chained deps)
- [ ] System provides clear error messages for unsatisfied dependencies

### Error Handling
- [ ] System handles plugin not found errors
- [ ] System handles plugin execution failures (non-zero exit code)
- [ ] System handles plugin timeout (kill process, log timeout)
- [ ] System handles malformed plugin output
- [ ] System continues processing remaining plugins after failures
- [ ] System aggregates and reports execution errors at end

### Per-File Orchestration
- [ ] System orchestrates plugin execution for each file independently
- [ ] System loads file-specific workspace before plugin execution
- [ ] System updates file-specific workspace after each plugin
- [ ] System handles per-file execution errors independently (don't fail entire run)

## Technical Considerations

### Implementation Approach
```bash
orchestrate_plugins() {
  local file_path="$1"
  local file_hash="$2"
  local workspace_dir="$3"
  local plugins_dir="$4"
  
  # Load workspace data for file
  local workspace_data
  workspace_data=$(load_workspace "$workspace_dir" "$file_hash")
  
  # Build dependency graph and sort
  local -a plugin_order
  plugin_order=($(build_dependency_graph "$plugins_dir"))
  
  # Execute plugins in dependency order
  for plugin_name in "${plugin_order[@]}"; do
    log "DEBUG" "ORCHESTRATOR" "Checking plugin: $plugin_name"
    
    # Check file type filtering
    if ! should_execute_plugin "$plugin_name" "$file_path" "$workspace_data"; then
      log "DEBUG" "ORCHESTRATOR" "Skipping $plugin_name (file type mismatch)"
      continue
    fi
    
    # Check dependency satisfaction
    if ! dependencies_satisfied "$plugin_name" "$workspace_data"; then
      log "WARN" "ORCHESTRATOR" "Skipping $plugin_name (dependencies not satisfied)"
      continue
    fi
    
    # Execute plugin
    log "INFO" "ORCHESTRATOR" "Executing plugin: $plugin_name"
    local plugin_result
    if plugin_result=$(execute_plugin "$plugin_name" "$file_path" "$workspace_data"); then
      # Merge results into workspace
      workspace_data=$(merge_plugin_results "$workspace_data" "$plugin_result") || {
        log "ERROR" "ORCHESTRATOR" "Failed to merge results from $plugin_name"
        continue
      }
      
      # Record execution
      workspace_data=$(update_execution_record "$workspace_data" "$plugin_name" "success")
    else
      log "ERROR" "ORCHESTRATOR" "Plugin $plugin_name failed"
      workspace_data=$(update_execution_record "$workspace_data" "$plugin_name" "failed")
    fi
  done
  
  # Save final workspace data
  save_workspace "$workspace_dir" "$file_hash" "$workspace_data"
}

build_dependency_graph() {
  local plugins_dir="$1"
  
  declare -A provides_map  # data_field -> plugin_name
  declare -A consumes_map  # plugin_name -> required_fields[]
  declare -A graph         # plugin_name -> depends_on[]
  
  # Analyze all plugins
  while IFS= read -r descriptor_file; do
    local plugin_name
    plugin_name=$(jq -r '.name' "$descriptor_file")
    
    # Extract provides
    local -a provides_fields
    mapfile -t provides_fields < <(jq -r '.provides[]' "$descriptor_file")
    for field in "${provides_fields[@]}"; do
      provides_map["$field"]="$plugin_name"
    done
    
    # Extract consumes
    mapfile -t consumes_map["$plugin_name"] < <(jq -r '.consumes[]' "$descriptor_file")
  done < <(find "$plugins_dir" -name 'descriptor.json')
  
  # Build dependency edges
  for plugin_name in "${!consumes_map[@]}"; do
    for required_field in "${consumes_map[$plugin_name][@]}"; do
      local provider="${provides_map[$required_field]}"
      if [[ -n "$provider" ]]; then
        graph["$plugin_name"]+=" $provider"
      fi
    done
  done
  
  # Topological sort (Kahn's algorithm)
  topological_sort graph
}

execute_plugin() {
  local plugin_name="$1"
  local file_path="$2"
  local workspace_data="$3"
  
  local plugin_dir="$PLUGINS_DIR/$plugin_name"
  local descriptor="$plugin_dir/descriptor.json"
  
  # Load execute command
  local execute_cmd
  execute_cmd=$(jq -r '.execute_commandline' "$descriptor")
  
  # Setup environment
  export FILE_PATH="$file_path"
  export WORKSPACE_DATA="$workspace_data"
  
  # Execute with timeout
  local output
  local start_time=$SECONDS
  if output=$(cd "$plugin_dir" && timeout 300 eval "$execute_cmd" 2>&1); then
    local duration=$((SECONDS - start_time))
    log "DEBUG" "PLUGIN" "$plugin_name completed in ${duration}s"
    echo "$output"
    return 0
  else
    log "ERROR" "PLUGIN" "$plugin_name failed or timed out"
    return 1
  fi
}

dependencies_satisfied() {
  local plugin_name="$1"
  local workspace_data="$2"
  
  local descriptor="$PLUGINS_DIR/$plugin_name/descriptor.json"
  
  # Get required fields
  local -a required_fields
  mapfile -t required_fields < <(jq -r '.consumes[]' "$descriptor")
  
  # Check each required field exists in workspace
  for field in "${required_fields[@]}"; do
    if ! jq -e "has(\"$field\")" <<< "$workspace_data" >/dev/null; then
      log "DEBUG" "ORCHESTRATOR" "Missing required data: $field"
      return 1
    fi
  done
  
  return 0
}

should_execute_plugin() {
  local plugin_name="$1"
  local file_path="$2"
  local workspace_data="$3"
  
  local descriptor="$PLUGINS_DIR/$plugin_name/descriptor.json"
  
  # Check if plugin has file type filters
  if ! jq -e 'has("processes")' "$descriptor" >/dev/null; then
    # No filter = execute for all files
    return 0
  fi
  
  # Get file MIME type from workspace
  local file_mime
  file_mime=$(jq -r '.file_type' <<< "$workspace_data")
  
  local file_ext="${file_path##*.}"
  
  # Check MIME type match
  if jq -e ".processes.mime_types[] | select(. == \"$file_mime\")" "$descriptor" >/dev/null; then
    return 0
  fi
  
  # Check extension match
  if jq -e ".processes.file_extensions[] | select(. == \".$file_ext\")" "$descriptor" >/dev/null; then
    return 0
  fi
  
  return 1
}
```

### Integration Points
- **Plugin Manager**: Discovers plugins and validates descriptors
- **Workspace Manager**: Reads/writes plugin data
- **Directory Scanner**: Provides file list for processing
- **Report Generator**: Consumes final workspace data

### Dependencies
- Plugin discovery (feature_0003) ✅
- Workspace management (feature_0007) - for data storage
- Directory scanner (feature_0006) - for file list
- Plugin descriptor validation (feature_0011) - for security

### Performance Considerations
- Efficient dependency graph construction (single pass)
- Minimize workspace read/write operations
- Consider parallel plugin execution for independent plugins (future)
- Cache plugin descriptors to avoid repeated parsing

### Security Considerations
- Validate plugin descriptors before execution (via feature_0011)
- Isolate plugin execution environment
- Enforce timeouts to prevent runaway plugins
- Validate plugin output before workspace merge
- Handle malicious or malformed plugin output safely

## Dependencies
- Requires: Basic script structure (feature_0001) ✅
- Requires: Plugin listing (feature_0003) ✅
- Requires: Workspace management (feature_0007)
- Requires: Directory scanner (feature_0006)
- Blocks: Report generator (feature_0010)

## Testing Strategy
- Unit tests: Dependency graph construction
- Unit tests: Topological sort
- Unit tests: Dependency satisfaction checking
- Unit tests: Plugin filtering by file type
- Integration tests: Multi-plugin execution with dependencies
- Integration tests: Circular dependency detection
- Integration tests: Plugin failure handling
- Integration tests: Timeout enforcement
- Performance tests: Large plugin sets, complex dependencies

## Definition of Done
- [ ] All acceptance criteria met
- [ ] Unit tests passing with >80% coverage
- [ ] Integration tests passing
- [ ] Code reviewed and approved
- [ ] Documentation updated (execution flow, orchestration)
- [ ] Security review completed
- [ ] Performance benchmarks meet targets
