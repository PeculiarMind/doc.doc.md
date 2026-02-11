# Requirement: File-Plugin Assignment Logic

**ID**: req_0061
**Title**: File-Plugin Assignment Logic  
**Status**: Funnel
**Created**: 2026-02-11
**Category**: Functional

## Overview
The system shall automatically determine which plugins should execute for each discovered file based on plugin capabilities, file types, and dependency requirements.

## Description
The system must analyze discovered files and available plugins to create a file-plugin assignment matrix that determines which plugins will execute for each file. Assignment logic must consider: (1) plugin file type filters and MIME type compatibility, (2) plugin data dependencies, (3) user-specified plugin inclusion/exclusion rules, and (4) plugin execution constraints. The assignment must ensure dependency requirements are satisfiable and provide clear reporting of assignment decisions.

## Motivation
From the vision: "Plugin‑based extensibility where each plugin declares what information it consumes and what information it provides" and "The toolkit automatically determines the optimal plugin execution order by analyzing these dependencies."

This requirement implements the intelligence layer that matches files with appropriate analysis capabilities while respecting dependency constraints.

## Category
- Type: Functional
- Priority: High

## Acceptance Criteria  
- [ ] System analyzes each discovered file's MIME type and properties
- [ ] System matches files to plugins based on plugin file type filters
- [ ] System respects plugin data dependencies when creating assignments
- [ ] System excludes plugins that cannot satisfy their input dependencies
- [ ] System supports user override rules for plugin inclusion/exclusion per file type
- [ ] System logs assignment decisions for each file-plugin combination
- [ ] System detects and reports unsatisfiable dependency chains
- [ ] System optimizes assignments to minimize redundant plugin executions
- [ ] Assignment process completes efficiently even for large file sets (1000+ files)
- [ ] System provides clear error messages when no plugins can process a file type

## Related Requirements
- req_0043 (Plugin File Type Filtering)
- req_0023 (Data-driven Execution Flow)
- req_0022 (Plugin-based Extensibility)