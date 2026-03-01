# Runtime View

## Process Command Workflow

This is the primary workflow for document processing.

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. User Invocation                                               │
│    doc.doc.sh process -d /input -o /output -i ".pdf,.txt"        │
└────────────┬─────────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────────┐
│ 2. CLI Argument Parsing (doc.doc.sh)                             │
│    • Parse command and options                                   │
│    • Validate required parameters (input/output dirs)            │
│    • Extract filter criteria (include/exclude)                   │
│    • Load template path or use default                           │
└────────────┬─────────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────────┐
│ 3. Plugin Discovery & Preparation (components/plugins.sh)        │
│    • Scan plugin directory for descriptor.json files             │
│    • Load active plugin list                                     │
│    • Resolve plugin dependencies                                 │
│    • Determine execution order for each file type                │
└────────────┬─────────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────────┐
│ 4. File Discovery (Unix find + Python filter)                    │
│    • find /input -type f                                         │
│    • Pipe to Python filter engine                                │
│    • Apply AND/OR logic for include/exclude                      │
│    • Evaluate file extensions, globs, MIME types                 │
│    • Output: Stream of matching file paths                       │
└────────────┬─────────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────────┐
│ 5. Process Each File (loop)                                      │
│    For each file in filtered list:                               │
│    • Determine file type                                         │
│    • Select applicable plugins based on type                     │
│    • Execute plugins in dependency order                         │
│    • Collect plugin outputs                                      │
│    • Apply template with collected data                          │
│    • Write markdown to output (mirrored path)                    │
└────────────┬─────────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────────┐
│ 6. Completion & Reporting                                        │
│    • Display summary (files processed, errors)                   │
│    • Exit with appropriate status code                           │
└──────────────────────────────────────────────────────────────────┘
```

### Detailed Step Breakdown

#### Step 4: File Discovery & Filtering

```
find /input -type f -print0 | python3 filter.py --include=".pdf,.txt" --include="**/2024/**"
                                                 --exclude=".log" --exclude="**/temp/**"
```

The Python filter engine:
1. Receives file paths from stdin
2. For each file:
   - Extract extension, path, MIME type
   - Check against each include parameter (OR within, AND between)
   - Check against each exclude parameter (OR within, AND between)
   - Include rules: file must match (at least one from param1) AND (at least one from param2)
   - Exclude rules: file excluded if (matches one from param1) AND (matches one from param2)
3. Outputs matching paths to stdout

#### Step 5: Plugin Execution Chain

```
For file: /input/docs/2024/report.pdf
│
├─ Determine MIME type (via 'file' plugin): application/pdf
│
├─ Select plugins for PDF:
│  ├─ stat plugin (provides file metadata)
│  └─ file plugin (provides MIME type)
│
├─ Execute plugins in order:
│  ├─ stat plugin → {fileSize, modifiedDate, permissions}
│  └─ file plugin → {mimeType, mimeDescription}
│
├─ Merge plugin outputs into data structure
│
├─ Apply template (default.md):
│  Replace {{filePath}}, {{fileSize}}, {{mimeType}}, etc.
│
└─ Write to: /output/docs/2024/report.md
```

## Plugin Management Workflows

### List Plugins Workflow

```
┌────────────────────────────────┐
│ doc.doc.sh list plugins        │
│                [active]         │
│                [inactive]       │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│ components/plugins.sh          │
│ • Scan plugin directory        │
│ • Read descriptor.json files   │
│ • Check activation status      │
│ • Apply filter (if specified)  │
│ • Format output                │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│ Display plugin list            │
│ plugin_name  [ACTIVE]          │
│ other_plugin [INACTIVE]        │
└────────────────────────────────┘
```

### Activate Plugin Workflow

```
┌────────────────────────────────┐
│ doc.doc.sh activate -p stat    │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│ components/plugins.sh          │
│ • Validate plugin exists       │
│ • Check dependencies installed │
│ • Mark as active               │
│ • Update active plugins list   │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│ Success: Plugin 'stat' activated│
└────────────────────────────────┘
```

### Install Plugin Workflow

```
┌────────────────────────────────┐
│ doc.doc.sh install -p myplugin │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│ components/plugins.sh          │
│ • Read plugin descriptor       │
│ • Check system prerequisites   │
│ • Run install.sh script        │
│ • Verify installation          │
│ • Register plugin              │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│ Success: Plugin 'myplugin'     │
│ installed successfully         │
└────────────────────────────────┘
```

## Plugin Lifecycle

```
┌─────────────┐
│  AVAILABLE  │ ← Plugin descriptor exists in plugin directory
└──────┬──────┘
       │ install (if dependencies needed)
       ▼
┌─────────────┐
│  INSTALLED  │ ← All dependencies met, install.sh executed
└──────┬──────┘
       │ activate
       ▼
┌─────────────┐
│   ACTIVE    │ ← Plugin included in processing chain
└──────┬──────┘
       │ deactivate
       ▼
┌─────────────┐
│  INACTIVE   │ ← Plugin ignored during processing
└─────────────┘
```

## Tree View Workflow

```
┌────────────────────────────────┐
│ doc.doc.sh tree                │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│ components/plugins.sh          │
│ • Load all plugins             │
│ • Parse dependencies           │
│ • Build dependency graph       │
│ • Determine activation status  │
│ • Generate tree visualization  │
│ • Apply color coding           │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│ Plugin Dependency Tree         │
│                                │
│ ├─ 🟢 stat (ACTIVE)            │
│ ├─ 🟢 file (ACTIVE)            │
│ └─ 🔴 custom (INACTIVE)        │
│    └─ depends: external-tool   │
└────────────────────────────────┘
```

## Error Handling Patterns

### Invalid Input Directory

```
User: doc.doc.sh process -d /nonexistent -o /output
  │
  ├─ Validate input directory exists
  │
  └─ ERROR: Input directory '/nonexistent' does not exist
     Exit code: 1
```

### Plugin Dependency Not Met

```
User: doc.doc.sh activate -p myplugin
  │
  ├─ Check plugin exists
  ├─ Verify dependencies
  │
  └─ ERROR: Plugin 'myplugin' requires 'external-tool' which is not installed
     Hint: Run 'doc.doc.sh install -p myplugin' first
     Exit code: 2
```

### Filter Syntax Error

```
User: doc.doc.sh process -d /input -o /output -i "[invalid"
  │
  ├─ Parse filter arguments
  ├─ Validate glob patterns
  │
  └─ ERROR: Invalid glob pattern '[invalid' in --include
     Exit code: 3
```
