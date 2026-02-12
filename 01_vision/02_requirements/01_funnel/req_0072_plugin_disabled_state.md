# Requirement: Plugin Disabled State

ID: req_0072

## Status
State: Funnel
Created: 2025-02-12
Last Updated: 2025-02-12

## Overview
Users shall be able to disable specific plugins without removing them from the plugins directory.

## Description
To provide flexibility in plugin usage and support troubleshooting scenarios, users need the ability to temporarily or permanently disable plugins:

**Disable Mechanisms**:
- Configuration file lists disabled plugins by ID
- Command-line flag to disable specific plugins (--disable-plugin)
- Plugin descriptor `enabled: false` flag
- Disabled plugin directory naming convention (.disabled suffix)

**Disable Scope**:
- Per-analysis disable (command-line flag)
- Per-workspace disable (workspace configuration)
- Global disable (toolkit configuration file)
- Platform-specific disable (disable plugin on specific OS)

**User Experience**:
- Plugin listing shows disabled plugins with status
- Clear indication why plugin is disabled (config, CLI, descriptor)
- Easy re-enable mechanism
- Disabled plugins don't generate warnings/errors

**Use Cases**:
- Disable slow plugin for quick analysis
- Disable problematic plugin while debugging
- Disable optional plugins not needed for specific analysis
- Disable incompatible plugin on specific platform
- Testing analysis with subset of plugins

**Discovery and Listing**:
- `--list-plugins` shows disabled plugins with status indicator
- Option to list only enabled plugins (default)
- Option to list only disabled plugins (--list-disabled)

## Motivation
Links to vision sections:
- **req_0024**: Plugin Listing (accepted) - listing should show plugin status
- **req_0021**: Toolkit Extensibility and Plugin Architecture (accepted) - flexibility in plugin usage
- **10_quality_requirements.md**: Scenario U4 - "Verbose Debugging" - disabling plugins aids debugging
- **User flexibility**: Users should control which plugins run
- **Performance optimization**: Disable unused plugins to speed up analysis
- **Troubleshooting**: Isolate problematic plugins

## Category
- Type: Functional
- Priority: Low

## Acceptance Criteria
- [ ] Configuration file supports disabled plugin list
- [ ] Command-line flag `--disable-plugin <id>` disables specific plugin
- [ ] Plugin descriptor `enabled: false` marks plugin as disabled
- [ ] Directory naming convention `.disabled` disables plugin
- [ ] Plugin listing shows disabled status
- [ ] Disabled plugins don't execute during analysis
- [ ] Disabled plugins don't generate tool availability warnings
- [ ] Documentation explains disable mechanisms
- [ ] Re-enable process documented and tested

## Related Requirements
- req_0024: Plugin Listing (accepted - should show disabled status)
- req_0021: Toolkit Extensibility and Plugin Architecture (accepted - flexibility)
- req_0007: Tool Availability Verification (accepted - disabled plugins skip verification)
- req_0043: Plugin File Type Filtering (accepted - disabled plugins skip filtering)
