# Vision
Provide a simple, scriptable toolkit that orchestrates existing CLI tools to extract metadata and content insights from files, then produce consistent, human‑readable summaries in Markdown.

# Goals
- **Automate analysis** of directories and file collections with a single command.
- **Standardize reports** using templates for repeatable Markdown output per analyzed file.
- **Stay composable** by integrating with common Linux tools instead of reinventing them.
- **Remain lightweight** and easy to run in local environments. 
- **Usability** by providing scripts that verify required tools are installed and, if not, prompt the user to install them.
- **Process data locally and offline**: All text analysis, metadata extraction, and content processing must be performed exclusively with local tools. No file content or sensitive data may be transmitted to online tools, LLMs, or external services. Network access is permitted only for tool installation and updates.
- **Toolkit extensibility**: Enable users to customize and extend the analysis workflow by adding or substituting CLI tools as needed. Therefore, a lightweight plugin architecture should be considered.

# Non‑Goals
- Building a full GUI application.
- Replacing specialized analysis tools.
- Providing heavy runtime dependencies like database and web servers.

# Intended Usage
The primary entry point is a single script that analyzes a directory and renders a Markdown report using a template.

Example command:

```
./doc.doc.sh -d <directory_to_analyze> -m <markdown_template> -t <target_directory> -w <workspace_directory> [-v]
```

Behavior:
- Recursively scans the source directory (`-d`).
- Extracts metadata and content using existing CLI tools.
- Stores document metadata and scan state in the workspace directory (`-w`) as JSON files for later processing.
- Records timestamps and metadata (last scan time, document information) for incremental analysis and tool integration.
- Renders Markdown reports to the target directory (`-t`) per analyzed file and/or an aggregated report.
- Uses the specified template (`-m`) for report formatting.
- Uses `-v` flag to enable verbose logging during analysis.
- `-p list` option to list available plugins and their capabilities.

Note on Workspace Directory:
The workspace (`-w`) serves as a persistent data layer that stores:
- Scan metadata and document information in JSON format
- Last scan timestamps for incremental analysis support
- Document summaries and extracted metadata
- State information that can be consumed by downstream tools and processes

# Features

## Plugin‑based extensibility
The toolkit is designed to be extended through plugins, allowing users to integrate custom CLI tools and analysis capabilities without modifying the core system. Each plugin declares what information it consumes and what information it provides through its descriptor.

## Data‑driven execution flow
The toolkit automatically determines the optimal plugin execution order by analyzing these dependencies. Plugins execute only after the data they require becomes available, creating a data‑driven execution flow. This approach keeps the system flexible and composable while ensuring **users do not need to model or maintain an explicit workflow**—the toolkit orchestrates the pipeline intelligently based on plugin capabilities.


