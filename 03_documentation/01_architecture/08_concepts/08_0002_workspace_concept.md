# Concept 0002: Workspace Management (Implementation)

**Status**: Not Implemented (Design Complete)  
**Last Updated**: 2026-02-08  
**Vision Reference**: [Workspace Concept](../../../../01_vision/03_architecture/08_concepts/08_0002_workspace_concept.md)

## Purpose

The workspace provides persistent storage for analysis metadata and state, enabling incremental processing, recovery from interruptions, and integration with external tools.

## Table of Contents

- [Implementation Status: ⏳ PLANNED (0% Complete)](#implementation-status--planned-0-complete)
- [Planned Design](#planned-design)
  - [Workspace Structure](#workspace-structure)
  - [JSON Schema (Planned)](#json-schema-planned)
  - [Planned Operations](#planned-operations)
  - [Integration Points](#integration-points)
  - [Benefits of This Design](#benefits-of-this-design)
  - [Trade-offs Accepted](#trade-offs-accepted)
- [Related Architecture Decisions](#related-architecture-decisions)
- [Testing Strategy (Planned)](#testing-strategy-planned)
  - [Unit Tests](#unit-tests)
  - [Integration Tests](#integration-tests)
  - [Performance Tests](#performance-tests)
- [Future Enhancements](#future-enhancements)
- [Implementation Priority](#implementation-priority)
- [Summary](#summary)

## Implementation Status: ⏳ PLANNED (0% Complete)

**Current State**: No workspace functionality implemented yet

**Design Status**: ✅ Complete - Architecture defined, ready to implement

## Planned Design

### Workspace Structure

```
workspace/
├── abc123def456.json        # Analysis data for file 1 (SHA-256 hash of path)
├── abc123def456.json.lock   # Lock file (prevents concurrent writes)
├── fed654cba321.json        # Analysis data for file 2
├── fed654cba321.json.lock
└── metadata.json            # Optional workspace-level metadata
```

**File Naming Convention**:
- Filename: SHA-256 hash of absolute file path
- Extension: `.json`
- Lock file: Same name + `.lock`

**Rationale**:
- Unique, deterministic filenames
- Handles special characters and long paths
- One-to-one file-to-workspace mapping

---

### JSON Schema (Planned)

```json
{
  "file_path": "/absolute/path/to/file.pdf",
  "file_path_relative": "documents/file.pdf",
  "file_type": "application/pdf",
  "file_extension": ".pdf",
  "file_size": 1048576,
  "file_created": 1707091200,
  "file_last_modified": 1707177600,
  "file_owner": "username",
  "last_scanned": "2026-02-08T10:00:00Z",
  
  "content": {
    "text": "Extracted text content...",
    "word_count": 5432,
    "line_count": 150,
    "summary": "Document summary...",
    "tags": ["important", "draft"]
  },
  
  "plugins_executed": [
    {
      "name": "stat",
      "timestamp": "2026-02-08T10:00:01Z",
      "status": "success"
    },
    {
      "name": "ocrmypdf",
      "timestamp": "2026-02-08T10:00:05Z",
      "status": "success"
    }
  ]
}
```

**Required Fields**:
- `file_path`, `file_type`, `last_scanned`

**Optional Fields**:
- All plugin outputs (dynamically added)
- `plugins_executed` (audit trail)

---

### Planned Operations

#### 1. Workspace Initialization

```bash
init_workspace() {
  local workspace_dir="$1"
  
  # Create workspace directory if not exists
  mkdir -p "${workspace_dir}"
  
  # Optional: Create metadata.json
  echo '{"version": "1.0", "created": "'"$(date -Iseconds)"'"}' > "${workspace_dir}/metadata.json"
}
```

---

#### 2. File Hash Calculation

```bash
get_file_hash() {
  local file_path="$1"
  
  # SHA-256 hash of absolute path
  echo -n "${file_path}" | sha256sum | cut -d' ' -f1
}
```

**Example**:
- Input: `/home/user/documents/report.pdf`
- Output: `abc123def456789...` (64 hex digits)
- Workspace file: `workspace/abc123def456789....json`

---

#### 3. Atomic Write Pattern

```bash
workspace_write() {
  local file_hash="$1"
  local workspace_dir="$2"
  local json_data="$3"
  
  local workspace_file="${workspace_dir}/${file_hash}.json"
  local temp_file="${workspace_file}.tmp.$$"
  local lock_file="${workspace_file}.lock"
  
  # 1. Acquire lock
  while [ -f "${lock_file}" ]; do
    sleep 0.1
  done
  echo $$ > "${lock_file}"
  
  # 2. Write to temp file
  echo "${json_data}" > "${temp_file}"
  
  # 3. Validate JSON (optional)
  if ! jq empty "${temp_file}" 2>/dev/null; then
    rm "${temp_file}" "${lock_file}"
    return 1
  fi
  
  # 4. Atomic rename
  mv "${temp_file}" "${workspace_file}"
  
  # 5. Release lock
  rm "${lock_file}"
}
```

**Safety Features**:
- ✅ Atomic rename operation
- ✅ Lock file prevents concurrent writes
- ✅ JSON validation before commit
- ✅ Process ID in lock file (debugging)

---

#### 4. Workspace Read

```bash
workspace_read() {
  local file_hash="$1"
  local workspace_dir="$2"
  
  local workspace_file="${workspace_dir}/${file_hash}.json"
  
  # Check existence
  [ ! -f "${workspace_file}" ] && return 1
  
  # Read and validate
  cat "${workspace_file}"
}
```

---

#### 5. Incremental Analysis Logic

```bash
should_analyze_file() {
  local file_path="$1"
  local workspace_dir="$2"
  
  local file_hash=$(get_file_hash "${file_path}")
  local workspace_file="${workspace_dir}/${file_hash}.json"
  
  # No workspace entry → analyze (first time)
  [ ! -f "${workspace_file}" ] && return 0
  
  # Get file modification time
  local file_mtime=$(stat -c %Y "${file_path}")
  
  # Get last scan time from workspace
  local last_scanned=$(jq -r '.last_scanned' "${workspace_file}")
  local scan_epoch=$(date -d "${last_scanned}" +%s)
  
  # File modified after last scan? → analyze
  [ ${file_mtime} -gt ${scan_epoch} ] && return 0
  
  # File unchanged → skip
  return 1
}
```

**Logic**:
1. No workspace entry → Analyze (first time)
2. File modified since last scan → Analyze (changed)
3. File unchanged → Skip (incremental)

---

### Integration Points

#### External Tools (Planned)

**Query Examples** (with jq):
```bash
# Find all PDFs analyzed
jq -r 'select(.file_type == "application/pdf") | .file_path' workspace/*.json

# Find files with specific tag
jq -r 'select(.content.tags[] == "important") | .file_path' workspace/*.json

# Get recently modified files (last 24h)
jq -r 'select(.file_last_modified > '"$(($(date +%s) - 86400))"') | .file_path' workspace/*.json

# Extract all summaries
for file in workspace/*.json; do
  jq -r '.content.summary' "$file"
done
```

**Downstream Workflow** (planned):
```bash
# 1. Run analysis
./doc.doc.sh -d documents/ -w workspace/ -t reports/

# 2. Query workspace for specific data
jq '.content.summary' workspace/*.json > all_summaries.txt

# 3. Build custom report
for hash in workspace/*.json; do
  # Custom processing
done
```

---

### Benefits of This Design

1. **Incremental Analysis**: Only process changed files
2. **State Persistence**: Survive script interruptions
3. **External Integration**: Standard JSON format
4. **Debugging**: Human-readable workspace files
5. **Concurrency Safe**: Lock file mechanism
6. **Scalability**: One file per document (distributed I/O)

---

### Trade-offs Accepted

**Advantages**:
- ✅ Simple, no database required
- ✅ Easy to debug (cat workspace/file.json | jq)
- ✅ Version control friendly (can track workspace changes)
- ✅ External tool integration (any JSON processor)

**Disadvantages**:
- ⚠️ No ACID transactions beyond filesystem atomicity
- ⚠️ Query performance limited (no indexing)
- ⚠️ Large workspaces (100K+ files) may have I/O overhead

**Mitigation**:
- Target use cases: thousands of files (acceptable performance)
- Workspace cleanup strategies (archive old data)
- One file per document (O(1) access, not O(n) scan)

---

## Related Architecture Decisions

- **Vision ADR-002**: JSON Workspace for State Persistence (vision-level decision)
- **ADR-0011**: Dual JSON Parser Strategy (implementation support)
- **Future ADR**: Workspace Locking Mechanism (when implemented)
- **Future ADR**: Workspace Schema Versioning (when implemented)

---

## Testing Strategy (Planned)

### Unit Tests
- `get_file_hash()` correctness
- `should_analyze_file()` logic
- Lock file acquisition/release
- Atomic write success/failure scenarios

### Integration Tests
- Full incremental analysis workflow
- Concurrent access handling
- Workspace corruption recovery

### Performance Tests
- Workspace operations with 1K, 10K files
- Lock contention under concurrent access

---

## Future Enhancements

1. **Workspace Migration**: Schema version upgrades
2. **Workspace Cleanup**: Archive/delete old entries
3. **Workspace Backup**: Automatic backup before operations
4. **Workspace Validation**: Integrity checking command
5. **Workspace Query**: Built-in query commands
6. **Workspace Export**: Export to different formats (CSV, SQLite)

---

## Implementation Priority

**Priority**: High (required for incremental analysis)

**Dependencies**:
- File scanner (to generate file lists)
- Plugin executor (to populate workspace data)

**Blocks**:
- Incremental analysis feature
- External tool integration
- Resume after interruption

---

## Summary

The workspace concept is **fully designed** and ready for implementation. The design is:
- ✅ Complete and detailed
- ✅ Aligned with vision
- ✅ Validated against requirements
- ✅ Simple yet powerful

**Next Step**: Implement workspace operations as part of file analysis feature development.

**Estimated Implementation Effort**: 1-2 features worth of work (moderate complexity)
