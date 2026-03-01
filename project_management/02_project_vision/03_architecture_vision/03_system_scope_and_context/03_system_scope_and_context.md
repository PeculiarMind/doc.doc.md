# System Scope and Context

## Business Context

```
┌─────────────┐
│    User     │
└──────┬──────┘
       │ Commands (process, list, activate, etc.)
       │ Input: file paths, filters, options
       │ Output: markdown files, status messages
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
       │ Read              │ Write
       ▼                    ▼
┌──────────────┐    ┌──────────────┐
│Input Documents│    │Output Markdown│
│  (Various    │    │  Files (.md)  │
│   Formats)   │    │               │
└──────────────┘    └───────────────┘
```

### External Interfaces

| Interface | Partner | Input | Output |
|-----------|---------|-------|--------|
| **User CLI** | End User | Commands, file paths, filter criteria | Status messages, generated markdown files |
| **Input Documents** | File System | Documents in various formats (PDF, TXT, images, etc.) | N/A |
| **Output Repository** | File System | N/A | Generated markdown files |
| **Plugin Repository** | Plugin Developers | Plugin packages (shell/Python scripts with descriptors) | N/A |
| **Template Files** | Template Authors | Markdown templates | N/A |

## Technical Context

```
┌─────────────────────────────────────────────────────────┐
│                     doc.doc.sh (Main Entry)             │
│                                                         │
│  ┌────────────────────────────────────────────────┐    │
│  │           Bash Orchestration Layer             │    │
│  │  • Argument parsing                            │    │
│  │  • Workflow coordination                       │    │
│  │  • Component/plugin invocation                 │    │
│  └──────────────┬─────────────────────────────────┘    │
│                 │                                       │
│    ┌────────────┼────────────┐                          │
│    ▼            ▼            ▼                          │
│┌──────┐  ┌──────────┐  ┌─────────┐                     │
││Python│  │ Bash     │  │Plugins  │                     │
││Filter│  │Components│  │(Various)│                     │
││Engine│  │          │  │         │                     │
│└──────┘  └──────────┘  └─────────┘                     │
└─────────────────────────────────────────────────────────┘
         │              │             │
         ▼              ▼             ▼
┌──────────────┐  ┌──────────┐  ┌───────────┐
│ Python Libs  │  │ Unix     │  │ External  │
│ (pathlib,    │  │ Utils    │  │ Tools     │
│  fnmatch)    │  │ (find,   │  │ (file,    │
│              │  │  grep)   │  │  custom)  │
└──────────────┘  └──────────┘  └───────────┘
```

### Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Main CLI** | Bash (POSIX-compliant) | Entry point, orchestration, user interaction |
| **Filter Engine** | Python 3.12+ | Complex include/exclude logic, pattern matching |
| **File Discovery** | Unix `find` | Efficient directory traversal |
| **MIME Detection** | Unix `file` command (via plugin) | File type identification |
| **Plugin System** | Bash + descriptor.json | Extensible processing capabilities |
| **Template Engine** | Bash text substitution (initial) | Markdown generation |

### Key Dependencies

- **Operating System**: Linux or macOS (or Windows with WSL/Git Bash)
- **Bash**: Version 4.0+
- **Python**: Version 3.7+ (standard library only)
- **Unix Utilities**: find, file, grep, sed, awk
- **Plugin Dependencies**: As specified by individual plugins

### Data Flow

1. **Input Phase**: User provides command, input directory, filters, and options
2. **Discovery Phase**: System identifies files matching filter criteria
3. **Processing Phase**: Each matched file processed through active plugin chain
4. **Output Phase**: Generated markdown written to output directory (mirrored structure)
5. **Feedback Phase**: Status, progress, and completion messages to user
