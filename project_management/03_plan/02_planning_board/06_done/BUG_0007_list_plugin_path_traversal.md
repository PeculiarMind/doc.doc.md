# List Command Path Traversal via --plugin Argument

- **ID:** BUG_0007
- **Priority:** Medium
- **Type:** Bug
- **Created at:** 2026-03-10
- **Created by:** security.agent
- **Status:** DONE
- **Assigned to:** developer.agent

## TOC

1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Dependencies](#dependencies)
4. [Related Links](#related-links)

## Overview

The `list --plugin <name>` command in `doc.doc.sh` constructs the plugin directory path as `"$PLUGIN_DIR/$plugin_name"` without canonicalization or boundary enforcement. A caller can pass `../` sequences in `<name>` to escape `$PLUGIN_DIR` and read an arbitrary `descriptor.json` file elsewhere on the filesystem.

The directory existence check (`[ ! -d "$plugin_dir" ]`) does not reject the traversal because the resolved path may genuinely be an existing directory. If that directory contains a `descriptor.json` file that is valid JSON, its contents are parsed and displayed as if it were a legitimate plugin descriptor.

**Affected locations in `doc.doc.sh`:**
- `--commands` branch: line 805 (`local plugin_dir="$PLUGIN_DIR/$plugin_name"`)
- `--parameters` branch: line 832 (`local plugin_dir="$PLUGIN_DIR/$plugin_name"`)

**Violates:** REQ_SEC_005 (Path Traversal Prevention), REQ_SEC_001 (Input Validation)

### Reproduction

```bash
# Create a bait file outside the plugin directory
echo '{"commands":{"secret":{"description":"exposed","input":{},"output":{}}}}' \
  > /tmp/descriptor.json

# Traverse to /tmp/ using the plugin name
./doc.doc.sh list --plugin '../../../../../../../tmp' --parameters
# Output: reads and displays /tmp/descriptor.json contents as a parameter table
```

### Fix

After constructing `plugin_dir`, canonicalize it and validate it is within `$PLUGIN_DIR`:

```bash
local plugin_dir="$PLUGIN_DIR/$plugin_name"
local canonical_plugin_dir
canonical_plugin_dir="$(readlink -f "$plugin_dir" 2>/dev/null || echo "")"
if [ -z "$canonical_plugin_dir" ] || [[ "$canonical_plugin_dir" != "$PLUGIN_DIR/"* ]]; then
  echo "Error: Plugin '$plugin_name' not found" >&2
  exit 1
fi
plugin_dir="$canonical_plugin_dir"
```

Apply the same fix to both the `--commands` and `--parameters` branches.

## Acceptance Criteria

- [x] `list --plugin '../../../../etc' --parameters` is rejected with an error before any filesystem access outside `$PLUGIN_DIR`
- [x] `list --plugin '../../../../etc' --commands` is likewise rejected
- [x] Legitimate plugin names (no `../`) continue to work correctly (regression test)
- [x] Plugin name with leading `../` sequences is sanitized before path construction
- [x] ShellCheck passes on the modified function

## Dependencies

None — standalone fix within `cmd_list()`.

## Related Links

- Security Review: [SECREV_007](../../../04_reporting/03_security_reviews/SECREV_007_FEATURE_0018_list_plugin_parameters.md)
- Security Requirement: [REQ_SEC_005](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md)
- Security Requirement: [REQ_SEC_001](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_001_input_validation_sanitization.md)
- Feature: [FEATURE_0018](../06_done/FEATURE_0018_list_plugin_parameters.md)

## Workflow Assessment Log

- **Step 3 (TDD):** tester.agent — Tests in test_bug_0007.sh (33 assertions) covering traversal via --parameters, --commands, various patterns, regression, bare '..'
- **Step 4 (Implementation):** developer.agent — Added `_validate_plugin_dir()` helper using `cd`/`pwd -P` canonicalization. Applied to both --commands and --parameters branches.
- **Step 5 (Tester Assessment):** tester.agent — All 33 tests pass. Legitimate plugins (file, stat) continue working. All traversal patterns correctly rejected.
- **Step 6 (Architect Assessment):** architect.agent — Helper function follows single-responsibility principle. Uses cd/pwd -P for canonicalization which is portable. No architectural concerns.
- **Step 7 (Security Assessment):** security.agent — Fix prevents path traversal via `list --plugin`. Canonicalization prevents both direct and nested traversal. No new vulnerabilities introduced.
- **Step 8 (License Assessment):** license.agent — No new dependencies. No license impact.
- **Step 9 (Documentation Assessment):** documentation.agent — No user-facing documentation changes needed. Error messages preserved.
