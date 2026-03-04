# Requirement: List Plugin Commands

- **ID:** REQ_0030
- **State:** Accepted
- **Type:** Functional
- **Priority:** Medium
- **Created at:** 2026-03-02
- **Last Updated:** 2026-03-02

## Overview
The system shall allow users to list the available commands of a specific plugin via `doc.doc.sh list --plugin <plugin_name> --commands`.

## Description
The `list` command shall be extended with `--plugin <plugin_name> --commands` flags that display all commands declared in the plugin's `descriptor.json`. For each command, the output shall include the command name and its description.

### Command Variation
- `doc.doc.sh list --plugin <plugin_name> --commands`: Lists all commands of the named plugin with their descriptions

The output shall be human-readable and printed to stdout.

## Motivation
Users need discoverability: once a plugin is installed, they should be able to inspect what commands it exposes without reading `descriptor.json` manually. This is consistent with the existing `list plugins` command that surfaces available plugins, extending the CLI's self-documentation capability.

## Acceptance Criteria
- [ ] Command can be invoked as `doc.doc.sh list --plugin <plugin_name> --commands`
- [ ] Output lists every command name declared in the plugin's `descriptor.json`
- [ ] Output includes the description of each command
- [ ] If the plugin does not exist, a clear error message is shown and exit code is non-zero
- [ ] If `--plugin` is given without `--commands`, a clear error message is shown
- [ ] If `--commands` is given without `--plugin`, a clear error message is shown
- [ ] Command works for both active and inactive plugins

## Related Requirements
- REQ_0003 (Plugin-Based Architecture)
- REQ_0021 (List Plugins Command)
