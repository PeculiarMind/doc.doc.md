
# BUG_0018 — process command mirrors full relative path instead of input directory contents

- **ID:** BUG_0018
- **Priority:** High
- **Type:** Bug
- **Created at:** 2026-03-20
- **Created by:** product_owner
- **Status:** IMPLEMENTING

## Overview

When the `-d` flag is given as a relative path (e.g. `-d ./tests/docs/`), the sidecar
`.md` files are written to a mirrored subdirectory that includes the full relative path
rather than only the contents of the input directory.

**Example:**

```bash
./doc.doc.sh process -d ./tests/docs/ -o ./tests/out
```

**Actual output tree:**

```
tests/out/
└── tests/
    └── docs/
        ├── README-PDF.pdf.md
        ├── README-MSWORD.docx.md
        └── ...
```

**Expected output tree:**

```
tests/out/
├── README-PDF.pdf.md
├── README-MSWORD.docx.md
└── ...
```

## Root Cause

In `_run_process_pipeline` (doc.doc.sh), `relative_path` is computed by stripping the
`_PROC_INPUT_DIR` prefix from `file_path`:

```bash
local relative_path="${file_path#${_PROC_INPUT_DIR}/}"
```

`find "$INPUT_DIR"` returns paths in the same form as `_PROC_INPUT_DIR` (e.g.
`./tests/docs/README-PDF.pdf`). The strip appends `/` to the already-suffixed input dir
producing a double-slash (`./tests/docs//`) that never matches, so the full path is
kept as the relative path.

The fix should canonicalise `_PROC_INPUT_DIR` (via `readlink -f`) before using it as a
strip prefix, consistent with how `_PROC_CANONICAL_OUT` is already handled, and derive
`relative_path` from canonical `file_path` values.

## Acceptance Criteria

- [ ] `./doc.doc.sh process -d ./tests/docs/ -o ./tests/out` writes sidecar files
  directly under `tests/out/` — no `tests/out/tests/docs/` subdirectory is created.
- [ ] The fix works for all forms of `-d`: relative path with `./` prefix, relative
  path without prefix, and absolute path.
- [ ] Existing tests continue to pass (`./tests/run_all_tests.sh`).
- [ ] A regression test is added that asserts the sidecar path depth equals the depth
  of the file relative to the input directory.

## Dependencies

None.

## Related Links

- Architecture Vision: —
- Requirements: —
- Security Concept: —
- Test Plan: —
