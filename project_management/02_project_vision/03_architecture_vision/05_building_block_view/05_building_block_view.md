# Building Block View

## Level 1: System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      doc.doc.sh System                      │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Main Entry Point (doc.doc.sh)           │   │
│  │  • Command routing                                   │   │
│  │  • Argument parsing                                  │   │
│  │  • Workflow orchestration                            │   │
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

### Responsibilities

| Component | Responsibility |
|-----------|---------------|
| **doc.doc.sh** | CLI entry point, command routing, parameter validation, workflow coordination |
| **Bash Components** | Help system, logging, plugin management, template handling |
| **Python Filter Engine** | Complex include/exclude logic, pattern matching, file filtering |
| **Plugin System** | Extensible processing capabilities, file type handlers, metadata extraction |

## Level 2: Main Entry Point

### doc.doc.sh

**Purpose**: Main command-line interface and orchestration layer.

**Responsibilities**:
1. Parse command-line arguments
2. Validate input parameters
3. Route to appropriate workflow (process, list, activate, etc.)
4. Set up logging and progress indication  
5. Coordinate component and plugin execution
6. Handle errors and provide user feedback

**Interfaces**:
- **Input**: Command-line arguments
- **Output**: Status messages, execution results, exit codes

**Implementation**: Bash script

### Main Workflow (Process Command)

```bash
#!/bin/bash
# doc.doc.sh main workflow

# 1. Parse arguments
parse_arguments "$@"

# 2. Validate parameters
validate_input_directory "$INPUT_DIR"
validate_output_directory "$OUTPUT_DIR"

# 3. Load plugins
source components/plugins.sh
load_active_plugins

# 4. Build file list with filtering
find "$INPUT_DIR" -type f -print0 | \
  python3 components/filter.py \
    --include "$INCLUDE_FILTERS" \
    --exclude "$EXCLUDE_FILTERS" | \
  while IFS= read -r -d $'\0' file; do
    # 5. Process each file
    process_file "$file" "$OUTPUT_DIR"
  done

# 6. Report completion
report_summary
```

## Level 3: Components Detail

### Bash Components (components/)

```
components/
├── help.sh          # Help system
├── logging.sh       # Logging and output
├── plugins.sh       # Plugin management
├── templates.sh     # Template handling
└── filter.py        # Python filter engine
```

#### help.sh

**Purpose**: Provide comprehensive help and usage information.

**Responsibilities**:
- Display command usage
- Show parameter descriptions
- Provide examples
- Context-sensitive help

**Key Functions**:
```bash
show_help()              # Display main help
show_command_help()      # Display help for specific command
show_examples()          # Display usage examples
```

#### logging.sh

**Purpose**: Unified logging and user feedback.

**Responsibilities**:
- Log messages at different levels (ERROR, WARN, INFO, DEBUG)
- Progress indication
- Error reporting
- Status updates

**Key Functions**:
```bash
log_error()             # Log error message
log_warn()              # Log warning message
log_info()              # Log info message
log_debug()             # Log debug message
show_progress()         # Display progress indicator
```

#### plugins.sh

**Purpose**: Plugin lifecycle management.

**Responsibilities**:
- Discover available plugins
- Load plugin descriptors
- Manage activation state
- Install/check plugins
- Resolve plugin dependencies
- Execute plugin chains

**Key Functions**:
```bash
list_plugins()          # List all plugins
list_active_plugins()   # List active plugins
activate_plugin()       # Activate a plugin
deactivate_plugin()     # Deactivate a plugin
install_plugin()        # Install a plugin
check_installed()       # Check if plugin installed
load_plugin_descriptor() # Parse descriptor.json
execute_plugin()        # Run plugin with file
```

**Data Structures**:
```bash
# Plugin registry (associative array)
declare -A PLUGINS
PLUGINS["stat"]="active"
PLUGINS["file"]="active"
PLUGINS["custom"]="inactive"

# Plugin execution order (array)
PLUGIN_ORDER=("stat" "file")
```

#### templates.sh

**Purpose**: Template management and variable substitution.

**Responsibilities**:
- Load templates
- Substitute template variables
- Generate markdown output

**Key Functions**:
```bash
load_template()         # Load template from file
substitute_variables()  # Replace {{var}} with values
generate_output()       # Create markdown file
```

#### filter.py

**Purpose**: Complex file filtering logic.

**Responsibilities**:
- Parse include/exclude parameters
- Evaluate file extensions
- Match glob patterns
- Determine MIME types
- Apply AND/OR logic
- Output matching files

**Interface**:
```python
# Input: stdin (file paths from find)
# Arguments: --include, --exclude (can be specified multiple times)
# Output: stdout (filtered file paths)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--include', action='append', default=[])
    parser.add_argument('--exclude', action='append', default=[])
    args = parser.parse_args()
    
    for file_path in read_stdin():
        if should_process(file_path, args.include, args.exclude):
            print(file_path)
```

## Level 4: Plugin Architecture

### Plugin Structure

Each plugin is self-contained with clear interface:

```
plugins/stat/
├── descriptor.json    # Metadata
├── main.sh           # Entry point
├── install.sh        # Installation script
└── installed.sh      # Check script
```

### Plugin Interface Contract

**Standard Input (JSON via stdin)**:
```json
{
  "filePath": "/input/docs/report.pdf",
  "outputDir": "/output/docs",
  "pluginDataDir": "/tmp/plugin_data"
}
```

**Standard Output (JSON via stdout)**:
```json
{
  "fileSize": 1048576,
  "fileSizeHuman": "1.0 MB",
  "modifiedDate": "2024-02-25",
  "permissions": "rw-r--r--"
}
```

**Exit Codes**:
- 0: Success
- 1: Temporary failure (skip file, continue)
- 2: Fatal error (stop processing)

### Standard Plugins

#### stat Plugin

**Purpose**: Extract file metadata using `stat` command.

**Outputs**:
- fileSize
- fileSizeHuman
- modifiedDate
- createdDate
- permissions
- owner

#### file Plugin

**Purpose**: Determine MIME type using `file` command.

**Outputs**:
- mimeType
- mimeDescription

## Component Interactions

### Process Command Sequence

```
User
  │
  │ doc.doc.sh process -d /input -o /output
  ▼
doc.doc.sh
  │
  ├─▶ help.sh (if --help)
  │
  ├─▶ logging.sh (initialize)
  │
  ├─▶ plugins.sh (load active plugins)
  │
  ├─▶ find + filter.py (get file list)
  │
  └─▶ For each file:
      ├─▶ plugins.sh (execute plugin chain)
      │   ├─▶ stat plugin
      │   ├─▶ file plugin
      │   └─▶ custom plugins
      │
      ├─▶ templates.sh (generate markdown)
      │
      └─▶ logging.sh (report progress)
```

### Plugin Management Sequence

```
User
  │
  │ doc.doc.sh list plugins active
  ▼
doc.doc.sh
  │
  └─▶ plugins.sh
      │
      ├─▶ Scan plugin directory
      ├─▶ Load descriptor.json files
      ├─▶ Check activation state
      └─▶ Display filtered list
```

## Design Decisions

### Bash for Orchestration

**Rationale**: Native CLI interface, direct access to Unix utilities, no compilation needed, familiar to target users.

**Trade-off**: Limited for complex logic (hence Python filter engine).

### Python for Complex Logic

**Rationale**: Superior pattern matching, cleaner AND/OR logic, better maintainability.

**Trade-off**: Additional dependency (but Python widely available).

### Shell-Based Plugin Invocation

**Rationale**: Language-agnostic, simple interface, no tight coupling.

**Trade-off**: Slight overhead vs. native function calls (acceptable for file I/O workload).
