# Requirement: Aggregated Reports

**ID**: req_0019  
**Title**: Aggregated Reports  
**Status**: Rejected  
**Created**: 2026-01-31  
**Rejected**: 2026-02-02  
**Category**: Functional

## Overview
The system shall generate aggregated reports that summarize analysis results across multiple files or entire directories.

## Description
In addition to per-file reports, the system must be capable of generating summary reports that aggregate data across multiple files. These reports should provide overview statistics, trends, and high-level insights about the entire analyzed directory or file collection. Aggregation leverages the metadata stored in JSON format in the workspace directory to efficiently compute statistics without re-analyzing files.

## Rejection Reason
**Decision**: Rejected by project owner.

**Rationale**: The project owner does not want aggregated reports. The focus remains on per-file analysis and reporting via req_0018 (Per-File Reports). Aggregation functionality can be deferred to downstream tools that consume the workspace metadata JSON files.

## Original Motivation
From the vision: "Renders a Markdown summary per analyzed file and/or an aggregated report."

Aggregated reports provide a "big picture" view of projects, enabling users to quickly understand overall project characteristics, identify trends, and spot outliers without reviewing individual file reports.

## Notes
- Aggregation can be performed by downstream tools consuming workspace metadata
- Per-file reports (req_0018) remain as primary output
- Workspace JSON metadata provides foundation for external aggregation tools
