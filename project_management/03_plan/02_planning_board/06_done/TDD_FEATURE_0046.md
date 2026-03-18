# TDD Plan: FEATURE_0046 CRM114 Text Classification Plugin

- **ID:** TDD_FEATURE_0046
- **Type:** TDD Plan
- **Related Feature:** FEATURE_0046
- **Status:** DONE
- **Created at:** 2026-03-18
- **Created by:** tester.agent

## Test File

`tests/test_feature_0046.sh` — 77 tests across 10 groups

## Test Groups

### Group 1: Plugin structure validation (18 tests)
- descriptor.json exists and is valid JSON
- All 8 command scripts exist and are executable
- Plugin name is "crm114", active is true
- All required commands registered: process, manageCategories, train, learn, unlearn, listCategories, install, installed
- manageCategories and train are marked interactive
- process, learn, unlearn, listCategories, install, installed are NOT interactive

### Group 2: installed.sh — availability check (4 tests)
- Always exits 0
- Returns valid JSON
- Has 'installed' field
- installed field is boolean (true or false)

### Group 3: install.sh — install command (3 tests)
- Returns valid JSON
- Has 'success' field
- Has 'message' field

### Group 4: listCategories.sh (9 tests)
- Exits 0 with no models, returns empty array
- Exits 0 with models, returns 3 categories
- Includes correct category names in output
- Exits 1 with missing pluginStorage field
- Rejects path traversal in pluginStorage (exit 1)
- Exits 0 with non-existent storage dir, returns empty array

### Group 5: learn.sh — non-interactive learn (10 + 5 conditional tests)
- Exits 1 with missing category
- Exits 1 with missing pluginStorage
- Exits 1 with missing text content
- Rejects path traversal in category name (exit 1)
- Rejects path traversal in pluginStorage (exit 1)
- Rejects category name with metacharacters (exit 1)
- (SKIP if crm114 not installed) Succeeds with valid input, returns JSON, success true, category name, creates CSS file

### Group 6: unlearn.sh — non-interactive unlearn (7 tests)
- Exits 1 with missing category
- Exits 1 with missing pluginStorage
- Exits 1 with missing text
- Exits 1 when CSS file does not exist
- Returns JSON error when CSS file missing
- Rejects path traversal in category name (exit 1)
- Rejects path traversal in pluginStorage (exit 1)

### Group 7: process.sh (9 + 4 conditional tests)
- Exits 65 when pluginStorage does not exist
- Exits 65 when textContent is empty
- Exits 65 when no trained categories
- Exits 1 with missing pluginStorage
- Rejects path traversal in pluginStorage (exit 1)
- (SKIP if crm114 not installed) Exits 0 with trained categories, returns JSON with categories array

### Group 8: Plugin in CLI list and tree (2 tests)
- crm114 appears in 'list' output
- crm114 appears in 'tree' output

### Group 9: run command integration (4 tests)
- run crm114 listCategories exits 0
- run crm114 listCategories returns valid JSON and empty array
- run crm114 installed exits 0
- run crm114 installed returns valid JSON

### Group 10: Security — input validation (9 + 5 tests)
- Invalid category names (path traversal, slashes, spaces, metacharacters) all exit 1
- Valid category names are accepted without sanitization error

## Skip Logic

Tests requiring CRM114 binaries (`csslearn`, `cssunlearn`) are wrapped in
`if [ "$CRM114_AVAILABLE" = "true" ]` blocks and individually skipped
with a `(crm114 not installed)` message when the binaries are absent.
