# Filter Engine Ignores MIME Type Criteria — Always Returns No Match

- **ID:** BUG_0003
- **Priority:** High
- **Type:** Bug
- **Created at:** 2026-03-04
- **Created by:** tester.agent
- **Status:** Backlog
- **Assigned to:** developer.agent

## Overview

`filter.py` does not implement MIME type matching. When a criterion containing a `/`
(e.g. `text/plain`, `application/pdf`, `image/*`) is passed via `--include` or
`--exclude`, the engine falls through to `fnmatch.fnmatch(file_path, criterion)`.
A MIME type string never matches a file path, so:

- `--include "text/plain"` → **no file is ever included** (empty result)
- `--exclude "image/png"` → **no file is ever excluded** (criterion silently ignored)

This means any invocation relying on MIME type filtering (as documented in the
project goals, ARC_0001, and REQ_SEC_002) produces incorrect output with no
error or warning to the user.

### Reproduction

```bash
# Expected: returns all text/plain files; Actual: returns nothing
./doc.doc.sh process -d . -i "text/plain"

# Expected: returns only PDFs; Actual: returns nothing
./doc.doc.sh process -d . -i "application/pdf"

# Direct filter test — expected: /tmp/x/hello.txt; Actual: (empty)
echo "/tmp/x/hello.txt" | python3 doc.doc.md/components/filter.py --include "text/plain"
```

### Root Cause

`matches_criterion()` in `filter.py` has two branches:

1. Criterion starts with `.` → suffix/extension match  
2. Everything else → `fnmatch.fnmatch(file_path, criterion)`

There is no third branch for MIME types (criteria containing `/`).
ARC_0001 specifies MIME type detection via `file --mime-type`, but this call
was never implemented.

## Acceptance Criteria

- [ ] `matches_criterion()` detects MIME type criteria by the presence of `/` in the criterion
- [ ] For MIME criteria, the actual MIME type of the file is resolved via `file --mime-type -b <path>` (consistent with ARC_0001 and the existing `file` plugin)
- [ ] Glob-style MIME patterns (e.g. `image/*`) are matched using `fnmatch` against the detected MIME type
- [ ] Exact MIME type matching works: `text/plain`, `application/pdf`, `application/json`, `image/png`
- [ ] Glob MIME matching works: `image/*`, `text/*`, `application/*`
- [ ] Extension and glob path criteria are unaffected (no regression)
- [ ] `--include "text/plain"` on a directory of `.txt` and `.md` files returns those files
- [ ] `--exclude "image/png"` correctly removes PNG files from an otherwise matching set
- [ ] `--include "text/plain"` returns `[]` from a directory containing only PNG files
- [ ] All 8 example cases from project goals continue to pass
- [ ] All 19 tests in `tests/test_filter_mime.sh` pass (0 failures)
- [ ] All existing tests in `tests/test_doc_doc.sh` continue to pass (no regression)
- [ ] If `file` command is unavailable, the filter logs a clear error and exits non-zero

## Tests

Failing tests are in [`tests/test_filter_mime.sh`](../../../../tests/test_filter_mime.sh).

**Test run results before fix (2026-03-04):** 11/19 passed, **8 failed**

Failing test cases:
1. `include text/plain keeps hello.txt` — filter returns empty
2. `include text/plain keeps doc.md` — filter returns empty
3. `include image/png keeps image.png` — filter returns empty
4. `include image/* keeps image.png` — filter returns empty
5. `exclude image/png removes image.png` — image.png not excluded
6. `exclude image/* removes image.png` — image.png not excluded
7. `MIME+ext AND: keeps hello.txt` — filter returns empty
8. `process -i text/plain returned 0 files` — integration returns `[]`

## Dependencies

- **Related:** FEATURE_0007 (file plugin as MIME filter gate) — FEATURE_0007
  assumes MIME type filtering works; this bug must be fixed first or in the
  same iteration
- **Violates:** REQ_SEC_002 (Filter Logic Correctness), REQ_0031
  (Include-before-exclude precedence), ARC_0001 (Filtering Logic concept)

## Related Links

- Tests: [`tests/test_filter_mime.sh`](../../../../tests/test_filter_mime.sh)
- Filter engine: [`doc.doc.md/components/filter.py`](../../../../doc.doc.md/components/filter.py)
- Architecture concept: [ARC_0001](../../../02_project_vision/03_architecture_vision/08_concepts/ARC_0001_filtering_logic.md)
- Requirements: [REQ_SEC_002](../../../02_project_vision/02_requirements/03_accepted/REQ_SEC_002_filter_logic_correctness.md), [REQ_0031](../../../02_project_vision/02_requirements/03_accepted/REQ_0031_filter-include-exclude-precedence.md)
- Related feature: [FEATURE_0007](FEATURE_0007_file_plugin_first_in_chain_and_mime_filter_gate.md)
- Project goals: [project_goals.md](../../../02_project_vision/01_project_goals/project_goals.md)
