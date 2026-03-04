# Constraints

## Technical Constraints

| ID | Constraint | Applied |
|----|------------|---------|
| **TC-1** | **Unix/Linux Environment** — Primary target is Linux and macOS. Windows supported only via WSL or Git Bash. | ✅ Implemented using POSIX utilities and Bash. |
| **TC-2** | **Bash as Primary Language** — Main orchestration and CLI interface implemented in Bash. | ✅ `doc.doc.sh` (1027 lines) is the Bash entry point. Components (`plugins.sh`, `help.sh`, etc.) are Bash scripts. |
| **TC-3** | **Python 3.12+ for Complex Logic** — Complex filtering and data processing implemented in Python. | ✅ `filter.py` implements include/exclude logic using `pathlib`, `fnmatch`, and `subprocess`. Python 3.12+ required (Ubuntu 24.04+ / Debian 13+). |
| **TC-4** | **Standard Unix Utilities** — Rely on POSIX-compliant utilities (`find`, `file`, `stat`, `jq`). | ✅ `find` for discovery; `file` command via `file` plugin; `stat` command via `stat` plugin; `jq` for JSON parsing in plugin scripts. |
| **TC-5** | **Minimal External Dependencies** — Minimize dependencies beyond standard Unix utilities and Python standard library. | ✅ Core system uses only Bash built-ins, standard Unix utilities, and Python standard library. Plugin-specific dependencies (e.g., `ocrmypdf`) are managed per-plugin. |
| **TC-6** | **Shell-Based Plugin Invocation** — Plugins invoked as shell commands, not direct imports. | ✅ Plugins are executed via shell command strings defined in `descriptor.json`; communication is JSON over stdin/stdout. |

## Organizational Constraints

| ID | Constraint | Applied |
|----|------------|---------|
| **OC-1** | **Open Source** — Project maintained under permissive open-source license. | ✅ See `LICENSE.md`. |
| **OC-2** | **Single Developer** — Initially maintained by a single developer; architecture must be understandable by newcomers. | ✅ Clear separation of concerns; comprehensive Arc42 documentation. |
| **OC-3** | **Documentation Requirements** — Comprehensive documentation required for users and plugin developers. | ✅ Arc42 architecture docs; `README.md`; inline code comments. |

## Conventions

| ID | Convention | Applied |
|----|------------|---------|
| **CV-1** | **Arc42 Documentation** — Architecture documented using the Arc42 template structure. | ✅ This document set follows Arc42. |
| **CV-2** | **Markdown for All Docs** — All documentation written in Markdown. | ✅ All documentation files are `.md`. |
| **CV-3** | **POSIX Compliance** — Shell scripts follow POSIX standards where possible. | ✅ `set -euo pipefail`; `command -v` for tool checks; `#!/bin/bash` shebangs. |
| **CV-4** | **Clear Naming** — Commands and options use descriptive names; both long and short parameter forms provided. | ✅ E.g., `--plugin` / `-p`; `--input-directory` / `-d`. |
| **CV-5** | **lowerCamelCase Parameters** — All plugin input/output parameter names and template variables follow lowerCamelCase. | ✅ E.g., `filePath`, `mimeType`, `fileSize`, `fileSizeHuman`. |
