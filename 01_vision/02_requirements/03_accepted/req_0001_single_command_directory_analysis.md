# Requirement: Single Command Directory Analysis

**ID**: req_0001  
**Title**: Single Command Directory Analysis  
**Status**: Accepted  
**Created**: 2026-01-31  
**Category**: Functional

## Overview
The system shall provide a single command-line interface to analyze an entire directory and its contents automatically.

## Description
Users must be able to execute a single command that triggers the complete analysis workflow for a specified directory. The command shall accept the directory path, template, target directory, and workspace directory as parameters and orchestrate all necessary analysis operations without requiring additional user intervention. The command acts as a scriptable entry point that coordinates metadata extraction, workspace storage, and report generation.

## Motivation
From the vision: "Automate analysis of directories and file collections with a single command."

This requirement addresses the core goal of automation, enabling users to analyze complex directory structures efficiently without manual, per-file operations.

## Acceptance Criteria
1. The system provides a command-line script (e.g., `./doc.doc.sh`) that accepts required parameters:
   - `-d` for source directory path to analyze
   - `-m` for template file path for report formatting
   - `-t` for target output directory for Markdown reports
   - `-w` for workspace directory for metadata and state storage
   - `-v` optional flag for verbose logging during analysis
2. Executing the command successfully initiates analysis of all files within the source directory
3. The analysis completes without requiring additional user commands or manual file-by-file processing
4. Document metadata and scan state are stored in the workspace directory (`-w`) as JSON files
5. Scan timestamps are recorded for incremental analysis support
6. Markdown reports are rendered to the target directory (`-t`) for each analyzed file
7. The command uses the specified template (`-m`) for report formatting
8. Verbose mode (`-v`) enables detailed logging of the analysis process
9. The command returns appropriate exit codes (0 for success, non-zero for failure)
10. Invalid parameters or missing directories produce clear error messages without starting analysis

## Dependencies
None

## Notes
This is the foundational requirement that enables the automation goal. All other functional requirements build upon this single-command interface.
