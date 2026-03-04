# Deployment View

## Overview

doc.doc.md is a standalone command-line application. No server, network services, or database are required. It runs directly on a user's workstation or server.

## Deployment Scenarios

### Single-User Workstation (Primary Target)

```
┌─────────────────────────────────────────────────┐
│         User's Workstation (Linux/macOS)        │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │         Operating System                  │  │
│  │  • Bash 4.0+                              │  │
│  │  • Python 3.12+                           │  │
│  │  • find, file, stat, jq                   │  │
│  └───────────────────────────────────────────┘  │
│                      │                          │
│  ┌───────────────────────────────────────────┐  │
│  │      doc.doc.md Installation              │  │
│  │                                           │  │
│  │  doc.doc.sh          ← main entry point   │  │
│  │  doc.doc.md/                              │  │
│  │  ├─ components/                           │  │
│  │  │  ├─ plugins.sh                         │  │
│  │  │  ├─ filter.py                          │  │
│  │  │  ├─ help.sh                            │  │
│  │  │  ├─ logging.sh                         │  │
│  │  │  └─ templates.sh                       │  │
│  │  └─ plugins/                              │  │
│  │     ├─ file/   (descriptor.json + *.sh)   │  │
│  │     ├─ stat/   (descriptor.json + *.sh)   │  │
│  │     └─ ocrmypdf/ (descriptor.json + *.sh) │  │
│  └───────────────────────────────────────────┘  │
│                      │                          │
│  ┌───────────────────────────────────────────┐  │
│  │         User Data Directories             │  │
│  │  /home/user/documents/  ← Input           │  │
│  │  /home/user/output/     ← Output (future) │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

## Installation Methods

### Method 1: System-Wide Installation (Recommended)

```bash
git clone <repository> /tmp/doc.doc.md
cd /tmp/doc.doc.md
sudo cp -r . /usr/local/share/doc.doc.md
sudo ln -s /usr/local/share/doc.doc.md/doc.doc.sh /usr/local/bin/doc.doc.sh
doc.doc.sh --help
```

| Location | Path |
|----------|------|
| Binaries | `/usr/local/bin/` |
| Application files | `/usr/local/share/doc.doc.md/` |

### Method 2: User-Local Installation

```bash
git clone <repository> ~/bin/doc.doc.md
chmod +x ~/bin/doc.doc.md/doc.doc.sh
export PATH="$PATH:$HOME/bin/doc.doc.md"
doc.doc.sh --help
```

### Method 3: Portable (Run in Place)

```bash
git clone <repository> /any/path/doc.doc.md
/any/path/doc.doc.md/doc.doc.sh --help
```

No installation required; run directly from the cloned directory.

## Runtime Requirements

### Mandatory

| Component | Minimum Version | Purpose |
|-----------|----------------|---------|
| Bash | 4.0+ | Main script execution |
| Python | 3.12+ | `filter.py` filter engine |
| `find` | POSIX | File discovery |
| `file` | Any | MIME detection (via `file` plugin) |
| `stat` | Any (Linux/macOS) | File metadata (via `stat` plugin) |
| `jq` | Any | JSON handling in plugin scripts |

### Optional (Plugin-Specific)

| Component | Required by | Purpose |
|-----------|------------|---------|
| `ocrmypdf` | `ocrmypdf` plugin | OCR processing of PDFs and images |

## Configuration

### Plugin Activation State

Plugin activation is persisted by modifying the `active` field in each plugin's `descriptor.json`. No separate configuration file is needed for the current implementation.

### Template Resolution Order

1. User-specified via `--template` flag.
2. `~/.config/doc.doc.md/templates/default.md` (user override).
3. Built-in template shipped with the application.

### Standard Directory Locations

| Purpose | System-Wide | User-Local |
|---------|------------|------------|
| Binaries | `/usr/local/bin/` | `~/bin/` |
| Application | `/usr/local/share/doc.doc.md/` | `~/bin/doc.doc.md/` |
| Configuration | `/etc/doc.doc.md/` (future) | `~/.config/doc.doc.md/` |
| Plugins | `<app_dir>/doc.doc.md/plugins/` | `~/.local/share/doc.doc.md/plugins/` (future) |
| Templates | `<app_dir>/doc.doc.md/templates/` | `~/.config/doc.doc.md/templates/` |

## Cross-Platform Notes

| Platform | Support | Notes |
|----------|---------|-------|
| Linux | Full | Primary target; all features supported. |
| macOS | Full | `stat` plugin detects macOS via `uname -s` and uses BSD `stat` flags. `file` plugin uses portable flags. |
| Windows (WSL) | Best-effort | Core features work under WSL; native Windows not supported. |

## Update Process

```bash
# Pull latest version (system-wide)
cd /usr/local/share/doc.doc.md
sudo git pull origin main

# Verify
doc.doc.sh --help
```

## Uninstallation

```bash
# System-wide
sudo rm /usr/local/bin/doc.doc.sh
sudo rm -rf /usr/local/share/doc.doc.md

# User configuration (optional)
rm -rf ~/.config/doc.doc.md
rm -rf ~/.local/share/doc.doc.md
```
