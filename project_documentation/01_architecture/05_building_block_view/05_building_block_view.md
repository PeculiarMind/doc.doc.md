# Building Block View

## Level 1: System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      doc.doc.sh System                      │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Main Entry Point (doc.doc.sh)           │   │
│  │  • Command routing                                   │   │
│  │  • Argument parsing and validation                   │   │
│  │  • MIME criterion classification                     │   │
│  │  • File-first plugin chain ordering                  │   │
│  │  • MIME filter gate                                  │   │
│  └────────────────────┬─────────────────────────────────┘   │
│                       │                                     │
│       ┌───────────────┼───────────────┐                     │
│       │               │               │                     │
│  ┌────▼────┐    ┌─────▼─────┐   ┌────▼─────┐               │
│  │  Bash   │    │  Python   │   │ Plugin   │               │
│  │Components│   │  Filter   │   │ System   │               │
│  │         │    │  Engine   │   │          │               │
│  └─────────┘    └───────────┘   └──────────┘               │
└─────────────────────────────────────────────────────────────┘
```

| Component | Responsibility |
|-----------|---------------|
| **doc.doc.sh** | CLI entry point, command routing, parameter validation, MIME criterion classification, file-first enforcement, MIME filter gate, workflow coordination |
| **Bash Components** | Help system, logging, plugin management, template handling |
| **Python Filter Engine** | Path, extension, glob, and MIME include/exclude logic |
| **Plugin System** | Extensible file processing; JSON stdin/stdout interface |

## Level 2: Main Entry Point

### doc.doc.sh

**Responsibilities**:
1. Parse command-line arguments; route to subcommand handlers (`cmd_process`, `cmd_list`, `cmd_activate`, …).
2. Validate input directory and required parameters.
3. Classify filter criteria: path/extension/glob criteria vs. MIME criteria (criteria containing `/` but not `**`).
4. Load active plugins; enforce `file` plugin first in chain.
5. Invoke `find` + `filter.py` pipeline for file discovery and path filtering.
6. For each discovered file: run plugin chain; apply MIME filter gate after `file` plugin; continue or skip.
7. Report results to stdout (JSON) and progress/errors to stderr.

**Implemented subcommands**: `process`, `list`, `activate`, `deactivate`, `install`, `installed`, `tree`, `run`.

## Level 3: Component Detail

### Source Layout

```
doc.doc.md/
├── components/
│   ├── plugin_management.sh  # Plugin discovery, descriptor loading, activation state, tree/list commands
│   ├── plugin_execution.sh   # Plugin command invocation, I/O routing, exit-code classification
│   ├── plugin_info.py        # Python component: DFS dependency tree rendering and table formatting
│   ├── filter.py             # Python filter engine
│   ├── help.sh               # Help text generation
│   ├── logging.sh            # Logging utilities
│   └── templates.sh          # Template loading and variable substitution
└── plugins/
    ├── file/
    │   ├── descriptor.json
    │   ├── main.sh
    │   ├── install.sh
    │   └── installed.sh
    ├── stat/
    │   ├── descriptor.json
    │   ├── main.sh
    │   ├── install.sh
    │   └── installed.sh
    └── ocrmypdf/
        ├── descriptor.json
        ├── main.sh
        ├── install.sh
        ├── installed.sh
        └── convert.sh
```

### plugins.sh

**Purpose**: Plugin lifecycle management.

**Key responsibilities**:
- `discover_plugins()`: Scan plugin directory; parse `descriptor.json`; honour `active` field (absent or `null` defaults to `true`).
- `run_plugin()`: Invoke a plugin command via shell; pass JSON input via stdin; capture JSON output from stdout.
- Activation/deactivation: Update `active` field in `descriptor.json` via `jq`.
- `cmd_tree()`: Build and render a dependency tree from declared input/output parameters.

### filter.py

**Purpose**: Stateless, general-purpose include/exclude filter.

**Interface**:
- stdin: newline- or null-delimited file paths (or a single MIME type string when invoked by the MIME gate).
- Arguments: `--include <criteria>` and `--exclude <criteria>` (repeatable; comma-separated values within each argument).
- stdout: matching values (same delimiter as input).

**Filter logic**:
- OR within a single `--include`/`--exclude` parameter (comma-separated values).
- AND between multiple `--include`/`--exclude` parameters.
- Criterion classification: starts with `.` → extension match; contains `/` but not `**` → treated as MIME glob via `fnmatch`; otherwise → path glob via `fnmatch`.
- When input is a MIME type string (not a file path), `os.path.isfile()` returns False and `fnmatch` is applied directly.

### templates.sh

**Purpose**: Template loading and `{{variable}}` substitution.

**Template resolution order**:
1. User-specified via `--template` argument.
2. `~/.config/doc.doc.md/templates/default.md`
3. Built-in template shipped with the application.

### help.sh / logging.sh

Standard help display and logging utilities. Errors and progress written to stderr; data output to stdout.

## Level 4: Plugin Architecture

### Plugin Structure

```
plugins/<name>/
├── descriptor.json    # Metadata, command declarations, parameter schemas
├── main.sh            # process command entry point
├── install.sh         # install command entry point
└── installed.sh       # installed command entry point
```

Optional additional commands (e.g., `convert.sh` in `ocrmypdf`) are defined in `descriptor.json` under `commands`.

### Plugin Descriptor Schema (ADR-003)

```json
{
  "name": "stat",
  "version": "1.0.0",
  "description": "...",
  "active": true,
  "commands": {
    "process": {
      "description": "...",
      "command": "main.sh",
      "input": {
        "filePath": { "type": "string", "required": true, "description": "..." }
      },
      "output": {
        "fileSize":   { "type": "number",  "description": "..." },
        "fileOwner":  { "type": "string",  "description": "..." },
        "fileCreated":{ "type": "string",  "description": "..." },
        "fileModified":{ "type": "string", "description": "..." }
      }
    },
    "install":   { "command": "install.sh",   "output": { "success": ..., "message": ... } },
    "installed": { "command": "installed.sh", "output": { "installed": ... } }
  }
}
```

All parameter names follow lowerCamelCase. The `active` field controls whether a plugin participates in the processing chain (absent/`null` treated as `true`).

### Implemented Plugins

| Plugin | Key Outputs | Notes |
|--------|-------------|-------|
| **file** | `mimeType` | Wraps `file --mime-type -b`; always executes first in chain. |
| **stat** | `fileSize`, `fileOwner`, `fileCreated`, `fileModified`, `fileMetadataChanged` | Cross-platform: detects Linux vs. macOS via `uname -s`. |
| **ocrmypdf** | `ocrText` | Requires `filePath` and `mimeType` as inputs; implicit dependency on `file` plugin. Optional `imageDpi`. Also provides custom `convert` command. |

### Plugin Dependency Resolution

Dependencies are inferred from parameter types: if a plugin's `process.input` contains a parameter name that matches another plugin's `process.output` parameter name, an execution dependency is established. The `file` plugin provides `mimeType`; `ocrmypdf` requires `mimeType` — making `file` → `ocrmypdf` the implicit order.

> **Note**: `ocrmypdf/descriptor.json` currently contains an explicit `"dependencies": ["file"]` attribute. This is a known defect (BUG_0005, backlog). The authoritative dependency mechanism is type-based matching.

### Plugin Interface Contract

**process input** (JSON via stdin):
```json
{ "filePath": "/absolute/path/to/file.pdf", "mimeType": "application/pdf" }
```

**process output** (JSON via stdout):
```json
{ "fileSize": 1048576, "fileOwner": "user", "fileModified": "2024-02-25T14:30:00Z" }
```

**Exit codes**:
- `0`: Success.
- `1`: Temporary failure — skip file, continue processing.
- `2`: Fatal error — stop processing.
