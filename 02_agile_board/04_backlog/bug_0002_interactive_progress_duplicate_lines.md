# Bug: Interactive Mode Showing Duplicate Plugin Execution Lines

**ID**: 0002  
**Type**: Bug Fix  
**Status**: Backlog  
**Created**: 2026-02-12  
**Priority**: Medium  
**Severity**: Low

## Overview
In interactive mode, "Executing plugin: stat" messages appear multiple times in separate rows instead of being handled on the same row with progress updates.

## Description
When running the script in interactive mode, the progress display shows "Executing plugin: stat" appearing multiple times on separate rows rather than updating the same row with progress information. This creates unnecessary vertical scrolling and makes it difficult to track actual progress through the file list.

The interactive progress system (feature_0017) is designed to provide clean, single-row updates for each operation, but the stat plugin execution is creating new lines for each file instead of reusing the same display row.

## Business Impact
- **User experience degradation**: Cluttered terminal output makes progress hard to follow
- **Readability issues**: Excessive scrolling obscures important information
- **Professional appearance**: Makes the tool appear less polished

## Bug Details

### Expected Behavior
Interactive mode should:
1. Show "Executing plugin: stat" on a single row
2. Update that row with current file being processed
3. Use carriage return or similar mechanism to rewrite the same line
4. Maintain clean, compact progress display

### Actual Behavior
- "Executing plugin: stat" appears multiple times
- Each appearance is on a new row
- Terminal fills with duplicate messages
- Progress information is spread across many lines

### Reproduction Steps
1. Run `./scripts/doc.doc.sh -d <directory> -m <template> -t <output> -w <workspace>` in interactive mode
2. Observe the terminal output during plugin execution
3. Notice "Executing plugin: stat" appearing on multiple separate rows

### Environment
- **Mode**: Interactive mode (default/verbose)
- **Related feature**: feature_0017_interactive_progress_display
- **Related component**: Plugin execution engine (feature_0009)
- **Plugin affected**: stat plugin (feature_0020)

### Error Analysis
- **Progress display logic**: Likely not using carriage return properly
- **Plugin execution messaging**: May be calling display function incorrectly
- **Line management**: Not tracking/reusing display rows as intended

## Acceptance Criteria
- [ ] "Executing plugin: stat" updates on the same row in interactive mode
- [ ] Progress shows which file is currently being processed
- [ ] No duplicate/repeated plugin execution messages on separate rows
- [ ] Terminal output remains clean and readable
- [ ] Non-interactive mode output unaffected

## Investigation Required
1. Review interactive progress display component implementation
2. Check how plugin execution engine reports progress
3. Verify carriage return (\r) usage for same-row updates
4. Ensure proper ANSI escape codes for line clearing/updating

## Related Requirements
- [req_0026](../../01_vision/02_requirements/03_accepted/req_0026_interactive_progress_display.md) - Interactive Progress Display

## Dependencies
- **Bug in**: [feature_0017_interactive_progress_display](../06_done/feature_0017_interactive_progress_display.md) - Status: **Done** (implementation issue)
- **Related**: [feature_0009_plugin_execution_engine](../06_done/feature_0009_plugin_execution_engine.md) - Status: **Done** (execution reporting)
- **Related**: [feature_0020_stat_plugin](../06_done/feature_0020_stat_plugin.md) - Status: **Done** (affected plugin)

## Analysis Summary
This is an implementation bug in feature_0017 which is marked as Done. The interactive progress display logic was implemented but has a defect where plugin execution messages create new lines instead of updating the same row. All related features (0009, 0017, 0020) are completed, so this is a straightforward bug fix in existing code.

## Definition of Done
- [ ] Interactive mode shows clean, single-row progress updates
- [ ] Plugin execution messages do not duplicate on separate rows
- [ ] Terminal output is readable and professional
- [ ] Verification with multiple plugins confirms consistent behavior
- [ ] Non-interactive mode remains functional
