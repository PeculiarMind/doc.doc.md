# TDD Task: BUG_0004 ocrmypdf Plugin Fix

- **ID:** TDD_BUG_0004
- **Type:** TDD Task
- **Status:** Done
- **Assigned to:** tester.agent
- **Parent:** BUG_0004

## Task

Write failing tests for BUG_0004 fix before implementation. Tests should verify:
1. main.sh accepts PDF, JPEG, PNG, TIFF, BMP, GIF files
2. main.sh rejects unsupported file types
3. main.sh uses sidecar pattern (--sidecar, --output-type none)
4. main.sh uses --image-dpi for image inputs
5. doc.doc.sh aborts with clear error when active plugin is not installed
