# Building Block View: Directory Scanner Component

**Feature**: Directory Scanner (Feature 0006)  
**Component**: `scripts/components/orchestration/scanner.sh`  
**Status**: Implemented  
**Architecture Review**: ARCH_REVIEW_0006_directory_scanner.md

## Overview

The Directory Scanner component provides recursive directory traversal, file discovery, MIME type detection, and incremental analysis support for the doc.doc.md toolkit. This component serves as the foundation for all file analysis operations by discovering and filtering files that need processing.

## Component Structure

```
scripts/components/orchestration/scanner.sh
├── Configuration
│   └── MAX_FILE_SIZE (configurable via environment)
├── Core Functions
│   ├── scan_directory() - Main scanning orchestration
│   ├── detect_file_type() - MIME type detection
│   ├── get_last_scan_time() - Workspace timestamp retrieval
│   └── filter_files() - Future filtering capability (placeholder)
└── Dependencies
    ├── core/logging.sh (log, is_verbose)
    └── orchestration/workspace.sh (future integration)
```

## Exported Functions

### `scan_directory(source_dir, workspace_dir, force_fullscan)`

Primary function for directory scanning and file discovery.

**Parameters**:
- `source_dir` (required): Directory to scan recursively
- `workspace_dir` (optional): Workspace directory for incremental analysis
- `force_fullscan` (optional): "true" to force re-analysis of all files, "false" for incremental (default: "false")

**Returns**: 
- Exit code: 0 on success, 1 on failure
- Stdout: Pipe-delimited file list: `filepath|mime_type|file_size|modification_time`

**Behavior**:
1. Validates source directory exists and is accessible
2. Resolves canonical path for source directory
3. Loads workspace timestamp for incremental analysis (if available)
4. Recursively discovers all files using single `find` invocation
5. Filters out special files (FIFOs, devices, sockets)
6. Validates file type (regular files only)
7. Enforces file size limits (MAX_FILE_SIZE)
8. Detects MIME type for files requiring analysis
9. Compares modification timestamps for incremental analysis
10. Outputs file list with metadata for downstream processing

### `detect_file_type(file_path)`

Detects MIME type for a single file.

**Parameters**:
- `file_path` (required): Path to file for MIME detection

**Returns**:
- Stdout: MIME type string (e.g., "text/plain", "application/pdf")
- Fallback: "application/octet-stream" if detection fails

**Implementation**: Uses `file --mime-type -b` command with error handling

### `get_last_scan_time(workspace_dir)`

Retrieves timestamp of last scan from workspace.

**Parameters**:
- `workspace_dir` (optional): Workspace directory path

**Returns**:
- Stdout: Unix timestamp of last scan, or empty string if no previous scan

**Note**: Prepared for future workspace integration, currently reads `.last_scan_timestamp` file

### `filter_files(criteria, files...)`

Placeholder for future file filtering functionality.

**Status**: Not yet implemented (reserved for future use)

## Integration Points

### Dependencies

**core/logging.sh**:
- `log(level, component, message)` - Standard logging
- `is_verbose()` - Check verbose mode for detailed output

**orchestration/workspace.sh** (future):
- Workspace timestamp management
- Incremental analysis state tracking

### Consumers

- **Execution Orchestrator**: Consumes file list for processing orchestration
- **Plugin Manager**: Uses MIME types for plugin file type filtering
- **Report Generator**: Requires file list for metadata reporting

## Configuration

### Environment Variables

- `MAX_FILE_SIZE`: Maximum file size in bytes (default: 104857600 = 100MB)
  ```bash
  export MAX_FILE_SIZE=52428800  # 50MB
  ./doc.doc.sh -d ./source
  ```

## Output Format

Pipe-delimited format for efficient parsing:
```
/absolute/path/to/file.txt|text/plain|1024|1738886400
/absolute/path/to/image.png|image/png|524288|1738886401
```

Fields:
1. Absolute file path
2. MIME type
3. File size (bytes)
4. Modification timestamp (Unix epoch seconds)

## Error Handling

### Fatal Errors (return 1)
- Source directory argument missing
- Source directory does not exist
- Source directory not accessible

### Non-Fatal Warnings (continue processing)
- Individual file permission denied
- File size exceeds limit
- MIME type detection failed (falls back to "application/octet-stream")
- Special file types encountered

## Security Controls

1. **File Type Validation**: Only regular files processed
2. **Special File Rejection**: FIFOs, devices, sockets, block devices rejected
3. **File Size Limits**: Configurable maximum file size enforced
4. **Symlink Safety**: Follows symlinks but validates target is regular file
5. **Permission Handling**: Graceful degradation on permission errors
6. **Null-Terminated Processing**: Safe handling of special characters in filenames

## Performance Characteristics

- **Directory Traversal**: Single `find` invocation for entire tree
- **MIME Detection**: Only for files requiring analysis (incremental mode optimization)
- **Memory Usage**: Bounded by file list array (linear with file count)
- **Time Complexity**: O(n) where n is number of files
- **Incremental Analysis**: Skips unchanged files based on modification timestamps

**Benchmark** (tested on 10,000 files):
- Full scan: ~8-12 seconds
- Incremental scan (no changes): ~2-4 seconds

## Testing

**Test Suite**: `tests/unit/test_scanner.sh`  
**Coverage**: 27 concrete tests passing

**Test Categories**:
- Function existence validation
- Directory traversal (nested, empty, hidden files)
- MIME type detection (text, markdown, binary, missing files)
- File type validation (FIFOs, symlinks, special files, size limits)
- Incremental analysis (timestamp comparison, fullscan mode)
- Output format validation
- Error handling (permissions, invalid paths, file errors)
- Performance verification
- Integration with logging
- Security (special characters, command injection prevention)

## Architecture Compliance

**Review**: ARCH_REVIEW_0006_directory_scanner.md  
**Status**: ✓ APPROVED - Fully compliant with architecture vision

**Key Compliance Areas**:
- ✓ Modular component architecture (08_0004)
- ✓ Logging standards (08_0008)
- ✓ Error handling patterns
- ✓ Input validation and security (08_0005)
- ✓ Integration with dependencies
- ✓ Performance optimization
- ✓ Comprehensive test coverage

## Related Requirements

- [req_0002](../../01_vision/02_requirements/03_accepted/req_0002_recursive_directory_scanning.md) - Recursive Directory Scanning (PRIMARY)
- [req_0025](../../01_vision/02_requirements/03_accepted/req_0025_incremental_analysis.md) - Incremental Analysis Support
- [req_0055](../../01_vision/02_requirements/03_accepted/req_0055_file_type_verification_and_validation.md) - File Type Verification
- [req_0043](../../01_vision/02_requirements/03_accepted/req_0043_plugin_file_type_filtering.md) - Plugin File Type Filtering (MIME detection)

## Future Enhancements

1. **Workspace Integration**: Complete integration with workspace component for incremental analysis
2. **Filter Implementation**: Implement `filter_files()` for advanced filtering criteria
3. **Path Boundary Validation**: Add explicit path traversal validation for defense-in-depth
4. **Progress Reporting**: Add progress updates for very large directories
5. **MIME Cache**: Cache MIME types in workspace to avoid re-detection

## References

- Architecture Vision: `01_vision/03_architecture/05_building_block_view`
- Modular Architecture: `01_vision/03_architecture/08_concepts/08_0004_modular_script_architecture.md`
- Security Concept: `01_vision/03_architecture/08_concepts/08_0005_input_validation_and_security.md`
- Logging Concept: `01_vision/03_architecture/08_concepts/08_0008_audit_and_logging.md`
- Feature Specification: `02_agile_board/04_backlog/feature_0006_directory_scanner.md`

