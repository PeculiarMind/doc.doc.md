# Feature: Full Mustache Template Support via Python

- **ID:** FEATURE_0040
- **Priority:** Medium
- **Type:** Feature
- **Created at:** 2026-03-14
- **Created by:** Product Owner
- **Status:** IMPLEMENTING

## TOC
1. [Overview](#overview)
2. [Motivation](#motivation)
3. [Scope](#scope)
4. [Implementation Notes](#implementation-notes)
5. [Acceptance Criteria](#acceptance-criteria)
6. [Dependencies](#dependencies)
7. [Related Links](#related-links)

## Overview

Replace the current Bash string-substitution template engine in `doc.doc.md/components/templates.sh` with a full Mustache implementation written in Python. A new standalone component `doc.doc.md/components/mustache_render.py` accepts a template file path and a JSON object and renders the template against the full Mustache specification. The Bash function `render_template_json` is updated to delegate to this script instead of performing its own `{{key}}` substitution.

**Business Value:**
- Unlocks rich template authoring: conditionals, loops over arrays, inverted sections, comments, and (optionally) partials — capabilities that are impossible with the current single-pass string substitution.
- Enables templates to iterate over multi-valued plugin output (e.g. a list of OCR pages, keyword arrays) without custom Bash code per key.
- Keeps Bash code simple: `templates.sh` becomes a thin shell shim, with all rendering logic in maintainable, testable Python.
- Backward compatible: existing `{{key}}` templates continue to work unchanged.

## Motivation

The current rendering engine in `render_template_json` uses Bash parameter expansion (`${content//\{\{${key}\}\}/${val}}`) which:

- Supports only simple scalar `{{key}}` substitution.
- Cannot iterate over array values returned by plugins.
- Cannot express conditional content (show a section only when OCR text is present).
- Cannot suppress empty sections cleanly.
- Performs substitution in a Bash string loop, which carries inherent risks when values contain special characters (see REQ_SEC_004).

Delegating rendering to a purpose-built Python Mustache library (`chevron`, MIT licence — compatible with this project's AGPL-3.0 licence) eliminates these limitations while improving security, testability, and maintainability.

## Scope

### 1 — New file: `doc.doc.md/components/mustache_render.py`

A standalone, executable Python 3 script that:

1. Accepts exactly two positional command-line arguments:
   - `<template_file>` — path to the Mustache template file to render.
   - `<json_string>` — the accumulated JSON object produced by the plugin pipeline (same object currently passed to `render_template_json`).
2. Parses `<json_string>` with `json.loads`.
3. Derives `fileName` from the `filePath` key (identical logic to the current Bash implementation) and injects it into the data dict before rendering.
4. Renders the template using the `chevron` library (preferred) or `pystache` as a fallback, supporting the full Mustache spec:
   - `{{variable}}` — HTML-escaped variable interpolation.
   - `{{{variable}}}` — unescaped variable interpolation.
   - `{{#section}}...{{/section}}` — sections (truth checks, array loops).
   - `{{^inverted}}...{{/inverted}}` — inverted sections (falsy blocks).
   - `{{! comment }}` — comments (stripped from output).
   - `{{> partial}}` — partials (stretch goal; may be omitted in initial implementation if the chosen library does not trivially support them from the filesystem).
5. Writes rendered output to **stdout** with no trailing newline manipulation (preserves content as-is).
6. Exits 0 on success, 1 on error (prints error message to stderr).

The script must never use `eval`, subprocess shell execution on template content, or any mechanism that allows template values to execute code (REQ_SEC_004).

### 2 — Updated `render_template_json` in `templates.sh`

Replace the Bash substitution loop with a single call to `mustache_render.py`:

```bash
render_template_json() {
  local template="$1"
  local result_json="$2"
  python3 "$(dirname "${BASH_SOURCE[0]}")/mustache_render.py" "$template" "$result_json"
}
```

- The `mustache_render.py` path is resolved relative to `templates.sh` (not the caller's cwd).
- The function signature and return behaviour (rendered string to stdout) remain unchanged so all callers continue to work without modification.

### 3 — Library dependency: `chevron`

- `chevron` (PyPI: `chevron`) is a pure-Python, zero-dependency Mustache renderer licensed under **MIT**.
- MIT is compatible with this project's AGPL-3.0 licence: `chevron` may be used as a runtime dependency without licence conflict.
- The library is already available in many Python environments; if not present, `mustache_render.py` must emit a clear error directing the user to install it (`pip install chevron`).
- If `chevron` is unavailable and a fallback is desired, `pystache` (also MIT) may be used as a secondary option, but `chevron` is the primary target.

### 4 — No change to default template syntax for existing placeholders

The default template `doc.doc.md/templates/default.md` uses only `{{key}}` syntax. These continue to render identically under Mustache (scalar variable lookup). No template file changes are required unless the developer chooses to enhance them as a separate task.

## Implementation Notes

- `mustache_render.py` must reside in `doc.doc.md/components/` alongside `filter.py` and `plugin_info.py`. It must be executable (`chmod +x`).
- The script receives the full accumulated JSON from the pipeline. Plugin keys with array values (e.g. a future plugin returning `{"keywords": ["a","b"]}`) will automatically become iterable Mustache sections without any additional Bash glue.
- HTML escaping in `{{variable}}` is per the Mustache spec. Since the output is Markdown (not HTML), templates may prefer `{{{variable}}}` for content that should not be HTML-escaped. Both forms must work correctly.
- Error handling: if `<template_file>` does not exist, or `<json_string>` is not valid JSON, `mustache_render.py` prints a diagnostic to stderr and exits 1. `render_template_json` should propagate this exit code to the caller.
- The `fileName` derivation currently done in Bash (`basename "$fp"`) must be replicated in Python before the Mustache render call so that `{{fileName}}` continues to work in templates.
- Security: template data values are treated as plain strings by `chevron`; no shell interpretation occurs. This satisfies REQ_SEC_004.

## Acceptance Criteria

### mustache_render.py — Component

- [ ] `doc.doc.md/components/mustache_render.py` exists and is executable (`chmod +x`).
- [ ] Script accepts exactly two positional arguments: `<template_file>` and `<json_string>`.
- [ ] Script renders `{{variable}}` placeholders (HTML-escaped) from JSON scalar values.
- [ ] Script renders `{{{variable}}}` placeholders (unescaped) from JSON scalar values.
- [ ] Script renders `{{#section}}...{{/section}}` for truthy values and array loops.
- [ ] Script renders `{{^inverted}}...{{/inverted}}` for falsy/empty values.
- [ ] Script renders `{{! comment }}` by omitting the comment from output.
- [ ] Script derives `fileName` from the `filePath` JSON key (using `os.path.basename`) and makes it available as `{{fileName}}` in all templates.
- [ ] Script exits 0 on successful render and writes the rendered content to stdout.
- [ ] Script exits 1 and writes a diagnostic message to stderr if `chevron` is not installed.
- [ ] Script exits 1 and writes a diagnostic message to stderr if `<template_file>` does not exist or is not readable.
- [ ] Script exits 1 and writes a diagnostic message to stderr if `<json_string>` is not valid JSON.
- [ ] Script does not use `eval`, `exec`, or any shell execution mechanism on template content or variable values.

### render_template_json — Bash shim

- [ ] `render_template_json` in `templates.sh` calls `mustache_render.py` instead of performing Bash string substitution.
- [ ] The `mustache_render.py` path is resolved relative to `templates.sh` (invariant to caller cwd).
- [ ] `render_template_json` propagates the exit code of `mustache_render.py` to its caller.
- [ ] The function signature (two positional args: template file, JSON string) is unchanged.

### Backward Compatibility

- [ ] The default template `doc.doc.md/templates/default.md` renders identically under the new engine compared to the old Bash implementation (all existing `{{key}}` placeholders are replaced correctly).
- [ ] All existing integration tests (`tests/test_docs_integration.sh`) pass without modification.
- [ ] All existing feature tests that exercise templating pass without modification.

### Tests

- [ ] A test script `tests/test_feature_0040.sh` (or equivalent) exists.
- [ ] Test verifies that `{{variable}}` substitution works for scalar string values.
- [ ] Test verifies that `{{{variable}}}` renders without HTML escaping.
- [ ] Test verifies that `{{#list}}...{{/list}}` iterates correctly over a JSON array.
- [ ] Test verifies that `{{^missing}}...{{/missing}}` renders the block when the key is absent/falsy.
- [ ] Test verifies that `{{! comment }}` content is absent from the output.
- [ ] Test verifies that `{{fileName}}` is derived from `filePath` and rendered correctly.
- [ ] Test verifies that a missing `<template_file>` causes exit code 1 and a stderr message.
- [ ] Test verifies that invalid JSON input causes exit code 1 and a stderr message.
- [ ] Test verifies that `render_template_json` produces identical output for the default template compared to the original Bash implementation (regression guard).

## Dependencies

- REQ_0007 (Markdown Output — template rendering is the final step in sidecar file generation)
- REQ_0009 (Process Command — `render_template_json` is called in the process pipeline)
- REQ_SEC_004 (Template Injection Prevention — mustache_render.py must satisfy safe substitution controls)
- FEATURE_0019 (Process Output Directory — introduced `render_template_json`; this feature replaces its internals)
- Runtime dependency: `chevron` Python package (MIT licence, compatible with AGPL-3.0)

## Related Links

- Template rendering: `doc.doc.md/components/templates.sh` (function `render_template_json`)
- Default template: `doc.doc.md/templates/default.md`
- Python components (reference): `doc.doc.md/components/filter.py`, `doc.doc.md/components/plugin_info.py`
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0007_markdown-output.md`
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0009_process-command.md`
- Security requirement: `project_management/02_project_vision/02_requirements/03_accepted/REQ_SEC_004_template_injection_prevention.md`
- `chevron` on PyPI: https://pypi.org/project/chevron/
