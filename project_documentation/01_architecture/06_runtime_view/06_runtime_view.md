# Runtime View

## Scenario 1: Process Command — End-to-End

```
User: doc.doc.sh process -d /input -i ".pdf,.txt" -i "**/2024/**" -e "image/*"
```

### Step 1 — Argument Parsing and Validation

`doc.doc.sh` parses `-d`, `-i`, `-e` flags. Validates that `/input` exists and is readable. Collects all `-i`/`-e` values into arrays.

### Step 2 — Criterion Classification

Criteria are classified before the processing loop:

- **Path criteria** (`-i ".pdf,.txt"`, `-i "**/2024/**"`): contain no `/`, or contain `**` → sent to `filter.py` as `--include` arguments.
- **MIME criteria** (`-e "image/*"`): contain `/` but not `**` → stored in `_MIME_EXCLUDE_ARGS`; evaluated by the MIME filter gate after the `file` plugin runs.

### Step 3 — Plugin Discovery and Ordering

`discover_plugins()` in `plugins.sh` scans `doc.doc.md/plugins/`, reads each `descriptor.json`, and returns active plugins. `doc.doc.sh` moves the `file` plugin to position 0 in the chain (file-first enforcement).

### Step 4 — File Discovery and Path Filtering

```bash
find /input -type f -print0 | \
  python3 filter.py --include ".pdf,.txt" --include "**/2024/**" -0
```

`filter.py` evaluates each file path:
- Applies OR logic within each `--include` parameter.
- Applies AND logic between multiple `--include` parameters.
- Outputs matching paths (null-delimited).

### Step 5 — Per-File Processing Loop

For each matching file (e.g., `/input/2024/report.pdf`):

```
1. run_plugin "file" {"filePath": "/input/2024/report.pdf"}
   → {"mimeType": "application/pdf"}

2. MIME filter gate (if MIME criteria exist):
   echo "application/pdf" | python3 filter.py --exclude "image/*"
   → "application/pdf" (passes; not excluded)
   → If filtered: return early; no output for this file.

3. run_plugin "stat" {"filePath": "/input/2024/report.pdf"}
   → {"fileSize": 204800, "fileOwner": "user", "fileModified": "2024-06-01T10:00:00Z", ...}

4. run_plugin "ocrmypdf" {"filePath": "/input/2024/report.pdf", "mimeType": "application/pdf"}
   → {"ocrText": "...extracted text..."}

5. Merge all plugin outputs into a single JSON object.
6. Emit merged JSON to stdout.
```

### Step 6 — Completion

Processing completes; summary statistics written to stderr.

---

## Scenario 2: MIME Filter Gate — File Rejected

```
File: /input/photo.jpg  (MIME: image/jpeg)
MIME exclude criteria: "image/*"
```

1. `file` plugin runs → `{"mimeType": "image/jpeg"}`.
2. MIME gate: `echo "image/jpeg" | python3 filter.py --exclude "image/*"` → empty output.
3. `doc.doc.sh` detects empty output → `return 0`; file produces no JSON entry.
4. Processing loop continues with next file.

---

## Scenario 3: Plugin Management — `list plugins`

```
User: doc.doc.sh list plugins
```

1. `cmd_list` calls `discover_plugins()`.
2. `plugins.sh` scans `doc.doc.md/plugins/`; reads each `descriptor.json`; evaluates `active` field.
3. Formats and prints plugin table with name, version, and `[ACTIVE]`/`[INACTIVE]` status to stdout.

```
file        1.0.0  [ACTIVE]
ocrmypdf    1.1.0  [ACTIVE]
stat        1.0.0  [ACTIVE]
```

---

## Scenario 4: Plugin Activation — `activate`

```
User: doc.doc.sh activate --plugin ocrmypdf
```

1. `cmd_activate` validates `ocrmypdf` exists in plugin directory.
2. Uses `jq` to set `"active": true` in `ocrmypdf/descriptor.json`.
3. Prints confirmation to stdout.

---

## Scenario 5: Dependency Tree — `tree`

```
User: doc.doc.sh tree
```

1. `cmd_tree` loads all plugins via `discover_plugins()`.
2. For each plugin, reads `process.input` and `process.output` from descriptors.
3. Builds a dependency graph: plugin A depends on plugin B if A requires an input that B provides as output.
4. Renders tree with activation status indicators.

```
├─ 🟢 file        [ACTIVE]   (provides: mimeType)
├─ 🟢 stat        [ACTIVE]   (provides: fileSize, fileOwner, ...)
└─ 🟢 ocrmypdf    [ACTIVE]   (requires: mimeType ← file)
```

---

## Plugin Lifecycle

```
┌─────────────┐
│  AVAILABLE  │ ← descriptor.json exists in plugins/
└──────┬──────┘
       │ install (if external dependencies needed)
       ▼
┌─────────────┐
│  INSTALLED  │ ← installed.sh exits 0
└──────┬──────┘
       │ activate (set active: true in descriptor.json)
       ▼
┌─────────────┐
│   ACTIVE    │ ← included in processing chain
└──────┬──────┘
       │ deactivate (set active: false in descriptor.json)
       ▼
┌─────────────┐
│  INACTIVE   │ ← excluded from processing chain
└─────────────┘
```

---

## Error Handling Patterns

| Scenario | Behavior |
|----------|----------|
| Input directory does not exist | Immediate exit with error message to stderr; exit code 1. |
| Plugin not found | Error to stderr; exit code 1. |
| Plugin `process` exits with code 1 | Warning to stderr; file skipped; processing continues. |
| Plugin `process` exits with code 2 | Error to stderr; processing halted; exit code 2. |
| `file` plugin not active | MIME criteria cannot be evaluated; `doc.doc.sh` aborts with error. |
| MIME filter gate rejects file | File silently skipped; no JSON output for that file. |
| Invalid filter pattern | Error to stderr; exit code 1. |
