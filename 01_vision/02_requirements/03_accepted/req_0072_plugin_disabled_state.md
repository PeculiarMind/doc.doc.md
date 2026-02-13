
# Requirement: Plugin Active State (User-Configurable)

ID: req_0072_plugin_disabled_state

## Status
State: Accepted
Created: 2025-02-12
Last Updated: 2026-02-13

## Overview
Users must be able to configure whether a plugin is "active" (true or false) without removing it from the plugins directory. Only the "active" state is user-configurable; there is no separate "enabled" field. The system will only execute plugins marked as active and meeting all runtime requirements (e.g., installed, compatible).

## Description
To provide flexibility and robust plugin management, the following mechanisms are required:

**Active State**:
- Controlled by user via configuration file, command-line flag, or plugin descriptor (`active: true/false`)
- Plugins marked as `active: false` are ignored for execution but remain discoverable
- Plugins must also pass runtime checks (e.g., required tool is installed, compatible with platform) to be executed
- See also req_0074_plugin_installation_verification

**Activation/Deactivation Mechanisms**:
- Configuration file lists plugins by ID with their active state
- Command-line flag to activate/deactivate specific plugins (e.g., `--deactivate-plugin`)
- Plugin descriptor `active: false` flag
- Directory naming convention (optional, e.g., `.disabled`)

**Scope**:
- Per-analysis (command-line flag)
- Per-workspace (workspace configuration)
- Global (toolkit configuration file)
- Platform-specific (deactivate plugin on specific OS)

**User Experience**:
- Plugin listing shows active/inactive status
- Clear indication why a plugin is not active (deactivated by user, missing dependency, incompatible, etc.)
- Easy activation/deactivation mechanism
- Inactive plugins do not generate execution errors or warnings

**Use Cases**:
- Temporarily deactivate a plugin for quick analysis
- Deactivate problematic or slow plugin while debugging
- Deactivate optional plugins not needed for specific analysis
- Deactivate incompatible plugin on specific platform
- Test analysis with a subset of plugins

## Motivation
Links to vision sections:
- User flexibility: Users should control which plugins run
- Performance optimization: Disable unused plugins to speed up analysis
- Troubleshooting: Isolate problematic plugins
- See also: 10_quality_requirements.md (Scenario U4 - "Verbose Debugging"), req_0021 (Toolkit Extensibility), req_0024 (Plugin Listing)

## Category
- Type: Functional
- Priority: Medium

## Acceptance Criteria
- [ ] User can set plugin `active` state via configuration file
- [ ] User can set plugin `active` state via command-line flag
- [ ] Plugin descriptor supports `active: true/false`
- [ ] Plugins marked as inactive are not executed but remain discoverable
- [ ] Plugin listing shows active/inactive status and reason if inactive
- [ ] Inactive plugins do not generate execution errors or warnings
- [ ] Documentation explains all activation/deactivation mechanisms

## Related Requirements
- req_0021_plugin_based_extensibility
- req_0047_plugin_descriptor_validation
- req_0074_plugin_installation_verification
- req_0024_plugin_listing
