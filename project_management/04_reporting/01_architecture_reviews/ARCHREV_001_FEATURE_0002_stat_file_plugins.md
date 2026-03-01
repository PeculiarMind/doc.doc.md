# Architecture Review: FEATURE_0002 — stat and file Plugin Implementation

- **ID:** ARCHREV_001
- **Created at:** 2026-03-01
- **Created by:** architect.agent
- **Work Item:** [FEATURE_0002](../../../project_management/03_plan/02_planning_board/05_implementing/FEATURE_0002_implement_stat_and_file_plugins.md)
- **Status:** Conditionally Compliant

## TOC

1. [Reviewed Scope](#reviewed-scope)
2. [Architecture Vision Reference](#architecture-vision-reference)
3. [Compliance Assessment](#compliance-assessment)
4. [Deviations Found](#deviations-found)
5. [Recommendations](#recommendations)
6. [Conclusion](#conclusion)

## Reviewed Scope

Six bash scripts implementing the stat and file plugins for doc.doc.md:

| Plugin | Script | Purpose |
|--------|--------|---------|
| stat | `doc.doc.md/plugins/stat/main.sh` | Extracts file statistics (size, owner, timestamps) |
| stat | `doc.doc.md/plugins/stat/installed.sh` | Checks if `stat` command is available |
| stat | `doc.doc.md/plugins/stat/install.sh` | Reports stat availability / install guidance |
| file | `doc.doc.md/plugins/file/main.sh` | Detects MIME type via `file` command |
| file | `doc.doc.md/plugins/file/installed.sh` | Checks if `file` command is available |
| file | `doc.doc.md/plugins/file/install.sh` | Reports file availability / install guidance |

Also reviewed:
- `doc.doc.md/plugins/stat/descriptor.json`
- `doc.doc.md/plugins/file/descriptor.json`

## Architecture Vision Reference

- [ADR-003: JSON-Based Plugin Descriptors with Shell Command Invocation](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md)
- [ARC-0003: Plugin Architecture Concept](../../02_project_vision/03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md)
- [ADR-002: Prioritize Reuse of Existing Tools](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_002_prioritize_tool_reuse.md)

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| **ADR-003 — JSON stdin/stdout** | Compliant | Both process commands read JSON from stdin via `cat` and pipe through `jq -r`. All six scripts write structured JSON to stdout exclusively via `jq -n`. No non-JSON content is emitted on stdout. |
| **ADR-003 — lowerCamelCase parameters** | Compliant | All input parameters (`filePath`) and output parameters (`fileSize`, `fileOwner`, `fileCreated`, `fileModified`, `fileMetadataChanged`, `mimeType`, `installed`, `success`, `message`) follow lowerCamelCase convention. |
| **ADR-003 — jq usage** | Compliant | JSON parsing uses `jq -r '.filePath // empty'` with stderr redirection. JSON generation uses `jq -n` with `--arg` / `--argjson` for proper type handling. No manual JSON string construction. |
| **ADR-003 — Plugin structure** | Compliant | Both plugins contain the four required files: `descriptor.json`, `main.sh`, `install.sh`, `installed.sh`. Directory layout matches the canonical structure defined in ADR-003. |
| **ADR-003 — Exit codes** | Compliant | Process commands: exit 0 on success, exit 1 on error. Install commands: exit 0 on success, exit 1 on failure. Installed commands: always exit 0. Consistent with ADR-003 contract. |
| **ARC-0003 — Standard commands** | Compliant | Both plugins implement all three required standard commands: `process` (main.sh), `install` (install.sh), `installed` (installed.sh). |
| **ARC-0003 — Descriptor contract** | Deviation | Install command output includes `message` field not declared in either descriptor.json. See [Deviations Found](#deviations-found). |
| **ARC-0003 — Plugin interface** | Compliant | Process commands accept JSON input via stdin and produce JSON output via stdout. Install/installed commands produce JSON output via stdout with no input required. |
| **ADR-002 — Tool reuse** | Compliant | stat plugin reuses: `stat`, `uname`, `date`, `jq`. file plugin reuses: `file`, `jq`. No custom reimplementations of existing tool functionality. Fully aligned with tool-reuse-first principle. |
| **Error handling — stderr/stdout separation** | Compliant | All error messages use `>&2` for stderr. stdout is reserved exclusively for JSON output. Error messages are clear and actionable (e.g., "File not found", "Missing filePath", "Invalid JSON input"). |
| **Cross-platform — Linux/macOS** | Compliant | stat/main.sh detects platform via `uname -s` and uses platform-appropriate `stat` flags (`-c` for Linux, `-f` for macOS). Date conversion uses platform-appropriate `date` syntax. file/main.sh uses portable `file --mime-type -b` flags that work on both platforms. |
| **Output type correctness** | Compliant | stat/main.sh uses `--argjson` for `fileSize` (preserving numeric type) and `--arg` for string fields. file/main.sh uses `--arg` for `mimeType`. installed.sh uses jq booleans (`true`/`false`). Types match descriptor declarations. |
| **Bash best practices** | Compliant | Process commands use `set -euo pipefail`. All scripts use `#!/bin/bash` shebang. Scripts include descriptive comments. `command -v` is used for portable command availability checks. |

## Deviations Found

### DEV-001: Install command output includes undeclared `message` field

**Affected files:**
- `doc.doc.md/plugins/stat/install.sh`
- `doc.doc.md/plugins/file/install.sh`

**Description:**
Both install.sh scripts output a JSON object with two fields: `success` (boolean) and `message` (string). However, the corresponding `descriptor.json` files only declare `success` as an output parameter for the install command. The `message` field is not documented in the descriptor contract.

**Stat descriptor install output (current):**
```json
"output": {
    "success": { "type": "boolean", "description": "..." }
}
```

**Stat install.sh actual output:**
```json
{"success": true, "message": "stat command already available"}
```

**Severity:** Low — The deviation is additive (extra data, not missing data). Consumers that rely on the descriptor contract will not break. The `message` field was explicitly requested in the FEATURE_0002 acceptance criteria.

**Remediation:** Update both `descriptor.json` files to declare the `message` output parameter for the install command, aligning the descriptor with the implementation and the acceptance criteria.

**DEBTR Record:** [DEBTR_001](../../03_plan/02_planning_board/04_backlog/DEBTR_001_update_install_command_descriptors.md)

## Recommendations

1. **Update install command descriptors** (tracked as DEBTR_001): Add the `message` output parameter to the install command in both `stat/descriptor.json` and `file/descriptor.json`. This is a documentation-level fix that aligns the contract with the implemented behavior and the acceptance criteria.

2. **Consider adding `set -euo pipefail`** to `installed.sh` and `install.sh` scripts for consistency with the process commands. This is not a compliance issue but would improve robustness.

3. **Future consideration — exit code 2**: ADR-003 defines exit code 2 as "fatal error (stop processing)" for process commands. Current implementations only use exit codes 0 and 1. This is acceptable for now but should be considered as plugin complexity grows.

## Conclusion

The stat and file plugin implementation is **conditionally compliant** with the architecture vision. All core architectural requirements are met: JSON stdin/stdout communication, lowerCamelCase naming, jq-based JSON handling, standard command structure, tool reuse, proper error handling, and cross-platform support.

One low-severity deviation was identified: the install command scripts produce a `message` output field that is not declared in the plugin descriptors. This is an additive deviation that does not break the contract but should be remediated by updating the descriptors. A DEBTR_001 work item has been created to track this remediation.

The implementation serves as a high-quality reference for future plugin development, demonstrating all required architectural patterns correctly.
