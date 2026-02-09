# IDR-0005: Platform-Specific Plugin Precedence

**ID**: IDR-0005  
**Status**: Accepted  
**Created**: 2026-02-06  
**Last Updated**: 2026-02-08  
**Related ADRs**: [ADR-0004: Platform-Specific Plugin Directories](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0004_platform_specific_plugin_directories.md)

## Decision

Platform-specific plugins take precedence over cross-platform plugins when the same plugin name exists in both locations.

## Context

Plugins can exist in both platform-specific directories (`plugins/ubuntu/`, `plugins/darwin/`) and cross-platform directories (`plugins/all/`). When a plugin with the same name exists in both locations, the system must decide which version to use during discovery and listing.

## Rationale

**Use Cases for Platform-Specific Override**:

1. **Platform Optimization**:
   - Ubuntu-specific `stat` plugin using Ubuntu-specific flags (`-c` format)
   - macOS `stat` plugin using BSD stat syntax (`-f` format)
   - Platform-optimized tool invocations

2. **Tool Availability**:
   - Platform-specific plugin uses tools only available on that platform
   - Fallback to generic implementation when tool unavailable
   - Example: `apt-get` plugin only on Debian/Ubuntu systems

3. **Customization Without Forking**:
   - User can override generic plugin with custom platform version
   - No need to modify original plugin
   - Maintains clean separation of concerns

4. **Plugin Evolution Path**:
   - Plugin starts as generic (`plugins/all/example/`)
   - Platform-specific optimization added (`plugins/ubuntu/example/`)
   - Generic version remains as fallback for other platforms

**Precedence Logic**:
```
Discovery Order:
1. plugins/ubuntu/example   → Found, added to seen_plugins["example"]
2. plugins/all/example      → Found, but skipped (already in seen_plugins)

Result: Only Ubuntu-specific version appears in listing
```

## Implementation

**Discovery Algorithm**:
```bash
declare -A seen_plugins

# Scan platform-specific directory first (higher priority)
if [[ -d "${platform_dir}" ]]; then
  find "${platform_dir}" -name "descriptor.json" | while read descriptor; do
    plugin_data=$(parse_plugin_descriptor "$descriptor")
    plugin_name="${plugin_data%%|*}"
    
    if [[ -z "${seen_plugins[${plugin_name}]+x}" ]]; then
      plugin_list+=("${plugin_data}")
      seen_plugins[${plugin_name}]=1
    fi
  done
fi

# Scan cross-platform directory second (lower priority)
if [[ -d "${all_dir}" ]]; then
  find "${all_dir}" -name "descriptor.json" | while read descriptor; do
    plugin_data=$(parse_plugin_descriptor "$descriptor")
    plugin_name="${plugin_data%%|*}"
    
    # Skip if already seen (platform version exists)
    if [[ -z "${seen_plugins[${plugin_name}]+x}" ]]; then
      plugin_list+=("${plugin_data}")
      seen_plugins[${plugin_name}]=1
    fi
  done
fi
```

**Verbose Mode Logging**:
```bash
log "DEBUG" "Added platform plugin: ${plugin_name}"
log "DEBUG" "Skipped duplicate plugin (platform version exists): ${plugin_name}"
```

## Reason

Platform precedence rule necessary during Feature 0003 implementation to operationalize platform-specific plugin directories specified in vision (ADR-0004). Vision establishes the directory structure but does not specify precedence behavior when plugins exist in multiple locations. This decision enables platform optimization and customization.

## Deviation from Vision

No deviation - this decision fills implementation details not specified in vision. ADR-0004 (Platform-Specific Plugin Directories) establishes the directory structure but does not define precedence rules. This implementation decision extends the vision by defining predictable, intuitive precedence behavior that aligns with the vision's goals of platform optimization.

## Associated Risks

No associated risks - decision aligns with vision principles. Primary consideration is silent override of cross-platform plugins, which is mitigated:
- Documented precedence rules in help text and README
- Debug logging in verbose mode shows which plugins are skipped
- Intentional behavior enabling platform customization
- Users can delete platform version to use cross-platform fallback
**Positive**:
- ✅ Enables platform-specific optimizations
- ✅ Allows user customization without modifying source
- ✅ Clear, predictable behavior
- ✅ Supports gradual plugin evolution (generic → optimized)
- ✅ No configuration required

**Negative**:
- ⚠️ **Cross-platform version silently ignored**
  - **Mitigation**: Log at DEBUG level in verbose mode
  - **Mitigation**: Document precedence rules in help and README
  - **Acceptable**: Intentional override behavior
  - **User Control**: User can delete platform version to use cross-platform
- ⚠️ **Must document precedence rules clearly**
  - **Mitigation**: Document in plugin concept documentation
  - **Mitigation**: Include in help text and examples
  - **Impact**: Low (intuitive behavior)

## Precedence Example Scenarios

### Scenario 1: Platform Optimization
```
plugins/
├── ubuntu/
│   └── stat/
│       └── descriptor.json  (uses -c format, Ubuntu-specific)
└── all/
    └── stat/
        └── descriptor.json  (generic version)

Result on Ubuntu: Uses ubuntu/stat/ (optimized)
Result on macOS: Uses all/stat/ (generic, since no darwin/stat/)
```

### Scenario 2: Platform-Only Plugin
```
plugins/
├── ubuntu/
│   └── apt-info/
│       └── descriptor.json  (Ubuntu-specific, no generic equivalent)
└── all/
    (no apt-info here)

Result on Ubuntu: Uses ubuntu/apt-info/
Result on macOS: Plugin not available (correctly absent)
```

### Scenario 3: User Customization
```
plugins/
├── ubuntu/
│   └── custom-analyzer/
│       └── descriptor.json  (user's custom version)
└── all/
    └── custom-analyzer/
        └── descriptor.json  (original version)

Result: Uses ubuntu/custom-analyzer/ (user's custom version)
```

## Alternatives Considered

1. **Error on Duplicate Plugin Names**
   - ❌ Prevents legitimate use cases (optimization, customization)
   - ❌ Forces user to manually manage conflicts
   - ❌ Reduces flexibility
   - **Rejected**: Too restrictive

2. **Cross-Platform Takes Precedence**
   - ❌ Backwards: Platform-specific should override generic
   - ❌ Counter-intuitive for users
   - ❌ Prevents optimization use case
   - **Rejected**: Wrong priority order

3. **Load Both and Warn**
   - ❌ Which one executes during plugin run?
   - ❌ Ambiguity is undesirable
   - ❌ Complicates execution logic
   - **Rejected**: Creates confusion

4. **User Configuration File**
   - ❌ Too complex for simple use case
   - ❌ Adds configuration file requirement
   - ❌ Reduces "it just works" experience
   - **Rejected**: Over-engineered

5. **Explicit Priority Field in Descriptor**
   - ❌ Requires modifying all descriptors
   - ❌ More complex than directory-based precedence
   - ❌ Less intuitive
   - **Rejected**: Adds unnecessary complexity

## Impact

- **Plugin Discovery**: Consistent, predictable precedence rules
- **User Experience**: Intuitive behavior (platform-specific naturally overrides generic)
- **Maintainability**: Simple to understand and debug
- **Extensibility**: Enables platform-specific optimizations without forking

## Future Considerations

If precedence becomes a user pain point (unlikely), could add:
- Configuration option to reverse precedence
- Warning flag to show when duplicates exist
- Flag to list all plugins including duplicates

These would be additive features, not breaking changes.

## Related Decisions

- [IDR-0009: Platform Detection Fallback](IDR_0009_platform_detection_fallback.md) - Defines platform detection mechanism
- [IDR-0003: Pipe-Delimited Plugin Data](IDR_0003_pipe_delimited_plugin_data.md) - Data format for plugins

## References

- **Implementation**: `scripts/doc.doc.sh` (lines 242-290)
- **Requirements**: req_0024 (Plugin Listing), req_0022 (Plugin-based Extensibility)
- **Vision**: `01_vision/03_architecture/08_concepts/08_0001_plugin_concept.md`
- **Testing**: `tests/unit/test_plugin_listing.sh`
