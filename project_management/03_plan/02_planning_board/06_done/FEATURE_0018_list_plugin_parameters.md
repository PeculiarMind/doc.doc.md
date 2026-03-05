# List Plugin Parameters Command

- **ID:** FEATURE_0018
- **Priority:** Medium
- **Type:** Feature
- **Created at:** 2026-03-05
- **Created by:** Product Owner
- **Status:** DONE
- **Assigned to:** developer

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

Extend `doc.doc.sh list` with two new argument combinations that display the parameters (both input and output) declared by plugins:

| Command | Description |
|---------|-------------|
| `doc.doc.sh list parameters` | Lists all parameters for every command of every installed plugin |
| `doc.doc.sh list --plugin <name> --parameters` | Lists all parameters for every command of one specific plugin |

Parameters are read directly from the `input` and `output` blocks in each plugin's `descriptor.json` and rendered in a human-readable tabular format. Each parameter row includes a `DIRECTION` column (`input` or `output`) to make the flow immediately clear.

**Current state:** Users can discover plugin commands via `list --plugin <name> --commands` (FEATURE_0004, DONE) but cannot inspect what parameters each command accepts or produces without opening `descriptor.json` manually.

**Business value:**
- Makes the plugin contract fully self-documenting from the CLI — no need to inspect raw JSON files
- Enables users to construct correct input when invoking plugins programmatically or via scripts
- Consistent extension of the existing `list` surface; follows the same discoverability pattern established by FEATURE_0004 and FEATURE_0008
- Reduces onboarding friction for new plugin authors and power users

**What this delivers:**
- `doc.doc.sh list parameters` — aggregated parameter listing across all plugins and all their commands
- `doc.doc.sh list --plugin <name> --parameters` — scoped parameter listing for one plugin
- Consistent column-aligned output covering: command, **direction** (input/output), parameter name, type, required/optional, default value (input only), and description
- Updated `usage()` / `--help` text
- Clear error handling for unknown plugins and invalid flag combinations

## Acceptance Criteria

### `list parameters` (all plugins)

- [ ] `doc.doc.sh list parameters` exits with code 0
- [ ] Output covers every plugin in `PLUGIN_DIR` that has a valid `descriptor.json`
- [ ] For each plugin, all commands that declare an `input` or `output` block are included
- [ ] For each such command, every parameter in the `input` block is printed as one line with direction `input`
- [ ] For each such command, every parameter in the `output` block is printed as one line with direction `output`
- [ ] Each line includes: plugin name, command name, direction, parameter name, type, required/optional, default (if any, input parameters only), and description
- [ ] Output is sorted: first by plugin name alphabetically, then by command name, then by direction (`input` before `output`), then by parameter name
- [ ] Commands with neither an `input` nor an `output` block are silently skipped (no error)
- [ ] If no plugins exist, output is empty and exit code is 0

### `list --plugin <name> --parameters` (single plugin)

- [ ] `doc.doc.sh list --plugin <name> --parameters` exits with code 0
- [ ] Output covers only the named plugin
- [ ] `--plugin` and `--parameters` can appear in either order
- [ ] Each line includes: command name, direction, parameter name, type, required/optional, default (if any, input parameters only), and description
- [ ] Output is sorted by command name, then direction (`input` before `output`), then parameter name
- [ ] If the named plugin has no commands with an `input` or `output` block, output is empty and exit code is 0
- [ ] If the named plugin directory does not exist in `PLUGIN_DIR`, print a clear error to stderr and exit 1
- [ ] If `descriptor.json` is missing or invalid JSON, print a clear error to stderr and exit 1

### Flag Validation

- [ ] `--parameters` given without `--plugin <name>` is rejected with a clear error to stderr and exit 1 (the global `list parameters` form is the intended syntax for all-plugin listing — the scoped `--parameters` flag always requires `--plugin`)
- [ ] `--plugin <name>` given with neither `--commands` nor `--parameters` prints a clear error to stderr and exits 1
- [ ] `list parameters extra_arg` prints a clear error to stderr and exits 1

### Output Format

- [ ] All columns are space-padded for alignment
- [ ] A `DIRECTION` column is present with value `input` or `output` for every row
- [ ] The `REQUIRED` field is rendered as `required` or `optional` for `input` parameters; output parameters render this column as `-`
- [ ] The `DEFAULT` field is rendered as `default:<value>` when present on an input parameter, or `-` when absent or for output parameters
- [ ] Output goes to stdout; errors go to stderr

**Example — `list parameters` (all plugins, truncated):**
```
PLUGIN      COMMAND   DIRECTION  PARAMETER   TYPE     REQUIRED   DEFAULT      DESCRIPTION
file        process   input      filePath    string   required   -            Path to the file to identify.
file        process   output     mimeType    string   -          -            Detected MIME type of the file.
ocrmypdf    process   input      filePath    string   required   -            Path to the PDF or image file to process.
ocrmypdf    process   input      imageDpi    integer  optional   default:300  DPI to use when processing image inputs.
ocrmypdf    process   input      mimeType    string   required   -            MIME type of the input file.
ocrmypdf    process   output     ocrText     string   -          -            Full plain-text content extracted by OCR.
stat        process   input      filePath    string   required   -            Path to the file to stat.
```

**Example — `list --plugin ocrmypdf --parameters`:**
```
COMMAND   DIRECTION  PARAMETER   TYPE     REQUIRED   DEFAULT      DESCRIPTION
convert   input      filePath    string   required   -            Path to the input image file.
convert   input      imageDpi    integer  optional   default:300  DPI to use when processing the image.
convert   input      outputPath  string   optional   -            Path for the output PDF.
convert   output     outputPath  string   -          -            Path to the resulting PDF file.
process   input      filePath    string   required   -            Path to the PDF or image file to process.
process   input      imageDpi    integer  optional   default:300  DPI to use when processing image inputs.
process   input      mimeType    string   required   -            MIME type of the input file.
process   output     ocrText     string   -          -            Full plain-text content extracted by OCR.
```

### CLI Help

- [ ] `doc.doc.sh --help` output documents both `list parameters` and `list --plugin <name> --parameters`
- [ ] `doc.doc.sh list --help` output includes both variants alongside existing `list plugins` and `list --plugin <name> --commands` entries

## Scope

**In scope:**
- Displaying both `input` and `output` parameters with a `DIRECTION` column indicating which is which
- All commands that declare an `input` or `output` block
- Column-aligned human-readable output
- Sorted output (plugin → command → direction → parameter)
- `required`/`optional` and `default` shown for input parameters; `-` placeholder for output parameters in those columns
- Updated usage/help text
- Error handling for invalid flags, unknown plugins, missing/invalid `descriptor.json`

**Out of scope:**
- Machine-readable / JSON output format
- Filtering parameters by direction, type, or required status
- Modifying any plugin descriptor files
- Commands with neither an `input` nor an `output` block — silently skipped

## Technical Requirements

### `jq` Extraction

Both input and output parameters can be extracted from `descriptor.json` with:

```bash
jq -r '
  .name as $plugin |
  .commands | to_entries[] |
  .key as $cmd |
  .value as $cmdval |
  (
    ($cmdval.input // {} | to_entries[] |
      [$plugin, $cmd, "input", .key, .value.type,
       (if .value.required then "required" else "optional" end),
       (.value.default | if . != null then "default:\(.)" else "-" end),
       .value.description]
    ),
    ($cmdval.output // {} | to_entries[] |
      [$plugin, $cmd, "output", .key, .value.type, "-", "-",
       .value.description]
    )
  ) | @tsv
' descriptor.json | sort
```

For the single-plugin form, omit the `.name as $plugin` injection and drop the first (`PLUGIN`) column.

### Column Alignment

Use `column -t -s $'\t'` (or equivalent `printf`-based formatting) to produce aligned output from the tab-separated `jq` output.

### Integration with Existing `list` Handler

Extend the existing `cmd_list` function in `doc.doc.sh`:

```bash
cmd_list() {
  case "$1" in
    plugins)    cmd_list_plugins "$@" ;;
    parameters) cmd_list_parameters_all ;;  # NEW
    "")         usage_list; exit 1 ;;
    *)
      # existing --plugin / --commands handling + NEW --parameters
      ;;
  esac
}
```

### Architecture Compliance

- JSON parsing uses `jq` (existing dependency — no new external tools)
- Output only to stdout; errors only to stderr
- No plugin processes are invoked — read-only inspection of `descriptor.json`

## Dependencies

- REQ_0030 (List Plugin Commands) — defines the `list --plugin <name> --commands` contract this feature extends
- REQ_0002 (Modular and Extensible Architecture)
- REQ_0003 (Plugin-Based Architecture) — plugin discovery and `descriptor.json` structure
- FEATURE_0004 (List Plugin Commands, DONE) — existing `--plugin` / `--commands` flag infrastructure
- FEATURE_0008 (List Plugins Commands, DONE) — existing `list plugins` sub-command infrastructure

## Related Links

- Project Goals: [project_goals.md](../../../02_project_vision/01_project_goals/project_goals.md)
- Requirements: [REQ_0030](../../../02_project_vision/02_requirements/03_accepted/REQ_0030_list-plugin-commands.md), [REQ_0002](../../../02_project_vision/02_requirements/03_accepted/REQ_0002_modular-extensible-architecture.md), [REQ_0003](../../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-based-architecture.md)
- Architecture: [05_building_block_view.md](../../../../project_documentation/01_architecture/05_building_block_view/05_building_block_view.md)
