# TDD Plan: FEATURE_0042 CRM114 Model Management Commands

- **ID:** TDD_FEATURE_0042
- **Type:** TDD Plan
- **Related Feature:** FEATURE_0042
- **Status:** OBSOLETED
- **Obsolescence reason:** Parent feature FEATURE_0042 obsoleted; CRM114 plugin requires massive rework.
- **Created at:** 2026-03-14
- **Created by:** tester.agent

## Test Cases

### Group 1: Plugin structure — new script files
- `learn.sh` exists and is executable
- `unlearn.sh` exists and is executable
- `listCategories.sh` exists and is executable
- `train.sh` exists and is executable

### Group 2: descriptor.json — new commands registered
- `train` command registered
- `learn` command registered
- `unlearn` command registered
- `listCategories` command registered
- Each command references the correct `.sh` file

### Group 3: listCategories — no models
- Returns `{"categories": []}` when pluginStorage is empty
- Rejects missing pluginStorage field (exit 1)
- Rejects nonexistent pluginStorage (exit 1)

### Group 4: listCategories — with models
- Returns correct category names from .css files
- Skips non-.css files in pluginStorage

### Group 5: learn — validation
- Rejects missing category (exit 1)
- Rejects missing pluginStorage (exit 1)
- Rejects missing filePath (exit 1)
- Rejects invalid category name (path traversal / metacharacters)

### Group 6: unlearn — validation
- Rejects missing .css model file (exit 1, JSON error output)
- Rejects missing category (exit 1)

### Group 7: learn/unlearn — crm114 available (SKIP when not installed)
- learn: creates .css model file, exits 0, outputs success JSON
- unlearn: removes text from model, exits 0, outputs success JSON

### Group 8: train — argument validation
- Exits 1 with usage when called with no arguments
- Validates pluginStorage path exists
- Validates input directory exists

### Group 9: Security
- Category name with `..` is rejected
- Category name with `/` is rejected
- Category name with shell metacharacters is rejected
- pluginStorage path validated before any file I/O
