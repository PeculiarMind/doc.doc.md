# ADR-0001: Bash as Primary Implementation Language

**ID**: ADR-0001  
**Status**: Accepted  
**Created**: 2026-02-06  
**Last Updated**: 2026-02-08

## Context

Need to choose implementation language for CLI tool orchestration system that will run on Linux, macOS, and WSL environments. The tool must be lightweight, easy to distribute, and integrate naturally with command-line tools.

## Decision

Implement the core orchestration logic in Bash shell scripting (v4.0+).

## Rationale

**Strengths**:
- **Ubiquitous Availability**: Present on all target platforms (Linux, macOS, WSL)
- **Native Process Control**: Direct access to process spawning and management
- **Zero Installation Overhead**: No runtime or compilation required
- **CLI Tool Integration**: Natural fit for invoking command-line tools
- **File System Operations**: Direct, efficient file system access
- **Low Learning Curve**: Familiar to system administrators and DevOps users

**Weaknesses**:
- **Limited Data Structures**: No native support for complex data structures
- **Error Handling**: Less robust than modern languages
- **Portability Concerns**: Shell-specific features may limit portability
- **Maintainability**: Complex logic harder to maintain than structured languages

## Alternatives Considered

### Python
- ✅ Better data structures, error handling, maintainability
- ❌ Requires Python runtime installation
- ❌ Additional dependency management (pip, virtualenv)
- ❌ Slower startup time
- **Decision**: Overkill for orchestration task, adds runtime dependency

### Go
- ✅ Fast, single binary, excellent error handling
- ❌ Compilation required
- ❌ Higher development complexity
- ❌ Less accessible to non-programmers
- **Decision**: Unnecessary complexity for script orchestration

### Node.js
- ✅ Good async capabilities, JSON handling
- ❌ Requires Node.js runtime
- ❌ Heavyweight for simple orchestration
- **Decision**: Too heavy for lightweight toolkit

## Consequences

### Positive
- Users can run without installing additional software
- Easy to inspect, modify, and debug
- Natural integration with existing shell workflows
- Can invoke any CLI tool without wrappers

### Negative
- Complex data operations need external tools (jq for JSON)
- Must be careful with shell-specific features (use POSIX where possible)
- Testing requires special frameworks (bats, shunit2)

### Risks
- Shell version incompatibilities across platforms
- Limited type safety may lead to runtime errors
- Complex logic may become difficult to maintain

## Implementation Notes

**Mitigation Strategies**:
- Use JSON workspace to handle complex data structures
- Follow POSIX standards for maximum portability
- Delegate complex logic to specialized plugins
- Document shell version requirements clearly

**Shell Version Requirements**:
- Minimum: Bash 4.0+
- Prefer POSIX-compliant features where possible
- Document bash-specific features when used

## Related Items

- [ADR-0002](ADR_0002_json_workspace_for_state_persistence.md) - JSON workspace complements Bash limitations
- [ADR-0003](ADR_0003_data_driven_plugin_orchestration.md) - Plugin architecture leverages Bash's CLI integration
- [ADR-0009](ADR_0009_modular_component_based_script_architecture.md) - Modular architecture improves Bash maintainability
- TC-0001: Bash Runtime Environment (technical constraint)

**Trade-offs Accepted**:
- **Simplicity over Sophistication**: Accept bash limitations for zero-dependency deployment
- **Composability over Integration**: Leverage external tools rather than built-in capabilities
- **Accessibility over Performance**: Bash adequate for use case, prioritize ease of use
