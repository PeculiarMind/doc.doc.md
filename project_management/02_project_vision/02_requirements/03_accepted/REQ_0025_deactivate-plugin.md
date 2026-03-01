# Requirement: Deactivate Plugin Command

- **ID:** REQ_0025
- **State:** Accepted
- **Type:** Functional
- **Priority:** High
- **Created at:** 2026-02-25
- **Last Updated:** 2026-02-25

## Overview
The system shall provide a command to deactivate plugins.

## Description
The tool must support a `doc.doc.sh deactivate --plugin <plugin_name>` command that deactivates a specified plugin, making it unavailable for use in document processing.

## Motivation
Derived from [project_management/02_project_vision/01_project_goals/project_goals.md](../../01_project_goals/project_goals.md):
- "**Command:** `doc.doc.sh deactivate --plugin <plugin_name>`"
- "Deactivates a plugin, making it unavailable for use in document processing."

## Acceptance Criteria
- [ ] Command can be invoked as `doc.doc.sh deactivate --plugin <name>` or with `-p` short form
- [ ] Command deactivates the specified plugin
- [ ] Plugin becomes unavailable for document processing
- [ ] Attempting to deactivate non-existent plugin shows clear error
- [ ] Attempting to deactivate already-inactive plugin is handled gracefully

## Related Requirements
- REQ_0003 (Plugin-Based Architecture)
- REQ_0021 (List Plugins Command)
- REQ_0024 (Activate Plugin)
