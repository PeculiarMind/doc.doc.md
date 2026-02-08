# ADR-0004: Platform-Specific Plugin Directories

**ID**: ADR-0004  
**Status**: Accepted  
**Created**: 2026-02-06  
**Last Updated**: 2026-02-08

## Context

Need to support tools that differ across operating systems. Some analysis tools only exist on certain platforms, and command-line flags often differ between GNU and BSD variants.

## Decision

Organize plugins in platform-specific directories (`plugins/ubuntu/`, `plugins/macos/`, `plugins/all/`). System detects platform at runtime and loads appropriate plugins with precedence: platform-specific over generic.

## Rationale

**Strengths**:
- **Tool Availability**: Some tools only exist on certain platforms
- **Command Differences**: Tool flags differ (GNU stat vs BSD stat)
- **Graceful Degradation**: Missing plugins on unsupported platforms don't break core
- **Clear Organization**: Obvious which plugins work where

**Weaknesses**:
- **Duplication**: Some plugins may be duplicated across platforms
- **Maintenance**: Must maintain multiple versions of similar plugins
- **Testing**: Need to test on multiple platforms

## Alternatives Considered

### Single Plugin with Platform Detection
- ✅ No duplication, single source of truth
- ❌ Complex plugin logic to handle all platforms
- ❌ Harder to maintain and test
- **Decision**: Violates "simple plugins" principle

### Plugin Inheritance
- ✅ Share common logic, override platform-specific
- ❌ Too complex for bash implementation
- ❌ Harder to understand
- **Decision**: Over-engineered

### Runtime Platform Checks in Each Plugin
- ✅ Single plugin file
- ❌ Every plugin must handle all platforms
- ❌ Duplicated platform detection logic
- **Decision**: Inefficient, error-prone

## Consequences

### Positive
- Clear plugin organization
- Simple per-platform plugin implementation
- Easy to add platform support (create new directory)
- Plugins can use platform-native tool syntax

### Negative
- Duplicate plugins for cross-platform tools
- More directory traversal during discovery

### Risks
- Platform detection failures could load wrong plugins
- Inconsistent behavior across platforms
- Documentation burden to explain differences

## Implementation Notes

**Directory Structure**:
```
plugins/
├── all/                  # Cross-platform plugins
│   └── template-plugin/
│       └── descriptor.json
├── ubuntu/               # Ubuntu-specific
│   ├── stat/
│   │   ├── descriptor.json
│   │   └── install.sh
│   └── apt-tool/
│       └── descriptor.json
├── alpine/               # Alpine Linux-specific
│   └── apk-tool/
└── macos/                # macOS-specific
    └── bsd-stat/
```

**Plugin Loading Precedence**:
1. Platform-specific directory (e.g., `plugins/ubuntu/`)
2. Generic directory (`plugins/all/`)
3. Plugin with same name in platform-specific overrides generic

**Mitigation Strategies**:
- Use `plugins/all/` for truly cross-platform plugins
- Document platform-specific plugin development guidelines
- Minimize platform-specific plugins where possible
- Provide plugin template for each platform type

## Related Items

- [ADR-0003](ADR_0003_data_driven_plugin_orchestration.md) - Platform-specific plugins participate in orchestration
- TC-0001: Bash Runtime Environment (defines supported platforms)
- REQ-0013: Platform-Specific Plugin Support

**Trade-offs Accepted**:
- **Duplication over Complexity**: Accept some plugin duplication for simplicity
- **Directory Structure over Inheritance**: Filesystem organization clearer than plugin hierarchy
