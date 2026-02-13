# Tester Agent Handover: Feature 0002 OCRmyPDF Plugin

**Date**: 2026-02-13  
**Feature**: feature_0002_ocrmypdf_plugin.md  
**Branch**: copilot/work-on-backlog-items  
**Status**: Tests Complete - Ready for Implementation

## Summary
Comprehensive test suite created for OCRmyPDF plugin feature following TDD (Test-Driven Development) approach. All 37 tests define expected behavior before implementation, ensuring clear acceptance criteria.

## Test Artifacts Created

### 1. Unit Test Suite
**File**: `tests/unit/test_ocrmypdf_plugin.sh`
- 37 comprehensive tests
- Covers all acceptance criteria from feature specification
- Follows existing test patterns from project
- Executable with proper permissions

### 2. Test Coverage Documentation
Updated `02_agile_board/05_implementing/feature_0002_ocrmypdf_plugin.md` with:
- Complete test coverage breakdown
- Test execution instructions
- Expected behavior definitions
- Next steps for developer

## Test Categories

### Plugin Structure (4 tests)
- Directory existence
- Required files (descriptor.json, install.sh)
- File permissions

### Schema Compliance (4 tests)
- Valid JSON format
- Required metadata fields (name, description, active)
- Naming conventions

### File Processing (2 tests)
- MIME type filtering (application/pdf)
- Extension filtering (.pdf)

### Data Contracts (13 tests)
**Consumes** (3 tests):
- file_path_absolute field with correct type and description

**Provides** (7 tests):
- ocr_text_content (string)
- ocr_status (string)
- ocr_confidence (number)
- All with descriptions and proper types

**Output Format** (2 tests):
- Alphabetical key ordering
- Output count matches field count

### Command Configuration (7 tests)
- commandline field with variable substitution
- check_commandline for tool availability
- install_commandline referencing install.sh
- Proper use of ocrmypdf command

### Install Script (3 tests)
- Bash shebang
- Tool availability check
- GPL license header

### Security (2 tests)
- No dangerous command patterns
- Proper quoting for injection prevention

### Integration (2 tests)
- Plugin validation system compatibility
- Error handling design

## Key Implementation Requirements Defined by Tests

### 1. Directory Structure
```
scripts/plugins/ubuntu/ocrmypdf/
├── descriptor.json
└── install.sh (executable)
```

### 2. Descriptor.json Schema
```json
{
  "name": "ocrmypdf",
  "description": "<min 10 chars>",
  "active": true,
  "processes": {
    "mime_types": ["application/pdf"],
    "file_extensions": [".pdf"]
  },
  "consumes": {
    "file_path_absolute": {
      "type": "string",
      "description": "..."
    }
  },
  "provides": {
    "ocr_confidence": {
      "type": "number",
      "description": "..."
    },
    "ocr_status": {
      "type": "string",
      "description": "..."
    },
    "ocr_text_content": {
      "type": "string",
      "description": "..."
    }
  },
  "commandline": "...'${file_path_absolute}'...",
  "check_commandline": "command -v ocrmypdf ...",
  "install_commandline": "...install.sh"
}
```

**Note**: Keys in `provides` are alphabetically sorted by jq, so output order must be:
1. ocr_confidence
2. ocr_status
3. ocr_text_content

### 3. Output Format
Command must output 3 comma-separated values matching alphabetical key order:
```
<confidence_number>,<status_string>,<text_content_string>
```

### 4. Install Script Requirements
- Bash shebang
- Check if ocrmypdf already installed
- Install ocrmypdf if missing
- GPL v3 copyright header

### 5. Security Requirements
- Proper quoting of `${file_path_absolute}` variable
- No dangerous commands (rm -rf, sudo in commandline)
- Safe command construction

## Test Execution

Run test suite:
```bash
./tests/unit/test_ocrmypdf_plugin.sh
```

Expected initial result: **All tests should FAIL** (TDD red phase) until implementation is complete.

## Handover to Developer Agent

### Developer Tasks
1. Create plugin directory: `scripts/plugins/ubuntu/ocrmypdf/`
2. Implement `descriptor.json` following schema above
3. Implement `install.sh` with:
   - GPL v3 header
   - Tool availability check
   - ocrmypdf installation logic
4. Make install.sh executable
5. Run tests iteratively until all pass (TDD green phase)
6. Refactor if needed while keeping tests passing (TDD refactor phase)

### Success Criteria
✓ All 37 tests pass  
✓ Plugin follows unified schema (ADR-0010)  
✓ Plugin integrates with existing plugin system  
✓ Security checks pass  
✓ Installation script works correctly

### Reference Materials
- Existing plugin: `scripts/plugins/ubuntu/stat/`
- Test patterns: `tests/unit/test_plugin_validation.sh`
- Plugin validation: `scripts/components/plugin/plugin_validator.sh`

## Notes
- Tests follow existing project patterns and conventions
- All tests are non-destructive and use temporary directories
- Tests validate both structure and security requirements
- Integration test checks compatibility with plugin validation system
- Documentation updated in feature work item

---

**Tester Agent**: Tests complete and ready for implementation  
**Status**: Awaiting Developer Agent implementation  
**Next**: Developer Agent should implement plugin to pass all tests
