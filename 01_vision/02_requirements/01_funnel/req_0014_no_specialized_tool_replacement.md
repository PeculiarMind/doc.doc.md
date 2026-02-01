# Requirement: No Specialized Tool Replacement

**ID**: req_0014  
**Title**: No Specialized Tool Replacement  
**Status**: Funnel  
**Created**: 2026-01-31  
**Category**: Constraint

## Overview
The system shall not attempt to replace or duplicate the functionality of existing specialized analysis tools.

## Description
The toolkit must focus on orchestration, integration, and reporting rather than reimplementing analysis logic. When specialized tools exist for specific file types or analysis tasks (e.g., linters, parsers, formatters), the system should invoke those tools rather than creating its own implementations. This maintains the "lightweight" and "composable" principles.

## Motivation
From the vision: "Non‑Goals: Replacing specialized analysis tools."

This constraint ensures the project remains focused on its core value proposition—orchestration and standardized reporting—rather than expanding into an unwieldy collection of analysis implementations.

## Acceptance Criteria
1. The system leverages existing CLI tools for all format-specific analysis (e.g., uses `jq` for JSON, `xmllint` for XML)
2. No custom file format parsers are implemented when standard tools are available
3. The codebase does not include reimplementations of functionality provided by common UNIX utilities
4. When evaluating new features, the system preferentially integrates existing tools over custom implementation
5. Documentation explicitly describes the system as an orchestrator rather than an analysis engine

## Dependencies
- req_0003 (Metadata Extraction with CLI Tools)
- req_0010 (UNIX Tool Composability)

## Notes
This constraint guides architectural decisions and helps maintain project scope. Custom logic is acceptable only when no suitable existing tool is available.
