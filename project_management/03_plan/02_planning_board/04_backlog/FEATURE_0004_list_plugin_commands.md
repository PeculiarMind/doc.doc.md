# List Plugin Commands

- **ID:** FEATURE_0004
- **Priority:** MEDIUM
- **Type:** Feature
- **Created at:** 2026-03-02
- **Created by:** Product Owner
- **Status:** BACKLOG

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

Extend `doc.doc.sh list` with `--plugin <plugin_name> --commands` flags that display all commands declared by a given plugin. The implementation reads from the plugin's `descriptor.json` and prints each command name and description to stdout.

**Business Value:**
- Improves CLI discoverability — users can inspect a plugin's interface without opening files
- Consistent with the existing `list plugins` command; extends the same `list` surface
- Makes the plugin contract self-documenting at runtime

**What this delivers:**
- New argument combination: `doc.doc.sh list --plugin <name> --commands`
- Human-readable output listing each command with its description
- Proper error handling for unknown plugin names and missing flags

## Acceptance Criteria

### Command Parsing

- [ ] `doc.doc.sh list --plugin <plugin_name> --commands` is accepted without error
- [ ] `--plugin` and `--commands` can appear in either order
- [ ] If `--plugin <name>` is given without `--commands`, print a clear error to stderr and exit 1
- [ ] If `--commands` is given without `--plugin <name>`, print a clear error to stderr and exit 1
- [ ] If the named plugin directory does not exist in `PLUGIN_DIR`, print a clear error to stderr and exit 1
- [ ] If the plugin's `descriptor.json` does not exist or is not valid JSON, print a clear error to stderr and exit 1

### Output Format

- [ ] Output is printed to stdout
- [ ] Each command is listed on its own line in the format:
  ```
  <command_name>  <description>
  ```
- [ ] Output is sorted alphabetically by command name
- [ ] Exit code is 0 on success

**Example interaction:**
```bash
$ doc.doc.sh list --plugin stat --commands
install    Install the stat plugin if it is not already installed.
installed  Check if the stat plugin is installed and available for use.
process    Get statistical information about a file.
```

### CLI Help

- [ ] The main `--help` / `usage()` output is updated to document `list --plugin <name> --commands`
- [ ] The `list` command section in usage describes the `--plugin` and `--commands` flags

### Code Quality

- [ ] Implementation added to `doc.doc.sh` following existing code style
- [ ] JSON parsing uses `jq`
- [ ] No new external dependencies introduced
- [ ] shellcheck passes on the modified script

## Scope

### In Scope
✅ Parsing `--plugin` and `--commands` flags under the `list` command  
✅ Reading and displaying commands from `descriptor.json`  
✅ Error handling for missing/invalid plugin or flags  
✅ Updated `usage()` help text  

### Out of Scope
❌ Displaying command input/output parameter details (just name + description)  
❌ Machine-readable (JSON) output format  
❌ Filtering commands by type  
❌ Changes to any plugin descriptor files  

## Technical Requirements

### Implementation Details

The `list` command handler in `doc.doc.sh` currently does not exist — the script only handles `process`. This feature introduces a `list` branch in `main()`:

```bash
case "$command" in
  process)
    # existing logic
    ;;
  list)
    cmd_list "$@"
    ;;
  *)
    echo "Error: Unknown command '$command'." >&2; exit 1
    ;;
esac
```

The `cmd_list` function shall:
1. Parse `--plugin <name>` and `--commands` from its arguments
2. Resolve the plugin directory: `$PLUGIN_DIR/<plugin_name>/descriptor.json`
3. Validate existence and JSON validity
4. Extract and print commands using `jq`:
   ```bash
   jq -r '.commands | to_entries[] | "\(.key)\t\(.value.description)"' descriptor.json \
     | sort
   ```

### Architecture Compliance

- **ADR-003** does not apply (this is CLI output to stdout, not plugin communication)
- Reads `descriptor.json` directly — no plugin script invocation required
- Consistent with the self-documenting CLI design of the tool

### Required Tools
- bash 4.0+
- jq

## Dependencies

### Blocking Items
None

### Blocks These Features
None

### Related Requirements
- **REQ_0030**: List Plugin Commands — the requirement this feature implements
- **REQ_0021**: List Plugins Command — sibling command on the same `list` surface
- **REQ_0003**: Plugin-Based Architecture

## Related Links

### Requirements
- [REQ_0030: List Plugin Commands](../../../02_project_vision/02_requirements/03_accepted/REQ_0030_list-plugin-commands.md)
- [REQ_0021: List Plugins Command](../../../02_project_vision/02_requirements/03_accepted/REQ_0021_list-plugins.md)
- [REQ_0003: Plugin-Based Architecture](../../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-system.md)

### Existing Plugin Descriptors (test targets)
- [stat descriptor](../../../../doc.doc.md/plugins/stat/descriptor.json)
- [file descriptor](../../../../doc.doc.md/plugins/file/descriptor.json)
