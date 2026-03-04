# List Plugins Commands

- **ID:** FEATURE_0008
- **Priority:** HIGH
- **Type:** Feature
- **Created at:** 2026-03-04
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

Implement the `doc.doc.sh list plugins` family of commands as defined in the project goals and REQ_0021. These commands allow users to inspect the available plugins and their activation state directly from the CLI.

**Three sub-commands are required:**

| Command | Description |
|---------|-------------|
| `doc.doc.sh list plugins` | Lists all plugins (active and inactive) |
| `doc.doc.sh list plugins active` | Lists only active plugins |
| `doc.doc.sh list plugins inactive` | Lists only inactive plugins |

**Current state:** The `list` command only supports `--plugin <name> --commands` (FEATURE_0004, DONE). The `list plugins` sub-commands are completely unimplemented — calling them results in `Error: Unknown option 'plugins'`.

**Business Value:**
- Enables users to discover what plugins are available without inspecting files manually
- Allows quick checks of activation state to understand why certain files may or may not be processed
- Provides a self-documenting CLI consistent with the project goal of intuitive usability
- Foundation for future plugin management workflows (activate/deactivate)

**What this delivers:**
- `doc.doc.sh list plugins` — lists all plugin names with their activation status
- `doc.doc.sh list plugins active` — lists only active plugin names
- `doc.doc.sh list plugins inactive` — lists only inactive plugin names
- Updated `usage()` help text covering all three variants
- Clear error for invalid sub-arguments

## Acceptance Criteria

### `list plugins` (all)

- [ ] `doc.doc.sh list plugins` exits with code 0
- [ ] Output lists every plugin directory (with a valid `descriptor.json`) found in `PLUGIN_DIR`
- [ ] Each plugin is shown on its own line
- [ ] Each line includes the plugin name and its activation status (e.g. `stat  [active]` / `stat  [inactive]`)
- [ ] Both active and inactive plugins are included in the output
- [ ] Output is sorted alphabetically by plugin name
- [ ] If no plugins exist, output is empty and exit code is 0

### `list plugins active`

- [ ] `doc.doc.sh list plugins active` exits with code 0
- [ ] Output lists only plugins where `active` is `true` (or absent, defaulting to `true`) in `descriptor.json`
- [ ] Each plugin is shown on its own line with its name
- [ ] If no active plugins exist, output is empty and exit code is 0

### `list plugins inactive`

- [ ] `doc.doc.sh list plugins inactive` exits with code 0
- [ ] Output lists only plugins where `active` is explicitly `false` in `descriptor.json`
- [ ] Each plugin is shown on its own line with its name
- [ ] If no inactive plugins exist, output is empty and exit code is 0

### Error Handling

- [ ] `doc.doc.sh list plugins unknown_arg` prints a clear error to stderr and exits with code 1
- [ ] `doc.doc.sh list plugins active extra_arg` prints a clear error to stderr and exits with code 1

### Help / Usage

- [ ] `doc.doc.sh --help` output includes `list plugins`, `list plugins active`, and `list plugins inactive`
- [ ] `doc.doc.sh list --help` output includes all three `list plugins` variants and `--plugin --commands`

### Backward Compatibility

- [ ] `doc.doc.sh list --plugin <name> --commands` continues to work exactly as before (no regression)
- [ ] All existing tests in `tests/test_doc_doc.sh` continue to pass

## Scope

### In Scope
✅ `list plugins`, `list plugins active`, `list plugins inactive` sub-command parsing  
✅ Plugin discovery for all plugins (not just active ones, unlike current `discover_plugins`)  
✅ Activation status read from `descriptor.json` `.active` field  
✅ Alphabetically sorted output  
✅ Updated `usage()` help text  
✅ Error handling for invalid sub-arguments  

### Out of Scope
❌ Plugin installation status (whether `installed.sh` reports installed) — future feature  
❌ Machine-readable (JSON) output — future flag  
❌ Plugin version or description in list output — future enhancement  
❌ Activate/deactivate commands — separate features (REQ_0024, REQ_0025)  

## Technical Requirements

### Plugin Discovery (all, including inactive)

`components/plugins.sh` `discover_plugins` currently filters out inactive plugins. A new helper function (or an extra parameter) is needed to enumerate **all** plugins regardless of activation state:

```bash
discover_all_plugins() {
  local plugin_dir="$1"
  for dir in "$plugin_dir"/*/; do
    [ -d "$dir" ] || continue
    local descriptor="$dir/descriptor.json"
    [ -f "$descriptor" ] || continue
    jq -e '.name and .commands' "$descriptor" >/dev/null 2>&1 || continue
    basename "$dir"
  done | sort
}
```

### Activation Status Detection

```bash
is_plugin_active() {
  local descriptor="$1"
  local active
  active=$(jq -r 'if .active == false then "false" else "true" end' "$descriptor")
  echo "$active"
}
```

### `cmd_list` Extension

Add a `plugins` branch before the existing `--plugin` parsing:

```bash
cmd_list() {
  if [ "${1:-}" = "plugins" ]; then
    local filter="${2:-all}"
    case "$filter" in
      all|"")  _list_plugins "all" ;;
      active)  _list_plugins "active" ;;
      inactive) _list_plugins "inactive" ;;
      *)
        echo "Error: Unknown filter '$filter'. Use: plugins [active|inactive]" >&2
        exit 1
        ;;
    esac
    exit 0
  fi
  # ... existing --plugin / --commands parsing ...
}
```

### Architecture Compliance
- Reads `descriptor.json` directly — consistent with FEATURE_0004 approach
- No new external dependencies (bash + jq)
- Follows existing code style in `doc.doc.sh`

### Required Tools
- bash 4.0+
- jq

## Dependencies

### Blocking Items
None

### Blocks These Features
None

### Related Requirements
- **REQ_0021**: List Plugins Command — the primary requirement this feature implements
- **REQ_0003**: Plugin-Based Architecture
- **REQ_0024**: Activate Plugin Command — uses activation state set by this command's display
- **REQ_0025**: Deactivate Plugin Command

## Related Links

### Tests
- [`tests/test_list_plugins.sh`](../../../../tests/test_list_plugins.sh) — test suite for this feature (covers both implemented and unimplemented commands)

### Requirements
- [REQ_0021: List Plugins Command](../../../02_project_vision/02_requirements/03_accepted/REQ_0021_list-plugins.md)
- [REQ_0003: Plugin-Based Architecture](../../../02_project_vision/02_requirements/03_accepted/REQ_0003_plugin-system.md)

### Project Goals
- [project_goals.md — Plugin Management section](../../../02_project_vision/01_project_goals/project_goals.md)

### Related Features (already done)
- [FEATURE_0004: List Plugin Commands](../../06_done/FEATURE_0004_list_plugin_commands.md) — `list --plugin --commands` (DONE)
