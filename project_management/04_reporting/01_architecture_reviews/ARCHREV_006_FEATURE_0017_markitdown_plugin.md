# Architecture Review: FEATURE_0017 — Markitdown MS Office Plugin

- **ID:** ARCHREV_006
- **Created at:** 2026-03-06
- **Created by:** architect.agent
- **Work Item:** [FEATURE_0017](../../03_plan/02_planning_board/06_done/FEATURE_0017_markitdown_ms_office_plugin.md)
- **Status:** Compliant

## TOC

1. [Reviewed Scope](#reviewed-scope)
2. [Architecture Vision Reference](#architecture-vision-reference)
3. [Compliance Assessment](#compliance-assessment)
4. [Deviations Found](#deviations-found)
5. [Recommendations](#recommendations)
6. [Conclusion](#conclusion)

## Reviewed Scope

| File | Change | Purpose |
|------|--------|---------|
| `doc.doc.md/plugins/markitdown/descriptor.json` | New | Plugin metadata, command definitions, parameter contracts |
| `doc.doc.md/plugins/markitdown/main.sh` | New | Process command: converts MS Office documents to markdown text via `markitdown` |
| `doc.doc.md/plugins/markitdown/install.sh` | New | Install command: installs `markitdown` via pip |
| `doc.doc.md/plugins/markitdown/installed.sh` | New | Installed check command: verifies `markitdown` is on PATH |

## Architecture Vision Reference

- [ADR-003: JSON-Based Plugin Descriptors with Shell Command Invocation](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md)
- [ADR-002: Prioritize Reuse of Existing Tools](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_002_prioritize_tool_reuse.md)
- [ARC-0003: Plugin Architecture Concept](../../02_project_vision/03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md)
- [ARC-0006: Security Considerations](../../02_project_vision/03_architecture_vision/08_concepts/ARC_0006_security_considerations.md)

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| **ADR-003 — Plugin structure (four required files)** | ✅ Compliant | `descriptor.json`, `main.sh`, `install.sh`, and `installed.sh` are all present in `doc.doc.md/plugins/markitdown/`. |
| **ADR-003 — JSON stdin/stdout** | ✅ Compliant | `main.sh` reads JSON from stdin via `cat` and parses with `jq`. Output is produced with `jq -n --arg documentText "$document_text"`. No non-JSON content is emitted on stdout. `install.sh` and `installed.sh` produce JSON-only stdout. |
| **ADR-003 — lowerCamelCase parameters** | ✅ Compliant | All input parameters (`filePath`, `mimeType`) and the output parameter (`documentText`) follow lowerCamelCase convention. |
| **ADR-003 — jq for JSON handling** | ✅ Compliant | `main.sh` uses `jq -r '.filePath // empty'` and `jq -r '.mimeType // empty'` for input parsing, and `jq -n --arg` for output generation. No manual JSON string construction. |
| **ADR-003 — No `dependencies` field** | ✅ Compliant | The descriptor contains no `"dependencies"` key. The dependency on the `file` plugin (which supplies `mimeType`) is correctly resolved automatically via parameter name matching (per BUG_0005 fix). |
| **ADR-003 — Descriptor schema** | ✅ Compliant | Descriptor declares `name`, `version`, `description`, `active` (false), and `commands` with `process`, `install`, `installed`. All commands declare their `input`/`output` with `type` and `description`. `active: false` is architecturally appropriate since `markitdown` requires external installation. |
| **ADR-003 — Exit codes** | ✅ Compliant | `main.sh`: exit 0 on success, exit 1 on all error paths. `install.sh`: exit 0 in all cases (outputs `success: false` in JSON on failure). `installed.sh`: always exits 0. Consistent with ADR-003. |
| **ARC-0003 — Standard commands** | ✅ Compliant | All three required standard commands are implemented: `process` (main.sh), `install` (install.sh), `installed` (installed.sh). |
| **ARC-0003 — Plugin interface contract** | ✅ Compliant | `main.sh` accepts JSON input via stdin and emits JSON output via stdout. The `file` plugin's `mimeType` output feeds into `main.sh`'s `mimeType` input, correctly expressing the dependency chain through parameter naming. |
| **ADR-002 — Tool reuse** | ✅ Compliant | Reuses `markitdown` (Microsoft's open-source library), `jq`, `readlink`, `basename`. No reimplementation of existing tool functionality. |
| **ARC-0006 — Path validation** | ✅ Compliant | `filePath` is canonicalized with `readlink -f`. The resolved path is checked against the restricted list (`/proc/`, `/dev/`, `/sys/`, `/etc/`). A missing or unresolvable path produces a stderr error and exit 1. |
| **ARC-0006 — Input validation** | ✅ Compliant | Both required fields (`filePath`, `mimeType`) are validated for presence before use. A MIME gate rejects unsupported types before invoking `markitdown`. |
| **ARC-0006 — No shell injection** | ✅ Compliant | `markitdown` is invoked as `markitdown "$canonical_path"` where `canonical_path` is the output of `readlink -f` — a canonicalized, validated path. No user-supplied values are interpolated into unquoted shell constructs. |
| **ARC-0006 — stderr/stdout separation** | ✅ Compliant | All error messages use `>&2`. stdout is reserved exclusively for JSON output. No internal paths, stack traces, or system details are leaked to stdout on error. |
| **Bash best practices** | ✅ Compliant | `set -euo pipefail` is present in all three scripts. `#!/bin/bash` shebang is present. `command -v` is used for portable command availability check in `installed.sh`. |

## Deviations Found

None.

## Recommendations

1. **Restrict the MIME gate in main.sh**: The current implementation validates `mimeType` against an explicit allow-list using a loop comparison. This is correct and secure. However, the allow-list is hardcoded in the script and also declared in `descriptor.json` — two places to keep in sync. A future improvement could have `main.sh` read the allowed MIME types from its own descriptor, though the current duplication is low-risk.

2. **Install guard for pip/Python availability**: `install.sh` invokes `pip install markitdown` directly without first verifying that `pip` or Python 3 is available. If pip is absent, the error message will come from the shell rather than from the plugin's own error handling. Adding a `command -v pip >/dev/null 2>&1 || { jq -n '{"success": false, "message": "pip not found. Install Python 3 and pip first."}'; exit 0; }` guard before the install would produce a cleaner, more informative error for users without a Python environment. (Consistent with how `ocrmypdf/install.sh` behaves.)

3. **Multiline `documentText` in templates**: `documentText` will typically contain multiple paragraphs. The current `render_template_json` function in `doc.doc.sh` uses a line-by-line read loop that only captures the first line of multiline JSON string values (see DEBTR_003 in ARCHREV_008). Plugin authors who add `{{documentText}}` to a custom template should be aware of this limitation until it is resolved.

## Conclusion

The markitdown plugin is **fully compliant** with the architecture vision. All four required files are present. The plugin communicates exclusively through JSON stdin/stdout, uses jq for all JSON handling, follows lowerCamelCase parameter naming, and correctly omits the forbidden `dependencies` field. Security requirements from ARC-0006 are fully addressed: path canonicalization, restricted path blocking, MIME type gating, and input validation are all implemented correctly.

The dependency on the `file` plugin (which provides `mimeType`) is implicitly and correctly expressed through parameter name matching, consistent with the BUG_0005 fix and ADR-003.

**Result: PASS**
