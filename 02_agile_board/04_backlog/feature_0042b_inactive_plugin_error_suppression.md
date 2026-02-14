# Feature: Inactive Plugin Error Suppression

**ID**: feature_0042b_inactive_plugin_error_suppression  
**Status**: Backlog  
**Created**: 2026-02-14  
**Last Updated**: 2026-02-14  
**Assigned**: Developer Agent

## Overview
Suppress errors and warnings for plugins marked as inactive to avoid confusing users with messages about plugins they've intentionally disabled.

## Description
When a plugin is marked as inactive (via CLI, config, or descriptor), the system should not generate errors or warnings related to that plugin. This includes:
- Missing tool/dependency warnings
- Installation verification failures
- Plugin validation errors
- Execution errors

Inactive plugins should be silently skipped without cluttering the output.

**Implementation Components**:
- Identify all locations where plugin errors/warnings are generated
- Add checks for plugin activation state before logging errors
- Ensure error suppression respects the same precedence: CLI > Config > Descriptor
- Add test coverage for error suppression scenarios
- Document the behavior in user documentation

## Traceability
- **Primary**: [req_0072](../../01_vision/02_requirements/03_accepted/req_0072_plugin_disabled_state.md) - Plugin Active State (User-Configurable)
- **Continuation of**: [feature_0042](../05_implementing/feature_0042_plugin_active_state.md) - Plugin Active State Configuration
- **Related**: [req_0007](../../01_vision/02_requirements/03_accepted/req_0007_tool_availability_verification.md) - Tool Availability Verification
- **Related**: [req_0047](../../01_vision/02_requirements/03_accepted/req_0047_plugin_descriptor_validation.md) - Plugin Descriptor Validation

## Acceptance Criteria
- [ ] Inactive plugins do not generate tool availability warnings
- [ ] Inactive plugins do not generate installation verification errors
- [ ] Inactive plugins do not generate validation errors
- [ ] Inactive plugins do not generate execution errors
- [ ] Error suppression respects activation precedence (CLI > Config > Descriptor)
- [ ] System still logs inactive plugins at DEBUG level for troubleshooting
- [ ] Documentation explains error suppression behavior

## Dependencies
- feature_0042 (listing/config components)
- feature_0042a (execution filtering)
- Tool availability verification mechanism
- Plugin installation verification (feature_0043)

## Notes
- Created to address acceptance criterion in feature_0042
- This is a continuation task, not a new feature
- Priority: Medium (quality-of-life improvement)
- Type: Feature Enhancement
- Should be implemented after feature_0042a is complete

## Implementation Areas
Likely locations where error suppression is needed:
1. `plugin_tool_checker.sh` - Tool availability checks
2. `plugin_validator.sh` - Plugin descriptor validation
3. `plugin_executor.sh` - Execution errors
4. `plugin_parser.sh` - Parsing errors
5. Main orchestrator - Installation verification warnings

## Implementation Strategy
```bash
# Before logging error/warning for a plugin:
if is_plugin_active "$plugin_name"; then
  log_error "Plugin $plugin_name: $error_message"
else
  log_debug "Plugin $plugin_name (inactive): $error_message"
fi
```

## Reference
- Original requirement in: `02_agile_board/05_implementing/feature_0042_plugin_active_state.md`
- Acceptance criterion: "Inactive plugins do not generate execution errors or warnings"
