# Feature: OCR PDF Plugin Integration

**ID**: 0002 
**Type**: Feature Implementation  
**Status**: Implementing  
**Created**: 2026-02-05  
**Updated**: 2026-02-13 (Started implementation)  
**Started**: 2026-02-13T21:25:30Z  
**Developer**: Developer Agent  
**Branch**: copilot/work-on-backlog-items  
**Priority**: Medium

## Overview
Develop a plugin that integrates ocrmypdf CLI tool to perform OCR on PDF files, extracting text content and making PDFs searchable. This plugin will serve as a reference implementation of the accepted plugin architecture.

## Description
Create a plugin module that wraps the ocrmypdf CLI tool following the established plugin architecture (req_0022, req_0023). The plugin will:
- Detect PDF files in the analysis directory
- Execute ocrmypdf to perform optical character recognition on PDF documents
- Extract text content from the OCR results
- Make processed PDFs searchable
- Provide structured output for downstream processing and reporting

The plugin will serve as both a functional tool for PDF analysis and a reference implementation demonstrating the plugin architecture in practice.

## Business Value
- Enables automated extraction of text from scanned PDFs and images embedded in PDFs
- Makes PDF content searchable and analyzable by downstream tools
- Demonstrates the extensibility of the toolkit through practical example
- Provides foundation for document analysis workflows

## Related Requirements
- [req_0022](../../01_vision/02_requirements/03_accepted/req_0022_plugin_based_extensibility.md) - Plugin-based Extensibility
- [req_0023](../../01_vision/02_requirements/03_accepted/req_0023_data_driven_execution_flow.md) - Data-driven Execution Flow
- [req_0007](../../01_vision/02_requirements/03_accepted/req_0007_tool_availability_verification.md) - Tool Availability Verification
- [req_0008](../../01_vision/02_requirements/03_accepted/req_0008_installation_prompts.md) - Installation Prompts

## Acceptance Criteria

### Plugin Structure
- [ ] Plugin directory structure follows established pattern (`plugins/<platform>/ocrmypdf/`)
- [ ] Plugin includes `descriptor.json` with complete metadata
- [ ] Plugin includes platform-specific installation script (`install.sh` for Linux/Unix)
- [ ] Plugin code/scripts are self-contained within plugin directory

### Descriptor Requirements
- [ ] Descriptor declares plugin name, description, and active status
- [ ] Descriptor includes `processes` field with file filtering criteria:
  - `mime_types`: ["application/pdf"]
  - `file_extensions`: [".pdf"]
- [ ] Descriptor specifies data inputs (consumes) with type and description:
  - `file_path_absolute` (string): Absolute path to the PDF file
- [ ] Descriptor specifies data outputs (provides) with type and description:
  - `ocr_text_content` (string): Extracted text content
  - `ocr_status` (string): Processing status (success, failed, skipped)
  - `ocr_confidence` (number): OCR confidence score if available
- [ ] Descriptor includes `commandline` field using proper `read -r` pattern for all outputs  
- [ ] Descriptor includes `check_commandline` field to verify tool availability
- [ ] Descriptor includes `install_commandline` field to run installation script
- [ ] Descriptor follows unified plugin schema per ADR-0010

### Functionality
- [ ] Plugin detects PDF files based on file type/extension

## Test Coverage

### Test Suite: test_ocrmypdf_plugin.sh
Comprehensive unit tests created following TDD approach. Test coverage includes:

#### Plugin Structure (4 tests)
- ✓ Plugin directory exists at expected location
- ✓ descriptor.json file exists
- ✓ install.sh file exists
- ✓ install.sh is executable

#### Descriptor Schema Compliance (4 tests)
- ✓ descriptor.json is valid JSON
- ✓ Descriptor has correct name ("ocrmypdf")
- ✓ Descriptor has description (minimum 10 characters)
- ✓ Descriptor has active flag (boolean)

#### File Type Processing (2 tests)
- ✓ Processes application/pdf MIME type
- ✓ Processes .pdf file extension

#### Data Inputs - Consumes (3 tests)
- ✓ Consumes file_path_absolute field
- ✓ file_path_absolute type is string
- ✓ file_path_absolute has description

#### Data Outputs - Provides (7 tests)
- ✓ Provides ocr_text_content field (type: string)
- ✓ Provides ocr_status field (type: string)
- ✓ Provides ocr_confidence field (type: number)
- ✓ All provided fields have descriptions
- ✓ Provides keys are alphabetically sorted (jq ordering)

#### Command Configuration (7 tests)
- ✓ Has commandline field
- ✓ commandline uses ${file_path_absolute} variable
- ✓ commandline mentions ocrmypdf
- ✓ Has check_commandline field
- ✓ check_commandline verifies ocrmypdf availability
- ✓ Has install_commandline field
- ✓ install_commandline references install.sh script

#### Output Format Validation (2 tests)
- ✓ Output count matches provides field count
- ✓ Provides keys alphabetically sorted for consistent mapping

#### Install Script Validation (3 tests)
- ✓ Has bash shebang
- ✓ Checks ocrmypdf tool availability before install
- ✓ Contains copyright and GPL license header

#### Security and Safety (2 tests)
- ✓ No dangerous command patterns (rm -rf, sudo, etc.)
- ✓ file_path_absolute properly quoted (injection prevention)

#### Integration Tests (2 tests)
- ✓ Plugin passes validation system checks
- ✓ Error handling design documented

**Total: 37 comprehensive tests** covering all acceptance criteria

### Test Execution
Run tests with:
```bash
./tests/unit/test_ocrmypdf_plugin.sh
```

### Expected Behavior (TDD)
Tests define the following expected behavior before implementation:

1. **Plugin must be self-contained** in `scripts/plugins/ubuntu/ocrmypdf/` directory
2. **Descriptor must be valid JSON** with all required fields
3. **File filtering**: Only process PDF files (application/pdf, .pdf)
4. **Input**: Absolute file path as string
5. **Output**: Three comma-separated values in alphabetical key order:
   - ocr_confidence (number)
   - ocr_status (string: success/failed/skipped)
   - ocr_text_content (string)
6. **Commands**: Must check availability, execute OCR, and provide installation
7. **Security**: Proper quoting, no dangerous patterns
8. **Licensing**: GPL v3 headers required

### Next Steps for Developer
1. Create plugin directory structure
2. Implement descriptor.json matching test expectations
3. Create install.sh with ocrmypdf installation logic
4. Run tests to verify implementation
5. Fix any failing tests iteratively
