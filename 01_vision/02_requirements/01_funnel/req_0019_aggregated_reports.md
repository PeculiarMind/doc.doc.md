# Requirement: Aggregated Reports

**ID**: req_0019  
**Title**: Aggregated Reports  
**Status**: Funnel  
**Created**: 2026-01-31  
**Category**: Functional

## Overview
The system shall generate aggregated reports that summarize analysis results across multiple files or entire directories.

## Description
In addition to per-file reports, the system must be capable of generating summary reports that aggregate data across multiple files. These reports should provide overview statistics, trends, and high-level insights about the entire analyzed directory or file collection.

## Motivation
From the vision: "Renders a Markdown summary per analyzed file and/or an aggregated report."

Aggregated reports provide a "big picture" view of projects, enabling users to quickly understand overall project characteristics, identify trends, and spot outliers without reviewing individual file reports.

## Acceptance Criteria
1. The system generates at least one aggregated report per analysis run
2. Aggregated reports include summary statistics (e.g., total files analyzed, file type distribution, total size)
3. The report presents aggregated data in a clear, organized format using appropriate Markdown elements
4. Aggregated reports link to or reference individual file reports when applicable
5. The aggregation process handles large directories (10,000+ files) without excessive memory consumption

## Dependencies
- req_0004 (Markdown Report Generation)
- req_0018 (Per-File Reports)

## Notes
Consider what aggregation metrics are most valuable: file type distribution, size statistics, date ranges, complexity metrics, etc.
