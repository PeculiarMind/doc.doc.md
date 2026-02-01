# Requirement: Minimal Runtime Dependencies

**ID**: req_0015  
**Title**: Minimal Runtime Dependencies  
**Status**: Funnel  
**Created**: 2026-01-31  
**Category**: Constraint

## Overview
The system shall minimize runtime dependencies beyond common CLI utilities that are typically available on UNIX-like systems.

## Description
The core toolkit should rely primarily on standard UNIX utilities that are commonly pre-installed on most Linux and macOS systems. When additional tools are required for specific file types or analysis tasks, they should be optional dependencies that are only required when analyzing those specific file types, not for basic operation.

## Motivation
From the vision: "Non‑Goals: Providing heavy runtime dependencies beyond common CLI utilities."

Minimal dependencies reduce installation complexity, improve portability across different systems, and decrease the risk of version conflicts or dependency management issues.

## Acceptance Criteria
1. The core functionality requires only tools commonly available in standard UNIX environments (e.g., `bash`, `sed`, `awk`, `grep`)
2. Optional analysis features may require additional tools, but these are not mandatory for basic operation
3. The system provides clear documentation of required vs. optional dependencies
4. Installation on a fresh Linux or macOS system requires installing fewer than 5 additional packages for basic functionality
5. Dependencies are limited to tools available through standard package managers

## Dependencies
- req_0009 (Lightweight Implementation)

## Notes
"Common CLI utilities" includes tools typically in coreutils, findutils, and similar standard packages. The exact list should be documented.
