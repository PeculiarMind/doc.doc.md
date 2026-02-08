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
└── .workspace_version       # Workspace schema version
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

**Schema Migration**:
```bash
# Workspace version file
echo "1.0" > workspace/.workspace_version

# Migration script when schema changes
migrate_workspace() {
  local version=$(cat workspace/.workspace_version)
  case "${version}" in
    "1.0") migrate_1_0_to_1_1 ;;
    "1.1") migrate_1_1_to_2_0 ;;
  esac
}
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
