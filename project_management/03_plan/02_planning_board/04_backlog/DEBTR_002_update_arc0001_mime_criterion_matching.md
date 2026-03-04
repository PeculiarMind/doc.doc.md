# Update ARC_0001 Filtering Logic — MIME Criterion Matching Pseudocode

- **ID:** DEBTR_002
- **Priority:** LOW
- **Type:** Technical Debt
- **Created at:** 2026-03-03
- **Created by:** architect.agent
- **Assigned to:** developer.agent
- **Status:** BACKLOG

## TOC

1. [Overview](#overview)
2. [Origin](#origin)
3. [Description](#description)
4. [Acceptance Criteria](#acceptance-criteria)
5. [Affected Files](#affected-files)

## Overview

The `ARC_0001_filtering_logic.md` concept document contains pseudocode for `matches_criterion` that shows MIME type matching as calling `get_mime_type(file_path)` at criterion-match time. The actual implementation diverges from this pseudocode in a superior way: `filter.py` receives the MIME type string directly on stdin (not the file path), and matches it against the criterion using `fnmatch` — just as it does for any other glob criterion. ARC_0001 should be updated to reflect this design.

## Origin

- **Architecture Review:** ARCHREV_002_FEATURE_0007
- **Feature:** [FEATURE_0007](../05_implementing/FEATURE_0007_file_plugin_first_in_chain_and_mime_filter_gate.md)
- **Deviation:** DEV-001 — ARC_0001 pseudocode describes a `get_mime_type(file_path)` call that does not exist in the implementation

## Description

`ARC_0001_filtering_logic.md` pseudocode (under "Proposed Solution") reads:

```python
def matches_criterion(file_path, criterion):
    # MIME type match
    elif '/' in criterion:
        mime_type = get_mime_type(file_path)
        return mime_type == criterion
```

This implies that:
1. MIME type detection happens inside `matches_criterion`
2. The match is an exact equality check
3. Glob-style MIME patterns (e.g., `image/*`) are not supported

The FEATURE_0007 implementation uses a different — and architecturally superior — approach:

- The `file` plugin detects the MIME type once per file and emits it as `mimeType` in its JSON output
- `doc.doc.sh` identifies MIME criteria (presence of `/`, absence of `**`) and routes them separately from path criteria
- For MIME criteria, `doc.doc.sh` pipes the `mimeType` string directly into `filter.py` stdin (instead of the file path)
- `filter.py` applies `fnmatch.fnmatch(mime_type_string, criterion)` — the same glob matching used for all non-extension criteria

This approach is correct and superior because:
- Avoids redundant MIME detection (`file` plugin already performed it)
- Enables glob-style MIME patterns (`image/*`, `text/*`) via `fnmatch` at no extra cost
- Keeps `filter.py` simple and general-purpose (no MIME-specific code path needed)

ARC_0001 pseudocode should be updated to document this actual design, including the criterion routing logic in `doc.doc.sh` and the MIME-as-input approach to `filter.py`.

## Acceptance Criteria

- [ ] `ARC_0001_filtering_logic.md` "Proposed Solution" section updated to reflect the actual MIME matching approach: MIME type string is fed directly as stdin to filter.py; `fnmatch` handles both literal and glob MIME criteria
- [ ] The `matches_criterion` pseudocode no longer references `get_mime_type(file_path)` for MIME criteria
- [ ] A note is added explaining criterion routing in `doc.doc.sh`: criteria containing `/` (but not `**`) are classified as MIME criteria and evaluated against the detected MIME type
- [ ] The filter examples table is updated or extended to include at least one MIME type filter example showing glob matching (e.g., `image/*` matching `image/jpeg`)
- [ ] ARC_0001 status updated from "Proposed" to "Accepted" if appropriate (architecture team decision)

## Affected Files

- `project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_0001_filtering_logic.md`
