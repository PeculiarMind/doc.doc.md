# Requirement: Incremental Analysis

**ID**: req_0025

## Status
State: Accepted  
Created: 2026-02-06  
Last Updated: 2026-02-06

## Overview
The system shall perform incremental analysis by default, tracking file modification timestamps and only processing files that have changed since the last analysis run. Users can override this behavior to force full re-analysis via command-line option.

## Description
When analyzing a directory that has been previously processed, the system must detect which files have been modified since the last scan and selectively process only those files by default. This is achieved by storing last-scan timestamps in the workspace directory and comparing them against current file modification times. 

Incremental analysis significantly improves performance for large directories where only a subset of files change between analysis runs. The system provides a command-line option (`-f fullscan`) to override this default behavior and force full re-analysis of all files regardless of modification status.

## Motivation
From the vision: "Records timestamps and metadata (last scan time, document information) for incremental analysis and tool integration."

Incremental analysis is essential for efficient repeated analysis of large codebases, documentation repositories, and file collections where full re-analysis would be unnecessarily expensive. Making this the default behavior optimizes the common use case while still allowing users to force complete re-processing when needed.

## Category
- Type: Functional
- Priority: Medium

## Acceptance Criteria

### Default Incremental Behavior
- [ ] The system stores last-analysis timestamps in the workspace directory for each processed file
- [ ] On subsequent runs, the system compares file modification times against stored timestamps by default
- [ ] Files with modification times newer than last-analysis times are automatically re-analyzed
- [ ] Files with no modifications since last analysis are skipped (reports preserved from previous run)
- [ ] Timestamp metadata is stored in JSON format in the workspace directory
- [ ] The system correctly detects new files and includes them in incremental analysis
- [ ] The system correctly handles deleted files (removes stale metadata and reports)
- [ ] Incremental analysis reduces processing time by at least 50% when fewer than 20% of files have changed

### Force Full Re-analysis Option
- [ ] The system accepts a `-f fullscan` command-line option to force full re-analysis
- [ ] When `-f fullscan` is specified, all files are re-analyzed regardless of timestamps
- [ ] Fullscan mode ignores stored timestamp metadata
- [ ] Fullscan mode updates all timestamps after re-analysis completes
- [ ] Help text clearly documents the `-f fullscan` option and its purpose
- [ ] Fullscan mode is indicated in verbose output

### Error Handling
- [ ] The system handles missing timestamp data gracefully (defaults to full analysis of affected files)
- [ ] The system handles corrupt timestamp data gracefully (logs warning, treats as missing)
- [ ] First-time analysis (no existing workspace data) completes without errors
- [ ] Missing workspace directory triggers full analysis behavior
- [ ] Timestamp file I/O errors are logged and fail gracefully

### Performance
- [ ] Timestamp reading/writing has minimal overhead (< 100ms for 1000 files)
- [ ] Incremental analysis decision-making is fast (< 50ms for 1000 files)
- [ ] Memory usage for timestamp tracking is reasonable (< 1MB per 10,000 files)

### Integration
- [ ] Incremental analysis works with all plugin types
- [ ] Plugins receive only changed files during incremental runs
- [ ] Reports from previous runs are preserved and accessible
- [ ] Workspace metadata schema is documented

## Related Requirements
- req_0001 (Single Command Directory Analysis) - incremental analysis optimizes repeated executions
- req_0002 (Recursive Directory Scanning) - timestamps recorded during scanning
- req_0018 (Per-File Reports) - reports preserved or regenerated based on timestamps
- req_0006 (Verbose Logging Mode) - verbose output shows incremental vs. full analysis

## Technical Considerations

### Timestamp Storage Format
```json
{
  "workspace_version": "1.0",
  "last_full_scan": "2026-02-06T10:30:00Z",
  "files": {
    "path/to/file1.md": {
      "last_analyzed": "2026-02-06T10:30:15Z",
      "last_modified": "2026-02-05T14:22:00Z",
      "checksum": "sha256:abc123...",
      "report_path": "output/file1.doc.doc.md"
    }
  }
}
```

### CLI Usage Examples
```bash
# Default: incremental analysis (only changed files)
./doc.doc.sh -d ./docs -m template.md -t ./output -w ./.workspace

# Force full re-analysis of all files
./doc.doc.sh -d ./docs -m template.md -t ./output -w ./.workspace -f fullscan
```

### Decision Logic
```
IF workspace exists AND timestamp data valid AND NOT fullscan mode:
    For each file:
        IF new file OR modified since last scan:
            Re-analyze file
        ELSE:
            Skip (preserve previous report)
ELSE:
    Full analysis of all files
```

## Transition History
- [2026-02-06] Created in Funnel
  - Comment: Gap identified during lifecycle review. Explicitly mentioned in vision but no requirement existed. Designed as default behavior with force override option per user specification.
