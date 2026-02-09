# Requirement: Aggregated Summary Reports

**ID**: req_0039

## Status
State: Accepted  
Created: 2026-02-09  
Last Updated: 2026-02-09

## Overview
The system shall provide an optional aggregated summary report feature that consolidates analysis results across all analyzed files when explicitly requested by the user.

## Description
While req_0004 and req_0018 address per-file Markdown report generation, the vision explicitly mentions: "Renders Markdown reports to the target directory (`-t`) per analyzed file **and/or an aggregated report**." Users analyzing large document collections may optionally request summary views showing statistics, trends, and insights across the entire corpus. Aggregated reports are opt-in to avoid unnecessary overhead for users performing single-file analysis or those with specific workflows that don't require corpus-level summaries.

When enabled, aggregated reports include: total file counts by type, size distributions, summary statistics, list of all analyzed files with key metadata, and any cross-file insights that plugins can provide. The aggregated report format should be customizable via template similar to per-file reports.

**Rationale for Opt-In Approach**:
- Not all users need corpus-level summaries (e.g., single-file analyses, targeted workflows)
- Reduces default processing overhead and complexity
- Explicit opt-in makes behavior predictable and controllable
- Aligns with Unix philosophy: do one thing well by default, provide options for extended functionality
- Minimizes resource usage when aggregation is unnecessary

## Motivation
From vision (01_vision.md): "Renders Markdown reports to the target directory (`-t`) per analyzed file and/or an aggregated report."

From quality scenario U5: Users should be able to create custom templates including aggregated views.

Aggregated reports serve multiple use cases:
- **Executive summaries**: High-level overview for stakeholders
- **Corpus analysis**: Understanding document collection characteristics
- **Compliance reporting**: Demonstrating coverage and completeness
- **Quality monitoring**: Tracking metrics over time across repository

## Category
- Type: Functional
- Priority: Medium

## Acceptance Criteria

### Opt-In Behavior
- [ ] Aggregated report generation is **disabled by default**
- [ ] Command-line flag `-s` or `--summary` enables aggregated report generation
- [ ] Flag accepts optional template path: `--summary=<template>` or `-s <template>`
- [ ] Without flag, system generates only per-file reports
- [ ] Help documentation clearly indicates opt-in nature

### Aggregated Report Generation (When Enabled)
- [ ] System generates a summary/index report at the root of the target directory (e.g., `index.md` or `summary.md`)
- [ ] Aggregated report includes total file count analyzed
- [ ] Aggregated report includes file count breakdown by MIME type
- [ ] Aggregated report includes total size of analyzed files (bytes and human-readable)
- [ ] Aggregated report includes size distribution statistics (min, max, average, median)
- [ ] Aggregated report includes list of all analyzed files with links to their individual reports
- [ ] Aggregated report includes timestamps showing when analysis was performed
- [ ] Aggregated report includes workspace location reference

### Template Support
- [ ] Aggregated report uses separate template file (e.g., `template.summary.md`)
- [ ] Template receives aggregated statistics variables (total_files, total_size, file_types_summary, etc.)
- [ ] Template can iterate over file list to generate table of contents or file listing
- [ ] Default aggregated template provided with toolkit
- [ ] Users can specify custom aggregated template via command-line option (e.g., `-s <summary_template>`)

### Data Collection
- [ ] When aggregated report disabled: minimal statistics collection (only per-file essentials)
- [ ] When aggregated report enabled: system collects corpus-level statistics during analysis run (incremental accumulation)
- [ ] Statistics stored in workspace metadata only when aggregated report requested (workspace.json or summary.json)
- [ ] Statistics include per-type counts, size metrics, and plugin execution summary
- [ ] Cross-file insights from plugins included if provided (e.g., duplicate detection, common tags)

### Performance
- [ ] Aggregated report generation adds minimal overhead (< 5% of total runtime)
- [ ] Statistics collection happens incrementally, not in separate pass
- [ ] Memory usage for statistics tracking remains constant regardless of file count

### Integration
- [ ] Aggregated report (when enabled) references per-file reports with relative paths
- [ ] Aggregated report includes metadata from workspace allowing external tool integration
- [ ] Verbose mode logs aggregated report generation progress when feature is enabled
- [ ] Verbose mode confirms when aggregated report is skipped (default behavior)

## Related Requirements
- req_0004 (Markdown Report Generation) - aggregated report also generated as Markdown
- req_0018 (Per-File Reports) - aggregated report complements per-file reports
- req_0005 (Template-Based Reporting) - aggregated report uses template system
- req_0034 (Default Template Provision) - should include default aggregated template

## Technical Considerations

### Aggregated Report Structure Example
```markdown
# Document Analysis Summary

**Analysis Date**: 2026-02-09 14:30:00  
**Source Directory**: /home/user/documents  
**Total Files Analyzed**: 152  
**Total Size**: 2.3 GB  

## Statistics by File Type

| Type | Count | Total Size | Avg Size |
|------|-------|------------|----------|
| application/pdf | 89 | 1.8 GB | 20.7 MB |
| text/markdown | 42 | 312 KB | 7.4 KB |
| image/jpeg | 21 | 487 MB | 23.2 MB |

## File Listing

| File | Type | Size | Modified | Report |
|------|------|------|----------|--------|
| manual.pdf | PDF | 45 MB | 2026-01-15 | [report](manual.pdf.md) |
| readme.md | Markdown | 3 KB | 2026-02-01 | [report](readme.md.md) |
...

## Analysis Details

- **Workspace**: /home/user/workspace
- **Template Used**: template.doc.doc.md
- **Plugins Executed**: stat, file, content-analyzer
- **Duration**: 12 minutes 34 seconds

---
*Generated by doc.doc v1.0.0*
```

### Command-Line Interface
```bash
# Default: per-file reports only, no aggregated summary
./doc.doc.sh -d docs/ -t reports/ -w workspace/

# Opt-in to aggregated summary report (uses default template)
./doc.doc.sh -d docs/ -t reports/ -w workspace/ --summary

# Opt-in with short flag
./doc.doc.sh -d docs/ -t reports/ -w workspace/ -s

# Opt-in with custom template
./doc.doc.sh -d docs/ -t reports/ -w workspace/ --summary=custom_summary.md
./doc.doc.sh -d docs/ -t reports/ -w workspace/ -s custom_summary.md
```

### Default Behavior
When aggregated report flag is **not** specified:
- Generate per-file reports only
- Skip corpus-level statistics collection
- Minimize memory overhead
- No summary/index file created

## Transition History
- [2026-02-09] Created in funnel by Requirements Engineer Agent - extracted from vision analysis
- [2026-02-09] Moved to analyze for detailed analysis
- [2026-02-09] Refined in analyze by Requirements Engineer Agent - changed from default to opt-in feature for aggregated reports
- [2026-02-09] Moved to accepted by user - ready for implementation
