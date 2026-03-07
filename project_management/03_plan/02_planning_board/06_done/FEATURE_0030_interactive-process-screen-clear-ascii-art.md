# Feature: Screen Clear and ASCII Art Banner on Interactive Process Start

- **ID:** FEATURE_0030
- **Priority:** Medium
- **Type:** Feature
- **Created at:** 2026-03-07
- **Created by:** Product Owner
- **Status:** BACKLOG

## Overview
When `doc.doc.sh process` is started in interactive (TTY) mode, the terminal should be cleared and an ASCII art banner printed before any processing output appears. This provides a focused, visually clean user experience and establishes a clear separation between the tool's UI and its processing output.

## Implementation Notes (from architecture review)

- The banner function `ui_show_banner` belongs in `doc.doc.md/components/ui.sh`. There is no existing banner code in `ui.sh`.
- **All banner output MUST go to stderr** (`>&2`). The `process` command already streams the JSON result array to stdout. Any banner content written to stdout would corrupt the JSON pipeline when stdout is piped.
  - `printf '\033c' >&2` — screen clear to stderr
  - `cat >&2 <<'BANNER' ... BANNER` — banner text to stderr
- The TTY gate is `[ -t 2 ]` (stderr is a TTY), matching the existing `ui_progress_init` pattern in `ui.sh`.
- The call site is inside the `process()` function in `doc.doc.sh`, before `ui_progress_init`.
- When `--echo` flag is active (FEATURE_0024), the banner and screen clear must be suppressed regardless of TTY state (banner to stderr would be acceptable but the screen clear would corrupt the echoed markdown output).
- The test file reference is `tests/test_feature_0030.sh`.

## Acceptance Criteria
- [ ] The terminal screen is cleared at the start of interactive process mode (`[ -t 2 ]` — stderr is a TTY)
- [ ] The ASCII art banner is printed immediately after the screen clear, **to stderr**
- [ ] The following exact content is printed (character-for-character):
  ```
    ___     ___    ____      ____    ___    ____      __  __  ____    
   |  _ \  / _ \  / ___|    |  _ \  / _ \  / ___|    |  \/  ||  _ \   
   | | | || | | || |        | | | || | | || |        | |\/| || | | |  
   | |_| || |_| || |___  _  | |_| || |_| || |___  _  | |  | || |_| | 
   |____/  \___/  \____|(_) |____/  \___/  \____|(_) |_|  |_||____/  
  
               ~ document your documents in markdown ~ 
  
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  ▓▓▓ [ PAPER STACK ] >> [ SCAN ] >> [ doc.doc.sh ] >> [ .MD SIDECAR ] ▓▓▓
  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ```
- [ ] All banner and screen-clear output goes to **stderr**, not stdout — stdout remains clean for JSON pipeline use
- [ ] All subsequent processing output (progress, results, errors) appears below the banner
- [ ] Non-interactive mode (`[ -t 2 ]` is false) suppresses the banner and screen clear entirely
- [ ] `--echo` mode (FEATURE_0024) suppresses the banner and screen clear regardless of TTY state
- [ ] The `ui_show_banner` function is implemented in `doc.doc.md/components/ui.sh`
- [ ] Existing tests pass without modification
- [ ] REQ_0038 (backward-compatible CLI) is not violated

## Dependencies
- REQ_0040 (Screen Clear and ASCII Art on Interactive Process Start)
- REQ_0032 (Separate UI Module)
- FEATURE_0026 (Interactive Progress Display — the banner must not conflict with the progress bar)

## Related Links
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0040_interactive-process-screen-clear-ascii-art.md`
- Architecture Concept: `project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_0008_interactive_process_banner.md`
