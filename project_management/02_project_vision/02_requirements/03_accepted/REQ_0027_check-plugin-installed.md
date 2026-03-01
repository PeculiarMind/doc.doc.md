# Requirement: Check Plugin Installation Command

- **ID:** REQ_0027
- **State:** Accepted
- **Type:** Functional
- **Priority:** Low
- **Created at:** 2026-02-25
- **Last Updated:** 2026-02-25

## Overview
The system shall provide a command to check if a plugin is installed.

## Description
The tool must support a `doc.doc.sh installed --plugin <plugin_name>` command that checks whether a specified plugin is installed.

## Motivation
Derived from [project_management/02_project_vision/01_project_goals/project_goals.md](../../01_project_goals/project_goals.md):
- "**Command:** `doc.doc.sh installed --plugin <plugin_name>`"
- "Checks if a plugin is installed."

## Acceptance Criteria
- [ ] Command can be invoked as `doc.doc.sh installed --plugin <name>` or with `-p` short form
- [ ] Command checks plugin installation status
- [ ] Output clearly indicates whether plugin is installed
- [ ] Command handles non-existent plugins appropriately

## Related Requirements
- REQ_0003 (Plugin-Based Architecture)
- REQ_0026 (Install Plugin)
