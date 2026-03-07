# Requirement: Screen Clear and ASCII Art on Interactive Process Start

- **ID:** REQ_0040
- **State:** Accepted
- **Type:** Functional
- **Priority:** Medium
- **Created at:** 2026-03-07
- **Last Updated:** 2026-03-07

## Overview
`doc.doc.sh process` shall clear the terminal screen and display a fixed ASCII art banner before producing any other output in interactive process mode.

## Description
When `doc.doc.sh process` enters interactive process mode, the terminal shall be cleared and the following ASCII art banner shall be printed before any processing output:

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

All subsequent processing output (phase progress, plugin results, summaries, errors) shall be printed below the banner, with no content appearing above it.

The screen clear shall use the standard terminal `clear` command (or equivalent `printf '\033c'`). The banner is a fixed string and shall not be configurable by the user.

This behaviour applies only when running in interactive process mode. Non-interactive invocations (e.g., piped or scripted usage) are outside the scope of this requirement.

## Motivation
Derived from:
[project_management/02_project_vision/01_project_goals/project_goals.md](../../01_project_goals/project_goals.md) — TODO 2: "create a feature that doc.doc.sh clears the screen before starting the interactive process mode to provide a cleaner and more focused user experience … An ascii art could be printed after clearing the screen to add a touch of personality to the tool."

## Acceptance Criteria
- [ ] Invoking `doc.doc.sh process` in interactive mode clears the terminal screen as the first visible action
- [ ] The exact ASCII art banner specified above is printed immediately after the screen clear
- [ ] No output from any processing phase appears above (before) the ASCII art banner
- [ ] The banner text matches the specified content character-for-character, including the decorative block-character lines
- [ ] All subsequent output (progress, errors, summaries) appears below the banner
- [ ] Interactive mode is detected by checking whether file descriptor 2 (stderr) is a TTY (`[ -t 2 ]`); screen clear and banner are suppressed when this test fails — this is the same TTY gate used by the existing progress display
- [ ] Non-interactive (piped) invocations are not affected by this change
- [ ] When `--echo` is active (FEATURE_0024 dry-run mode), screen clear and banner are suppressed regardless of TTY state, to avoid corrupting the stdout markdown stream that `--echo` produces
- [ ] Existing test suite passes without modification after the feature is implemented

## Related Requirements
- [REQ_0006 User-Friendly Interface](REQ_0006_user-friendly-interface.md)
- [REQ_0009 Process Command](REQ_0009_process-command.md)
- [REQ_0032 Separate UI Module](REQ_0032_separate-ui-module.md)
- FEATURE_0024 (Process `--echo` Dry-Run) — implementation of REQ_0040 must be coordinated with FEATURE_0024 to ensure the banner is suppressed in `--echo` mode
