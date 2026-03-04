# Solution Strategy

## Key Architectural Decisions

### 1. Mixed Bash/Python Implementation (ADR-001)

**Decision**: Use Bash for CLI orchestration and system operations; Python for complex filtering logic.

**Implemented as**:
- `doc.doc.sh`: 1027-line Bash script handling all command routing, plugin orchestration, and the MIME filter gate.
- `doc.doc.md/components/filter.py`: Python script evaluating include/exclude criteria using `fnmatch` and `subprocess` for MIME detection.
- Clean boundary: Bash invokes Python via shell pipeline; Python never imports plugin code.

**See**: [ADR-001](../../../project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_001_mixed_bash_python_implementation.md)

---

### 2. Tool Reuse Over Custom Implementation (ADR-002)

**Decision**: Prioritize existing proven tools (`find`, `file`, `stat`, `jq`) over custom implementations. Custom code requires documented justification.

**Implemented as**:
- `find` for directory traversal.
- `file --mime-type -b` for MIME detection (encapsulated in `file` plugin).
- `stat` for file metadata (encapsulated in `stat` plugin).
- Python `fnmatch` / `pathlib` for pattern matching.
- `jq` for JSON parsing/generation in all plugin scripts.
- Custom filter logic in `filter.py` is justified by the complexity of AND/OR multi-criteria evaluation (see ADR-001).

**See**: [ADR-002](../../../project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_002_prioritize_tool_reuse.md)

---

### 3. JSON-Based Plugin Descriptors with Shell Command Invocation (ADR-003)

**Decision**: Plugins described by `descriptor.json`; invoked as shell commands; communicate via JSON stdin/stdout.

**Implemented as**:
- Every plugin directory contains `descriptor.json`, `main.sh`, `install.sh`, `installed.sh`.
- `descriptor.json` declares `commands` object with `process`, `install`, `installed` entries.
- All input/output parameter names follow lowerCamelCase (e.g., `filePath`, `mimeType`, `fileSize`).
- `jq` used in plugin scripts for type-safe JSON parsing and generation.
- Plugin invocation pattern: `echo "$json_input" | bash main.sh`.
- Process isolation: each plugin invocation is a separate process.

**See**: [ADR-003](../../../project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md)

---

### 4. File Plugin First in Chain and MIME Filter Gate

**Decision**: The `file` plugin is always first in the processing chain; MIME criteria are evaluated after it runs via a dedicated filter gate.

**Implemented as**:
- `doc.doc.sh` (lines 176–194) re-orders the plugin list post-discovery, placing `file` first.
- Criteria containing `/` but not `**` are extracted as MIME criteria before the processing loop.
- After `file` plugin returns `mimeType`, `doc.doc.sh` pipes the MIME string to `filter.py` with the MIME criteria.
- `filter.py` is stateless and reused as-is for MIME gate evaluation; it applies `fnmatch` uniformly to both path and MIME inputs.
- Files failing the MIME gate produce no output and are skipped cleanly.

---

### 5. Type-Based Plugin Dependency Resolution

**Decision**: Plugin execution order is derived from matching output parameter types to input parameter types across plugin commands — not from an explicit `dependencies` attribute.

**Implemented as**:
- `plugins.sh` resolves execution order by comparing declared output fields of earlier plugins with required input fields of later plugins.
- The `ocrmypdf` plugin requires `mimeType` as input; this is satisfied by the `file` plugin's `mimeType` output, establishing an implicit dependency.
- An explicit `"dependencies"` field in `ocrmypdf/descriptor.json` is a known defect tracked as BUG_0005 (backlog).

## Quality Goal Achievement Strategy

### Usability (Priority 1)
- Intuitive subcommand structure: `process`, `list plugins`, `activate`, `deactivate`, `install`, `installed`, `tree`.
- Both long (`--plugin`) and short (`-p`) parameter forms throughout.
- Help accessible via `--help` at top level and per subcommand.
- Clear, actionable error messages to stderr; JSON output to stdout for scripting.

### Flexibility (Priority 2)
- Plugin architecture: add a plugin directory with `descriptor.json` and scripts — no core modification required.
- Three filter criterion types: file extensions (`.pdf`), glob patterns (`**/2024/**`), MIME types (`image/*`).
- Customizable templates via `--template` flag.
- Language-agnostic plugin interface (any executable can be a plugin).

### Reliability (Priority 3)
- `set -euo pipefail` in `doc.doc.sh` and plugin process scripts.
- Input validation before processing begins.
- Plugin failures produce stderr warnings; processing continues with remaining plugins.
- `file` plugin always runs first to ensure MIME data is available for dependent plugins.
- MIME filter gate prevents unnecessary processing of files that do not match type criteria.

### Maintainability (Priority 4)
- Bash orchestration (`doc.doc.sh`) delegates complex logic to Python (`filter.py`).
- Component scripts (`plugins.sh`, `help.sh`, etc.) have single responsibilities.
- Arc42 architecture documentation kept in sync with implementation.
- All plugin contracts documented in `descriptor.json` files.

### Compatibility (Priority 5)
- `stat` plugin uses `uname -s` to select Linux vs. macOS `stat` flags.
- `file --mime-type -b` flags work on both Linux and macOS.
- Python standard library only — no third-party packages for core logic.
- Markdown output compatible with Obsidian.

## Design Principles

1. **Unix Philosophy** — Do one thing well; compose through pipelines.
2. **Convention over Configuration** — Sensible defaults; minimal required options.
3. **Fail Fast** — Validate inputs early; provide clear error messages.
4. **Progressive Enhancement** — Core processing is simple; plugins add capabilities.
5. **Explicit over Implicit** — Clear command structure; plugin dependencies derived from declared types, not hidden conventions.
6. **Separation of Concerns** — Orchestration (Bash), filtering (Python), processing (plugins), and output (templates) are cleanly separated.
