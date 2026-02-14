# IDR-0018: Plugin Installation Verification Implementation

**ID**: IDR-0018  
**Status**: Implemented  
**Created**: 2026-02-13  
**Implemented**: 2026-02-14  
**Requirement**: req_0074_plugin_installation_verification

## Context

Requirement req_0074_plugin_installation_verification mandates that before executing any plugin, doc.doc.sh must verify installation using the `check_commandline` in the plugin descriptor, during initialization. All active but not installed plugins must be listed for the user.

## Decision

- **Initialization Check**: During startup, after plugin discovery, doc.doc.sh will iterate over all active plugins and execute their `check_commandline` in a subshell.
- **Unavailable Plugins**: If the check fails (exit code != 0 or result != 'true'), the plugin is marked as unavailable.
- **User Notification**: All active but unavailable plugins are listed for the user before any plugin execution or file analysis.
- **Execution Guard**: Unavailable plugins cannot be executed; attempts result in a clear error and installation guidance (using `install_commandline`).
- **Platform Awareness**: Installation guidance is platform-specific, leveraging platform detection logic.

## Rationale

- Ensures user is aware of missing dependencies before attempting plugin-based operations.
- Prevents runtime errors and improves user experience.
- Aligns with modular, data-driven plugin architecture and layered validation (see IDR-0016).

## Alternatives Considered

- **Lazy Checking**: Checking tool availability only at execution time. Rejected due to poor user experience and delayed feedback.
- **Auto-Install**: Automatically installing missing tools. Rejected for security and user control reasons.

## Consequences

- **Positive**: Early feedback, improved reliability, clear user guidance, compliance with new requirement.
- **Negative**: Slightly increased startup time due to checks.

## Related Concepts
- [Concept 0009: Plugin Installation Verification](../08_concepts/08_0009_plugin_installation_verification.md)
- [Concept 0001: Plugin Architecture](../08_concepts/08_0001_plugin_concept.md)

## Related Requirements
- [req_0074_plugin_installation_verification](../../../01_vision/02_requirements/req_0074_plugin_installation_verification.md)

## Related Decisions
- [IDR-0016: Plugin Execution Engine Implementation](IDR_0016_plugin_execution_engine_implementation.md)

## Implementation Details

### Components Modified

1. **main_orchestrator.sh**: Added `verify_plugin_installation()` function
   - Checks all active plugins during initialization phase
   - Uses `check_commandline` from plugin descriptors
   - Tracks unavailable plugins in `UNAVAILABLE_PLUGINS` global associative array
   - Reports missing plugins with installation guidance before analysis starts

2. **plugin_executor.sh**: Added guard in `execute_plugin()` function
   - Checks if plugin is in `UNAVAILABLE_PLUGINS` array
   - Skips execution and returns error for unavailable plugins
   - Prevents runtime errors from missing tools

### Workflow Integration

The verification is integrated into `orchestrate_directory_analysis()` as follows:
1. Step 1: Validate parameters
2. Step 2: Initialize analysis environment
3. **Step 3: Verify plugin installation (NEW)**
4. Step 4: Execute analysis workflow

### Testing

Comprehensive test suites validate the implementation:
- `test_plugin_installation_verification.sh`: Tests the verification function with various scenarios
- `test_plugin_executor_skip_unavailable.sh`: Tests that unavailable plugins are skipped during execution

---

*This IDR documents the implementation decision for plugin installation verification as required by req_0074_plugin_installation_verification.*
