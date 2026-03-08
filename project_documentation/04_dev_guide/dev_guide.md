# Development Guide

## Table of Contents

- [Development Environment](#development-environment)
- [Architecture Overview](#architecture-overview)
- [Contributing Guidelines](#contributing-guidelines)
- [Plugin Development](#plugin-development)
- [Testing](#testing)
- [Template Development](#template-development)
- [Code Style](#code-style)
- [Architecture Decision Process](#architecture-decision-process)

---

## Development Environment

### Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Bash | 4.0+ | Required for associative arrays (`declare -A`) |
| jq | any current | Used in all plugin scripts and the main CLI |
| Python | 3.12+ | Filter engine (`filter.py`) |
| `file` | any | MIME detection (`file` plugin) |
| `stat` | any | File statistics (`stat` plugin) |
| Git | any | Version control |

Optional (for OCR plugin development):

| Tool | Notes |
|------|-------|
| `ocrmypdf` | OCR processing |
| `pdftotext` | Fast PDF text extraction (poppler-utils) |
| Pillow (Python) | Image alpha channel handling |

Optional (for markitdown plugin development):

| Tool | Notes |
|------|-------|
| `markitdown` (pip) | MS Office to markdown conversion |

### Dev Container

A VS Code Dev Container is configured in the repository. Open the repository in VS Code and select **Reopen in Container** to get a fully provisioned environment with all dependencies.

### Project Structure

```
doc.doc.md/
├── doc.doc.sh                       # Main CLI entry point
└── doc.doc.md/                      # Core directory
    ├── components/
    │   ├── filter.py                # Python filter engine (include/exclude logic)
    │   └── plugins.sh               # Plugin discovery and execution helpers
    ├── plugins/
    │   ├── file/                    # MIME type detection plugin
    │   │   ├── descriptor.json
    │   │   ├── main.sh
    │   │   ├── install.sh
    │   │   └── installed.sh
    │   ├── stat/                    # File statistics plugin
    │   │   ├── descriptor.json
    │   │   ├── main.sh
    │   │   ├── install.sh
    │   │   └── installed.sh
    │   └── ocrmypdf/                # OCR processing plugin
    │       ├── descriptor.json
    │       ├── main.sh
    │       ├── convert.sh
    │       ├── install.sh
    │       └── installed.sh
    │   └── markitdown/              # MS Office to markdown plugin
    │       ├── descriptor.json
    │       ├── main.sh
    │       ├── install.sh
    │       └── installed.sh
    └── templates/
        └── default.md               # Default markdown template

tests/                               # Test suite
    ├── docs/                        # Sample documents for integration tests
    ├── test_doc_doc.sh              # CLI and filter engine tests
    ├── test_plugins.sh              # Plugin unit tests
    ├── test_filter_mime.sh          # MIME filter tests
    ├── test_list_commands.sh        # list command tests
    ├── test_docs_integration.sh     # Integration tests with real documents
    └── test_feature_*.sh           # Feature-specific test files
    └── test_bug_*.sh               # Bug regression tests

project_documentation/               # Architecture docs (arc42 structure)
project_management/                  # Guidelines, workflows, vision documents
```

---

## Architecture Overview

doc.doc.md uses a **mixed Bash + Python architecture**:

- **Bash** (`doc.doc.sh`, `plugins.sh`, plugin scripts): CLI orchestration, file discovery using `find`, plugin execution, Unix pipeline coordination
- **Python** (`filter.py`): Complex AND/OR include/exclude filtering logic that is impractical to implement reliably in pure Bash

The **plugin pipeline** is the central processing model:

1. `find` discovers all files in the input directory
2. `filter.py` applies path and extension filters to the file list
3. For each file, active plugins execute in dependency order (topological sort), each receiving the accumulated JSON from prior plugins and adding its own fields
4. The MIME filter gate runs immediately after the `file` plugin, before any other plugin processes the file
5. Results are streamed as a JSON array to stdout

See `project_documentation/01_architecture/` for full arc42 architecture documentation, and `project_management/02_project_vision/03_architecture_vision/` for ADRs and architecture concepts.

**Key ADR:** [ADR-001](../../project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/) — rationale for the Bash+Python hybrid approach.

---

## Contributing Guidelines

### Branching Strategy

- `main` — stable, tested code only
- Feature branches: `feature/<short-description>`
- Bug fix branches: `bugfix/<short-description>`

### Commit Conventions

Use descriptive commit messages. Reference work items where applicable:

```
Add MIME type wildcard support to filter engine (FEATURE_0010)

Support patterns like 'image/*' matching against full MIME types.
```

### Pull Request Process

1. Fork the repository and create a branch
2. Write tests first (TDD) — see [Testing](#testing)
3. Implement the feature
4. Ensure all tests pass: `bash tests/test_doc_doc.sh`
5. Open a PR with a clear description of the change and its rationale

### Coding Standards

- Bash: `set -euo pipefail` in every script; `shellcheck` clean
- Python: type hints, PEP 8 formatting
- JSON: 2-space indentation in `descriptor.json` files
- All plugin scripts must produce **only valid JSON on stdout**; diagnostics go to stderr

---

## Plugin Development

### Plugin Directory Structure

Create a new directory under `doc.doc.md/plugins/<plugin-name>/`:

```
doc.doc.md/plugins/my-plugin/
├── descriptor.json     # required — declares commands, inputs, outputs
├── main.sh             # or any executable: process command implementation
├── install.sh          # optional — installs external dependencies
└── installed.sh        # optional — checks if dependencies are available
```

### `descriptor.json` Schema

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "What this plugin does.",
  "active": true,
  "commands": {
    "process": {
      "description": "One-line description of what process does.",
      "command": "main.sh",
      "input": {
        "filePath": {
          "type": "string",
          "description": "Path to the file.",
          "required": true
        },
        "mimeType": {
          "type": "string",
          "description": "MIME type from the file plugin.",
          "required": false
        }
      },
      "output": {
        "myField": {
          "type": "string",
          "description": "Something this plugin extracts."
        }
      }
    },
    "install": {
      "description": "Install external dependencies.",
      "command": "install.sh",
      "output": {
        "success": { "type": "boolean", "description": "Whether installation succeeded." },
        "message": { "type": "string", "description": "Human-readable status." }
      }
    },
    "installed": {
      "description": "Check if dependencies are available.",
      "command": "installed.sh",
      "output": {
        "installed": { "type": "boolean", "description": "true if ready to run." }
      }
    }
  },
  "dependencies": ["file"]
}
```

**Fields:**

| Field | Required | Notes |
|-------|----------|-------|
| `name` | Yes | Matches the directory name |
| `version` | Yes | Semver string |
| `description` | Yes | Human-readable summary |
| `active` | Yes | `true` or `false`; controls whether the plugin runs |
| `commands.process` | Yes | The main processing command |
| `commands.process.command` | Yes | Shell command to execute (relative to plugin directory) |
| `commands.process.input` | Yes | Fields the plugin reads from the accumulated JSON |
| `commands.process.output` | Yes | Fields the plugin adds to the JSON |
| `commands.install` | No | Runs `install.sh` for dependency installation |
| `commands.installed` | No | Runs `installed.sh` to check installation status |
| `dependencies` | No | Array of plugin names this plugin depends on |

### Input/Output JSON Contract

The doc.doc.md framework passes an accumulated JSON object to each plugin via **stdin**. The plugin writes its additions as a JSON object to **stdout**. The framework merges the output into the accumulated object using `jq -s '.[0] * .[1]'`.

**stdin example:**
```json
{
  "filePath": "/docs/report.pdf",
  "mimeType": "application/pdf",
  "fileSize": 204800
}
```

**stdout example (plugin adds one new field):**
```json
{
  "myField": "extracted value"
}
```

Rules:
- Read from stdin only; never read the file path from CLI arguments
- Write only valid JSON to stdout; all other output (logs, errors) must go to stderr
- Limit stdin reads to prevent memory exhaustion (built-in plugins use `head -c 1048576`)
- Follow the exit code contract described below

### Plugin Exit Code Contract (ADR-004)

Every plugin's `process` command must follow the **three-state exit code contract** defined in [ADR-004](../../project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md). This contract determines how the framework handles each plugin's result:

| Exit Code | Constant | Meaning | stdout | Framework Action |
|-----------|----------|---------|--------|------------------|
| **0** | `EX_OK` | Success | Output JSON as declared in `descriptor.json` | Merge JSON into combined result |
| **65** | `EX_DATAERR` | Intentional skip / unsupported input | `{}` or `{"message":"<reason>"}` | Silently discard — no error printed |
| **1** (or other ≠ 0, 65) | — | Unexpected failure | Any (ignored) | Print error message to stderr |

**Key rules:**
- Exit **65** must only be used when the plugin decides **not to handle** the input (e.g., unsupported MIME type). It must **never** be used for processing errors.
- The skip message (`{"message":"..."}`) must be written to **stdout** as valid JSON — not to stderr as plain text.
- Plugins that handle all file types (e.g., `file`, `stat`) should **never** return exit 65.

**Code example — three exit paths in `main.sh`:**

```bash
#!/bin/bash
# Exit codes: 0 success (EX_OK), 65 unsupported input (EX_DATAERR, ADR-004), 1 failure
set -euo pipefail

input=$(head -c 1048576)
file_path=$(echo "$input" | jq -r '.filePath // empty')
mime_type=$(echo "$input" | jq -r '.mimeType // empty')

# ... validate inputs ...

# Exit 65: unsupported MIME type — intentional skip
if [ "$mime_supported" = false ]; then
  echo "{\"message\":\"skipped: unsupported MIME type $mime_type\"}"
  exit 65
fi

# Exit 1: genuine processing failure
if ! result=$(my_tool "$file_path" 2>/dev/null); then
  echo "Error: processing failed" >&2
  exit 1
fi

# Exit 0: success
jq -n --arg myField "$result" '{myField: $myField}'
```

See [ADR-004](../../project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md) for the full rationale and design decision behind this contract.

### Dependency Resolution

The execution order of plugins is determined **automatically** by matching output field names to input field names across all active plugins — no explicit dependency graph declarations are needed (beyond the `"dependencies"` array in `descriptor.json` for documenting intent).

**Example:** `ocrmypdf` declares `mimeType` as a required input field. The `file` plugin declares `mimeType` as an output field. The framework infers that `file` must run before `ocrmypdf`.

The `file` plugin is always placed at position 0 in the execution order regardless of dependency declarations.

### Step-by-Step: Creating a New Plugin

**1. Create the plugin directory:**

```bash
mkdir doc.doc.md/plugins/my-plugin
```

**2. Write `descriptor.json`:**

Declare name, version, description, active state, and the `process` command with its input and output fields.

**3. Implement the process script:**

**Bash example (`main.sh`):**

```bash
#!/bin/bash
set -euo pipefail

input=$(head -c 1048576)

file_path=$(echo "$input" | jq -r '.filePath // empty') || {
  echo "Error: Invalid JSON input" >&2; exit 1
}

if [ -z "$file_path" ]; then
  echo "Error: Missing filePath" >&2; exit 1
fi

# Resolve and validate the path
resolved=$(readlink -f "$file_path" 2>/dev/null) || {
  echo "Error: Cannot access file" >&2; exit 1
}

case "$resolved" in
  /proc/*|/dev/*|/sys/*|/etc/*)
    echo "Error: Cannot access file" >&2; exit 1 ;;
esac

[ -f "$resolved" ] && [ -r "$resolved" ] || {
  echo "Error: Cannot access file" >&2; exit 1
}

# Do the work
my_result="example"

jq -n --arg myField "$my_result" '{myField: $myField}'
```

**Python example:**

```python
#!/usr/bin/env python3
import json
import sys

def main():
    raw = sys.stdin.read(1048576)
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        print("Error: Invalid JSON input", file=sys.stderr)
        sys.exit(1)

    file_path = data.get("filePath")
    if not file_path:
        print("Error: Missing filePath", file=sys.stderr)
        sys.exit(1)

    # Do the work
    result = {"myField": "extracted value"}
    json.dump(result, sys.stdout)

if __name__ == "__main__":
    main()
```

For Python plugins, set `"command": "python3 main.py"` in `descriptor.json`.

**4. Make scripts executable:**

```bash
chmod +x doc.doc.md/plugins/my-plugin/main.sh
```

**5. Write `install.sh` (if needed):**

```bash
#!/bin/bash
if command -v my-tool >/dev/null 2>&1; then
  jq -n '{success: true, message: "my-tool already available"}'
  exit 0
fi
# Try to install...
if apt-get install -y my-tool >/dev/null 2>&1; then
  jq -n '{success: true, message: "my-tool installed"}'
else
  jq -n '{success: false, message: "Could not install my-tool"}'
  exit 1
fi
```

**6. Write `installed.sh`:**

```bash
#!/bin/bash
if command -v my-tool >/dev/null 2>&1; then
  jq -n '{installed: true}'
else
  jq -n '{installed: false}'
fi
exit 0
```

`installed.sh` always exits `0` — it reports status, it does not fail.

**7. Activate and verify:**

```bash
./doc.doc.sh activate --plugin my-plugin
./doc.doc.sh install --plugin my-plugin
./doc.doc.sh installed --plugin my-plugin
./doc.doc.sh tree
```

### `install.sh` Contract

- Output: JSON `{"success": boolean, "message": string}` to stdout
- Exit `0` if the tool is already available or was successfully installed
- Exit non-zero if installation failed
- Never prompt for user input

### `installed.sh` Contract

- Output: JSON `{"installed": boolean}` to stdout
- Always exit `0` (reporting status, not failing)
- Only check availability; do not install anything

### Plugin Security Guidelines

All plugins — built-in and third-party — must follow these guidelines.

#### Input Validation

- **Always** parse and validate the JSON object received from stdin before use.
- **Always** verify that `filePath` is a non-empty string, resolves to a regular file, and is readable.
- **Always** canonicalize `filePath` with `readlink -f` (Bash) or `os.path.realpath` (Python) and verify the resolved path is within expected boundaries.
- **Never** execute file content (no `bash <`, `eval`, `source`).

```bash
# Bash — path validation pattern
resolved=$(readlink -f "$file_path" 2>/dev/null) || { echo "Cannot resolve path" >&2; exit 1; }
case "$resolved" in /proc/*|/dev/*|/sys/*|/etc/*) echo "Restricted path" >&2; exit 1 ;; esac
[ -f "$resolved" ] && [ -r "$resolved" ] || { echo "Not a readable file" >&2; exit 1; }
```

```python
# Python — path validation pattern
import os, sys
resolved = os.path.realpath(file_path)
for restricted in ("/proc/", "/dev/", "/sys/", "/etc/"):
    if resolved.startswith(restricted):
        print("Restricted path", file=sys.stderr); sys.exit(1)
if not os.path.isfile(resolved) or not os.access(resolved, os.R_OK):
    print("Not a readable file", file=sys.stderr); sys.exit(1)
```

#### Output Safety

- **Always** write only valid JSON to stdout; diagnostics go to stderr.
- **Always** use `jq -n --arg` (Bash) or `json.dump` (Python) to build output — never construct JSON by string concatenation.
- **Never** include raw file content in JSON output without ensuring it is properly escaped.

#### Resource Management

- **Always** limit stdin reads to 1 MB (`head -c 1048576` / `sys.stdin.read(1048576)`).
- **Always** clean up temporary files (`trap cleanup EXIT`).
- **Never** spawn background processes that outlive the plugin execution.
- **Never** require root/sudo.

#### What Plugins Must NOT Do

| ❌ Anti-pattern | Risk |
|----------------|------|
| `eval "$(cat "$file_path")"` | Executes file content as shell code |
| `bash < "$file_path"` | Same as above |
| `echo "result: $value"` (raw stdout) | Corrupts JSON output stream |
| Construct JSON by `echo "{ \"key\": $var }"` | JSON injection if `$var` contains `"` |
| Write to files outside the plugin temp dir | Unauthorized filesystem modification |
| Access the network without documenting it clearly | Unexpected data exfiltration |
| `echo "Processing…"` to stdout | Pollutes JSON stream |

#### Plugin Security Checklist

Before publishing a plugin:

- [ ] JSON input parsed and validated from stdin
- [ ] `filePath` canonicalized and boundary-checked
- [ ] Stdin read bounded to 1 MB
- [ ] Output is valid JSON produced by `jq` or equivalent library
- [ ] All diagnostic messages go to stderr
- [ ] Temporary files cleaned up via `trap`
- [ ] No background processes survive plugin exit
- [ ] `install.sh` and `installed.sh` present and correct
- [ ] Tested with adversarial input: missing fields, wrong types, path traversal attempts
- [ ] No hardcoded absolute paths (works on any machine)
- [ ] No network access, or network access clearly documented in `descriptor.json`

---

## Testing

### Test Framework

Tests are plain Bash scripts using helper functions (`assert_eq`, `assert_exit_code`, `assert_contains`, `assert_json_field`). No external test framework (e.g., BATS) is used.

### Running Tests

All tests are run from the repository root:

```bash
# Run all test suites individually
bash tests/test_doc_doc.sh         # CLI and filter engine
bash tests/test_plugins.sh         # stat and file plugin unit tests
bash tests/test_filter_mime.sh     # MIME filter behaviour
bash tests/test_list_commands.sh   # list command
bash tests/test_docs_integration.sh # integration tests with real documents
bash tests/test_feature_0004.sh    # feature-specific tests
# ... etc.
```

Each script prints `PASS`/`FAIL` for every test and a summary at the end. Exit code is `0` if all tests passed, `1` if any failed.

### Test File Naming

| Pattern | Purpose |
|---------|---------|
| `test_doc_doc.sh` | Core CLI and filter engine |
| `test_plugins.sh` | Plugin unit tests |
| `test_filter_mime.sh` | MIME filtering behaviour |
| `test_feature_<NNNN>.sh` | Tests for a specific feature work item |
| `test_bug_<NNNN>.sh` | Regression tests for a specific bug fix |
| `test_docs_integration.sh` | End-to-end integration with real document files |

### Writing New Tests

1. Create `tests/test_feature_<NNNN>.sh` (or `test_bug_<NNNN>.sh` for regressions)
2. Copy the helper functions from an existing test file
3. Set up a temporary directory in `TEST_DIR=$(mktemp -d)` and register a cleanup trap
4. Write test cases using the helper assertions:

```bash
# Assert string equality
assert_eq "description" "expected" "$actual"

# Assert command exit code
some_command; exit_code=$?
assert_exit_code "description" "0" "$exit_code"

# Assert output contains a substring
assert_contains "description" "substring" "$output"

# Assert a JSON field value
assert_json_field "description" "$json_output" "fieldName" "expected_value"
```

5. Print a summary and exit with `1` if any test failed:

```bash
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
```

### Test Conventions

- Each test script is self-contained and cleans up its own temporary files via `trap cleanup EXIT`
- Plugin error-case tests must suppress stderr (`2>/dev/null`) to avoid polluting test output
- Integration tests that process real files use the sample documents in `tests/docs/`
- Tests must pass on both Linux and macOS

---

## Template Development

### Template Variable Naming

Template variables use `{{variableName}}` syntax with **lowerCamelCase** names. Variable names must exactly match the output field names declared in plugin `descriptor.json` files.

```markdown
# {{fileName}}

- **MIME**: {{mimeType}}
- **Size**: {{fileSize}} bytes
- **Owner**: {{fileOwner}}
- **Created**: {{fileCreated}}
- **Modified**: {{fileModified}}
```

### Available Variables

Variables are only available if the corresponding plugin is active. Referencing a variable from an inactive plugin produces an empty substitution.

| Variable | Source plugin | Type |
|----------|--------------|------|
| `{{mimeType}}` | file | string |
| `{{fileSize}}` | stat | number |
| `{{fileOwner}}` | stat | string |
| `{{fileCreated}}` | stat | string (ISO 8601) |
| `{{fileModified}}` | stat | string (ISO 8601) |
| `{{fileMetadataChanged}}` | stat | string (ISO 8601) |
| `{{ocrText}}` | ocrmypdf | string |
| `{{documentText}}` | markitdown | string |

Custom plugin output fields are referenced the same way — use the exact field name from `descriptor.json`.

### Template Location

Place templates in `doc.doc.md/templates/` or any accessible path. The default template is `doc.doc.md/templates/default.md`.

---

## Code Style

### Bash

- Every script starts with `#!/bin/bash` and `set -euo pipefail`
- Variables are quoted: `"$var"`, not `$var`
- Local variables are declared with `local` inside functions
- Error messages go to stderr: `echo "Error: ..." >&2`
- Use `jq -n` for building JSON output; never construct JSON by string concatenation
- Follow the security patterns in built-in plugins: resolve symlinks, validate paths, reject dangerous directories

### Python

- Type hints on all function signatures
- PEP 8 formatting
- Use `json.load(sys.stdin)` / `json.dump(result, sys.stdout)` for JSON I/O
- Error messages to `sys.stderr`; exit non-zero on failure

### JSON (`descriptor.json`)

- 2-space indentation
- All string values use double quotes
- Boolean values are `true`/`false` (not `"true"`/`"false"`)
- `"active"` field must always be present

### General

- No silent failures: if something goes wrong, print a clear error to stderr and exit non-zero
- Stdin reads are bounded (1 MB limit) in all plugin scripts
- New plugins must include both `install.sh` and `installed.sh` unless the plugin has no external dependencies

---

## Architecture Decision Process

### ADRs (Architecture Decision Records)

Significant architectural choices are documented as ADRs in:

```
project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/
```

To propose a new ADR:

1. Create a file `ADR_<NNN>_<short-title>.md` using the existing ADRs as a template
2. Include: context, decision, alternatives considered, consequences, and rationale
3. Reference the ADR in commit messages and PR descriptions when implementing the decision

### IDRs (Implementation Decision Records)

Decisions scoped to implementation details (not architecture) are documented as IDRs in the same directory with the prefix `IDR_`.

### Architecture Concepts

Cross-cutting concerns (filtering logic, plugin architecture, template processing, error handling) are documented as concept documents in:

```
project_management/02_project_vision/03_architecture_vision/08_concepts/
```

These describe *how* something works, not *why* it was chosen (that belongs in ADRs).

### Proposing Changes

For significant changes:

1. Open a GitHub issue describing the problem and proposed solution
2. Draft an ADR or architecture concept document
3. Request review from maintainers before implementing
4. Reference the ADR/concept in your PR
