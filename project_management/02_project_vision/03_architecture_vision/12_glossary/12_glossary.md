# Glossary

## Domain Terms

| Term | Definition |
|------|------------|
| **Document Processing** | The act of transforming input documents into structured markdown output files. |
| **Filter Criteria** | Conditions used to determine which files should be processed (file extensions, glob patterns, MIME types). |
| **Glob Pattern** | A pattern-matching syntax using wildcards (e.g., `*.txt`, `**/2024/**`) to match file paths. |
| **MIME Type** | Multipurpose Internet Mail Extensions type; a standard way of classifying file types (e.g., `application/pdf`, `text/plain`). |
| **Template** | A markdown file with placeholder variables that get replaced with file-specific data during processing. |
| **Directory Mirroring** | Preserving the directory structure from input to output; files maintain their relative paths. |

## System Components

| Term | Definition |
|------|------------|
| **doc.doc.sh** | Main entry point script; command-line interface for the system. |
| **Filter Engine** | Python component that evaluates include/exclude criteria to determine which files should be processed. |
| **Plugin** | An independent, installable component that extends the system's document processing capabilities. |
| **Plugin Descriptor** | JSON file (`descriptor.json`) containing metadata about a plugin (name, version, dependencies, entry point). |
| **Template Engine** | Component responsible for replacing template variables with actual data to generate output markdown. |

## Plugin System

| Term | Definition |
|------|------------|
| **Active Plugin** | A plugin that is available and enabled for use during document processing. |
| **Inactive Plugin** | A plugin that exists but is disabled and will not be used during processing. |
| **Installed Plugin** | A plugin that has completed its installation process and has all dependencies met. |
| **Available Plugin** | A plugin whose descriptor exists in the plugin directory, regardless of installation state. |
| **Plugin Dependency** | A requirement specified by a plugin; another plugin or system utility that must be present for the plugin to function. |
| **Plugin Chain** | The ordered sequence of plugins executed for each file during processing. |
| **Entry Point** | The script (typically `main.sh`) that serves as the executable for a plugin. |

## Filter Logic

| Term | Definition |
|------|------------|
| **Include Filter** | Criteria specifying which files should be processed; files must match to be included. |
| **Exclude Filter** | Criteria specifying which files should not be processed; files matching are excluded. |
| **OR Logic** | Boolean operation where a file matches if it satisfies at least one criterion (within a single parameter). |
| **AND Logic** | Boolean operation where a file must match all criteria (between multiple parameters). |
| **Filter Parameter** | A single `--include` or `--exclude` option provided on the command line. |

## Architecture Terms

| Term | Definition |
|------|------------|
| **Orchestration Layer** | The Bash-based component responsible for coordinating workflow execution and component interaction. |
| **Processing Pipeline** | The flow of data from file discovery through filtering, plugin execution, and template generation. |
| **Component** | A modular script (e.g., `help.sh`, `logging.sh`) that provides specific functionality. |
| **POSIX Compliance** | Adherence to the Portable Operating System Interface standards for shell scripts and utilities. |

## File System Terms

| Term | Definition |
|------|------------|
| **Input Directory** | The source directory containing documents to be processed. |
| **Output Directory** | The destination directory where generated markdown files are written. |
| **Working Directory** | The current directory from which the tool is executed (not necessarily the input directory). |
| **Absolute Path** | A complete path from the filesystem root (e.g., `/home/user/documents/file.pdf`). |
| **Relative Path** | A path relative to some reference point, typically the current working directory or input directory (e.g., `docs/file.pdf`). |

## Output Formats

| Term | Definition |
|------|------------|
| **Markdown** | Lightweight markup language used for formatting text; the output format of this system. |
| **Obsidian** | A popular markdown-based knowledge management application; target compatibility for generated markdown. |
| **Template Variable** | A placeholder in a template file (e.g., `{{file_name}}`) that gets replaced with actual data. |

## Quality Attributes

| Term | Definition |
|------|------------|
| **Extensibility** | The ease with which new functionality can be added to the system (via plugins). |
| **Modularity** | The degree to which system components are separated and can be developed/tested independently. |
| **Portability** | The ability of the system to run on different platforms (Linux, macOS, etc.). |
| **Maintainability** | The ease with which the system can be modified, debugged, and understood. |
| **Usability** | The ease with which users can learn and effectively use the system. |

## Command-Line Interface

| Term | Definition |
|------|------------|
| **Command** | The action to perform (e.g., `process`, `list`, `activate`). |
| **Parameter** | An option provided to a command to configure its behavior. |
| **Long Form** | Descriptive parameter name preceded by `--` (e.g., `--input-directory`). |
| **Short Form** | Abbreviated parameter name preceded by `-` (e.g., `-d`). |
| **Required Parameter** | A parameter that must be provided for a command to execute. |
| **Optional Parameter** | A parameter that has a default value and can be omitted. |

## Development Terms

| Term | Definition |
|------|------------|
| **Arc42** | A template for architecture documentation; the structure used for this project's architecture docs. |
| **ADR (Architecture Decision Record)** | A document capturing an important architectural decision and its context. |
| **Technical Debt** | Code or design shortcuts that may need to be addressed in the future. |
| **Accepted Trade-off** | A conscious decision to choose one approach over another, accepting its limitations. |

## Acronyms

| Acronym | Full Form |
|---------|-----------|
| **CLI** | Command-Line Interface |
| **MIME** | Multipurpose Internet Mail Extensions |
| **POSIX** | Portable Operating System Interface |
| **ADR** | Architecture Decision Record |
| **JSON** | JavaScript Object Notation |
| **WSL** | Windows Subsystem for Linux |
| **TDD** | Test-Driven Development |
| **MVP** | Minimum Viable Product |
