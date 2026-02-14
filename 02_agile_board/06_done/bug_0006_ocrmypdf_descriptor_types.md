# Bug: OCRmyPDF Descriptor Field Types and Install Command

**ID**: bug_0006_ocrmypdf_descriptor_types  
**Status**: Done  
**Created**: 2026-02-14  
**Last Updated**: 2026-02-14  
**Completed**: 2026-02-14

## Overview
The OCRmyPDF plugin descriptor.json contained incorrect field types and an install command that didn't reference the install.sh script.

## Description
Two issues were identified in `scripts/plugins/ubuntu/ocrmypdf/descriptor.json`:

1. **Wrong type for ocr_confidence**: The `provides.ocr_confidence.type` was set to `"integer"` but should be `"number"` to align with JSON Schema conventions for numeric values (confidence scores can be decimal).

2. **Missing install.sh reference**: The `install_commandline` was set to a direct `apt-get install` command instead of referencing the plugin's `install.sh` script. This was inconsistent since the plugin already has a proper `install.sh` script with dependency management.

Additionally, the plugin validator (`plugin_validator.sh`) needed updates:
- Accept `"number"` as a valid type in addition to `"string"`, `"integer"`, and `"boolean"`
- Accept `install.sh` script references in `install_commandline` validation

## Resolution
**Fixed**:
- Changed `ocr_confidence.type` from `"integer"` to `"number"` in descriptor.json
- Changed `install_commandline` from direct apt-get to `"./install.sh"`
- Updated `plugin_validator.sh` to accept `"number"` type
- Updated `plugin_validator.sh` to accept `install.sh` references in install_commandline validation

## Category
- Type: Bug
- Priority: Medium

## Tests
- All 36 tests in `tests/unit/test_ocrmypdf_plugin.sh` pass
- All 8 tests in `tests/unit/test_plugin_validation.sh` pass
