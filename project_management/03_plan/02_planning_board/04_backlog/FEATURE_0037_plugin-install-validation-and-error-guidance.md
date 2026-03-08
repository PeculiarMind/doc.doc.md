# Feature: Plugin Install Validation and Error Guidance

- **ID:** FEATURE_0037
- **Priority:** High
- **Type:** Feature
- **Created at:** 2026-03-08
- **Created by:** Product Owner
- **Status:** BACKLOG

## TOC
1. [Overview](#overview)
2. [Motivation](#motivation)
3. [Scope](#scope)
4. [Implementation Notes](#implementation-notes)
5. [Acceptance Criteria](#acceptance-criteria)
6. [Dependencies](#dependencies)
7. [Related Links](#related-links)

## Overview

Improve three related commands — `process`, `install --plugin`, and `setup` — to provide consistent, actionable error guidance whenever an active plugin is not installed or fails to install. This feature implements the validation and failure-handling behavior described in the refined project goals (Processing Documents §1/§1.1, Setup, and Plugin Management — install command).

## Motivation

The current implementation silently skips or gives generic errors when plugins are not installed. The refined project vision defines a precise interactive flow:

- **`process`**: A Validation Phase (step 1) must check that all active plugins are installed before processing begins. In interactive mode, the user must be given a choice to continue without the plugin, abort, or trigger installation on-the-fly.
- **`install --plugin`**: Must validate the plugin name is known (listing available plugins if not), guard against redundant re-installation, and provide elevated-privilege advice when installation fails.
- **`setup`**: When installation of a plugin fails during setup, the user must receive both an error message and specific recovery advice (e.g. `sudo ./doc.doc.sh install --plugin <plugin_name>` or `sudo ./doc.doc.sh setup`), then exit non-zero.

These three flows share the same conceptual gap: missing actionable guidance when a plugin is absent or cannot be installed.

## Scope

### 1 — `process` command: Validation Phase (step 1 / step 1.1)

Before entering the Planning Phase, `doc.doc.sh process` must verify that every active plugin is installed.

**Non-interactive mode** (stdin is not a TTY or `--non-interactive` flag is set):
- Print an error listing which active plugins are not installed and exit with a non-zero exit code.

**Interactive mode**:
For each uninstalled active plugin, prompt the user with three options:
```
Plugin '<name>' is not installed.
  [c] Continue without this plugin
  [a] Abort
  [i] Install now
Choice [c/a/i]:
```
- **Continue (`c`)**: skip the plugin and proceed with the remaining active plugins.
- **Abort (`a`)**: exit with a non-zero exit code immediately.
- **Install (`i`)**: attempt to install the plugin via the plugin's `install.sh`.
  - If installation succeeds: print a success message and proceed.
  - If installation fails: print an error message describing the failure, print the advice `sudo ./doc.doc.sh install --plugin <plugin_name>`, and exit with a non-zero exit code.

### 2 — `install --plugin` command: enhanced validation and failure guidance

Refine the existing `install --plugin` command (introduced in FEATURE_0014) with:

- **Unknown plugin name**: if the named plugin does not exist, print an error message that also lists the available plugin names and exit with a non-zero exit code.
- **Already installed guard**: if the plugin is already installed, print an informational message and exit 0 without re-running `install.sh` (behaviour already specified in FEATURE_0014; ensure it is implemented correctly).
- **Install failure advice**: if `install.sh` exits non-zero, print the error output followed by the advice: `Tip: try re-running with elevated privileges: sudo ./doc.doc.sh install --plugin <plugin_name>`, then exit with a non-zero exit code.

### 3 — `setup` command: install failure advice

Refine the `setup` command (introduced in FEATURE_0025) so that when a plugin's installation fails during setup:
- Print an error message that includes the captured failure output.
- Print the recovery advice: `sudo ./doc.doc.sh install --plugin <plugin_name>` or `sudo ./doc.doc.sh setup`.
- Exit with a non-zero exit code (do not silently continue after a failed install).

## Implementation Notes

- All interactive prompts must honour the existing `--non-interactive` / `-n` and `--yes` / `-y` flags already defined for `setup` (REQ_0006 / FEATURE_0025).
- Non-interactive `process` runs should treat a missing plugin as a hard error (exit non-zero) so that CI pipelines fail explicitly.
- The validation phase runs **before** the Planning Phase — no topological sort or file collection should occur if required plugins are missing and the user has not resolved the situation.
- Elevated-privilege advice (`sudo`) should only be printed when the installation failure output or exit code suggests a permissions issue, or as a general fallback tip (not as the sole explanation).

## Acceptance Criteria

### `process` — Validation Phase
- [ ] Before processing begins, every active plugin's `installed.sh` is invoked; plugins that report `"installed": false` are flagged
- [ ] In non-interactive mode, if any active plugin is not installed, the command prints a clear error listing the uninstalled plugins and exits with a non-zero exit code without processing any document
- [ ] In interactive mode, for each uninstalled active plugin, the user is prompted: continue without / abort / install
- [ ] Choosing **continue**: the plugin is skipped for the current run; remaining plugins are used normally
- [ ] Choosing **abort**: the command exits with a non-zero exit code immediately
- [ ] Choosing **install** and installation succeeds: a success message is printed and processing proceeds with the plugin included
- [ ] Choosing **install** and installation fails: an error message is printed, the advice `sudo ./doc.doc.sh install --plugin <plugin_name>` is displayed, and the command exits with a non-zero exit code
- [ ] When all active plugins are installed, the validation phase passes silently and processing continues normally

### `install --plugin` — enhanced validation and failure guidance
- [ ] When the specified plugin name is not found in `PLUGIN_DIR`, the error message lists all known plugin names and exits non-zero
- [ ] When the plugin is already installed, an informational message is printed and the command exits 0 without re-running `install.sh`
- [ ] When `install.sh` exits non-zero, the failure output is forwarded to stderr and the advice `sudo ./doc.doc.sh install --plugin <plugin_name>` is printed before exiting non-zero

### `setup` — install failure advice
- [ ] When a plugin's `install.sh` exits non-zero during setup, the captured failure output is forwarded to stderr
- [ ] The setup command prints the recovery advice: `sudo ./doc.doc.sh install --plugin <plugin_name>` or `sudo ./doc.doc.sh setup`
- [ ] The setup command exits with a non-zero exit code after an install failure (does not silently continue)

### General
- [ ] All interactive prompts are skipped (and treated as the safe default) when stdin is not a TTY or `--non-interactive` is set
- [ ] `--yes` / `-y` flag auto-answers **install** for uninstalled plugins in `process` and `setup`
- [ ] Existing tests pass without modification
- [ ] New tests cover: process exits non-zero in non-interactive mode with uninstalled plugin; install lists available plugins on unknown name; install prints sudo tip on failure; setup exits non-zero with advice on install failure

## Dependencies

- REQ_0009 (Process Command)
- REQ_0026 (Install Plugin Command)
- REQ_0006 (User-Friendly Interface)
- FEATURE_0014 (Install Single Plugin — baseline implementation)
- FEATURE_0025 (Interactive Setup Routine — baseline implementation)

## Related Links

- Project Goals: `project_management/02_project_vision/01_project_goals/project_goals.md` (§ Processing Documents — Validation Phase 1/1.1; § Setup; § Plugin Management — install command)
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0009_process-command.md`
- Requirements: `project_management/02_project_vision/02_requirements/03_accepted/REQ_0026_install-plugin.md`
