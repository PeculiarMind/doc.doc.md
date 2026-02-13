# Requirement: Plugin Installation Verification Before Execution
ID: req_0074_plugin_installation_verification

## Status
State: Accepted
Created: 2026-02-13
Last Updated: 2026-02-13

## Overview
Before executing any plugin, the system must verify that the plugin is installed using the command specified in its descriptor.

## Description
When a plugin is marked as "active": true in its descriptor, the system must check that the required command or tool for the plugin is installed before attempting execution. This check must be performed during the initialization phase of `doc.doc.sh`, before the file-based analyzation phase starts. The check should use the command or method defined in the plugin's descriptor (e.g., via a command-line check or install script). If the plugin is not installed, execution must be skipped or fail gracefully with a clear error message. All plugins that are active but not installed must be listed and reported to the user before analysis begins. This approach is crucial for performance, as it avoids unnecessary checks during per-file analysis and provides immediate feedback on missing dependencies.

## Motivation
- Prevents runtime errors due to missing plugin dependencies
- Ensures only functional plugins are executed
- Improves user experience and reliability
- Maximizes performance by avoiding repeated checks during file analysis
- Provides early, actionable feedback on missing plugins

## Category
- Type: Functional
- Priority: High

## Acceptance Criteria
- [ ] System checks for plugin installation during the initialization phase, before file-based analysis
- [ ] Uses the command or method defined in the plugin descriptor
- [ ] Skips or fails gracefully if plugin is not installed
- [ ] All active but not installed plugins are listed and reported to the user before analysis
- [ ] Clear error or warning is provided to the user

## Related Requirements
- req_0021_plugin_based_extensibility
- req_0047_plugin_descriptor_validation
- req_0072_plugin_disabled_state

---

**Architect Advice:**
- Please create or update architecture concepts to describe the initialization and plugin verification process.
- If this requirement introduces or changes architectural decisions, document them as Architecture Decision Records (ADRs) as needed.
