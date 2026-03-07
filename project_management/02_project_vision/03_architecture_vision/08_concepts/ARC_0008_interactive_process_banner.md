## Interactive Process Banner: Screen Clear and ASCII Art on Process Start

**Author:** Architect Agent
**Created on:** 2026-03-07
**Last Updated:** 2026-03-07
**Status:** Accepted


**Version History**
| Date       | Author          | Description               |
|------------|-----------------|---------------------------|
| 2026-03-07 | Architect Agent | Initial draft             |
| 2026-03-07 | Architect Agent | Code review: add >&2 to all banner output; document --no-progress open question |

**Table of Contents:**
- [Problem Statement](#problem-statement)
- [Scope](#scope)
- [In Scope](#in-scope)
- [Out of Scope](#out-of-scope)
- [Proposed Solution](#proposed-solution)
- [Benefits](#benefits)
- [Challenges and Risks](#challenges-and-risks)
- [Implementation Plan](#implementation-plan)
- [Conclusion](#conclusion)
- [References](#references)


### Problem Statement

When a user invokes `doc.doc.sh process` interactively, processing output begins immediately after the command line, mixed into whatever was already visible in the terminal. There is no visual boundary that signals the start of a new processing session, no clearing of unrelated terminal content, and no branding or personality that makes the tool memorable.

REQ_0040 requires that in interactive process mode, the terminal is cleared and a fixed ASCII art banner is displayed before any other output. This transforms the terminal into a focused workspace for the processing session and gives the tool a recognisable identity.

The challenge is architectural: which module owns the banner, when exactly is it shown, how is interactive mode detected reliably, and how does the banner interact with the existing progress display and JSON streaming logic without breaking non-interactive (piped/scripted) usage?


### Scope

This concept defines:
- Ownership of the banner display function (`ui.sh`)
- The detection strategy for interactive vs non-interactive mode
- The precise point in the execution flow where the clear and banner occur
- How the feature interacts with the existing progress and JSON output modes


### In Scope

- A new `ui_show_banner` function added to `ui.sh`
- Invocation of `ui_show_banner` from the process branch of `main()` in `doc.doc.sh`
- Interactive mode detection using terminal TTY checks
- Use of `printf '\033c'` for screen clearing
- The exact ASCII art banner string specified in REQ_0040


### Out of Scope

- Making the banner configurable or suppressible by users (REQ_0040 specifies a fixed string)
- Showing a banner for other sub-commands (`list`, `activate`, etc.)
- Non-interactive invocation behaviour (no banner, no clear)
- Progress display redesign
- Colour or ANSI styling beyond the block characters in the banner itself


### Proposed Solution

#### 1. Module Ownership: `ui.sh`

The banner function belongs in `ui.sh`. This is the canonical home for all user-facing interaction in the architecture (see [ARC_0005 Logging and Progress](ARC_0005_logging_and_progress.md) and REQ_0032 Separate UI Module). `ui.sh` already owns progress messages, log formatting, and all help text. Adding `ui_show_banner` there is consistent with the established separation of concerns.

`doc.doc.sh` itself remains responsible only for calling the banner function at the right moment in the processing flow; it does not embed any banner string or screen-clearing logic directly.

#### 2. Interactive Mode Detection

The framework already contains two TTY checks in `doc.doc.sh`'s process handler:

```bash
# Whether to stream JSON to stdout
local suppress_json=false
if [ -t 1 ]; then suppress_json=true; fi

# Whether to show progress on stderr
elif [ -t 2 ]; then
  show_progress=true
fi
```

The banner condition mirrors the existing progress check: **the banner is shown if and only if stderr is an interactive TTY** (`[ -t 2 ]`). This aligns the banner with the progress display — both appear only when a human is watching, and both are suppressed in piped, redirected, or CI execution contexts.

The rationale for using `stderr` rather than `stdout` as the TTY anchor: `stdout` may be piped (to capture JSON) while `stderr` remains a terminal. In that scenario the progress display (on `stderr`) is already active and the banner should be shown. Using `stdout` as the gate would incorrectly suppress the banner in this case.

Condition:
```bash
if [ -t 2 ]; then
  ui_show_banner
fi
```

#### 3. Placement in the Execution Flow

The banner invocation is the **first action** inside the process command handler after argument parsing and initial validation have confirmed that the `process` sub-command is being executed. It must appear before:

- `ui_progress_init` (progress bar initialisation)
- The "Scan directory" phase
- Any file count or processing output

Placement in `doc.doc.sh` `main()` — process branch (note: there is no `cmd_process` function; all process logic is inline in `main()`):

```
main() — process branch:
  [argument parsing and validation]
  [input/output/template validation]

  <<< ui_show_banner here (before progress init) >>>

  [discover active plugins]
  [ui_progress_init / Scan phase]
  [file discovery]
  [processing loop]
}
```

This ensures the terminal is clean and the banner is visible before any other text is printed to the user's screen.

#### 4. `ui_show_banner` Implementation

```bash
ui_show_banner() {
  printf '\033c' >&2
  cat >&2 <<'BANNER'
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
BANNER
}
```

**All output goes to stderr (`>&2`).** This is mandatory. The banner condition is `[ -t 2 ]` (stderr is a TTY), but stdout may simultaneously be a pipe (e.g., `doc.doc.sh process ... | jq .`). If `printf '\033c'` or the heredoc writes to stdout in that scenario, the escape sequence and banner text are injected into the JSON pipe and must corrupt the output. Directing all banner content to stderr ensures it appears on the user's terminal regardless of stdout disposition.

The banner string is a fixed `cat` heredoc. It MUST match the exact content from REQ_0040 character-for-character, including block characters.

#### 5. Interaction with Existing Output Modes

| Invocation context | `[ -t 2 ]` | Banner shown | Progress shown | JSON to stdout |
|---|---|---|---|---|
| Interactive TTY, `-o` given | true | **Yes** | Yes (stderr) | Suppressed |
| Interactive TTY, stdout piped | true | **Yes** | Yes (stderr) | Yes (stdout) |
| Non-interactive (CI/script) | false | No | No | Yes (stdout) |
| `--progress` forced | false | No | Yes (stderr) | Yes (stdout) |
| `--no-progress` forced | true | **Yes** | No | Suppressed |

The `--no-progress` case: progress is suppressed but the banner is still shown because stderr is still a TTY. The banner is a one-time visual reset, not a progress indicator; it is not governed by the `--progress`/`--no-progress` flags.

A possible future addition is a `--no-banner` flag, but this is explicitly out of scope for REQ_0040, which specifies the banner as non-configurable.


### Benefits

- **Focused UX**: A clean terminal and visual boundary sharply distinguishes the processing session from preceding terminal history.
- **Brand identity**: The ASCII art gives the tool personality and makes it immediately recognisable.
- **Non-intrusive**: The feature is gated on `[ -t 2 ]`; scripts, CI pipelines, and piped invocations are entirely unaffected.
- **Zero-dependency implementation**: `printf '\033c'` and a bash heredoc require no additional tools.
- **Architectural consistency**: Placing the function in `ui.sh` keeps all user-facing output logic in a single module, consistent with the existing architecture.


### Challenges and Risks

- **Test environment compatibility**: Automated tests run in non-interactive shells (`[ -t 2 ]` is false). The banner is never shown in tests, which means its rendering cannot be easily asserted. Tests should verify that the `ui_show_banner` function exists and that the process command does not print unexpected content before the banner in interactive mode. End-to-end banner verification requires a pseudo-TTY (e.g., `script(1)` or `expect`) and is considered an optional quality gate.
- **Terminal emulator edge cases**: A small number of terminal emulators may not respond to `\033c` as a full reset. Mitigation: `\033c` is the ANSI terminal reset sequence and is supported by all modern terminal emulators (xterm, VTE, iTerm2, Windows Terminal). The `clear` command could be used as a fallback for environments where `\033c` fails, but this adds complexity without practical benefit.
- **Banner placement with `--no-progress`**: If future changes introduce validation output before the banner invocation point, the banner could appear mid-stream. The implementation plan must enforce that no output-producing logic runs before `ui_show_banner` in the process handler.
- **Wide terminal assumption**: The banner is designed for a terminal at least 72 characters wide. Narrower terminals will cause text wrapping. No adaptive layout is planned; this matches the requirement's fixed-string specification.


### Implementation Plan

1. **`ui.sh`**: Add `ui_show_banner` function implementing screen clear and banner output (all output directed to stderr).
2. **`doc.doc.sh` `main()` — process branch**: Add the `[ -t 2 ]` guard and `ui_show_banner` call at the designated point (after argument validation, before `ui_progress_init`). Note: the process sub-command logic is inline in `main()`, not in a separate `cmd_process` function.
3. **`ui.sh` public interface comment**: Add `ui_show_banner` to the module's public interface documentation block.
4. **Test**: Add `tests/test_feature_0030.sh` verifying that:
   - `ui_show_banner` is defined and callable
   - In non-interactive mode, invoking the process command produces no clear-screen sequence
5. **Regression**: Run the existing test suite; verify no progress or JSON output is affected.


### Conclusion

The interactive process banner is a small, self-contained UI enhancement. Placing the logic in `ui.sh`, gating it on `[ -t 2 ]`, and positioning the call before any progress output fully satisfies REQ_0040 while leaving all non-interactive behaviour untouched. The primary implementation risk is ensuring no output escapes before the banner in the process handler — a constraint that is enforced by call order in `doc.doc.sh`.


### References

- [REQ_0040 Screen Clear and ASCII Art on Interactive Process Start](../../../02_requirements/03_accepted/REQ_0040_interactive-process-screen-clear-ascii-art.md)
- [REQ_0032 Separate UI Module](../../../02_requirements/03_accepted/REQ_0032_separate-ui-module.md)
- [ARC_0005 Logging and Progress](ARC_0005_logging_and_progress.md)
- [ui.sh](../../../../doc.doc.md/components/ui.sh) — UI module source
- [doc.doc.sh](../../../../doc.doc.sh) — Process command handler and existing TTY detection logic
- [Project Goals TODO 2](../../../01_project_goals/project_goals.md)
