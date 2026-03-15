# doc.doc.md

[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE.md)
[![Shell: Bash 4.0+](https://img.shields.io/badge/shell-bash_4.0%2B-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Python: 3.12+](https://img.shields.io/badge/python-3.12%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Last Commit](https://img.shields.io/github/last-commit/PeculiarMind/doc.doc.md)](https://github.com/PeculiarMind/doc.doc.md/commits)
[![GitHub Stars](https://img.shields.io/github/stars/PeculiarMind/doc.doc.md?style=social)](https://github.com/PeculiarMind/doc.doc.md/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/PeculiarMind/doc.doc.md)](https://github.com/PeculiarMind/doc.doc.md/issues)

**Transform your document collections into organized, searchable markdown files.**

doc.doc.md is a command-line tool that mirrors a directory of source documents and generates a structured set of templated  markdown descriptions — one per document. It is designed for individuals who want a lightweight, file-system based document management without the overhead of a full-fledged server based document management system.

---

## Features

- **Directory Mirroring**: Automatically mirrors your input directory structure in the output location
- **Markdown Generation**: Creates markdown files for each document based on customizable templates
- **Advanced Filtering**: Powerful include/exclude logic with AND/OR operators for extensions, glob patterns, and MIME types
- **Language-Agnostic Plugin System**: Extensible architecture supporting plugins in any language (Bash, Python, compiled binaries)
- **Template-Based Output**: Full control over the structure of generated markdown files
- **Full Mustache Template Engine**: Templates support the full Mustache specification — variables, conditionals (`{{#section}}`), inverted sections (`{{^section}}`), loops over arrays, comments (`{{! comment}}`), and unescaped interpolation (`{{{raw}}}`) via a Python rendering engine
- **Unix Pipeline Architecture**: Efficient file processing using standard Unix pipes and streams
- **Simple CLI**: Straightforward command-line interface with clear options
- **Interactive Progress Display**: Live-updating ASCII progress bar when running in a terminal, with TTY auto-detection
- **TTY-Aware Output**: JSON result stream is automatically suppressed when stdout is an interactive terminal and `-o` is given — only the human-readable summary is shown; piped/redirected invocations still receive the full JSON array (Unix pipeline compatible)
- **Dry-Run Mode**: `--echo` flag previews rendered markdown output without writing files
- **Interactive Setup**: `setup` command verifies dependencies and configures plugins interactively
- **Custom Base Path**: `--base-path` parameter for controlling relative file references in rendered output
- **Graceful Plugin Skipping**: Plugins silently skip unsupported file types (ADR-004) — no spurious error messages
- **Plugin Validation Phase**: Before processing, validates that all active plugins are installed — with interactive resolution options (continue/abort/install) or hard error in non-interactive mode
- **Actionable Error Guidance**: Clear recovery advice (including `sudo` tips) when plugin installation fails
- **Plugin State Storage**: Stateful plugins receive an isolated `pluginStorage` directory for persisting data across invocations (e.g., classification models)
- **Per-Command Help**: Each command supports `--help` for detailed, command-specific usage; global `--help` shows a compact overview
- **Externalised Banner**: ASCII art banner stored in `banner.txt` with `{{key}}` mustache placeholder support for dynamic content

## Installation

### Prerequisites

- **Bash** shell environment (version 4.0+)
- **jq** (JSON processor, used by built-in plugins)
- **Python 3.12+** for advanced filtering and processing
- **chevron** Python library for Mustache template rendering (`pip install chevron`)
- **Git** (for cloning the repository)

The tool uses a mixed Bash+Python architecture:
- Bash handles CLI orchestration, file discovery, and plugin execution
- Python handles complex filtering logic (AND/OR operators across include/exclude parameters)

### Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/PeculiarMind/doc.doc.md.git
   cd doc.doc.md
   ```

2. Make the script executable:
   ```bash
   chmod +x doc.doc.sh
   ```

3. Run your first command:
   ```bash
   ./doc.doc.sh --help
   ```

4. Verify dependencies and configure plugins:
   ```bash
   ./doc.doc.sh setup
   ```

### Development Container

This project is configured for use with VS Code Dev Containers. If you're using VS Code with the Remote-Containers extension, simply open the repository and select "Reopen in Container" when prompted.

## Usage

### Basic Command

```bash
./doc.doc.sh process \
  --input-directory /path/to/documents \
  --output-directory /path/to/output \
  --template /path/to/template.md
```

### Advanced Filtering

Filter files using powerful include/exclude logic:

```bash
./doc.doc.sh process \
  --input-directory /path/to/documents \
  --output-directory /path/to/output \
  --include ".pdf,.docx" \
  --include "**/2024/**" \
  --exclude ".log" \
  --exclude "**/temp/**" \
  --exclude "**/drafts/**"
```

**Filter Logic:**
- Multiple `--include` parameters are ANDed (file must match at least one criterion from each)
- Values within a single `--include` parameter are ORed (e.g., `.pdf,.docx` matches either)
- Same logic applies to `--exclude` parameters
- Auto-detects filter types: file extensions (`.pdf`), glob patterns (`**/2024/**`), or MIME types (`application/pdf`)

#### MIME Type Filtering

Criteria containing `/` (but not `**`) are treated as MIME type criteria, evaluated against the MIME type detected by the `file` plugin:

```bash
# Include only plain-text files
./doc.doc.sh process \
  --input-directory /path/to/documents \
  --output-directory /path/to/output \
  --include "text/plain"

# Exclude all image files using a wildcard MIME pattern
./doc.doc.sh process \
  --input-directory /path/to/documents \
  --output-directory /path/to/output \
  --exclude "image/*"

# Combine MIME type and extension filters
./doc.doc.sh process \
  --input-directory /path/to/documents \
  --output-directory /path/to/output \
  --include "application/pdf,.docx" \
  --exclude "image/*"
```

**MIME filter behaviour:**
- Wildcard patterns are supported: `image/*` matches `image/png`, `image/jpeg`, etc.
- Files that do not pass the MIME filter are **silently skipped** (no output, no error)
- MIME detection requires the `file` plugin to be installed and active; if it is not, an error is raised and processing stops

> **Note:** The `file` plugin always runs first in the processing chain to ensure MIME type information is available for all subsequent filters and plugins.

### Example Workflow

**Input Directory:**
```
/documents
├── 2025
│   ├── somedoc.pdf
│   ├── anotherdoc.docx
│   └── justaphoto.jpg
└── 2024
    └── olderdoc.pdf
```

**Output Directory** (after processing):
```
/output
├── 2025
│   ├── somedoc.md
│   ├── anotherdoc.md
│   └── justaphoto.md
└── 2024
    └── olderdoc.md
```

Each `.md` file contains metadata and content extracted from the original document, formatted according to your template.

### Command-Line Options

#### Process Command

| Option | Short | Description | Required | Default |
|--------|-------|-------------|----------|----------|
| `--input-directory` | `-d` | Path to the input directory containing documents | Yes | |
| `--output-directory` | `-o` | Path where the markdown files will be created | Yes (unless `--echo`) | |
| `--template` | `-t` | Path to the markdown template file | No | Built-in default |
| `--include` | `-i` | Comma-separated file extensions, glob patterns, or MIME types to include | No | All files |
| `--exclude` | `-e` | Comma-separated file extensions, glob patterns, or MIME types to exclude | No | |
| `--echo` | | Print rendered markdown to stdout instead of writing files (dry-run) | No | |
| `--base-path` | `-b` | Base path for computing relative file references in templates | No | |
| `--progress` | | Force progress display even when stdout is not a TTY | No | Auto-detect TTY |
| `--no-progress` | | Suppress progress display even on a TTY | No | Auto-detect TTY |

> **TTY-aware JSON output:** When `-o <dir>` is provided and stdout is an interactive terminal, the JSON result array is **not** printed to stdout — only the `Processed N documents.` summary appears on stderr. When stdout is piped or redirected, the full JSON array is streamed to stdout as normal (backward-compatible Unix pipeline behaviour).

#### Plugin Commands

```bash
./doc.doc.sh list plugins                    # List all available plugins
./doc.doc.sh list plugins active             # List active plugins only
./doc.doc.sh list plugins inactive           # List inactive plugins only
./doc.doc.sh list parameters                 # List all parameters for every plugin
./doc.doc.sh list --plugin <name> --parameters  # List parameters for a specific plugin
./doc.doc.sh activate --plugin <name>        # Activate a plugin
./doc.doc.sh deactivate --plugin <name>      # Deactivate a plugin
./doc.doc.sh install --plugin <name>         # Install plugin dependencies
./doc.doc.sh installed --plugin <name>       # Check if plugin is installed
./doc.doc.sh tree                            # Display plugin dependency tree
./doc.doc.sh run <plugin> <command>          # Run a plugin command directly
./doc.doc.sh run crm114 listCategories -o /path/to/output  # Derive pluginStorage from -o
./doc.doc.sh run crm114 train -d /docs -o /path/to/output  # Pass input and output dirs
./doc.doc.sh run crm114 learn --help        # Show per-command help
./doc.doc.sh run --help                      # Show run command help
./doc.doc.sh setup                           # Verify dependencies and configure plugins
./doc.doc.sh setup --yes                     # Auto-configure everything (non-interactive)
```

## Project Structure

```
doc.doc.md/
├── doc.doc.sh              # Main script
├── doc.doc.md/             # Core directory
│   ├── components/         # Reusable components (filter, plugins, UI, templates)
│   ├── plugins/            # Plugin directory
│   │   ├── crm114/         # CRM114 text classification plugin
│   │   │   ├── descriptor.json
│   │   │   ├── main.sh
│   │   │   ├── install.sh
│   │   │   └── installed.sh
│   │   ├── file/           # MIME type detection plugin
│   │   │   ├── descriptor.json
│   │   │   ├── main.sh
│   │   │   ├── install.sh
│   │   │   └── installed.sh
│   │   ├── stat/           # File statistics plugin
│   │   │   ├── descriptor.json
│   │   │   ├── main.sh
│   │   │   ├── install.sh
│   │   │   └── installed.sh
│   │   ├── ocrmypdf/       # OCR processing plugin
│   │   │   ├── descriptor.json
│   │   │   ├── main.sh
│   │   │   ├── convert.sh
│   │   │   ├── install.sh
│   │   │   └── installed.sh
│   │   └── markitdown/     # MS Office to markdown plugin
│   │       ├── descriptor.json
│   │       ├── main.sh
│   │       ├── install.sh
│   │       └── installed.sh
│   └── templates/          # Template directory
│       └── default.md      # Default markdown template
├── project_documentation/  # Project docs (arc42 structure)
├── project_management/     # Guidelines, workflows, tools
└── LICENSE.md             # AGPL-3.0 license
```

## Plugins

Plugins extend doc.doc.md's functionality by extracting metadata and content from different file types. The project includes built-in plugins for file statistics and MIME type detection.

### Built-in Plugins

- **file**: Detects MIME types using the standard `file` command — **always runs first** in the processing chain; must be installed and active
- **stat**: Extracts file system metadata (size, owner, timestamps)
- **ocrmypdf**: Runs OCR on PDF and image files (JPEG, PNG, TIFF, BMP, GIF) using OCRmyPDF; also converts images to searchable PDFs
- **markitdown**: Converts MS Office documents (`.docx`, `.xlsx`, `.pptx`, `.doc`, `.xls`, `.ppt`) to markdown text using the `markitdown` Python library; requires `pip install markitdown`
- **crm114**: Statistical text classification using the CRM114 Discriminator; stores trained models in `pluginStorage`; requires `crm114` system package (inactive by default). Supports model management commands:
  - **`train`** — Interactive training loop: iterates documents, shows file path and first 100 words, prompts y/n per document/category to learn or unlearn. Uses `crm -e 'learn/unlearn ...'` (only the `crm` binary is required). Invoked via `./doc.doc.sh run crm114 train -d /docs -o /output`; receives `pluginStorage` and `inputDirectory` as positional arguments (stdin left free for user interaction)
  - **`learn`** — Non-interactive: trains a category model with a document's text (`category`, `pluginStorage`, `filePath` via JSON stdin)
  - **`unlearn`** — Non-interactive: removes a document's text from a category model (`category`, `pluginStorage`, `filePath` via JSON stdin)
  - **`listCategories`** — Lists all category names with trained `.css` models in `pluginStorage` (`pluginStorage` via JSON stdin)

### Plugin Architecture

Plugins are **language-agnostic** and invoked via shell commands:
- Defined using `descriptor.json` files
- Can be implemented in **any language** (Bash, Python, compiled binaries, etc.)
- Invoked as shell commands, never imported directly
- Simple interface: receive JSON input via stdin, produce JSON output via stdout
- Interactive commands (marked `"interactive": true` in descriptor) receive positional arguments instead, leaving stdin free for user interaction
- Type-safe communication using JSON for both input and output
- **Dependency ordering**: Execution order is derived automatically by matching `output` parameter names of one plugin to `input` parameter names of another — no explicit dependency declarations in descriptors

### Plugin Structure

Plugins are defined using JSON descriptors that specify:
- **Name and description**: Plugin identification
- **Commands**: Shell commands to execute (main, install, installed checks)
- **Input parameters**: What the plugin needs to process a file
- **Output fields**: What information the plugin extracts

### Example: file Plugin (Bash)

The `file` plugin detects MIME types using the standard `file` command:

```json
{
  "name": "file",
  "description": "Detects MIME types using the file command",
  "commands": {
    "process": {
      "command": "main.sh",
      "input": {
        "filePath": { "required": true, "type": "string", "description": "Path to file" }
      },
      "output": {
        "mimeType": { "type": "string", "description": "Detected MIME type" }
      }
    },
    "install": {
      "command": "install.sh"
    },
    "installed": {
      "command": "installed.sh"
    }
  }
}
```

The plugin receives input via stdin:
```json
{"filePath": "/path/to/file.pdf"}
```

### Example: stat Plugin (Bash)

The `stat` plugin extracts file system information:

```json
{
  "name": "stat",
  "description": "Provides statistical information about a file",
  "commands": {
    "process": {
      "command": "main.sh",
      "input": {
        "filePath": { "required": true, "type": "string", "description": "Path to file" }
      },
      "output": {
        "fileSize": { "type": "number", "description": "File size in bytes" },
        "fileOwner": { "type": "string", "description": "File owner" },
        "fileCreated": { "type": "string", "description": "File creation date (ISO 8601)" },
        "fileModified": { "type": "string", "description": "Last modification date (ISO 8601)" },
        "fileMetadataChanged": { "type": "string", "description": "Metadata change date (ISO 8601)" }
      }
    },
    "install": {
      "command": "install.sh"
    },
    "installed": {
      "command": "installed.sh"
    }
  }
}
```

The plugin receives input via stdin:
```json
{"filePath": "/path/to/file.pdf"}
```

### Example: Python Plugin

Plugins can be implemented in Python:

```json
{
  "name": "pdf-extractor",
  "commands": {
    "process": {
      "command": "python3 extract.py",
      "input": {
        "filePath": { "required": true, "type": "string", "description": "Path to PDF" }
      },
      "output": {
        "pdfTitle": { "type": "string", "description": "PDF title" },
        "pdfAuthor": { "type": "string", "description": "PDF author" }
      }
    }
  }
}
```

The Python script reads JSON from stdin:
```python
import json
import sys

input_data = json.load(sys.stdin)
file_path = input_data['filePath']
# Process file...
output = {"pdfTitle": "...", "pdfAuthor": "..."}
json.dump(output, sys.stdout)
```

### Creating Custom Plugins

1. Create a new directory under `doc.doc.md/plugins/[plugin-name]/`
2. Add a `descriptor.json` file defining commands, inputs, and outputs
3. Implement the plugin in your preferred language:
   - **Bash**: Create `main.sh` script
   - **Python**: Create `process.py` script
   - **Compiled**: Add your binary and update command path
4. Specify the shell command in `descriptor.json`
5. Optionally add `install.sh` and `installed.sh` for dependency management
6. Reference the plugin output variables in your template

## Templates

Templates control the structure and content of generated markdown files.

### Default Template

Located at `doc.doc.md/templates/default.md`:

```markdown
# {{fileName}}

Document processed on {{processingDate}}
```

### Template Variables

Templates use the full **Mustache** specification, rendered by a Python engine. Variables use the `{{variableName}}` syntax (lowerCamelCase).

Supported Mustache features:
- `{{variable}}` — HTML-escaped interpolation
- `{{{variable}}}` — unescaped (raw) interpolation
- `{{#section}}...{{/section}}` — conditional sections / array loops
- `{{^section}}...{{/section}}` — inverted sections (render when falsy)
- `{{! comment }}` — comments (omitted from output)

Example template using the stat plugin:

```markdown
# {{fileName}}

## File Information

- **Size**: {{fileSize}} bytes
- **Owner**: {{fileOwner}}
- **Created**: {{fileCreated}}
- **Modified**: {{fileModified}}


```

### Creating Custom Templates

1. Create a new `.md` file with your desired structure
2. Use `{{variableName}}` placeholders for dynamic content (lowerCamelCase matching plugin outputs)
3. Pass the template path via the `--template` option

## Use Cases

- **Personal Document Management**: Convert your file cabinets into searchable markdown
- **Home Lab Documentation**: Generate documentation indices for your digital archives
- **Content Migration**: Prepare documents for import into Obsidian, Logseq, or other markdown tools
- **Document Cataloging**: Create metadata-rich catalogs of large document collections

## Architecture

doc.doc.md uses a **mixed Bash and Python architecture** for optimal performance and maintainability:

- **Bash**: CLI orchestration, file discovery (`find`), plugin execution, Unix pipeline coordination
- **Python 3.12+**: Complex filtering logic with AND/OR operators across include/exclude parameters

**Why this approach?**
- **Primary driver**: Complex filter evaluation (AND/OR logic across multiple parameters) is difficult to implement reliably in pure Bash
- Leverages each language's strengths (shell operations vs. complex logic)
- Maintains Unix CLI tool philosophy
- Supports language-agnostic plugins via shell command invocation
- Efficient pipeline processing via null-delimited streams

See [ADR-001](project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_001_mixed_bash_python_implementation.md) for detailed rationale.

## Contributing

Contributions are welcome! This project is in active development and needs help with:

- Core script implementation (Bash + Python components)
- Plugin development (PDF, DOCX, image processing, etc.) in any language
- Template creation
- Documentation improvements
- Testing and bug reports

### Getting Started

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines 

- Follow the workflow guidelines in `project_management/01_guidelines/workflows/`
- Review the communication standards in `project_management/01_guidelines/agent_behavior/`
- Check the documentation standards in `project_management/01_guidelines/documentation_standards/`

## License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

Key points:
- **Open Source**: Source code must be made available
- **Copyleft**: Derivative works must use the same license
- **Network Use**: Running modified versions on a server requires sharing source code with users
- **Patent Grant**: Contributors grant patent rights to users

See [LICENSE.md](LICENSE.md) for full details.

## Credits

- **arc42**: Architecture documentation structure based on the [arc42 template](https://arc42.org)
- **ProTemp.AI**: Project structure inspired by [PeculiarMind/ProTemp.AI](https://github.com/PeculiarMind/ProTemp.AI)

See [CREDITS.md](CREDITS.md) for complete attribution.

## Documentation

- [User Guide](project_documentation/03_user_guide/user_guide.md) — installation, usage, filtering, plugins, and templates for end users
- [Operations Guide](project_documentation/02_ops_guide/ops_guide.md) — system requirements, plugin management, troubleshooting, and security
- [Development Guide](project_documentation/04_dev_guide/dev_guide.md) — architecture, plugin development, testing, and contribution guidelines
- [Architecture Documentation](project_documentation/01_architecture/) — arc42 architecture docs including building-block view and decisions

## Support

- **Issues**: Report bugs or request features via [GitHub Issues](https://github.com/PeculiarMind/doc.doc.md/issues)
- **Discussions**: Join conversations about the project

---

**Ready to organize your documents?** Start by exploring the examples and customizing your first template!
