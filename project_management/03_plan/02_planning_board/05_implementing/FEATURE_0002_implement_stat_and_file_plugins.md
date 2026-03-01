# Implement stat and file Plugins

- **ID:** FEATURE_0002
- **Priority:** CRITICAL
- **Type:** Feature
- **Created at:** 2026-03-01
- **Created by:** Product Owner
- **Status:** IMPLEMENTING

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

Implement the stat and file plugins as working bash scripts that follow the JSON stdin/stdout architecture. These plugins are foundational building blocks required by the walking skeleton (FEATURE_0001) and all future file processing workflows.

**Business Value:**
- Provides essential file metadata extraction capabilities
- Demonstrates plugin implementation pattern for future plugin developers
- Validates JSON stdin/stdout communication works in practice
- Enables FEATURE_0001 (walking skeleton) to function end-to-end

**What this delivers:**
- Working stat plugin that extracts file statistics (size, owner, timestamps)
- Working file plugin that detects MIME types
- Implementation of all three standard commands (process, install, installed) for both plugins
- Reference implementation for future plugin development

**Current State:**
- Plugin descriptors exist and are correct (doc.doc.md/plugins/stat/descriptor.json, doc.doc.md/plugins/file/descriptor.json)
- Plugin shell scripts exist but are empty stubs (main.sh, install.sh, installed.sh)

## Acceptance Criteria

### stat Plugin - process Command (main.sh)

- [ ] `doc.doc.md/plugins/stat/main.sh` is executable (`chmod +x`)
- [ ] Script reads JSON input from stdin
- [ ] Script parses JSON to extract `filePath` parameter
- [ ] Script validates that file path is provided and file exists
- [ ] Script uses `stat` command to gather file information
- [ ] Script outputs valid JSON to stdout with these fields:
  - `fileSize` (number): File size in bytes
  - `fileOwner` (string): File owner (username)
  - `fileCreated` (string): File creation time (ISO 8601 format if possible, or platform format)
  - `fileModified` (string): Last modification time (ISO 8601 format if possible, or platform format)
  - `fileMetadataChanged` (string): Metadata change time (ISO 8601 format if possible, or platform format)
- [ ] Script handles errors gracefully (file not found, no permissions, invalid JSON input)
- [ ] Script exits with code 0 on success, 1 on error
- [ ] Script logs errors to stderr (not stdout)
- [ ] Script works on both Linux and macOS (stat command syntax differs)

**Example interaction:**
```bash
echo '{"filePath":"/path/to/file.pdf"}' | ./main.sh
# Output: {"fileSize":12345,"fileOwner":"user","fileCreated":"2024-01-01T10:00:00Z","fileModified":"2024-01-02T15:30:00Z","fileMetadataChanged":"2024-01-02T15:30:00Z"}
```

### stat Plugin - installed Command (installed.sh)

- [ ] `doc.doc.md/plugins/stat/installed.sh` is executable
- [ ] Script checks if `stat` command is available on the system
- [ ] Script outputs valid JSON to stdout:
  - `installed` (boolean): true if stat command available, false otherwise
- [ ] Script exits with code 0 (always - reporting status, not failing)

**Example interaction:**
```bash
./installed.sh
# Output: {"installed":true}
```

### stat Plugin - install Command (install.sh)

- [ ] `doc.doc.md/plugins/stat/install.sh` is executable
- [ ] Script checks if `stat` command is already available
- [ ] If stat is available, outputs success immediately
- [ ] If stat is not available, outputs informative message (stat is typically pre-installed on Unix systems)
- [ ] Script outputs valid JSON to stdout:
  - `success` (boolean): true if stat is available/installed, false otherwise
  - `message` (string): Human-readable status message
- [ ] Script exits with code 0 on success, 1 if installation is needed but can't be done

**Example interaction:**
```bash
./install.sh
# Output: {"success":true,"message":"stat command already available"}
```

### file Plugin - process Command (main.sh)

- [ ] `doc.doc.md/plugins/file/main.sh` is executable (`chmod +x`)
- [ ] Script reads JSON input from stdin
- [ ] Script parses JSON to extract `filePath` parameter
- [ ] Script validates that file path is provided and file exists
- [ ] Script uses `file --mime-type` command to detect MIME type
- [ ] Script outputs valid JSON to stdout with these fields:
  - `mimeType` (string): MIME type of the file (e.g., "application/pdf", "text/plain")
- [ ] Script handles errors gracefully (file not found, no permissions, invalid JSON input)
- [ ] Script exits with code 0 on success, 1 on error
- [ ] Script logs errors to stderr (not stdout)
- [ ] Script works on both Linux and macOS

**Example interaction:**
```bash
echo '{"filePath":"/path/to/file.pdf"}' | ./main.sh
# Output: {"mimeType":"application/pdf"}
```

### file Plugin - installed Command (installed.sh)

- [ ] `doc.doc.md/plugins/file/installed.sh` is executable
- [ ] Script checks if `file` command is available on the system
- [ ] Script outputs valid JSON to stdout:
  - `installed` (boolean): true if file command available, false otherwise
- [ ] Script exits with code 0 (always - reporting status, not failing)

**Example interaction:**
```bash
./installed.sh
# Output: {"installed":true}
```

### file Plugin - install Command (install.sh)

- [ ] `doc.doc.md/plugins/file/install.sh` is executable
- [ ] Script checks if `file` command is already available
- [ ] If file is available, outputs success immediately
- [ ] If file is not available, provides installation instructions for common platforms
- [ ] Script outputs valid JSON to stdout:
  - `success` (boolean): true if file is available/installed, false otherwise
  - `message` (string): Human-readable status message or installation instructions
- [ ] Script exits with code 0 on success, 1 if installation is needed but can't be done

**Example interaction:**
```bash
./install.sh
# Output: {"success":true,"message":"file command already available"}
```

### Code Quality

- [ ] All scripts use `#!/bin/bash` shebang
- [ ] Scripts follow bash best practices (shellcheck passes)
- [ ] JSON parsing uses `jq` for reliability
- [ ] JSON output generation uses `jq` for correct formatting
- [ ] Error messages are clear and actionable
- [ ] Scripts include comments explaining non-obvious logic
- [ ] Platform-specific code (Linux vs macOS) is handled with conditionals

### Testing

- [ ] Manual testing completed on Linux
- [ ] Manual testing completed on macOS (if available)
- [ ] Tested with valid JSON input
- [ ] Tested with invalid JSON input (malformed, missing fields)
- [ ] Tested with non-existent files
- [ ] Tested with files without read permissions
- [ ] Tested with various file types (PDF, text, images, etc.)

## Scope

### In Scope
✅ stat plugin implementation (main.sh, install.sh, installed.sh)  
✅ file plugin implementation (main.sh, install.sh, installed.sh)  
✅ JSON stdin/stdout communication  
✅ Error handling and validation  
✅ Cross-platform support (Linux and macOS)  
✅ Exit code conventions (0=success, 1=error)  
✅ Using `jq` for JSON parsing/generation  

### Out of Scope
❌ Plugin descriptors (already exist and are correct)  
❌ Additional output fields beyond what's in descriptors  
❌ Windows support (WSL/Git Bash may work but not explicitly tested)  
❌ Automated test suite (manual testing only for walking skeleton)  
❌ Plugin packaging or distribution  
❌ Performance optimization  

## Technical Requirements

### Architecture Compliance

- **ADR-003**: JSON stdin/stdout plugin communication
  - Read input as JSON from stdin
  - Write output as JSON to stdout
  - Use lowerCamelCase parameter names (filePath, fileSize, etc.)
  - Never output non-JSON to stdout (errors to stderr only)

- **Plugin Descriptor Contract**:
  - Implement exactly what's defined in descriptor.json
  - Match input/output parameter names exactly
  - Match output types exactly (number for fileSize, string for others, boolean for installed)

### Implementation Details

**stat Plugin:**
- Use `stat` command (platform-specific syntax handling required)
- Linux: `stat -c` format specifiers
- macOS: `stat -f` format specifiers
- Detect platform with `uname` and use appropriate syntax
- Convert timestamps to ISO 8601 format if possible

**file Plugin:**
- Use `file --mime-type -b` to get MIME type only
- Strip any extra whitespace from output
- Handle cases where file type is unknown

**Both Plugins:**
- Use `jq -r '.filePath'` to extract input parameter
- Use `jq -n` to construct output JSON
- Validate file exists before processing
- Exit code 0 = success, 1 = error
- All errors logged to stderr

### Required Tools
- bash 4.0+
- jq (JSON processor)
- stat command (typically pre-installed on Unix systems)
- file command (typically pre-installed on Unix systems)

## Dependencies

### Blocking Items
None - this feature has no dependencies (can be implemented immediately)

### Blocks These Features
- **FEATURE_0001**: Walking Skeleton - requires working stat and file plugins

### Related Requirements
- **REQ_0003**: Plugin-Based Architecture - Provides reference plugin implementation
- **REQ_SEC_009**: JSON Input Validation - Plugins must validate JSON input

## Related Links

### Architecture Vision
- [ADR-003: JSON Plugin Descriptors](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md)
- [ARC_0003: Plugin Architecture](../../02_project_vision/03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md)

### Requirements
- [REQ_0003: Plugin-Based Architecture](../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin_based_architecture.md)
- [REQ_SEC_009: JSON Input Validation](../../02_project_vision/02_requirements/01_funnel/REQ_SEC_009_json_input_validation.md)

### Plugin Descriptors
- [stat plugin descriptor](../../../doc.doc.md/plugins/stat/descriptor.json)
- [file plugin descriptor](../../../doc.doc.md/plugins/file/descriptor.json)

### Security
- [Plugin Security Documentation](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_007_plugin_security_documentation.md)

## Next Steps

1. **Product Owner**: Review and move to ANALYZE
2. **Architect**: Review implementation approach for architecture compliance
3. **Security**: Review for security considerations (input validation, command injection)
4. **Developer**: Implement plugins following acceptance criteria
5. **Tester**: Perform manual testing on available platforms

## Notes

**Implementation Priority:**
Since FEATURE_0001 depends on this, this feature should be implemented first or in parallel with the doc.doc.sh script development.

**Platform Considerations:**
The stat command has different syntax on Linux vs macOS:
- Linux: `stat -c '%s %U %W %Y %Z' file`
- macOS: `stat -f '%z %Su %B %m %c' file`

Use `uname` to detect platform and adjust accordingly.

**JSON Handling:**
Using `jq` for all JSON operations is critical for:
- Correct JSON parsing (handles escaping, special characters)
- Correct JSON generation (proper quoting, escaping)
- Avoiding manual string manipulation bugs

**Reference Implementation:**
These plugins serve as reference implementations for future plugin developers. Code should be:
- Clear and well-commented
- Following best practices
- Easy to understand for developers new to the project

## Workflow Assessment Log

### Step 5: Tester Assessment
- **Date:** 2026-03-01
- **Agent:** tester.agent
- **Result:** PASS
- **Report:** [TESTREP_001](../../../04_reporting/02_tests_reports/TESTREP_001_FEATURE_0002_stat_file_plugins.md)
- **Summary:** All 52 automated tests pass (0 failures). Both stat and file plugins correctly implement the JSON stdin/stdout architecture, all required output fields, error handling, exit codes, and cross-platform logic. One minor test coverage gap identified: the `fileCreated` field is correctly output by stat/main.sh but has no automated test assertion. macOS testing not possible in current CI environment. Feature meets all acceptance criteria and is ready to advance.
