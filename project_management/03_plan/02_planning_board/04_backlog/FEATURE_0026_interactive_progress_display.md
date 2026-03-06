# Feature: Interactive Progress Display for Process Command

- **ID:** FEATURE_0026
- **Priority:** Medium
- **Type:** Feature
- **Created at:** 2026-03-06
- **Created by:** Product Owner
- **Status:** BACKLOG

## Overview
When `process` is run in an interactive terminal (stdin/stdout attached to a TTY), display a live-updating progress dashboard showing an ASCII progress bar with percentage display, the current phase, the current step, counts of discovered documents, and the currently executing plugin. In non-interactive (piped / redirected) mode the display is suppressed so output remains machine-readable.
The progress bar should have a fixed with of 50 characters and use the following symbols to indicate progress:
- `░` for 0% progress (empty)
- `░` alternating with `▒` for progress between 1% and 50%
- `▒` alternating with `▓` for progress between 51% and 99%
- `▓` for 100% progress (fully filled)

Example display (updated in-place via ANSI cursor control):
```
Progress: ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░ x%
Phase:    Scan directory
Step:     Apply include/exclude filters
Found:    12 documents
Process:  report_2025.pdf
Execute:  ocrmypdf
```

## Acceptance Criteria

### Progress bar
- [ ] A single-line ASCII progress bar is rendered with a fixed width (e.g. 40 characters), filled with `=` and a leading `>` for the filled portion and spaces for the remaining portion, surrounded by `[` and `]`
- [ ] The current overall percentage (0–100 %) is displayed centred inside or immediately after the bar
- [ ] The bar and all status lines are updated in-place (no scrolling) using ANSI escape codes (cursor-up + carriage-return overwrite) while the terminal session is interactive
- [ ] Percentage is calculated as `(files fully processed) / (total files found) × 100`; during the scan phase the bar shows 0 %

### Status lines
The display contains the following labelled lines, each updated as processing advances:

| Label | Content |
|---|---|
| `Progress:` | ASCII bar + percentage |
| `Phase:` | Current high-level phase name (see phases below) |
| `Step:` | Current step within the phase |
| `Found:` | Number of documents discovered (updated live during scan) |
| `Process:` | Filename (relative path) of the document currently being processed |
| `Execute:` | Name of the plugin currently being invoked |

### Phases and steps (minimum set)
- **Scan directory** — steps: *reading directory tree*, *apply include/exclude filters*
- **Process documents** — steps: *render template*, *execute plugin `<name>`*, *write output*
- **Done** — final phase shown briefly before the display clears

### Interactivity detection
- [ ] Progress display is shown **only** when stdout is a TTY (`[ -t 1 ]`)
- [ ] In non-interactive mode (piped, redirected, `--echo` flag) no ANSI codes or progress lines are emitted
- [ ] A explicit `--progress` flag forces the progress display even when stdout is not a TTY (useful for terminal multiplexers that mis-report TTY state)
- [ ] A explicit `--no-progress` flag suppresses the display even on a TTY

### Output and UX
- [ ] After all documents are processed the progress display is cleared and a plain-text summary line is printed (e.g. `Processed 12 documents.`)
- [ ] If processing is interrupted (Ctrl-C / SIGINT) the display is cleared and the cursor is restored before exit, leaving the terminal in a clean state
- [ ] Colours used in the progress display are consistent with the palette already defined in `doc.doc.md/components/ui.sh`; the feature adds no new colour constants
- [ ] Progress rendering logic lives in `doc.doc.md/components/ui.sh` as a dedicated function set (e.g. `ui_progress_init`, `ui_progress_update`, `ui_progress_done`)

### Backward compatibility
- [ ] All existing `process` flags and behaviour are unchanged (REQ_0038)
- [ ] Existing tests continue to pass; progress output does not pollute captured stdout in test mode because tests do not attach a TTY
- [ ] New tests verify that `--no-progress` suppresses all ANSI output and that the summary line is printed correctly

## Dependencies
- REQ_0006 (User-Friendly Interface)
- REQ_0009 (Process Command)
- REQ_0032 (Separate UI Module)
- REQ_0038 (Backward-Compatible CLI)
- FEATURE_0019 (process output directory — baseline process pipeline)
- FEATURE_0020 (extract UI module — ui.sh baseline)
- FEATURE_0024 (process `--echo` dry-run — `--no-progress` must also suppress output in echo mode)
- FEATURE_0025 (interactive setup routine — shares TTY-detection and UI conventions)

## Related Links
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0006_user-friendly-interface.md`
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0009_process-command.md`
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0032_separate-ui-module.md`
- UI module: `doc.doc.md/components/ui.sh`
- Orchestration: `doc.doc.sh`
