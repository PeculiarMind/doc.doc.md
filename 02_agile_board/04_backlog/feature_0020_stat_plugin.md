# Feature: File Statistics Plugin (stat)

**ID**: 0020  
**Type**: Feature Implementation  
**Status**: Backlog  
**Created**: 2026-02-10  
**Updated**: 2026-02-10 (Moved to backlog)  
**Priority**: High

## Overview
Implement a basic file statistics plugin using the `stat` command to extract essential filesystem metadata including last modified time, file size, and owner information for all analyzed files.

## Description
Create a foundational plugin that retrieves core filesystem metadata for every file in the analysis workflow using the POSIX `stat` command. This plugin provides essential file properties that form the baseline metadata for all documents, enabling incremental analysis (timestamp comparison), file filtering (size-based), and audit/compliance reporting (owner tracking).

The stat plugin is a critical baseline plugin that should execute for all files regardless of type, providing the fundamental metadata layer that other plugins and reporting features depend on. Unlike specialized plugins that process specific file types, stat provides universal filesystem information applicable to any file.

## Business Value
- Provides essential file metadata for incremental analysis (compare modification times)
- Enables size-based filtering and reporting (identify large files, calculate storage)
- Supports audit and compliance requirements (track file ownership)
- Forms baseline metadata layer for all file analysis workflows
- Zero external dependencies (uses standard POSIX `stat` command)
- Critical foundation for workspace timestamp management

## Related Requirements
- [req_0022](../../01_vision/02_requirements/03_accepted/req_0022_plugin_based_extensibility.md) - Plugin-based Extensibility
- [req_0023](../../01_vision/02_requirements/03_accepted/req_0023_data_driven_execution_flow.md) - Data-driven Execution Flow
- [req_0025](../../01_vision/02_requirements/03_accepted/req_0025_incremental_analysis.md) - Incremental Analysis Support (PRIMARY)
- [req_0007](../../01_vision/02_requirements/03_accepted/req_0007_tool_availability_verification.md) - Tool Availability Verification

## Acceptance Criteria

### Plugin Structure
- [ ] Plugin directory structure: `scripts/plugins/ubuntu/stat/`
- [ ] Plugin includes `descriptor.json` with complete metadata
- [ ] Plugin includes `install.sh` script (minimal, stat is usually pre-installed)
- [ ] Plugin code self-contained within plugin directory

### Descriptor Requirements
- [ ] Descriptor declares plugin name: "stat"
- [ ] Descriptor includes description of plugin functionality
- [ ] Descriptor sets `active: true` for automatic execution
- [ ] Descriptor includes `processes` field (empty for universal plugin - applies to all files)
- [ ] Descriptor specifies data inputs (consumes) with type and description:
  - `file_path_absolute` (string): Absolute path to the file to analyze
- [ ] Descriptor specifies data outputs (provides) with type and description:
  - `file_last_modified` (integer): Last modified time as Unix timestamp
  - `file_size` (integer): File size in bytes
  - `file_owner` (string): Owner username
- [ ] Descriptor includes `commandline` field using `stat -c` format with variable substitution
- [ ] Descriptor includes `check_commandline` to verify `stat` command availability
- [ ] Descriptor includes `install_commandline` for installation (no-op on most systems)
- [ ] Descriptor follows unified plugin schema per ADR-0010

### File Type Filtering
- [ ] Plugin applies to ALL file types (`processes` object with no restrictions)
- [ ] Plugin executes for every file discovered by directory scanner
- [ ] Plugin processes field allows universal execution (no MIME type or extension filters)

### Functionality
- [ ] Plugin extracts last modified timestamp using `stat -c %Y` 
- [ ] Plugin extracts file size in bytes using `stat -c %s`
- [ ] Plugin extracts file owner username using `stat -c %U`  
- [ ] Plugin uses command template with `${file_path_absolute}` variable substitution
- [ ] Plugin outputs data in comma-separated format compatible with `read -r` parsing
- [ ] Plugin handles files with spaces, special characters in paths via proper quoting
- [ ] Plugin executes in Bubblewrap sandbox per ADR-0009 (mandatory sandboxing)
- [ ] Plugin follows command template execution model per ADR-0010

### Integration
- [ ] Plugin outputs map to workspace JSON structure per orchestrator design:
  - `file_last_modified` → workspace metadata
  - `file_size` → workspace metadata  
  - `file_owner` → workspace metadata
- [ ] Plugin metadata available for incremental analysis timestamp comparison
- [ ] Plugin metadata available for reporting and aggregation
- [ ] Plugin works with verbose logging mode (req_0006)
- [ ] Plugin respects data-driven execution flow (req_0023)
- [ ] Plugin executes in sandboxed environment with command template approach

### Error Handling
- [ ] Plugin handles files that don't exist (deleted between scan and execution)
- [ ] Plugin handles permission denied errors gracefully
- [ ] Plugin logs errors appropriately without failing entire analysis
- [ ] Plugin provides clear error messages in case of stat command failure

### Testing
- [ ] Plugin tested with regular files
- [ ] Plugin tested with files of various sizes (0 bytes, large files)
- [ ] Plugin tested with files owned by different users
- [ ] Plugin tested with files having recent vs old modification times
- [ ] Plugin tested with filenames containing spaces and special characters
- [ ] Plugin tested with missing stat command (error handling)

## Technical Considerations

### stat Command
- Standard POSIX utility available on all Unix/Linux systems
- Format specifiers using `-c` flag:
  - `%Y` - Last modification time as Unix timestamp (seconds since epoch)
  - `%s` - File size in bytes
  - `%U` - Owner username
  - `%W` - File creation time (birth time, may be 0 if unsupported)
- Reliable, fast, no external dependencies

### Implementation Approach

**descriptor.json**:
```json
{
  "name": "stat",
  "description": "Retrieves file statistics such as last modified time, size, and owner using the stat command.",
  "active": true,
  "provides": {
    "file_last_modified": {
      "type": "integer",
      "description": "Last modified time as Unix timestamp."
    },
    "file_size": {
      "type": "integer",
      "description": "Size of the file in bytes."
    },
    "file_owner": {
      "type": "string",
      "description": "Owner of the file."
    }
  },
  "consumes": {
    "file_path_absolute": {
      "type": "string",
      "description": "Path to the file to be analyzed."
    }
  },
  "commandline": "read -r file_last_modified file_size file_owner < <(stat -c %Y,%s,%U \"${file_path_absolute}\" 2>/dev/null || echo '0,0,unknown')",
  "check_commandline": "read -r plugin_works < <(which stat > /dev/null 2>&1 && echo 'true' || echo 'false')",
  "install_commandline": "read -r plugin_successfully_installed < <(echo 'true')"
}
```

**install.sh**:
```bash
#!/bin/bash
# stat is part of GNU coreutils, typically pre-installed
# Installation only needed if missing

if ! command -v stat &> /dev/null; then
    apt-get update
    apt-get install -y coreutils
fi
```

### Output Format
The `commandline` uses `stat -c %Y,%s,%U` to output comma-separated values:
- Example output: `1707577200,2048576,docuser`
- Parsed into variables: file_last_modified=1707577200, file_size=2048576, file_owner=docuser
- Error handling: outputs `0,0,unknown` if stat fails

### Performance Considerations
- stat is extremely fast (syscall-level operation)
- No significant performance impact even for large file sets
- Should execute inline (not background) as baseline metadata

### Platform Compatibility
- Linux: Full support with GNU coreutils stat
- macOS/BSD: Different stat syntax (uses `-f` instead of `-c`), requires platform-specific implementation
- This implementation targets Ubuntu/Linux (as indicated by plugin path)

## Dependencies
- GNU coreutils (stat command) - typically pre-installed on all Linux systems
- No other dependencies

## Estimated Effort
Small (1-2 hours) - Simple descriptor, minimal installation script, basic testing

## Notes
- This is a universal plugin (no file type filtering) - runs on ALL files
- Critical for feature_0006 (Directory Scanner) incremental analysis support
- Should be one of the first plugins implemented as other features depend on it
- Consider adding `file_created` (birth time, %W) if filesystem supports it
- Future enhancement: Platform-specific versions for macOS/BSD

## Transition History
- [2026-02-10] Created by Requirements Engineer Agent - derived from existing stat plugin implementation for formal feature tracking
