# Feature: Single-File Analysis Mode

**ID**: feature_0051_single_file_analysis  
**Status**: Implementing  
**Created**: 2026-02-14  
**Last Updated**: 2026-02-14
**Started**: 2026-02-14
**Assigned**: Developer Agent

## Overview
Support analyzing a single file instead of an entire directory, enabling targeted plugin execution on specific files.

## Description
Currently, doc.doc.sh only supports directory-based analysis via the `-d <directory>` flag. There is no mechanism to analyze a single file directly. The `-f` flag is currently used for "force full scan" mode.

The test `test_active_plugins_are_executed` in `tests/unit/test_plugin_active_state.sh` (test 21) expects `-f <file>` to analyze a single file with active plugins. This is a reasonable user expectation — users should be able to quickly analyze one file without scanning an entire directory.

**Implementation Components**:
- New CLI flag for single-file analysis (e.g., `--file <path>` or repurpose `-f` with argument detection)
- Single-file orchestration path (skip directory scanning)
- MIME type detection for the single file
- Plugin execution for the single file
- Report generation for single-file results
- Workspace integration for single-file analysis

## Acceptance Criteria
- [ ] Users can analyze a single file via CLI
- [ ] Active plugins are executed on the specified file
- [ ] MIME type is correctly detected for the file
- [ ] Results are generated in the target directory
- [ ] Non-existent file paths produce clear error messages
- [ ] Single-file mode works with `--activate-plugin` and `--deactivate-plugin` flags
- [ ] Test `test_active_plugins_are_executed` passes

## Dependencies
- Plugin execution engine (feature_0009)
- Plugin active state management (feature_0042)

## Notes
- Created from test analysis: `tests/unit/test_plugin_active_state.sh` test 21 fails due to this missing feature
- The current `-f` flag is used for force full scan; a new flag or argument detection needed
- Priority: Medium
- Type: Feature Enhancement
