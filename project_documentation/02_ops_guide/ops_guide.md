# Operations Guide

## Table of Contents

- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Plugin Management](#plugin-management)
- [Configuration](#configuration)
- [Running the Tool](#running-the-tool)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

---

## System Requirements

### Runtime Dependencies

| Dependency | Minimum Version | Role |
|------------|----------------|------|
| Bash | 4.0+ | CLI orchestration, plugin execution, pipeline coordination |
| jq | any current | JSON parsing in all plugin scripts and the main CLI |
| Python | 3.12+ | Filter engine (`doc.doc.md/components/filter.py`) |
| `file` command | any current | MIME type detection (required by the `file` plugin) |
| `stat` command | any current | File statistics (required by the `stat` plugin) |

### Optional Dependencies (for `ocrmypdf` plugin)

| Dependency | Notes |
|------------|-------|
| `ocrmypdf` | OCR processing for PDFs and images |
| `pdftotext` (poppler-utils) | Fast text extraction from PDFs with an existing text layer; falls back to OCRmyPDF if absent |
| `python3-pillow` (Pillow) | Alpha channel detection and conversion for RGBA images before OCR |

### Operating System

Linux and macOS are supported. The `stat` plugin detects the platform at runtime and uses the appropriate `stat` format specifiers.

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/PeculiarMind/doc.doc.md.git
cd doc.doc.md
```

### 2. Make the Script Executable

```bash
chmod +x doc.doc.sh
```

### 3. Verify Prerequisites

Check that all required tools are available:

```bash
bash --version          # Bash 4.0+
jq --version            # any
python3 --version       # 3.12+
file --version          # any
```

### 4. Install Plugin Dependencies

Install dependencies for all plugins at once:

```bash
./doc.doc.sh install plugins --all
```

Or check and install individually:

```bash
./doc.doc.sh installed --plugin file    # check
./doc.doc.sh installed --plugin stat    # check
./doc.doc.sh install --plugin ocrmypdf  # install optional OCR plugin
```

### 5. Verify the Installation

```bash
./doc.doc.sh --help
./doc.doc.sh list plugins
```

### Development Container

A VS Code Dev Container configuration is included. Open the repository in VS Code and select **Reopen in Container** to get a pre-configured environment.

---

## Plugin Management

Plugins are stored under `doc.doc.md/plugins/<plugin-name>/`. Each plugin has a `descriptor.json` that controls its active state and declares its commands.

### Listing Plugins

```bash
./doc.doc.sh list plugins            # all plugins with [active]/[inactive] status
./doc.doc.sh list plugins active     # active plugins only
./doc.doc.sh list plugins inactive   # inactive plugins only
```

### Inspecting Plugin Commands

```bash
./doc.doc.sh list --plugin stat --commands
./doc.doc.sh list --plugin ocrmypdf --commands
```

### Activating and Deactivating Plugins

Activation sets `"active": true` in the plugin's `descriptor.json`. Deactivation sets it to `false`. Active plugins are included in every `process` run; inactive ones are skipped.

```bash
./doc.doc.sh activate --plugin ocrmypdf       # enable OCR processing
./doc.doc.sh deactivate --plugin ocrmypdf     # disable without uninstalling
```

The `file` plugin **must remain active**; deactivating it will cause `process` to fail.

### Installing Plugin Dependencies

```bash
./doc.doc.sh install --plugin <name>      # single plugin
./doc.doc.sh install plugins --all        # all plugins
```

`install` is idempotent — already-installed plugins are skipped.

### Checking Installation Status

```bash
./doc.doc.sh installed --plugin stat
```

Exit codes: `0` = installed, `1` = not installed, `2` = plugin not found.

### Plugin Dependency Tree

```bash
./doc.doc.sh tree
```

Displays a tree with active plugins in green and inactive plugins in red. Plugins listed as dependencies appear as children under the plugins that require them.

---

## Configuration

doc.doc.md has **no configuration files**. All behaviour is controlled by CLI flags at runtime. Plugin active/inactive state is the only persistent setting and is stored in each plugin's `descriptor.json`.

---

## Running the Tool

### Syntax

```
./doc.doc.sh process -d <input-dir> [-i <criteria>] [-e <criteria>]
```

### Required Flags

| Flag | Description |
|------|-------------|
| `-d <dir>` | Input directory to process (must exist and be readable) |

### Optional Flags

| Flag | Description |
|------|-------------|
| `-i <criteria>` | Include criteria (repeatable; values comma-separated) |
| `-e <criteria>` | Exclude criteria (repeatable; values comma-separated) |

### Output

`process` writes a JSON array to **stdout**. Each element contains the file path and all fields produced by active plugins:

```json
[
  {
    "filePath": "/docs/2024/report.pdf",
    "mimeType": "application/pdf",
    "fileSize": 204800,
    "fileOwner": "alice",
    "fileCreated": "2024-01-15T09:30:00Z",
    "fileModified": "2024-03-01T14:22:10Z",
    "fileMetadataChanged": "2024-03-01T14:22:10Z"
  }
]
```

Empty input directory or a filter that matches nothing returns `[]`.

### Basic Examples

```bash
# Process all files
./doc.doc.sh process -d /path/to/documents

# Include only PDFs
./doc.doc.sh process -d /path/to/documents -i ".pdf"

# Exclude log files and temp directories
./doc.doc.sh process -d /path/to/documents -e ".log" -e "**/temp/**"

# MIME type filter — include only plain text
./doc.doc.sh process -d /path/to/documents -i "text/plain"

# Combine extension and MIME filters (AND logic)
./doc.doc.sh process -d /path/to/documents \
  -i ".pdf,application/pdf" \
  -i "**/2024/**" \
  -e "**/drafts/**"
```

### Filter Criteria Types

| Format | Example | Matched against |
|--------|---------|----------------|
| File extension | `.pdf` | File path suffix |
| Glob pattern | `**/2024/**` | Full file path |
| MIME type | `application/pdf` | MIME type from `file` plugin |
| MIME wildcard | `image/*` | MIME type prefix |

**Detection rule**: criteria containing `/` but not `**` are treated as MIME criteria; all others are path/extension criteria.

### Filter Logic

- Values within a single `-i` are **ORed** (file matches if it satisfies at least one)
- Multiple `-i` flags are **ANDed** (file must satisfy at least one criterion from each flag)
- Same logic applies to `-e` flags
- Include filters run first to build the candidate set; exclude filters reduce it
- MIME filters are evaluated as a gate after the `file` plugin runs on each file

---

## Troubleshooting

### "No active plugins found"

All plugins are inactive. Activate at least the `file` plugin:

```bash
./doc.doc.sh activate --plugin file
./doc.doc.sh activate --plugin stat
```

### "file plugin must be active and installed"

The `file` plugin is either deactivated or its dependency (`file` command) is not available.

```bash
./doc.doc.sh activate --plugin file
./doc.doc.sh install --plugin file
```

On Debian/Ubuntu: `sudo apt-get install file`  
On macOS: `brew install file`

### "Plugin is active but not installed"

The plugin's `installed.sh` reported `false`. Run the install command:

```bash
./doc.doc.sh install --plugin <name>
```

### "Filter engine not found"

`doc.doc.md/components/filter.py` is missing. This means the repository is incomplete. Re-clone or restore the file from version control.

### "Error: Input directory does not exist"

The path passed to `-d` does not exist or is not a directory. Verify the path:

```bash
ls -la /path/to/documents
```

### Processing Fails for a Specific File

Plugin failures during `process` are handled with graceful degradation — the pipeline continues with partial results for that file. Only `file` plugin failures with active MIME criteria cause the file to be silently skipped.

Check stderr for plugin error messages:

```bash
./doc.doc.sh process -d /path/to/documents 2>errors.log
cat errors.log
```

### MIME Filter Silently Skips Files

Files that do not match an active MIME filter are silently excluded — no error, no output entry. This is by design. To debug, run without MIME filters first and inspect the `mimeType` field in the JSON output to understand what types are present.

### Output Is Not Valid JSON

If the output is malformed, a plugin is likely writing non-JSON to stdout. Run `installed` to verify plugin health:

```bash
./doc.doc.sh installed --plugin file
./doc.doc.sh installed --plugin stat
```

---

## Security Considerations

### Plugin Trust Model

Plugins are shell scripts executed with the same user privileges as the `doc.doc.md` process. **Only install plugins you trust.** Third-party plugins have full access to any file path passed to them.

Activation does not install a plugin; installation and activation are separate steps. A plugin can be present in the plugin directory but inactive (and therefore never executed).

### Path Traversal Protections

All built-in plugins (`file`, `stat`, `ocrmypdf`) resolve symlinks with `readlink -f` and validate the canonical path before processing. Paths that resolve into `/proc`, `/dev`, `/sys`, or `/etc` are rejected. File readability is checked before any system command is invoked on the path.

### Input Size Limit

All plugins limit stdin reads to 1 MB (`head -c 1048576`) to prevent memory exhaustion from oversized or malformed JSON input.

### MIME Gate for Input Validation

When MIME-type filter criteria are present, the `file` plugin runs first for every candidate file. A file is processed further only if its detected MIME type passes the filter. This provides a content-based validation gate in addition to path-based filtering. If the `file` plugin itself cannot run (not installed, inaccessible file), MIME-gated files are skipped — the system fails closed.

### Principle of Least Privilege

Run doc.doc.md with the minimum permissions needed to read the input directory. Do not run as root unless the input directory requires it.
