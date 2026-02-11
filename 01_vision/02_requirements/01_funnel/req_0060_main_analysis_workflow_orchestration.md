# Requirement: Main Analysis Workflow Orchestration

**ID**: req_0060
**Title**: Main Analysis Workflow Orchestration
**Status**: Funnel
**Created**: 2026-02-11
**Category**: Functional

## Overview
The system shall provide a main orchestration layer that coordinates the complete directory analysis workflow from scanning through plugin execution to report generation.

## Description
When the `-d <directory>` command is executed, the system must orchestrate a complete workflow that: (1) validates inputs and initializes workspace, (2) performs directory scanning and file discovery, (3) determines plugin assignments for discovered files, (4) executes plugins in dependency order, (5) aggregates results, and (6) generates final reports using templates. The orchestrator must handle errors gracefully, provide progress feedback, and ensure workspace consistency throughout the process.

## Motivation
From the vision: "The primary entry point is a single script that analyzes a directory and renders a Markdown report using a template." And "Automate analysis of directories and file collections with a single command."

This requirement ensures the end-to-end workflow operates correctly and provides the main entry point users expect from the single-command goal.

## Category
- Type: Functional
- Priority: Critical

## Acceptance Criteria
- [ ] System validates all required parameters (`-d`, `-m`, `-t`, `-w`) before starting analysis
- [ ] System initializes workspace directory if it doesn't exist
- [ ] System performs recursive directory scan to discover files
- [ ] System determines which plugins should run for each discovered file
- [ ] System executes plugins in dependency order as determined by execution engine
- [ ] System collects and aggregates plugin outputs into workspace
- [ ] System generates final markdown reports using specified template
- [ ] System provides progress feedback during analysis (when `-v` enabled)
- [ ] System handles errors at each stage without leaving workspace in inconsistent state
- [ ] System returns appropriate exit codes (0 for success, non-zero for failures)
- [ ] System logs the complete workflow execution for troubleshooting

## Related Requirements
- req_0001 (Single Command Directory Analysis)
- req_0002 (Recursive Directory Scanning)  
- req_0023 (Data-driven Execution Flow)
- req_0004 (Markdown Report Generation)