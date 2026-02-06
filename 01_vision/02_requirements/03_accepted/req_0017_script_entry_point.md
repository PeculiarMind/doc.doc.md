# Requirement: Script Entry Point

**ID**: req_0017  
**Title**: Script Entry Point  
**Status**: Accepted  
**Created**: 2026-01-31  
**Category**: Functional

## Overview
The system shall provide a shell script named `doc.doc.sh` as the primary entry point for all operations.

## Description
Users must interact with the system through a single, clearly-named shell script that serves as the main executable. This script should handle command-line argument parsing, tool verification, analysis orchestration, and report generation. The script name and location should be predictable and consistent across installations.

## Motivation
From the vision: "The primary entry point is a single script" and example command: `./doc.doc.sh -d <directory_to_analyze> -m <report_template> [-v]`.

A single, well-named entry point simplifies usage, documentation, and integration into workflows. It provides a clear, discoverable interface for new users.

## Acceptance Criteria
1. A file named `doc.doc.sh` exists in the project root directory
2. The script is executable (has appropriate permissions set)
3. The script accepts the documented command-line parameters (`-d`, `-m`, `-v`)
4. Invoking the script without parameters displays usage information
5. The script can be executed from any working directory when using its full or relative path

## Dependencies
- req_0001 (Single Command Directory Analysis)

## Notes
The `.sh` extension clearly indicates this is a shell script. Consider supporting symbolic linking to system paths for system-wide installation.
