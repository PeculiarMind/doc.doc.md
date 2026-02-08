# ADR-0002: JSON Workspace for State Persistence

**ID**: ADR-0002  
**Status**: Accepted  
**Created**: 2026-02-06  
**Last Updated**: 2026-02-08

## Context

Need mechanism to store analysis state and support incremental updates. The system must persist metadata about analyzed files, track processing state, and enable efficient re-analysis of only changed files.

## Decision

Use JSON files in a workspace directory to persist analysis results and metadata. Each analyzed file gets its own JSON file identified by content hash.

## Rationale

**Strengths**:
- **Human-Readable**: Easy to inspect and debug
- **Widely Supported**: Standard format with excellent tool support
- **No Database Required**: File-based, no server dependencies
- **Tool Integration**: Easy to consume by downstream tools (jq, scripts, etc.)
- **Version Control Friendly**: Text format can be tracked in git
- **Flexible Schema**: Easy to add new fields without breaking compatibility

**Weaknesses**:
- **Performance**: Slower than binary formats for large datasets
- **Concurrency**: Requires explicit locking mechanisms
- **Query Capabilities**: No SQL-like queries (need jq or scripting)

## Alternatives Considered

### SQLite Database
- ✅ Excellent query capabilities, good performance, ACID properties
- ❌ Requires SQLite library (additional dependency)
- ❌ Less human-readable (binary format)
- ❌ Adds complexity for simple key-value lookups
- **Decision**: Overkill for file-to-metadata mapping

### Binary Format (MessagePack, Protocol Buffers)
- ✅ Faster parsing, smaller file sizes
- ❌ Not human-readable
- ❌ Requires additional tools for inspection
- ❌ More complex schema management
- **Decision**: Human-readability more valuable than performance

### Plain Text (Key=Value)
- ✅ Simple, bash-native parsing
- ❌ No nested structures
- ❌ Limited data type support
- ❌ Poor extensibility
- **Decision**: Insufficient for structured metadata

### XML
- ✅ Structured, well-supported
- ❌ Verbose, harder to parse in bash
- ❌ Less modern tooling
- **Decision**: JSON more compact and better tooling

## Consequences

### Positive
- Simple debugging (cat workspace/file.json | jq)
- Easy integration with other tools
- No runtime dependencies beyond jq (optional)
- Incremental analysis straightforward (check timestamps)

### Negative
- Must implement file locking for concurrent access
- JSON parsing in bash requires jq or workarounds
- Large workspaces (1M+ files) may have I/O overhead

### Risks
- Race conditions during concurrent writes
- Workspace corruption if process killed during write
- Performance degradation with very large workspaces

## Implementation Notes

**Workspace Structure**:
```
workspace/
├── abc123def456.json        # File hash as filename
├── abc123def456.json.lock   # Lock file during write
├── fed654cba321.json
└── metadata.json            # Optional: Workspace-level metadata
```

**Mitigation Strategies**:
- Use atomic writes (write temp, then rename)
- Implement file locking with .lock files
- Use jq when available, fall back to bash JSON parsing
- One JSON file per analyzed file (scalable, distributed I/O)

**JSON Schema Example**:
```json
{
  "file_path": "/path/to/document.pdf",
  "file_hash": "abc123def456",
  "last_scanned": "2026-02-08T10:30:00Z",
  "metadata": {
    "type": "application/pdf",
    "size": 2048576,
    "modified": "2026-02-01T14:20:00Z"
  },
  "extracted_data": {
    "author": "John Doe",
    "title": "Sample Document"
  }
}
```

## Related Items

- [ADR-0001](ADR_0001_bash_as_primary_implementation_language.md) - Bash requires external JSON handling
- [ADR-0003](ADR_0003_data_driven_plugin_orchestration.md) - Plugins read/write JSON workspace
- REQ-0008: JSON Workspace for State Persistence

**Trade-offs Accepted**:
- **Simplicity over Performance**: JSON adequate for expected use cases (thousands of files)
- **Human-Readability over Compactness**: Prefer debuggability
- **File-per-Document over Single-Database**: Better scalability, simpler locking
