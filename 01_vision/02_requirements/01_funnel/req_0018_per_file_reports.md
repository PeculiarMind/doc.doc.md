# Requirement: Per-File Reports

**ID**: req_0018  
**Title**: Per-File Reports  
**Status**: Funnel  
**Created**: 2026-01-31  
**Category**: Functional

## Overview
The system shall generate individual Markdown reports for each analyzed file.

## Description
For each file processed during directory analysis, the system must generate a separate Markdown document containing that file's metadata, content insights, and analysis results. Per-file reports enable detailed documentation of individual files while maintaining organization and traceability.

## Motivation
From the vision: "Renders a Markdown summary per analyzed file and/or an aggregated report."

Per-file reports support use cases where detailed, file-level documentation is needed, such as code review documentation, compliance records, or detailed project inventories.

## Acceptance Criteria
1. The system generates one Markdown file for each analyzed source file
2. Per-file reports contain all extracted metadata and analysis results for that specific file
3. Generated report files are named in a predictable, consistent manner (e.g., based on source file name/path)
4. Per-file reports are organized in a structured output directory
5. The system handles name collisions appropriately when multiple source files have identical names

## Dependencies
- req_0004 (Markdown Report Generation)
- req_0005 (Template-Based Reporting)

## Notes
Consider whether per-file reports should be opt-in, opt-out, or always generated. Output organization strategy needs definition.
