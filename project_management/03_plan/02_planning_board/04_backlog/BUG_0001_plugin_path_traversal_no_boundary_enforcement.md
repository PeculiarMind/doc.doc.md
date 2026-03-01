# Plugin Path Traversal — No Boundary Enforcement

- **ID:** BUG_0001
- **Priority:** High
- **Type:** Bug
- **Created at:** 2026-03-01
- **Created by:** security.agent
- **Status:** BACKLOG

## TOC

## Overview

The stat and file plugin `main.sh` scripts accept any absolute file path via JSON stdin and operate on any readable file on the system without path boundary enforcement. This allows reading metadata of sensitive files (`/etc/passwd`, `/proc/self/environ`), device files (`/dev/*`), and following symlinks to arbitrary locations.

This violates:
- **REQ_SEC_005** (Path Traversal Prevention): All file paths must be validated to remain within intended boundaries
- **REQ_SEC_001** (Input Validation): File paths must be canonicalized and validated
- **SC-001** (Input Path Validation): Canonicalize paths, reject traversal attempts

**Discovered in:** [SECREV_002](../../../04_reporting/03_security_reviews/SECREV_002_FEATURE_0002_stat_file_plugins.md)
**Affects:** FEATURE_0002 (stat and file plugins)

### Reproduction

```bash
# Reads /etc/passwd metadata — should be rejected
echo '{"filePath":"/etc/passwd"}' | ./doc.doc.md/plugins/stat/main.sh

# Reads /proc/self/environ metadata — should be rejected
echo '{"filePath":"/proc/self/environ"}' | ./doc.doc.md/plugins/stat/main.sh

# Follows symlink to sensitive file — should validate target
ln -s /etc/passwd /tmp/test_link
echo '{"filePath":"/tmp/test_link"}' | ./doc.doc.md/plugins/stat/main.sh

# Device file access — should be rejected
echo '{"filePath":"/dev/null"}' | ./doc.doc.md/plugins/stat/main.sh
```

### Secondary Issue: No stdin Size Limit

Additionally, `input=$(cat)` reads all of stdin without any size constraint. A caller sending gigabytes of data will cause memory exhaustion. REQ_SEC_009 specifies a 1 MB maximum for JSON input.

## Acceptance Criteria

- [ ] Plugins reject file paths in dangerous system directories (`/proc`, `/dev`, `/sys`, `/etc`) as a defense-in-depth measure
- [ ] Plugins resolve symlinks and validate the resolved target path
- [ ] Plugins add a stdin size limit (e.g., `head -c 1048576`) to prevent memory exhaustion
- [ ] Existing functionality for legitimate file paths is preserved
- [ ] Error messages for rejected paths are generic (do not reveal the validation rule)
- [ ] All 52 existing tests continue to pass after changes

**Note:** Full path boundary enforcement (validating paths are within a specified base directory) is the responsibility of the runtime system (SC-001). This bug addresses plugin-level defense-in-depth measures only.

## Dependencies

- **Blocks:** FEATURE_0002 advancement to DONE (partially — may be risk-accepted for MVP)
- **Related:** REQ_SEC_005, REQ_SEC_001, REQ_SEC_009, SC-001

## Related Links

- Security Review: [SECREV_002](../../../04_reporting/03_security_reviews/SECREV_002_FEATURE_0002_stat_file_plugins.md)
- Feature: [FEATURE_0002](../05_implementing/FEATURE_0002_implement_stat_and_file_plugins.md)
- Requirements: [REQ_SEC_005](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md), [REQ_SEC_001](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_001_input_validation_sanitization.md)
- Security Concept: [Scope 3 & SC-001](../../02_project_vision/04_security_concept/01_security_concept.md)
