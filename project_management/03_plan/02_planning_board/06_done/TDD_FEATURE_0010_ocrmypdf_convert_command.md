# TDD Task: FEATURE_0010 ocrmypdf Convert Command

- **ID:** TDD_FEATURE_0010
- **Type:** TDD Task
- **Status:** Done
- **Assigned to:** tester.agent
- **Parent:** FEATURE_0010

## Task

Write failing tests for the convert command before implementation.
Tests should verify:
1. convert.sh exists and is executable
2. convert.sh reads JSON from stdin
3. convert.sh accepts JPEG, PNG, TIFF, BMP, GIF inputs
4. convert.sh rejects unsupported MIME types
5. convert.sh invokes ocrmypdf with --image-dpi
6. convert.sh outputs JSON with outputPdf and success fields
7. descriptor.json has convert command defined
