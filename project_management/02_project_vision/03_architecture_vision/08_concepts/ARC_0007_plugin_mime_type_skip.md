## Plugin Skip Protocol: Exit Code-Based Skip Signalling

**Author:** Architect Agent
**Created on:** 2026-03-07
**Last Updated:** 2026-03-07
**Status:** Accepted


**Version History**
| Date       | Author          | Description               |
|------------|-----------------|---------------------------|
| 2026-03-07 | Architect Agent | Initial draft |
| 2026-03-07 | Architect Agent | Rework: skip decision belongs to plugin, not framework pre-check; skip via exit 0 + JSON shape |
| 2026-03-07 | Architect Agent | Rework: adopt ADR-004 exit code contract; skip signalled by exit 65 (EX_DATAERR) |
| 2026-03-07 | Architect Agent | Code review: clarify two-layer change in run_plugin + process_file; document stderr→stdout channel switch for plugin skip message |

**Table of Contents:**
- [Problem Statement](#problem-statement)
- [Scope](#scope)
- [In Scope](#in-scope)
- [Out of Scope](#out-of-scope)
- [Proposed Solution](#proposed-solution)
- [Benefits](#benefits)
- [Challenges and Risks](#challenges-and-risks)
- [Implementation Plan](#implementation-plan)
- [Conclusion](#conclusion)
- [References](#references)


### Problem Statement

During the Document Processing Phase of `doc.doc.sh process`, every active plugin is invoked for every discovered file. Plugins such as `markitdown` and `ocrmypdf` only process specific MIME types. When such a plugin receives a file it cannot handle, it currently exits with code 1, causing the framework to treat the invocation as a failure and print:

```
Error: Plugin 'markitdown' failed for file: README-Screenshot-PNG.png
```

This is a false error. The plugin did not fail — it chose not to handle that file. The misleading output erodes user trust, contaminates log pipelines, and obscures genuine failures.

The root cause is the absence of a machine-readable exit code that distinguishes "I chose not to process this input" from "I tried and something went wrong." ADR-004 resolves this at the architectural level by defining a structured exit code contract for all plugins.


### Scope

This concept defines how the plugin skip protocol (as decided in ADR-004) applies to the plugin execution layer: specifically what plugins must do to signal a skip, what the framework must do in response, and which components require changes.


### In Scope

- Application of the ADR-004 exit code contract to `plugin_execution.sh`
- Update of `markitdown/main.sh` and `ocrmypdf/main.sh` to exit 65 for unsupported input
- Framework handling of exit 65: silent discard, no user-visible message
- Preservation of the existing error-reporting path for non-zero exits other than 65


### Out of Scope

- Addition of any `supportedMimeTypes` or similar metadata to `descriptor.json`
- Changes to the framework's pre-invocation logic; no MIME pre-check is added
- Changes to the `file` or `stat` plugins (they do not perform type-based skips)
- Changes to user-visible filter criteria (`-i`/`-e` flags on the `process` command)
- Changes to `plugins.sh` (legacy coordination file; out of scope)


### Proposed Solution

#### 1. Exit Code Contract (ADR-004)

As decided in ADR-004, the plugin exit code contract is:

| Exit Code | Constant    | Meaning | JSON stdout |
|-----------|-------------|---------|-------------|
| **0**     | `EX_OK`     | Successful execution | JSON object with output attributes as declared in `descriptor.json` |
| **65**    | `EX_DATAERR`| Input not supported — intentional skip | `{}` or `{"message": "<reason>"}` (optional but recommended) |
| **1** (or any other non-zero ≠ 65) | — | Unexpected failure | Any (framework will not parse it) |

Exit code 65 maps to `EX_DATAERR` from BSD `sysexits.h`, the closest standard constant for "the input data was not processable." The project's usage is specifically: "this plugin does not support this input type."

#### 2. Plugin Side — Affected Plugins

Any plugin that encounters an input it will not process MUST:

1. Exit with code **65**
2. Optionally print to stdout a JSON object `{}` or `{"message": "<human-readable reason>"}` for diagnostic purposes

**Example — `markitdown/main.sh`:**

Current code (to be changed):
```bash
# Current: message to stderr, exit 1
if [ "$mime_supported" = false ]; then
  echo "Error: Unsupported MIME type: $mime_type" >&2
  exit 1
fi
```

Required change:
```bash
# Required: skip message to stdout as JSON, exit 65
if [ "$mime_supported" = false ]; then
  echo '{"message": "skipped due to unsupported mime type"}'
  exit 65
fi
```

**Two changes per plugin**: (1) exit code `1` → `65`; (2) error message output channel `>&2` → stdout, reformatted as JSON `{"message":"..."}`.

**Plugins requiring update:**
- `markitdown/main.sh` — currently exits 1 (with message to stderr) for unsupported MIME types
- `ocrmypdf/main.sh` — currently exits 1 (with message to stderr) for unsupported MIME types

**Plugins not requiring changes:**
- `file/main.sh` — runs for all file types; produces MIME detection output
- `stat/main.sh` — runs for all file types; produces file system metadata

#### 3. Framework Side — `plugin_execution.sh`

The change requires **two separate edits** within `plugin_execution.sh`:

##### 3a. `run_plugin` — capture and pass through exit 65

The current implementation uses a `||` pattern that absorbs ALL non-zero plugin exits as `return 1`:

```bash
# CURRENT (incorrect for exit-65 support)
local plugin_output
plugin_output=$(echo "$json_input" | "$script_path" 2>/dev/null) || {
  echo "Error: Plugin '$plugin_name' failed for file: $(basename "$file_path")" >&2
  return 1
}
```

This pattern swallows exit 65 — the skip signal never reaches `process_file`. It must be replaced with explicit exit-code capture:

```bash
# REQUIRED (captures exit 65 and passes it through)
local plugin_output
local plugin_exit
plugin_output=$(echo "$json_input" | "$script_path" 2>/dev/null)
plugin_exit=$?

if [ "$plugin_exit" -eq 65 ]; then
  # Intentional skip — pass through to caller
  return 65
elif [ "$plugin_exit" -ne 0 ]; then
  echo "Error: Plugin '$plugin_name' failed for file: $(basename "$file_path")" >&2
  return "$plugin_exit"
fi
```

##### 3b. `process_file` — handle `run_plugin` returning 65

Once `run_plugin` passes through exit 65, `process_file` must check for it:

```bash
local plugin_output
local plugin_exit
plugin_output=$(run_plugin "$plugin_name" "$file_path" "$PLUGIN_DIR" "$combined_result")
plugin_exit=$?

if [ "$plugin_exit" -eq 0 ]; then
  # Success — merge output into combined result
  combined_result=$(echo "$combined_result" "$plugin_output" | jq -s '.[0] * .[1]')

elif [ "$plugin_exit" -eq 65 ]; then
  # Intentional skip (EX_DATAERR) — silently discard, no message
  :

else
  # Unexpected failure — existing error-reporting path
  # (file-plugin failure and MIME-filter logic also lives here; see current code)
  :
fi
```

The exit code is the first and only check. No JSON parsing is required to determine the outcome.

#### 4. Data Flow Diagram

```
process_file("/path/to/image.png", ["file", "markitdown", "stat"])
  │
  ├─ run_plugin("file", ...)
  │    exit 0,  output: {"filePath": "...", "mimeType": "image/png", ...}
  │    → merged into combined_result
  │
  ├─ run_plugin("markitdown", ...)
  │    markitdown/main.sh: "image/png" not in supported set
  │    exit 65, output: {"message": "skipped due to unsupported mime type"}
  │    → SILENT SKIP (exit 65 path, no merge, no error message)
  │
  └─ run_plugin("stat", ...)
       exit 0,  output: {"fileSize": 42300, ...}
       → merged into combined_result

final combined_result: {"filePath":"...", "mimeType":"image/png", "fileSize":42300, ...}
```


### Benefits

- **Unambiguous signal**: The exit code alone determines framework behaviour; no JSON parsing required to decide skip vs success.
- **Standard-aligned**: Exit 65 (`EX_DATAERR`) is a well-known UNIX constant, reducing cognitive overhead for plugin authors.
- **Plugin autonomy**: Each plugin decides independently whether it supports a given input. The framework does not pre-screen.
- **No descriptor changes**: `descriptor.json` requires no new fields. The skip logic is fully encapsulated in plugin `main.sh`.
- **Minimal framework change**: `run_plugin` / `process_file` gains one extra `elif [ $exit -eq 65 ]` branch and nothing else.
- **Accurate error signal**: Non-zero exits other than 65 exclusively indicate genuine failures.


### Challenges and Risks

- **Plugin update required**: `markitdown` and `ocrmypdf` must be updated to exit 65 instead of 1 for unsupported inputs. This is a one-time change per plugin.
- **Developer guide must document the contract**: Plugin authors not familiar with this ADR could mistakenly exit 1. The convention must be written into `project_documentation/04_dev_guide/dev_guide.md`.
- **EX_DATAERR semantic stretch**: In strict `sysexits.h` usage, `EX_DATAERR` means "data format error in input", not "input type not supported." The project documentation must clarify the chosen meaning for this context. See ADR-004 for the rationale.


### Implementation Plan

1. **Update `markitdown/main.sh`**: Change exit 1 on unsupported MIME type to `echo '{"message":"skipped due to unsupported mime type"}'; exit 65`.
2. **Update `ocrmypdf/main.sh`**: Same change.
3. **Update `run_plugin` / `process_file`** (`plugin_execution.sh`): Add `elif [ "$plugin_exit" -eq 65 ]` silent-skip branch as shown in §3.
4. **Update developer guide**: Document the exit code contract (ADR-004) in `project_documentation/04_dev_guide/dev_guide.md`.
5. **Test**: Add a test verifying that processing a mixed document collection produces no error output for MIME-type mismatches, and that genuine failures still produce error output.
6. **Regression**: Run the full existing test suite.


### Conclusion

By adopting the ADR-004 exit code contract, the framework can handle intentional plugin skips with a single integer comparison. Exit 65 (`EX_DATAERR`) gives plugin authors a clear, standard-aligned way to say "this input is not for me." The framework's response — a silent no-op — requires minimal code change and eliminates all false error output. The primary implementation task is updating two plugin `main.sh` files and a single `elif` branch in the execution layer.


### References

- [ADR-004 Plugin Exit Code and Failure Handling Strategy](../09_architecture_decisions/ADR_004_plugin_exit_code_strategy.md)
- [REQ_0039 Silent Skip for Unsupported MIME Types](../../../02_requirements/03_accepted/REQ_0039_silent-skip-unsupported-mime-types.md)
- [ARC_0003 Plugin Architecture](ARC_0003_plugin_architecture.md)
- [ARC_0004 Error Handling](ARC_0004_error_handling.md)
- [plugin_execution.sh](../../../../doc.doc.md/components/plugin_execution.sh)
- [markitdown/main.sh](../../../../doc.doc.md/plugins/markitdown/main.sh)
- [ocrmypdf/main.sh](../../../../doc.doc.md/plugins/ocrmypdf/main.sh)
- [Project Goals TODO 1](../../../01_project_goals/project_goals.md)
- BSD sysexits.h — `EX_DATAERR = 65`

**Author:** Architect Agent
**Created on:** 2026-03-07
**Last Updated:** 2026-03-07
**Status:** Draft


**Version History**
| Date       | Author          | Description               |
|------------|-----------------|---------------------------|
| 2026-03-07 | Architect Agent | Initial draft             |
| 2026-03-07 | Architect Agent | Rework: skip decision belongs to the plugin, not the framework pre-check |

**Table of Contents:**
- [Problem Statement](#problem-statement)
- [Scope](#scope)
- [In Scope](#in-scope)
- [Out of Scope](#out-of-scope)
- [Proposed Solution](#proposed-solution)
- [Benefits](#benefits)
- [Challenges and Risks](#challenges-and-risks)
- [Implementation Plan](#implementation-plan)
- [Conclusion](#conclusion)
- [References](#references)


### Problem Statement

During the Document Processing Phase of `doc.doc.sh process`, every active plugin is invoked for every discovered file. Plugins such as `markitdown` and `ocrmypdf` only process specific MIME types. When such a plugin receives a file it does not intend to handle, it currently exits with a non-zero code, causing the framework (`run_plugin` in `plugin_execution.sh`) to treat the invocation as a failure and print:

```
Error: Plugin 'markitdown' failed for file: README-Screenshot-PNG.png
```

This is a false error. The plugin did not fail — it simply chose not to handle that file. The misleading output erodes user trust, contaminates log pipelines, and obscures genuine failures.

The root cause is a missing convention for how a plugin signals "I choose not to process this input" as distinct from "I tried to process this input and something went wrong."


### Scope

This concept defines the plugin–framework contract for communicating an intentional skip, how the framework must respond to it silently, and what plugins must change to conform to the protocol. The decision of whether to skip a given file is the **plugin's own responsibility** — the framework does not pre-screen or second-guess it.


### In Scope

- Definition of the plugin skip signal: exit code 0 with an empty JSON object or a message-only JSON object
- Framework handling: silent merge of skip output, no error printed
- Update of plugin `main.sh` scripts that currently exit non-zero for unsupported types to exit 0 with the skip signal instead
- Preservation of the existing error-reporting path for genuine failures (non-zero exit)
- Backward compatibility: plugins that currently exit 0 with a valid data JSON object are unaffected


### Out of Scope

- Addition of any `supportedMimeTypes` or similar metadata to `descriptor.json` (not required by this approach)
- Changes to the framework's pre-invocation logic; no MIME pre-check is added
- Changes to the `file` or `stat` plugins (they do not perform MIME-based skips)
- Changes to user-visible MIME filter criteria (`-i`/`-e` flags on the `process` command)
- Changes to `plugins.sh` (legacy coordination file; out of scope)
- New top-level exit codes for the `doc.doc.sh process` command


### Proposed Solution

#### 1. Plugin Skip Signal (Plugin Side)

A plugin that decides not to process a particular document MUST:

1. Exit with code **0** (indicating no error occurred)
2. Print to stdout a JSON object that is either:
   - An **empty object**: `{}`
   - An **informational object** carrying only a `message` key and no document data: `{"message": "skipped due to unsupported mime type"}`

The `message` value is free-form text for diagnostic purposes. The framework does not display or forward it; it is only useful when a developer inspects raw plugin output during debugging.

**What a skip looks like from `markitdown/main.sh`:**

```bash
# Detect unsupported MIME type
file_mime=$(echo "$input_json" | jq -r '.mimeType // empty')
case "$file_mime" in
  application/vnd.openxmlformats-officedocument.* | \
  application/msword | application/vnd.ms-* )
    # supported — continue processing
    ;;
  *)
    # not supported — signal skip, not failure
    echo '{"message": "skipped due to unsupported mime type"}'
    exit 0
    ;;
esac
```

#### 2. Framework Skip Detection (Framework Side)

The `run_plugin` function in `plugin_execution.sh` already collects stdout and checks the exit code. The detection logic is extended as follows:

```
if exit code != 0:
    → existing failure path: print "Error: Plugin '<name>' failed for file: <file>"

if exit code == 0:
    parse stdout as JSON
    if result is empty object {}
    OR result contains only a "message" key (no other keys):
        → skip: silently discard, do not merge into combined_result
    else:
        → normal success: merge result into combined_result as today
```

The detection criterion — "only a `message` key" — is unambiguous: no legitimate plugin output would carry a `message` field without also carrying document metadata fields (like `filePath`, `mimeType`, `content`, etc.).

**Implementation sketch:**

```bash
plugin_output=$(run_plugin "$plugin_name" "$input_json")
plugin_exit=$?

if [ "$plugin_exit" -ne 0 ]; then
  ui_error "Plugin '$plugin_name' failed for file: $(basename "$file_path")"
  continue
fi

# Detect skip signal: {} or {"message":"..."}
key_count=$(echo "$plugin_output" | jq 'keys | length' 2>/dev/null || echo -1)
if [ "$key_count" -eq 0 ] || \
   { [ "$key_count" -eq 1 ] && echo "$plugin_output" | jq -e 'has("message")' > /dev/null 2>&1; }; then
  # Intentional skip — silently continue
  continue
fi

# Normal success — merge into combined result
combined_result=$(echo "$combined_result $plugin_output" | jq -s 'add')
```

#### 3. Exit Code Contract Summary

| Exit Code | stdout                             | Framework Interpretation |
|-----------|------------------------------------|--------------------------|
| Non-zero  | any                                | **Failure** — print error message |
| 0         | `{}` or `{"message":"..."}`        | **Intentional skip** — silent, no error |
| 0         | JSON with one or more data fields  | **Success** — merge into combined result |

This contract is minimal, unambiguous, and does not require any new descriptor fields or framework pre-checks.

#### 4. Data Flow Diagram

```
process_file("/path/to/image.png", ["file", "markitdown", "stat"])
  │
  ├─ run_plugin("file", ...)
  │    exit 0, output: {"filePath": "...", "mimeType": "image/png", ...}
  │    → merged into combined_result
  │
  ├─ run_plugin("markitdown", ...)
  │    markitdown/main.sh detects "image/png" is not supported
  │    exit 0, output: {"message": "skipped due to unsupported mime type"}
  │    → key_count == 1, has("message") == true → SILENT SKIP
  │
  └─ run_plugin("stat", ...)
       exit 0, output: {"fileSize": 42300, ...}
       → merged into combined_result
```


### Benefits

- **Plugin autonomy**: Each plugin retains full control over which inputs it processes. The framework does not need to know anything about MIME types, file sizes, or any other domain-specific skip criteria.
- **Simple, stable contract**: A single rule — "exit 0 with `{}` or a message-only object means skip" — covers all current and future skip reasons without protocol changes.
- **No descriptor changes needed**: Plugins are self-contained; no external metadata must be kept in sync with internal logic.
- **Accurate error signal**: Non-zero exits exclusively indicate genuine failures. Users and pipelines are no longer misled.
- **No framework pre-check complexity**: The framework does not need to parse MIME types, read descriptors before calls, or maintain a pre-screening layer.
- **Backward compatible**: Plugins that currently exit 0 with data JSON are completely unaffected.


### Challenges and Risks

- **Plugin adaptation required**: Any plugin that currently exits non-zero for "not my file type" must be updated to exit 0 with the skip signal. This is a one-time change per plugin (`markitdown`, `ocrmypdf`). Other plugins (`file`, `stat`) do not need changes.
- **Ambiguity if a future plugin legitimately produces only a `message` field**: A plugin that intentionally returns `{"message": "some diagnostic text"}` as real output would be indistinguishable from a skip signal. Plugin authors must be clearly documented to never use `message` as a lone top-level data field. The convention must be written into the developer guide.
- **JSON parse failure on skip detection**: If stdout is not valid JSON (e.g., the plugin printed a warning line before the JSON), the `jq` parse will return -1 key count, falling through to the failure path. This is acceptable and correct — malformed output is a genuine problem.


### Implementation Plan

1. **Update `markitdown/main.sh`**: Change the unsupported MIME type exit path from non-zero exit to `echo '{"message":"skipped due to unsupported mime type"}'; exit 0`.
2. **Update `ocrmypdf/main.sh`** (if applicable): Same change for any unsupported MIME type early-exit.
3. **Update `run_plugin` / `process_file`** (`plugin_execution.sh`): Add skip-signal detection after exit-0 check, as described in §2.
4. **Update developer guide**: Document the skip protocol convention in `project_documentation/04_dev_guide/dev_guide.md` — the `message`-only rule, the `{}` alternative, and the prohibition on `message` as a lone data field.
5. **Test**: Add a test in `tests/` verifying that processing a mixed document collection produces no error output for MIME-type mismatches, and that genuine plugin failures still produce error output.
6. **Regression**: Run the full existing test suite.


### Conclusion

The skip protocol places the skip decision where it belongs — inside the plugin — and requires the framework to do nothing more than detect a well-defined, lightweight signal (exit 0 with an empty or message-only JSON object) and discard it silently. This eliminates misleading error output, preserves plugin autonomy, keeps the framework free of domain-specific pre-check logic, and requires only a small, targeted change to the affected plugins and the `run_plugin` handling code.


### References

- [REQ_0039 Silent Skip for Unsupported MIME Types](../../../02_requirements/03_accepted/REQ_0039_silent-skip-unsupported-mime-types.md)
- [ARC_0003 Plugin Architecture](ARC_0003_plugin_architecture.md)
- [ARC_0004 Error Handling](ARC_0004_error_handling.md)
- [plugin_execution.sh](../../../../doc.doc.md/components/plugin_execution.sh) — `run_plugin` and `process_file` implementation
- [markitdown/main.sh](../../../../doc.doc.md/plugins/markitdown/main.sh) — current non-zero exit on unsupported MIME type
- [ocrmypdf/main.sh](../../../../doc.doc.md/plugins/ocrmypdf/main.sh) — current non-zero exit on unsupported MIME type
- [Project Goals TODO 1](../../../01_project_goals/project_goals.md)
