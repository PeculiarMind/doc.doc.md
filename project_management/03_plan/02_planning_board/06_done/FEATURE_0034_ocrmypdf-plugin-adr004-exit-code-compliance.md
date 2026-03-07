# Feature: ocrmypdf Plugin — ADR-004 Exit Code Compliance

- **ID:** FEATURE_0034
- **Priority:** High
- **Type:** Feature
- **Created at:** 2026-03-07
- **Created by:** Product Owner
- **Status:** BACKLOG

## Overview
Update the `ocrmypdf` plugin's `process` command to fully conform to the three-state exit code contract defined in ADR-004. The plugin currently exits 1 and prints to stderr when it encounters an unsupported MIME type. Under ADR-004 this must become exit 65 (`EX_DATAERR`) with a JSON message on stdout so the framework can silently skip unsupported files.

## Motivation
ADR-004 defines the mandatory plugin interface contract. REQ_0042 makes that contract a testable requirement. BUG_0011 raised the spurious error symptom. The `ocrmypdf` plugin supports only PDF and a handful of image MIME types and correctly rejects others — this rejection must be signalled with exit 65 + stdout JSON, not exit 1 + stderr.

## Implementation Notes (from architecture review)

**Change 1 — `ocrmypdf/main.sh`: switch unsupported-MIME exit path**

The MIME guard is a `case` statement. The `*` (wildcard) branch must change:
```bash
# BEFORE
  *)
    echo "Error: Unsupported MIME type '${mime_type}'. Supported types: ..." >&2
    exit 1
    ;;

# AFTER
  *)
    echo "{\"message\":\"skipped: unsupported MIME type $mime_type\"}"
    exit 65
    ;;
```

**Change 2 — `ocrmypdf/main.sh`: update header comment**
```bash
# Exit codes: 0 success (EX_OK), 65 unsupported input (EX_DATAERR, ADR-004), 1 failure
```

**Note:** Exit 1 remains correct for OCR processing failures on supported MIME types (e.g., corrupted PDF, OCR engine crash). Only the unsupported-MIME path changes.

**Note:** The `run_plugin` refactor in `plugin_execution.sh` (BUG_0011) is a prerequisite for user-visible effect in the full pipeline, but the plugin-side change can be implemented and tested in isolation.

## Acceptance Criteria
- [ ] `ocrmypdf/main.sh` process command exits **65** when invoked with a MIME type outside `{application/pdf, image/jpeg, image/png, image/tiff, image/bmp, image/gif}`
- [ ] The stdout payload for exit 65 is valid JSON of the form `{"message":"..."}` — nothing is written to stderr for a skip
- [ ] `ocrmypdf/main.sh` process command exits **0** when invoked with a supported MIME type and OCR succeeds; stdout contains `{"ocrText":"..."}`
- [ ] `ocrmypdf/main.sh` process command exits **1** when OCR processing fails for a supported MIME type; an error message is written to stderr
- [ ] No exit code other than 0, 65, or 1 is produced by this plugin's process command
- [ ] The header comment in `ocrmypdf/main.sh` references ADR-004 and the three-state exit contract
- [ ] `tests/test_feature_0034.sh` covers all three exit states (0, 65, 1)
- [ ] Existing tests pass without modification

## Dependencies
- REQ_0042 (Plugin Process Command Exit Code Interface Contract)
- REQ_0039 (Silent Skip for Unsupported MIME Types)
- BUG_0011 (framework-side `run_plugin` exit-code propagation — prerequisite for user-visible effect)

## Related Links
- Architecture Decision: `project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md`
- Architecture Concept: `project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_0007_plugin_mime_type_skip.md`
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0042_plugin-process-exit-code-contract.md`
- Driving Bug: `project_management/03_plan/02_planning_board/01_funnel/BUG_0011_plugin-silent-skip-unsupported-mime-types.md`
