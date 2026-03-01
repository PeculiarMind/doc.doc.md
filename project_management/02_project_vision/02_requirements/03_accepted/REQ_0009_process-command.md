# Requirement: Process Command

- **ID:** REQ_0009
- **State:** Accepted
- **Type:** Functional
- **Priority:** Critical
- **Created at:** 2026-02-25
- **Last Updated:** 2026-02-25

## Overview
The system shall provide a 'process' command for document processing with support for input/output directories, templates, and filtering.

## Description
The tool must implement a `process` command that processes documents from an input directory and generates markdown files in an output directory according to specified criteria. The command supports the following parameters:

### Required Parameters
- `--input-directory` / `-d`: The directory containing the documents to be processed
- `--output-directory` / `-o`: The directory where the generated markdown files will be saved (input directory structure will be mirrored)

### Optional Parameters
- `--template` / `-t`: The path to the markdown template used for generating the markdown files (default: built-in template)
- `--include` / `-i`: A comma-separated list of file extensions, glob patterns, or MIME types to include in the processing (can be specified multiple times)
- `--exclude` / `-e`: A comma-separated list of file extensions, glob patterns, or MIME types to exclude from the processing (can be specified multiple times)

### Filter Criteria Types
Each include and exclude parameter can contain:
- File extensions (e.g., `.txt`, `.md`, `.log`)
- Glob patterns (e.g., `**/2024/**`, `**/temp/**`)
- MIME types (e.g., `application/pdf`, `text/plain`)

### Filter Logic
- Values within a single `--include` parameter are **ORed** together (file matches if it satisfies at least one criterion)
- Multiple `--include` parameters are **ANDed** together (file must match at least one criterion from each parameter)
- Values within a single `--exclude` parameter are **ORed** together (file is excluded if it matches at least one criterion)
- Multiple `--exclude` parameters are **ANDed** together (file is excluded only if it matches at least one criterion from each parameter)

## Motivation
Derived from [project_management/02_project_vision/01_project_goals/project_goals.md](../../01_project_goals/project_goals.md):
- "**Command:** `doc.doc.sh process`" with complete parameter table
- "The script processes documents in the input directory according to the specified criteria and generates markdown files in the output directory, mirroring the input directory structure."
- Detailed filtering logic and examples

## Acceptance Criteria
- [ ] Command can be invoked as `doc.doc.sh process`
- [ ] Required `--input-directory` / `-d` parameter is validated and accepts valid directory paths
- [ ] Required `--output-directory` / `-o` parameter is validated and creates output directory if needed
- [ ] Optional `--template` / `-t` parameter uses specified template or built-in default
- [ ] Optional `--include` / `-i` parameters support file extensions, glob patterns, and MIME types
- [ ] Optional `--exclude` / `-e` parameters support file extensions, glob patterns, and MIME types
- [ ] Multiple include and exclude parameters can be specified
- [ ] Values within single parameters are comma-separated
- [ ] File extension filtering works correctly (e.g., `.txt`, `.md`)
- [ ] Glob pattern filtering works correctly (e.g., `**/2024/**`)
- [ ] MIME type filtering works correctly (e.g., `application/pdf`)
- [ ] OR logic works correctly within single include/exclude parameters
- [ ] AND logic works correctly between multiple include/exclude parameters
- [ ] Combined include and exclude filters work as specified
- [ ] Directory structure is mirrored from input to output
- [ ] Generated files are in markdown format
- [ ] Invalid parameters show clear error messages
- [ ] Examples from project goals produce expected results

## Related Requirements
- REQ_0007 (Markdown Output Format)
- REQ_0013 (Directory Structure Mirroring)
