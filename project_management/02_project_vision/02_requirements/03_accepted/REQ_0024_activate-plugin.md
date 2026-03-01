# Requirement: Activate Plugin Command

- **ID:** REQ_0024
- **State:** Accepted
- **Type:** Functional
- **Priority:** High
- **Created at:** 2026-02-25
- **Last Updated:** 2026-02-25

## Overview
The system shall provide a command to activate plugins.

## Description
The tool must support a `doc.doc.sh activate --plugin <plugin_name>` command that activates a specified plugin, making it available for use in document processing.

## Motivation
Derived from [project_management/02_project_vision/01_project_goals/project_goals.md](../../01_project_goals/project_goals.md):
- "**Command:** `doc.doc.sh activate --plugin <plugin_name>`"
- "Activates a plugin, making it available for use in document processing."

## Acceptance Criteria
- [ ] Command can be invoked as `doc.doc.sh activate --plugin <name>` or with `-p` short form
- [ ] Command activates the specified plugin
- [ ] Plugin becomes available for document processing
- [ ] Attempting to activate non-existent plugin shows clear error
- [ ] Attempting to activate already-active plugin is handled gracefully

## Related Requirements
- REQ_0003 (Plugin-Based Architecture)
- REQ_0021 (List Plugins Command)
- REQ_0025 (Deactivate Plugin)
