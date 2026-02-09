# Requirement: Plugin File Type Filtering

**ID**: req_0043

## Status
State: Accepted  
Created: 2026-02-09  
Last Updated: 2026-02-09

## Overview
The system shall filter plugin execution based on file MIME types and extensions as declared in plugin descriptors, ensuring plugins only process files they are designed to handle.

## Description
The Plugin Concept (08_0001) defines the `processes` attribute in plugin descriptors specifying which MIME types and file extensions each plugin can handle. While req_0022 addresses plugin descriptor parsing, there is no explicit requirement ensuring the toolkit filters files appropriately before passing them to plugins. The system must: detect file MIME types using `file --mime-type` command, match against plugin `processes.mime_types` array, match file extensions against plugin `processes.file_extensions` array, and only execute plugins on compatible files. Plugins with empty or omitted `processes` arrays should handle all file types. This filtering prevents plugins from receiving incompatible files, reduces unnecessary executions, and allows specialized plugins for specific formats.

## Motivation
From Plugin Concept (08_0001_plugin_concept.md):
```json
"processes": {
  "mime_types": ["application/pdf"],
  "file_extensions": [".pdf"]
}
```

Documentation states: "The toolkit uses `consumes` and `provides` to determine plugin execution order automatically. Plugins execute only when all their consumed data is available. The `processes` attribute filters which files are passed to each plugin based on type or extension."

Without file type filtering, all plugins would attempt to process all files, causing errors, wasted processing, and meaningless results (e.g., PDF extraction plugin running on plain text files).

## Category
- Type: Functional
- Priority: Medium

## Acceptance Criteria

### MIME Type Detection
- [ ] System detects MIME type of each file using `file --mime-type <filepath>` command
- [ ] MIME type detection cached per file to avoid repeated executions
- [ ] MIME type detection errors logged but analysis continues (treat as unknown type)
- [ ] MIME type included in workspace JSON metadata for reference
- [ ] Verbose mode logs detected MIME type for each file

### Plugin File Type Specification
- [ ] Plugin descriptors support `processes.mime_types` as array of strings (MIME type patterns)
- [ ] Plugin descriptors support `processes.file_extensions` as array of strings (extension patterns including dot)
- [ ] Empty `processes.mime_types` array means "all MIME types"
- [ ] Empty `processes.file_extensions` array means "all extensions"
- [ ] Omitted `processes` object means plugin handles all file types
- [ ] MIME type matching is exact string match (e.g., `"application/pdf"`)
- [ ] Extension matching is case-insensitive (e.g., `.PDF` matches `.pdf`)

### Filtering Logic
- [ ] For each file, system determines applicable plugins based on MIME type and extension
- [ ] If file MIME type matches any entry in `processes.mime_types`, plugin is applicable
- [ ] If file extension matches any entry in `processes.file_extensions`, plugin is applicable
- [ ] If both arrays specified, matching either makes plugin applicable (logical OR)
- [ ] Plugins with empty/omitted `processes` execute for all files
- [ ] Only applicable plugins executed for each file (non-applicable plugins skipped)

### Performance
- [ ] MIME type detection overhead is minimal (< 10ms per file)
- [ ] File type filtering decision is fast (< 1ms per plugin per file)
- [ ] Filtering reduces unnecessary plugin executions by at least 50% for heterogeneous directories
- [ ] Memory usage for file type metadata is reasonable (< 100 bytes per file)

### Error Handling
- [ ] Files with undetectable MIME types handled gracefully (logged, analysis continues)
- [ ] Invalid `processes` specification in plugin descriptor logged with clear error
- [ ] Plugin skipped if `processes` specification is malformed
- [ ] Missing `file` command detected and reported with actionable guidance

### Logging and Transparency
- [ ] Verbose mode logs which plugins are applicable for each file
- [ ] Verbose mode logs when plugins are skipped due to file type mismatch
- [ ] Plugin list (`-p list`) shows which file types each plugin handles
- [ ] Workspace JSON includes list of plugins executed for each file

### Integration
- [ ] File type filtering applied before plugin dependency resolution (req_0023)
- [ ] File type filtering respects plugin `active` flag (inactive plugins never executed regardless of type)
- [ ] Filtering works with platform-specific plugin loading (req_0033)

## Related Requirements
- req_0022 (Plugin-Based Extensibility) - defines plugin descriptor format including `processes`
- req_0023 (Data-Driven Execution Flow) - filtering precedes dependency resolution
- req_0003 (Metadata Extraction with CLI Tools) - `file` command used for MIME detection
- req_0033 (Platform Support) - filtering works with platform-specific plugins

## Technical Considerations

### MIME Type Detection
```bash
detect_mime_type() {
  local file_path="$1"
  
  if ! command -v file >/dev/null 2>&1; then
    log "WARN" "file command not available, cannot detect MIME types"
    echo "application/octet-stream"  # Fallback
    return 1
  fi
  
  local mime_type=$(file --brief --mime-type "$file_path" 2>/dev/null)
  
  if [ -z "$mime_type" ]; then
    log "WARN" "Could not detect MIME type for $file_path"
    echo "application/octet-stream"
    return 0
  fi
  
  echo "$mime_type"
  return 0
}
```

### Plugin Filtering Logic
```bash
is_plugin_applicable() {
  local plugin_name="$1"
  local file_path="$2"
  local file_mime_type="$3"
  local file_extension="${file_path##*.}"  # Extract extension
  file_extension=".${file_extension,,}"    # Lowercase with dot
  
  # Parse plugin descriptor processes section
  local processes_mime_types=$(jq -r '.processes.mime_types[]?' "$plugin_descriptor")
  local processes_extensions=$(jq -r '.processes.file_extensions[]?' "$plugin_descriptor")
  
  # If processes not specified, plugin handles all files
  if [ -z "$processes_mime_types" ] && [ -z "$processes_extensions" ]; then
    return 0  # Applicable
  fi
  
  # Check MIME type match
  if echo "$processes_mime_types" | grep -qxF "$file_mime_type"; then
    return 0  # Applicable
  fi
  
  # Check extension match (case-insensitive)
  if echo "$processes_extensions" | grep -qiF "$file_extension"; then
    return 0  # Applicable
  fi
  
  return 1  # Not applicable
}
```

### Example Plugin Descriptors

**PDF-specific plugin:**
```json
{
  "name": "pdfinfo",
  "processes": {
    "mime_types": ["application/pdf"],
    "file_extensions": [".pdf"]
  }
}
```

**Image plugin handling multiple types:**
```json
{
  "name": "imageinfo",
  "processes": {
    "mime_types": ["image/jpeg", "image/png", "image/gif"],
    "file_extensions": [".jpg", ".jpeg", ".png", ".gif"]
  }
}
```

**Generic plugin handling all files:**
```json
{
  "name": "stat",
  "processes": {
    "mime_types": [],
    "file_extensions": []
  }
}
```

## Transition History
- [2026-02-09] Created in funnel by Requirements Engineer Agent - extracted from Plugin Concept analysis
- [2026-02-09] Moved to analyze for detailed analysis
- [2026-02-09] Moved to accepted by user - ready for implementation
