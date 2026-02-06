---
title: Glossary
arc42-chapter: 12
---

# 12. Glossary

This glossary defines key terms and concepts used throughout the doc.doc architecture documentation.

## A

### Analysis
The process of extracting metadata and content insights from files using plugins and CLI tools.

### Arc42
A template for documenting software architecture, structured into 12 chapters covering all aspects of system design.

### Atomic Write
A file write operation that appears instantaneous and complete, implemented via write-to-temp-then-rename pattern to prevent partial writes or corruption.

## B

### Bash
Bourne Again SHell, the command-line interpreter used to implement the doc.doc toolkit. Required version: 4.0 or later.

### Building Block
A component or module of the system with clearly defined responsibilities and interfaces (e.g., Plugin Manager, File Scanner).

## C

### CLI (Command-Line Interface)
The text-based interface through which users interact with doc.doc, using flags and arguments to control behavior.

### CLI Tool
An external command-line utility that performs specialized analysis (e.g., `stat`, `file`, `jq`, OCR tools). Plugins orchestrate these tools.

### Consumes
A plugin descriptor field declaring what data the plugin requires to execute (e.g., `file_path_absolute`, `mime_type`).

### Cron Job
A scheduled task on Unix-like systems that executes commands at specified intervals (e.g., daily, weekly).

## D

### Data-Driven Execution
An orchestration approach where plugin execution order emerges from analyzing data dependencies rather than explicit configuration.

### Dependency Graph
A directed graph showing relationships between plugins based on what data they consume and provide. Used to determine execution order.

### Descriptor
A JSON file (`descriptor.json`) that defines a plugin's metadata, capabilities, dependencies, and execution commands.

## E

### Entry Point
The main script (`doc.doc.sh`) that users execute to start analysis.

### Exit Code
A numeric value returned by a command indicating success (0) or failure (non-zero). Used for error handling and scripting.

## F

### File Scanner
A component that recursively traverses directories to discover files for analysis.

### Filter
In the context of Unix pipes and filters pattern, a component that transforms input data to output data (e.g., a plugin processing a file).

## I

### Incremental Analysis
The ability to skip analyzing files that haven't changed since the last scan, based on timestamps in the workspace.

## J

### JSON (JavaScript Object Notation)
A text-based data format used for plugin descriptors and workspace files. Human-readable and widely supported.

### jq
A command-line JSON processor used for parsing, filtering, and transforming JSON data.

## L

### Lock File
A temporary file (e.g., `file.json.lock`) used to prevent concurrent writes to the same workspace file, ensuring data consistency.

## M

### Markdown
A lightweight markup language used for templates and generated reports. Easy to read and write, widely supported.

### MIME Type
A standard identifier for file types (e.g., `application/pdf`, `text/plain`). Determined using the `file` command.

## N

### NAS (Network Attached Storage)
A file storage device connected to a network (e.g., Synology, QNAP) commonly used as a deployment target for doc.doc.

## O

### Orchestrator
The component responsible for coordinating plugin execution based on data dependencies and managing the overall analysis workflow.

## P

### Plugin
A self-contained module that wraps a CLI tool, declaring its dependencies and outputs via a descriptor file. Plugins extend doc.doc's analysis capabilities.

### Plugin Manager
The component that discovers, loads, validates, and provides metadata about available plugins.

### POSIX (Portable Operating System Interface)
A family of standards for maintaining compatibility between operating systems. Doc.doc follows POSIX conventions where possible for portability.

### Provides
A plugin descriptor field declaring what data the plugin produces (e.g., `file_size`, `content.text`).

## R

### Report Generator
The component that merges workspace data with Markdown templates to produce human-readable reports.

### Recursive Scanning
The process of traversing a directory and all its subdirectories to discover files.

## S

### Source Directory
The directory containing files to be analyzed, specified via the `-d` argument.

### State Persistence
Storing analysis results across multiple runs to enable incremental analysis and recovery from interruptions.

## T

### Target Directory
The directory where generated Markdown reports are written, specified via the `-t` argument.

### Template
A Markdown file with variable placeholders (e.g., `{{file_path}}`) that defines the structure of generated reports.

### Topological Sort
An algorithm that orders a directed acyclic graph so that for every edge from node A to node B, A comes before B. Used to determine plugin execution order.

## U

### Unix Philosophy
A set of design principles emphasizing small, modular, composable tools that do one thing well. Doc.doc follows this philosophy.

## V

### Variable Substitution
The process of replacing placeholders in templates (e.g., `{{variable_name}}`) with actual values from workspace data.

## W

### Workspace
A directory containing JSON files that persist analysis results, metadata, and state information. Enables incremental analysis and external tool integration.

### Workspace Data
The structured information stored in workspace JSON files, including file metadata, analysis results, and plugin execution history.

### WSL (Windows Subsystem for Linux)
A compatibility layer for running Linux binary executables natively on Windows. Doc.doc can run in WSL environments.

## Acronyms and Abbreviations

| Abbreviation | Full Term | Description |
|--------------|-----------|-------------|
| **ADR** | Architecture Decision Record | Documentation of significant architectural decisions |
| **AJAX** | Asynchronous JavaScript and XML | Not used in doc.doc (no web interface) |
| **API** | Application Programming Interface | Not applicable (bash script, not a library) |
| **BSD** | Berkeley Software Distribution | Unix variant with different CLI tool flags than GNU |
| **CD** | Continuous Deployment | Automated deployment pipeline |
| **CI** | Continuous Integration | Automated testing and building |
| **CLI** | Command-Line Interface | Text-based user interface |
| **CPU** | Central Processing Unit | Processor hardware |
| **DAG** | Directed Acyclic Graph | Graph structure used for dependency management |
| **DFS** | Depth-First Search | Graph traversal algorithm |
| **GNU** | GNU's Not Unix | Free software project providing Unix-like tools |
| **I/O** | Input/Output | Data transfer operations |
| **JSON** | JavaScript Object Notation | Data interchange format |
| **MB** | Megabyte | Unit of data size (1,048,576 bytes) |
| **MIME** | Multipurpose Internet Mail Extensions | Standard for file type identification |
| **NAS** | Network Attached Storage | Network file storage device |
| **OCR** | Optical Character Recognition | Text extraction from images |
| **OS** | Operating System | System software (Linux, macOS, etc.) |
| **PID** | Process ID | Unique identifier for running processes |
| **POSIX** | Portable Operating System Interface | Unix compatibility standard |
| **RAM** | Random Access Memory | Computer memory |
| **SSD** | Solid State Drive | Fast storage device |
| **TDD** | Test-Driven Development | Development approach (write tests first) |
| **UI** | User Interface | How users interact with software |
| **URL** | Uniform Resource Locator | Web address |
| **VCS** | Version Control System | Software for tracking code changes (git) |
| **WSL** | Windows Subsystem for Linux | Linux compatibility on Windows |
| **XML** | Extensible Markup Language | Data format (not used in doc.doc) |

## Plugin-Specific Terms

### Execute Commandline
The bash command defined in a plugin descriptor that invokes the CLI tool and captures its output.

### Install Commandline
The bash command defined in a plugin descriptor that installs or configures the required tool.

### Check Commandline
The bash command defined in a plugin descriptor that verifies the required tool is installed and functional.

### Platform-Specific Plugin
A plugin located in a platform-specific directory (e.g., `plugins/ubuntu/`) that uses OS-specific tools or command syntax.

### Cross-Platform Plugin
A plugin located in `plugins/all/` that works across multiple operating systems without modification.

### Active Plugin
A plugin with `"active": true` in its descriptor that will be used during analysis.

### Inactive Plugin
A plugin with `"active": false` in its descriptor that is discovered but not executed.

## File System Terms

### File Hash
A SHA-256 hash of a file's absolute path, used as the workspace filename to ensure uniqueness (e.g., `abc123def456.json`).

### Absolute Path
A complete file path from the root directory (e.g., `/home/user/docs/file.txt`).

### Relative Path
A file path relative to a reference directory (e.g., `docs/file.txt` relative to `/home/user/`).

### Symbolic Link (Symlink)
A file that points to another file or directory. Doc.doc follows symlinks with depth limits to prevent infinite loops.

### Hidden File
A file whose name starts with a dot (`.`), typically configuration files. Doc.doc excludes hidden files by default.

## Workflow Terms

### Full Analysis
Processing all files in the source directory, regardless of whether they've been analyzed before.

### Incremental Analysis
Processing only files that have changed since the last analysis, based on modification timestamps.

### Plugin Discovery
The process of scanning plugin directories and loading descriptor files to determine available plugins.

### Dependency Resolution
Analyzing plugin consumes/provides declarations to build a dependency graph and determine execution order.

### Circular Dependency
A situation where plugins have cyclic dependencies (A depends on B, B depends on A), which prevents execution.

## Quality Attributes

### Composability
The ability to combine the tool with other Unix utilities in pipelines and scripts.

### Extensibility
The ability to add new analysis capabilities through plugins without modifying core code.

### Reliability
The ability to execute consistently without errors, even in automated environments.

### Portability
The ability to run on different Unix-like systems with minimal adaptation.

### Usability
The ease with which users can understand and operate the tool.

## References

For more detailed information on specific concepts, refer to:
- Project Vision: [01_vision/01_project_vision/01_vision.md](../../01_project_vision/01_vision.md)
- Requirements: [01_vision/02_requirements/03_accepted/](../../02_requirements/03_accepted/)
- Architecture Constraints: [02_architecture_constraints.md](../02_architecture_constraints/02_architecture_constraints.md)
- Building Block View: [05_building_block_view.md](../05_building_block_view/05_building_block_view.md)
