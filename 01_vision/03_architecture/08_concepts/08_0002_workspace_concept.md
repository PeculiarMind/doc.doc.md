---
title: Workspace Concept
arc42-chapter: 8
---

## 0002 Workspace Concept

## Table of Contents

- [Purpose](#purpose)
- [Rationale](#rationale)
- [Implementation Details](#implementation-details)
- [Workspace Operations](#workspace-operations)
- [File Format](#file-format)
- [Concurrency and Locking](#concurrency-and-locking)
- [Related Requirements](#related-requirements)

The workspace is a persistent data layer that stores analysis results, metadata, and state information. It enables incremental analysis, external tool integration, and recovery from interruptions.

### Purpose

The workspace serves as:
- **State Persistence**: Store analysis results across multiple runs
- **Incremental Analysis**: Track which files have been analyzed and when
- **Integration Point**: Provide structured data for downstream tools
- **Recovery Mechanism**: Resume interrupted analysis
- **Audit Trail**: Record what analysis was performed and when

### Rationale

- **Efficiency**: Avoid re-analyzing unchanged files
- **Composability**: External tools can consume workspace data
- **Reliability**: Graceful recovery from failures
- **Traceability**: Know what was analyzed and with which plugins

### Implementation Details

**Workspace Structure**:
```
workspace/
├── <file_hash_1>.json       # Analysis data for file 1
├── <file_hash_1>.json.lock  # Lock file during write
├── <file_hash_2>.json       # Analysis data for file 2
├── metadata.json            # Optional: workspace-level metadata
```

**File Naming**:
- Use SHA-256 hash of absolute file path as filename
- Ensures unique, deterministic filenames
- Handles special characters and long paths
- Example: `/home/user/docs/file.pdf` → `abc123def456.json`

**JSON Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["file_path", "file_type", "last_scanned"],
  "properties": {
    "file_path": {
      "type": "string",
      "description": "Absolute path to the analyzed file"
    },
    "file_path_relative": {
      "type": "string",
      "description": "Relative path from source directory"
    },
    "file_type": {
      "type": "string",
      "description": "MIME type of the file"
    },
    "file_extension": {
      "type": "string",
      "description": "File extension including the dot"
    },
    "file_size": {
      "type": "integer",
      "description": "File size in bytes"
    },
    "file_created": {
      "type": "integer",
      "description": "Creation timestamp (Unix epoch)"
    },
    "file_last_modified": {
      "type": "integer",
      "description": "Last modification timestamp (Unix epoch)"
    },
    "file_owner": {
      "type": "string",
      "description": "File owner username"
    },
    "last_scanned": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp when file was last analyzed"
    },
    "content": {
      "type": "object",
      "description": "Content analysis results",
      "properties": {
        "text": {"type": "string"},
        "word_count": {"type": "integer"},
        "line_count": {"type": "integer"},
        "summary": {"type": "string"},
        "tags": {"type": "array", "items": {"type": "string"}}
      }
    },
    "plugins_executed": {
      "type": "array",
      "description": "Record of plugin executions",
      "items": {
        "type": "object",
        "properties": {
          "name": {"type": "string"},
          "timestamp": {"type": "string", "format": "date-time"},
          "status": {"type": "string", "enum": ["success", "failure", "skipped"]},
          "error": {"type": "string"}
        }
      }
    }
  },
  "additionalProperties": true
}
```

**Atomic Write Pattern**:
```bash
workspace_update() {
  local file_hash="$1"
  local workspace_dir="$2"
  local data="$3"
  
  local workspace_file="${workspace_dir}/${file_hash}.json"
  local temp_file="${workspace_file}.tmp.$$"
  local lock_file="${workspace_file}.lock"
  
  # 1. Acquire lock
  while [ -f "${lock_file}" ]; do
    sleep 0.1  # Wait for lock release
  done
  echo $$ > "${lock_file}"
  
  # 2. Write to temporary file
  echo "${data}" > "${temp_file}"
  
  # 3. Atomic rename
  mv "${temp_file}" "${workspace_file}"
  
  # 4. Release lock
  rm "${lock_file}"
}
```

### Incremental Analysis Logic

**Decision Flow**:
```bash
should_analyze_file() {
  local file_path="$1"
  local workspace_file="$2"
  
  # No workspace → first analysis
  [ ! -f "${workspace_file}" ] && return 0
  
  # Get file modification time
  local file_mtime=$(stat -c %Y "${file_path}")
  
  # Get last scan time from workspace
  local last_scanned=$(jq -r '.last_scanned' "${workspace_file}")
  local scan_epoch=$(date -d "${last_scanned}" +%s)
  
  # Modified after last scan?
  [ ${file_mtime} -gt ${scan_epoch} ] && return 0
  
  # File unchanged, skip
  return 1
}
```

**Benefits**:
- ✅ Only analyze changed files
- ✅ Fast repeated executions
- ✅ Suitable for cron jobs or scheduled tasks
- ✅ Workspace grows incrementally

### Integration with External Tools

**Reading Workspace Data**:
```bash
# Get all PDFs analyzed
jq -r 'select(.file_type == "application/pdf") | .file_path' workspace/*.json

# Get files with specific tag
jq -r 'select(.content.tags[] == "important") | .file_path' workspace/*.json

# Get recently modified files
jq -r 'select(.file_last_modified > 1707100000) | .file_path' workspace/*.json

# Extract all summaries
for f in workspace/*.json; do
  jq -r '.content.summary' "$f"
done
```

**Downstream Workflow Example**:
```bash
# 1. Run doc.doc analysis
./doc.doc.sh -d documents/ -w workspace/ -t reports/

# 2. Extract specific data for downstream processing
jq -r '.content.text' workspace/*.json | analyze-sentiment.py

# 3. Build search index from workspace
build-index.sh workspace/ > search_index.json

# 4. Generate dashboard
generate-dashboard.py --workspace workspace/ --output dashboard.html
```

### Concurrency Safety

**Lock File Protocol**:
- Create `.json.lock` before writing
- Lock contains PID and timestamp
- Other processes wait for lock release
- Lock automatically removed after write
- Stale lock detection (timeout after 60s)

**Multi-Process Safety**:
```bash
# Multiple doc.doc instances can run simultaneously
# Each processes different files
# Workspace locks prevent corruption

# Safe:
./doc.doc.sh -d dir1/ -w workspace/ &
./doc.doc.sh -d dir2/ -w workspace/ &
wait

# File-level locking ensures no conflicts
```

### Workspace Management Operations

#### Initialization

**Purpose**: Create workspace directory structure when specified directory doesn't exist or validate existing workspace.

**Initialization Logic**:
```bash
initialize_workspace() {
    local workspace_dir="$1"
    
    # Create workspace directory if it doesn't exist
    if [[ ! -d "$workspace_dir" ]]; then
        log_info "Creating workspace directory: $workspace_dir"
        mkdir -p "$workspace_dir" || {
            log_error "Failed to create workspace directory: $workspace_dir"
            return 1
        }
    fi
    
    # Set restrictive permissions (user read/write only)
    chmod 700 "$workspace_dir" || {
        log_error "Failed to set workspace permissions"
        return 1
    }
    
    # Create workspace metadata file
    local metadata_file="$workspace_dir/workspace.json"
    if [[ ! -f "$metadata_file" ]]; then
        cat > "$metadata_file" <<EOF
{
  "version": "1.0",
  "created": "$(date -Iseconds)",
  "last_updated": "$(date -Iseconds)",
  "tool_version": "${TOOL_VERSION}"
}
EOF
    fi
    
    # Create subdirectories if needed
    mkdir -p "$workspace_dir/files" || true
    mkdir -p "$workspace_dir/plugins" || true
    
    
    log_info "Workspace initialized successfully: $workspace_dir"
    return 0
}
```

**Initialization Requirements**:
- Atomic operation (completes fully or fails cleanly)
- Creates workspace.json with version and timestamp
- Sets permissions to user-only (700)
- Creates standard subdirectories (files/, plugins/)

#### Validation

**Purpose**: Verify workspace structure integrity on startup before analysis begins.

**Validation Logic**:
```bash
validate_workspace() {
    local workspace_dir="$1"
    local errors=0
    
    log_verbose "Validating workspace: $workspace_dir"
    
    # Check workspace directory exists and is accessible
    if [[ ! -d "$workspace_dir" ]]; then
        log_error "Workspace directory does not exist: $workspace_dir"
        return 1
    fi
    
    if [[ ! -r "$workspace_dir" || ! -w "$workspace_dir" ]]; then
        log_error "Workspace directory not accessible: $workspace_dir"
        return 1
    fi
    
    # Recreate missing subdirectories with warnings
    for subdir in files plugins; do
        if [[ ! -d "$workspace_dir/$subdir" ]]; then
            log_warning "Missing subdirectory $subdir, recreating..."
            mkdir -p "$workspace_dir/$subdir" || ((errors++))
        fi
    done
    
    # Check workspace metadata file
    local metadata_file="$workspace_dir/workspace.json"
    if [[ ! -f "$metadata_file" ]]; then
        log_warning "Workspace metadata missing, recreating..."
        initialize_workspace "$workspace_dir"
    else
        # Validate JSON syntax
        if ! jq empty "$metadata_file" 2>/dev/null; then
          log_warning "Workspace metadata corrupted, recreating..."
          rm -f "$metadata_file"
          initialize_workspace "$workspace_dir"
        fi
    fi
    
    if [[ $errors -gt 0 ]]; then
        log_error "Workspace validation failed with $errors errors"
        return 1
    fi
    
    log_verbose "Workspace validation completed successfully"
    return 0
}
```

**Validation Checks**:
- Directory exists and has correct permissions
- Required subdirectories exist (recreate if missing)
- workspace.json exists and is valid JSON
- Stale lock files cleaned up (optional)

#### Corruption Detection and Recovery

**Purpose**: Detect and recover from corrupted workspace files without losing all data.

**Corruption Handling Logic**:
```bash
check_workspace_file() {
    local json_file="$1"
    local workspace_dir="$2"
    
    # Try to parse JSON
    if ! jq empty "$json_file" 2>/dev/null; then
        log_warning "Corrupted workspace file detected: $json_file"
        
        rm -f "$json_file"
        log_info "Corrupted file removed: $json_file"
        log_info "File will be re-analyzed in next scan"
        
        return 1  # Indicates corruption found
    fi
    
    return 0  # File is valid
}

scan_workspace_corruption() {
    local workspace_dir="$1"
    local corrupted_count=0
    
    log_info "Scanning workspace for corrupted files..."
    
    # Check all JSON files
    for json_file in "$workspace_dir"/*.json; do
        [[ ! -f "$json_file" ]] && continue
        [[ "$json_file" == */workspace.json ]] && continue  # Skip metadata
        
        if ! check_workspace_file "$json_file" "$workspace_dir"; then
            ((corrupted_count++))
        fi
    done
    
    if [[ $corrupted_count -gt 0 ]]; then
      log_warning "Found $corrupted_count corrupted files (removed)"
      log_info "Affected files will be re-analyzed automatically"
    else
        log_verbose "No corrupted workspace files found"
    fi
    
    return 0  # Continue analysis with healthy files
}
```

**Corruption Recovery Process**:
1. **Detection**: Attempt to parse JSON, catch syntax errors
2. **Removal**: Delete corrupted file and mark it for re-scan
3. **Continue**: Process remaining valid workspace files
4. **Re-analyze**: Missing workspace files automatically re-analyzed in next scan
5. **Logging**: Document corruption detection and recovery actions

#### Cleanup Operations

**Purpose**: Remove workspace entries for deleted source files and manage workspace size.

**Cleanup Logic**:
```bash
cleanup_workspace() {
    local workspace_dir="$1"
    local source_dir="$2"
    local dry_run="${3:-false}"
    local removed_count=0
    
    log_info "Starting workspace cleanup..."
    
    for json_file in "$workspace_dir"/*.json; do
        [[ ! -f "$json_file" ]] && continue
        [[ "$json_file" == */workspace.json ]] && continue
        
        # Extract original file path
        local file_path=$(jq -r '.file_path' "$json_file" 2>/dev/null)
        
        if [[ -z "$file_path" || "$file_path" == "null" ]]; then
            log_warning "Workspace file missing file_path: $json_file"
            continue
        fi
        
        # Check if source file still exists
        if [[ ! -f "$file_path" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                log_info "[DRY RUN] Would remove: $json_file (source deleted: $file_path)"
            else
                log_verbose "Removing workspace file: $json_file (source deleted)"
                rm -f "$json_file"
                rm -f "${json_file}.lock"  # Clean up any stale locks
            fi
            ((removed_count++))
        fi
    done
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "Dry run complete: $removed_count files would be removed"
    else
        log_info "Cleanup complete: $removed_count workspace files removed"
    fi
    
    return 0
}

workspace_size_report() {
    local workspace_dir="$1"
    
    local total_size=$(du -sh "$workspace_dir" 2>/dev/null | cut -f1)
    local file_count=$(find "$workspace_dir" -name "*.json" -type f | wc -l)
    
    echo "Workspace Statistics:"
    echo "  Location: $workspace_dir"
    echo "  Total Size: $total_size"
    echo "  JSON Files: $file_count"
}

reset_workspace() {
    local workspace_dir="$1"
    local confirm="${2:-false}"
    
    if [[ "$confirm" != "true" ]]; then
        log_error "Workspace reset requires explicit confirmation"
        log_error "Pass 'true' as second argument to confirm"
        return 1
    fi
    
    log_warning "Resetting workspace: $workspace_dir"
    
    # Remove all JSON files except metadata
    find "$workspace_dir" -name "*.json" -type f -not -name "workspace.json" -delete
    find "$workspace_dir" -name "*.lock" -type f -delete
    
    # Update metadata
    if [[ -f "$workspace_dir/workspace.json" ]]; then
        jq '.last_updated = "'$(date -Iseconds)'" | .reset_count = (.reset_count // 0) + 1' \
            "$workspace_dir/workspace.json" > "$workspace_dir/workspace.json.tmp"
        mv "$workspace_dir/workspace.json.tmp" "$workspace_dir/workspace.json"
    fi
    
    log_info "Workspace reset complete"
    return 0
}
```

**Cleanup Operations**:
- **Orphan Removal**: Delete workspace files for non-existent source files
- **Size Query**: Report workspace disk usage and file counts
- **Reset**: Clear all workspace data while preserving structure
- **Dry Run**: Preview cleanup actions without making changes

**Command-Line Integration**:
```bash
# Cleanup deleted files
./doc.doc.sh --workspace-cleanup -w workspace/

# Workspace size report
./doc.doc.sh --workspace-info -w workspace/

# Force full workspace reset (with confirmation)
./doc.doc.sh --workspace-reset -w workspace/

# Dry run cleanup
./doc.doc.sh --workspace-cleanup --dry-run -w workspace/
```

### Workspace Maintenance

**Cleanup Old Data**:
```bash
# Remove workspace entries for deleted files
cleanup_workspace() {
  local workspace_dir="$1"
  for json in "${workspace_dir}"/*.json; do
    file_path=$(jq -r '.file_path' "${json}")
    [ ! -f "${file_path}" ] && rm "${json}"
  done
}
```

**Workspace Reset**:
```bash
# Force full re-analysis
rm -rf workspace/*.json

# Or update last_scanned to old date
for json in workspace/*.json; do
  jq '.last_scanned = "1970-01-01T00:00:00Z"' "${json}" > "${json}.tmp"
  mv "${json}.tmp" "${json}"
done
```

**Schema Recovery**:
```bash
# No migrations. Rebuild workspace by re-scanning when schema changes.
rm -f workspace/*.json
```

### Design Principles

1. **One File = One JSON**: Scalable, distributed I/O, simple locking
2. **Human-Readable**: JSON format, easy debugging with jq
3. **Atomic Updates**: Temp file + rename pattern prevents corruption
4. **Backward Compatible**: Additional properties allowed, old readers still work
5. **Tool-Friendly**: Standard JSON consumable by any language

### Usage Patterns

**Development/Testing**:
```bash
# Quick iteration with small workspace
./doc.doc.sh -d test_docs/ -w /tmp/workspace/ -t /tmp/reports/
```

**Production/Scheduled**:
```bash
# Large workspace, incremental updates
./doc.doc.sh -d /data/documents/ -w /var/lib/doc.doc/workspace/ -t /var/www/reports/
```

**One-Off Analysis**:
```bash
# Disposable workspace
./doc.doc.sh -d incoming_files/ -w $(mktemp -d) -t reports/
```

**Shared Workspace**:
```bash
# Multiple users share workspace for consistency
./doc.doc.sh -d ~/my_docs/ -w /shared/workspace/ -t ~/my_reports/
```

### Trade-offs

**Chosen Approach**:
- ✅ Simple file-based storage
- ✅ Human-readable JSON
- ✅ One file per analyzed document
- ⚠️ Directory size grows with analyzed files
- ⚠️ File I/O overhead for very large datasets (1M+ files)

**Acceptable Because**:
- Target use case: Thousands to tens of thousands of files
- File I/O fast on modern systems (especially SSD)
- Simplicity and debuggability more valuable than max performance
- Can purge old workspace data if needed

### Future Enhancements

**Potential Improvements**:
- Compression for old/inactive workspace files
- Index file for faster lookups
- Workspace statistics and health checks
- Automatic cleanup of orphaned entries
- Workspace backup and restore utilities

### Related Requirements

- [req_0001: Single Command Directory Analysis](../../02_requirements/03_accepted/req_0001_single_command_directory_analysis.md) - requires `-w` workspace parameter
- [req_0003: Metadata Extraction](../../02_requirements/03_accepted/req_0003_metadata_extraction_with_cli_tools.md) - stores metadata in workspace as JSON
- [req_0018: Per-File Reports](../../02_requirements/03_accepted/req_0018_per_file_reports.md) - stores file metadata in workspace JSON files
- [req_0023: Data-driven Execution Flow](../../02_requirements/03_accepted/req_0023_data_driven_execution_flow.md) - plugins read/write workspace data
- [req_0025: Incremental Analysis](../../02_requirements/03_accepted/req_0025_incremental_analysis.md) - depends on workspace timestamp tracking
- [req_0059: Workspace Recovery and Rescan](../../02_requirements/03_accepted/req_0059_workspace_recovery_and_rescan.md) - defines workspace lifecycle operations
