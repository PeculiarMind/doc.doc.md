# Architecture Decisions

This section indexes architecture decisions made during implementation. Vision-level decisions (ADRs) are maintained in `project_management/`. Implementation-level decisions (IDRs) that arose during development are documented here.

## Architecture Decision Records (ADRs)

These decisions were made during the architecture vision phase and remain authoritative. See linked documents for full context, alternatives considered, and rationale.

| ID | Title | Status | Link |
|----|-------|--------|------|
| ADR-001 | Mixed Bash/Python Implementation | DECIDED | [ADR_001](../../../project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_001_mixed_bash_python_implementation.md) |
| ADR-002 | Prioritize Reuse of Existing Tools | DECIDED | [ADR_002](../../../project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_002_prioritize_tool_reuse.md) |
| ADR-003 | JSON-Based Plugin Descriptors with Shell Command Invocation | DECIDED | [ADR_003](../../../project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md) |

### ADR-001 Summary: Mixed Bash/Python

Bash handles all CLI orchestration, plugin invocation, and system operations. Python handles the filter evaluation engine (`filter.py`) where complex AND/OR logic across multiple filter types (extensions, globs, MIME types) would be fragile in pure Bash. The boundary is a Unix pipeline: `find | python3 filter.py`. Plugins are always invoked as shell commands — never imported as Python modules.

### ADR-002 Summary: Tool Reuse

Standard Unix utilities (`find`, `file`, `stat`, `jq`) are preferred over custom implementations. Custom code is justified only when existing tools are demonstrably inadequate. The filter engine (`filter.py`) is justified because shell-only AND/OR multi-criteria filtering is unmaintainable.

### ADR-003 Summary: JSON Plugin Descriptors

Each plugin has a `descriptor.json` declaring its commands, input/output parameter schemas, and activation state. All plugins implement three standard commands: `process`, `install`, `installed`. Communication is JSON via stdin/stdout. All parameter names follow lowerCamelCase. Dependencies between plugins are derived from parameter name/type matching — not from an explicit `dependencies` attribute.

## Implementation Decision Records (IDRs)

Implementation decisions that arose during development and require documentation.

| ID | Title | Status | Context |
|----|-------|--------|---------|
| IDR-001 | File Plugin First in Chain + MIME Filter Gate | Implemented | [ARCHREV_002](../../../project_management/04_reporting/01_architecture_reviews/ARCHREV_002_FEATURE_0007_file_plugin_first_mime_filter_gate.md) |

### IDR-001: File Plugin First in Chain and MIME Filter Gate

**Decision**: The `file` plugin is always placed first in the processing chain regardless of discovery order. MIME filter criteria (criteria containing `/` but not `**`) are evaluated after the `file` plugin runs via a dedicated MIME filter gate in `doc.doc.sh`.

**Rationale**: MIME-based filtering requires MIME type detection to have already run. Routing MIME criteria through the same `filter.py` mechanism (with `fnmatch`) provides consistency with path/glob filtering and avoids a separate code path in `filter.py`.

**Implementation details**:
- `doc.doc.sh` (lines 916–934) re-orders the active plugin list post-discovery to ensure `file` is at index 0.
- Criteria classification occurs before the processing loop: `_MIME_INCLUDE_ARGS` and `_MIME_EXCLUDE_ARGS` global arrays hold MIME criteria.
- After `file` plugin returns `mimeType`, `doc.doc.sh` pipes the MIME string to `filter.py` with the MIME criteria arrays. Empty output = file skipped.
- `filter.py` is unchanged; it applies `fnmatch` uniformly to both file paths and MIME type strings.

**Architecture review**: ARCHREV_002 — Compliant with Notes.
