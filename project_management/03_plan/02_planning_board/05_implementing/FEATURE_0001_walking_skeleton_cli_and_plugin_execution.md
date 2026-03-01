# Walking Skeleton: CLI Entry Point, Filtering, and Plugin Execution

- **ID:** FEATURE_0001
- **Priority:** CRITICAL
- **Type:** Feature
- **Created at:** 2026-03-01
- **Created by:** Product Owner
- **Status:** IMPLEMENTING
- **Assigned to:** developer.agent

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

This feature implements the first end-to-end walking skeleton for doc.doc.md, demonstrating the core architecture working from CLI entry point through file filtering and plugin execution to result collection. It establishes the foundational pattern for all future features.

**Business Value:**
- Validates the core architecture decisions (JSON stdin/stdout plugin communication, Python filtering)
- Provides a working baseline for iterative development
- Demonstrates end-to-end flow with real-world filtering capabilities
- Enables early testing of plugin integration and filtering patterns

**What this delivers:**
- Executable doc.doc.sh script that can process files from input directory
- Python filter engine with include/exclude logic (AND/OR operators)
- Working integration with stat and file plugins via JSON stdin/stdout
- Proof that ADR-003 (JSON plugin parameter passing) and ARC-0001 (filtering logic) work in practice
- Foundation for adding templating and directory mirroring later

## Acceptance Criteria

### CLI Entry Point
- [ ] `doc.doc.sh` script exists in repository root and is executable (`chmod +x`)
- [ ] Script accepts `process` command with `-d <input-dir>` argument (input directory)
- [ ] Script accepts optional `-i <criteria>` argument(s) for include filters (repeatable)
- [ ] Script accepts optional `-e <criteria>` argument(s) for exclude filters (repeatable)
- [ ] Script validates that input directory exists and is readable
- [ ] Script displays usage help with `--help` or when arguments are invalid
- [ ] Script exits with code 0 on success, non-zero on errors

### File Discovery and Filtering
- [ ] Script uses `find` to discover all files in input directory recursively
- [ ] Script pipes file paths to Python filter engine (`components/filter.py`)
- [ ] Filter engine accepts include criteria via `--include` arguments
- [ ] Filter engine accepts exclude criteria via `--exclude` arguments
- [ ] Filter supports file extensions (e.g., `-i ".pdf,.txt"`)
- [ ] Filter supports glob patterns (e.g., `-i "**/2024/**"`, `-e "**/temp/**"`)
- [ ] Include logic: OR within parameter, AND between parameters (per ARC-0001)
  - Example: `-i ".pdf,.txt" -i "**/2024/**"` = (pdf OR txt) AND (path contains 2024)
- [ ] Exclude logic: OR within parameter, AND between parameters
  - Example: `-e ".log" -e "**/temp/**"` = (log) AND (path contains temp) → excluded
- [ ] Filter outputs matching file paths to stdout (one per line)
- [ ] Filter handles invalid patterns gracefully with clear error messages

### Plugin Discovery
- [ ] Script discovers plugins by scanning `doc.doc.md/plugins/` directory
- [ ] Script loads and validates `descriptor.json` for stat and file plugins
- [ ] Script validates descriptor against schema (required fields: name, version, description, commands)
- [ ] Script handles missing or malformed descriptors gracefully with clear error messages

### Plugin Execution - stat Plugin
- [ ] Script invokes `doc.doc.md/plugins/stat/main.sh` with JSON input via stdin
- [ ] JSON input contains `{"filePath": "/path/to/file"}` matching descriptor schema
- [ ] Stat plugin returns valid JSON output via stdout containing:
  - `fileSize` (number): File size in bytes
  - `fileOwner` (string): File owner
  - `fileCreated` (string): Creation timestamp
  - `fileModified` (string): Last modified timestamp
  - `fileMetadataChanged` (string): Metadata change timestamp
- [ ] Script captures and parses stat plugin JSON output
- [ ] Script handles stat plugin errors (non-zero exit code, invalid JSON, missing fields)

### Plugin Execution - file Plugin
- [ ] Script invokes `doc.doc.md/plugins/file/main.sh` with JSON input via stdin
- [ ] JSON input contains `{"filePath": "/path/to/file"}` matching descriptor schema
- [ ] File plugin returns valid JSON output via stdout containing:
  - `mimeType` (string): MIME type of the file
- [ ] Script captures and parses file plugin JSON output
- [ ] Script handles file plugin errors (non-zero exit code, invalid JSON, missing fields)

### Result Collection
- [ ] Script collects outputs from both plugins into single JSON structure
- [ ] Combined JSON output printed to stdout in valid JSON format
- [ ] Combined output contains all fields from both plugins
- [ ] Example output structure:
  ```json
  {
    "filePath": "/input/test.pdf",
    "fileSize": 12345,
    "fileOwner": "user",
    "fileCreated": "2024-01-01T10:00:00Z",
    "fileModified": "2024-01-02T15:30:00Z",
    "fileMetadataChanged": "2024-01-02T15:30:00Z",
    "mimeType": "application/pdf"
  }
  ```

### Error Handling
- [ ] Clear error message when input file not found
- [ ] Clear error message when plugin not found or not executable
- [ ] Clear error message when plugin returns invalid JSON
- [ ] Clear error message when plugin exits with error code
- [ ] Script continues with partial results if one plugin fails (graceful degradation)

### Code Quality
- [ ] Code follows Bash best practices (shellcheck passes)
- [ ] Functions are well-named and have single responsibilities
- [ ] Comments explain non-obvious logic
- [ ] Error messages are actionable and user-friendly

## Scope

### In Scope
✅ doc.doc.sh CLI entry point with argument parsing (`-d`, `-i`, `-e`)  
✅ Python filter engine with include/exclude logic (AND/OR operators)  
✅ File extension filtering (`.pdf`, `.txt`, etc.)  
✅ Glob pattern filtering (`**/2024/**`, `**/temp/**`, etc.)  
✅ Plugin descriptor discovery and validation  
✅ JSON stdin/stdout parameter passing (implementing ADR-003)  
✅ stat plugin integration  
✅ file plugin integration  
✅ Multiple file processing (filtered files from input directory)  
✅ Result collection and JSON output (one JSON object per processed file)  
✅ Basic error handling and exit codes  

### Explicitly Out of Scope
❌ Template processing (deferred to future feature)  
❌ MIME type filtering (requires plugin execution before filtering - deferred)  
❌ Directory structure mirroring (deferred)  
❌ Plugin dependency resolution (deferred)  
❌ Plugin management commands (list, activate, deactivate, install) (deferred)  
❌ Progress indication (deferred)  
❌ Logging framework (deferred)  

## Technical Requirements

### Architecture Compliance
- **ADR-001**: Mixed Bash/Python Implementation
  - Bash for CLI orchestration and workflow coordination
  - Python for complex filtering logic (filter.py)
  
- **ADR-003**: Implement JSON stdin/stdout plugin parameter passing
  - Plugins receive input as JSON object via stdin
  - Plugins return output as JSON object via stdout
  - Parameter names use lowerCamelCase (e.g., `filePath`, not `FILE_PATH`)
  
- **ARC-0001**: Filtering Logic
  - File extension filtering (`.pdf`, `.txt`)
  - Glob pattern filtering (`**/path/**`)
  - Include: OR within parameter, AND between parameters
  - Exclude: OR within parameter, AND between parameters
  
- **ARC_0003**: Follow plugin architecture concept
  - Use descriptor.json for plugin metadata
  - Invoke plugins via shell command specified in descriptor
  - Standard commands: process, install, installed

### Plugin Descriptors
Use existing descriptors:
- `doc.doc.md/plugins/stat/descriptor.json`
- `doc.doc.md/plugins/file/descriptor.json`

Both already conform to current schema (lowerCamelCase, JSON I/O).

### Implementation Language
- **Bash** for doc.doc.sh orchestration (per ADR-001)
- **Python 3.12+** for filter engine (components/filter.py)
- Use `jq` for JSON parsing and generation
- POSIX-compliant where possible for portability

### Required Tools
- bash 4.0+
- Python 3.12+ (standard library only: pathlib, fnmatch, sys, argparse)
- jq (JSON processor)
- find (Unix utility)
- plugins may require: stat, file commands (system utilities)

## Dependencies

### Blocking Items
- **FEATURE_0002**: Implement stat and file Plugins - This feature requires working stat and file plugins to function end-to-end

### Related Requirements
- **REQ_0001**: Command-Line Tool - ✅ Implemented via doc.doc.sh
- **REQ_0003**: Plugin-Based Architecture - ✅ Implemented via plugin discovery and execution
- **REQ_0009**: Process Command - ✅ Fully implemented with filtering (except MIME type filtering)

### Security Requirements
- **REQ_SEC_009**: JSON Input Validation - Should validate JSON output from plugins
- Input file path validation (path traversal prevention)

## Related Links

### Architecture Vision
- [ADR-001: Mixed Bash/Python Implementation](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_001_mixed_bash_python_implementation.md)
- [ADR-003: JSON Plugin Descriptors](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md)
- [ARC_0001: Filtering Logic](../../02_project_vision/03_architecture_vision/08_concepts/ARC_0001_filtering_logic.md)
- [ARC_0003: Plugin Architecture](../../02_project_vision/03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md)
- [Building Block View](../../02_project_vision/03_architecture_vision/05_building_block_view/05_building_block_view.md)

### Requirements
- [REQ_0001: Command-Line Tool](../../02_project_vision/02_requirements/03_accepted/REQ_0001_command_line_tool.md)
- [REQ_0003: Plugin-Based Architecture](../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin_based_architecture.md)
- [REQ_0009: Process Command](../../02_project_vision/02_requirements/03_accepted/REQ_0009_process_command.md)

### Plugin Descriptors
- [stat plugin descriptor](../../../doc.doc.md/plugins/stat/descriptor.json)
- [file plugin descriptor](../../../doc.doc.md/plugins/file/descriptor.json)

### Workflows
- [Implementation Workflow](../../01_guidelines/workflows/implementation_workflow.md)

## Next Steps

1. **Product Owner**: Review and move to ANALYZE if acceptance criteria are clear
2. **Architect**: Review technical requirements for architecture compliance
3. **Security**: Review for security considerations (input validation, plugin execution)
4. **Developer**: Analyze implementation approach and estimate effort
5. **Tester**: Create test plan once moved to READY

## Notes

This walking skeleton demonstrates core capabilities:
- Validates architecture decisions (JSON I/O, Python filtering, plugin integration)
- Provides working baseline for all file processing workflows
- Enables early testing and feedback on real-world scenarios
- Includes filtering to make it genuinely useful for testing

Future features will add:
- Template processing (FEATURE_0002 - proposed)
- Directory structure mirroring (FEATURE_0003 - proposed)
- Plugin management commands (FEATURE_0004 - proposed)
- MIME type filtering (FEATURE_0005 - proposed - requires pre-filtering plugin execution)
