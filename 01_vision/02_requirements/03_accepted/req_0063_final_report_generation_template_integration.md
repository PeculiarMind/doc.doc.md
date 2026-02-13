# Requirement: Final Report Generation and Template Integration

**ID**: req_0063
**Title**: Final Report Generation and Template Integration
**Status**: Accepted
**Created**: 2026-02-11
**Last Updated**: 2026-02-13
**Category**: Functional

## Overview
The system shall generate final Markdown reports by applying user-specified templates to aggregated workspace data, producing both per-file and aggregated summary reports.

## Description
The system must implement final report generation that: (1) applies user-specified Markdown templates to workspace data using template engine, (2) generates per-file reports in target directory with consistent naming, (3) creates aggregated summary reports combining data from multiple files, (4) handles template errors and missing data gracefully, (5) supports template inheritance and includes for consistency, and (6) ensures output directory structure matches user expectations. The generation process must be efficient for large data sets and provide clear feedback on template processing errors.

## Motivation
From the vision: "Renders Markdown reports to the target directory per analyzed file and/or an aggregated report" and "Uses the specified template for report formatting."

This requirement delivers the final user-visible output that provides value from the analysis process.

## Category
- Type: Functional
- Priority: Critical

## Acceptance Criteria
- [ ] System loads and validates user-specified template files before processing
- [ ] System applies templates to workspace data using template engine (req_0040)
- [ ] System generates per-file Markdown reports in target directory
- [ ] System creates aggregated summary reports combining multi-file data  
- [ ] System maintains consistent file naming and directory structure in output
- [ ] System handles missing or incomplete data gracefully in template processing
- [ ] System provides meaningful error messages for template syntax or data errors
- [ ] Generated reports are valid Markdown that renders correctly in standard viewers
- [ ] Report generation completes efficiently for large workspaces (1000+ files)
- [ ] System supports template includes/imports for modular report design

## Related Requirements
- req_0004 (Markdown Report Generation)
- req_0005 (Template-based Reporting)
- req_0040 (Template Engine Implementation)
- req_0018 (Per File Reports)
- req_0039 (Aggregated Summary Reports)