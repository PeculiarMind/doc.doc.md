# Architecture Concepts

Cross-cutting concepts that shape the architecture of doc.doc.md. Each concept is documented in detail in the corresponding ARC document in `project_management/02_project_vision/03_architecture_vision/08_concepts/`.

## Concept Index

| ID | Concept | Status | Summary |
|----|---------|--------|---------|
| [ARC-0001](../../../project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_0001_filtering_logic.md) | **Filtering Logic** | Accepted | Two-pass filtering: path/extension/glob criteria evaluated by `filter.py`; MIME criteria evaluated via MIME filter gate after `file` plugin runs. OR within parameter, AND between parameters. |
| [ARC-0002](../../../project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_0002_template_processing.md) | **Template Processing** | Proposed | Markdown templates with `{{variable}}` placeholders; resolved in user → custom → built-in order; variables populated from plugin outputs. |
| [ARC-0003](../../../project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md) | **Plugin Architecture** | Accepted | Self-contained plugin directories; `descriptor.json` schema; JSON stdin/stdout communication; lowerCamelCase parameter names; three required commands (`process`, `install`, `installed`). |
| [ARC-0004](../../../project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_0004_error_handling.md) | **Error Handling** | Proposed | Five error categories with defined response strategies; structured exit codes (0–4); graceful degradation for plugin/file failures; `--verbose` for diagnostics. |
| [ARC-0005](../../../project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_0005_logging_and_progress.md) | **Logging and Progress** | Proposed | Four log levels (ERROR/WARN/INFO/DEBUG); progress indication; summary statistics; verbosity controlled via `--quiet`/`--verbose`. |
| [ARC-0006](../../../project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_0006_security_considerations.md) | **Security Considerations** | Proposed | Input validation; path sanitization; plugin name validation; JSON-based plugin communication eliminates environment variable injection; plugin sandboxing planned for future. |

## Concept Summaries

### ARC-0001: Filtering Logic

Filtering operates in two passes:

**Pass 1 — Path filtering** (`filter.py`):
- Criteria without `/` (or with `**`) are path/extension/glob criteria.
- `filter.py` receives file paths from `find` via stdin.
- Extension criteria: `criterion.startswith('.')` → `value.endswith(criterion)`.
- Glob criteria: `fnmatch.fnmatch(value, criterion)`.
- OR within a single `--include`/`--exclude` parameter; AND between multiple parameters.

**Pass 2 — MIME filter gate** (`doc.doc.sh` + `filter.py`):
- Criteria containing `/` but not `**` are MIME criteria; classified in `doc.doc.sh` before the processing loop.
- After the `file` plugin runs for each file, `doc.doc.sh` pipes the detected `mimeType` string to `filter.py` with the MIME criteria.
- `filter.py` is stateless: it applies `fnmatch` to the MIME string exactly as it does to file paths. Handles both exact types (`text/plain`) and wildcards (`image/*`).
- Files failing the MIME gate produce no output and are skipped.

### ARC-0002: Template Processing

Templates are markdown files containing `{{variableName}}` placeholders. The template engine (`templates.sh`) collects all plugin output variables into a dictionary and performs string substitution. Variables follow lowerCamelCase naming (e.g., `{{filePath}}`, `{{mimeType}}`, `{{fileSize}}`). Missing variables are left as empty or logged as warnings.

### ARC-0003: Plugin Architecture

Every plugin is a self-contained directory with:
- `descriptor.json`: declares `name`, `version`, `description`, `active`, and `commands` (with typed input/output schemas).
- `main.sh`: entry point for the `process` command.
- `install.sh`: entry point for the `install` command.
- `installed.sh`: entry point for the `installed` command.

Plugins communicate exclusively via JSON stdin (input) and stdout (output). All parameter names use lowerCamelCase. Process isolation is guaranteed — each invocation is a separate shell process.

Plugin execution order is derived from parameter type matching: a plugin that requires an input named `mimeType` depends on any plugin that declares `mimeType` in its output. The `file` plugin is always positioned first by `doc.doc.sh`.

### ARC-0004: Error Handling

| Category | Examples | Response |
|----------|----------|----------|
| User Input | Invalid directory, bad filter pattern | Error to stderr; hint; exit 1 |
| Configuration | Missing template, invalid descriptor | Error to stderr; suggest fix; exit 2 |
| Plugin | Crash, missing dependency | Warning; skip plugin; continue |
| File Processing | Permission denied, unreadable file | Warning; skip file; continue |
| System | Disk full | Critical error; exit 3 |

Exit codes: 0 = success, 1 = user input error, 2 = configuration error, 3 = system error, 4 = partial success.

### ARC-0005: Logging and Progress

Log levels: ERROR → stderr (red), WARN → stderr (yellow), INFO → stderr (default), DEBUG → stderr (verbose). Data output always goes to stdout. Progress indication writes to stderr only when connected to a terminal. Summary statistics shown at completion.

### ARC-0006: Security Considerations

- File paths validated and canonicalized before use.
- Plugin names validated against `[a-zA-Z0-9_-]+` pattern.
- JSON stdin/stdout for plugin communication avoids environment variable injection, size limits, and cross-process visibility.
- Output paths sanitized to prevent overwriting system files.
- Plugin sandboxing (filesystem restrictions, resource limits) is planned for a future version.

## Concept Relationships

```
ARC-0001 (Filtering) ──► determines which files enter the pipeline
ARC-0003 (Plugin Architecture) ──► defines how data is collected per file
ARC-0002 (Template Processing) ──► uses plugin outputs to generate markdown
ARC-0004 (Error Handling) ──► applied in all three above
ARC-0005 (Logging) ──► provides visibility into all operations
ARC-0006 (Security) ──► constrains input/output handling across all concepts
```
