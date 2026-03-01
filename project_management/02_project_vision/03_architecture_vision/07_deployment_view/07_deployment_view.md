# Deployment View

## Infrastructure Overview

The doc.doc.md tool is deployed as a standalone command-line application on Unix/Linux systems. No server infrastructure, network services, or databases are required.

## Deployment Scenario: Single-User Workstation

```
┌─────────────────────────────────────────────────┐
│         User's Workstation (Linux/macOS)        │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │         Operating System                  │  │
│  │  • Bash 4.0+                              │  │
│  │  • Python 3.7+                            │  │
│  │  • Standard Unix utilities (find, file)   │  │
│  └───────────────────────────────────────────┘  │
│                      │                          │
│  ┌───────────────────────────────────────────┐  │
│  │      doc.doc.md Installation              │  │
│  │                                           │  │
│  │  /usr/local/bin/                          │  │
│  │  └─ doc.doc.sh (symlink or copy)          │  │
│  │                                           │  │
│  │  /usr/local/share/doc.doc.md/             │  │
│  │  ├─ doc.doc.sh (main script)              │  │
│  │  ├─ components/                           │  │
│  │  │  ├─ help.sh                            │  │
│  │  │  ├─ logging.sh                         │  │
│  │  │  ├─ plugins.sh                         │  │
│  │  │  └─ templates.sh                       │  │
│  │  ├─ plugins/                              │  │
│  │  │  ├─ file/                              │  │
│  │  │  │  ├─ descriptor.json                 │  │
│  │  │  │  ├─ main.sh                         │  │
│  │  │  │  └─ install.sh                      │  │
│  │  │  └─ stat/                              │  │
│  │  │     ├─ descriptor.json                 │  │
│  │  │     ├─ main.sh                         │  │
│  │  │     └─ install.sh                      │  │
│  │  └─ templates/                            │  │
│  │     └─ default.md                         │  │
│  └───────────────────────────────────────────┘  │
│                      │                          │
│  ┌───────────────────────────────────────────┐  │
│  │       User Configuration (Optional)       │  │
│  │                                           │  │
│  │  ~/.config/doc.doc.md/                    │  │
│  │  ├─ active_plugins.txt                    │  │
│  │  └─ custom_templates/                     │  │
│  └───────────────────────────────────────────┘  │
│                      │                          │
│  ┌───────────────────────────────────────────┐  │
│  │         User Data Directories             │  │
│  │                                           │  │
│  │  /home/user/documents/  ← Input           │  │
│  │  /home/user/markdown/   ← Output          │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

## Installation Methods

### Method 1: System-Wide Installation (Recommended)

```bash
# Clone or download
git clone <repository> /tmp/doc.doc.md
cd /tmp/doc.doc.md

# Install to system directories (requires sudo)
sudo cp -r doc.doc.md /usr/local/share/
sudo ln -s /usr/local/share/doc.doc.md/doc.doc.sh /usr/local/bin/doc.doc.sh

# Verify installation
doc.doc.sh --help
```

**Location**:
- Binaries: `/usr/local/bin/`
- Application files: `/usr/local/share/doc.doc.md/`

**Advantages**:
- Available to all users
- In system PATH
- Standard Unix file hierarchy

### Method 2: User-Local Installation

```bash
# Clone or download
git clone <repository> ~/bin/doc.doc.md
cd ~/bin/doc.doc.md

# Make executable
chmod +x doc.doc.sh

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$PATH:$HOME/bin/doc.doc.md"

# Verify installation
doc.doc.sh --help
```

**Location**:
- Application files: `~/bin/doc.doc.md/`

**Advantages**:
- No sudo required
- User-specific installation
- Easy to modify/customize

### Method 3: Portable Installation

```bash
# Download and extract anywhere
unzip doc.doc.md.zip -d /path/to/location

# Run directly
/path/to/location/doc.doc.md/doc.doc.sh --help
```

**Advantages**:
- Maximum flexibility
- Multiple versions possible
- No installation required

## Runtime Requirements

### Mandatory Dependencies

| Component | Version | Check Command | Purpose |
|-----------|---------|---------------|---------|
| **Bash** | 4.0+ | `bash --version` | Main shell interpreter |
| **Python** | 3.7+ | `python3 --version` | Filter engine and complex logic |
| **find** | GNU findutils or BSD | `find --version` | File discovery |
| **file** | Any | `file --version` | MIME type detection (via plugin) |

### Optional Dependencies

Depending on active plugins:
- Additional command-line tools
- Python packages (via plugin requirements)
- External binaries

### Verification Script

```bash
# Check all prerequisites
doc.doc.sh --check-requirements

# Output:
# ✓ Bash 5.0.17 (required: 4.0+)
# ✓ Python 3.9.7 (required: 3.7+)
# ✓ find (GNU findutils 4.8.0)
# ✓ file 5.40
# 
# All requirements met!
```

## Configuration Files

### System Configuration (Optional)

**Location**: `/etc/doc.doc.md/config`

```bash
# System-wide defaults
DEFAULT_TEMPLATE="/usr/local/share/doc.doc.md/templates/default.md"
PLUGIN_PATH="/usr/local/share/doc.doc.md/plugins"
LOG_LEVEL="INFO"
```

### User Configuration (Optional)

**Location**: `~/.config/doc.doc.md/config`

```bash
# User overrides
PLUGIN_PATH="$HOME/.local/share/doc.doc.md/plugins"
CUSTOM_TEMPLATE="$HOME/.config/doc.doc.md/templates/my_template.md"
```

### Active Plugins List

**Location**: `~/.config/doc.doc.md/active_plugins.txt`

```
file
stat
```

## Directory Structure Conventions

### Standard Locations

| Purpose | System-Wide | User-Local |
|---------|------------|------------|
| **Binaries** | `/usr/local/bin/` | `~/bin/` |
| **Application** | `/usr/local/share/doc.doc.md/` | `~/bin/doc.doc.md/` |
| **Configuration** | `/etc/doc.doc.md/` | `~/.config/doc.doc.md/` |
| **User Data** | N/A | `~/.local/share/doc.doc.md/` |
| **Plugins** | `/usr/local/share/doc.doc.md/plugins/` | `~/.local/share/doc.doc.md/plugins/` |
| **Templates** | `/usr/local/share/doc.doc.md/templates/` | `~/.config/doc.doc.md/templates/` |

## Cross-Platform Considerations

### Linux

- Standard deployment target
- All features supported
- Use package managers for distribution (future: .deb, .rpm)

### macOS

- Fully supported
- Use Homebrew for distribution (future)
- BSD versions of utilities (find, sed) have slight differences
- Ensure POSIX compliance in scripts

### Windows (WSL/Git Bash)

- Supported via Windows Subsystem for Linux (WSL)
- Git Bash provides minimal Unix environment
- Some features may require WSL for full functionality
- Not primary target, best-effort support

## Update/Upgrade Process

### Manual Update

```bash
# Pull latest version
cd /usr/local/share/doc.doc.md
sudo git pull origin main

# Verify
doc.doc.sh --version
```

### Future: Package Manager

```bash
# Using package manager (future)
sudo apt update && sudo apt upgrade doc.doc.md
# or
brew upgrade doc.doc.md
```

## Uninstallation

```bash
# System-wide
sudo rm /usr/local/bin/doc.doc.sh
sudo rm -rf /usr/local/share/doc.doc.md
sudo rm -rf /etc/doc.doc.md

# User configuration (optional)
rm -rf ~/.config/doc.doc.md
rm -rf ~/.local/share/doc.doc.md
```
