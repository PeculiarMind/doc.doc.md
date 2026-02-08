# ADR-0003: Data-Driven Plugin Orchestration

**ID**: ADR-0003  
**Status**: Accepted  
**Created**: 2026-02-06  
**Last Updated**: 2026-02-08

## Context

Need to determine how plugins execute and in what order. System must support multiple plugins with interdependencies, ensuring correct execution sequence without requiring users to manually configure workflow order.

## Decision

Automatically determine plugin execution order by analyzing data dependencies declared in plugin descriptors (consumes/provides). Plugins execute when their required data becomes available.

## Rationale

**Strengths**:
- **Zero Configuration**: Users don't specify execution order
- **Automatic Adaptation**: Adding/removing plugins automatically adjusts workflow
- **Composability**: New plugins integrate without configuration changes
- **Correctness**: Dependency analysis ensures proper execution order
- **Flexibility**: Supports complex, multi-level dependency chains

**Weaknesses**:
- **Complexity**: Requires dependency graph analysis and topological sorting
- **Debugging**: Execution order not explicitly specified, harder to reason about
- **Circular Dependencies**: Must detect and handle gracefully

## Alternatives Considered

### Fixed Execution Order
- ✅ Simple, predictable, easy to debug
- ❌ Fragile (breaks when plugins added/removed)
- ❌ Requires manual configuration
- ❌ Not composable
- **Decision**: Violates extensibility goal

### User-Defined Workflow
- ✅ Full control, explicit dependencies
- ❌ High configuration burden
- ❌ Error-prone (user must understand all dependencies)
- ❌ Requires workflow modeling knowledge
- **Decision**: From vision: "users do not need to model or maintain an explicit workflow"

### Priority-Based Execution
- ✅ Simple numeric ordering
- ❌ Doesn't express dependencies
- ❌ Fragile when priorities conflict
- ❌ Requires manual priority assignment
- **Decision**: Insufficient for complex dependencies

### Event-Driven (Pub/Sub)
- ✅ Highly decoupled
- ❌ Too complex for bash implementation
- ❌ Harder to reason about execution flow
- **Decision**: Over-engineered for use case

## Consequences

### Positive
- Users can add custom plugins without modifying core
- System adapts automatically as plugins evolve
- Clear plugin contract (consumes/provides)
- Supports parallel execution of independent plugins (future)

### Negative
- Must implement graph algorithms (topological sort, cycle detection)
- Execution order not immediately obvious to users
- Requires clear error messages when dependencies fail

### Risks
- Circular dependencies could deadlock system
- Missing dependency data may cause runtime failures
- Complex dependency chains harder to debug

## Implementation Notes

**Dependency Graph Construction**:
```bash
# For each plugin:
for plugin in "${PLUGINS[@]}"; do
  consumes=$(jq -r '.consumes | keys[]' "${plugin}/descriptor.json")
  provides=$(jq -r '.provides | keys[]' "${plugin}/descriptor.json")
  # Build graph: if plugin B consumes what plugin A provides, edge A→B
done
```

**Topological Sort**:
```bash
# Kahn's algorithm or DFS-based topological sort
# Output: Ordered list of plugins
```

**Execution**:
```bash
for plugin in "${ORDERED_PLUGINS[@]}"; do
  if data_available_for_plugin "${plugin}"; then
    execute_plugin "${plugin}"
  else
    skip_plugin "${plugin}"
  fi
done
```

**Mitigation Strategies**:
- Provide `-v` verbose mode showing execution order
- Clear error messages for circular dependencies
- Document plugin contract explicitly
- Log which plugins execute and why

## Related Items

- [ADR-0002](ADR_0002_json_workspace_for_state_persistence.md) - JSON workspace stores plugin data dependencies
- [ADR-0004](ADR_0004_platform_specific_plugin_directories.md) - Platform-specific plugins participate in orchestration
- REQ-0011: Automatic Plugin Dependency Resolution
- REQ-0012: Plugin Execution Orchestration

**Trade-offs Accepted**:
- **Complexity over Simplicity**: Accept graph algorithm complexity for user convenience
- **Implicit over Explicit**: Execution order emergent, not specified
- **Automation over Control**: System orchestrates, users trust the algorithm
