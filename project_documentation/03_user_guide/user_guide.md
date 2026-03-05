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

The command prints a JSON array to stdout. Each entry represents one file and contains all fields produced by the active plugins:

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

---

## Templates

### Current State

doc.doc.md includes a default template at `doc.doc.md/templates/default.md`. Template-based markdown file generation is an upcoming feature. The `process` command currently outputs JSON to stdout, which you can pipe into any template engine or post-processing script.

### Default Template

```markdown
# {{fileName}}

## File Metadata
- **Size**: {{fileSize}} bytes
- **Owner**: {{fileOwner}}
- **Created**: {{fileCreated}}
- **Modified**: {{fileModified}}
- **Metadata Changed**: {{fileMetadataChanged}}
```

### Template Variables

Template variables use `{{variableName}}` syntax in lowerCamelCase. Variable names match the output field names from plugins exactly.

| Variable | Source plugin | Description |
|----------|--------------|-------------|
| `{{mimeType}}` | file | Detected MIME type |
| `{{fileSize}}` | stat | File size in bytes |
| `{{fileOwner}}` | stat | File owner username |
| `{{fileCreated}}` | stat | Creation date |
| `{{fileModified}}` | stat | Last modification date |
| `{{fileMetadataChanged}}` | stat | Last metadata change date |
| `{{ocrText}}` | ocrmypdf | Extracted OCR text |

Custom plugins add their own variables using the same naming convention.

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
./doc.doc.sh process -d <dir> [-i <criteria>] [-e <criteria>]
```

| Flag | Required | Description |
|------|----------|-------------|
| `-d <dir>` | Yes | Input directory to scan recursively |
| `-i <criteria>` | No | Include criteria (repeatable) |
| `-e <criteria>` | No | Exclude criteria (repeatable) |
| `--help` | No | Show help |

**Output:** JSON array to stdout.

---

### `list`

```
./doc.doc.sh list plugins [active|inactive]
./doc.doc.sh list --plugin <name> --commands
```

| Form | Description |
|------|-------------|
| `list plugins` | All plugins with `[active]`/`[inactive]` labels |
| `list plugins active` | Active plugins only |
| `list plugins inactive` | Inactive plugins only |
| `list --plugin <name> --commands` | Commands declared by a specific plugin |

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

No. doc.doc.md reads files but never modifies them. The `ocrmypdf` plugin uses a temporary directory for sidecar text extraction and cleans it up on exit.
