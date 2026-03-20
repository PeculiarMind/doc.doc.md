# User Guide

## Table of Contents

- [Introduction](#introduction)
- [Getting Started](#getting-started)
- [Basic Usage](#basic-usage)
- [Filtering Documents](#filtering-documents)
- [Plugin System](#plugin-system)
- [Templates](#templates)
- [Example Workflows](#example-workflows)
- [Command Reference](#command-reference)
- [FAQ](#faq)

---

## Introduction

**doc.doc.md** is a command-line tool that scans a directory of documents, runs each file through a configurable set of plugins, and produces a JSON record for every file containing the metadata extracted by those plugins.

**Key benefits:**

- No server, database, or cloud account required — runs entirely on your machine
- Works on any directory of files; no special document format needed
- Extensible: add plugins for PDF text extraction, image OCR, EXIF data, and more
- Filter by file extension, path pattern, or actual MIME type (content-based, not just extension)
- Output is plain JSON — pipe it into any tool, template engine, or markdown generator

doc.doc.md is designed for home users and home-lab enthusiasts who want to catalogue, index, or document a collection of files without deploying a full document management system.

---

## Getting Started

### Prerequisites

Before you start, make sure you have:

- **Bash 4.0+** (standard on Linux; macOS ships Bash 3 by default — use Homebrew to upgrade)
- **jq** — `sudo apt install jq` or `brew install jq`
- **Python 3.12+** — `sudo apt install python3` or from python.org
- **Git** — to clone the repository

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/PeculiarMind/doc.doc.md.git
cd doc.doc.md

# 2. Make the script executable
chmod +x doc.doc.sh

# 3. Install plugin dependencies
./doc.doc.sh install plugins --all

# 4. Confirm everything is ready
./doc.doc.sh list plugins
```

### First Run

```bash
./doc.doc.sh process -d ~/Documents
```

This processes every file in `~/Documents` and prints a JSON array to your terminal, one entry per file.

---

## Basic Usage

### The `process` Command

```
./doc.doc.sh process -d <directory> [options]
```

`-d` is the only required flag — it specifies the directory to scan.

**Example:**

```bash
./doc.doc.sh process -d ~/Documents
```

### What the Output Looks Like

The command streams a JSON array to stdout. Each entry represents one file and contains all fields produced by the active plugins:

> **TTY-aware behaviour:** When stdout is an interactive terminal and `-o <dir>` is given, the JSON array is **suppressed** — only the `Processed N documents.` summary line appears on stderr. To receive the JSON stream in a terminal session, pipe stdout to another command (e.g., `| jq .`) or redirect it to a file. When stdout is piped or redirected, the full JSON array is always produced (backward-compatible Unix pipeline behaviour).

```json
[
  {
    "filePath": "/home/alice/Documents/2024/invoice.pdf",
    "mimeType": "application/pdf",
    "fileSize": 512000,
    "fileOwner": "alice",
    "fileCreated": "2024-02-10T08:00:00Z",
    "fileModified": "2024-02-10T08:15:30Z",
    "fileMetadataChanged": "2024-02-10T08:15:30Z"
  },
  {
    "filePath": "/home/alice/Documents/notes.txt",
    "mimeType": "text/plain",
    "fileSize": 1024,
    "fileOwner": "alice",
    "fileCreated": "",
    "fileModified": "2024-05-01T10:00:00Z",
    "fileMetadataChanged": "2024-05-01T10:00:00Z"
  }
]
```

> **Note:** `fileCreated` may be empty on Linux filesystems that do not store a creation (birth) time.

### Saving the Output

Redirect stdout to a file:

```bash
./doc.doc.sh process -d ~/Documents > documents.json
```

Or pipe it directly into `jq` for exploration:

```bash
./doc.doc.sh process -d ~/Documents | jq '.[] | {name: .filePath, size: .fileSize}'
```

### Directory Mirroring

doc.doc.md scans your input directory recursively. The `filePath` field in each output record preserves the full path, so the directory structure is reflected in the output data.

---

## Filtering Documents

### Include Filters (`-i`)

Use `-i` to specify which files to process. Without any `-i`, all files are candidates.

```bash
# Only PDFs
./doc.doc.sh process -d ~/Documents -i ".pdf"

# PDFs or Word documents
./doc.doc.sh process -d ~/Documents -i ".pdf,.docx"

# Only files in a 2024 subdirectory
./doc.doc.sh process -d ~/Documents -i "**/2024/**"
```

### Exclude Filters (`-e`)

Use `-e` to skip certain files from an otherwise matching set.

```bash
# Exclude log files
./doc.doc.sh process -d ~/Documents -e ".log"

# Exclude anything in a temp or drafts subdirectory
./doc.doc.sh process -d ~/Documents -e "**/temp/**" -e "**/drafts/**"
```

### AND/OR Logic

**Within a single flag** (comma-separated values): **OR** logic — the file matches if it satisfies any one criterion.

**Across multiple flags of the same type**: **AND** logic — the file must satisfy at least one criterion from *each* flag.

```bash
# Must be .txt OR .md AND must be under a 2024 directory
./doc.doc.sh process -d ~/Documents \
  -i ".txt,.md" \
  -i "**/2024/**"

# Excluded only if it matches .log AND is under temp
# (a .log file outside of temp is kept; a temp file without .log extension is kept)
./doc.doc.sh process -d ~/Documents \
  -e ".log" \
  -e "**/temp/**"
```

### MIME Type Filters

Criteria containing `/` (but not `**`) are treated as MIME type criteria. The MIME type is detected from the file's actual content — not its extension.

```bash
# Only plain-text files (by content, not extension)
./doc.doc.sh process -d ~/Documents -i "text/plain"

# Exclude all images
./doc.doc.sh process -d ~/Documents -e "image/*"

# PDFs by MIME and extension, from 2024
./doc.doc.sh process -d ~/Documents \
  -i "application/pdf,.pdf" \
  -i "**/2024/**"
```

MIME wildcards are supported: `image/*` matches `image/png`, `image/jpeg`, etc.

> **MIME filter requirement:** MIME filtering requires the `file` plugin to be active and installed. If it is not, processing stops with an error. Files that do not match a MIME filter are silently skipped.

### Filter Type Detection

| Criterion pattern | Treated as |
|-------------------|-----------|
| Starts with `.` | File extension |
| Contains `**` | Glob pattern |
| Contains `/` (no `**`) | MIME type |

### Practical Filter Examples

| Command | What it selects |
|---------|----------------|
| `-i ".pdf"` | All PDF files |
| `-i ".pdf,.docx"` | PDF or Word files |
| `-i "**/2024/**"` | Files in any path containing `2024` |
| `-i ".pdf" -i "**/2024/**"` | PDF files that are also in a `2024` path |
| `-e ".log"` | Everything except `.log` files |
| `-e ".log" -e "**/temp/**"` | Exclude files that are **both** `.log` and inside `temp` |
| `-i "text/plain"` | Files whose content is plain text |
| `-e "image/*"` | Exclude all image types |

---

## Plugin System

### What Plugins Do

Plugins extract information from files. When you run `process`, each active plugin receives the file path (and any outputs from earlier plugins), does its work, and adds new fields to the record for that file.

Plugins communicate via JSON: they read a JSON object from stdin and write a JSON object to stdout. This design means plugins can be written in any language.

### Listing Plugins

```bash
./doc.doc.sh list plugins            # all plugins with status
./doc.doc.sh list plugins active     # active only
./doc.doc.sh list plugins inactive   # inactive only
```

### Activating and Deactivating Plugins

```bash
./doc.doc.sh activate --plugin ocrmypdf    # turn on OCR processing
./doc.doc.sh deactivate --plugin ocrmypdf  # turn it off
```

Deactivating a plugin does not remove it — it is simply skipped on the next `process` run.

### Built-in Plugins

#### `file` — MIME Type Detection

Detects the actual MIME type of a file by reading its content with the `file` system command. Always runs first in the processing pipeline.

**Always required.** The `file` plugin must be active for `process` to run.

| Output field | Type | Description |
|-------------|------|-------------|
| `mimeType` | string | Detected MIME type (e.g., `application/pdf`, `image/png`) |

#### `stat` — File System Metadata

Extracts file system statistics using the `stat` command.

| Output field | Type | Description |
|-------------|------|-------------|
| `fileSize` | number | Size in bytes |
| `fileOwner` | string | Username of the file owner |
| `fileCreated` | string | Creation date (ISO 8601); empty if unsupported by filesystem |
| `fileModified` | string | Last modification date (ISO 8601) |
| `fileMetadataChanged` | string | Last metadata change date (ISO 8601) |

#### `markitdown` — MS Office to Markdown Conversion

Converts MS Office documents to markdown text using the `markitdown` Python library (maintained by Microsoft). Requires the `file` plugin (uses `mimeType` to gate on supported types).

**Supported input types:** `.docx`, `.xlsx`, `.pptx` (OOXML) and `.doc`, `.xls`, `.ppt` (legacy binary formats)

| Output field | Type | Description |
|-------------|------|-------------|
| `documentText` | string | Extracted document content as markdown |

Install the `markitdown` plugin before activating it:

```bash
./doc.doc.sh install --plugin markitdown
./doc.doc.sh activate --plugin markitdown
```

> **Note:** `markitdown` is installed as a Python package via `pip`. Python 3 and pip must be available on your system.

#### `ocrmypdf` — Text Extraction via OCR

Extracts text from PDFs and images using OCRmyPDF. Requires the `file` plugin (uses `mimeType` to determine how to process the file).

**Supported input types:** `application/pdf`, `image/jpeg`, `image/png`, `image/tiff`, `image/bmp`, `image/gif`

For PDFs with an existing text layer, `pdftotext` is tried first (faster and more accurate). OCRmyPDF is used as a fallback for scanned PDFs, and as the primary tool for image files.

| Output field | Type | Description |
|-------------|------|-------------|
| `ocrText` | string | Full plain text extracted from the file |

Install the `ocrmypdf` plugin before activating it:

```bash
./doc.doc.sh install --plugin ocrmypdf
./doc.doc.sh activate --plugin ocrmypdf
```

### Plugin Dependency Tree

```bash
./doc.doc.sh tree
```

Shows which plugins depend on which. For example, `ocrmypdf` depends on `file` (it needs the `mimeType` value that `file` produces). Active plugins are shown in green; inactive in red.

### Plugin Security

> ⚠️ **Plugins execute code on your system with your user permissions.** Read this section before installing any third-party plugin.

#### Built-in vs. Third-Party Plugins

| Type | Examples | Trust Level |
|------|----------|------------|
| **Built-in** | `file`, `stat`, `ocrmypdf`, `markitdown` | Maintained by the doc.doc.md core team; included in this repository |
| **Third-party** | Any plugin not in this repository | Created by the community; varying trust level; review before use |

#### What Plugins Can Do

A plugin runs with the same OS permissions as the `doc.doc.sh` process. It can:

- **Read** any file your user account can read
- **Write or delete** any file your user account can write
- **Execute** system commands
- **Access the network** (unless blocked by the OS)
- **Consume** CPU, memory, and disk space

#### Before Installing a Third-Party Plugin

1. **Check the source** — prefer well-known repositories with a public change history.
2. **Read the code** — plugins are shell scripts (`main.sh`, `install.sh`) and a JSON descriptor (`descriptor.json`). Read them before installing.
3. **Check `install.sh`** — it reveals what external tools will be installed.
4. **Start deactivated** — install the plugin but leave it inactive (`deactivate --plugin <name>`) until you have verified it.
5. **Run as a low-privilege user** — never run doc.doc.md as root unless the input directory requires it.

---

## Templates

When you supply an output directory with `-o`, doc.doc.md renders one sidecar `.md` file per processed document by applying a Mustache template to each file's JSON record. The default template lives at `doc.doc.md/templates/default.md`; you can supply your own with `-t`.

### Generating Sidecar Markdown Files

```bash
# Write one .md file per document alongside the originals
./doc.doc.sh process -d ~/Documents -o ~/Documents/docs

# Use a custom template
./doc.doc.sh process -d ~/Documents -o ~/docs-out -t ~/my-template.md

# Preview rendered output without writing files (dry-run)
./doc.doc.sh process -d ~/Documents --echo
```

### Default Template

```markdown
# {{fileName}}


{{#categories}}#{{.}} {{/categories}}

=> [{{fileName}}]({{filePath}})

## File Metadata
- **Size**: {{fileSize}} bytes
- **Owner**: {{fileOwner}}
- **Created**: {{fileCreated}}
- **Modified**: {{fileModified}}
- **Metadata Changed**: {{fileMetadataChanged}}
- **MIME Type**: {{mimeType}}


## Content

### Extracted Text from File
{{documentText}}  
{{ocrText}}
```

### Template Variables

Variable names match the JSON output field names from plugins exactly, and use lowerCamelCase.

| Variable | Source | Description |
|----------|--------|-------------|
| `{{fileName}}` | derived | Basename of the file (derived automatically from `filePath`) |
| `{{filePath}}` | core | Full path to the file |
| `{{mimeType}}` | `file` plugin | Detected MIME type |
| `{{fileSize}}` | `stat` plugin | File size in bytes |
| `{{fileOwner}}` | `stat` plugin | File owner username |
| `{{fileCreated}}` | `stat` plugin | Creation date (ISO 8601; may be empty on Linux) |
| `{{fileModified}}` | `stat` plugin | Last modification date (ISO 8601) |
| `{{fileMetadataChanged}}` | `stat` plugin | Last metadata change date (ISO 8601) |
| `{{documentText}}` | `markitdown` plugin | Extracted content from MS Office documents, as markdown |
| `{{ocrText}}` | `ocrmypdf` plugin | Full plain text extracted via OCR |
| `{{categories}}` | `crm114` plugin | Array of classification category names |

Custom plugins add their own variables using the same naming convention.

### Supported Mustache Syntax

Templates are rendered with the [chevron](https://github.com/noahmorrison/chevron) library, which implements the full [Mustache specification](https://mustache.github.io/mustache.5.html). The following constructs are supported.

#### Variable Tags — `{{variable}}`

Outputs the value of a key from the JSON record. The value is HTML-escaped by default.

```mustache
# {{fileName}}
- **MIME**: {{mimeType}}
- **Size**: {{fileSize}} bytes
```

#### Unescaped Variables — `{{{variable}}}` or `{{&variable}}`

Outputs the value without HTML escaping. Use this when the plugin already returns HTML or when you know the content is safe.

```mustache
{{{documentText}}}
{{&ocrText}}
```

#### Section Blocks — `{{#key}}...{{/key}}`

Renders the block only if `key` is truthy (non-empty string, non-zero number, non-empty array, or non-false boolean). If `key` is absent or falsy the block is skipped entirely.

```mustache
{{#ocrText}}
### OCR Text
{{ocrText}}
{{/ocrText}}
```

#### Inverted Sections — `{{^key}}...{{/key}}`

The opposite of a section block — renders the block only when `key` is falsy or absent. Useful for fallback content.

```mustache
{{^documentText}}
*No text content was extracted from this file.*
{{/documentText}}
```

#### List Iteration — `{{#list}}...{{/list}}` with `{{.}}`

When `key` is an array, a section block iterates over every item. Inside the block, `{{.}}` refers to the current item. Items can also be objects, in which case their keys are accessed directly.

```mustache
{{#categories}}#{{.}} {{/categories}}
```

For an array value of `["work", "finance", "2024"]` this renders:

```
#work #finance #2024 
```

#### Comments — `{{! comment }}`

Comments are stripped from the rendered output and never appear in the final file.

```mustache
{{! TODO: add summary section once plugin is ready }}
# {{fileName}}
```

---

## Example Workflows

### Personal Document Management

Catalogue all documents in a home folder:

```bash
./doc.doc.sh process -d ~/Documents \
  -i ".pdf,.docx,.txt,.odt" \
  > ~/document-catalogue.json
```

Use `jq` to find all documents over 10 MB:

```bash
cat ~/document-catalogue.json | jq '.[] | select(.fileSize > 10485760) | .filePath'
```

### Home Lab Documentation

Index all configuration files, ignoring backups:

```bash
./doc.doc.sh process -d /etc/homelab \
  -i ".conf,.yaml,.yml,.toml,.ini" \
  -e "**/*.bak" \
  > homelab-config-index.json
```

### OCR a Document Archive

Extract text from PDFs and images in a scanned archive:

```bash
# Ensure ocrmypdf is active
./doc.doc.sh activate --plugin ocrmypdf

# Process only supported OCR types
./doc.doc.sh process -d ~/scanned-archive \
  -i "application/pdf,image/jpeg,image/png,image/tiff" \
  > scanned-archive-ocr.json
```

### Obsidian Integration

Generate a JSON catalogue and use a script to populate Obsidian vault notes:

```bash
./doc.doc.sh process -d ~/vault-source > catalogue.json

# Example: pipe into a Python or Node.js script that reads catalogue.json
# and creates one .md file per entry in your Obsidian vault
python3 scripts/to_obsidian.py < catalogue.json
```

---

## Command Reference

### `process`

Process files in a directory through active plugins.

```
./doc.doc.sh process -d <dir> [-o <dir>] [-t <file>] [-i <criteria>] [-e <criteria>] [--echo]
```

| Flag | Required | Description |
|------|----------|-------------|
| `-d <dir>` | Yes | Input directory to scan recursively |
| `-o <dir>` | No | Output directory for sidecar `.md` files; required unless `--echo` |
| `-t <file>` | No | Mustache template file (defaults to `doc.doc.md/templates/default.md`) |
| `-i <criteria>` | No | Include criteria (repeatable) |
| `-e <criteria>` | No | Exclude criteria (repeatable) |
| `-b <dir>` | No | Base path for computing relative file references in rendered output |
| `--echo` | No | Print rendered markdown to stdout instead of writing files (dry-run); mutually exclusive with `-o` |
| `--progress` | No | Force progress display even when stdout is not a TTY |
| `--no-progress` | No | Suppress progress display even on a TTY |
| `--help` | No | Show help |

**Output:** JSON array to stdout (suppressed when stdout is a TTY and `-o` is given; human-readable summary on stderr instead — see [What the Output Looks Like](#what-the-output-looks-like)).

---

### `list`

```
./doc.doc.sh list plugins [active|inactive]
./doc.doc.sh list --plugin <name> --commands
./doc.doc.sh list parameters
./doc.doc.sh list --plugin <name> --parameters
```

| Form | Description |
|------|-------------|
| `list plugins` | All plugins with `[active]`/`[inactive]` labels |
| `list plugins active` | Active plugins only |
| `list plugins inactive` | Inactive plugins only |
| `list --plugin <name> --commands` | Commands declared by a specific plugin |
| `list parameters` | All input/output parameters for every plugin |
| `list --plugin <name> --parameters` | Input/output parameters for a specific plugin |

---

### `activate` / `deactivate`

```
./doc.doc.sh activate --plugin <name>
./doc.doc.sh deactivate --plugin <name>
```

Short form: `-p <name>`

---

### `install`

```
./doc.doc.sh install --plugin <name>
./doc.doc.sh install plugins --all
```

Runs the plugin's `install.sh`. Idempotent — skips already-installed plugins.

---

### `installed`

```
./doc.doc.sh installed --plugin <name>
```

Exit codes: `0` = installed, `1` = not installed, `2` = plugin not found or error.

---

### `tree`

```
./doc.doc.sh tree
```

Renders a dependency tree of all plugins. Active = green, inactive = red.

---

### `run`

Invoke any command declared in a plugin's `descriptor.json` directly from the CLI.

```
./doc.doc.sh run <pluginName> <commandName> [--plugin-storage <dir>] [--file <path>] [--category <name>] [-- key=value...]
./doc.doc.sh run --help
./doc.doc.sh run <pluginName> --help
```

| Form | Description |
|------|-------------|
| `run <plugin> <command>` | Execute the named command from the plugin's descriptor |
| `run <plugin> <command> --file <path>` | Pass a file path to the command |
| `run <plugin> <command> -- key=value` | Pass arbitrary key/value pairs to the command |
| `run --help` | Show run command help |
| `run <plugin> --help` | List commands available in the specified plugin |

Use `./doc.doc.sh run <plugin> --help` to see commands available in a plugin, or `./doc.doc.sh list --plugin <name> --commands` to list them.

Use `./doc.doc.sh list --plugin <name> --commands` to discover commands available in a plugin.

---

## FAQ

**Do I need to install plugins before activating them?**

Yes. A plugin can be active but not have its external dependencies available. Run `./doc.doc.sh install --plugin <name>` before activating. For the built-in `file` and `stat` plugins, the dependencies (`file` and `stat` commands) are almost always pre-installed on Linux and macOS.

**What happens if a plugin fails on a file?**

Plugin failures are handled with graceful degradation — the pipeline continues without that plugin's output for the affected file. The exception is the `file` plugin: if it fails and MIME filter criteria are active, the file is silently skipped (fail-closed behaviour).

**Can I use doc.doc.md on a single file?**

No — the tool processes directories. To process a single file, put it in a temporary directory:

```bash
mkdir /tmp/single && cp myfile.pdf /tmp/single
./doc.doc.sh process -d /tmp/single
rm -rf /tmp/single
```

**Why does my `.pdf` file have `mimeType: text/plain`?**

The `file` plugin detects MIME type by content, not extension. A file named `.pdf` that actually contains plain text will be reported as `text/plain`. This is intentional — it reflects the true nature of the file.

**Why does `-e ".log" -e "**/temp/**"` keep some `.log` files?**

Multiple `-e` flags are ANDed: a file is excluded only if it matches criteria from **all** exclude flags. A `.log` file outside a `temp` directory matches the first exclude but not the second, so it is kept. Use `-e ".log"` alone to exclude all `.log` files regardless of location.

**The `ocrmypdf` plugin is active but I'm getting an error about it not being installed.**

Install its system dependencies:

```bash
./doc.doc.sh install --plugin ocrmypdf
```

If that reports success but OCR still fails, verify `ocrmypdf` is on your PATH:

```bash
which ocrmypdf
ocrmypdf --version
```

On Ubuntu/Debian: `sudo apt install ocrmypdf`

**Does doc.doc.md modify my original files?**

The built-in plugins (`file`, `stat`, `ocrmypdf`) only read files and never modify them. The `ocrmypdf` plugin uses a temporary directory for sidecar text extraction and cleans it up on exit. Third-party plugins are not bound by this guarantee — they execute with your user permissions and can read, write, or delete files. Always review third-party plugin code before use (see [Plugin Security](#plugin-security)).
