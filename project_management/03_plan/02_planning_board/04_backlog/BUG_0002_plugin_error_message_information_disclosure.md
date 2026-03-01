# Plugin Error Message Information Disclosure

- **ID:** BUG_0002
- **Priority:** Medium
- **Type:** Bug
- **Created at:** 2026-03-01
- **Created by:** security.agent
- **Status:** BACKLOG

## TOC

## Overview

The stat and file plugin `main.sh` scripts include the full user-supplied file path in error messages and differentiate between "file not found" and "file not readable" states. This discloses system structure and creates a file-existence oracle that an attacker can exploit for reconnaissance.

This violates:
- **REQ_SEC_006** (Error Information Disclosure Prevention): Production error messages must not reveal internal system paths
- **SC-006** (Error Message Sanitization): Generic user errors in production mode

**Discovered in:** [SECREV_002](../../../04_reporting/03_security_reviews/SECREV_002_FEATURE_0002_stat_file_plugins.md)
**Affects:** FEATURE_0002 (stat and file plugins)

### Reproduction

```bash
# Reveals full path in error message
echo '{"filePath":"/home/secretuser/documents/classified.pdf"}' | ./doc.doc.md/plugins/stat/main.sh
# Output: "Error: File not found: /home/secretuser/documents/classified.pdf"

# File-existence oracle: distinguishes "not found" from "not readable"
echo '{"filePath":"/etc/shadow"}' | ./doc.doc.md/plugins/stat/main.sh
# Output: "Error: File is not readable: /etc/shadow"
# (confirms /etc/shadow exists, even though content cannot be read)

echo '{"filePath":"/etc/nonexistent"}' | ./doc.doc.md/plugins/stat/main.sh
# Output: "Error: File not found: /etc/nonexistent"
# (confirms file does NOT exist — information leakage)
```

### Affected Lines

**stat/main.sh:**
- Line 27: `echo "Error: File not found: $filePath" >&2`
- Line 33: `echo "Error: File is not readable: $filePath" >&2`

**file/main.sh:**
- Line 27: `echo "Error: File not found: $filePath" >&2`
- Line 33: `echo "Error: File is not readable: $filePath" >&2`

## Acceptance Criteria

- [ ] Error messages do not include full file paths (use basename only or generic message)
- [ ] "File not found" and "file not readable" are combined into a single generic error (e.g., `"Error: Cannot access file"`) to eliminate the file-existence oracle
- [ ] Error messages remain actionable enough for debugging when the runtime provides verbose mode
- [ ] All 52 existing tests continue to pass (test assertions on error messages may need updating)
- [ ] Changes applied to both `stat/main.sh` and `file/main.sh`

### Suggested Fix

```bash
# Replace separate not-found / not-readable checks:
if [ ! -e "$filePath" ] || [ ! -r "$filePath" ]; then
  echo "Error: Cannot access the specified file" >&2
  exit 1
fi
```

## Dependencies

- **Blocks:** FEATURE_0002 advancement to DONE
- **Related:** REQ_SEC_006, SC-006

## Related Links

- Security Review: [SECREV_002](../../../04_reporting/03_security_reviews/SECREV_002_FEATURE_0002_stat_file_plugins.md)
- Feature: [FEATURE_0002](../05_implementing/FEATURE_0002_implement_stat_and_file_plugins.md)
- Requirement: [REQ_SEC_006](../../02_project_vision/02_requirements/03_accepted/REQ_SEC_006_error_information_disclosure_prevention.md)
- Security Concept: [SC-006](../../02_project_vision/04_security_concept/01_security_concept.md)
