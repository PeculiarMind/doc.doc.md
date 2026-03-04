# System Scope and Context

## Business Context

```
┌─────────────┐
│    User     │
└──────┬──────┘
       │ Commands (process, list, activate, deactivate, install, installed, tree)
       │ Input: file paths, filter criteria, plugin names
       │ Output: JSON results (stdout), status messages (stderr)
       ▼
┌────────────────────────────────────────┐
│         doc.doc.sh System              │
│                                        │
│  ┌──────────┐      ┌──────────────┐   │
│  │   CLI    │─────▶│  Processing  │   │
│  │ Interface│      │   Engine     │   │
│  └──────────┘      └──────┬───────┘   │
│                           │            │
│                    ┌──────▼────────┐   │
│                    │ Plugin System │   │
│                    └───────────────┘   │
└────────────────────────────────────────┘
       │                    │
       │ Read              │ JSON (stdout)
       ▼                    ▼
┌──────────────┐    ┌──────────────┐
│Input Documents│    │Structured    │
│  (Various    │    │JSON Output   │
│   Formats)   │    │  (stdout)    │
└──────────────┘    └───────────────┘
```

### External Interfaces

| Interface | Partner | Input | Output |
|-----------|---------|-------|--------|
| **User CLI** | End User | Commands, file paths, filter criteria | Status messages (stderr), JSON results (stdout) |
| **Input Documents** | File System | Documents in various formats (PDF, images, text, etc.) | N/A |
| **Plugin Repository** | Plugin Developers | Plugin packages (`descriptor.json` + shell/Python scripts) | N/A |
| **Template Files** | Template Authors | Markdown templates with `{{variable}}` placeholders | N/A |

> **Note**: The output directory (`-o` flag) and directory-mirrored markdown file writing are not yet implemented. The system currently streams JSON to stdout. See [Section 11](../11_risks_and_technical_debt/11_risks_and_technical_debt.md).

## Technical Context

```
┌─────────────────────────────────────────────────────────┐
│                     doc.doc.sh (Main Entry)             │
│                                                         │
│  ┌────────────────────────────────────────────────┐    │
│  │           Bash Orchestration Layer             │    │
│  │  • Argument parsing and command routing        │    │
│  │  • MIME criterion classification               │    │
│  │  • Plugin chain ordering (file-first)          │    │
│  │  • MIME filter gate (post-file-plugin)         │    │
│  │  • Plugin management commands                  │    │
│  └──────────────┬─────────────────────────────────┘    │
│                 │                                       │
│    ┌────────────┼────────────┐                          │
│    ▼            ▼            ▼                          │
│┌──────┐  ┌──────────┐  ┌─────────┐                     │
││Python│  │ Bash     │  │Plugins  │                     │
││Filter│  │Components│  │(file,   │                     │
││Engine│  │(plugins, │  │ stat,   │                     │
││      │  │ help, …) │  │ ocrmypdf│                     │
│└──────┘  └──────────┘  └─────────┘                     │
└─────────────────────────────────────────────────────────┘
         │              │             │
         ▼              ▼             ▼
┌──────────────┐  ┌──────────┐  ┌───────────┐
│ Python Libs  │  │ Unix     │  │ External  │
│ (pathlib,    │  │ Utils    │  │ Tools     │
│  fnmatch,    │  │ (find,   │  │ (file,    │
│  subprocess) │  │  jq)     │  │  stat,    │
│              │  │          │  │  ocrmypdf)│
└──────────────┘  └──────────┘  └───────────┘
```

### Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Main CLI** | Bash (`doc.doc.sh`, 1027 lines) | Entry point, command routing, orchestration, MIME gate |
| **Filter Engine** | Python 3.12+ (`filter.py`) | Path and MIME include/exclude logic with `fnmatch` |
| **Plugin Management** | Bash (`components/plugins.sh`) | Discovery, activation, invocation, dependency tree |
| **File Discovery** | Unix `find` | Recursive directory traversal |
| **MIME Detection** | Unix `file` command (via `file` plugin) | File type identification; feeds MIME filter gate |
| **JSON Handling** | `jq` (in plugin scripts) | Parsing plugin input; generating plugin output |
| **Template Engine** | Bash text substitution (`components/templates.sh`) | `{{variable}}` substitution in markdown templates |

### Key Dependencies

| Dependency | Version | Purpose |
|-----------|---------|---------|
| Bash | 4.0+ | Primary language for orchestration |
| Python | 3.12+ | Filter engine (`filter.py`) |
| `find` | Any POSIX | File discovery |
| `file` | Any | MIME type detection (via `file` plugin) |
| `jq` | Any | JSON parsing in plugin scripts |
| `stat` | Any (Linux/macOS) | File metadata (via `stat` plugin) |
| `ocrmypdf` | Any | OCR processing (via `ocrmypdf` plugin; optional) |

### Data Flow

1. **Input Phase**: User provides command, input directory, filter criteria.
2. **Discovery Phase**: `find` traverses the input directory; paths piped to `filter.py` for path/extension/glob filtering.
3. **MIME Classification**: Criteria containing `/` (but not `**`) are extracted as MIME criteria before the processing loop.
4. **Processing Phase**: For each matched file:
   - Plugin chain executes with `file` plugin first (mandatory).
   - After `file` plugin runs, MIME filter gate evaluates MIME criteria against detected MIME type.
   - Remaining plugins execute in dependency order; each receives JSON via stdin, returns JSON via stdout.
5. **Output Phase**: Aggregated JSON written to stdout; status/progress messages to stderr.
