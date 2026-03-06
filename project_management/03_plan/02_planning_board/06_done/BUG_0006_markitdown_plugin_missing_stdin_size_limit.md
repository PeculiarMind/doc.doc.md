# Markitdown Plugin Missing Stdin Size Limit

- **ID:** BUG_0006
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

The `markitdown` plugin `main.sh` reads JSON from stdin using `input_json="$(cat)"` without any size constraint. All other plugins (`stat`, `file`, `ocrmypdf`) implement a 1 MB stdin limit (`head -c 1048576`) as established by the BUG_0001 remediation and required by REQ_SEC_009. The markitdown plugin was implemented after BUG_0001 was resolved and did not inherit this safeguard, creating an inconsistency in the security posture.

An attacker (or malfunctioning caller) can send an arbitrarily large payload to the plugin, causing memory exhaustion and denial of service in the calling process.

**Affected file:** `doc.doc.md/plugins/markitdown/main.sh` — line 21

**Violates:** REQ_SEC_009 (JSON Input Validation — 1 MB stdin limit)

### Reproduction

```bash
# Sends a ~10 MB payload — no rejection, unbounded memory consumption
python3 -c "print('{\"filePath\":\"/tmp/x\",\"x\":\"' + 'A'*10000000 + '\"}')" \
  | ./doc.doc.md/plugins/markitdown/main.sh
```

### Fix

Replace:
```bash
input_json="$(cat)"
```

With:
```bash
input_json="$(head -c 1048576)"
```

This matches the pattern implemented in `stat/main.sh`, `file/main.sh`, and `ocrmypdf/main.sh` after BUG_0001.

## Acceptance Criteria

- [x] `main.sh` reads at most 1,048,576 bytes from stdin (consistent with `head -c 1048576`)
- [x] Payloads exceeding 1 MB are truncated; the plugin either processes the truncated JSON or exits with a JSON parse error (same behavior as other plugins)
- [x] Payloads within the 1 MB limit continue to work correctly (regression test)
- [x] ShellCheck passes on the modified script

## Dependencies

None — standalone fix in a single file.

## Related Links

- Security Review: [SECREV_006](../../../04_reporting/03_security_reviews/SECREV_006_FEATURE_0017_markitdown_plugin.md)
- Security Requirement: [REQ_SEC_009 JSON Input Validation](../../../02_project_vision/02_requirements/01_funnel/REQ_SEC_009_json_input_validation.md)
- Precedent: [BUG_0001](../06_done/BUG_0001_plugin_path_traversal_no_boundary_enforcement.md) — established the `head -c 1048576` standard
- Feature: [FEATURE_0017](../06_done/FEATURE_0017_markitdown_ms_office_plugin.md)

## Workflow Assessment Log

### Step 3: TDD
- **Date:** 2026-03-05
- **Agent:** tester.agent
- **Result:** PASS
- **Summary:** Tests written in test_bug_0006.sh (5 assertions), initially failed as expected.

### Step 4: Implementation
- **Date:** 2026-03-05
- **Agent:** developer.agent
- **Result:** PASS
- **Summary:** Fixed `cat` → `head -c 1048576` in markitdown/main.sh line 21.

### Step 5: Tester Assessment
- **Date:** 2026-03-05
- **Agent:** tester.agent
- **Result:** PASS
- **Summary:** All 5 tests pass, fix matches pattern from stat/file/ocrmypdf plugins.

### Step 6: Architect Assessment
- **Date:** 2026-03-05
- **Agent:** architect.agent
- **Result:** PASS
- **Summary:** Fix aligns with established stdin limit pattern (REQ_SEC_009). No architectural concerns.

### Step 7: Security Assessment
- **Date:** 2026-03-05
- **Agent:** security.agent
- **Result:** PASS
- **Summary:** Fix closes denial-of-service vector. Consistent with other plugins. No new vulnerabilities.

### Step 8: License Assessment
- **Date:** 2026-03-05
- **Agent:** license.agent
- **Result:** PASS
- **Summary:** No new dependencies, no license impact.

### Step 9: Documentation Assessment
- **Date:** 2026-03-05
- **Agent:** documentation.agent
- **Result:** PASS
- **Summary:** No user-facing documentation changes needed.
