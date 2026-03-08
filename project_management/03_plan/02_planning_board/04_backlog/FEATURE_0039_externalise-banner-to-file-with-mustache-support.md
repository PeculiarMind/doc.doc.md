# Feature: Externalise Banner to File with Mustache Placeholder Support

- **ID:** FEATURE_0039
- **Priority:** Low
- **Type:** Feature
- **Created at:** 2026-03-08
- **Created by:** Product Owner
- **Status:** BACKLOG

## TOC
1. [Overview](#overview)
2. [Motivation](#motivation)
3. [Scope](#scope)
4. [Implementation Notes](#implementation-notes)
5. [Acceptance Criteria](#acceptance-criteria)
6. [Dependencies](#dependencies)
7. [Related Links](#related-links)

## Overview

Move the ASCII art banner from its inline heredoc in `doc.doc.md/components/ui.sh` into a dedicated `doc.doc.md/components/banner.txt` file. `ui_show_banner` reads and renders this file at runtime, applying `{{key}}` placeholder substitution (consistent with the project's existing mustache convention in `templates.sh`) so that dynamic values such as `{{version}}` or `{{date}}` can be embedded in the banner in future.

## Motivation

The banner is currently hardcoded as a heredoc inside `ui_show_banner()` in `ui.sh`. This couples visual content to code, making it:
- Harder to edit (developers must touch bash source to tweak copy or layout)
- Impossible to inject dynamic values (version, environment, date) without code changes
- Inconsistent with how the project already handles text templates (`doc.doc.md/templates/default.md` and `templates.sh`)

Externalising the banner to `banner.txt` and adding `{{key}}` rendering makes it a first-class text asset, editable without touching bash, and ready to display metadata like the tool version in future.

## Scope

### 1 — New file: `doc.doc.md/components/banner.txt`

- Contains exactly the current ASCII art banner content (extracted verbatim from the heredoc in `ui.sh`).
- Uses `{{key}}` placeholders for any value that may be substituted at render time.
- Initially ships with no required placeholders; all `{{key}}` tokens that are not resolved are left as-is (graceful passthrough) so the banner degrades cleanly when no context is provided.

### 2 — Updated `ui_show_banner()` in `ui.sh`

Replace the heredoc with logic that:
1. Locates `banner.txt` relative to `ui.sh` (i.e. `$(dirname "${BASH_SOURCE[0]}")/banner.txt`).
2. Reads the file content.
3. Applies `{{key}}` substitution for a defined set of context variables passed as arguments or derived from the environment (e.g. `VERSION`, `DATE`). Unresolved placeholders are left unchanged.
4. Prints the result to stderr (preserving existing TTY guard and screen-clear behaviour, subject to FEATURE_0038 which removes the screen-clear for help output).

The substitution mechanism must follow the same `{{key}}` → value pattern already used by `render_template_json` in `templates.sh`. A new lightweight helper `ui_render_banner_text <content> [key=value ...]` may be introduced inside `ui.sh` if helpful, but reusing or calling `render_template_json` is also acceptable if it can be done without pulling in JSON dependencies for the simple banner case.

### 3 — No change to banner visuals

The rendered output of `ui_show_banner` must be byte-for-byte identical to the current output when no placeholders are present in `banner.txt` and no substitution context is supplied.

## Implementation Notes

- `banner.txt` path must be resolved relative to `ui.sh`, not relative to the caller's working directory, so it works regardless of `cwd`.
- If `banner.txt` is missing or unreadable at runtime, `ui_show_banner` must fall back silently (print nothing, no error) — the banner is decorative and must never break the tool.
- The placeholder substitution only needs to handle simple scalar `{{key}}` → string replacement. No loops, conditionals, or nested templates are required.
- Initially ship `banner.txt` with zero active placeholders; the mechanism just needs to work. A comment in `banner.txt` documenting the placeholder syntax (e.g. `# use {{version}} to display the tool version`) is welcome but not required.

## Acceptance Criteria

- [ ] `doc.doc.md/components/banner.txt` exists and contains the current ASCII art banner content (visually identical to the current heredoc)
- [ ] `ui_show_banner` reads its content from `banner.txt` instead of a heredoc; the heredoc is removed from `ui.sh`
- [ ] `banner.txt` path is resolved relative to `ui.sh` (not cwd-dependent)
- [ ] `{{key}}` placeholders in `banner.txt` are substituted with supplied values before printing; unrecognised placeholders are passed through unchanged
- [ ] When `banner.txt` is missing or unreadable, `ui_show_banner` silently produces no output and exits 0
- [ ] The rendered banner output is visually identical to the current output when no substitution context is provided
- [ ] A test verifies that a `{{key}}` placeholder in `banner.txt` is replaced with the expected value when a matching context is supplied to `ui_show_banner`
- [ ] A test verifies that the fallback (missing `banner.txt`) produces no output and no error
- [ ] Existing tests pass without modification

## Dependencies

- REQ_0006 (User-Friendly Interface)
- FEATURE_0030 (Interactive Process Screen Clear and ASCII Art — original banner introduction)
- FEATURE_0038 (Per-Command Help and Trimmed Global Help — adjusts banner screen-clear behaviour; must be coordinated)

## Related Links

- UI module: `doc.doc.md/components/ui.sh` (function `ui_show_banner`, line ~240)
- Template rendering: `doc.doc.md/components/templates.sh` (function `render_template_json` — existing `{{key}}` convention)
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0006_user-friendly-interface.md`
