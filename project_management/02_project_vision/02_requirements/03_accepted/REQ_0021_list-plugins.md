# Requirement: List Plugins Command

- **ID:** REQ_0021
- **State:** Accepted
- **Type:** Functional
- **Priority:** Medium
- **Created at:** 2026-02-25
- **Last Updated:** 2026-02-25

## Overview
The system shall provide commands to list available plugins with optional filtering by activation status.

## Description
The tool must support listing plugins with the following command variations:

### Command Variations
- `doc.doc.sh list plugins`: Lists all available plugins, both active and inactive
- `doc.doc.sh list plugins active`: Lists only active plugins
- `doc.doc.sh list plugins inactive`: Lists only inactive plugins

The output should display plugin names and clearly indicate their activation status.

## Motivation
Derived from [project_management/02_project_vision/01_project_goals/project_goals.md](../../01_project_goals/project_goals.md):
- "**Command:** `doc.doc.sh list plugins` - Lists all available plugins, both active and inactive."
- "**Command:** `doc.doc.sh list plugins active` - Lists all active plugins."
- "**Command:** `doc.doc.sh list plugins inactive` - Lists all inactive plugins."

## Acceptance Criteria
- [ ] Command can be invoked as `doc.doc.sh list plugins`
- [ ] Without filter, displays all plugins regardless of state
- [ ] With `active` filter, displays only active plugins
- [ ] With `inactive` filter, displays only inactive plugins
- [ ] Output shows plugin names clearly
- [ ] Output indicates activation status for each plugin
- [ ] Invalid filter parameters show clear error messages

## Related Requirements
- REQ_0003 (Plugin-Based Architecture)
- REQ_0024 (Activate Plugin)
- REQ_0025 (Deactivate Plugin)
