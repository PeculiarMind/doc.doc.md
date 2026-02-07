# Feature: OCR PDF Plugin Integration

**ID**: 0002 
**Type**: Feature Implementation  
**Status**: Ready  
**Created**: 2026-02-05  
**Updated**: 2026-02-07 (Architecture alignment corrections, moved to ready)  
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
  - `ocr_text_content` (string): Extracted text content (maps to workspace `content.text`)
  - `ocr_status` (string): Processing status (success, failed, skipped)
  - `ocr_confidence` (number): OCR confidence score if available
- [ ] Descriptor includes `execute_commandline` field using proper `read -r` pattern for all outputs
- [ ] Descriptor includes `check_commandline` field to verify tool availability
- [ ] Descriptor includes `install_commandline` field to run installation script
- [ ] Descriptor follows JSON schema used by other plugins and architecture specifications

### Functionality
- [ ] Plugin detects PDF files based on file type/extension
- [ ] Plugin executes ocrmypdf with appropriate parameters
- [ ] Plugin extracts text content from OCR results
- [ ] Plugin handles PDFs that already contain text (skip or process)
- [ ] Plugin produces structured output in expected format
- [ ] Plugin handles errors gracefully (missing tool, corrupt PDF, unsupported format)

### Integration
- [ ] Plugin works with existing file scanning and metadata extraction
- [ ] Plugin output integrates with workspace JSON structure (ocr_text_content → content.text)
- [ ] Plugin output can be consumed by reporting/template plugins
- [ ] Plugin respects verbose logging mode (req_0006)
- [ ] Plugin works with tool verification system (req_0007)
- [ ] Plugin integrates with installation prompt system (req_0008)
- [ ] Plugin file filtering uses `processes` field (orchestrator filters before execution)

### Testing
- [ ] Plugin tested with standard PDF files
- [ ] Plugin tested with scanned PDFs requiring OCR
- [ ] Plugin tested with PDFs already containing text
- [ ] Plugin tested with corrupt/invalid PDF files
- [ ] Plugin tested with missing ocrmypdf tool (error handling)
- [ ] Plugin tested in data-driven execution flow with dependencies

## Technical Considerations

### ocrmypdf Tool
- CLI tool for adding OCR text layer to PDF files
- Requires Tesseract OCR engine as dependency
- Supports multiple languages
- Can process PDFs in place or create new output files
- Provides options for image preprocessing and optimization

### Implementation Approach
1. Create plugin directory structure under `scripts/plugins/ubuntu/ocrmypdf/`
2. Define `descriptor.json` declaring processes, inputs, outputs, and dependencies
3. Implement plugin wrapper script (`ocrmypdf_wrapper.sh`) that:
   - Accepts file_path_absolute as input
   - Executes ocrmypdf with appropriate parameters
   - Extracts text to temporary location using unique filename (avoid race conditions)
   - Outputs variables using proper format for `read -r` consumption
   - Returns: ocr_text_content, ocr_status, ocr_confidence (space/newline separated)
4. Add installation script that checks for and installs ocrmypdf and Tesseract
5. Implement error handling for common failure scenarios
6. Add logging output for debugging and verbose mode
7. Test with representative PDF samples
8. Document workspace JSON mapping in plugin README

### Data Flow
```
Orchestrator File Scanning
  ↓
  Identifies PDF files (via processes.mime_types / file_extensions)
  ↓
Orchestrator passes file_path_absolute to ocrmypdf plugin
  ↓
ocrmypdf_wrapper.sh execution:
  - Creates unique temp file for OCR output (avoid race conditions)
  - Executes: ocrmypdf --sidecar <temp_file> <input_pdf> /dev/null
  - Reads extracted text from temp file
  - Calculates confidence if available
  - Outputs: "<text_content>\n<status>\n<confidence>"
  - Cleans up temp file
  ↓
Plugin output captured via read -r pattern
  ↓
Workspace JSON updated:
  - content.text = ocr_text_content
  - metadata.ocr_status = ocr_status
  - metadata.ocr_confidence = ocr_confidence
  ↓
Output available for downstream plugins and reporting
```

### Descriptor Schema (Corrected)
```json
{
    "name": "ocrmypdf",
    "description": "Performs OCR on PDF files using ocrmypdf to extract text content.",
    "active": true,
    "version": "1.0.0",
    "processes": {
        "mime_types": ["application/pdf"],
        "file_extensions": [".pdf"]
    },
    "consumes": {
        "file_path_absolute": {
            "type": "string",
            "description": "Absolute path to the PDF file to be processed."
        }
    },
    "provides": {
        "ocr_text_content": {
            "type": "string",
            "description": "Extracted text content from the PDF file (maps to workspace content.text).",
            "workspace_mapping": "content.text"
        },
        "ocr_status": {
            "type": "string",
            "description": "Processing status (success, failed, skipped)."
        },
        "ocr_confidence": {
            "type": "number",
            "description": "Average OCR confidence score (0-100) if available."
        }
    },
    "execute_commandline": "read -r ocr_text_content ocr_status ocr_confidence < <(./ocrmypdf_wrapper.sh \"${file_path_absolute}\")",
    "check_commandline": "read -r plugin_works < <(which ocrmypdf > /dev/null 2>&1 && echo 'true' || echo 'false')",
    "install_commandline": "read -r plugin_successfully_installed < <(./install.sh 2>&1 >/dev/null && echo 'true' || echo 'false')"
}
```

## Dependencies
- **Architecture**: Plugin architecture implementation (req_0022, req_0023) including:
  - Plugin discovery and loading mechanism
  - Descriptor validation
  - Processes-based file filtering
  - Execute commandline with read -r pattern
  - Workspace JSON structure
- **Infrastructure**: Tool verification system (req_0007) and installation prompts (req_0008)
- **External Tools**: 
  - ocrmypdf CLI tool (primary dependency)
  - Tesseract OCR engine (ocrmypdf dependency)
  - jq or python for JSON handling (orchestrator dependency)
- **Foundation**: Feature 0001 (basic script structure) and Feature 0003 (plugin listing for testing)

## Risks and Mitigation
- **Risk**: ocrmypdf/Tesseract installation complexity varies across platforms
  - **Mitigation**: Start with Ubuntu support, provide clear installation documentation
  
- **Risk**: OCR processing can be slow for large/complex PDFs
  - **Mitigation**: Add logging to show progress, consider timeout handling
  
- **Risk**: OCR quality varies with input document quality
  - **Mitigation**: Document limitations, provide configuration options for preprocessing

- **Risk**: Descriptor schema may evolve as plugin architecture matures
  - **Mitigation**: Schema now aligned with architecture documentation; minimal changes expected
  
- **Risk**: Temporary file handling in wrapper script could have race conditions
  - **Mitigation**: Use unique temp filenames (e.g., mktemp, PID-based naming) and cleanup in trap handlers

## Estimated Effort
- Plugin structure and descriptor: 2-3 hours
- Wrapper script implementation (ocrmypdf_wrapper.sh): 3-4 hours
  - Unique temp file handling
  - Proper output formatting for read -r
  - Error handling and status reporting
- Installation script: 1-2 hours
- Testing with various PDFs: 2-3 hours
- Workspace JSON integration verification: 1-2 hours
- Documentation (README, inline comments): 1-2 hours
**Total**: 10-16 hours

## Notes

### Architectural Alignment
This feature has been refined to comply with:
- **Building Block View (5.3)**: Plugin Manager interface expectations
- **Runtime View (6.1)**: Plugin loading and execution patterns  
- **req_0022**: Plugin-based extensibility with correct descriptor schema
- **req_0023**: Data-driven execution flow using consumes/provides

### Key Architectural Corrections Applied
1. **Added `processes` field**: File filtering now uses MIME types and extensions (not in consumes)
2. **Removed `file_type` from consumes**: Orchestrator handles filtering via `processes`
3. **Fixed execute_commandline**: Now uses proper `read -r` pattern with wrapper script
4. **Documented workspace mapping**: `ocr_text_content` → `content.text` in workspace JSON
5. **Removed file output**: Eliminated `searchable_pdf_path` to focus on data extraction

### Reference Implementation Value
This plugin demonstrates:
- Complete descriptor.json following architecture specifications
- Wrapper script pattern for complex CLI tool integration
- Proper output formatting for read -r consumption
- Temporary file handling with race condition avoidance
- Workspace JSON integration
- Error handling and status reporting

Success with this plugin validates the plugin architecture and provides a template for future plugin development.
