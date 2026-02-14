# Feature: Plugin Active State Configuration

**ID**: feature_0042_plugin_active_state  
**Status**: Implementing  
**Created**: 2026-02-13  
**Last Updated**: 2025-02-14  
**Started**: 2025-02-14  
**Assigned**: Developer Agent

## Overview
Implement user-configurable plugin activation state, allowing users to control whether a plugin is active (true/false) without removing it from the plugins directory.

## Description
This feature enables users to activate or deactivate plugins through multiple mechanisms: configuration files, command-line flags, plugin descriptors, and optional directory naming conventions. Plugins marked as inactive are not executed but remain discoverable. The system only executes plugins marked as active and meeting all runtime requirements.

**Implementation Components**:
- Plugin descriptor `active: true/false` field support
- Configuration file for global/workspace/per-analysis plugin activation settings
- Command-line flag `--deactivate-plugin <id>` or `--activate-plugin <id>`
- Optional directory naming convention (`.disabled` suffix)
- Plugin listing enhancement to show active/inactive status
- Filtering logic to skip inactive plugins during execution
- Error/warning suppression for inactive plugins

## Traceability
- **Primary**: [req_0072](../../01_vision/02_requirements/03_accepted/req_0072_plugin_disabled_state.md) - Plugin Active State (User-Configurable)
- **Related**: [req_0021](../../01_vision/02_requirements/03_accepted/req_0021_toolkit_extensibility_and_plugin_architecture.md) - Plugin Architecture
- **Related**: [req_0024](../../01_vision/02_requirements/03_accepted/req_0024_plugin_listing.md) - Plugin Listing
- **Related**: [req_0074](../../01_vision/02_requirements/03_accepted/req_0074_plugin_installation_verification.md) - Plugin Installation Verification

## Acceptance Criteria
- [x] User can set plugin `active` state via configuration file
- [x] User can set plugin `active` state via command-line flag
- [x] Plugin descriptor supports `active: true/false`
- [ ] Plugins marked as inactive are not executed but remain discoverable
- [ ] Directory naming convention (e.g., `.disabled`) disables plugin (optional)
- [x] Plugin listing shows active/inactive status
- [ ] Inactive plugins do not generate execution errors or warnings
- [ ] Documentation covers all activation/deactivation mechanisms

## Dependencies
- Plugin discovery and loading mechanism
- Plugin listing feature (feature_0003)

## Notes
- Created by Requirements Engineer Agent from accepted requirement req_0072
- Priority: Medium
- Type: Feature Enhancement

## Implementation Notes (2025-02-14)
**Status**: Core functionality complete, execution filtering pending

**Implemented**:
1. Plugin descriptor `active` field parsing (defaults to `true` if missing)
2. `--activate-plugin <name>` CLI flag
3. `--deactivate-plugin <name>` CLI flag
4. `--config <file>` flag with JSON config file support
   - Format: `{"plugins": {"plugin-name": {"active": true/false}}}`
5. ACTIVE/INACTIVE status display in plugin listing
6. Precedence: CLI > Config > Descriptor
7. PLUGINS_DIR environment variable for test isolation
8. Test suite: 20/30 tests passing

**Pending**:
- Execution filtering: Skip inactive plugins during analysis
- Error suppression for inactive plugins
- Directory naming convention (.disabled suffix) - OPTIONAL

**Files Modified**:
- `scripts/components/plugin/plugin_parser.sh` - Active field parsing
- `scripts/components/plugin/plugin_discovery.sh` - Apply overrides, PLUGINS_DIR support
- `scripts/components/plugin/plugin_display.sh` - Already had ACTIVE/INACTIVE display
- `scripts/components/ui/argument_parser.sh` - Added flags and config loading
- `tests/unit/test_plugin_active_state.sh` - Comprehensive test suite (765 lines)

**Next Steps**:
1. Implement execution filtering in plugin_executor.sh
2. Add error suppression for inactive plugins
3. Complete remaining test coverage
