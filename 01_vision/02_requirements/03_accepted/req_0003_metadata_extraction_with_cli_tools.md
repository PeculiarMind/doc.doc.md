# Requirement: Metadata Extraction with CLI Tools

**ID**: req_0003  
**Title**: Metadata Extraction with CLI Tools  
**Status**: Accepted  
**Created**: 2026-01-31  
**Category**: Functional

## Overview
The system shall extract metadata and content insights from files using existing command-line tools.

## Description
The system must orchestrate existing CLI utilities to extract metadata from discovered files. This includes file properties (size, timestamps, permissions), content analysis, and format-specific metadata. The system acts as an orchestrator rather than implementing analysis logic directly.

## Motivation
From the vision: "Extracts metadata and content using existing CLI tools" and "Stay composable by integrating with common Linux tools instead of reinventing them."

This requirement ensures the toolkit remains lightweight and leverages proven, widely-available tools rather than duplicating functionality.

## Acceptance Criteria
1. The system successfully invokes at least three different CLI tools for metadata extraction (e.g., `file`, `stat`, `wc`)
2. Metadata extraction includes at minimum: file type, file size, modification timestamp, and file path
3. Extracted metadata is stored in JSON format in the workspace directory for later processing
4. The system captures and parses output from CLI tools correctly
5. Failures of individual CLI tools are handled gracefully without stopping the entire analysis
6. The system does not implement custom parsing logic for file formats when CLI tools are available
7. Stored metadata in JSON format can be easily consumed by downstream tools and processes

## Dependencies
- req_0002 (Recursive Directory Scanning)

## Notes
The specific CLI tools used may vary based on file types and available system utilities.
