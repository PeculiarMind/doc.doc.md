# Introduction and Goals

## Requirements Overview

doc.doc.md is a command-line tool for processing document collections within directory structures. It generates markdown-formatted documentation files compatible with Obsidian and other markdown-based tools.

### Implemented Features

- **Document Processing**: Process files from an input directory through an active plugin chain; stream structured JSON results to stdout (directory mirroring to output not yet implemented — see [Section 11](../11_risks_and_technical_debt/11_risks_and_technical_debt.md)).
- **Flexible Filtering**: Include/exclude logic supporting file extensions, glob patterns, and MIME types with OR-within-parameter / AND-between-parameters semantics. MIME filtering is implemented via a two-pass mechanism: path criteria applied by `filter.py`; MIME criteria applied via a dedicated MIME filter gate after the `file` plugin runs.
- **Plugin Architecture**: Extensible plugin system. Plugins are self-contained directories with a `descriptor.json` and shell-invocable entry points communicating via JSON stdin/stdout. Implemented plugins: `file`, `stat`, `ocrmypdf`.
- **Plugin Management CLI**: `list`, `activate`, `deactivate`, `install`, `installed`, and `tree` commands are fully implemented.
- **Template System**: Variable-substitution-based markdown templates (initial Bash implementation).
- **User-Friendly CLI**: Comprehensive help system; both long and short parameter forms; clear error messages.

### Requirements Traceability

| Requirement | Description | Status |
|------------|-------------|--------|
| REQ_0001 | Command-Line Tool | ✅ Implemented |
| REQ_0002 | Modular and Extensible Architecture | ✅ Implemented |
| REQ_0003 | Plugin-Based Architecture | ✅ Implemented |
| REQ_0004 | Documentation and Help System | ✅ Implemented |
| REQ_0006 | User-Friendly Interface | ✅ Implemented |
| REQ_0007 | Markdown Output Format | ✅ Implemented (JSON streaming; template engine present) |
| REQ_0008 | Obsidian Compatibility | ✅ Implemented |
| REQ_0009 | Process Command with complex filtering | ✅ Implemented |
| REQ_0013 | Directory Structure Mirroring | ⚠️ Pre-condition met; `-o` flag not yet implemented |
| REQ_0021 | List Plugins Command | ✅ Implemented |
| REQ_0024 | Activate Plugin Command | ✅ Implemented |
| REQ_0025 | Deactivate Plugin Command | ✅ Implemented |
| REQ_0026 | Install Plugin Command | ✅ Implemented |
| REQ_0027 | Check Plugin Installation Command | ✅ Implemented |
| REQ_0028 | Plugin Tree View Command | ✅ Implemented |
| REQ_SEC_001 | Input Validation and Sanitization | ✅ Implemented |
| REQ_SEC_004 | Template Injection Prevention | ⏳ Pending (template engine not yet released) |
| REQ_SEC_005 | Path Traversal Prevention | ✅ Implemented |
| REQ_SEC_007 | Plugin Security Documentation | ✅ Implemented |

All accepted requirements are documented in `project_management/02_project_vision/02_requirements/03_accepted/`.

## Quality Goals

| Priority | Quality Goal | Description |
|----------|-------------|-------------|
| 1 | **Usability** | Intuitive CLI targeting home users. Clear error messages, comprehensive help, sensible defaults. |
| 2 | **Flexibility** | Plugin-based architecture enabling extension without core modification. Complex filtering for diverse use cases. |
| 3 | **Reliability** | Robust error handling, graceful degradation, predictable behavior. Proven tools reused to minimize defects. |
| 4 | **Maintainability** | Clear separation of concerns (Bash orchestration / Python filter logic), well-documented architecture, minimal dependencies. |
| 5 | **Compatibility** | Linux and macOS support; standard markdown output compatible with Obsidian and similar tools. |

## Stakeholders

| Role | Expectations |
|------|--------------|
| **Home Users** | Simple, intuitive tool for managing personal document collections. |
| **Home-Lab Enthusiasts** | Flexible, extensible tool that integrates into personal workflows. |
| **Plugin Developers** | Clear plugin interface, JSON descriptor schema, and developer documentation. |
| **Maintainers** | Clean architecture, minimal dependencies, easy to understand and extend. |
