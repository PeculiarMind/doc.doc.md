# Bug: Stat Plugin Output Data Formatting Issues

**ID**: 0003  
**Type**: Bug Fix  
**Status**: Backlog  
**Created**: 2026-02-12  
**Priority**: High  
**Severity**: Medium

## Overview
The stat plugin's workspace output has incorrect field mappings (file owner and filesize appear swapped) and inconsistent timestamp formatting compared to execution timestamps.

## Description
The stat plugin (feature_0020) is writing data to the workspace JSON files with formatting problems:

1. **Swapped fields**: File owner information appears in the filesize field and vice versa
2. **Inconsistent timestamps**: File modified timestamps use a different format than execution timestamps

This creates incorrect and confusing data in the workspace, making downstream report generation unreliable and data interpretation difficult.

## Business Impact
- **Data accuracy**: Reports will show incorrect file sizes and ownership information
- **User trust**: Incorrect data undermines confidence in the tool's analysis
- **Report quality**: Generated documentation contains misleading information
- **Format inconsistency**: Mixed timestamp formats make data harder to process

## Bug Details

### Expected Behavior
Workspace JSON should contain:
- **File owner**: User/group ownership in appropriate field
- **File size**: Numeric size in bytes in appropriate field  
- **Modified timestamp**: Formatted consistently with execution timestamps (ISO 8601 or similar)
- All fields correctly labeled and mapped

### Actual Behavior
- File owner data appears in filesize field
- File size data appears in owner field
- File modified timestamp uses different format from execution timestamp
- Data mapping is swapped/incorrect

### Reproduction Steps
1. Run `./scripts/doc.doc.sh -d <directory> -m <template> -t <output> -w <workspace>`
2. Open workspace JSON file for a processed file
3. Examine stat plugin output fields
4. Observe owner/size swap and timestamp format inconsistency

### Environment
- **Plugin**: stat plugin (feature_0020)
- **Workspace structure**: JSON files in `workspace/files/`
- **Related component**: Plugin execution engine data collection

### Error Analysis
- **Field mapping error**: Stat command output being parsed/mapped incorrectly
- **Order mismatch**: Field positions in stat output not matching JSON field assignments
- **Timestamp conversion**: Different formatting logic for file times vs execution times

## Root Cause Investigation
Likely causes:
1. **Stat output parsing**: Incorrect field index or delimiter parsing from `stat` command
2. **JSON field assignment**: Wrong variable assigned to wrong field in workspace JSON
3. **Timestamp formatting**: Missing date format standardization in stat plugin

## Acceptance Criteria
- [ ] File owner information appears in correct field (not filesize field)
- [ ] File size information appears in correct field (not owner field)
- [ ] File modified timestamp uses same format as execution timestamp
- [ ] All existing stat plugin data remains accurate  
- [ ] Field labels in JSON correctly match their contents
- [ ] Timestamp format is consistent across all workspace data

## Related Requirements
- [req_0025](../../01_vision/02_requirements/03_accepted/req_0025_file_metadata_collection.md) - File Metadata Collection (if exists)
- Data accuracy and integrity requirements

## Dependencies
- **Critical fix for**: feature_0020_stat_plugin (broken output)
- **Affects**: Report generation quality and accuracy
- **Affects**: Template rendering with correct data

## Investigation Required
1. Review stat plugin implementation for field mapping logic
2. Verify `stat` command output format and parsing
3. Check JSON field assignment in plugin result collection
4. Standardize timestamp formatting across all plugins
5. Add validation to detect field type mismatches

## Definition of Done
- [ ] File size shows numeric bytes, not owner information
- [ ] File owner shows user/group, not size information
- [ ] Timestamp formats consistent across workspace JSON
- [ ] Manual verification of workspace data accuracy
- [ ] Test cases covering various file types and ownership scenarios
- [ ] Existing workspace data migration or regeneration guidance provided
