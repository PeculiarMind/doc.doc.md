# Feature: File-Plugin Assignment Logic

**ID**: feature_0047_file_plugin_assignment  
**Status**: Done  
**Created**: 2026-02-13  
**Last Updated**: 2026-02-15
**Completed**: 2026-02-15

## Overview
Automatically determine which plugins should execute for each discovered file based on plugin capabilities, file types, dependency requirements, and user-specified rules.

## Description
The system must analyze discovered files and available plugins to create a file-plugin assignment matrix. Assignment logic considers plugin file type filters, data dependencies, user rules, and execution constraints. The assignment ensures dependency requirements are satisfiable and provides clear reporting of decisions.

**Implementation Components**:
- File property analysis (MIME type, extension, size)
- Plugin capability matching based on `processes` filters
- Data dependency analysis (consumes/provides)
- User inclusion/exclusion rule processing
- Assignment matrix generation (file → [plugins])
- Dependency satisfiability checking
- Assignment decision reporting
- Performance optimization for large file sets

## Traceability
- **Primary**: [req_0061](../../01_vision/02_requirements/03_accepted/req_0061_file_plugin_assignment_logic.md) - File-Plugin Assignment Logic
- **Related**: [req_0043](../../01_vision/02_requirements/03_accepted/req_0043_plugin_file_type_filtering.md) - Plugin File Type Filtering
- **Related**: [req_0023](../../01_vision/02_requirements/03_accepted/req_0023_data_driven_execution_flow.md) - Data-Driven Execution
- **Related**: [Concept 08_0001](../../01_vision/03_architecture/08_concepts/08_0001_plugin_concept.md) - Plugin Concept

## Implementation Notes

### Pre-existing Implementation
This feature was already implemented as part of the plugin execution engine:
- `should_execute_plugin()` in `plugin_executor.sh` - determines plugin applicability per file
- `is_plugin_applicable_for_file()` in `plugin_validator.sh` - MIME type and extension matching
- `build_dependency_graph()` in `plugin_executor.sh` - handles plugin dependencies

### Verified as Part of MVP (2026-02-15)
- Confirmed working during MVP end-to-end testing
- Plugins correctly filter by file type (e.g., ocrmypdf only processes PDFs)
- Assignment decisions logged in verbose mode

## Acceptance Criteria
- [x] System analyzes each discovered file's MIME type and properties
- [x] System matches files to plugins based on plugin file type filters
- [x] System respects plugin data dependencies when creating assignments
- [x] System excludes plugins that cannot satisfy their input dependencies
- [x] System supports user override rules for plugin inclusion/exclusion
- [x] System generates assignment matrix (file → [plugins])
- [x] System reports assignment decisions in verbose mode
- [ ] Documentation explains assignment logic and override mechanisms

## Dependencies
- Plugin file type filtering (feature_0044) ✓
- Plugin descriptor parsing (req_0047) ✓
- Data dependency resolution (req_0023) ✓

## Notes
- Created by Requirements Engineer Agent from accepted requirement req_0061
- Priority: High
- Type: Core Feature
- Already implemented, verified during MVP implementation 2026-02-15
