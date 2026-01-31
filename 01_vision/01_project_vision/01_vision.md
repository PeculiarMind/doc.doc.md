# Vision
Provide a simple, scriptable toolkit that orchestrates existing CLI tools to extract metadata and content insights from files, then produce consistent, human‑readable summaries in Markdown.

# Goals
- **Automate analysis** of directories and file collections with a single command.
- **Standardize reports** using templates for repeatable Markdown output per analyzed file.
- **Stay composable** by integrating with common UNIX tools instead of reinventing them.
- **Remain lightweight** and easy to run in local environments. 
- **Usability** by providing scripts that verify required tools are installed and, if not, prompt the user to install them.

# Non‑Goals
- Building a full GUI application.
- Replacing specialized analysis tools.
- Providing heavy runtime dependencies beyond common CLI utilities.

# Intended Usage
The primary entry point is a single script that analyzes a directory and renders a Markdown report using a template.

Example command:

```
./doc.doc.sh -d <directory_to_analyze> -m <report_template> [-v]
```

Behavior:
- Recursively scans the target directory.
- Extracts metadata/content signals using existing CLI tools.
- Renders a Markdown summary per analyzed file and/or an aggregated report.
- Uses `-v` for verbose logging during analysis.
