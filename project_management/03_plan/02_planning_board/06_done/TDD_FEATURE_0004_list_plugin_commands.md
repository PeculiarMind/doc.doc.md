# TDD Task: List Plugin Commands

- **ID:** TDD_FEATURE_0004
- **Priority:** MEDIUM
- **Type:** TDD Task
- **Created at:** 2026-03-04
- **Created by:** developer.agent
- **Status:** DONE
- **Assigned to:** tester.agent
- **Related Feature:** FEATURE_0004

## Overview

Implement failing tests for FEATURE_0004 following TDD workflow.
Tests cover all acceptance criteria for the `list --plugin <name> --commands` CLI command.

## Acceptance Criteria Covered

### Command Parsing
- `list --plugin <name> --commands` accepted without error
- `--plugin` and `--commands` can appear in either order
- `--plugin` without `--commands` prints error to stderr and exits 1
- `--commands` without `--plugin` prints error to stderr and exits 1
- Unknown plugin name prints error to stderr and exits 1
- Missing descriptor.json prints error to stderr and exits 1
- Invalid JSON descriptor prints error to stderr and exits 1

### Output Format
- Output printed to stdout
- Each command listed in `<name>\t<description>` format
- Output sorted alphabetically by command name
- Exit code 0 on success

### CLI Help
- `--help` documents `list --plugin <name> --commands`
- `--plugin` and `--commands` flags described in usage

## Test File

`tests/test_feature_0004.sh`
