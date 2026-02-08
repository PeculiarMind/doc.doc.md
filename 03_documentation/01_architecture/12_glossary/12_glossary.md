# 12. Glossary (Implementation)

**Status**: Living Document  
**Last Updated**: 2026-02-08  
**Vision Reference**: [Glossary](../../../01_vision/03_architecture/12_glossary/12_glossary.md)

## Table of Contents

- [Purpose](#purpose)
- [Terms (Alphabetical)](#terms-alphabetical)
- [Acronyms and Abbreviations](#acronyms-and-abbreviations)
- [Implementation-Specific Terms](#implementation-specific-terms)
- [Cross-References](#cross-references)
- [Maintenance](#maintenance)
- [Contributing New Terms](#contributing-new-terms)

## Purpose

This glossary defines key terms and concepts used in the doc.doc implementation documentation. It complements the vision glossary by adding implementation-specific terms.

---

## Terms (Alphabetical)

### Active Plugin
A plugin with `"active": true` in its descriptor. Active plugins are executed during analysis; inactive plugins are discovered but not executed.

### ADR (Architecture Decision Record)
A document capturing a significant architectural decision, its context, alternatives considered, and rationale. See [Architecture Decisions](../09_architecture_decisions/09_architecture_decisions.md).

### Arc42
A template for software architecture documentation with 12 standardized sections used throughout this documentation.

### Atomic Write
A file write operation that appears instantaneous using the pattern: write to temp file → validate → atomic rename. Prevents partial writes and corruption.

### Bash Strict Mode
Bash configuration (`set -euo pipefail`) that exits on unset variables, command failures, and pipeline errors. See ADR-0019.

---

### Building Block
A component or module with clearly defined responsibilities and interfaces (e.g., Plugin Manager, File Scanner, Execution Orchestrator).

---

### CLI (Command-Line Interface)
The text-based interface for interacting with doc.doc via arguments and flags. See [CLI Concept](../08_concepts/08_0003_cli_interface_concept.md).

### Consumer (`consumes`)
A plugin descriptor field declaring what data a plugin requires to execute (e.g., `file_path_absolute`, `file_size`).

### Cron Job
A scheduled task on Unix-like systems that executes commands at specified intervals. Doc.doc is designed to run unattended via cron.

---

### Data-Driven Execution
An orchestration approach where plugin execution order emerges automatically from analyzing data dependencies (`consumes`/`provides`).

### Dependency Graph
A directed graph showing data dependencies between plugins. Used to determine execution order via topological sort.

### Descriptor (Plugin Descriptor)
A JSON file (`descriptor.json`) defining a plugin's metadata, capabilities, dependencies, and execution commands.

---

### Entry Point Guard
A Bash pattern (`if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi`) that prevents `main()` execution when script is sourced, enabling unit testing. See ADR-0020.

### Exit Code
A numeric value returned by a command: 0 = success, 1-5 = specific error categories. See ADR-0008.

**Doc.doc Exit Codes**:
- `0` - Success
- `1` - Invalid arguments
- `2` - File/directory error
- `3` - Plugin execution error
- `4` - Report generation error
- `5` - Workspace error

---

### Feature ID
An identifier for implemented features (e.g., `feature_0001`, `feature_0003`) used to track implementation progress and cross-reference documentation.

---

### Hash (File Hash)
SHA-256 hash of a file's absolute path, used as the workspace filename (e.g., `/path/to/file.pdf` → `abc123def456.json`).

---

### Incremental Analysis
Processing only files that changed since the last scan, based on workspace timestamps. Improves performance for repeated analyses.

---

### JQ
A command-line JSON processor used for parsing plugin descriptors and workspace files. Doc.doc falls back to python3 if jq is unavailable (ADR-0011).

### JSON (JavaScript Object Notation)
Text-based data format used for plugin descriptors and workspace files. Human-readable and widely supported.

---

### Lock File
A temporary file (e.g., `file.json.lock`) preventing concurrent writes to the same workspace file, ensuring data consistency.

### Log Level
Severity classification for log messages: DEBUG, INFO, WARN, ERROR. DEBUG/INFO require verbose mode (`-v`); WARN/ERROR always show. See ADR-0017.

---

### Markdown
Lightweight markup language used for templates and generated reports. Readable as plain text, renders as formatted documents.

### MIME Type
A standard identifier for file types (e.g., `application/pdf`, `text/plain`). Determined using the `file` command.

### Modular Function Architecture
Design pattern organizing code into focused, single-responsibility functions for improved testability and maintainability. See ADR-0007.

---

### NAS (Network Attached Storage)
A file storage device connected to a network (e.g., Synology, QNAP). A primary deployment target for doc.doc.

---

### OCR (Optical Character Recognition)
Text extraction from images or scanned documents. Example plugin: `ocrmypdf`.

### Orchestrator (Execution Orchestrator)
The component coordinating plugin execution based on data dependencies and managing the overall analysis workflow.

---

### Pipe-Delimited Format
Internal data format using pipes as separators (e.g., `"name|description|active|available"`). Bash-native, no parsing dependencies needed. See ADR-0010.

### Platform
The operating system or distribution detected by `detect_platform()` (e.g., "ubuntu", "darwin", "generic"). Determines which plugin directories to scan.

### Platform-Specific Plugin
A plugin in `plugins/{platform}/` that overrides cross-platform plugins with the same name. See ADR-0012.

### Plugin
A self-contained module wrapping a CLI tool, defined by a descriptor.json file. Extends doc.doc's capabilities without core code changes.

### Plugin Manager
The component discovering, loading, validating, and providing metadata about available plugins. See [Plugin Concept](../08_concepts/08_0001_plugin_concept.md).

### POSIX (Portable Operating System Interface)
Unix compatibility standards followed by doc.doc for portability across operating systems.

### Provider (`provides`)
A plugin descriptor field declaring what data a plugin produces (e.g., `file_size`, `content.text`).

---

### Report Generator
The component merging workspace data with Markdown templates to produce human-readable reports. (Not yet implemented)

---

### Source Directory
The directory containing files to analyze, specified via `-d` argument.

### Stderr (Standard Error)
Output stream for diagnostic messages (logs, errors). Doc.doc routes all diagnostic information to stderr, keeping stdout clean for data.

### Stdout (Standard Output)
Output stream for data and results (help text, plugin list, reports). Diagnostic messages go to stderr.

---

### Target Directory
The directory where generated Markdown reports are written, specified via `-t` argument. (Not yet functional)

### Template
A Markdown file with variable placeholders (e.g., `{{file_path}}`) defining report structure. (Not yet implemented)

### Topological Sort
An algorithm ordering a directed acyclic graph so dependencies execute before dependents. Used to determine plugin execution order.

---

### Vision
The planned architecture and design intent documented in `01_vision/03_architecture/`. Contrasts with implementation documentation (this directory).

---

### Workspace
A directory containing JSON files persisting analysis metadata, state, and plugin results. Enables incremental analysis and external tool integration. See [Workspace Concept](../08_concepts/08_0002_workspace_concept.md).

**Status**: Designed but not yet implemented.

---

## Acronyms and Abbreviations

| Abbreviation | Full Term | Description |
|--------------|-----------|-------------|
| **ADR** | Architecture Decision Record | Documentation of architectural decisions |
| **API** | Application Programming Interface | Not applicable (Bash script, not a library) |
| **BSD** | Berkeley Software Distribution | Unix variant (different CLI tool flags than GNU) |
| **CD** | Continuous Deployment | Automated deployment pipeline |
| **CI** | Continuous Integration | Automated testing and building |
| **CLI** | Command-Line Interface | Text-based user interface |
| **CPU** | Central Processing Unit | Processor hardware |
| **DAG** | Directed Acyclic Graph | Graph structure for dependency management |
| **FSF** | Free Software Foundation | Organization promoting free software |
| **GNU** | GNU's Not Unix | Free software project providing Unix-like tools |
| **I/O** | Input/Output | Data transfer operations |
| **JSON** | JavaScript Object Notation | Data interchange format |
| **MB** | Megabyte | Unit of data size (1,048,576 bytes) |
| **MIME** | Multipurpose Internet Mail Extensions | File type identification standard |
| **NAS** | Network Attached Storage | Network file storage device |
| **OCR** | Optical Character Recognition | Text extraction from images |
| **OS** | Operating System | System software (Linux, macOS, etc.) |
| **PID** | Process ID | Unique identifier for running processes |
| **POSIX** | Portable Operating System Interface | Unix compatibility standard |
| **RAM** | Random Access Memory | Computer memory |
| **SHA** | Secure Hash Algorithm | Cryptographic hash function |
| **TDD** | Test-Driven Development | Write tests before implementation |
| **WSL** | Windows Subsystem for Linux | Linux compatibility on Windows |

---

## Implementation-Specific Terms

### Feature Implementation Status Indicators

| Indicator | Meaning |
|-----------|---------|
| ✅ | Fully implemented and tested |
| 🚧 | Partially implemented, work in progress |
| ⏳ | Planned but not started |
| 📋 | Designed but not implemented |
| ❌ | Not planned or rejected |

---

### Version Numbering (Semantic Versioning)

**Format**: `MAJOR.MINOR.PATCH` (e.g., `1.0.0`)

- **MAJOR**: Incompatible API changes
- **MINOR**: Backward-compatible functionality additions
- **PATCH**: Backward-compatible bug fixes

---

### Test Types

| Type | Description |
|------|-------------|
| **Unit Test** | Tests individual functions in isolation |
| **Integration Test** | Tests component interactions |
| **System Test** | Tests complete user workflows |

---

## Cross-References

- **Vision Glossary**: [01_vision/03_architecture/12_glossary/12_glossary.md](../../../01_vision/03_architecture/12_glossary/12_glossary.md)
- **Architecture Decisions**: [09_architecture_decisions/](../09_architecture_decisions/)
- **Concepts**: [08_concepts/](../08_concepts/)
- **Building Blocks**: [05_building_block_view/](../05_building_block_view/)

---

## Maintenance

This glossary is a **living document** that evolves with the implementation:

- Add terms as new features are implemented
- Update definitions when implementation details change
- Remove obsolete terms when features are refactored
- Keep synchronized with vision glossary

**Last Major Update**: 2026-02-08 (Architecture synchronization)

---

## Contributing New Terms

When adding new terms:
1. Place in alphabetical order
2. Use bold for the term name
3. Provide clear, concise definition
4. Link to relevant documentation
5. Include examples if helpful
6. Mark implementation status if applicable

---

**Note**: This glossary reflects the current implementation state. Some terms describe planned features (marked ⏳ or 📋). Vision glossary contains additional conceptual terms not yet implemented.
