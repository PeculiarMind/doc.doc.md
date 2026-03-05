# Process Output Sidecar Boundary Check Uses Bare String Prefix

- **ID:** BUG_0008
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

The `process` command boundary check for sidecar file writes uses a bare string prefix test:

```bash
if [[ "$canonical_sidecar" != "${canonical_out}"* ]]; then
```

The bash glob `"${canonical_out}"*` matches any string whose first characters equal `canonical_out`. This means a sidecar path resolving to a directory whose name STARTS WITH the same characters as the output directory (e.g., `canonical_out=/output`, sibling `/output_evil`) incorrectly passes the check without being flagged as a boundary violation.

REQ_SEC_005 specifies the correct pattern:
```bash
case "$target_canonical" in
  "$base_canonical"|"$base_canonical/"*)  # within boundary
```

This is a latent security defect. Under the current `find "$input_dir" -type f` code path, `find` does not produce paths containing `..`, so direct exploitation is difficult. However, the incorrect boundary check violates REQ_SEC_005 and defeats the defense-in-depth guarantee that any future code path involving a traversal escape would be caught.

**Affected file:** `doc.doc.sh` — line 1221

**Violates:** REQ_SEC_005 (Path Traversal Prevention — Boundary Enforcement)

### Example of Incorrect Behavior

```bash
canonical_out="/tmp/output"
canonical_sidecar="/tmp/output_evil/subdir"

# Current check (FLAWED):
[[ "/tmp/output_evil/subdir" != "/tmp/output"* ]]
# Result: FALSE (matches!) — boundary violation is NOT detected

# Correct check:
[[ "/tmp/output_evil/subdir" != "/tmp/output" && "/tmp/output_evil/subdir" != "/tmp/output/"* ]]
# Result: TRUE — boundary violation IS correctly detected
```

### Fix

Replace line 1221:
```bash
if [[ "$canonical_sidecar" != "${canonical_out}"* ]]; then
```

With:
```bash
if [[ "$canonical_sidecar" != "${canonical_out}" && "$canonical_sidecar" != "${canonical_out}/"* ]]; then
```

## Acceptance Criteria

- [x] A sidecar path resolving to a sibling directory (e.g., `/out_evil` when `canonical_out=/out`) is correctly rejected by the boundary check
- [x] A sidecar path resolving to a subdirectory of `canonical_out` is correctly allowed (regression)
- [x] A sidecar path equal to `canonical_out` itself is correctly rejected (output dir is a file, not a directory — edge case)
- [x] The existing boundary rejection log message (`"Error: path traversal detected for '$file_path'"`) is preserved
- [x] ShellCheck passes on the modified block

## Dependencies

None — single-line fix in the process output block.

## Related Links

- Security Review: [SECREV_008](../../../04_reporting/03_security_reviews/SECREV_008_FEATURE_0019_process_output_directory.md)
- Security Requirement: [REQ_SEC_005](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_005_path_traversal_prevention.md) — specifies the `"$base/"*` pattern
- Feature: [FEATURE_0019](../06_done/FEATURE_0019_process_output_directory.md)

## Workflow Assessment Log

- **Step 3 (TDD):** tester.agent — Tests in test_bug_0008.sh (8 assertions) verifying correct boundary check pattern and process regression
- **Step 4 (Implementation):** developer.agent — Changed `"${canonical_out}"*` to `"${canonical_out}" && ... != "${canonical_out}/"*` pattern per REQ_SEC_005
- **Step 5 (Tester Assessment):** tester.agent — All 8 tests pass. Process output with -o works correctly. Sidecar files created as expected.
- **Step 6 (Architect Assessment):** architect.agent — Fix aligns with REQ_SEC_005 boundary check pattern. Matches case statement approach documented in requirements.
- **Step 7 (Security Assessment):** security.agent — Fix closes sibling-directory bypass vulnerability. Boundary check now correctly differentiates `/output` from `/output_evil`.
- **Step 8 (License Assessment):** license.agent — No new dependencies. No license impact.
- **Step 9 (Documentation Assessment):** documentation.agent — No user-facing documentation changes needed. Error message preserved.
