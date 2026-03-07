## Custom Base Path Parameter: `--base-path` / `-b`

**Author:** Architect Agent
**Created on:** 2026-03-07
**Last Updated:** 2026-03-07
**Status:** Accepted


**Version History**
| Date       | Author          | Description               |
|------------|-----------------|---------------------------|
| 2026-03-07 | Architect Agent | Initial draft             |
| 2026-03-07 | Architect Agent | Code review: fix cmd_process→main() reference; document JSON stdout impact of filePath rewrite; lock backward-compat recommendation (Option 1) |
| 2026-03-07 | Product Owner | Correction: base-path rewrite is render-time only; combined_result.filePath must remain the real filesystem path throughout processing |

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

`doc.doc.sh process` generates markdown sidecar files in an output directory, each containing a link to the corresponding source document via the `{{filePath}}` template variable. Currently that link is the absolute filesystem path of the source file (e.g., `/home/user/documentstore/contracts/2024/acme.pdf`). This path is valid from the machine where `doc.doc.sh` was run, but it ceases to be valid when:

1. The sidecar files are accessed from a different machine or user account.
2. The sidecar files and their source documents are managed through a tool (such as an Obsidian vault) that provides its own directory abstraction via symlinks — the vault sees the files through mounted paths that differ from the processing-time filesystem paths.

In the Obsidian use case described in REQ_0041:

```
/home/user/documentstore/           ← input directory (processing time)
/home/user/doc.doc.out/             ← output directory (processing time)
/home/user/obsidianvault/attachments → symlink → documentstore
/home/user/obsidianvault/documents  → symlink → doc.doc.out
```

A sidecar file opened in Obsidian from `documents/contracts/2024/acme.md` expects its source link to resolve relative to the vault — e.g., `../attachments/contracts/2024/acme.pdf`. The absolute processing-time path `/home/user/documentstore/contracts/2024/acme.pdf` is meaningless inside the vault.

The `--base-path` parameter provides the missing bridge: the user specifies the root from which source document references in sidecar files should be computed, independent of where the tool, the input documents, and the output files actually reside on disk during processing.


### Scope

This concept defines the semantics of `--base-path`, how it is parsed and validated, how it flows through the call chain, and how it modifies the path value injected into the template rendering step. It does not change plugin behaviour, MIME filtering, output directory structure, or template syntax.


### In Scope

- CLI parameter `--base-path` (long form) and `-b` (short form) for the `process` sub-command
- Default behaviour: input directory is used as the base path when the parameter is omitted (backward-compatible)
- Validation of the supplied base path (must be a directory that exists on the filesystem)
- Relative path resolution at the template rendering stage: `filePath` in the result JSON is rewritten to be the path of the source file relative to the resolved base path
- Threading the base path value from CLI parsing through to the template rendering call
- Updates to `ui.sh` help text (`ui_usage`) to document the new parameter
- Acceptance of both absolute and relative values (relative resolved from current working directory)


### Out of Scope

- Changes to plugin `main.sh` scripts or plugin descriptors
- Changes to the output directory structure or sidecar filename conventions
- Changes to the template file format or the introduction of new template variables beyond redefining `{{filePath}}`
- Symlink-following or canonicalisation of the source document paths beyond what is already done
- Validation that the base path is an ancestor of the input directory
- Multi-base-path configurations
- REQ_0008 Obsidian vault detection or auto-configuration


### Proposed Solution

#### 1. Semantic Distinction Between the Three Paths

| Parameter | Purpose | Default |
|---|---|---|
| `--input-directory` / `-d` | Root of source documents to discover and process | (required) |
| `--output-directory` / `-o` | Root of the mirror tree where sidecar `.md` files are written | (required) |
| `--base-path` / `-b` | Reference root used when computing relative links inside sidecar files | Input directory |

The three paths are **independent**. The base path is a purely logical reference point used at link-generation time; it does not affect which files are discovered, where output files are written, or which plugins run.

Concrete example from REQ_0041:

```
input directory:   /home/user/documentstore/
output directory:  /home/user/doc.doc.out/
base path:         /home/user/doc.doc.out/../attachments
                   → resolves to /home/user/attachments
                   → but user intends: ../attachments (relative to output dir)
```

A user invoking the tool from the output directory might supply `--base-path ../attachments`; the framework resolves this relative to CWD at parse time and validates the result.

#### 2. CLI Parsing

The new parameter is added to the `while` loop in `main()` in `doc.doc.sh` (note: there is no `cmd_process` function; the process sub-command argument parsing is inline in `main()`):

```bash
local base_path=""

# Inside the while loop:
-b|--base-path)
  [ $# -ge 2 ] || { echo "Error: $1 requires an argument" >&2; exit 1; }
  base_path="$2"
  shift 2
  ;;
```

After the loop, default assignment and validation:

```bash
# Default to input_dir when --base-path is not supplied
if [ -z "$base_path" ]; then
  base_path="$input_dir"
fi

# Resolve relative paths from CWD
base_path="$(readlink -f "$base_path" 2>/dev/null || echo "")"
if [ -z "$base_path" ]; then
  echo "Error: Cannot resolve base path" >&2
  exit 1
fi

# Validate existence
if [ ! -d "$base_path" ]; then
  echo "Error: Base path does not exist or is not a directory: $base_path" >&2
  exit 1
fi
```

This validation runs before any file discovery or plugin execution, satisfying the REQ_0041 requirement that an invalid `--base-path` produces an error before processing begins.

#### 3. Path Rewriting at Template Rendering Time Only

The `--base-path` transformation is applied **exclusively at template rendering time**. The `filePath` key inside `combined_result` — which accumulates the plugin outputs throughout the entire processing run — is **never mutated**. This is essential because plugins that execute after the `file` plugin may still need to read the source file from the real filesystem path.

The rewrite works as follows: immediately before calling `render_template_json`, a **render-time copy** of `combined_result` is created with `filePath` replaced by the base-path-relative link. This copy is passed to the template renderer; `combined_result` itself is left unchanged.

```bash
# After process_file() returns combined_result — combined_result.filePath is
# still the real filesystem path and is NOT modified here.

local render_json="$result"   # start with a copy

if [ -n "$base_path" ]; then
  local source_abs_path
  source_abs_path=$(echo "$result" | jq -r '.filePath // empty')

  if [ -n "$source_abs_path" ]; then
    local relative_link
    relative_link=$(python3 -c \
      "import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" \
      "$source_abs_path" "$base_path")
    # Rewrite only the render-time copy — combined_result stays untouched
    render_json=$(echo "$result" | jq --arg rl "$relative_link" '.filePath = $rl')
  fi
fi

render_template_json "$template_file" "$render_json"
# (echo "$result" to stdout for the JSON pipeline uses the original, unmodified result)
```

**What stays unchanged:**
- `combined_result` / `result` — retains the real filesystem path for the entire processing run
- The JSON array streamed to stdout (for pipeline consumers) — unchanged; still contains the real filesystem path
- Plugin inputs on subsequent invocations — unaffected

**What changes (only when `--base-path` is supplied):**
- `{{filePath}}` in the rendered sidecar markdown file — uses the base-path-relative link

**Why a render-time copy rather than a new template variable:**
The `{{filePath}}` variable already appears in `doc.doc.md/templates/default.md` and in user-defined custom templates. Introducing a separate `{{relativeFilePath}}` variable would require existing templates to be updated to benefit from the feature, breaking backward compatibility for template authors. Rewriting `filePath` only in the render-time copy means existing templates automatically use the base-path-relative link when `--base-path` is supplied, with no template changes required, and the real path is preserved everywhere else.

#### 4. Call Chain Summary

```
CLI: doc.doc.sh process -d /input -o /output -b /vault/attachments
  │
  ├─ [Parse] base_path = "/vault/attachments"
  ├─ [Validate] readlink -f → "/vault/attachments" (exists, is dir)
  │
  ├─ [Per file: /input/contracts/acme.pdf]
  │    process_file() → combined_result = {filePath: "/input/contracts/acme.pdf", ...}
  │    combined_result.filePath is UNCHANGED — real filesystem path retained
  │
  │    [Render-time only — temporary render_json copy:]
  │    relpath("/input/contracts/acme.pdf", "/vault/attachments")
  │      → "../../input/contracts/acme.pdf"
  │    render_json.filePath ← "../../input/contracts/acme.pdf"
  │    render_template_json(template, render_json)
  │      → "=> [acme.pdf](../../input/contracts/acme.pdf)"
  │
  │    [JSON stdout — uses original combined_result, NOT render_json:]
  │    echo "$combined_result"  → {filePath: "/input/contracts/acme.pdf", ...}
  │
  └─ [Sidecar written to /output/contracts/acme.pdf.md]
```

#### 5. `ui_usage` Update

The `ui_usage` function in `ui.sh` must be updated to document the new parameter:

```
  -b <path>, --base-path <path>
                 Reference root for links in generated markdown files.
                 Accepts absolute or relative paths (resolved from CWD).
                 Must be an existing directory. Defaults to the input directory.
                 Example: --base-path /vault/attachments
```

The `Examples:` block should include a usage example with `--base-path`.


### Benefits

- **Obsidian compatibility**: Users can generate sidecar files whose links resolve correctly within an Obsidian vault, even when the vault uses symlinks to bridge processing-time and management-time paths.
- **Portability**: Relative links in generated markdown are not tied to absolute processing-time paths, making sidecar files portable across machines and user accounts.
- **Backward compatible by design**: The parameter is optional; omitting it preserves existing behaviour (subject to the open question on default path format).
- **Minimal implementation surface**: The change is confined to `doc.doc.sh` (argument parsing, validation, per-file path rewriting) and `ui.sh` (help text). No plugin, filter, or template changes are required.
- **Self-documenting via help text**: The parameter and its distinct purpose are clearly documented in `--help` output.


### Challenges and Risks

- **Backward compatibility of default path format**: As decided in §3, path rewriting is applied **only when `--base-path` is explicitly supplied**. `combined_result` is never mutated. This eliminates the risk of breaking existing users or downstream JSON consumers.
- **JSON stdout is unaffected**: Because `combined_result.filePath` is never modified, the JSON array emitted to stdout always contains the real filesystem path, regardless of whether `--base-path` is supplied. Pipeline consumers who previously relied on absolute paths continue to receive them without change.
- **Relative path resolution**: Supplying a relative `base_path` that is resolved from CWD may surprise users who invoke the tool from an unexpected working directory. The error message for a non-existent resolved path should quote the resolved value, not just the user-supplied value, so users can diagnose the issue.
- **Symlink transparency**: `readlink -f` canonicalises symlinks. If the user supplies a symlinked `--base-path`, the canonical path is used internally. This may produce different relative paths than the user expects if the symlink target differs in depth from the symlink location. Mitigation: document this behaviour in the help text and ops guide.
- **`os.path.relpath` on divergent paths**: If the source file and the base path share no common ancestor (e.g., different Windows drive letters, not applicable on Linux), `relpath` still produces a valid but deeply nested `../../..` path. On Linux this is never a problem, but it is worth noting for cross-platform future work.
- **Template authors using absolute `{{filePath}}`**: Users with custom templates that rely on the absolute path form will see link changes when they adopt `--base-path`. This is expected and documented behaviour; no mitigation beyond documentation is required.


### Implementation Plan

1. **`doc.doc.sh` argument parsing**: Add `--base-path` / `-b` to the `main()` while-loop, default/validation logic, and per-file path rewriting (§2 and §3). There is no `cmd_process` function; all changes are inside `main()`.
2. **`ui.sh` `ui_usage`**: Add `--base-path` documentation to the `process Options` block and `Examples` (§5).
3. **Test**: Create `tests/test_feature_0041.sh` covering:
   - `--base-path` with an absolute path produces expected relative links in sidecar files
   - `--base-path` with a relative path is accepted and resolved correctly
   - `--base-path` with a non-existent path produces a validation error before any processing
   - Omitting `--base-path` preserves pre-existing behaviour (no regression)
   - `-b` short form is accepted as equivalent to `--base-path`
4. **`ui_usage`**: Verify `--help` output includes the new parameter.
5. **Regression**: Run the existing test suite.
6. **Documentation**: Update `project_documentation/03_user_guide/user_guide.md` with an Obsidian vault usage example demonstrating `--base-path`.


### Conclusion

The `--base-path` parameter is a focused, composable extension to the `process` command. It does not change plugin execution, file discovery, or output directory layout. Its sole effect is to rewrite the `filePath` value in the template rendering context (and the JSON stdout stream) when the flag is explicitly supplied, replacing the processing-time file path with a user-specified relative reference root. Backward compatibility is fully preserved when the parameter is omitted — path rewriting is opt-in only (Option 1, see §3).


### References

- [REQ_0041 Custom Base Path Parameter](../../../02_requirements/03_accepted/REQ_0041_custom-base-path-parameter.md)
- [REQ_0008 Obsidian Compatibility](../../../02_requirements/03_accepted/REQ_0008_obsidian-compatibility.md)
- [REQ_0013 Directory Mirroring](../../../02_requirements/03_accepted/REQ_0013_directory-mirroring.md)
- [REQ_0038 Backward-Compatible CLI](../../../02_requirements/03_accepted/REQ_0038_backward-compatible-cli.md)
- [ARC_0002 Template Processing](ARC_0002_template_processing.md)
- [templates.sh](../../../../doc.doc.md/components/templates.sh) — `render_template_json` implementation
- [doc.doc.sh](../../../../doc.doc.sh) — CLI parsing and process command handler
- [default.md template](../../../../doc.doc.md/templates/default.md) — shows `{{filePath}}` usage
- [Project Goals TODO 3](../../../01_project_goals/project_goals.md)
