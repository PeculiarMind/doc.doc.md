# Glossary

## Domain Terms

| Term | Definition |
|------|------------|
| **Document Processing** | Transforming input documents into structured JSON output (and, in future, markdown files) by running them through the active plugin chain. |
| **Filter Criteria** | Conditions used to select which files enter the processing pipeline: file extensions (`.pdf`), glob patterns (`**/2024/**`), or MIME types (`image/*`). |
| **Glob Pattern** | A wildcard path-matching syntax (e.g., `*.txt`, `**/2024/**`) matched using Python `fnmatch`. |
| **MIME Type** | Multipurpose Internet Mail Extensions type; a standard file type identifier (e.g., `application/pdf`, `text/plain`). Detected by the `file` plugin using the `file --mime-type -b` command. |
| **Template** | A markdown file containing `{{variable}}` placeholders that are replaced with file-specific data during output generation. |
| **Directory Mirroring** | Preserving the directory structure from input to output so files maintain their relative paths. Planned but not yet implemented. |

## System Components

| Term | Definition |
|------|------------|
| **doc.doc.sh** | Main Bash entry point; CLI interface; command routing; MIME criterion classification; file-first plugin chain enforcement; MIME filter gate. |
| **filter.py** | Python filter engine; evaluates include/exclude criteria using `fnmatch`; stateless and general-purpose — used for both path filtering and MIME gate evaluation. |
| **plugins.sh** | Bash component for plugin discovery, invocation, activation, and dependency tree rendering. |
| **templates.sh** | Bash component for template loading and `{{variable}}` substitution. |
| **Plugin Descriptor** | `descriptor.json` — JSON file declaring plugin metadata, command schemas, and parameter types. |

## Plugin System

| Term | Definition |
|------|------------|
| **Active Plugin** | A plugin with `"active": true` in its `descriptor.json`; included in the processing chain. Absent or `null` `active` field defaults to `true`. |
| **Inactive Plugin** | A plugin with `"active": false`; discovered but excluded from processing. |
| **Installed Plugin** | A plugin whose `installed.sh` exits with code 0; all system dependencies are present. |
| **Plugin Chain** | The ordered sequence of active plugins executed for each file; `file` plugin is always first. |
| **Process Command** | The `process` entry in a plugin's `commands` object; its `main.sh` extracts data from a file and returns JSON. |
| **Install Command** | The `install` entry; `install.sh` installs any required system dependencies. |
| **Installed Command** | The `installed` entry; `installed.sh` checks whether dependencies are met (exit 0 = ready). |
| **JSON stdin/stdout Communication** | Plugin invocation pattern: parameters sent as JSON object on stdin; results returned as JSON object on stdout. Provides type preservation and eliminates environment variable injection risks. |
| **Type-Based Dependency Resolution** | Plugin execution order derived by matching output parameter names of earlier plugins to required input parameter names of later plugins. No explicit `dependencies` attribute permitted. |

## Filter Logic

| Term | Definition |
|------|------------|
| **Include Filter** | `--include` / `-i` criteria; a file must satisfy at least one criterion from each `--include` argument to be processed. |
| **Exclude Filter** | `--exclude` / `-e` criteria; a file is excluded only if it matches at least one criterion from each `--exclude` argument. |
| **OR Logic** | Within a single `--include` or `--exclude` parameter: comma-separated values are ORed — a file matches if it satisfies any one of them. |
| **AND Logic** | Between multiple `--include` or `--exclude` parameters: all parameters must match — a file must satisfy at least one criterion from each. |
| **Path Criterion** | A criterion containing no `/`, or containing `**` (e.g., `.pdf`, `**/2024/**`). Evaluated by `filter.py` during file discovery. |
| **MIME Criterion** | A criterion containing `/` but not `**` (e.g., `application/pdf`, `image/*`). Evaluated by the MIME filter gate after the `file` plugin runs. |
| **MIME Filter Gate** | A second filter pass in `doc.doc.sh`: after the `file` plugin returns a `mimeType`, the MIME string is piped to `filter.py` with MIME criteria; files failing this gate are skipped. |

## Architecture Terms

| Term | Definition |
|------|------------|
| **Orchestration Layer** | The Bash layer (`doc.doc.sh` + component scripts) responsible for coordinating workflow, invoking the filter engine, and managing the plugin chain. |
| **Processing Pipeline** | The end-to-end flow: file discovery → path filtering → plugin chain → MIME gate → output. |
| **Component** | A modular Bash script (`plugins.sh`, `help.sh`, `logging.sh`, `templates.sh`) sourced by `doc.doc.sh`. |
| **POSIX Compliance** | Adherence to Portable Operating System Interface standards in shell scripts; ensures cross-platform compatibility. |
| **File-First Enforcement** | The guarantee that the `file` plugin always executes at position 0 in the plugin chain, regardless of discovery order. Implemented in `doc.doc.sh` post-discovery. |

## Parameter and Variable Naming

| Term | Definition |
|------|------------|
| **lowerCamelCase** | Naming convention where the first word is lowercase and subsequent words are capitalized (e.g., `filePath`, `mimeType`, `fileSizeHuman`). Required for all plugin input/output parameter names and template variables. |
| **Template Variable** | A placeholder in a template file of the form `{{variableName}}` (lowerCamelCase) replaced with plugin output data. |
| **Plugin Input Parameter** | A named, typed value passed to a plugin via JSON stdin; declared in the plugin's `descriptor.json` `commands.<cmd>.input` object. |
| **Plugin Output Variable** | A named, typed value returned by a plugin via JSON stdout; declared in `descriptor.json` `commands.<cmd>.output` object. |

## File System Terms

| Term | Definition |
|------|------------|
| **Input Directory** | The source directory containing documents to process; specified via `-d`. |
| **Output Directory** | The destination for generated files; specified via `-o` (not yet implemented). |
| **Plugin Directory** | `<app_dir>/doc.doc.md/plugins/`; contains one subdirectory per plugin. |

## Development Terms

| Term | Definition |
|------|------------|
| **Arc42** | A structured template for software architecture documentation. This project uses Arc42 for all architecture docs. |
| **ADR** | Architecture Decision Record — captures a significant architectural decision, its context, alternatives, and rationale. |
| **IDR** | Implementation Decision Record — captures a significant decision made during implementation (not vision). |
| **DEBTR** | Debt Record — tracks a known technical debt item for future remediation. |
| **ARCHREV** | Architecture Review — documents a post-implementation review of a feature or bug fix against the architecture vision. |
| **Technical Debt** | Shortcuts or incomplete implementations accepted now, to be addressed in future releases. |

## Acronyms

| Acronym | Full Form |
|---------|-----------|
| CLI | Command-Line Interface |
| MIME | Multipurpose Internet Mail Extensions |
| POSIX | Portable Operating System Interface |
| ADR | Architecture Decision Record |
| IDR | Implementation Decision Record |
| JSON | JavaScript Object Notation |
| WSL | Windows Subsystem for Linux |
| MVP | Minimum Viable Product |
