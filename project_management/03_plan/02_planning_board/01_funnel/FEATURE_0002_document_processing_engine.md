# Document Processing Engine

- **ID:** FEATURE_0002
- **Priority:** High
- **Type:** Feature
- **Created at:** 2026-02-27
- **Created by:** Requirements Engineer
- **Status:** FUNNEL

## Overview

As a **user**, I want to **process document collections with flexible filtering and template-based output** so that I can **generate well-organized markdown documentation from my files**.

This feature implements the core document processing capability, including the `process` command with comprehensive filtering options, template-based markdown generation, and directory structure preservation.

## User Value

- Process entire document collections automatically
- Filter documents by extension, path patterns, or MIME types
- Generate consistent markdown output using templates
- Preserve directory organization from source to output
- Support complex filtering logic for precise document selection

## Scope

### In Scope
- `process` command implementation
- Input/output directory handling with structure mirroring
- File filtering engine (extensions, glob patterns, MIME types)
- Complex AND/OR filter logic as specified
- Template processing for markdown generation
- Progress indication during processing
- Markdown output with Obsidian compatibility

### Out of Scope
- Plugin execution during processing (FEATURE_0003)
- Security hardening (FEATURE_0004)
- Template authoring documentation (FEATURE_0005)

## Acceptance Criteria

- [ ] Command invocable as `doc.doc.sh process --input-directory <dir> --output-directory <dir>`
- [ ] Required parameters (--input-directory, --output-directory) validated
- [ ] Optional --template parameter accepts custom template path or uses built-in default
- [ ] Multiple --include parameters can be specified with comma-separated values
- [ ] Multiple --exclude parameters can be specified with comma-separated values
- [ ] File extension filtering works correctly (e.g., `.txt`, `.md`)
- [ ] Glob pattern filtering works correctly (e.g., `**/2024/**`, `**/temp/**`)
- [ ] MIME type filtering works correctly (e.g., `application/pdf`)
- [ ] OR logic: values within single --include parameter are ORed
- [ ] AND logic: multiple --include parameters are ANDed
- [ ] OR logic: values within single --exclude parameter are ORed
- [ ] AND logic: multiple --exclude parameters are ANDed
- [ ] Input directory structure is mirrored to output directory
- [ ] Generated files have .md extension and valid markdown syntax
- [ ] Output is compatible with Obsidian
- [ ] Progress indication shows files being processed
- [ ] Summary report shows files processed, skipped, errors
- [ ] Examples from project goals produce expected results

## Technical Details

### Architecture Alignment
- **Building Block**: Filter Engine (filter.py), Template Processing (templates.sh)
- **ADR References**: ADR-002 (Reuse Existing Tools - use `file` command for MIME detection)
- **Quality Goals**: Reliability (QS-R02), Flexibility (QS-F01, QS-F02)
- **Crosscutting Concepts**: Filtering Logic, Template Processing

### Implementation Approach
- **Bash** for command orchestration and directory traversal
- **Python** for complex filter logic evaluation
- **file command** for MIME type detection
- **find** for file discovery
- Template variable substitution using bash string manipulation

### Filter Algorithm (from Architecture)
```
1. Discover all files in input directory
2. For each file:
   a. Evaluate all --include parameters (AND across parameters)
   b. If any --include: file must match at least one criterion per parameter
   c. Evaluate all --exclude parameters (AND across parameters)
   d. If any --exclude: file excluded only if matches criterion in each parameter
   e. If passes filters: add to processing queue
3. Process queue with template
```

### Complexity
**Large (L)**: Complex filtering algorithm, Python integration, template processing

## Dependencies

### Blocked By
- FEATURE_0001 (Core CLI Framework) - requires CLI parsing and validation

### Blocks
None (other features can develop in parallel)

### Optional Integration
- Can be enhanced later with plugin execution (FEATURE_0003)

## Related Requirements

### Functional Requirements
- REQ_0007: Markdown Output Format
  - Generated files use .md extension
  - Output follows standard markdown syntax
  
- REQ_0008: Obsidian Compatibility
  - Markdown compatible with Obsidian's parser
  
- REQ_0009: Process Command
  - All parameters and filtering logic as specified
  - Input/output directory handling
  - Template support
  
- REQ_0013: Directory Structure Mirroring
  - Preserve relative paths and directory structure

### Security Requirements
- REQ_SEC_001: Input Validation and Sanitization
  - Validate directory paths
  
- REQ_SEC_002: Filter Logic Correctness
  - Prevent filter bypass
  - Regex DoS protection with timeouts
  
- REQ_SEC_004: Template Injection Prevention
  - Safe string substitution only (no eval/exec)
  
- REQ_SEC_005: Path Traversal Prevention
  - Canonicalize paths, validate boundaries
  - Symlink protection

## Related Links

- Architecture Vision: [06_runtime_view](../../../02_project_vision/03_architecture_vision/06_runtime_view/06_runtime_view.md)
- Architecture Vision: [08_concepts](../../../02_project_vision/03_architecture_vision/08_concepts/08_concepts.md)
- Requirements: [REQ_0007](../../../02_project_vision/02_requirements/01_funnel/REQ_0007_markdown-output.md)
- Requirements: [REQ_0008](../../../02_project_vision/02_requirements/01_funnel/REQ_0008_obsidian-compatibility.md)
- Requirements: [REQ_0009](../../../02_project_vision/02_requirements/01_funnel/REQ_0009_process-command.md)
- Requirements: [REQ_0013](../../../02_project_vision/02_requirements/01_funnel/REQ_0013_directory-mirroring.md)
- Requirements: [REQ_SEC_002](../../../02_project_vision/02_requirements/01_funnel/REQ_SEC_002_filter_logic_correctness.md)
- Requirements: [REQ_SEC_004](../../../02_project_vision/02_requirements/01_funnel/REQ_SEC_004_template_injection_prevention.md)
- Requirements: [REQ_SEC_005](../../../02_project_vision/02_requirements/01_funnel/REQ_SEC_005_path_traversal_prevention.md)

## Implementation Notes

### Component Structure
```
doc.doc.md/
├── components/
│   ├── filter.py           # Filter logic engine
│   └── templates.sh        # Template processing
└── templates/
    └── default.md          # Built-in default template
```

### Filter Test Cases (from Project Goals)
Must pass all 8 examples from project goals document showing:
- Extension + path matching
- Exclude with AND logic
- Complex multi-criteria filtering

### Quality Checklist
- [ ] All 8 filter examples from project goals pass
- [ ] Python filter engine has unit tests
- [ ] Template injection attempts fail safely
- [ ] Path traversal attempts are blocked
- [ ] Symlinks handled securely
- [ ] MIME type detection works for common formats
- [ ] Performance acceptable for 1000+ files
- [ ] Error handling graceful (bad templates, permission errors)
- [ ] Integration tests with various directory structures
