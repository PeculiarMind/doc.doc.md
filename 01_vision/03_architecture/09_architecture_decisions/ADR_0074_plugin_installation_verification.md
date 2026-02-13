# ADR-0074: Plugin Installation Verification

**ID**: ADR-0074  
**Status**: Draft  
**Created**: 2026-02-13  
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
- Aligns with modular, data-driven plugin architecture and layered validation (see ADR-0072).

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
- [req_0074_plugin_installation_verification](../../../02_requirements/03_accepted/req_0074_plugin_installation_verification.md)

## Related Decisions
- [ADR-0072: Plugin Execution Engine](ADR_0072_plugin_execution_engine.md)

---

*This ADR documents the architecture decision for plugin installation verification as required by req_0074_plugin_installation_verification.*
