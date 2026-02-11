# IDR-0016: Plugin Execution Engine Implementation

**ID**: IDR-0016  
**Status**: Implemented  
**Created**: 2026-02-11  
**Features**: Feature 0009 (Plugin Execution Engine), Feature 0011 (Tool Verification), Feature 0012 (Plugin Security Validation), Feature 0020 (Stat Plugin)

## Table of Contents

- [Context](#context)
- [Implementation Decisions](#implementation-decisions)
- [Consequences](#consequences)
- [Compliance Verification](#compliance-verification)
- [Related Items](#related-items)

## Context

Features 0009, 0011, 0012, and 0020 collectively implement the plugin execution subsystem envisioned in ADR-0009 (Plugin Security Sandboxing) and ADR-0010 (Plugin-Toolkit Interface Architecture). This IDR documents the actual implementation decisions made when building three new components (`plugin_executor.sh`, `plugin_validator.sh`, `plugin_tool_checker.sh`) and the first concrete plugin (`stat`).

## Implementation Decisions

### 1. Dependency Graph via Kahn's Algorithm

**Decision**: Use Kahn's algorithm (topological sort with in-degree tracking) for plugin execution ordering.

**Rationale**:
- Naturally detects circular dependencies (unprocessed nodes remaining after algorithm completes)
- Deterministic ordering through sorted queue processing
- Linear time complexity O(V + E) suitable for plugin scale
- Simpler to implement in Bash than DFS-based alternatives

**Alternatives Considered**:
- DFS-based topological sort → Rejected (cycle detection requires separate visited-state tracking, more complex in Bash)
- Manual ordering in configuration → Rejected (violates data-driven design per ADR-0010)

### 2. Sandboxed Execution with Graceful Fallback

**Decision**: Prefer Bubblewrap (`bwrap`) for sandboxed execution but fall back to `timeout`-wrapped execution when `bwrap` is unavailable.

**Rationale**:
- Bubblewrap may not be installed on all target systems
- Refusing to run entirely would prevent adoption on systems without `bwrap`
- Timeout-wrapped fallback still provides execution time limits
- Warning logged when falling back so operators are aware of reduced isolation

**Deviation from ADR-0009**: ADR-0009 specifies a "hard dependency" on Bubblewrap with no plugin execution without sandbox. The implementation relaxes this to a preferred-but-optional dependency. This trade-off prioritizes usability over strict sandboxing enforcement. The fallback logs a warning and is intended as a transitional measure until `bwrap` becomes a hard requirement.

**Sandbox Configuration** (when bwrap available):
- Read-only bind of `/usr`, `/bin`, `/lib`, `/lib64`
- Read-only bind of source file
- Writable plugin directory and temp directory
- `--unshare-net`, `--unshare-pid`, `--new-session`, `--die-with-parent`

### 3. Plugin Count Limit (DoS Protection)

**Decision**: Limit discovered plugins to 100 maximum.

**Rationale**:
- Prevents resource exhaustion from excessive plugin directories
- 100 is well above expected practical use (< 20 plugins)
- Simple guard that protects topological sort and execution loop
- Aligns with defense-in-depth security principle

### 4. Comma-Separated Output Parsing

**Decision**: Plugin output uses comma-separated values parsed by the orchestrator, not the `read -r` pattern from within the sandbox.

**Rationale**:
- Avoids process substitution complexity inside sandboxed environments
- Comma-separated format (`stat -c '%Y,%s,%U'`) is simple and reliable
- Orchestrator splits output using `IFS=','` after sandbox execution completes
- Aligns with the `provides` field ordering in descriptors

**Alternative Considered**:
- `read -r` inside sandbox (per ADR-0010 example) → Rejected for implementation simplicity; the orchestrator handles parsing externally

### 5. Secure Variable Substitution

**Decision**: Implement allowlist-based character validation for variable values before template substitution.

**Rationale**:
- Blocks shell metacharacters: `;`, `|`, `&`, `` ` ``, `$()`, control characters
- Validates variable names against `^[a-zA-Z0-9_]+$` pattern
- Substitution performed via `sed` with pipe delimiter to avoid path separator conflicts
- Defense-in-depth: complements sandbox isolation

**Pattern**:
```bash
# Reject values containing injection characters
if [[ "$value" =~ [;\|&\`\$\(] ]] || [[ "$value" =~ [[:cntrl:]] ]]; then
    log "ERROR" "SECURITY" "Unsafe characters in variable value"
    return 1
fi
```

### 6. File Type Filtering with Wildcard Support

**Decision**: Support wildcard patterns (`*/*` for MIME types, `*` for extensions) to indicate universal plugins.

**Rationale**:
- Stat plugin processes all file types (no filtering needed)
- Wildcard avoids maintaining exhaustive type lists
- Extension check performed first (fast string match), MIME type check via `file` command as fallback
- Empty `processes` field also means universal execution

### 7. Tool Availability via `bash -c` Subshell

**Decision**: Execute `check_commandline` from descriptors using `bash -c` in a subshell.

**Rationale**:
- Isolates check execution from main shell environment
- check_commandline values come from plugin descriptors (validated by plugin_validator.sh)
- Acceptable security trade-off for availability checks (no file access, no state modification)
- Consistent with how install_commandline is also executed

### 8. Layered Validation Architecture

**Decision**: Implement validation as a separate component (`plugin_validator.sh`) called before execution.

**Rationale**:
- Separation of concerns: validation logic independent from execution logic
- Fail-fast: invalid plugins rejected before any execution attempt
- Comprehensive checks: injection patterns, sandbox compatibility, `processes` field, circular dependencies
- Aligns with ADR-0007 modular component architecture

**Validation Layers**:
1. JSON syntax validation
2. Required field presence
3. Field format validation (name, types)
4. Command template injection checks
5. Variable substitution security
6. Sandbox compatibility
7. Cross-plugin circular dependency detection

### 9. Platform-Aware Installation Guidance

**Decision**: Provide platform-specific install commands derived from platform detection component.

**Rationale**:
- Reuses existing `platform_detection.sh` component
- Maps platforms to package managers (apt, brew, apk)
- Interactive prompts only when stdin is TTY
- Falls back to generic guidance for unsupported platforms

### 10. Stat Plugin as Reference Implementation

**Decision**: Implement stat plugin using simple `stat -c` command template with comma-separated output.

**Rationale**:
- Demonstrates the full plugin interface (consumes/provides/processes/commandline)
- Zero external dependencies (stat is part of coreutils)
- Universal plugin (processes all file types)
- Simple enough to serve as a template for future plugins
- Validates the entire pipeline from descriptor to execution

## Consequences

### Positive Outcomes

✅ **Security**: Layered defense (validation → sandbox → variable filtering)  
✅ **Extensibility**: New plugins only need descriptor.json and optional install.sh  
✅ **Modularity**: Three focused components (executor: 615 lines, validator: 491 lines, tool_checker: 223 lines)  
✅ **Usability**: Graceful degradation when bwrap unavailable  
✅ **Data-Driven**: Automatic execution ordering from consumes/provides declarations  
✅ **Reference Plugin**: Stat plugin validates the full pipeline end-to-end  

### Trade-offs Accepted

📊 **ADR-0009 Deviation**: Bwrap fallback relaxes mandatory sandboxing requirement  
📊 **Component Size**: plugin_executor.sh at 615 lines exceeds the 200-line component guideline from ADR-0007 (justified by orchestration complexity)  
📊 **bash -c for checks**: Tool availability checks use `bash -c` which is less restrictive than sandbox execution  

## Compliance Verification

### Against ADR-0009 (Plugin Security Sandboxing)

| ADR-0009 Specification | Implementation Status | Notes |
|------------------------|----------------------|-------|
| Mandatory Bubblewrap sandboxing | ⚠️ Partial | Preferred but graceful fallback when unavailable |
| Read-only filesystem access | ✅ Implemented | ro-bind for system dirs and source file |
| Temporary directory isolation | ✅ Implemented | Per-execution temp dir within plugin directory |
| No network access | ✅ Implemented | --unshare-net flag |
| Process isolation | ✅ Implemented | --unshare-pid, --new-session |
| Die with parent | ✅ Implemented | --die-with-parent flag |
| Plugin count limits | ✅ Implemented | 100 plugin maximum |

### Against ADR-0010 (Plugin-Toolkit Interface)

| ADR-0010 Specification | Implementation Status | Notes |
|------------------------|----------------------|-------|
| Command template with variable substitution | ✅ Implemented | sed-based ${variable} replacement |
| Sandboxed execution | ✅ Implemented | bwrap with fallback |
| Plugin directory as working directory | ✅ Implemented | --chdir in bwrap, cd in fallback |
| Structured output capture | ✅ Implemented | Comma-separated parsing |
| Unified plugin schema | ✅ Implemented | consumes/provides/processes/commandline |
| Variable validation | ✅ Implemented | Allowlist character validation |

### Against ADR-0007 (Modular Component Architecture)

| ADR-0007 Specification | Implementation Status | Notes |
|------------------------|----------------------|-------|
| Component in scripts/components/ | ✅ Implemented | All 3 components in plugin/ domain |
| Component interface headers | ✅ Implemented | Standard headers on all components |
| Explicit dependency loading | ✅ Implemented | Declared in component headers |
| Component independence | ✅ Implemented | Each component independently testable |
| Component size < 200 lines | ⚠️ Partial | tool_checker (223) OK; validator (491) and executor (615) exceed target |

## Related Items

- **Vision ADRs**: [ADR-0009](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0009_plugin_security_sandboxing_bubblewrap.md), [ADR-0010](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0010_plugin_toolkit_interface_architecture.md), [ADR-0007](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0007_modular_component_based_script_architecture.md)
- **Features**: [Feature 0009](../../../02_agile_board/05_implementing/feature_0009_plugin_execution_engine.md), [Feature 0011](../../../02_agile_board/05_implementing/feature_0011_tool_verification.md), [Feature 0012](../../../02_agile_board/05_implementing/feature_0012_plugin_security_validation.md), [Feature 0020](../../../02_agile_board/05_implementing/feature_0020_stat_plugin.md)
- **Building Block View**: [Plugin Execution Engine](../05_building_block_view/feature_0009_plugin_execution_engine.md)
- **Prior IDR**: [IDR-0014: Modular Component Architecture](IDR_0014_modular_component_architecture_implementation.md)
