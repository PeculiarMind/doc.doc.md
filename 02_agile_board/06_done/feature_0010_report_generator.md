# Feature: Report Generator

**ID**: 0010  
**Type**: Feature Implementation  
**Status**: Done  
**Created**: 2026-02-09  
**Updated**: 2026-02-12 (Moved to done - implementation complete)
**Priority**: Critical

## Overview
Implement the report generation subsystem that loads templates, merges workspace data, renders per-file Markdown reports, and optionally generates aggregated summary reports across all analyzed files.

## Description
Create the report generation engine that transforms workspace JSON data into human-readable Markdown reports using templates. The generator processes each analyzed file, loads its workspace data, applies the template engine, and writes formatted Markdown to the target directory. It also supports optional aggregated reports that provide corpus-level summaries and statistics when explicitly requested by the user.

This feature completes the analysis workflow by delivering the final output that users interact with directly.

## Business Value
- Provides human-readable output from analysis data
- Enables customization through template system
- Delivers consistent, professional documentation
- Supports both per-file detail and aggregated overview
- Essential for user value - visible end product

## Related Requirements
- [req_0004](../../01_vision/02_requirements/03_accepted/req_0004_markdown_report_generation.md) - Markdown Report Generation (PRIMARY)
- [req_0018](../../01_vision/02_requirements/03_accepted/req_0018_per_file_reports.md) - Per-File Reports
- [req_0039](../../01_vision/02_requirements/03_accepted/req_0039_aggregated_summary_reports.md) - Aggregated Reports (OPT-IN)
- [req_0005](../../01_vision/02_requirements/03_accepted/req_0005_template_based_reporting.md) - Template-based Reporting

## Architecture Review

**Review Date**: 2026-02-12  
**Reviewer**: Architect Agent  
**Status**: ✅ **CONDITIONAL APPROVAL** - Architecture compliant, documentation updates required before "Ready"

**Review Report**: [ARCH_REVIEW_FEATURE_0008_0010_TEMPLATE_AND_REPORT.md](../../ARCH_REVIEW_FEATURE_0008_0010_TEMPLATE_AND_REPORT.md)

### Compliance Summary
- ✅ Aligns with accepted requirements (req_0004, req_0018, req_0039, req_0005)
- ✅ Correctly depends on feature_0008 (Template Engine)
- ✅ Component location correct (orchestration/report_generator.sh)
- ✅ Integration points well-defined (Template Engine, Workspace Manager)

### Architecture Documentation Created
- ✅ [ADR-0011: Bash Template Engine with Control Structures](../../01_vision/03_architecture/09_architecture_decisions/ADR_0011_bash_template_engine_with_control_structures.md)
- ✅ [Concept 08_0011: Template Engine](../../01_vision/03_architecture/08_concepts/08_0011_template_engine.md)
- ✅ Building Block View 5.6 updated with enhanced Report Generator and Template Engine
- ✅ Mermaid diagram updated to show Template Engine integration

### Feature Dependencies
- **Depends On**: feature_0008 (Template Engine) - MUST be implemented first
- **Integration**: Calls `process_template()` from template_engine component
- **Shared Documentation**: Architecture updates apply to both features

### Blocking Issues
**NONE** - All architecture documentation complete. Feature ready to move to "Ready" state **AFTER** feature_0008 moves to "Ready".

### Recommendations
1. Wait for feature_0008 to move to "Ready" (template engine is prerequisite)
2. Add acceptance criteria for mode-aware behavior (progress display in interactive mode)
3. After both features implemented, verify end-to-end report generation workflow
4. Consider batch optimization: load template once, apply to all files (cache template content)

## Acceptance Criteria

### Per-File Report Generation
- [ ] System generates one Markdown report per analyzed file
- [ ] System writes reports to target directory specified by `-t` argument
- [ ] System preserves directory structure from source to target (optional, configurable)
- [ ] System names report files consistently (e.g., `<filename>.analysis.md`)
- [ ] System handles file name conflicts (overwrite or skip based on configuration)
- [ ] System creates target directory if it doesn't exist

### Template Loading
- [ ] System loads template file specified by `-m` argument
- [ ] System validates template file exists and is readable
- [ ] System caches template content (single load for all files)
- [ ] System provides default template if none specified
- [ ] System handles template load failures gracefully (error message, exit)

### Data Merging
- [ ] System loads workspace JSON for each file
- [ ] System provides all workspace fields to template engine as variables
- [ ] System includes metadata fields: file_path, file_size, file_type, last_scanned
- [ ] System includes analysis results from all executed plugins
- [ ] System provides helper variables: file_size_human, formatted dates
- [ ] System handles missing data gracefully (template conditionals)

### Report Writing
- [ ] System writes generated Markdown to target file atomically
- [ ] System validates target directory is writable
- [ ] System handles write failures gracefully (log error, continue with next file)
- [ ] System preserves UTF-8 encoding
- [ ] System logs each report written in verbose mode

### Aggregated Report (OPT-IN)
- [ ] System generates aggregated report ONLY when `--summary` or `-s` flag specified
- [ ] System collects statistics across all analyzed files:
  - Total file count by type
  - Total size and size distribution
  - File type distribution
  - Common tags or keywords (if available)
  - Processing summary (success/failure counts)
- [ ] System writes aggregated report to target directory (e.g., `SUMMARY.md` or `INDEX.md`)
- [ ] System uses summary template (default or specified via `--summary=<template>`)
- [ ] System includes list of all analyzed files with key metadata
- [ ] System allows plugins to contribute aggregated data

### Error Handling
- [ ] System validates target directory exists or can be created
- [ ] System handles template processing errors (per file, continue with others)
- [ ] System provides clear error messages for report generation failures
- [ ] System continues generating remaining reports after individual failures
- [ ] System aggregates and reports all errors at end

### Output Format
- [ ] Reports are valid Markdown format
- [ ] Reports include metadata header (YAML frontmatter optional)
- [ ] Reports are human-readable and well-formatted
- [ ] Reports follow consistent structure across all files
- [ ] Reports include generation timestamp

### Performance
- [ ] Report generation completes in reasonable time (< 1 second per file)
- [ ] Memory usage bounded for large file sets
- [ ] Efficient template application (single compile, multiple applies)

## Technical Considerations

### Implementation Approach
```bash
generate_reports() {
  local source_dir="$1"
  local target_dir="$2"
  local template_file="$3"
  local workspace_dir="$4"
  local generate_summary="${5:-false}"
  
  # Validate target directory
  mkdir -p "$target_dir" || {
    log "ERROR" "REPORTER" "Failed to create target directory: $target_dir"
    return 1
  }
  
  # Load template
  local template_content
  template_content=$(<"$template_file") || {
    log "ERROR" "REPORTER" "Failed to load template: $template_file"
    return 1
  }
  
  # Initialize statistics for aggregated report
  declare -A stats
  stats["total_files"]=0
  stats["total_size"]=0
  declare -a file_list=()
  
  # Process each file
  while IFS= read -r workspace_file; do
    local file_hash
    file_hash=$(basename "$workspace_file" .json)
    
    # Load workspace data
    local workspace_data
    workspace_data=$(<"$workspace_file")
    
    # Extract file info
    local file_path
    file_path=$(jq -r '.file_path' <<< "$workspace_data")
    
    local file_relative
    file_relative=$(jq -r '.file_path_relative' <<< "$workspace_data")
    
    # Generate report
    log "DEBUG" "REPORTER" "Generating report for: $file_relative"
    local report_content
    if report_content=$(process_template "$template_content" "$workspace_data"); then
      # Write report to target
      local report_file="$target_dir/${file_relative}.analysis.md"
      mkdir -p "$(dirname "$report_file")"
      echo "$report_content" > "$report_file"
      
      log "INFO" "REPORTER" "Generated report: $report_file"
      
      # Collect statistics
      if [[ "$generate_summary" == "true" ]]; then
        ((stats["total_files"]++))
        local file_size
        file_size=$(jq -r '.file_size' <<< "$workspace_data")
        ((stats["total_size"] += file_size))
        file_list+=("$file_relative|$file_size")
      fi
    else
      log "ERROR" "REPORTER" "Failed to generate report for: $file_relative"
    fi
  done < <(find "$workspace_dir/files" -name '*.json' -type f)
  
  # Generate aggregated report if requested
  if [[ "$generate_summary" == "true" ]]; then
    generate_aggregated_report "$target_dir" stats file_list
  fi
  
  log "INFO" "REPORTER" "Report generation complete: ${stats[total_files]} files"
}

generate_aggregated_report() {
  local target_dir="$1"
  declare -n stats_ref="$2"
  declare -n files_ref="$3"
  
  log "INFO" "REPORTER" "Generating aggregated summary report"
  
  # Build summary data
  local summary_data
  summary_data=$(cat <<EOF
{
  "total_files": ${stats_ref[total_files]},
  "total_size": ${stats_ref[total_size]},
  "total_size_human": "$(human_readable_size ${stats_ref[total_size]})",
  "generation_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "files": [
$(for file_entry in "${files_ref[@]}"; do
    IFS='|' read -r filepath filesize <<< "$file_entry"
    echo "    {\"path\": \"$filepath\", \"size\": $filesize},"
  done)
  ]
}
EOF
)
  
  # Load summary template
  local summary_template="${SUMMARY_TEMPLATE:-$DEFAULT_SUMMARY_TEMPLATE}"
  
  # Generate summary report
  local summary_content
  summary_content=$(process_template "$summary_template" "$summary_data")
  
  # Write summary
  echo "$summary_content" > "$target_dir/SUMMARY.md"
  log "INFO" "REPORTER" "Aggregated report written: $target_dir/SUMMARY.md"
}

human_readable_size() {
  local bytes="$1"
  local units=("B" "KB" "MB" "GB" "TB")
  local unit_index=0
  local size=$bytes
  
  while (( size > 1024 && unit_index < 4 )); do
    ((size /= 1024))
    ((unit_index++))
  done
  
  echo "${size}${units[$unit_index]}"
}
```

### Default Template
```markdown
# Analysis Report: {{filename}}

**Generated**: {{format_date last_scanned}}

## File Information

- **Path**: `{{file_path_relative}}`
- **Size**: {{file_size_human}}
- **Type**: {{file_type}}
- **Last Modified**: {{format_date file_last_modified}}

## Content Analysis

{{#if content.summary}}
### Summary
{{content.summary}}
{{/if}}

{{#if content.word_count}}
### Statistics
- **Word Count**: {{content.word_count}}
- **Line Count**: {{content.line_count}}
{{/if}}

{{#if content.tags}}
### Tags
{{#each content.tags}}
- {{this}}
{{/each}}
{{/if}}

## Processing Details

{{#if plugins_executed}}
The following plugins were executed:
{{#each plugins_executed}}
- **{{name}}**: {{status}} ({{timestamp}})
{{/each}}
{{/if}}

---
*Report generated by doc.doc.md*
```

### Integration Points
- **Template Engine**: Processes templates with workspace data
- **Workspace Manager**: Loads analysis results
- **CLI**: Receives template path and generates reports
- **Directory Scanner**: Determines which files have reports

### Dependencies
- Template engine (feature_0008) - for template processing
- Workspace management (feature_0007) - for data source
- Basic script structure (feature_0001) ✅

### Performance Considerations
- Single template load for all files
- Efficient workspace data loading
- Parallel report generation (future enhancement)
- Minimize disk I/O during writing

### Security Considerations
- Validate target directory to prevent path traversal
- Sanitize file paths before writing
- Set appropriate file permissions on reports
- Validate template output doesn't execute code

## Dependencies
- Requires: Template engine (feature_0008)
- Requires: Workspace management (feature_0007)
- Requires: Basic script structure (feature_0001) ✅
- Completes: Core workflow (enables end-to-end functionality)

## Testing Strategy
- Unit tests: Report file naming
- Unit tests: Data merging
- Unit tests: Aggregated statistics collection
- Integration tests: Per-file report generation
- Integration tests: Aggregated report generation (opt-in)
- Integration tests: Template application with real data
- Integration tests: Error handling (missing data, write failures)
- Integration tests: Large file sets (1000+ files)
- Performance tests: Report generation speed

## Definition of Done
- [ ] All acceptance criteria met
- [ ] Unit tests passing with >80% coverage
- [ ] Integration tests passing
- [ ] Code reviewed and approved
- [ ] Documentation updated (report generation, templates)
- [ ] Default templates created and tested
- [ ] Performance benchmarks meet targets
- [ ] User documentation for template customization
